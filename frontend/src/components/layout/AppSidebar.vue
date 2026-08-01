<script setup>
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()

const navItems = [
  { path: '/', icon: '📊', label: 'Dashboard' },
  { path: '/transactions', icon: '💳', label: 'Transações' },
  { path: '/income', icon: '💰', label: 'Renda' },
  { path: '/plans', icon: '🎯', label: 'Planos' },
  { path: '/reports', icon: '📈', label: 'Relatórios' },
]
</script>

<template>
  <nav class="sidebar">
    <div class="sidebar-logo">
      <span>💰</span>
      <span class="logo-text">FinPlanner</span>
    </div>

    <ul class="nav-list">
      <li v-for="item in navItems" :key="item.path">
        <RouterLink :to="item.path" :class="['nav-item', route.path === item.path && 'active']">
          <span class="nav-icon">{{ item.icon }}</span>
          <span>{{ item.label }}</span>
        </RouterLink>
      </li>
    </ul>

    <div class="sidebar-footer">
      <div class="user-info" v-if="auth.user">
        <div class="user-avatar">{{ auth.user.name[0].toUpperCase() }}</div>
        <div class="user-details">
          <div class="user-name">{{ auth.user.name }}</div>
          <div class="user-email text-muted text-sm">{{ auth.user.email }}</div>
        </div>
      </div>
      <button class="btn btn-secondary btn-sm" @click="auth.logout()">Sair</button>
    </div>
  </nav>
</template>

<style scoped>
.sidebar {
  width: 240px; min-height: 100vh; padding: 1.5rem 1rem;
  background: var(--bg-secondary); border-right: 1px solid var(--border-subtle);
  display: flex; flex-direction: column; gap: 2rem; flex-shrink: 0;
}
.sidebar-logo { display: flex; align-items: center; gap: 0.5rem; padding: 0 0.5rem; font-size: var(--font-size-lg); font-weight: 700; }
.nav-list { list-style: none; display: flex; flex-direction: column; gap: 0.25rem; flex: 1; }
.nav-item {
  display: flex; align-items: center; gap: 0.75rem;
  padding: 0.625rem 0.875rem; border-radius: var(--radius-sm);
  color: var(--text-secondary); text-decoration: none; font-size: var(--font-size-sm); font-weight: 500;
  transition: all var(--transition-fast);
}
.nav-item:hover { background: var(--bg-card-hover); color: var(--text-primary); }
.nav-item.active { background: var(--accent-primary-glow); color: var(--accent-primary); }
.nav-icon { font-size: 1.1rem; }
.sidebar-footer { display: flex; flex-direction: column; gap: 0.75rem; }
.user-info { display: flex; align-items: center; gap: 0.75rem; }
.user-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--gradient-primary); display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: var(--font-size-sm); flex-shrink: 0; }
.user-name { font-size: var(--font-size-sm); font-weight: 600; }
.user-details { overflow: hidden; }
.user-email { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
