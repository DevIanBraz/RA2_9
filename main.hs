module Main where

import Data.List (find)
import Data.Map (Map)
import qualified Data.Map as M
import Data.Time (getCurrentTime, UTCTime)
import Control.Exception (catch, SomeException)
import System.IO (hPutStrLn, stderr, appendFile, readFile, writeFile)
import Data.Bifunctor (first)

-- Constantes para arquivos de persistência
invFile :: FilePath
invFile = "Inventario.dat"

logFile :: FilePath
logFile = "Auditoria.log"

-- ====================================================================
-- 1. TIPOS DE DADOS E ESTRUTURAS
-- ====================================================================

-- Tipo para representar um Item no inventário
data Item = Item
    { itemID :: String
    , nome :: String
    , quantidade :: Int
    , categoria :: String
    } deriving (Show, Read)

-- Tipo principal: O inventário é um mapa de ID para Item
type Inventario = Map String Item

-- Tipos para o sistema de Logs
data AcaoLog
    = InitLoad
    | Add
    | Remove
    | Update
    | List
    | Report
    | QueryFail
    | Exit
    deriving (Show, Read)

data StatusLog
    = Sucesso
    | Falha String
    deriving (Show, Read)

data LogEntry = LogEntry
    { timestamp :: UTCTime
    , acao :: AcaoLog
    , detalhes :: String
    , status :: StatusLog
    } deriving (Show, Read)

type ResultadoOperacao = (Inventario, LogEntry)

-- ====================================================================
-- 2. FUNÇÕES PURAS DE NEGÓCIO
-- ====================================================================

-- Helpers para criar logs
logSucesso :: AcaoLog -> String -> ResultadoOperacao -> LogEntry
logSucesso acao msg (inv, _) = LogEntry (timestamp (snd (inv, LogEntry {timestamp = undefined, acao = acao, detalhes = msg, status = Sucesso}))) acao msg Sucesso

logFalha :: AcaoLog -> String -> String -> LogEntry
logFalha acao detalhes msg = LogEntry (timestamp (snd (M.empty, LogEntry {timestamp = undefined, acao = acao, detalhes = detalhes, status = Falha msg}))) acao detalhes (Falha msg)

-- Adiciona um novo item ao inventário
addItem :: Inventario -> Item -> AcaoLog -> Either String ResultadoOperacao
addItem inv newItem acao =
    case M.lookup (itemID newItem) inv of
        Just _ -> Left $ "ItemID '" ++ itemID newItem ++ "' ja existe no inventario."
        Nothing ->
            let newInv = M.insert (itemID newItem) newItem inv
                msg = "Adicionado: " ++ nome newItem ++ " (ID: " ++ itemID newItem ++ ", Qtd: " ++ show (quantidade newItem) ++ ")"
                logE = LogEntry { timestamp = undefined, acao = acao, detalhes = msg, status = Sucesso }
            in Right (newInv, logE)

-- Remove uma quantidade de um item
removeItem :: Inventario -> String -> Int -> AcaoLog -> Either String ResultadoOperacao
removeItem inv idToRemove qtd acao =
    case M.lookup idToRemove inv of
        Nothing -> Left $ "ItemID '" ++ idToRemove ++ "' nao encontrado para remocao."
        Just item ->
            let newQty = quantidade item - qtd
                detalhesMsg = "Item: " ++ nome item ++ " (" ++ show (quantidade item) ++ ") < Remocao: " ++ show qtd ++ " (Comando: remove " ++ idToRemove ++ " " ++ show qtd ++ ")"
            in if newQty < 0
               then Left $ "Estoque insuficiente. " ++ detalhesMsg
               else
                   let newInv = if newQty == 0
                                then M.delete idToRemove inv
                                else M.insert idToRemove (item { quantidade = newQty }) inv
                       msg = "Removido: " ++ show qtd ++ " de " ++ nome item ++ " (ID: " ++ idToRemove ++ "). Novo estoque: " ++ show newQty
                       logE = LogEntry { timestamp = undefined, acao = acao, detalhes = msg, status = Sucesso }
                   in Right (newInv, logE)

-- Atualiza a quantidade de um item (usa delta positivo ou negativo)
updateQty :: Inventario -> String -> Int -> AcaoLog -> Either String ResultadoOperacao
updateQty inv idToUpdate qtdDelta acao =
    case M.lookup idToUpdate inv of
        Nothing -> Left $ "ItemID '" ++ idToUpdate ++ "' nao encontrado para atualizar."
        Just item ->
            let newQty = quantidade item + qtdDelta
                detalhesMsg = "Item: " ++ nome item ++ " (" ++ show (quantidade item) ++ ") | Delta: " ++ show qtdDelta
            in if newQty < 0
               then Left $ "Estoque insuficiente. " ++ detalhesMsg
               else
                   let newInv = M.insert idToUpdate (item { quantidade = newQty }) inv
                       msg = "Atualizado: " ++ nome item ++ " (ID: " ++ idToUpdate ++ "). Delta: " ++ show qtdDelta ++ ". Novo estoque: " ++ show newQty
                       logE = LogEntry { timestamp = undefined, acao = acao, detalhes = msg, status = Sucesso }
                   in Right (newInv, logE)

-- ====================================================================
-- 3. FUNÇÕES PURAS DE RELATÓRIO
-- ====================================================================

isFalha :: LogEntry -> Bool
isFalha log = case status log of
    Falha _ -> True
    _       -> False

-- Filtra os logs para exibir apenas as falhas
logsDeErro :: [LogEntry] -> String
logsDeErro logs =
    let erros = filter isFalha logs
        formatError log =
            case status log of
                Falha msg -> show (timestamp log) ++ " [" ++ show (acao log) ++ "]: FALHA - " ++ detalhes log
                _         -> ""
    in unlines ("--- RELATORIO DE ERROS ---" : map formatError erros)

-- Formata o inventário para exibição na CLI
listarInventario :: Inventario -> String
listarInventario inv =
    let header = "--- LISTAGEM DE INVENTARIO ---\n" ++ "ID   | Nome         | Qtd | Categoria\n" ++ "---|--------------|-----|----------"
        items = M.elems inv
        formatItem item =
            let q = show (quantidade item)
            in itemID item ++ replicate (5 - length (itemID item)) ' ' ++
               "|" ++ nome item ++ replicate (13 - length (nome item)) ' ' ++
               "|" ++ q ++ replicate (4 - length q) ' ' ++
               "|" ++ categoria item
    in unlines (header : map formatItem items) ++ "\n------------------------------"

-- ====================================================================
-- 4. FUNÇÕES DE I/O E PERSISTÊNCIA
-- ====================================================================

-- Tenta carregar o inventário do arquivo Inventario.dat
loadInventario :: IO Inventario
loadInventario = catch
    (do
        content <- readFile invFile
        case reads content of
            [(inv, "")] -> return inv
            _ -> do
                putStrLn "Aviso: Falha na desserializacao de Inventario.dat. Iniciando vazio."
                return M.empty
    )
    (\(e :: SomeException) -> do
        putStrLn $ "Aviso: Nao foi possivel carregar " ++ invFile ++ ". Iniciando vazio. (Detalhe: " ++ show e ++ ")"
        return M.empty
    )

-- Tenta carregar os logs do Auditoria.log
loadLogs :: IO [LogEntry]
loadLogs = catch
    (do
        content <- readFile logFile
        -- Logs sao lidos linha por linha
        let logLines = lines content
        let parsedLogs = foldr (\line acc -> case reads line of
                                            [(logEntry, "")] -> logEntry : acc
                                            _ -> acc
                              ) [] logLines
        return parsedLogs
    )
    (\(e :: SomeException) -> do
        hPutStrLn stderr $ "Aviso: Nao foi possivel carregar logs. (Detalhe: " ++ show e ++ ")"
        return []
    )

-- Persiste o novo estado e o novo log (usado em operações de sucesso)
sincronizarSucesso :: Inventario -> LogEntry -> IO ()
sincronizarSucesso inv logE = do
    writeFile invFile (show inv)
    appendFile logFile (show logE ++ "\n")

-- Registra um log de Falha ou Logs simples (List, Report)
registrarLog :: LogEntry -> IO ()
registrarLog logE = do
    appendFile logFile (show logE ++ "\n")

-- Parser de comandos
parseComando :: String -> Either String (AcaoLog, [String])
parseComando input =
    let tokens = words input
    in case tokens of
        ["add", id, nome, qtdStr, cat] -> case reads qtdStr of
            [(qtd, "")] | qtd > 0 -> Right (Add, [id, nome, show qtd, cat])
            _ -> Left "Quantidade invalida ou negativa para 'add'."
        ["remove", id, qtdStr] -> case reads qtdStr of
            [(qtd, "")] | qtd > 0 -> Right (Remove, [id, show qtd])
            _ -> Left "Quantidade invalida ou negativa para 'remove'."
        ["update", id, qtdStr] -> case reads qtdStr of
            [(qtd, "")] -> Right (Update, [id, show qtd])
            _ -> Left "Quantidade invalida para 'update'."
        ["list"]   -> Right (List, [])
        ["report"] -> Right (Report, [])
        ["exit"]   -> Right (Exit, [])
        _          -> Left $ "Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit"

-- ====================================================================
-- 5. LOOP PRINCIPAL E EXECUÇÃO
-- ====================================================================

-- Processa o resultado de uma função pura (sucesso ou falha)
processaResultado :: UTCTime -> Inventario -> AcaoLog -> String -> Either String ResultadoOperacao -> IO (Inventario, [LogEntry])
processaResultado time oldInv acao input result =
    case result of
        Right (newInv, logE) -> do
            let finalLog = logE { timestamp = time }
            putStrLn $ show (status finalLog) ++ ": " ++ detalhes finalLog
            sincronizarSucesso newInv finalLog
            return (newInv, [finalLog])

        Left errMsg -> do
            let detalhesMsg = "Falha na logica: Erro: " ++ errMsg ++ " (Comando: " ++ input ++ ")"
            let logE = logFalha acao detalhesMsg errMsg
            let finalLog = logE { timestamp = time }
            putStrLn $ "FALHA: " ++ detalhesMsg
            registrarLog finalLog
            return (oldInv, [finalLog])

-- Loop principal de I/O
loop :: Inventario -> [LogEntry] -> IO ()
loop inv logs = do
    putStrLn "\n--- Inventario CLI ---"
    putStrLn $ "Itens no Inventario: " ++ show (M.size inv) ++ " | Logs registrados: " ++ show (length logs)
    putStrLn "Comando (add, remove, update, list, report, exit): "
    input <- getLine
    time <- getCurrentTime

    let parsed = parseComando input
    
    (newInv, newLogs) <- case parsed of
        Right (Exit, _) -> do
            let logE = logSucesso Exit "Encerrando o programa. Estado persistido na ultima operacao." (inv, undefined)
            let finalLog = logE { timestamp = time }
            sincronizarSucesso inv finalLog
            putStrLn "Sistema de Inventario encerrado."
            return (inv, [finalLog])

        Right (Report, _) -> do
            putStrLn $ logsDeErro logs
            let logE = logSucesso Report "Geracao de relatorio de erros." (inv, undefined)
            let finalLog = logE { timestamp = time }
            registrarLog finalLog
            return (inv, [finalLog])

        Right (List, _) -> do
            putStrLn $ listarInventario inv
            let logE = logSucesso List "Listagem do inventario." (inv, undefined)
            let finalLog = logE { timestamp = time }
            registrarLog finalLog
            return (inv, [finalLog])

        Right (Add, [id, name, qtdStr, cat]) ->
            let qtd = read qtdStr
                item = Item id name qtd cat
            in processaResultado time inv Add input (addItem inv item Add)

        Right (Remove, [id, qtdStr]) ->
            let qtd = read qtdStr
            in processaResultado time inv Remove input (removeItem inv id qtd Remove)

        Right (Update, [id, qtdStr]) ->
            let qtdDelta = read qtdStr
            in processaResultado time inv Update input (updateQty inv id qtdDelta Update)

        Left errMsg -> do
            let detalhesMsg = "Comando invalido: " ++ input ++ ". Erro: " ++ errMsg
            let logE = logFalha QueryFail detalhesMsg errMsg
            let finalLog = logE { timestamp = time }
            putStrLn $ "ERRO DE COMANDO: " ++ errMsg
            registrarLog finalLog
            return (inv, [finalLog])

    -- Se o comando não for 'Exit', continua o loop
    case parsed of
        Right (Exit, _) -> return ()
        _               -> loop newInv (logs ++ newLogs)

-- Função principal que inicializa o sistema
main :: IO ()
main = do
    putStrLn "\nIniciando o Sistema de Inventario..."
    -- Carregar estados anteriores
    initialInv <- loadInventario
    initialLogs <- loadLogs

    putStrLn $ "Inventario: " ++ show (M.size initialInv) ++ " itens. Logs: " ++ show (length initialLogs)

    -- Registrar o log de inicialização
    time <- getCurrentTime
    let initMsg = "Programa iniciado e estado carregado/inicializado."
    let initLog = LogEntry { timestamp = time, acao = InitLoad, detalhes = initMsg, status = Sucesso }

    registrarLog initLog

    -- Iniciar o loop principal
    loop initialInv (initialLogs ++ [initLog])
