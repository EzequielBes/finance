# Algoritmo de Análise de Economia

## Contexto

Terceiro de quatro sub-projetos do conjunto de planejamento financeiro solicitado pelo usuário:

1. Gerenciamento de Categorias (concluído — seed padrão + limite mensal por categoria)
2. Autocomplete de transações repetidas (concluído)
3. **Algoritmo de análise de economia** (este spec)
4. Plano de economia dentro de Planos (depende deste)

Este é o núcleo do pedido original: "algoritmo inteligente com os gastos do usuário, pra ir mostrando onde a pessoa gastou a mais, de onde ela pode tirar pra equilibrar". O sub-projeto 4 vai consumir a saída deste algoritmo (categoria + valor sugerido de corte) para simular quanto tempo uma meta de plano pode ser antecipada.

## O que muda

### Classificação de categorias por necessidade

Toda categoria de gasto é classificada em dois grupos, usados para decidir se ela pode aparecer como sugestão de corte:

- **Essencial**: nome da categoria bate (case-insensitive) com "Moradia", "Saúde" ou "Contas fixas" — as 3 categorias-padrão do seed (sub-projeto 1) que representam gastos obrigatórios/de sobrevivência, não escolhas discricionárias.
- **Cortável**: qualquer outro nome — inclui as demais 5 categorias-padrão (Alimentação, Transporte, Lazer, Compras, Educação) e qualquer categoria criada pelo próprio usuário com nome diferente das 3 essenciais. Decisão explícita do usuário: por padrão, uma categoria desconhecida é tratada como cortável (mais útil assumir que pode ser otimizada do que assumir que é intocável).

Essa classificação é fixa em código (não é um campo novo no banco, não precisa de migração) — uma função pura que recebe o nome da categoria e devolve o grupo.

### Cálculo de referência por categoria

Para cada categoria de gasto (`type == 'expense'`) do usuário, a referência de comparação é:

1. Se a categoria tem `monthly_limit` definido (sub-projeto 1) → referência = `monthly_limit`.
2. Senão, se existe pelo menos 1 mês fechado anterior com gasto registrado nessa categoria → referência = média do gasto nos **3 meses calendário fechados anteriores ao atual** (não inclui o mês corrente, que ainda está em andamento e sendo comparado — isso é uma escolha deliberada, diferente do padrão já usado em `income.py`'s `/income/summary`, que usa "últimos 3 meses corridos" incluindo o atual; aqui isso misturaria o dado que está sendo avaliado com a própria base de comparação).
3. Senão (sem limite e sem histórico suficiente) → a categoria não entra na análise.

"3 meses calendário fechados anteriores" ao mês corrente M significa M-1, M-2, M-3 inteiros (do dia 1 ao último dia de cada um). Um mês só conta para a média se teve ao menos uma transação de gasto na categoria — meses sem gasto não entram no denominador (evita diluir artificialmente a média com zeros de meses em que a categoria nem existia ainda).

### Regra de inclusão na análise

Para cada categoria com referência válida, calcula-se `percent = (gasto_atual_do_mes / referencia) * 100`.

- `percent < 80` → não aparece na análise (dentro do esperado).
- `percent >= 80` → aparece na análise, com dois comportamentos possíveis:
  - **Essencial**: aparece só como aviso informativo ("Saúde está em 92% da referência"), nunca como sugestão de corte, mesmo passando de 100%.
  - **Cortável**: aparece como aviso entre 80-100%; ao passar de 100%, ganha também uma sugestão de corte no valor de `gasto_atual - referencia` (o excedente exato — não um percentual fixo, o objetivo é trazer de volta ao nível de referência, não mais que isso).

### Backend

**Endpoint novo: `GET /reports/savings-analysis`**

Novo router `backend/app/routers/reports.py`. Response: lista de itens, cada um com:
- `category_id`, `category_name`, `category_color`
- `is_essential: bool`
- `current_amount: float` (gasto do mês corrente na categoria)
- `reference_amount: float` (o limite ou a média, o que foi usado)
- `reference_source: "limit" | "average"` (para a UI poder dizer "comparado ao seu limite" vs "comparado à sua média")
- `percent: float`
- `suggested_cut: float | None` (só preenchido quando cortável e `percent > 100`; senão `null`)

Lista ordenada por `current_amount - reference_amount` decrescente (maior excedente absoluto primeiro — mistura itens com e sem sugestão de corte na mesma ordenação, já que o objetivo é mostrar onde o desvio é maior, seja aviso ou corte).

A query de gasto do mês corrente por categoria já existe (mesmo padrão de `GET /categories`, `backend/app/routers/categories.py`) — reaproveitar a mesma lógica de agregação, não duplicar uma terceira variante. A query de média dos 3 meses fechados é nova, usando o padrão de `and_`/`func.avg`/`group_by` já estabelecido no projeto.

### Frontend

**`ReportsView.vue`** (hoje um stub vazio com só o título) ganha conteúdo real:
- Busca `GET /reports/savings-analysis` ao montar.
- Lista os itens retornados como cards, cada um mostrando: nome da categoria, gasto atual vs referência, percentual (mesmo esquema de cor de 3 faixas já usado no medidor de orçamento do sub-projeto 1 — verde/terracota/terracota-escuro), e:
  - Se essencial: só o aviso, sem elemento de ação.
  - Se cortável com `suggested_cut`: mostra o valor sugerido de corte em destaque.
- Estado vazio: "Nenhuma categoria fora do esperado este mês" quando a lista vem vazia.
- Sem interatividade nova nesta tela (o sub-projeto 4 é quem vai consumir esses dados para simulação de plano — este spec só produz e exibe a análise, não constrói ainda o fluxo de "montar plano de economia").

## Fora de escopo

- Qualquer interação de "aceitar sugestão de corte" ou simulação de quanto tempo isso economiza — isso é o sub-projeto 4, que consome este endpoint (ou um formato derivado dele) dentro do contexto de um Plano específico.
- Classificação de necessidade configurável pelo usuário — é fixa em código por enquanto (ver seção acima).
- Análise para categorias de receita — só `type == 'expense'`.
- Histórico de análises passadas ou tendência mês a mês — a análise é sempre um snapshot do mês corrente.
- Notificação proativa (push, e-mail) quando uma categoria estoura — a tela é sob demanda, o usuário precisa visitar Relatórios.

## Testabilidade

Backend: testes com `pytest`/`httpx` seguindo o padrão de `backend/tests/test_categories.py` e `backend/tests/test_income.py` — cobrir: categoria com limite usa o limite como referência; categoria sem limite mas com histórico usa a média dos 3 meses fechados corretamente (excluindo o mês corrente do cálculo); categoria sem limite e sem histórico não aparece; categoria essencial acima de 100% aparece só como aviso sem `suggested_cut`; categoria cortável acima de 100% tem `suggested_cut` igual ao excedente exato; categoria entre 80-100% aparece mas sem `suggested_cut` mesmo sendo cortável; categoria abaixo de 80% não aparece; ordenação por maior excedente primeiro; isolamento por usuário (não vaza dado de outro usuário).

Frontend: sem suite de testes automatizados (padrão já confirmado no projeto) — verificação manual via browser cobrindo os cenários acima visualmente, incluindo o caso essencial (sem botão/valor de corte) vs cortável (com valor de corte destacado).
