<script setup>
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler } from 'chart.js'
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler)

const props = defineProps({
  labels: { type: Array, default: () => [] },
  incomeData: { type: Array, default: () => [] },
  expenseData: { type: Array, default: () => [] },
})

const chartData = computed(() => ({
  labels: props.labels,
  datasets: [
    {
      label: 'Receita', data: props.incomeData,
      borderColor: '#10B981', backgroundColor: 'rgba(16,185,129,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    },
    {
      label: 'Gasto', data: props.expenseData,
      borderColor: '#EF4444', backgroundColor: 'rgba(239,68,68,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    }
  ]
}))

const options = {
  responsive: true, maintainAspectRatio: false,
  scales: {
    x: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#94A3B8' } },
    y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#94A3B8', callback: (v) => `R$${v}` } }
  },
  plugins: { legend: { labels: { color: '#94A3B8', font: { family: 'Inter' } } } }
}
</script>

<template>
  <div style="height:220px;">
    <Line :data="chartData" :options="options" />
  </div>
</template>
