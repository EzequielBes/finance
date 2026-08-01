<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import PlanCard from '@/components/plans/PlanCard.vue'
import PlanSimulator from '@/components/plans/PlanSimulator.vue'
import AppIcon from '@/components/common/AppIcon.vue'
import { usePlansStore } from '@/stores/plans'

const store = usePlansStore()
const showForm = ref(false)
const form = ref({
  name: '', description: '', target_amount: '', current_savings: '0',
  monthly_contribution: '', deadline: null, priority: 1, parent_plan_id: null
})
const error = ref('')

async function submit() {
  error.value = ''
  try {
    await store.createPlan({
      ...form.value,
      target_amount: parseFloat(form.value.target_amount),
      current_savings: parseFloat(form.value.current_savings || 0),
      monthly_contribution: parseFloat(form.value.monthly_contribution),
      parent_plan_id: form.value.parent_plan_id ? parseInt(form.value.parent_plan_id) : null,
      deadline: form.value.deadline || null,
    })
    showForm.value = false
    form.value = { name: '', description: '', target_amount: '', current_savings: '0', monthly_contribution: '', deadline: null, priority: 1, parent_plan_id: null }
    await store.fetchPlans()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

onMounted(store.fetchPlans)
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Planos</h1>
        <p class="page-subtitle">Seus objetivos financeiros</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Novo plano</button>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Novo plano</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Nome do plano</label>
          <input v-model="form.name" class="form-input" required placeholder="Ex: Viagem ao Japão" />
        </div>
        <div class="form-group">
          <label class="form-label">Valor alvo (R$)</label>
          <input v-model="form.target_amount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Já guardado (R$)</label>
          <input v-model="form.current_savings" class="form-input" type="number" step="0.01" />
        </div>
        <div class="form-group">
          <label class="form-label">Contribuição mensal (R$)</label>
          <input v-model="form.monthly_contribution" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Prazo máximo (opcional)</label>
          <input v-model="form.deadline" class="form-input" type="date" />
        </div>
        <div class="form-group">
          <label class="form-label">Plano pai (sub-plano de...)</label>
          <select v-model="form.parent_plan_id" class="form-input">
            <option :value="null">Nenhum (plano raiz)</option>
            <option v-for="p in store.plans.filter(p => !p.parent_plan_id)" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Descrição</label>
          <input v-model="form.description" class="form-input" placeholder="Opcional" />
        </div>
        <div v-if="error" class="error-msg" style="grid-column:1/-1">{{ error }}</div>
        <div style="grid-column:1/-1;display:flex;gap:0.75rem">
          <button type="submit" class="btn btn-primary">Criar plano</button>
          <button type="button" class="btn btn-secondary" @click="showForm = false">Cancelar</button>
        </div>
      </form>
    </div>

    <!-- Lista de planos -->
    <div v-if="store.loading" class="grid-2">
      <div v-for="i in 3" :key="i" class="skeleton" style="height:200px;border-radius:var(--radius-lg)" />
    </div>
    <div v-else-if="!store.plans.length" class="card" style="text-align:center;padding:3rem">
      <AppIcon name="target" :size="40" style="color: var(--accent-primary); margin-bottom: 1rem" />
      <p class="text-muted">Nenhum plano criado ainda. Crie seu primeiro objetivo!</p>
    </div>
    <div v-else class="grid-2">
      <div v-for="plan in store.plans" :key="plan.id">
        <PlanCard :plan="plan" @refresh="store.fetchPlans()" />
        <PlanSimulator v-if="plan.status === 'active'" :plan="plan" />
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
</style>
