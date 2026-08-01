import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useDashboardStore = defineStore('dashboard', () => {
  const summary = ref(null)
  const timeline = ref([])
  const loading = ref(false)

  async function fetchSummary(month, year) {
    loading.value = true
    try {
      const params = {}
      if (month) params.month = month
      if (year) params.year = year
      const { data } = await api.get('/dashboard/summary', { params })
      summary.value = data
    } finally {
      loading.value = false
    }
  }

  // Backend retorna eventos discriminados por `type` (transaction | plan_milestone)
  // sem label/color prontos — mapeamos aqui para o formato que TimelineMap.vue consome.
  function mapEvent(e) {
    if (e.type === 'plan_milestone') {
      return {
        label: e.title,
        date: e.date,
        amount: e.target_amount,
        type: e.type,
        color: e.status === 'paused' ? '#8a7d6e' : '#7a9b7e', // cinza=pausado, verde=ativo
      }
    }
    // transaction
    let color = '#8a9bb0' // padrão: azul (pontual)
    if (e.is_recurring) color = '#b8563a' // vermelho=fixo recorrente
    else if (e.installments_total) color = '#c17a54' // amarelo=parcelado
    return {
      label: e.title,
      date: e.date,
      amount: e.amount,
      type: e.type,
      color,
    }
  }

  async function fetchTimeline(monthsAhead = 6) {
    const { data } = await api.get('/dashboard/timeline', { params: { months_ahead: monthsAhead } })
    timeline.value = data.map(mapEvent)
  }

  return { summary, timeline, loading, fetchSummary, fetchTimeline }
})
