<script setup>
import { computed } from 'vue'

const props = defineProps({ events: { type: Array, default: () => [] } })

const sorted = computed(() =>
  [...props.events].sort((a, b) => new Date(a.date) - new Date(b.date))
)

function formatDate(dateStr) {
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
}

function formatCurrency(val) {
  return val ? `R$ ${val.toFixed(0)}` : ''
}
</script>

<template>
  <div class="timeline-wrapper">
    <div class="timeline-track">
      <!-- Linha base -->
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
  background: linear-gradient(90deg, var(--accent-primary), transparent);
  opacity: 0.3;
}
.timeline-now { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; }
.now-dot {
  width: 16px; height: 16px; border-radius: 50%;
  background: var(--gradient-primary); box-shadow: 0 0 12px var(--accent-primary);
  flex-shrink: 0;
}
.now-label { font-size: 0.7rem; font-weight: 600; color: var(--accent-primary); white-space: nowrap; }
.timeline-event { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; }
.event-dot {
  width: 12px; height: 12px; border-radius: 50%;
  background: var(--event-color); flex-shrink: 0;
  box-shadow: 0 0 8px var(--event-color);
}
.milestone .event-dot { width: 16px; height: 16px; }
.event-card {
  background: var(--glass-bg); border: 1px solid var(--glass-border);
  border-radius: var(--radius-sm); padding: 0.5rem 0.75rem;
  min-width: 100px; text-align: center;
  backdrop-filter: var(--glass-blur);
}
.event-label { font-size: var(--font-size-xs); font-weight: 600; }
.event-amount { font-size: var(--font-size-xs); color: var(--text-secondary); margin-top: 0.15rem; }
</style>
