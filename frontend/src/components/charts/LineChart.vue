<script setup>
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler, Legend } from 'chart.js'
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler, Legend)

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
      borderColor: '#7a9b7e', backgroundColor: 'rgba(122,155,126,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    },
    {
      label: 'Gasto', data: props.expenseData,
      borderColor: '#b8563a', backgroundColor: 'rgba(184,86,58,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    }
  ]
}))

const options = {
  responsive: true, maintainAspectRatio: false,
  scales: {
    x: { grid: { color: 'rgba(44,38,32,0.6)' }, ticks: { color: '#a89c8e' } },
    y: { grid: { color: 'rgba(44,38,32,0.6)' }, ticks: { color: '#a89c8e', callback: (v) => `R$${v}` } }
  },
  plugins: { legend: { labels: { color: '#a89c8e' } } }
}
</script>

<template>
  <div style="height:220px;">
    <Line :data="chartData" :options="options" />
  </div>
</template>
