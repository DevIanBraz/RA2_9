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
Baixei os arquivos e anexei eles no repositório! Importante ressaltar que assim que voce escreve "exit" os arqwuivos são gerados, em seguida, se voce tentar rodar o arquivo novamente, os arquivos ficam "bloqueados", como se fosse um bug das IDEs Online, então, tive que excluir o log no cenario 1 para dar continuidade aos textes, entretanto, coloquei os dois logs (antes e o de depois) para que não haja desconfianças de conteúdos ou testes não feitos.

### Dados mínimos:
**Auditoria.log:**␣␣
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
