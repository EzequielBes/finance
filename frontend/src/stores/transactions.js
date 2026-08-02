import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useTransactionsStore = defineStore('transactions', () => {
  const items = ref([])
  const total = ref(0)
  const categories = ref([])
  const loading = ref(false)

  async function fetchTransactions(params = {}) {
    loading.value = true
    try {
      const { data } = await api.get('/transactions', { params })
      items.value = data.items
      total.value = data.total
    } finally {
      loading.value = false
    }
  }

  async function fetchCategories() {
    const { data } = await api.get('/categories')
    categories.value = data
  }

  async function fetchSuggestions(query) {
    const { data } = await api.get('/transactions/suggestions', { params: { q: query } })
    return data
  }

  async function createTransaction(payload) {
    await api.post('/transactions', payload)
  }

  async function deleteTransaction(id) {
    await api.delete(`/transactions/${id}`)
  }

  async function createCategory(payload) {
    const { data } = await api.post('/categories', payload)
    categories.value.push(data)
    return data
  }

  return { items, total, categories, loading, fetchTransactions, fetchCategories, createTransaction, deleteTransaction, createCategory, fetchSuggestions }
})
