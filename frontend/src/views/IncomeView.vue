<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useIncomeStore } from '@/stores/income'

const store = useIncomeStore()
const showForm = ref(false)
const form = ref({ amount: '', date: new Date().toISOString().slice(0, 10), source: '', is_recurring: false, recurrence_period: null, notes: '' })
const error = ref('')

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}

async function submit() {
  error.value = ''
  try {
    await store.createIncome({ ...form.value, amount: parseFloat(form.value.amount) })
    showForm.value = false
    form.value = { amount: '', date: new Date().toISOString().slice(0, 10), source: '', is_recurring: false, recurrence_period: null, notes: '' }
    await store.fetchIncome()
    await store.fetchSummary()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

async function remove(id) {
  if (!confirm('Deletar entrada de renda?')) return
  await store.deleteIncome(id)
  await store.fetchIncome()
  await store.fetchSummary()
}

onMounted(async () => {
  await store.fetchIncome()
  await store.fetchSummary()
})
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Renda</h1>
        <p class="page-subtitle">Gerencie suas fontes de receita</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Nova entrada</button>
    </div>

    <!-- Resumo de renda -->
    <div class="grid-2" style="margin-bottom:1.5rem" v-if="store.summary">
      <div class="card">
        <div class="text-muted text-sm">Média últimos 3 meses</div>
        <div class="font-bold text-success" style="font-size:var(--font-size-2xl)">{{ formatCurrency(store.summary.average_last_3_months) }}</div>
      </div>
      <div class="card">
        <div class="text-muted text-sm">Total este mês</div>
        <div class="font-bold" style="font-size:var(--font-size-2xl)">{{ formatCurrency(store.summary.total_this_month) }}</div>
      </div>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Nova entrada de renda</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group">
          <label class="form-label">Valor (R$)</label>
          <input v-model="form.amount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="form.date" class="form-input" type="date" required />
        </div>
        <div class="form-group">
          <label class="form-label">Fonte</label>
          <input v-model="form.source" class="form-input" required placeholder="Salário, Freela..." />
        </div>
        <div class="form-group">
          <label class="form-label">Recorrente?</label>
          <select v-model="form.is_recurring" class="form-input">
            <option :value="false">Não</option>
            <option :value="true">Sim</option>
          </select>
        </div>
        <div class="form-group" v-if="form.is_recurring">
          <label class="form-label">Período</label>
          <select v-model="form.recurrence_period" class="form-input">
            <option value="monthly">Mensal</option>
            <option value="weekly">Semanal</option>
            <option value="yearly">Anual</option>
          </select>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Observações</label>
          <input v-model="form.notes" class="form-input" placeholder="Opcional" />
        </div>
        <div v-if="error" class="error-msg" style="grid-column:1/-1">{{ error }}</div>
        <div style="grid-column:1/-1;display:flex;gap:0.75rem">
          <button type="submit" class="btn btn-primary">Salvar</button>
          <button type="button" class="btn btn-secondary" @click="showForm = false">Cancelar</button>
        </div>
      </form>
    </div>

    <!-- Lista -->
    <div class="card">
      <div v-if="!store.entries.length" style="text-align:center;padding:2rem;color:var(--text-muted)">Nenhuma entrada registrada.</div>
      <table v-else class="tx-table">
        <thead><tr><th>Fonte</th><th>Data</th><th>Valor</th><th>Tipo</th><th></th></tr></thead>
        <tbody>
          <tr v-for="entry in store.entries" :key="entry.id">
            <td>{{ entry.source }}</td>
            <td class="text-muted">{{ formatDate(entry.date) }}</td>
            <td class="text-success font-semibold">{{ formatCurrency(entry.amount) }}</td>
            <td><span :class="['badge', entry.is_recurring ? 'badge-info' : 'badge-warning']">{{ entry.is_recurring ? 'Recorrente' : 'Pontual' }}</span></td>
            <td><button class="btn btn-danger btn-sm" @click="remove(entry.id)">Excluir</button></td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppLayout>
</template>

<style scoped>
.tx-table { width: 100%; border-collapse: collapse; }
.tx-table th { text-align: left; padding: 0.5rem 0.75rem; font-size: var(--font-size-xs); color: var(--text-muted); font-weight: 600; border-bottom: 1px solid var(--border-subtle); }
.tx-table td { padding: 0.75rem; border-bottom: 1px solid var(--border-subtle); font-size: var(--font-size-sm); }
.tx-table tr:last-child td { border-bottom: none; }
</style>
