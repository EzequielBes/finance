# Plano de Economia (dentro de Planos) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a savings-plan section to `PlanSimulator.vue` that lets the user drag per-category cut sliders (built from cuttable categories in the savings analysis) and see the recalculated payoff timeline for the plan, live.

**Architecture:** Frontend-only. `PlanSimulator.vue` fetches `useReportsStore().fetchSavingsAnalysis()` on mount, filters to `is_essential === false`, and renders one slider per cuttable category. A computed total (`Σ percent_i/100 * current_amount_i`) is added to `plan.monthly_contribution` and fed into the existing `usePlansStore().simulate(planId, monthlyContribution)` call (debounced 400ms, mirroring the existing contribution simulator in the same file). The result is rendered with the same `.sim-result` markup pattern already in the file, plus a "you save N months" line computed against `plan.simulation.months_to_goal` (the plan's original simulation, already passed in via props — no extra fetch).

**Tech Stack:** Vue 3 Composition API (`<script setup>`), Pinia stores (`useReportsStore`, `usePlansStore`), no new backend code.

## Global Constraints

- No new backend endpoint — reuse `GET /reports/savings-analysis` and `GET /plans/{plan_id}/simulate?monthly_contribution=X` exactly as they exist today.
- Only cuttable (non-essential) categories appear — filter strictly on `item.is_essential === false`. The 80%-of-reference threshold is already enforced server-side in `build_savings_analysis`; the frontend does no additional percent filtering.
- If the filtered list is empty, the entire new section does not render.
- No persistence of the savings plan or slider state — it's a live "what-if" only, sliders always start at 0%, nothing is written back to the plan.
- No commit in this repo may include a `Co-Authored-By` trailer of any kind.

---

### Task 1: Savings plan section in PlanSimulator.vue

**Files:**
- Modify: `frontend/src/components/plans/PlanSimulator.vue`

**Interfaces:**
- Consumes:
  - `useReportsStore()` → `{ items, loading, fetchSavingsAnalysis() }` (`frontend/src/stores/reports.js`). `items` is `SavingsAnalysisItem[]`: `{ category_id, category_name, category_color, is_essential, current_amount, reference_amount, reference_source, percent, suggested_cut }`.
  - `usePlansStore()` → `simulate(planId, monthlyContribution)` (`frontend/src/stores/plans.js:37-42`), returns `{ months_to_goal: number|null, estimated_date: string|null, ... }` (same shape as `props.plan.simulation`, already consumed at `PlanSimulator.vue:44-48`).
  - `props.plan` — already has `.id`, `.monthly_contribution`, `.target_amount`, `.simulation` (original simulation result, with `.months_to_goal`).
- Produces: nothing consumed by later tasks — this is the only task.

This is a single self-contained UI task (one file, one cohesive feature) — no need to split further since there's no other file to coordinate with and the piece can't be tested in isolation from its own rendering.

- [ ] **Step 1: Read the current file to confirm line anchors are unchanged**

Run: view `frontend/src/components/plans/PlanSimulator.vue` — confirm it still matches this baseline (script block ends at line 25, template block spans 27-52, style block spans 54-57):

```vue
<script setup>
import { ref, watch } from 'vue'
import AppIcon from '@/components/common/AppIcon.vue'
import { usePlansStore } from '@/stores/plans'

const props = defineProps({ plan: Object })
const store = usePlansStore()

const contribution = ref(props.plan.monthly_contribution)
const result = ref(props.plan.simulation)
let debounceTimer = null

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

watch(contribution, async (newVal) => {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(async () => {
    if (newVal > 0) {
      result.value = await store.simulate(props.plan.id, newVal)
    }
  }, 400)
})
</script>

<template>
  <div class="simulator card" style="margin-top:0.75rem">
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem; display:flex; align-items:center; gap:0.5rem">
      <AppIcon name="calculator" :size="16" style="color: var(--accent-primary)" />
      Simulador interativo
    </div>
    <div class="form-group">
      <label class="form-label">Contribuição mensal: {{ formatCurrency(contribution) }}</label>
      <input
        v-model.number="contribution" type="range"
        :min="100" :max="plan.target_amount" :step="50"
        class="slider"
      />
    </div>
    <div v-if="result" class="sim-result">
      <div>
        <div class="text-muted" style="font-size:0.7rem">Prazo</div>
        <div class="font-bold">{{ result.months_to_goal != null ? `${result.months_to_goal} meses` : 'Indefinido' }}</div>
      </div>
      <div v-if="result.estimated_date">
        <div class="text-muted" style="font-size:0.7rem">Data estimada</div>
        <div class="font-bold">{{ new Date(result.estimated_date + 'T00:00:00').toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }) }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.sim-result { display: flex; gap: 2rem; margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid var(--border-subtle); }
.slider { width: 100%; accent-color: var(--accent-primary); }
</style>
```

If the file differs from this baseline, stop and re-read it fully before proceeding — the edits below assume this exact structure.

- [ ] **Step 2: Replace the `<script setup>` block**

Replace the entire `<script setup>...</script>` block with:

```vue
<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import AppIcon from '@/components/common/AppIcon.vue'
import { usePlansStore } from '@/stores/plans'
import { useReportsStore } from '@/stores/reports'

const props = defineProps({ plan: Object })
const store = usePlansStore()
const reportsStore = useReportsStore()

const contribution = ref(props.plan.monthly_contribution)
const result = ref(props.plan.simulation)
let debounceTimer = null

const cuttableCategories = ref([])
const cutPercents = ref({})
const savingsResult = ref(null)
let savingsDebounceTimer = null

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

watch(contribution, async (newVal) => {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(async () => {
    if (newVal > 0) {
      result.value = await store.simulate(props.plan.id, newVal)
    }
  }, 400)
})

const categoryCut = (categoryId) => {
  const category = cuttableCategories.value.find((c) => c.category_id === categoryId)
  const percent = cutPercents.value[categoryId] || 0
  return category ? (percent / 100) * category.current_amount : 0
}

const totalExtraSavings = computed(() =>
  cuttableCategories.value.reduce((sum, c) => sum + categoryCut(c.category_id), 0)
)

const monthsSaved = computed(() => {
  if (!savingsResult.value || savingsResult.value.months_to_goal == null) return null
  const original = props.plan.simulation?.months_to_goal
  if (original == null) return null
  const diff = original - savingsResult.value.months_to_goal
  return diff > 0 ? diff : null
})

watch(cutPercents, () => {
  clearTimeout(savingsDebounceTimer)
  savingsDebounceTimer = setTimeout(async () => {
    const newContribution = props.plan.monthly_contribution + totalExtraSavings.value
    savingsResult.value = await store.simulate(props.plan.id, newContribution)
  }, 400)
}, { deep: true })

onMounted(async () => {
  await reportsStore.fetchSavingsAnalysis()
  cuttableCategories.value = reportsStore.items.filter((item) => !item.is_essential)
  for (const category of cuttableCategories.value) {
    cutPercents.value[category.category_id] = 0
  }
})
</script>
```

- [ ] **Step 3: Replace the `<template>` block**

Replace the entire `<template>...</template>` block with:

```vue
<template>
  <div class="simulator card" style="margin-top:0.75rem">
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem; display:flex; align-items:center; gap:0.5rem">
      <AppIcon name="calculator" :size="16" style="color: var(--accent-primary)" />
      Simulador interativo
    </div>
    <div class="form-group">
      <label class="form-label">Contribuição mensal: {{ formatCurrency(contribution) }}</label>
      <input
        v-model.number="contribution" type="range"
        :min="100" :max="plan.target_amount" :step="50"
        class="slider"
      />
    </div>
    <div v-if="result" class="sim-result">
      <div>
        <div class="text-muted" style="font-size:0.7rem">Prazo</div>
        <div class="font-bold">{{ result.months_to_goal != null ? `${result.months_to_goal} meses` : 'Indefinido' }}</div>
      </div>
      <div v-if="result.estimated_date">
        <div class="text-muted" style="font-size:0.7rem">Data estimada</div>
        <div class="font-bold">{{ new Date(result.estimated_date + 'T00:00:00').toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }) }}</div>
      </div>
    </div>
  </div>

  <div v-if="cuttableCategories.length" class="simulator card savings-plan" style="margin-top:0.75rem">
    <div class="font-semibold text-sm" style="margin-bottom:0.5rem; display:flex; align-items:center; gap:0.5rem">
      <AppIcon name="trending-up" :size="16" style="color: var(--accent-primary)" />
      Plano de economia
    </div>
    <p class="text-muted text-sm" style="margin-bottom:1rem">
      Você tem gastos que podem ser economizados. Monte um plano de economia e veja quanto tempo pode ganhar para bater a meta.
    </p>

    <div v-for="category in cuttableCategories" :key="category.category_id" class="form-group">
      <label class="form-label">
        {{ category.category_name }} — {{ formatCurrency(category.current_amount) }}
        <span class="text-muted">(economizar {{ formatCurrency(categoryCut(category.category_id)) }})</span>
      </label>
      <input
        v-model.number="cutPercents[category.category_id]" type="range"
        :min="0" :max="100" :step="5"
        class="slider"
      />
    </div>

    <div class="text-sm" style="margin:0.75rem 0">
      Economia extra mensal: <span class="font-bold">{{ formatCurrency(totalExtraSavings) }}</span>
    </div>

    <div v-if="savingsResult" class="sim-result">
      <div>
        <div class="text-muted" style="font-size:0.7rem">Novo prazo</div>
        <div class="font-bold">{{ savingsResult.months_to_goal != null ? `${savingsResult.months_to_goal} meses` : 'Indefinido' }}</div>
      </div>
      <div v-if="savingsResult.estimated_date">
        <div class="text-muted" style="font-size:0.7rem">Nova data estimada</div>
        <div class="font-bold">{{ new Date(savingsResult.estimated_date + 'T00:00:00').toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }) }}</div>
      </div>
      <div v-if="monthsSaved">
        <div class="text-muted" style="font-size:0.7rem">Você economiza</div>
        <div class="font-bold" style="color: var(--accent-success)">{{ monthsSaved }} {{ monthsSaved === 1 ? 'mês' : 'meses' }}</div>
      </div>
    </div>
  </div>
</template>
```

- [ ] **Step 4: Leave the `<style scoped>` block unchanged**

The existing `.sim-result` and `.slider` rules already cover the new markup (same class names reused). No new CSS is required.

- [ ] **Step 5: Start the dev stack and verify manually in the browser**

Run: `docker compose -p analisadorfinanceiro up -d --build` (or the project's existing dev-start command if different — check `docker-compose.yml` at repo root first). Then, using Chrome browser automation:

1. Log in, navigate to a Plan that has a linked user with cuttable categories showing at ≥80% usage in `/reports/savings-analysis` (seed test data first if needed: create expense transactions in a non-essential category, e.g. "Lazer", exceeding its `monthly_limit` or 3-month average).
2. Confirm the "Plano de economia" card appears below the existing simulator, listing only non-essential categories from the savings analysis.
3. Drag one category's slider and confirm: (a) the "(economizar R$ X)" label updates immediately, (b) "Economia extra mensal" updates immediately, (c) after ~400ms the "Novo prazo" / "Nova data estimada" block updates.
4. Confirm "Você economiza N meses" only appears when the new `months_to_goal` is strictly less than `plan.simulation.months_to_goal`; drag all sliders back to 0 and confirm the line disappears (or shows the original unchanged timeline with no savings line).
5. Navigate to (or set up) a Plan/user where `/reports/savings-analysis` returns zero non-essential entries. Confirm the entire "Plano de economia" card does not render.
6. Check the browser console for errors during all of the above.

Fix any issues found before proceeding. Report explicitly if browser verification could not be performed (e.g., no environment available) rather than claiming success without it.

- [ ] **Step 6: Commit**

```bash
git add frontend/src/components/plans/PlanSimulator.vue
git commit -m "feat(plans): add savings plan section to plan simulator"
```

Do not include a `Co-Authored-By` trailer in this commit.
