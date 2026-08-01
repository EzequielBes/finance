<script setup>
defineProps({
  label: String,
  value: String,
  icon: String,
  variant: { type: String, default: 'default' }, // 'success' | 'danger' | 'warning' | 'default'
  subtitle: String,
})
</script>

<template>
  <div class="stat-card card animate-fade-in">
    <div class="stat-header">
      <span class="stat-icon">{{ icon }}</span>
      <span class="stat-label text-muted text-sm">{{ label }}</span>
    </div>
    <div :class="['stat-value', variant !== 'default' && `text-${variant}`]">{{ value }}</div>
    <div v-if="subtitle" class="text-muted text-sm">{{ subtitle }}</div>
  </div>
</template>

<style scoped>
.stat-card { display: flex; flex-direction: column; gap: 0.5rem; }
.stat-header { display: flex; align-items: center; gap: 0.5rem; }
.stat-icon { font-size: 1.25rem; }
.stat-label { font-weight: 500; }
.stat-value { font-size: var(--font-size-2xl); font-weight: 700; }
</style>
