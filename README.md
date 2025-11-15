# RA2_9

## 1. Informações Básicas

| **[Ian Carlo Araujo Braz]** | [DevIanBraz] |


**Link para o Ambiente de Execução:** [(https://onlinegdb.com/dhK49ZITRA)]

---

## 2. Estrutura e Lógica

O código foi dividido seguindo a separação de responsabilidades (Funções Puras vs. I/O). O estado do inventário (`Inventario`) é mantido em um `Map` persistente em disco.

**Principais Regras de Negócio Implementadas:**
* **Adição (`add`):** Bloqueia a criação de itens com `itemID` duplicado.
* **Remoção/Atualização (`remove`, `update`):** Bloqueia operações que resultem em estoque negativo (Estoque Insuficiente).
* **Persistência:** O comando `exit` garante que os dados sejam salvos no `Inventario.dat` e os logs no `Auditoria.log`.

---

## 3. Comandos do Sistema

| Comando | Exemplo de Uso | Função |
| :--- | :--- | :--- |
| **add** | `add T01 TecladoMec 20 Perifericos` | Adiciona um item novo. |
| **remove** | `remove T01 5` | Retira uma quantidade do estoque (valor positivo). |
| **update** | `update T01 -3` ou `update T01 5` | Altera o estoque usando um delta (positivo ou negativo). |
| **list** | `list` | Lista todos os itens do inventário. |
| **report** | `report` | Gera um relatório apenas com logs de erro (`FALHA`). |
| **exit** | `exit` | Salva o estado e fecha o programa de forma limpa. |

---

## 4. Comprovação dos Cenários de Teste
Baixei os arquivos e anexei eles no repositório! Importante ressaltar que assim que voce escreve "exit" os arquivos são gerados, em seguida, se você tentar rodar o arquivo novamente, os arquivos ficam "bloqueados", como se fosse um bug das IDEs Online, então, tive que excluir o log no cenario 1 para dar continuidade aos textes, entretanto, coloquei os dois logs (antes e o de depois) para que não haja desconfianças de conteúdos ou testes não feitos.

---

### Dados mínimos:

**Auditoria.log:**
LogEntry {timestamp = 2025-11-14 22:48:01.540010799 UTC, acao = InitLoad, detalhes = "Programa iniciado e estado carregado/inicializado.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:48:11.368352278 UTC, acao = QueryFail, detalhes = "Comando invalido: add 1 caixa. Erro: Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit", status = Falha "Comando invalido: add 1 caixa. Erro: Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit"}
LogEntry {timestamp = 2025-11-14 22:48:23.018902329 UTC, acao = Add, detalhes = "Adicionado: caixa (ID: 1, Qtd: 1)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:48:31.959972971 UTC, acao = Add, detalhes = "Adicionado: papelao (ID: 2, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:48:39.839505118 UTC, acao = Add, detalhes = "Adicionado: arroz (ID: 3, Qtd: 3)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:48:52.452060635 UTC, acao = Add, detalhes = "Adicionado: feijao (ID: 4, Qtd: 4)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:49:16.295579174 UTC, acao = Add, detalhes = "Adicionado: fenda (ID: 5, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:49:25.868836004 UTC, acao = QueryFail, detalhes = "Comando invalido: add 6 bola1 item. Erro: Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit", status = Falha "Comando invalido: add 6 bola1 item. Erro: Comando invalido. Formato esperado: add ID nome 10 categoria | remove ID 5 | update ID 3 | list | report | exit"}
LogEntry {timestamp = 2025-11-14 22:49:35.601072403 UTC, acao = Add, detalhes = "Adicionado: bola (ID: 6, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:49:48.454018048 UTC, acao = Add, detalhes = "Adicionado: macarrao (ID: 7, Qtd: 1)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:49:56.996682263 UTC, acao = Add, detalhes = "Adicionado: prato (ID: 8, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:50:12.040251419 UTC, acao = Add, detalhes = "Adicionado: garfo (ID: 9, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:50:30.180275683 UTC, acao = Add, detalhes = "Adicionado: faca (ID: 10, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:50:35.160622442 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 22:55:15.846127549 UTC, acao = Exit, detalhes = "Encerrando o programa. Estado persistido na ultima operacao.", status = Sucesso}


**Inventario.dat:** 
fromList [("1",Item {itemID = "1", nome = "caixa", quantidade = 1, categoria = "item"}),("10",Item {itemID = "10", nome = "faca", quantidade = 10, categoria = "item"}),("2",Item {itemID = "2", nome = "papelao", quantidade = 2, categoria = "item"}),("3",Item {itemID = "3", nome = "arroz", quantidade = 3, categoria = "comida"}),("4",Item {itemID = "4", nome = "feijao", quantidade = 4, categoria = "feijao"}),("5",Item {itemID = "5", nome = "fenda", quantidade = 2, categoria = "item"}),("6",Item {itemID = "6", nome = "bola", quantidade = 2, categoria = "item"}),("7",Item {itemID = "7", nome = "macarrao", quantidade = 1, categoria = "comida"}),("8",Item {itemID = "8", nome = "prato", quantidade = 10, categoria = "item"}),("9",Item {itemID = "9", nome = "garfo", quantidade = 10, categoria = "item"})]

---

### Cenário 1 (antes):

**Auditoria.log:** 
LogEntry {timestamp = 2025-11-14 23:20:54.154979249 UTC, acao = InitLoad, detalhes = "Programa iniciado e estado carregado/inicializado.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:21:07.343929348 UTC, acao = Add, detalhes = "Adicionado: teste (ID: 1, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:21:13.81249363 UTC, acao = Add, detalhes = "Adicionado: teste (ID: 2, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:21:19.783536007 UTC, acao = Add, detalhes = "Adicionado: teste (ID: 3, Qtd: 2)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:21:21.877311925 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:21:32.723446662 UTC, acao = Exit, detalhes = "Encerrando o programa. Estado persistido na ultima operacao.", status = Sucesso}


**Inventario.dat:**

fromList [("1",Item {itemID = "1", nome = "teste", quantidade = 2, categoria = "item"}),("2",Item {itemID = "2", nome = "teste", quantidade = 2, categoria = "item"}),("3",Item {itemID = "3", nome = "teste", quantidade = 2, categoria = "item"})]

### Cenário 1 (depois):

**Auditoria.log:**
LogEntry {timestamp = 2025-11-14 23:26:18.721899096 UTC, acao = InitLoad, detalhes = "Programa iniciado e estado carregado/inicializado.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:26:21.753786384 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:29:52.401767827 UTC, acao = Exit, detalhes = "Encerrando o programa. Estado persistido na ultima operacao.", status = Sucesso}

**Inventario.dat:** 
fromList [("1",Item {itemID = "1", nome = "teste", quantidade = 2, categoria = "item"}),("2",Item {itemID = "2", nome = "teste", quantidade = 2, categoria = "item"}),("3",Item {itemID = "3", nome = "teste", quantidade = 2, categoria = "item"})]

---

### Cenário 2:

**Auditoria.log:**
LogEntry {timestamp = 2025-11-14 23:40:25.251517008 UTC, acao = InitLoad, detalhes = "Programa iniciado e estado carregado/inicializado.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:33.602602085 UTC, acao = Add, detalhes = "Adicionado: item (ID: 1, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:36.351623797 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:49.449880075 UTC, acao = Add, detalhes = "Adicionado: teclado (ID: 2, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:53.228573413 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:59.606053002 UTC, acao = Remove, detalhes = "Falha na logica: Erro: Estoque insuficiente. Item: teclado (10) < Remocao: 15 (Comando: remove 2 15)", status = Falha "Falha na logica: Erro: Estoque insuficiente. Item: teclado (10) < Remocao: 15 (Comando: remove 2 15)"}
LogEntry {timestamp = 2025-11-14 23:41:05.233309367 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:41:16.26343531 UTC, acao = Report, detalhes = "Geracao de relatorio de erros.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:41:37.627146205 UTC, acao = Exit, detalhes = "Encerrando o programa. Estado persistido na ultima operacao.", status = Sucesso}

**Inventario.dat:** 
fromList [("1",Item {itemID = "1", nome = "item", quantidade = 10, categoria = "item"}),("2",Item {itemID = "2", nome = "teclado", quantidade = 10, categoria = "item"})]

---

### Cenário 3:

**Auditoria.log:**
LogEntry {timestamp = 2025-11-14 23:40:25.251517008 UTC, acao = InitLoad, detalhes = "Programa iniciado e estado carregado/inicializado.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:33.602602085 UTC, acao = Add, detalhes = "Adicionado: item (ID: 1, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:36.351623797 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:49.449880075 UTC, acao = Add, detalhes = "Adicionado: teclado (ID: 2, Qtd: 10)", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:53.228573413 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:40:59.606053002 UTC, acao = Remove, detalhes = "Falha na logica: Erro: Estoque insuficiente. Item: teclado (10) < Remocao: 15 (Comando: remove 2 15)", status = Falha "Falha na logica: Erro: Estoque insuficiente. Item: teclado (10) < Remocao: 15 (Comando: remove 2 15)"}
LogEntry {timestamp = 2025-11-14 23:41:05.233309367 UTC, acao = List, detalhes = "Listagem do inventario.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:41:16.26343531 UTC, acao = Report, detalhes = "Geracao de relatorio de erros.", status = Sucesso}
LogEntry {timestamp = 2025-11-14 23:41:37.627146205 UTC, acao = Exit, detalhes = "Encerrando o programa. Estado persistido na ultima operacao.", status = Sucesso}


**Inventario.dat:** 
fromList [("1",Item {itemID = "1", nome = "item", quantidade = 10, categoria = "item"}),("2",Item {itemID = "2", nome = "teclado", quantidade = 10, categoria = "item"})]







