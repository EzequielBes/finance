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

<style scoped>
.sim-result { display: flex; gap: 2rem; margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid var(--border-subtle); }
.slider { width: 100%; accent-color: var(--accent-primary); }
</style>
