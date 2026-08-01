<script setup>
import { computed } from 'vue'
import { Doughnut } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
ChartJS.register(ArcElement, Tooltip, Legend)

const props = defineProps({ categories: { type: Array, default: () => [] } })

const chartData = computed(() => ({
  labels: props.categories.map(c => c.name),
  datasets: [{
    data: props.categories.map(c => c.total),
    backgroundColor: props.categories.map(c => c.color + 'CC'),
    borderColor: props.categories.map(c => c.color),
    borderWidth: 1,
    hoverOffset: 8,
  }]
}))

const options = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '70%',
  plugins: {
    legend: { position: 'right', labels: { color: '#a89c8e', padding: 16, boxWidth: 12 } },
    tooltip: { callbacks: { label: (ctx) => ` R$ ${ctx.parsed.toFixed(2)}` } }
  }
}
</script>

<template>
  <div style="height:220px; position:relative;">
    <Doughnut v-if="categories.length" :data="chartData" :options="options" />
    <div v-else class="no-data">Sem gastos registrados</div>
  </div>
</template>

<style scoped>
.no-data { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--text-muted); font-size: var(--font-size-sm); }
</style>
