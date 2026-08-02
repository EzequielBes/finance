import { ref } from 'vue'
import { defineStore } from 'pinia'
import * as incomeRepo from '@/repositories/income.js'

export const useIncomeStore = defineStore('income', () => {
  const entries = ref([])
  const summary = ref(null)
  const loading = ref(false)

  async function fetchIncome(params = {}) {
    loading.value = true
    try {
      entries.value = await incomeRepo.list(params)
    } finally {
      loading.value = false
    }
  }

  async function fetchSummary() {
    summary.value = await incomeRepo.getSummary()
  }

  async function createIncome(payload) {
    await incomeRepo.create(payload)
  }

  async function deleteIncome(id) {
    await incomeRepo.remove(id)
  }

  return { entries, summary, loading, fetchIncome, fetchSummary, createIncome, deleteIncome }
})
