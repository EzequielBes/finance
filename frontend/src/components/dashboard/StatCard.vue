<script setup>
import AppIcon from '@/components/common/AppIcon.vue'

defineProps({
  label: String,
  value: String,
  icon: String, // nome do ícone (ver AppIcon.vue), ex: 'trending-up'
  variant: { type: String, default: 'default' }, // 'success' | 'danger' | 'warning' | 'default'
  subtitle: String,
})
</script>

<template>
  <div class="stat-card card animate-fade-in">
    <div class="stat-header">
      <AppIcon :name="icon" :size="18" class="stat-icon" />
      <span class="stat-label text-muted text-sm">{{ label }}</span>
    </div>
    <div :class="['stat-value', variant !== 'default' && `text-${variant}`]">{{ value }}</div>
    <div v-if="subtitle" class="text-muted text-sm">{{ subtitle }}</div>
  </div>
</template>

<style scoped>
.stat-card { display: flex; flex-direction: column; gap: 0.5rem; }
.stat-header { display: flex; align-items: center; gap: 0.5rem; }
.stat-icon { color: var(--accent-primary); flex-shrink: 0; }
.stat-label { font-weight: 500; }
.stat-value { font-family: var(--font-serif); font-size: var(--font-size-2xl); font-weight: 600; }
</style>
