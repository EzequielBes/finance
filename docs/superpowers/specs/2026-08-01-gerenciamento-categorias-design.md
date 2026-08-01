# Gerenciamento de Categorias (seed padrão + limite mensal)

## Contexto

Primeiro de quatro sub-projetos que juntos formam um conjunto de funcionalidades de planejamento financeiro:

1. **Gerenciamento de Categorias** (este spec) — categorias pré-configuradas + limite de gasto mensal por categoria
2. Autocomplete de transações repetidas
3. Algoritmo de análise de economia (onde a pessoa está gastando a mais)
4. Plano de economia dentro de Planos (simulação de corte por categoria reduzindo prazo da meta)

Os sub-projetos 3 e 4 dependem do limite mensal criado aqui — a base de comparação "gasto real vs. esperado" usa o `monthly_limit` desta feature como uma das fontes (combinado com média histórica, no sub-projeto 3).

Hoje o app não tem nenhuma noção de orçamento — só existe CRUD de categoria simples (nome, tipo, cor, ícone) usado como rótulo de transação, sem controle de quanto se espera gastar.

## O que muda

### Backend

**Modelo `Category`** (`backend/app/models/category.py`) ganha um campo novo:
- `monthly_limit: float | None` — nullable, só tem sentido semântico para `type == expense` (categorias de receita podem tecnicamente receber um valor no banco já que o campo é genérico, mas a UI nunca expõe a edição desse campo para categorias de receita).

**Migração de schema:** o projeto não usa Alembic — `create_all_tables()` roda `Base.metadata.create_all` no lifespan da app, que só cria tabelas *novas*, não altera tabelas existentes. Como `categories` já existe em bancos com dados (dev local, produção futura), adicionar a coluna requer uma migração leve manual: um script one-off (`backend/scripts/add_monthly_limit_column.py` ou uma checagem condicional no startup) que roda `ALTER TABLE categories ADD COLUMN monthly_limit FLOAT` se a coluna não existir. Isso evita depender de Alembic só para esta mudança, mantendo o padrão atual do projeto (SQLite + create_all), mas sem perder dados de usuários que já têm categorias criadas.

**Endpoint novo: `POST /categories/seed-defaults`**
- Cria um conjunto fixo de categorias padrão para o usuário autenticado, pulando (não recriando) qualquer categoria cujo `name` já exista para aquele usuário (comparação case-insensitive).
- Lista fixa, em português, cores da paleta atual do frontend (grafite quente + terracota — mas cor de categoria é dado do usuário, não temos como cravar cor "correta" por categoria; usar uma pequena rotação de tons dentro da família aprovada para dar alguma distinção visual no gráfico de pizza):
  - Expense: Moradia, Alimentação, Transporte, Saúde, Lazer, Compras, Educação, Contas fixas
  - Income: Salário, Freelance, Outros rendimentos
- Retorna a lista de categorias criadas (as puladas por já existir não aparecem na resposta).
- Idempotente por design: chamar duas vezes não duplica nada.

**Endpoint modificado: `GET /categories`**
- Resposta de cada categoria ganha um campo calculado `current_month_usage: float` — soma de `Transaction.amount` onde `category_id` bate e `date` está entre o primeiro dia do mês corrente e hoje (mês calendário, sem filtrar por `Transaction.type` — soma tudo que foi lançado na categoria, seja receita ou despesa, conforme decisão do usuário). Isso é calculado em uma query agregada (uma única query `GROUP BY category_id` com filtro de data, não N+1 por categoria).
- `monthly_limit` (podendo ser `null`) também vai na resposta.

**Endpoint `PUT /categories/{id}`** (já existe) — schema `CategoryUpdate` ganha o campo `monthly_limit: float | None = None`.

### Frontend

**Nova view `frontend/src/views/CategoriesView.vue`**, nova rota `/categories` (`name: 'Categories'`), novo item na sidebar ("Categorias", entre Planos e Relatórios, ícone novo — precisa de uma entrada `categories` em `AppIcon.vue`'s `paths` dict, ex. um ícone de etiqueta/tag).

A tela tem duas seções:

**Seção A — Todas as categorias**
- Lista simples de todas as categorias do usuário (nome, tipo, cor, badge indicando se tem limite configurado ou não).
- Botão "Usar categorias padrão" no topo da seção — chama `POST /categories/seed-defaults`, re-busca a lista após.
- Clicar em uma categoria da lista abre um modal de edição com: nome, tipo, cor, e (só se `type === 'expense'`) um campo "Limite mensal (R$)" opcional. Salvar chama `PUT /categories/{id}`.
- Este modal também serve para o caso de criar categoria nova continuar existindo (o form inline que já existe em `TransactionsView.vue` continua ali sem mudanças — esta tela não substitui aquele fluxo rápido, é um lugar dedicado a gerenciar o que já existe).

**Seção B — Orçamento do mês**
- Só mostra categorias `type === 'expense'` que têm `monthly_limit` não nulo.
- Cada categoria vira um card com: nome, barra de progresso horizontal (`current_month_usage / monthly_limit`, capada visualmente em 100% de largura mas o texto mostra o percentual real mesmo acima de 100%), texto "R$ {current} / R$ {limit}".
- Cor da barra: usa a paleta já existente — `--accent-success` (verde envelhecido) até 80% do limite, `--accent-warning`/`--accent-primary` (terracota) de 80% a 100%, `--accent-danger` (terracota escuro) acima de 100%. Sem alerta ou notificação — só a mudança de cor já comunica.
- Se nenhuma categoria tiver limite configurado, a seção mostra um estado vazio orientando a pessoa a definir um limite clicando em uma categoria na Seção A.

## Fora de escopo (deste spec)

- Autocomplete de transações (sub-projeto 2).
- Qualquer algoritmo de recomendação de economia (sub-projeto 3) — este spec só disponibiliza o dado (`monthly_limit`, `current_month_usage`) que o sub-projeto 3 vai consumir depois.
- Notificação/alerta quando o limite é ultrapassado — só indicação visual passiva.
- Editar o valor de `current_month_usage` diretamente — é sempre derivado das transações reais, nunca editável.
- Limite mensal em categorias de receita — o campo existe no modelo por simplicidade (não vale a pena um segundo modelo só para isso), mas a UI nunca oferece essa edição para `type === 'income'`.
- Resetar o limite manualmente — o "reset mensal" é automático e implícito no cálculo (é sempre "mês calendário atual"), não existe um botão de reset nem um histórico de meses passados nesta feature.

## Testabilidade

Backend: testes com `pytest`/`httpx` seguindo o padrão já existente em `backend/tests/test_categories.py` — cobrir seed idempotente (chamar duas vezes, checar que não duplica), `current_month_usage` calculado corretamente (criar transações em datas dentro e fora do mês atual, confirmar que só as de dentro contam), `monthly_limit` aceito só quando fornecido no update.

Frontend: sem suite de testes automatizados (confirmado em specs anteriores do projeto) — verificação manual via browser cobrindo: seed não duplica ao clicar duas vezes, modal de edição salva limite corretamente, barra de progresso reflete valores reais e muda de cor nos thresholds certos.
