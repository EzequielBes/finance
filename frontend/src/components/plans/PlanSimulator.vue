<script setup>
import { ref, watch } from 'vue'
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
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem">🧮 Simulador interativo</div>
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
