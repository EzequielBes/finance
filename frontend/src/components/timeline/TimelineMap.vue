<script setup>
import { computed, ref, onMounted } from 'vue'

const props = defineProps({ events: { type: Array, default: () => [] } })

const sorted = computed(() =>
  [...props.events].sort((a, b) => new Date(a.date) - new Date(b.date))
)

const visibleCount = ref(0)
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function formatDate(dateStr) {
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
}

function formatCurrency(val) {
  return val ? `R$ ${val.toFixed(0)}` : ''
}

onMounted(() => {
  if (prefersReducedMotion) {
    visibleCount.value = sorted.value.length
    return
  }
  const total = sorted.value.length
  let i = 0
  function revealNext() {
    if (i >= total) return
    visibleCount.value = i + 1
    i += 1
    setTimeout(revealNext, 80)
  }
  revealNext()
})
</script>

<template>
  <div class="timeline-wrapper">
    <div class="timeline-track">
      <!-- Trilha vertical desenhada -->
      <div class="timeline-line" />

      <!-- Ponto "Você aqui" -->
      <div class="timeline-now">
        <div class="now-dot" />
        <div class="now-label">Hoje</div>
      </div>

      <!-- Eventos -->
      <div
        v-for="(event, i) in sorted"
        :key="i"
        v-show="i < visibleCount"
        :class="['timeline-event', event.type === 'plan_milestone' && 'milestone']"
        :style="{ '--event-color': event.color }"
      >
        <div class="event-dot" />
        <div class="event-card">
          <div class="event-label">{{ event.label }}</div>
          <div class="event-date text-muted" style="font-size:0.7rem">{{ formatDate(event.date) }}</div>
          <div v-if="event.amount" class="event-amount">{{ formatCurrency(event.amount) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.timeline-wrapper { overflow-x: auto; padding: 1rem 0; }
.timeline-track {
  display: flex; align-items: flex-start; gap: 2rem;
  min-width: max-content; padding: 0 1rem; position: relative;
}
.timeline-line {
  position: absolute; top: 20px; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, var(--accent-primary), transparent 85%);
  opacity: 0.5;
}
.timeline-now { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; }
.now-dot {
  width: 16px; height: 16px; border-radius: 50%;
  background: var(--accent-primary); box-shadow: 0 0 10px var(--accent-primary-glow);
  flex-shrink: 0;
}
.now-label { font-family: var(--font-sans); font-size: 0.7rem; font-weight: 600; color: var(--accent-primary); white-space: nowrap; }
.timeline-event {
  display: flex; flex-direction: column; align-items: center; gap: 0.5rem;
  animation: eventReveal var(--transition-slow) ease forwards;
}
@keyframes eventReveal {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}
.event-dot {
  width: 12px; height: 12px; border-radius: 50%;
  background: var(--event-color); flex-shrink: 0;
  box-shadow: 0 0 6px var(--event-color);
}
.milestone .event-dot { width: 16px; height: 16px; }
.event-card {
  background: var(--bg-input); border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm); padding: 0.5rem 0.75rem;
  min-width: 100px; text-align: center;
}
.event-label { font-family: var(--font-sans); font-size: var(--font-size-xs); font-weight: 600; }
.event-amount { font-family: var(--font-sans); font-size: var(--font-size-xs); color: var(--text-secondary); margin-top: 0.15rem; }
</style>
