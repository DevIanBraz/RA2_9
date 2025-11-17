module Main where

import Data.List (find)
import Data.Map (Map)
import qualified Data.Map as M
import Data.Time (UTCTime, getCurrentTime, defaultTimeLocale, formatTime)
import Control.Exception (catch, SomeException(..))
import System.IO (hPutStrLn, stderr)
import Data.Bifunctor (first)

-- 1. TIPOS DE DADOS E ESTRUTURAS

-- Tipo base para um item
data Item = Item {
    itemID :: String,
    nome :: String,
    quantidade :: Int,
    categoria :: String
} deriving (Show, Read)

-- O inventário é um mapa onde a chave é o itemID
type Inventario = Map String Item

-- Tipos para o Log de Auditoria (ADT)
data AcaoLog 
    = Add 
    | Remove 
    | Update 
    | QueryFail 
    | Report 
    | List
    | InitLoad 
    | Exit 
    deriving (Show, Read)

data StatusLog 
    = Sucesso 
    | Falha String 
    deriving (Show, Read)

data LogEntry = LogEntry {
    timestamp :: UTCTime,
    acao :: AcaoLog,
    detalhes :: String,
    status :: StatusLog
} deriving (Show, Read)

-- Alias de tipo para o resultado de uma operação pura bem-sucedida
type ResultadoOperacao = (Inventario, LogEntry)

-- 2. FUNÇÕES PURAS DE NEGÓCIO

-- Helpers para criação de LogEntry
logSucesso :: UTCTime -> AcaoLog -> String -> LogEntry
logSucesso time act det = LogEntry time act det Sucesso

logFalha :: UTCTime -> AcaoLog -> String -> LogEntry
logFalha time act det = LogEntry time act det (Falha det)

-- Adiciona um novo item ao inventário.
addItem :: UTCTime -> String -> String -> Int -> String -> Inventario -> Either String ResultadoOperacao
addItem time iid nm qtd cat inv
    | M.member iid inv = Left $ "Erro: ItemID '" ++ iid ++ "' ja existe no inventario."
    | otherwise = 
        let newItem = Item iid nm qtd cat
            newInv = M.insert iid newItem inv
            logE = logSucesso time Add $ "Adicionado: " ++ nm ++ " (ID: " ++ iid ++ ", Qtd: " ++ show qtd ++ ")"
        in Right (newInv, logE)

-- Remove uma quantidade do item.
removeItem :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao
removeItem time iid qtdRemove inv =
    case M.lookup iid inv of
        Nothing -> Left $ "Erro: ItemID '" ++ iid ++ "' nao encontrado."
        Just item
            | qtdRemove <= 0 -> Left "Erro: Quantidade a remover deve ser positiva."
            | quantidade item < qtdRemove -> 
                Left $ "Erro: Estoque insuficiente. Item: " ++ nome item ++ " (" ++ show (quantidade item) ++ ") < Remocao: " ++ show qtdRemove
            | otherwise ->
                let newQty = quantidade item - qtdRemove
                    updatedItem = item { quantidade = newQty }
                    -- Remove o item se a quantidade for zero
                    newInv = if newQty == 0 then M.delete iid inv else M.insert iid updatedItem inv
                    logE = logSucesso time Remove $ "Removido: " ++ nome item ++ " (" ++ show qtdRemove ++ "). Novo estoque: " ++ show newQty
                in Right (newInv, logE)

-- Atualiza a quantidade (adicionando/subtraindo).
updateQty :: UTCTime -> String -> Int -> Inventario -> Either String ResultadoOperacao
updateQty time iid qtdDelta inv =
    case M.lookup iid inv of
        Nothing -> Left $ "Erro: ItemID '" ++ iid ++ "' nao encontrado para atualizar."
        Just item
            | qtdDelta == 0 -> Left "Erro: Quantidade de mudanca deve ser diferente de zero."
            | quantidade item + qtdDelta < 0 ->
                Left $ "Erro: Estoque insuficiente para remocao (" ++ show (abs qtdDelta) ++ "). Estoque atual: " ++ show (quantidade item)
            | otherwise ->
                let newQty = quantidade item + qtdDelta
                    updatedItem = item { quantidade = newQty }
                    newInv = if newQty == 0 then M.delete iid inv else M.insert iid updatedItem inv
                    
                    actionStr = if qtdDelta > 0 then "Adicionado" else "Removido"
                    logE = logSucesso time Update $ actionStr ++ " em: " ++ nome item ++ " (" ++ show qtdDelta ++ "). Novo estoque: " ++ show newQty
                in Right (newInv, logE)

-- 3. FUNÇÕES PURAS DE RELATÓRIO

-- Gera uma string de relatório de logs de erro
logsDeErro :: [LogEntry] -> String
logsDeErro logs = 
    let erros = filter isFalha logs
        isFalha log = case status log of 
            Falha _ -> True
            _       -> False
        formatError log = 
            let timeStr = formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S" (timestamp log)
            in case status log of
                Falha msg -> timeStr ++ " [" ++ show (acao log) ++ "]: FALHA - " ++ msg
                _         -> ""
    in "--- RELATORIO DE ERROS ---\n" ++ 
       (if null erros then "Nenhum erro de log registrado.\n" else unlines (map formatError erros)) ++
       "----------------------------"

-- Gera uma string formatada para listar todos os itens
listarInventario :: Inventario -> String
listarInventario inv 
    | M.null inv = "Inventario vazio."
    | otherwise = 
        let header = "ID   | Nome         | Qtd | Categoria"
            sep    = "---|--------------|-----|----------"
            formatItem item = 
                let idStr = take 4 (itemID item) ++ replicate (4 - length (itemID item)) ' '
                    nameStr = take 12 (nome item) ++ replicate (12 - length (nome item)) ' '
                    qtyStr = show (quantidade item)
                in idStr ++ " | " ++ nameStr ++ " | " ++ qtyStr ++ " | " ++ categoria item
        in unlines (header : sep : map formatItem (M.elems inv))

-- 4. FUNÇÕES DE I/O E PERSISTÊNCIA

invFile :: FilePath
invFile = "Inventario.dat"

logFile :: FilePath
logFile = "Auditoria.log"

-- Tenta carregar o Inventário do disco. Retorna Map.empty em falha.
loadInventario :: IO Inventario
loadInventario = do
    result <- catch (Right <$> readFile invFile) 
                    (\(e :: SomeException) -> return (Left $ show e))
    case result of
        Left err -> do
            hPutStrLn stderr $ "Aviso: Nao foi possivel carregar " ++ invFile ++ ". Iniciando vazio. (Detalhe: " ++ err ++ ")"
            return M.empty
        Right content -> 
            case reads content of
                [(inv, "")] -> return inv
                _ -> do
                    hPutStrLn stderr $ "Aviso: Falha na desserializacao de " ++ invFile ++ ". Iniciando vazio."
                    return M.empty

-- Tenta carregar os Logs do disco. Retorna [] em falha.
loadLogs :: IO [LogEntry]
loadLogs = do
    result <- catch (Right <$> readFile logFile) 
                    (\(e :: SomeException) -> return (Left $ show e))
    case result of
        Left err -> return []
        Right content -> 
            case reads content of
                [(logs, "")] -> return logs
                _ -> return []


-- Persiste o inventário (sobrescreve) e anexa a entrada de log.
sincronizarSucesso :: Inventario -> LogEntry -> IO ()
sincronizarSucesso inv logE = do
    writeFile invFile (show inv)
    appendFile logFile (show logE ++ "\n")
    putStrLn $ "SUCESSO: " ++ detalhes logE

-- Apenas anexa a entrada de log (para falhas ou logs sem alteração de estado)
registrarLog :: LogEntry -> IO ()
registrarLog logE = do
    appendFile logFile (show logE ++ "\n")
    case status logE of
        Sucesso -> return () -- Evita exibir SUCESSO duas vezes
        Falha msg -> putStrLn $ "FALHA: " ++ detalhes logE

-- Parser de comandos de usuário
parseComando :: String -> Either String (AcaoLog, [String])
parseComando input = 
    case words input of
        ("add":iid:nm:qtd:cat:[]) -> 
            case reads qtd of
                [(q, "")] | q > 0 -> Right (Add, [iid, nm, show q, cat])
                _ -> Left "Quantidade invalida ou negativa para ADD."
        ("remove":iid:qtd:[]) ->
            case reads qtd of
                [(q, "")] | q > 0 -> Right (Remove, [iid, show q])
                _ -> Left "Quantidade invalida ou negativa para REMOVE."
        ("update":iid:qtd:[]) ->
            case reads qtd of
                [(q, "")] | q /= 0 -> Right (Update, [iid, show q])
                _ -> Left "Quantidade invalida (deve ser diferente de zero) para UPDATE."
        ("list":[]) -> Right (List, [])
        ("report":[]) -> Right (Report, [])
        ("exit":[]) -> Right (Exit, [])
        [] -> Left "Comando vazio."
        _ -> Left "Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit"


-- 5. LOOP PRINCIPAL

loop :: Inventario -> [LogEntry] -> IO ()
loop inv logs = do
    putStrLn "\n--- Inventario CLI ---"
    putStrLn $ "Itens no Inventario: " ++ show (M.size inv) ++ " | Logs registrados: " ++ show (length logs)
    putStrLn "Comando (add, remove, update, list, report, exit): "
    input <- getLine
    currentTime <- getCurrentTime
    
    case parseComando input of
        Right (Exit, _) -> do
            let logE = logSucesso currentTime Exit "Encerrando o programa. Estado persistido na ultima operacao."
            registrarLog logE
            putStrLn "Programa encerrado."

        Right (Report, _) -> do
            putStrLn ""
            putStrLn $ logsDeErro logs
            let logE = logSucesso currentTime Report "Geracao de relatorio de erros."
            registrarLog logE
            loop inv logs

        Right (List, _) -> do
            putStrLn "\n--- LISTAGEM DE INVENTARIO ---"
            putStrLn $ listarInventario inv
            putStrLn "------------------------------"
            let logE = logSucesso currentTime List "Listagem do inventario."
            registrarLog logE
            loop inv logs
        
        -- Processamento de comandos de transação
        Right (Add, [iid, nm, qtdStr, cat]) -> 
            let qtd = read qtdStr :: Int
                resultadoPuro = addItem currentTime iid nm qtd cat inv
            in processaResultado inv logs resultadoPuro currentTime Add input

        Right (Remove, [iid, qtdStr]) -> 
            let qtd = read qtdStr :: Int
                resultadoPuro = removeItem currentTime iid qtd inv
            in processaResultado inv logs resultadoPuro currentTime Remove input

        Right (Update, [iid, qtdStr]) -> 
            let qtd = read qtdStr :: Int
                resultadoPuro = updateQty currentTime iid qtd inv
            in processaResultado inv logs resultadoPuro currentTime Update input

        -- Captura qualquer outra combinação que não deveria ser possível
        Right (action, _) -> do
            let erroMsg = "Erro interno: Parametros incompativeis para a acao " ++ show action
            putStrLn $ "ERRO INTERNO: " ++ erroMsg
            let logE = logFalha currentTime QueryFail erroMsg
            registrarLog logE
            loop inv (logE:logs)

        Left erroMsg -> do
            putStrLn $ "ERRO DE COMANDO: " ++ erroMsg
            let logE = logFalha currentTime QueryFail $ "Comando invalido: " ++ input ++ ". Erro: " ++ erroMsg
            registrarLog logE
            loop inv (logE:logs)

-- Função auxiliar para processar o resultado do cálculo puro
processaResultado :: Inventario -> [LogEntry] -> Either String ResultadoOperacao -> UTCTime -> AcaoLog -> String -> IO ()
processaResultado oldInv oldLogs resultadoPuro currentTime action input = 
    case resultadoPuro of
        Right (newInv, logEntry) -> do
            sincronizarSucesso newInv logEntry
            loop newInv (logEntry:oldLogs)
        Left erroLg -> do
            let logE = logFalha currentTime action $ "Falha na logica: " ++ erroLg ++ " (Comando: " ++ input ++ ")"
            registrarLog logE
            loop oldInv (logE:oldLogs) -- Retorna ao loop com o inventário antigo

-- 6. PONTO DE ENTRADA (main)

main :: IO ()
main = do
    putStrLn "Iniciando o Sistema de Inventario..."
    
    -- Carregamento do estado anterior
    inv <- loadInventario
    logs <- loadLogs
    
    putStrLn $ "Inventario: " ++ show (M.size inv) ++ " itens. Logs: " ++ show (length logs) ++ " entradas."
    
    currentTime <- getCurrentTime
    let initLog = logSucesso currentTime InitLoad "Programa iniciado e estado carregado/inicializado."
    registrarLog initLog -- Registra o log de inicialização
    
    -- Inicia o loop principal
    loop inv (initLog:logs)
