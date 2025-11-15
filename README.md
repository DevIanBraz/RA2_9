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
