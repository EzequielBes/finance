<script setup>
import { onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import ProgressRing from '@/components/dashboard/ProgressRing.vue'
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
      <!-- Hero: anel de saúde financeira + saldo em destaque -->
      <div class="dashboard-hero card">
        <ProgressRing :percent="dash.summary?.savings_percent || 0" />
        <div class="hero-text">
          <div class="hero-eyebrow text-muted">saldo disponível</div>
          <h2 class="hero-value">{{ formatCurrency(dash.summary?.balance) }}</h2>
        </div>
      </div>

      <!-- Stat Cards secundários -->
      <div class="grid-3" style="margin: 1.5rem 0">
        <StatCard label="Receita do mês" :value="formatCurrency(dash.summary?.total_income)" icon="trending-up" variant="success" />
        <StatCard label="Total gasto" :value="formatCurrency(dash.summary?.total_expense)" icon="trending-down" variant="danger" />
        <StatCard label="Economizado" :value="`${dash.summary?.savings_percent || 0}%`" icon="wallet" variant="success" subtitle="do total recebido" />
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

<style scoped>
.dashboard-hero { display: flex; align-items: center; gap: 3rem; padding: 2.5rem; }
.hero-eyebrow { font-family: var(--font-sans); font-size: var(--font-size-xs); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.5rem; }
.hero-value { font-family: var(--font-serif); font-size: 2.75rem; font-weight: 500; color: var(--text-primary); }
@media (max-width: 768px) {
  .dashboard-hero { flex-direction: column; text-align: center; gap: 1.5rem; padding: 1.5rem; }
}
</style>
