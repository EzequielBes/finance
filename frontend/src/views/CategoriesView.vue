<script setup>
import { ref, computed, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useCategoriesStore } from '@/stores/categories'

const store = useCategoriesStore()

const budgetedCategories = computed(() =>
  store.items.filter((c) => c.type === 'expense' && c.monthly_limit != null && c.monthly_limit > 0)
)

function usagePercent(cat) {
  return Math.round((cat.current_month_usage / cat.monthly_limit) * 100)
}

function usageColorClass(percent) {
  if (percent > 100) return 'usage-over'
  if (percent >= 80) return 'usage-warning'
  return 'usage-ok'
}

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

const editingCategory = ref(null)
const editForm = ref({ name: '', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: '' })
const editError = ref('')
const seeding = ref(false)
const pageError = ref('')

function openEdit(category) {
  editingCategory.value = category
  editForm.value = {
    name: category.name,
    type: category.type,
    color: category.color,
    icon: category.icon,
    monthly_limit: category.monthly_limit != null ? String(category.monthly_limit) : '',
  }
  editError.value = ''
}

function closeEdit() {
  editingCategory.value = null
}

async function saveEdit() {
  editError.value = ''
  try {
    const payload = {
      name: editForm.value.name,
      type: editForm.value.type,
      color: editForm.value.color,
      icon: editForm.value.icon,
      monthly_limit: editForm.value.type === 'expense' && editForm.value.monthly_limit
        ? parseFloat(editForm.value.monthly_limit)
        : null,
    }
    await store.updateCategory(editingCategory.value.id, payload)
    closeEdit()
  } catch (e) {
    editError.value = e.response?.data?.detail || 'Erro ao salvar categoria'
  }
}

async function handleSeed() {
  seeding.value = true
  pageError.value = ''
  try {
    await store.seedDefaults()
  } catch (e) {
    pageError.value = e.response?.data?.detail || 'Erro ao adicionar categorias padrão'
  } finally {
    seeding.value = false
  }
}

onMounted(async () => {
  try {
    await store.fetchCategories()
  } catch (e) {
    pageError.value = 'Erro ao carregar categorias. Tente recarregar a página.'
  }
})
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Categorias</h1>
        <p class="page-subtitle">Gerencie suas categorias e limites de gasto mensal</p>
      </div>
      <button class="btn btn-secondary" @click="handleSeed" :disabled="seeding">
        {{ seeding ? 'Adicionando...' : '+ Usar categorias padrão' }}
      </button>
    </div>

    <div v-if="pageError" class="error-msg" style="margin-bottom:1.5rem">{{ pageError }}</div>

    <div class="card" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Todas as categorias</h3>
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria cadastrada. Use o botão acima para começar com sugestões prontas.
      </div>
      <table v-else class="cat-table">
        <thead>
          <tr><th>Nome</th><th>Tipo</th><th>Limite mensal</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="cat in store.items" :key="cat.id" class="cat-row" @click="openEdit(cat)">
            <td>
              <span class="cat-color-dot" :style="{ background: cat.color }" />
              {{ cat.name }}
            </td>
            <td>
              <span :class="['badge', cat.type === 'income' ? 'badge-success' : 'badge-info']">
                {{ cat.type === 'income' ? 'Receita' : 'Gasto' }}
              </span>
            </td>
            <td class="text-muted">
              {{ cat.type === 'expense' && cat.monthly_limit != null
                  ? new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cat.monthly_limit)
                  : '—' }}
            </td>
            <td class="text-muted text-sm">Editar</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="card">
      <h3 class="font-semibold" style="margin-bottom:1rem">Orçamento do mês</h3>
      <div v-if="!budgetedCategories.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria com limite definido ainda. Clique em uma categoria de gasto acima para definir um limite mensal.
      </div>
      <div v-else class="budget-grid">
        <div v-for="cat in budgetedCategories" :key="cat.id" class="budget-card">
          <div class="budget-header">
            <span class="cat-color-dot" :style="{ background: cat.color }" />
            <span class="font-semibold text-sm">{{ cat.name }}</span>
          </div>
          <div class="progress-bar" style="margin:0.5rem 0">
            <div
              :class="['progress-fill', usageColorClass(usagePercent(cat))]"
              :style="{ width: Math.min(usagePercent(cat), 100) + '%' }"
            />
          </div>
          <div class="budget-footer text-muted text-sm">
            <span>{{ formatCurrency(cat.current_month_usage) }} / {{ formatCurrency(cat.monthly_limit) }}</span>
            <span :class="usageColorClass(usagePercent(cat))">{{ usagePercent(cat) }}%</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="editingCategory" class="modal-backdrop" @click.self="closeEdit">
      <div class="card modal-content animate-fade-in">
        <h3 class="font-semibold" style="margin-bottom:1rem">Editar categoria</h3>
        <form @submit.prevent="saveEdit" style="display:flex;flex-direction:column;gap:1rem">
          <div class="form-group">
            <label class="form-label">Nome</label>
            <input v-model="editForm.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label class="form-label">Tipo</label>
            <select v-model="editForm.type" class="form-input">
              <option value="expense">Gasto</option>
              <option value="income">Receita</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Cor</label>
            <input v-model="editForm.color" class="form-input" type="color" />
          </div>
          <div class="form-group" v-if="editForm.type === 'expense'">
            <label class="form-label">Limite mensal (R$) — opcional</label>
            <input v-model="editForm.monthly_limit" class="form-input" type="number" step="0.01" min="0" placeholder="Sem limite" />
          </div>
          <div v-if="editError" class="error-msg">{{ editError }}</div>
          <div style="display:flex;gap:0.75rem">
            <button type="submit" class="btn btn-primary">Salvar</button>
            <button type="button" class="btn btn-secondary" @click="closeEdit">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.cat-table { width: 100%; border-collapse: collapse; }
.cat-table th { text-align: left; padding: 0.5rem 0.75rem; font-size: var(--font-size-xs); color: var(--text-muted); font-weight: 600; border-bottom: 1px solid var(--border-subtle); }
.cat-table td { padding: 0.75rem; border-bottom: 1px solid var(--border-subtle); font-size: var(--font-size-sm); }
.cat-table tr:last-child td { border-bottom: none; }
.cat-row { cursor: pointer; transition: background var(--transition-fast); }
.cat-row:hover { background: var(--bg-card-hover); }
.cat-color-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 0.5rem; vertical-align: middle; }
.modal-backdrop {
  position: fixed; inset: 0; background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center; z-index: 100;
}
.modal-content { width: 100%; max-width: 420px; margin: 1rem; }
.budget-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
.budget-card { background: var(--bg-input); border: 1px solid var(--border-subtle); border-radius: var(--radius-sm); padding: 1rem; }
.budget-header { display: flex; align-items: center; gap: 0.5rem; }
.budget-footer { display: flex; justify-content: space-between; }
.usage-ok { color: var(--accent-success); }
.usage-warning { color: var(--accent-primary); }
.usage-over { color: var(--accent-danger); }
.progress-fill.usage-ok { background: var(--accent-success); }
.progress-fill.usage-warning { background: var(--accent-primary); }
.progress-fill.usage-over { background: var(--accent-danger); }
</style>
