import { ref } from 'vue'
import { defineStore } from 'pinia'
import * as transactionsRepo from '@/repositories/transactions.js'
import * as categoriesRepo from '@/repositories/categories.js'

export const useTransactionsStore = defineStore('transactions', () => {
  const items = ref([])
  const total = ref(0)
  const categories = ref([])
  const loading = ref(false)

  async function fetchTransactions(params = {}) {
    loading.value = true
    try {
      const { items: rows, total: count } = await transactionsRepo.list(params)
      items.value = rows
      total.value = count
    } finally {
      loading.value = false
    }
  }

  async function fetchCategories() {
    categories.value = await categoriesRepo.list()
  }

  async function fetchSuggestions(query) {
    return transactionsRepo.getSuggestions(query)
  }

  async function createTransaction(payload) {
    await transactionsRepo.create(payload)
  }

  async function deleteTransaction(id) {
    await transactionsRepo.remove(id)
  }

  async function createCategory(payload) {
    const created = await categoriesRepo.create(payload)
    categories.value.push(created)
    return created
  }

  return { items, total, categories, loading, fetchTransactions, fetchCategories, createTransaction, deleteTransaction, createCategory, fetchSuggestions }
})
