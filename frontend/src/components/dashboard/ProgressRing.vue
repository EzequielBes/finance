<script setup>
import { ref, onMounted, computed } from 'vue'

const props = defineProps({
  percent: { type: Number, required: true },
  label: { type: String, default: 'saúde financeira' },
  size: { type: Number, default: 200 },
})

const displayPercent = ref(0)
const radius = computed(() => props.size / 2 - 12)
const circumference = computed(() => 2 * Math.PI * radius.value)
const dashOffset = ref(circumference.value)

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function animateTo(target) {
  if (prefersReducedMotion) {
    displayPercent.value = target
    dashOffset.value = circumference.value * (1 - target / 100)
    return
  }
  const duration = 800
  const start = performance.now()
  const clamped = Math.max(0, Math.min(100, target))

  function tick(now) {
    const elapsed = now - start
    const t = Math.min(1, elapsed / duration)
    const eased = 1 - Math.pow(1 - t, 3) // ease-out cubic
    displayPercent.value = Math.round(eased * clamped)
    dashOffset.value = circumference.value * (1 - (eased * clamped) / 100)
    if (t < 1) requestAnimationFrame(tick)
  }
  requestAnimationFrame(tick)
}

onMounted(() => animateTo(props.percent))
</script>

<template>
  <div class="ring-wrap" :style="{ width: size + 'px', height: size + 'px' }">
    <svg :width="size" :height="size" :viewBox="`0 0 ${size} ${size}`">
      <circle
        :cx="size / 2" :cy="size / 2" :r="radius"
        fill="none" stroke="var(--border-subtle)" stroke-width="10"
      />
      <circle
        :cx="size / 2" :cy="size / 2" :r="radius"
        fill="none" stroke="var(--accent-primary)" stroke-width="10"
        stroke-linecap="round"
        :stroke-dasharray="circumference"
        :stroke-dashoffset="dashOffset"
        :transform="`rotate(-90 ${size / 2} ${size / 2})`"
      />
    </svg>
    <div class="ring-label">
      <div class="ring-value">{{ displayPercent }}%</div>
      <div class="ring-sub">{{ label }}</div>
    </div>
  </div>
</template>

<style scoped>
.ring-wrap { position: relative; flex-shrink: 0; }
.ring-wrap svg { position: absolute; inset: 0; }
.ring-label {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
}
.ring-value { font-family: var(--font-serif); font-size: 2.5rem; font-weight: 600; color: var(--text-primary); line-height: 1; }
.ring-sub {
  font-family: var(--font-sans); font-size: var(--font-size-xs); color: var(--text-muted);
  text-transform: uppercase; letter-spacing: 0.08em; margin-top: 0.375rem;
}
</style>
