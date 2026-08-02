import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useReportsStore = defineStore('reports', () => {
  const items = ref([])
  const loading = ref(false)

  async function fetchSavingsAnalysis() {
    loading.value = true
    try {
      const { data } = await api.get('/reports/savings-analysis')
      items.value = data
    } finally {
      loading.value = false
    }
  }

  return { items, loading, fetchSavingsAnalysis }
})
