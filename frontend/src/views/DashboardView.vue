<script setup>
import { onMounted, ref } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import DonutChart from '@/components/charts/DonutChart.vue'
import TimelineMap from '@/components/timeline/TimelineMap.vue'
import { useDashboardStore } from '@/stores/dashboard'

const dash = useDashboardStore()

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

onMounted(async () => {
  await dash.fetchSummary()
  await dash.fetchTimeline()
})
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h1 class="page-title">Dashboard</h1>
      <p class="page-subtitle">Visão geral das suas finanças</p>
    </div>

    <div v-if="dash.loading" class="grid-4" style="margin-bottom:1.5rem">
      <div v-for="i in 4" :key="i" class="skeleton card" style="height:100px" />
    </div>

    <div v-else>
      <!-- Stat Cards -->
      <div class="grid-4" style="margin-bottom:1.5rem">
        <StatCard label="Receita do mês" :value="formatCurrency(dash.summary?.total_income)" icon="💰" variant="success" />
        <StatCard label="Total gasto" :value="formatCurrency(dash.summary?.total_expense)" icon="💸" variant="danger" />
        <StatCard label="Saldo disponível" :value="formatCurrency(dash.summary?.balance)" icon="🏦" />
        <StatCard label="Economizado" :value="`${dash.summary?.savings_percent || 0}%`" icon="📈" variant="success" :subtitle="`do total recebido`" />
      </div>

      <!-- Gráfico + Timeline -->
      <div class="grid-2" style="margin-bottom:1.5rem">
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Gastos por categoria</h3>
          <DonutChart :categories="dash.summary?.by_category || []" />
        </div>
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Mapa financeiro</h3>
          <TimelineMap :events="dash.timeline" />
        </div>
      </div>
    </div>
  </AppLayout>
</template>
