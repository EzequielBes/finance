import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useCategoriesStore = defineStore('categories', () => {
  const items = ref([])
  const loading = ref(false)

  async function fetchCategories() {
    loading.value = true
    try {
      const { data } = await api.get('/categories')
      items.value = data
    } finally {
      loading.value = false
    }
  }

  async function seedDefaults() {
    const { data } = await api.post('/categories/seed-defaults')
    if (data.length) {
      await fetchCategories()
    }
    return data
  }

  async function updateCategory(id, payload) {
    const { data } = await api.put(`/categories/${id}`, payload)
    const index = items.value.findIndex((c) => c.id === id)
    if (index !== -1) items.value[index] = data
    return data
  }

  return { items, loading, fetchCategories, seedDefaults, updateCategory }
})
