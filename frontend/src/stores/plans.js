import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const usePlansStore = defineStore('plans', () => {
  const plans = ref([])
  const loading = ref(false)

  async function fetchPlans() {
    loading.value = true
    try {
      const { data } = await api.get('/plans', { params: { include_sub: true } })
      plans.value = data
    } finally {
      loading.value = false
    }
  }

  async function createPlan(payload) {
    const { data } = await api.post('/plans', payload)
    return data
  }

  async function updatePlan(id, payload) {
    const { data } = await api.put(`/plans/${id}`, payload)
    return data
  }

  async function deletePlan(id) {
    await api.delete(`/plans/${id}`)
  }

  async function addContribution(planId, payload) {
    await api.post(`/plans/${planId}/contributions`, payload)
  }

  async function simulate(planId, monthlyContribution) {
    const { data } = await api.get(`/plans/${planId}/simulate`, {
      params: { monthly_contribution: monthlyContribution }
    })
    return data
  }

  return { plans, loading, fetchPlans, createPlan, updatePlan, deletePlan, addContribution, simulate }
})
