<script setup>
const props = defineProps({
  name: { type: String, required: true },
  size: { type: [String, Number], default: 20 },
})

const paths = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  transactions: 'M7 10l5-5 5 5M7 14l5 5 5-5',
  income: 'M12 3v18M5 10l7-7 7 7',
  plans: 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 4a6 6 0 1 0 0 12 6 6 0 0 0 0-12zm0 4a2 2 0 1 0 0 4 2 2 0 0 0 0-4z',
  reports: 'M4 19h16M8 19V9m4 10V5m4 14v-7',
  wallet: 'M3 7a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v1h1a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7zm14 5h.01',
  'trending-up': 'M3 17l6-6 4 4 8-8M15 7h6v6',
  'trending-down': 'M3 7l6 6 4-4 8 8M21 11v6h-6',
  bank: 'M3 21h18M4 10h16M6 10V21M18 10V21M10 10V21M14 10V21M12 3L3 9h18L12 3z',
  target: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2z',
  calculator: 'M5 3h14a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM7 7h10M7 11h2M11 11h2M15 11h2M7 15h2M11 15h2M15 15h2',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
  categories: 'M20.59 13.41L13.42 20.58a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82zM7 7h.01',
}
</script>

<template>
  <svg
    :width="size" :height="size" viewBox="0 0 24 24"
    fill="none" stroke="currentColor" stroke-width="1.75"
    stroke-linecap="round" stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="paths[name]" />
  </svg>
</template>
