import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useIncomeStore = defineStore('income', () => {
  const entries = ref([])
  const summary = ref(null)
  const loading = ref(false)

  async function fetchIncome(params = {}) {
    loading.value = true
    try {
      const { data } = await api.get('/income', { params })
      entries.value = data
    } finally {
      loading.value = false
    }
  }

  async function fetchSummary() {
    const { data } = await api.get('/income/summary')
    summary.value = data
  }

  async function createIncome(payload) {
    await api.post('/income', payload)
  }

  async function deleteIncome(id) {
    await api.delete(`/income/${id}`)
  }

  return { entries, summary, loading, fetchIncome, fetchSummary, createIncome, deleteIncome }
})
