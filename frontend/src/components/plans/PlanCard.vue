<script setup>
import { ref } from 'vue'
import { usePlansStore } from '@/stores/plans'

const props = defineProps({ plan: Object })
const emit = defineEmits(['refresh'])
const store = usePlansStore()

const showContrib = ref(false)
const contribAmount = ref('')
const contribDate = ref(new Date().toISOString().slice(0, 10))

const statusLabels = { active: 'Ativo', paused: 'Pausado', cancelled: 'Cancelado', completed: 'Concluído' }
const statusVariants = { active: 'badge-success', paused: 'badge-warning', cancelled: 'badge-danger', completed: 'badge-info' }

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

async function submitContrib() {
  await store.addContribution(props.plan.id, {
    amount: parseFloat(contribAmount.value),
    date: contribDate.value,
  })
  showContrib.value = false
  contribAmount.value = ''
  emit('refresh')
}

async function remove() {
  if (!confirm(`Deletar plano "${props.plan.name}"?`)) return
  await store.deletePlan(props.plan.id)
  emit('refresh')
}

async function toggleStatus(status) {
  await store.updatePlan(props.plan.id, { status })
  emit('refresh')
}
</script>

<template>
  <div class="card plan-card">
    <div class="plan-header">
      <div>
        <h3 class="font-semibold">{{ plan.name }}</h3>
        <span :class="['badge', statusVariants[plan.status]]">{{ statusLabels[plan.status] }}</span>
      </div>
      <div class="plan-actions">
        <button v-if="plan.status === 'active'" class="btn btn-secondary btn-sm" @click="toggleStatus('paused')">Pausar</button>
        <button v-if="plan.status === 'paused'" class="btn btn-secondary btn-sm" @click="toggleStatus('active')">Retomar</button>
        <button class="btn btn-danger btn-sm" @click="remove">Excluir</button>
      </div>
    </div>

    <div class="plan-amounts">
      <div>
        <div class="text-muted text-sm">Guardado</div>
        <div class="font-bold text-success">{{ formatCurrency(plan.current_savings) }}</div>
      </div>
      <div>
        <div class="text-muted text-sm">Meta</div>
        <div class="font-bold">{{ formatCurrency(plan.target_amount) }}</div>
      </div>
      <div v-if="plan.simulation">
        <div class="text-muted text-sm">Faltam</div>
        <div class="font-bold">
          {{ plan.simulation.months_to_goal != null ? `${plan.simulation.months_to_goal} meses` : '∞' }}
        </div>
      </div>
    </div>

    <div class="progress-bar" style="margin:0.75rem 0">
      <div class="progress-fill" :style="{ width: `${plan.simulation?.progress_percent || 0}%` }" />
    </div>
    <div class="text-muted text-sm" style="text-align:right">{{ (plan.simulation?.progress_percent || 0).toFixed(1) }}% concluído</div>

    <!-- Sub-planos -->
    <div v-if="plan.sub_plans?.length" class="sub-plans">
      <div class="text-muted text-sm font-semibold" style="margin-bottom:0.5rem">Sub-planos</div>
      <div v-for="sub in plan.sub_plans" :key="sub.id" class="sub-plan-item">
        <span>{{ sub.name }}</span>
        <span class="text-muted text-sm">{{ formatCurrency(sub.current_savings) }} / {{ formatCurrency(sub.target_amount) }}</span>
      </div>
    </div>

    <!-- Aporte -->
    <div style="margin-top:1rem">
      <button class="btn btn-secondary btn-sm" @click="showContrib = !showContrib">+ Registrar aporte</button>
      <form v-if="showContrib" @submit.prevent="submitContrib" style="margin-top:0.75rem;display:flex;gap:0.75rem;align-items:flex-end">
        <div class="form-group" style="flex:1">
          <label class="form-label">Valor (R$)</label>
          <input v-model="contribAmount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="contribDate" class="form-input" type="date" required />
        </div>
        <button type="submit" class="btn btn-primary btn-sm">Salvar</button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.plan-card { display: flex; flex-direction: column; gap: 0.5rem; }
.plan-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.75rem; }
.plan-actions { display: flex; gap: 0.5rem; }
.plan-amounts { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
.sub-plans { margin-top: 0.5rem; padding-top: 0.75rem; border-top: 1px solid var(--border-subtle); }
.sub-plan-item { display: flex; justify-content: space-between; padding: 0.375rem 0; font-size: var(--font-size-sm); }
</style>
