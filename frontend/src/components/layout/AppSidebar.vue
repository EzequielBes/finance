<script setup>
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppIcon from '@/components/common/AppIcon.vue'

const route = useRoute()
const auth = useAuthStore()

const navItems = [
  { path: '/', icon: 'dashboard', label: 'Dashboard' },
  { path: '/transactions', icon: 'transactions', label: 'Transações' },
  { path: '/income', icon: 'income', label: 'Renda' },
  { path: '/plans', icon: 'plans', label: 'Planos' },
  { path: '/categories', icon: 'categories', label: 'Categorias' },
  { path: '/reports', icon: 'reports', label: 'Relatórios' },
]
</script>

<template>
  <nav class="sidebar">
    <div class="sidebar-logo">
      <span class="logo-mark">Finança</span>
    </div>

    <ul class="nav-list">
      <li v-for="item in navItems" :key="item.path">
        <RouterLink :to="item.path" :class="['nav-item', route.path === item.path && 'active']">
          <AppIcon :name="item.icon" :size="18" class="nav-icon" />
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
      <button class="btn btn-secondary btn-sm" @click="auth.logout()">
        <AppIcon name="logout" :size="14" />
        Sair
      </button>
    </div>
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
.sidebar-footer { display: flex; flex-direction: column; gap: 0.75rem; }
.user-info { display: flex; align-items: center; gap: 0.75rem; }
.user-avatar {
  width: 36px; height: 36px; border-radius: 50%; background: var(--accent-primary);
  color: #17130f; display: flex; align-items: center; justify-content: center;
  font-family: var(--font-serif); font-weight: 700; font-size: var(--font-size-sm); flex-shrink: 0;
}
.user-name { font-family: var(--font-sans); font-size: var(--font-size-sm); font-weight: 600; }
.user-details { overflow: hidden; }
.user-email { font-family: var(--font-sans); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
