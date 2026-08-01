<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useCategoriesStore } from '@/stores/categories'

const store = useCategoriesStore()

const editingCategory = ref(null)
const editForm = ref({ name: '', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: '' })
const editError = ref('')
const seeding = ref(false)

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
  try {
    await store.seedDefaults()
  } finally {
    seeding.value = false
  }
}

onMounted(() => store.fetchCategories())
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
</style>
