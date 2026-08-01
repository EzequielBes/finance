# Redesign Visual do Frontend — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o dark mode roxo/indigo genérico do frontend por uma identidade visual própria ("grafite quente + terracota", tipografia serifada+sans), com um anel de progresso circular como elemento assinatura do Dashboard e micro-animações de entrada nos elementos de destaque.

**Architecture:** A UI inteira já consome cores/espaçamento via CSS custom properties centralizadas em `frontend/src/assets/main.css` e um punhado de classes utilitárias (`.card`, `.btn`, `.form-input`, `.badge`, etc). Trocar os valores desses tokens propaga o novo visual para quase todas as views sem tocar em HTML/Vue. Only three views precisam de mudança estrutural: `LoginView.vue` (novo layout de cartão), `DashboardView.vue` (novo componente `ProgressRing.vue` substitui um stat card), e `TimelineMap.vue` (trilha desenhada + stagger reveal). Ícones emoji são trocados por um conjunto pequeno de ícones SVG monoline inline, centralizados em um único arquivo de componente `AppIcon.vue`.

**Tech Stack:** Vue 3 (Composition API, `<script setup>`), CSS puro (custom properties, sem framework de UI), sem bibliotecas novas.

## Global Constraints

- Paleta ("Grafite quente + terracota"), valores hex exatos:
  - `--bg-primary: #1a1613` (fundo geral)
  - `--bg-secondary: #14110e` (sidebar, mais escuro que o conteúdo)
  - `--bg-card: #211d19` (superfície de card)
  - `--bg-card-hover: #23201b`
  - `--bg-input: #17130f` (inputs, campos)
  - `--border-subtle: #2c2620`
  - `--text-primary: #ede6dc`
  - `--text-secondary: #a89c8e`
  - `--text-muted: #8a7d6e`
  - `--accent-primary: #c17a54` (terracota, único acento — usado com moderação)
  - `--accent-primary-glow: rgba(193, 122, 84, 0.25)`
  - `--accent-success: #7a9b7e` (verde envelhecido para receitas)
  - `--accent-warning: #c17a54` (mesma família quente do acento — sem amarelo/âmbar puro)
  - `--accent-danger: #b8563a` (terracota mais escuro/avermelhado para gastos/exclusão, distinto do acento primário)
  - `--accent-info: #8a9bb0` (azul acinzentado discreto, só para badges neutros)
- Sem glassmorphism: `.card` usa fundo sólido `var(--bg-card)` + borda `1px solid var(--border-subtle)`, sem `backdrop-filter`, sem transparência translúcida.
- Tipografia: `--font-serif: Georgia, 'Iowan Old Style', 'Times New Roman', serif` para títulos/números de destaque; `--font-sans: -apple-system, 'Helvetica Neue', Arial, sans-serif` para corpo/labels/UI (nenhuma fonte externa via Google Fonts — remove o `@import` do Inter).
- `border-radius`: reduzir a escala atual (`--radius-lg: 20px`, `--radius-xl: 28px` eram excessivos para o tom editorial) para `--radius-sm: 8px`, `--radius-md: 10px`, `--radius-lg: 14px`.
- Micro-animações ficam restritas a: anel de progresso (entrada animada), contadores numéricos de destaque (count-up), itens da timeline (stagger reveal). Nenhum novo hover/press-state em botões/cards fora do que já existe.
- Toda animação de entrada deve respeitar `prefers-reduced-motion: reduce` — quando ativo, mostrar o estado final direto, sem transição.
- Ícones: emojis em `AppSidebar.vue`, `StatCard.vue` (via props `icon` do Dashboard), `PlanSimulator.vue`, `TransactionsView.vue`/`IncomeView.vue`/`PlansView.vue` (empty states) são substituídos por ícones SVG monoline (stroke, sem preenchimento) de um componente único `AppIcon.vue`. Nenhuma lib de ícones externa — SVGs inline mínimos.
- Sem mudança de lógica de negócio, chamadas de API, rotas, ou stores em nenhuma task.
- Sem testes automatizados de frontend no projeto — verificação é manual via Chrome automation, comparando telas antes/depois.

---

### Task 1: Novos tokens de design em `main.css`

**Files:**
- Modify: `frontend/src/assets/main.css`

**Interfaces:**
- Produces: todas as CSS custom properties listadas em Global Constraints, disponíveis em `:root` para consumo por qualquer componente via `var(--nome)`. Nenhuma variável antiga é removida (mesmos nomes, novos valores), exceto `--glass-bg`, `--glass-border`, `--glass-blur`, `--gradient-primary`, `--gradient-success`, `--gradient-card`, `--shadow-glow` que são removidas (glassmorphism sai de cena) — qualquer consumidor dessas variáveis é atualizado nas tasks seguintes.
- Consumes: nada (é a base).

- [ ] **Step 1: Substituir o bloco `:root` inteiro**

Abra `frontend/src/assets/main.css` e substitua da linha 1 (`@import`) até o fechamento do bloco `:root` (linha 63, `}`) por:

```css
:root {
  /* Cores base — Grafite quente */
  --bg-primary: #1a1613;
  --bg-secondary: #14110e;
  --bg-card: #211d19;
  --bg-card-hover: #23201b;
  --bg-input: #17130f;

  /* Bordas */
  --border-subtle: #2c2620;
  --border-focus: rgba(193, 122, 84, 0.5);

  /* Texto */
  --text-primary: #ede6dc;
  --text-secondary: #a89c8e;
  --text-muted: #8a7d6e;

  /* Acentos */
  --accent-primary: #c17a54;      /* Terracota */
  --accent-primary-glow: rgba(193, 122, 84, 0.25);
  --accent-success: #7a9b7e;      /* Verde envelhecido */
  --accent-warning: #c17a54;
  --accent-danger: #b8563a;       /* Terracota escuro/avermelhado */
  --accent-info: #8a9bb0;         /* Azul acinzentado discreto */

  /* Sombras */
  --shadow-sm: 0 2px 8px rgba(0,0,0,0.35);
  --shadow-md: 0 4px 20px rgba(0,0,0,0.45);

  /* Raios */
  --radius-sm: 8px;
  --radius-md: 10px;
  --radius-lg: 14px;

  /* Transições */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
  --transition-slow: 400ms ease;

  /* Tipografia */
  --font-serif: Georgia, 'Iowan Old Style', 'Times New Roman', serif;
  --font-sans: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
}
```

- [ ] **Step 2: Atualizar `.card` para remover glassmorphism**

Substitua o bloco `.card` (logo após `body { ... }`):

```css
/* Cards */
.card {
  background: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  transition: background var(--transition-base), box-shadow var(--transition-base);
}
.card:hover { background: var(--bg-card-hover); box-shadow: var(--shadow-md); }
```

- [ ] **Step 3: Atualizar `.btn-primary` para usar cor sólida em vez de gradiente**

Substitua:
```css
.btn-primary {
  background: var(--gradient-primary); color: white;
  box-shadow: 0 4px 15px var(--accent-primary-glow);
}
.btn-primary:hover { transform: translateY(-1px); box-shadow: 0 6px 20px var(--accent-primary-glow); }
```
por:
```css
.btn-primary {
  background: var(--accent-primary); color: #17130f;
  box-shadow: 0 4px 15px var(--accent-primary-glow);
  font-weight: 600;
}
.btn-primary:hover { transform: translateY(-1px); box-shadow: 0 6px 20px var(--accent-primary-glow); background: #cd8862; }
```

- [ ] **Step 4: Atualizar badges para usar as novas cores (mesma estrutura, cores diferentes automaticamente via var — sem mudança de código, as regras `.badge-success`, `.badge-warning`, `.badge-danger`, `.badge-info` já usam `var(--accent-*)` e `rgba(...)` hardcoded)**

As regras atuais usam `rgba(16,185,129,0.15)` etc hardcoded em vez de derivar da var. Substitua o bloco `/* Badges */` inteiro:

```css
/* Badges */
.badge {
  display: inline-flex; align-items: center; gap: 0.25rem;
  padding: 0.2rem 0.6rem; border-radius: 999px;
  font-size: var(--font-size-xs); font-weight: 600;
  font-family: var(--font-sans);
}
.badge-success { background: rgba(122,155,126,0.15); color: var(--accent-success); }
.badge-warning { background: rgba(193,122,84,0.15); color: var(--accent-warning); }
.badge-danger { background: rgba(184,86,58,0.15); color: var(--accent-danger); }
.badge-info { background: rgba(138,155,176,0.15); color: var(--accent-info); }
```

- [ ] **Step 5: Atualizar `.progress-fill` para cor sólida**

Substitua:
```css
.progress-fill {
  height: 100%; border-radius: 999px;
  background: var(--gradient-primary);
  transition: width var(--transition-slow);
}
```
por:
```css
.progress-fill {
  height: 100%; border-radius: 999px;
  background: var(--accent-primary);
  transition: width var(--transition-slow);
}
```

- [ ] **Step 6: Aplicar fonte serifada em títulos, adicionar suporte a `prefers-reduced-motion`**

Adicione ao final do arquivo (após a media query de responsividade existente):

```css
/* Tipografia de destaque */
.page-title { font-family: var(--font-serif); }
h1, h2, h3 { font-family: var(--font-serif); }

/* Acessibilidade: respeitar preferência de menos movimento */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Note que `body` já usa `var(--font-sans)` (linha `font-family: var(--font-sans);` dentro do bloco `body`) — isso não muda, então textos/labels seguem sans por padrão, e só `h1`/`h2`/`h3`/`.page-title` (que usam `<h1>`,`<h2>`,`<h3>` ou a classe) herdam a serifada.

- [ ] **Step 7: Verificar visualmente que o build ainda funciona**

Run: `cd frontend && npm run build`
Expected: build succeeds (`✓ built in ...ms`), sem erros de CSS.

- [ ] **Step 8: Commit**

```bash
cd frontend
git add src/assets/main.css
git commit -m "feat(design): substitui tokens de cor/tipografia por grafite quente + terracota"
```

---

### Task 2: Componente `AppIcon.vue` (ícones SVG monoline)

**Files:**
- Create: `frontend/src/components/common/AppIcon.vue`

**Interfaces:**
- Produces: componente `AppIcon` com prop `name: String` (obrigatória) e prop opcional `size: [String, Number]` (default `20`). Renderiza um `<svg>` inline conforme o nome. Nomes suportados nesta task: `dashboard`, `transactions`, `income`, `plans`, `reports`, `wallet`, `trending-up`, `trending-down`, `bank`, `target`, `calculator`, `logout`. Import: `import AppIcon from '@/components/common/AppIcon.vue'`. Uso: `<AppIcon name="wallet" />` ou `<AppIcon name="wallet" :size="24" />`.
- Consumes: nada.

- [ ] **Step 1: Criar o componente com os ícones necessários**

```vue
<script setup>
const props = defineProps({
  name: { type: String, required: true },
  size: { type: [String, Number], default: 20 },
})

const paths = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  transactions: 'M7 10l5-5 5 5M7 14l5 5 5-5',
  income: 'M12 3v18M5 10l7-7 7 7',
  plans: 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 4a6 6 0 1 0 0 12 6 6 0 0 0 0-12zm0 4a2 2 0 1 0 0 4 2 2 0 0 0 0-4z',
  reports: 'M4 19h16M8 19V9m4 10V5m4 14v-7',
  wallet: 'M3 7a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v1h1a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7zm14 5h.01',
  'trending-up': 'M3 17l6-6 4 4 8-8M15 7h6v6',
  'trending-down': 'M3 7l6 6 4-4 8 8M21 11v6h-6',
  bank: 'M3 21h18M4 10h16M6 10V21M18 10V21M10 10V21M14 10V21M12 3L3 9h18L12 3z',
  target: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2z',
  calculator: 'M5 3h14a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM7 7h10M7 11h2M11 11h2M15 11h2M7 15h2M11 15h2M15 15h2',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
}
</script>

<template>
  <svg
    :width="size" :height="size" viewBox="0 0 24 24"
    fill="none" stroke="currentColor" stroke-width="1.75"
    stroke-linecap="round" stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="paths[name]" />
  </svg>
</template>
```

- [ ] **Step 2: Verificar visualmente em isolamento**

Não há framework de testes de componente neste projeto. Verificação: este componente será exercitado visualmente nas Tasks 3-8 ao substituir os emojis; se algum `name` usado não existir em `paths`, o SVG renderiza vazio (sem erro de console) — cada task subsequente que usa `AppIcon` deve conferir visualmente que o ícone aparece.

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/components/common/AppIcon.vue
git commit -m "feat(design): adiciona componente AppIcon com icones SVG monoline"
```

---

### Task 3: Componente `ProgressRing.vue` (elemento assinatura)

**Files:**
- Create: `frontend/src/components/dashboard/ProgressRing.vue`

**Interfaces:**
- Produces: componente `ProgressRing` com props `percent: Number` (0-100, obrigatória), `label: String` (default `'saúde financeira'`), `size: Number` (default `200`). Anima o preenchimento do anel de 0 até `percent` ao montar (800ms, ease-out), e o número central faz count-up de 0 até `percent` no mesmo intervalo. Respeita `prefers-reduced-motion: reduce` (mostra o valor final sem animar). Import: `import ProgressRing from '@/components/dashboard/ProgressRing.vue'`. Uso: `<ProgressRing :percent="75" />`.
- Consumes: nada além de Vue core (`ref`, `onMounted`, `computed`).

- [ ] **Step 1: Criar o componente**

```vue
<script setup>
import { ref, onMounted, computed } from 'vue'

const props = defineProps({
  percent: { type: Number, required: true },
  label: { type: String, default: 'saúde financeira' },
  size: { type: Number, default: 200 },
})

const displayPercent = ref(0)
const radius = computed(() => props.size / 2 - 12)
const circumference = computed(() => 2 * Math.PI * radius.value)
const dashOffset = ref(circumference.value)

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function animateTo(target) {
  if (prefersReducedMotion) {
    displayPercent.value = target
    dashOffset.value = circumference.value * (1 - target / 100)
    return
  }
  const duration = 800
  const start = performance.now()
  const clamped = Math.max(0, Math.min(100, target))

  function tick(now) {
    const elapsed = now - start
    const t = Math.min(1, elapsed / duration)
    const eased = 1 - Math.pow(1 - t, 3) // ease-out cubic
    displayPercent.value = Math.round(eased * clamped)
    dashOffset.value = circumference.value * (1 - (eased * clamped) / 100)
    if (t < 1) requestAnimationFrame(tick)
  }
  requestAnimationFrame(tick)
}

onMounted(() => animateTo(props.percent))
</script>

<template>
  <div class="ring-wrap" :style="{ width: size + 'px', height: size + 'px' }">
    <svg :width="size" :height="size" :viewBox="`0 0 ${size} ${size}`">
      <circle
        :cx="size / 2" :cy="size / 2" :r="radius"
        fill="none" stroke="var(--border-subtle)" stroke-width="10"
      />
      <circle
        :cx="size / 2" :cy="size / 2" :r="radius"
        fill="none" stroke="var(--accent-primary)" stroke-width="10"
        stroke-linecap="round"
        :stroke-dasharray="circumference"
        :stroke-dashoffset="dashOffset"
        :transform="`rotate(-90 ${size / 2} ${size / 2})`"
      />
    </svg>
    <div class="ring-label">
      <div class="ring-value">{{ displayPercent }}%</div>
      <div class="ring-sub">{{ label }}</div>
    </div>
  </div>
</template>

<style scoped>
.ring-wrap { position: relative; flex-shrink: 0; }
.ring-wrap svg { position: absolute; inset: 0; }
.ring-label {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
}
.ring-value { font-family: var(--font-serif); font-size: 2.5rem; font-weight: 600; color: var(--text-primary); line-height: 1; }
.ring-sub {
  font-family: var(--font-sans); font-size: var(--font-size-xs); color: var(--text-muted);
  text-transform: uppercase; letter-spacing: 0.08em; margin-top: 0.375rem;
}
</style>
```

- [ ] **Step 2: Verificar visualmente**

Este componente é standalone e será usado na Task 4. Verificação real acontece lá. Confirme aqui apenas que não há erro de sintaxe:

Run: `cd frontend && npm run build`
Expected: build succeeds sem erros (o componente ainda não é importado por nada, então só valida sintaxe do arquivo).

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/components/dashboard/ProgressRing.vue
git commit -m "feat(design): adiciona ProgressRing como elemento assinatura do dashboard"
```

---

### Task 4: Reestruturar `DashboardView.vue` com o anel de progresso

**Files:**
- Modify: `frontend/src/views/DashboardView.vue`
- Modify: `frontend/src/components/dashboard/StatCard.vue`

**Interfaces:**
- Consumes: `ProgressRing` (Task 3, prop `percent: Number`), `AppIcon` (Task 2, prop `name: String`).
- Produces: nenhuma interface nova consumida por outras tasks.

O Dashboard hoje mostra 4 `StatCard`s genéricos em grid (receita, gasto, saldo, economizado) seguidos de donut chart + timeline. A nova versão substitui o layout por: um "hero" no topo com o `ProgressRing` (usando `savings_percent` como o percentual de saúde financeira) ao lado do saldo em destaque tipográfico grande, seguido de 3 stat cards secundários (receita/gasto/economizado — sem o saldo repetido, já que ele virou o hero), depois donut chart + timeline como já existem.

- [ ] **Step 1: Trocar os emojis de `StatCard.vue` por `AppIcon`**

Em `frontend/src/components/dashboard/StatCard.vue`, adicione o import e troque a prop `icon` de string livre para um nome de ícone:

```vue
<script setup>
import AppIcon from '@/components/common/AppIcon.vue'

defineProps({
  label: String,
  value: String,
  icon: String, // nome do ícone (ver AppIcon.vue), ex: 'trending-up'
  variant: { type: String, default: 'default' }, // 'success' | 'danger' | 'warning' | 'default'
  subtitle: String,
})
</script>

<template>
  <div class="stat-card card animate-fade-in">
    <div class="stat-header">
      <AppIcon :name="icon" :size="18" class="stat-icon" />
      <span class="stat-label text-muted text-sm">{{ label }}</span>
    </div>
    <div :class="['stat-value', variant !== 'default' && `text-${variant}`]">{{ value }}</div>
    <div v-if="subtitle" class="text-muted text-sm">{{ subtitle }}</div>
  </div>
</template>

<style scoped>
.stat-card { display: flex; flex-direction: column; gap: 0.5rem; }
.stat-header { display: flex; align-items: center; gap: 0.5rem; }
.stat-icon { color: var(--accent-primary); flex-shrink: 0; }
.stat-label { font-weight: 500; }
.stat-value { font-family: var(--font-serif); font-size: var(--font-size-2xl); font-weight: 600; }
</style>
```

- [ ] **Step 2: Reestruturar o template de `DashboardView.vue`**

Substitua todo o `<template>` (mantendo `<script setup>` como está, exceto o import novo):

```vue
<script setup>
import { onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import ProgressRing from '@/components/dashboard/ProgressRing.vue'
import DonutChart from '@/components/charts/DonutChart.vue'
import TimelineMap from '@/components/timeline/TimelineMap.vue'
import { useDashboardStore } from '@/stores/dashboard'

const dash = useDashboardStore()

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

onMounted(async () => {
  await dash.fetchSummary()
  await dash.fetchTimeline()
})
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h1 class="page-title">Dashboard</h1>
      <p class="page-subtitle">Visão geral das suas finanças</p>
    </div>

    <div v-if="dash.loading" class="grid-4" style="margin-bottom:1.5rem">
      <div v-for="i in 4" :key="i" class="skeleton card" style="height:100px" />
    </div>

    <div v-else>
      <!-- Hero: anel de saúde financeira + saldo em destaque -->
      <div class="dashboard-hero card">
        <ProgressRing :percent="dash.summary?.savings_percent || 0" />
        <div class="hero-text">
          <div class="hero-eyebrow text-muted">saldo disponível</div>
          <h2 class="hero-value">{{ formatCurrency(dash.summary?.balance) }}</h2>
        </div>
      </div>

      <!-- Stat Cards secundários -->
      <div class="grid-3" style="margin: 1.5rem 0">
        <StatCard label="Receita do mês" :value="formatCurrency(dash.summary?.total_income)" icon="trending-up" variant="success" />
        <StatCard label="Total gasto" :value="formatCurrency(dash.summary?.total_expense)" icon="trending-down" variant="danger" />
        <StatCard label="Economizado" :value="`${dash.summary?.savings_percent || 0}%`" icon="wallet" variant="success" subtitle="do total recebido" />
      </div>

      <!-- Gráfico + Timeline -->
      <div class="grid-2" style="margin-bottom:1.5rem">
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Gastos por categoria</h3>
          <DonutChart :categories="dash.summary?.by_category || []" />
        </div>
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Mapa financeiro</h3>
          <TimelineMap :events="dash.timeline" />
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.dashboard-hero { display: flex; align-items: center; gap: 3rem; padding: 2.5rem; }
.hero-eyebrow { font-family: var(--font-sans); font-size: var(--font-size-xs); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.5rem; }
.hero-value { font-family: var(--font-serif); font-size: 2.75rem; font-weight: 500; color: var(--text-primary); }
@media (max-width: 768px) {
  .dashboard-hero { flex-direction: column; text-align: center; gap: 1.5rem; padding: 1.5rem; }
}
</style>
```

- [ ] **Step 3: Verificar visualmente no browser**

Com `docker compose up -d --build` (ou `npm run dev` local), navegar até `/` autenticado e confirmar: anel de progresso anima do 0 até o valor real ao carregar a página, saldo aparece grande ao lado em fonte serifada, os 3 stat cards abaixo mostram ícones SVG (não emoji), donut chart e timeline continuam funcionando como antes.

- [ ] **Step 4: Commit**

```bash
cd frontend
git add src/views/DashboardView.vue src/components/dashboard/StatCard.vue
git commit -m "feat(design): dashboard usa ProgressRing como hero, StatCard usa AppIcon"
```

---

### Task 5: Timeline com trilha desenhada e stagger reveal

**Files:**
- Modify: `frontend/src/components/timeline/TimelineMap.vue`

**Interfaces:**
- Consumes: nada novo (mesma prop `events: Array` de antes).
- Produces: nenhuma interface nova.

A timeline atual usa uma linha reta com gradiente simples e todos os eventos aparecem de uma vez. A nova versão adiciona uma trilha vertical com gradiente terracota→transparente (em vez de linha horizontal) e cada evento revela com um pequeno atraso sequencial (stagger) ao montar.

- [ ] **Step 1: Substituir o componente inteiro**

```vue
<script setup>
import { computed, ref, onMounted } from 'vue'

const props = defineProps({ events: { type: Array, default: () => [] } })

const sorted = computed(() =>
  [...props.events].sort((a, b) => new Date(a.date) - new Date(b.date))
)

const visibleCount = ref(0)
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function formatDate(dateStr) {
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
}

function formatCurrency(val) {
  return val ? `R$ ${val.toFixed(0)}` : ''
}

onMounted(() => {
  if (prefersReducedMotion) {
    visibleCount.value = sorted.value.length
    return
  }
  const total = sorted.value.length
  let i = 0
  function revealNext() {
    if (i >= total) return
    visibleCount.value = i + 1
    i += 1
    setTimeout(revealNext, 80)
  }
  revealNext()
})
</script>

<template>
  <div class="timeline-wrapper">
    <div class="timeline-track">
      <!-- Trilha vertical desenhada -->
      <div class="timeline-line" />

      <!-- Ponto "Você aqui" -->
      <div class="timeline-now">
        <div class="now-dot" />
        <div class="now-label">Hoje</div>
      </div>

      <!-- Eventos -->
      <div
        v-for="(event, i) in sorted"
        :key="i"
        v-show="i < visibleCount"
        :class="['timeline-event', event.type === 'plan_milestone' && 'milestone']"
        :style="{ '--event-color': event.color }"
      >
        <div class="event-dot" />
        <div class="event-card">
          <div class="event-label">{{ event.label }}</div>
          <div class="event-date text-muted" style="font-size:0.7rem">{{ formatDate(event.date) }}</div>
          <div v-if="event.amount" class="event-amount">{{ formatCurrency(event.amount) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.timeline-wrapper { overflow-x: auto; padding: 1rem 0; }
.timeline-track {
  display: flex; align-items: flex-start; gap: 2rem;
  min-width: max-content; padding: 0 1rem; position: relative;
}
.timeline-line {
  position: absolute; top: 20px; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, var(--accent-primary), transparent 85%);
  opacity: 0.5;
}
.timeline-now { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; }
.now-dot {
  width: 16px; height: 16px; border-radius: 50%;
  background: var(--accent-primary); box-shadow: 0 0 10px var(--accent-primary-glow);
  flex-shrink: 0;
}
.now-label { font-family: var(--font-sans); font-size: 0.7rem; font-weight: 600; color: var(--accent-primary); white-space: nowrap; }
.timeline-event {
  display: flex; flex-direction: column; align-items: center; gap: 0.5rem;
  animation: eventReveal var(--transition-slow) ease forwards;
}
@keyframes eventReveal {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
.event-dot {
  width: 12px; height: 12px; border-radius: 50%;
  background: var(--event-color); flex-shrink: 0;
  box-shadow: 0 0 6px var(--event-color);
}
.milestone .event-dot { width: 16px; height: 16px; }
.event-card {
  background: var(--bg-input); border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm); padding: 0.5rem 0.75rem;
  min-width: 100px; text-align: center;
}
.event-label { font-family: var(--font-sans); font-size: var(--font-size-xs); font-weight: 600; }
.event-amount { font-family: var(--font-sans); font-size: var(--font-size-xs); color: var(--text-secondary); margin-top: 0.15rem; }
</style>
```

Nota: `v-show` (não `v-if`) é usado para revelar eventos porque a animação CSS `eventReveal` precisa que o elemento já exista no DOM antes de ficar visível — `v-show` alterna `display:none`, e a keyframe roda a cada vez que o elemento passa a ser exibido dentro do fluxo normal do navegador (o elemento já está montado desde o início, só oculto).

- [ ] **Step 2: Verificar visualmente no browser**

Navegar até o Dashboard e observar: os itens da timeline aparecem em sequência rápida (não todos de uma vez) ao carregar a página, a trilha horizontal usa a cor terracota com fade.

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/components/timeline/TimelineMap.vue
git commit -m "feat(design): timeline com stagger reveal e trilha em terracota"
```

---

### Task 6: Reestruturar `LoginView.vue`

**Files:**
- Modify: `frontend/src/views/LoginView.vue`

**Interfaces:**
- Consumes: nada novo (mesmo `useAuthStore`).
- Produces: nenhuma interface nova.

- [ ] **Step 1: Substituir o arquivo inteiro**

```vue
<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const mode = ref('login') // 'login' | 'register'
const name = ref('')
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    if (mode.value === 'login') {
      await auth.login(email.value, password.value)
    } else {
      await auth.register(name.value, email.value, password.value)
    }
  } catch (e) {
    error.value = e.response?.data?.detail || 'Ocorreu um erro. Tente novamente.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-bg">
    <div class="login-container animate-fade-in">
      <div class="login-brand">
        <div class="login-mark">Finança</div>
        <h1 class="login-title">Bem-vindo de volta</h1>
        <p class="login-sub text-muted">Controle total da sua vida financeira</p>
      </div>

      <div class="card login-card">
        <div class="tab-row">
          <button :class="['tab-btn', mode === 'login' && 'active']" @click="mode = 'login'">Entrar</button>
          <button :class="['tab-btn', mode === 'register' && 'active']" @click="mode = 'register'">Criar conta</button>
        </div>

        <form @submit.prevent="submit" class="form-stack">
          <div v-if="mode === 'register'" class="form-group">
            <label class="form-label">Nome</label>
            <input v-model="name" class="form-input" type="text" placeholder="Seu nome completo" required />
          </div>
          <div class="form-group">
            <label class="form-label">E-mail</label>
            <input v-model="email" class="form-input" type="email" placeholder="seu@email.com" required />
          </div>
          <div class="form-group">
            <label class="form-label">Senha</label>
            <input v-model="password" class="form-input" type="password" placeholder="••••••••" required />
          </div>

          <div v-if="error" class="error-msg">{{ error }}</div>

          <button type="submit" class="btn btn-primary" style="width:100%;justify-content:center" :disabled="loading">
            {{ loading ? 'Aguarde...' : (mode === 'login' ? 'Entrar' : 'Criar conta') }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-bg {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  background: radial-gradient(ellipse at 50% 20%, #241d17 0%, var(--bg-primary) 65%);
}
.login-container { width: 100%; max-width: 400px; padding: 1rem; }
.login-brand { text-align: center; margin-bottom: 2.5rem; }
.login-mark {
  font-family: var(--font-sans); font-size: var(--font-size-sm); letter-spacing: 0.15em;
  text-transform: uppercase; color: var(--accent-primary); margin-bottom: 0.625rem;
}
.login-title { font-family: var(--font-serif); font-size: 1.875rem; font-weight: 500; color: var(--text-primary); }
.login-sub { font-family: var(--font-sans); font-size: var(--font-size-sm); margin-top: 0.5rem; }
.login-card { padding: 2rem; }
.tab-row {
  display: flex; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-subtle);
  font-family: var(--font-sans); font-size: var(--font-size-sm);
}
.tab-btn {
  padding: 0.5rem 0; margin-right: 1.5rem; color: var(--text-muted);
  background: none; border: none; cursor: pointer; position: relative;
  font-family: var(--font-sans); font-size: var(--font-size-sm);
  transition: color var(--transition-fast);
}
.tab-btn.active { color: var(--text-primary); }
.tab-btn.active::after {
  content: ''; position: absolute; bottom: -1px; left: 0; right: 0;
  height: 2px; background: var(--accent-primary);
}
.form-stack { display: flex; flex-direction: column; gap: 1rem; }
.error-msg { background: rgba(184,86,58,0.12); border: 1px solid rgba(184,86,58,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 2: Verificar visualmente no browser**

Navegar até `/login`, confirmar: cartão editorial sem glassmorphism, abas com sublinhado terracota (não fundo cheio), fonte serifada no título "Bem-vindo de volta". Testar o fluxo de erro: digitar credenciais erradas, clicar "Entrar", confirmar que a mensagem de erro aparece dentro do card **sem recarregar a página** (o fix do bug de login já foi commitado antes deste plano, mas esta é a primeira verificação visual pós-redesign).

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/views/LoginView.vue
git commit -m "feat(design): login com layout de cartao editorial"
```

---

### Task 7: Sidebar com ícones SVG e item ativo por borda lateral

**Files:**
- Modify: `frontend/src/components/layout/AppSidebar.vue`

**Interfaces:**
- Consumes: `AppIcon` (Task 2).
- Produces: nenhuma interface nova.

- [ ] **Step 1: Substituir o arquivo inteiro**

```vue
<script setup>
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppIcon from '@/components/common/AppIcon.vue'

const route = useRoute()
const auth = useAuthStore()

const navItems = [
  { path: '/', icon: 'dashboard', label: 'Dashboard' },
  { path: '/transactions', icon: 'transactions', label: 'Transações' },
  { path: '/income', icon: 'income', label: 'Renda' },
  { path: '/plans', icon: 'plans', label: 'Planos' },
  { path: '/reports', icon: 'reports', label: 'Relatórios' },
]
</script>

<template>
  <nav class="sidebar">
    <div class="sidebar-logo">
      <span class="logo-mark">Finança</span>
    </div>

    <ul class="nav-list">
      <li v-for="item in navItems" :key="item.path">
        <RouterLink :to="item.path" :class="['nav-item', route.path === item.path && 'active']">
          <AppIcon :name="item.icon" :size="18" class="nav-icon" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </li>
    </ul>

    <div class="sidebar-footer">
      <div class="user-info" v-if="auth.user">
        <div class="user-avatar">{{ auth.user.name[0].toUpperCase() }}</div>
        <div class="user-details">
          <div class="user-name">{{ auth.user.name }}</div>
          <div class="user-email text-muted text-sm">{{ auth.user.email }}</div>
        </div>
      </div>
      <button class="btn btn-secondary btn-sm" @click="auth.logout()">
        <AppIcon name="logout" :size="14" />
        Sair
      </button>
    </div>
  </nav>
</template>

<style scoped>
.sidebar {
  width: 240px; min-height: 100vh; padding: 1.75rem 1rem;
  background: var(--bg-secondary); border-right: 1px solid var(--border-subtle);
  display: flex; flex-direction: column; gap: 2rem; flex-shrink: 0;
}
.sidebar-logo { padding: 0 0.75rem; margin-bottom: 0.5rem; }
.logo-mark { font-family: var(--font-serif); font-size: var(--font-size-lg); font-weight: 600; color: var(--text-primary); letter-spacing: 0.01em; }
.nav-list { list-style: none; display: flex; flex-direction: column; gap: 0.125rem; flex: 1; }
.nav-item {
  display: flex; align-items: center; gap: 0.75rem;
  padding: 0.625rem 0.875rem; border-radius: var(--radius-sm);
  color: var(--text-secondary); text-decoration: none;
  font-family: var(--font-sans); font-size: var(--font-size-sm); font-weight: 500;
  border-left: 2px solid transparent;
  transition: all var(--transition-fast);
}
.nav-item:hover { background: var(--bg-card-hover); color: var(--text-primary); }
.nav-item.active { background: var(--bg-card); color: var(--accent-primary); border-left-color: var(--accent-primary); }
.nav-icon { flex-shrink: 0; }
.sidebar-footer { display: flex; flex-direction: column; gap: 0.75rem; }
.user-info { display: flex; align-items: center; gap: 0.75rem; }
.user-avatar {
  width: 36px; height: 36px; border-radius: 50%; background: var(--accent-primary);
  color: #17130f; display: flex; align-items: center; justify-content: center;
  font-family: var(--font-serif); font-weight: 700; font-size: var(--font-size-sm); flex-shrink: 0;
}
.user-name { font-family: var(--font-sans); font-size: var(--font-size-sm); font-weight: 600; }
.user-details { overflow: hidden; }
.user-email { font-family: var(--font-sans); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
```

- [ ] **Step 2: Verificar visualmente no browser**

Navegar pelo app autenticado, confirmar: sidebar mostra "Finança" em serifada, ícones SVG monoline em vez de emoji, item de rota ativa tem borda esquerda terracota (não fundo colorido cheio).

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/components/layout/AppSidebar.vue
git commit -m "feat(design): sidebar com AppIcon e indicador de rota ativa por borda lateral"
```

---

### Task 8: Ícones restantes (Planos, Simulador, empty states)

**Files:**
- Modify: `frontend/src/views/PlansView.vue`
- Modify: `frontend/src/components/plans/PlanSimulator.vue`

**Interfaces:**
- Consumes: `AppIcon` (Task 2).
- Produces: nenhuma interface nova.

- [ ] **Step 1: Trocar o emoji do empty state em `PlansView.vue`**

Em `frontend/src/views/PlansView.vue`, adicione o import no topo do `<script setup>`:

```js
import AppIcon from '@/components/common/AppIcon.vue'
```

E troque este trecho do template:

```html
    <div v-else-if="!store.plans.length" class="card" style="text-align:center;padding:3rem">
      <div style="font-size:3rem;margin-bottom:1rem">🎯</div>
      <p class="text-muted">Nenhum plano criado ainda. Crie seu primeiro objetivo!</p>
    </div>
```

por:

```html
    <div v-else-if="!store.plans.length" class="card" style="text-align:center;padding:3rem">
      <AppIcon name="target" :size="40" style="color: var(--accent-primary); margin-bottom: 1rem" />
      <p class="text-muted">Nenhum plano criado ainda. Crie seu primeiro objetivo!</p>
    </div>
```

- [ ] **Step 2: Trocar o emoji do título em `PlanSimulator.vue`**

Em `frontend/src/components/plans/PlanSimulator.vue`, adicione o import:

```js
import AppIcon from '@/components/common/AppIcon.vue'
```

E troque:

```html
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem">🧮 Simulador interativo</div>
```

por:

```html
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem; display:flex; align-items:center; gap:0.5rem">
      <AppIcon name="calculator" :size="16" style="color: var(--accent-primary)" />
      Simulador interativo
    </div>
```

- [ ] **Step 3: Verificar visualmente no browser**

Navegar até `/plans`: criar zero planos (ou usar conta nova) para ver o empty state com o ícone `target` SVG; abrir um plano ativo para ver o simulador com o ícone `calculator` SVG. Nenhum emoji deve restar nessas duas telas.

- [ ] **Step 4: Commit**

```bash
cd frontend
git add src/views/PlansView.vue src/components/plans/PlanSimulator.vue
git commit -m "feat(design): troca emojis restantes por AppIcon em Planos e Simulador"
```

---

### Task 9: Verificação final end-to-end

**Files:**
- Nenhum arquivo novo — apenas verificação manual via Chrome automation.

**Interfaces:**
- Consumes: todas as tasks anteriores.
- Produces: nada (task de verificação).

- [ ] **Step 1: Rebuild e subir o ambiente completo**

```bash
docker compose up -d --build
```

Expected: backend e frontend sobem sem erro, `docker compose ps` mostra ambos `Up`.

- [ ] **Step 2: Percorrer o fluxo completo no browser**

Usando o Chrome automation (ou manualmente):
1. Acessar `http://localhost:5173/login` — confirmar cartão editorial, sem emoji, fonte serifada no título.
2. Criar uma conta nova (ou logar com uma existente) — confirmar que **login com senha errada mostra mensagem de erro sem recarregar a página** (regressão do bug corrigido antes deste plano).
3. No Dashboard: confirmar que o anel de progresso anima do 0 até o valor real ao carregar, o saldo aparece grande em serifada ao lado do anel, os 3 stat cards abaixo usam ícones SVG, a timeline revela os itens em sequência (não todos de uma vez).
4. Navegar por Transações, Renda, Planos, Relatórios — confirmar que todas usam a nova paleta (fundo grafite, acento terracota, sem roxo/indigo, sem glassmorphism/blur visível).
5. Testar em uma tela estreita (mobile) que o hero do dashboard empilha verticalmente (min-width 768px breakpoint já existente).

- [ ] **Step 3: Checar console do browser por erros**

Usando `read_console_messages` (Chrome automation) com `onlyErrors: true` em cada tela visitada — nenhum erro de JS deve aparecer (nomes de ícone inválidos em `AppIcon`, por exemplo, não geram erro mas renderizam vazio; confirmar visualmente que todo ícone esperado aparece).

- [ ] **Step 4: Rodar build de produção uma última vez**

```bash
cd frontend && npm run build
```

Expected: build succeeds sem warnings novos.

- [ ] **Step 5: Commit final (se houver ajustes desta verificação)**

Se a verificação não encontrar nada para corrigir, não é necessário commit nesta task — as Tasks 1-8 já cobrem todo o código. Se algum ajuste pontual for necessário durante a verificação, commitar separadamente com mensagem descritiva do que foi ajustado.
