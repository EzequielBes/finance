# Design Spec: Plataforma de Análise e Planejamento Financeiro

**Data:** 2026-07-31  
**Status:** Aprovado  
**Autor:** Ezequiel + Antigravity

---

## 1. Visão Geral

Plataforma web de análise e planejamento financeiro pessoal com suporte a múltiplos usuários. O objetivo é dar ao usuário controle total sobre receitas, gastos e objetivos financeiros, incluindo uma visualização temporal (timeline) que mostra de forma intuitiva a distância até metas como viagens, compras ou investimentos.

**Stack:**
- **Backend:** Python + FastAPI + SQLite (via SQLAlchemy) + JWT auth
- **Frontend:** Vue.js 3 + Vite + Pinia + Vue Router
- **Formato:** Monorepo (`/backend` + `/frontend`) sem Docker no MVP
- **Custos:** Zero — 100% local, sem serviços externos

---

## 2. Arquitetura

```
AnalisadorFinanceiro/
├── backend/
│   ├── app/
│   │   ├── main.py                  # FastAPI app + CORS + lifespan
│   │   ├── database.py              # SQLAlchemy engine + session + Base
│   │   ├── auth.py                  # JWT: criação, validação, dependências
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── category.py
│   │   │   ├── transaction.py
│   │   │   ├── income_entry.py
│   │   │   ├── plan.py
│   │   │   ├── plan_contribution.py
│   │   │   └── insight.py
│   │   ├── schemas/                 # Pydantic (request/response)
│   │   ├── routers/
│   │   │   ├── auth.py              # /auth/register, /auth/login, /auth/me
│   │   │   ├── transactions.py      # CRUD + filtros
│   │   │   ├── income.py            # CRUD + histórico de renda
│   │   │   ├── plans.py             # CRUD planos + sub-planos + simulação
│   │   │   ├── dashboard.py         # Resumo mensal + timeline data
│   │   │   └── reports.py           # Relatórios e comparativos
│   │   └── services/
│   │       ├── plan_simulator.py    # Lógica: prazo, progresso, projeção
│   │       ├── timeline_builder.py  # Monta dados da timeline visual
│   │       └── insight_engine.py    # Análise de padrões (mock no MVP)
│   ├── requirements.txt
│   └── .env.example
│
├── frontend/
│   ├── src/
│   │   ├── main.js
│   │   ├── App.vue
│   │   ├── router/index.js
│   │   ├── stores/
│   │   │   ├── auth.js
│   │   │   ├── transactions.js
│   │   │   ├── income.js
│   │   │   ├── plans.js
│   │   │   └── dashboard.js
│   │   ├── services/
│   │   │   └── api.js               # Axios + interceptors JWT
│   │   ├── views/
│   │   │   ├── LoginView.vue
│   │   │   ├── DashboardView.vue
│   │   │   ├── TransactionsView.vue
│   │   │   ├── IncomeView.vue
│   │   │   ├── PlansView.vue
│   │   │   └── ReportsView.vue
│   │   └── components/
│   │       ├── layout/              # Sidebar, Header, NavBar
│   │       ├── charts/              # DonutChart, LineChart (Chart.js)
│   │       ├── timeline/            # TimelineMap.vue (componente central)
│   │       ├── plans/               # PlanCard, PlanSimulator, SubPlanList
│   │       └── transactions/        # TransactionForm, TransactionList
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
│
├── docs/
│   └── superpowers/specs/
├── README.md
└── .gitignore
```

**Fluxo de dados:**
1. Vue faz chamadas REST (Axios) para FastAPI em localhost:8000
2. FastAPI valida entrada com Pydantic, consulta SQLite via SQLAlchemy
3. JWT Bearer token armazenado no localStorage do frontend
4. Requests autenticados via header Authorization: Bearer <token>

---

## 3. Modelo de Dados

### users
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| name | String | |
| email | String UNIQUE | |
| password_hash | String | bcrypt |
| created_at | DateTime | |

### categories
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| user_id | Integer FK | |
| name | String | "Energia", "Transporte" |
| type | Enum | income / expense |
| color | String | Hex color |
| icon | String | Nome do ícone |

### transactions
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| user_id | Integer FK | |
| category_id | Integer FK | |
| description | String | |
| amount | Float | Sempre positivo |
| date | Date | Data da transação |
| type | Enum | income / expense |
| is_recurring | Boolean | |
| recurrence_period | Enum nullable | monthly / weekly / yearly |
| installments_total | Integer nullable | Total de parcelas |
| installments_current | Integer nullable | Parcela atual |
| installment_group_id | String nullable | UUID para agrupar parcelas |
| created_at | DateTime | |

### income_entries
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| user_id | Integer FK | |
| amount | Float | Valor recebido |
| date | Date | Quando recebeu |
| source | String | "Salário", "Freela", "Venda" |
| is_recurring | Boolean | Salário = true |
| recurrence_period | Enum nullable | monthly / weekly / yearly |
| notes | Text | |

### plans
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| user_id | Integer FK | |
| parent_plan_id | Integer FK nullable | Auto-referência para sub-planos |
| name | String | "Viagem Japão" |
| description | Text | |
| target_amount | Float | Valor necessário |
| current_savings | Float | Valor já guardado |
| monthly_contribution | Float | Quanto reservar/mês |
| deadline | Date nullable | Data limite (opcional) |
| status | Enum | active / paused / cancelled / completed |
| priority | Integer | 1 = maior prioridade |
| notes | Text | |
| created_at | DateTime | |
| updated_at | DateTime | Auto-atualizado |

### plan_contributions
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| plan_id | Integer FK | |
| amount | Float | Valor aportado |
| date | Date | Data do aporte |
| notes | Text | |

### insights
| Campo | Tipo | Notas |
|---|---|---|
| id | Integer PK | |
| user_id | Integer FK | |
| type | Enum | warning / tip / achievement |
| message | Text | Texto do insight |
| generated_at | DateTime | |
| is_read | Boolean | |

---

## 4. Funcionalidades

### 4.1 Autenticação
- POST /auth/register — cadastro com nome, email, senha
- POST /auth/login — retorna JWT (expira em 7 dias)
- GET /auth/me — retorna dados do usuário logado
- Senha armazenada com bcrypt

### 4.2 Transações
- CRUD completo: criar, listar, editar, deletar
- Tipos: pontual, recorrente, parcelado
- Parcelado: ao cadastrar "3x R$100", sistema cria 3 transações com installment_group_id comum e datas distribuídas mês a mês
- Filtros: período, categoria, tipo, texto
- Paginação na listagem

### 4.3 Renda (Income)
- Registro de receitas separado das transações
- Suporte a salário recorrente e renda extra pontual
- Cálculo de média de renda dos últimos 3 meses para simulações

### 4.4 Planos / Objetivos
- Criação com nome, valor alvo, contribuição mensal, prazo opcional
- Sub-planos: plano pai agrega progresso dos filhos
- Status: ativo, pausado, cancelado, concluído
- Simulador interativo: ajuste de monthly_contribution mostra nova data prevista
- Múltiplos planos simultâneos com prioridade configurável
- Histórico de aportes reais via plan_contributions

### 4.5 Dashboard
- Cards: Receita mensal, Total gasto, Saldo livre, % economizado
- Donut chart: gastos por categoria no mês atual
- Line chart: evolução dos últimos 6 meses (receita vs gasto)
- Mini-timeline: próximos 30 dias + marcos dos planos
- Card de Insight: insight do mês

### 4.6 Timeline Visual

Conceito:
```
AGORA       31/Jul      05/Ago    10/Ago     15/Ago   ...   Jan/27        Jun/27
  |            |           |         |          |               |             |
[YOU]─────[Luz:R$250]─[Condução]─[Tênis]─[Aluguel]────[PLANO:Carro]──[PLANO:Japão]
```

Comportamento:
- Eixo horizontal rolável (scroll/drag)
- Janela curta: hoje até fim do mês atual, com dias exatos para contas
- Marcos de planos: posicionados proporcionalmente no futuro
- Tooltip ao hover: nome, valor, data exata, status
- Código de cores: vermelho=fixo recorrente, amarelo=variável/parcelado, verde=plano ativo, cinza=pausado
- Endpoint: GET /dashboard/timeline?months_ahead=6

### 4.7 Relatórios
- Comparativo mês a mês
- Média por categoria
- Histórico de aportes por plano

### 4.8 Insights (Mock no MVP)
- Regras simples no insight_engine.py:
  - "Sua média de [categoria] subiu X% esse mês"
  - "Você tem saldo suficiente para atingir [plano] antes do prazo"
  - "Gasto [descrição] representa X% da sua receita"
- Estrutura preparada para substituição por LLM no futuro

---

## 5. Abordagens Descartadas

| Abordagem | Motivo |
|---|---|
| FastAPI + Jinja2 | Difícil escalar; sem reatividade rica |
| Docker desde início | Overhead excessivo para MVP |
| Open Finance / Pluggy | Custos e burocracia |
| React + Node.js | Preferência por Vue.js + Python |

---

## 6. Roadmap (Pós-MVP)

| Fase | Funcionalidade |
|---|---|
| v1.1 | Importação de extrato CSV/OFX |
| v1.2 | Integração com LLM local (Ollama) para insights reais |
| v2.0 | Integração com Pluggy/Open Finance |
| v2.1 | PWA / mobile-first |
| v2.2 | Deploy em nuvem (Railway/Render gratuito) |

---

## 7. Critérios de Sucesso do MVP

- [ ] Usuário consegue criar conta e logar
- [ ] Usuário consegue registrar receitas e gastos (fixos, variáveis, parcelados)
- [ ] Usuário consegue criar um plano e ver quando atingirá a meta
- [ ] Usuário consegue criar sub-planos e ajustar contribuição interativamente
- [ ] Timeline visual mostra gastos do mês + marcos dos planos no futuro
- [ ] Dashboard com resumo mensal e gráficos funciona corretamente
- [ ] Sistema funciona 100% local sem custo algum
