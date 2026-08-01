<script setup>
import { ref, watch, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useTransactionsStore } from '@/stores/transactions'

const store = useTransactionsStore()
const showForm = ref(false)
const showCategoryForm = ref(false)

const form = ref({
  description: '', amount: '', date: new Date().toISOString().slice(0, 10),
  type: 'expense', category_id: null, is_recurring: false,
  recurrence_period: null, installments_total: null
})
const categoryForm = ref({
  name: '',
  type: 'expense',
  color: '#c17a54'
})
const error = ref('')
const categoryError = ref('')

watch(() => form.value.is_recurring, (isRecurring) => {
  if (isRecurring) {
    form.value.installments_total = null
  }
})

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}

async function submit() {
  error.value = ''
  try {
    const payload = {
      ...form.value,
      amount: parseFloat(form.value.amount),
      installments_total: form.value.installments_total ? parseInt(form.value.installments_total) : null,
    }
    await store.createTransaction(payload)
    showForm.value = false
    form.value = { description: '', amount: '', date: new Date().toISOString().slice(0, 10), type: 'expense', category_id: null, is_recurring: false, recurrence_period: null, installments_total: null }
    await store.fetchTransactions()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

async function submitCategory() {
  categoryError.value = ''
  try {
    const newCategory = await store.createCategory({
      name: categoryForm.value.name,
      type: categoryForm.value.type,
      color: categoryForm.value.color
    })
    form.value.category_id = newCategory.id
    showCategoryForm.value = false
    categoryForm.value = {
      name: '',
      type: 'expense',
      color: '#c17a54'
    }
  } catch (e) {
    categoryError.value = e.response?.data?.detail || 'Erro ao criar categoria'
  }
}

async function remove(id) {
  if (!confirm('Deletar transação?')) return
  await store.deleteTransaction(id)
  await store.fetchTransactions()
}

onMounted(async () => {
  await store.fetchCategories()
  await store.fetchTransactions()
})
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Transações</h1>
        <p class="page-subtitle">{{ store.total }} transação(ões) registradas</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Nova transação</button>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Nova transação</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Descrição</label>
          <input v-model="form.description" class="form-input" required placeholder="Ex: Conta de luz" />
        </div>
        <div class="form-group">
          <label class="form-label">Valor (R$)</label>
          <input v-model="form.amount" class="form-input" type="number" step="0.01" required placeholder="0,00" />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="form.date" class="form-input" type="date" required />
        </div>
        <div class="form-group">
          <label class="form-label">Tipo</label>
          <select v-model="form.type" class="form-input">
            <option value="expense">Gasto</option>
            <option value="income">Receita</option>
          </select>
        </div>
        <div class="form-group">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.5rem">
            <label class="form-label">Categoria</label>
            <button type="button" class="btn btn-secondary btn-sm" @click="showCategoryForm = !showCategoryForm">
              {{ showCategoryForm ? '✕' : '+ Nova' }}
            </button>
          </div>
          <select v-model="form.category_id" class="form-input">
            <option :value="null">Sem categoria</option>
            <option v-for="cat in store.categories.filter(c => c.type === form.type)" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
          </select>
          <!-- Mini formulário de categoria -->
          <div v-if="showCategoryForm" style="margin-top:0.75rem;padding:0.75rem;background:var(--bg-input);border-radius:var(--radius-sm);border:1px solid var(--border-subtle)">
            <div class="form-group" style="margin-bottom:0.75rem">
              <label class="form-label">Nome da categoria</label>
              <input v-model="categoryForm.name" class="form-input" type="text" required placeholder="Ex: Energia" />
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.75rem">
              <div class="form-group" style="margin-bottom:0">
                <label class="form-label">Tipo</label>
                <select v-model="categoryForm.type" class="form-input">
                  <option value="expense">Gasto</option>
                  <option value="income">Receita</option>
                </select>
              </div>
              <div class="form-group" style="margin-bottom:0">
                <label class="form-label">Cor</label>
                <input v-model="categoryForm.color" class="form-input" type="color" />
              </div>
            </div>
            <div v-if="categoryError" class="error-msg" style="margin-top:0.75rem">{{ categoryError }}</div>
            <div style="display:flex;gap:0.5rem;margin-top:0.75rem">
              <button type="button" class="btn btn-primary btn-sm" @click="submitCategory">Criar</button>
              <button type="button" class="btn btn-secondary btn-sm" @click="showCategoryForm = false">Cancelar</button>
            </div>
          </div>
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
        <div class="form-group" v-if="!form.is_recurring">
          <label class="form-label">Parcelas (1 = sem parcelamento)</label>
          <input v-model="form.installments_total" class="form-input" type="number" min="1" max="60" placeholder="1" />
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
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">Nenhuma transação encontrada.</div>
      <table v-else class="tx-table">
        <thead>
          <tr>
            <th>Descrição</th><th>Data</th><th>Tipo</th><th>Valor</th><th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="tx in store.items" :key="tx.id">
            <td>
              {{ tx.description }}
              <span v-if="tx.installments_total" class="badge badge-info" style="margin-left:0.5rem">
                {{ tx.installments_current }}/{{ tx.installments_total }}
              </span>
              <span v-if="tx.is_recurring" class="badge badge-warning" style="margin-left:0.5rem">Recorrente</span>
            </td>
            <td class="text-muted">{{ formatDate(tx.date) }}</td>
            <td>
              <span :class="['badge', tx.type === 'income' ? 'badge-success' : 'badge-danger']">
                {{ tx.type === 'income' ? 'Receita' : 'Gasto' }}
              </span>
            </td>
            <td :class="tx.type === 'income' ? 'text-success' : 'text-danger'" class="font-semibold">
              {{ tx.type === 'income' ? '+' : '-' }}{{ formatCurrency(tx.amount) }}
            </td>
            <td>
              <button class="btn btn-danger btn-sm" @click="remove(tx.id)">Excluir</button>
            </td>
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
