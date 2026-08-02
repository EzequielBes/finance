# Autocomplete de Transações Repetidas

## Contexto

Segundo de quatro sub-projetos do conjunto de planejamento financeiro solicitado pelo usuário:

1. Gerenciamento de Categorias (concluído e mergeado — seed padrão + limite mensal por categoria)
2. **Autocomplete de transações repetidas** (este spec)
3. Algoritmo de análise de economia
4. Plano de economia dentro de Planos

Este sub-projeto não depende de nenhum dos outros e nenhum dos outros depende dele — é independente na cadeia, mas segue a mesma numeração de planejamento.

Hoje, cadastrar uma transação repetida (ex: "Mercado" todo mês) exige digitar descrição, valor e selecionar categoria do zero toda vez. O objetivo é sugerir, com base no histórico do próprio usuário, lançamentos parecidos conforme a pessoa digita a descrição — clicar na sugestão preenche o resto do formulário.

## O que muda

### Backend

**Endpoint novo: `GET /transactions/suggestions?q=<texto>`**

- Parâmetro `q: str` obrigatório (mínimo 2 caracteres — validado via `Query(min_length=2)`).
- Filtra `Transaction.description` do usuário autenticado por substring case-insensitive (`ILIKE`/`LIKE` conforme suportado pelo SQLite — comparação padrão do SQLite já é case-insensitive para ASCII, sem necessidade de função extra).
- Agrupa por descrição exata: para cada valor distinto de `description` que combina com `q`, retorna apenas a transação mais recente (`ORDER BY date DESC`) daquele grupo.
- Limita a 5 descrições distintas no resultado.
- Response: lista de objetos com os campos que o formulário de nova transação precisa para se auto-preencher: `description`, `amount`, `category_id`, `type`. Não é o `TransactionResponse` completo — um schema novo e menor, `TransactionSuggestion`, evita expor `id`/`installments_*`/`created_at` que não fazem sentido aqui (a sugestão é um molde para uma transação *nova*, não uma referência à antiga).

**Detalhe de implementação importante — ordem de rotas:** o router já tem `GET /transactions/{transaction_id}` (rota com path parameter inteiro). FastAPI casa rotas na ordem em que são declaradas — `GET /transactions/suggestions` precisa ser declarada **antes** de `GET /transactions/{transaction_id}` no arquivo, senão a palavra "suggestions" seria capturada como valor de `transaction_id` e falharia a validação de tipo `int` com 422 em vez de rotear corretamente.

**Query agrupada:** como SQLite não tem uma forma direta de "GROUP BY description, pegando a linha inteira com data mais recente" em uma única expressão simples, a abordagem mais direta e correta é: buscar todas as transações do usuário que combinam com `q` ordenadas por `date DESC`, iterar em Python mantendo um `dict` por `description` (primeira ocorrência de cada descrição = mais recente, já que a query está ordenada), parar ao atingir 5 descrições distintas. Isso evita subqueries complexas e é perfeitamente aceitável em escala pessoal (poucas centenas/milhares de transações por usuário).

### Frontend

**Store `frontend/src/stores/transactions.js`** ganha uma ação nova: `fetchSuggestions(query)` — chama `GET /transactions/suggestions?q=...` e retorna a lista (não precisa de estado persistente no store, é usado sob demanda pelo componente que chama).

**`TransactionsView.vue`**, no formulário de nova transação:
- O campo Descrição ganha um `watch` sobre `form.description` com debounce de 300ms. Só dispara a busca quando o texto tem 2+ caracteres; texto vazio ou com 1 caractere limpa a lista de sugestões sem chamar a API.
- Um dropdown de sugestões aparece logo abaixo do input de Descrição quando há resultados e o campo está em foco, estilizado como um pequeno menu (fundo `--bg-input`, borda `--border-subtle`, cada item com hover `--bg-card-hover`) — consistente com o restante do design system do app.
- Cada item do dropdown mostra a descrição e o valor formatado (ex: "Mercado — R$ 980,00") para a pessoa reconhecer a sugestão antes de clicar.
- Clicar em um item preenche `form.description`, `form.amount`, `form.category_id`, `form.type` com os valores da sugestão, e fecha o dropdown. Não mexe em `form.date` (mantém o que já estava selecionado) nem em `form.is_recurring`/`form.recurrence_period`/`form.installments_total` (usuário decide esses campos de novo a cada lançamento, mesmo que o anterior fosse recorrente ou parcelado — evita marcar uma parcela nova como recorrente automaticamente por engano).
- Clicar fora do dropdown (ou selecionar um item) fecha a lista.
- Se o usuário trocar o valor de `form.type` manualmente depois de aceitar uma sugestão, o dropdown de categoria já existente (que filtra por tipo, feature já implementada) volta a filtrar normalmente — nenhuma mudança necessária ali, o autocomplete só popula os campos, não interfere na lógica já existente de filtro de categoria por tipo.

## Fora de escopo

- Sugestões na tela de Renda (`IncomeView.vue`) — só transações (`TransactionsView.vue`), conforme pedido original do usuário ("se todo mês ela vai gastando em coisas repetidas pra pessoa cadastrar esse valor fica mais fácil" — no contexto de gastos).
- Aprendizado/ranking por frequência de uso — a ordenação é sempre por data mais recente, não por quantas vezes a pessoa usou aquela descrição.
- Edição de transação existente ganhando autocomplete — só o formulário de criação.
- Navegação por teclado no dropdown (setas + Enter) — só clique do mouse; pode ser adicionado depois se o usuário sentir falta, mas não é solicitado aqui.
- Sugestões cross-usuário ou globais — sempre e só o histórico do próprio usuário autenticado (já garantido pelo filtro `Transaction.user_id == current_user.id`, mas vale deixar explícito: nenhuma sugestão vem de dados de outros usuários).

## Testabilidade

Backend: testes com `pytest`/`httpx` seguindo o padrão de `backend/tests/test_transactions.py` — cobrir: busca retorna a transação mais recente quando há duplicatas por descrição; busca é case-insensitive; busca não retorna mais de 5 descrições distintas; busca só considera transações do usuário autenticado (não vaza dados de outro usuário); `q` com menos de 2 caracteres retorna 422 (validação do FastAPI); rota `/transactions/suggestions` não conflita com `/transactions/{transaction_id}` (teste de regressão explícito, já que é o tipo de bug que passa despercebido até alguém reordenar rotas sem perceber a dependência de ordem).

Frontend: sem suite de testes automatizados (padrão já confirmado no projeto) — verificação manual via browser: digitar 1 caractere não busca, digitar 2+ com debounce mostra sugestões, clicar preenche os 4 campos corretamente, clicar fora fecha o dropdown, criar duas transações com a mesma descrição e valores diferentes confirma que a sugestão mostra a mais recente.
