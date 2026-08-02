import { ref } from 'vue'
import { defineStore } from 'pinia'
import * as categoriesRepo from '@/repositories/categories.js'

export const useCategoriesStore = defineStore('categories', () => {
  const items = ref([])
  const loading = ref(false)

  async function fetchCategories() {
    loading.value = true
    try {
      items.value = await categoriesRepo.list()
    } finally {
      loading.value = false
    }
  }

  async function seedDefaults() {
    const created = await categoriesRepo.seedDefaults()
    await fetchCategories()
    return created
  }

  async function updateCategory(id, payload) {
    const updated = await categoriesRepo.update(id, payload)
    await fetchCategories()
    return updated
  }

  return { items, loading, fetchCategories, seedDefaults, updateCategory }
})
