<script setup>
import { useRoute } from 'vue-router'
import AppIcon from '@/components/common/AppIcon.vue'

const route = useRoute()

const navItems = [
  { path: '/transactions', icon: 'transactions', label: 'Transações' },
  { path: '/income', icon: 'income', label: 'Renda' },
  { path: '/categories', icon: 'categories', label: 'Categorias' },
]
</script>

<template>
  <nav class="sidebar">
    <div class="sidebar-logo">
      <span class="logo-mark">Finança (Local)</span>
    </div>

    <ul class="nav-list">
      <li v-for="item in navItems" :key="item.path">
        <RouterLink :to="item.path" :class="['nav-item', route.path === item.path && 'active']">
          <AppIcon :name="item.icon" :size="18" class="nav-icon" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </li>
    </ul>
  </nav>
</template>

<style scoped>
.sidebar {
  width: 240px; min-height: 100vh; padding: 1.75rem 1rem;
  background: var(--bg-secondary); border-right: 1px solid var(--border-subtle);
  display: flex; flex-direction: column; gap: 2rem; flex-shrink: 0;
}
.sidebar-logo { padding: 0 0.75rem; margin-bottom: 0.5rem; }
.logo-mark { font-family: var(--font-serif); font-size: var(--font-size-lg); font-weight: 600; color: var(--text-primary); letter-spacing: 0.01em; }
.nav-list { list-style: none; display: flex; flex-direction: column; gap: 0.125rem; flex: 1; }
.nav-item {
  display: flex; align-items: center; gap: 0.75rem;
  padding: 0.625rem 0.875rem; border-radius: var(--radius-sm);
  color: var(--text-secondary); text-decoration: none;
  font-family: var(--font-sans); font-size: var(--font-size-sm); font-weight: 500;
  border-left: 2px solid transparent;
  transition: all var(--transition-fast);
}
.nav-item:hover { background: var(--bg-card-hover); color: var(--text-primary); }
.nav-item.active { background: var(--bg-card); color: var(--accent-primary); border-left-color: var(--accent-primary); }
.nav-icon { flex-shrink: 0; }
</style>
