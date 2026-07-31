import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/login', name: 'Login', component: () => import('@/views/LoginView.vue'), meta: { public: true } },
  { path: '/', name: 'Dashboard', component: () => import('@/views/DashboardView.vue') },
  { path: '/transactions', name: 'Transactions', component: () => import('@/views/TransactionsView.vue') },
  { path: '/income', name: 'Income', component: () => import('@/views/IncomeView.vue') },
  { path: '/plans', name: 'Plans', component: () => import('@/views/PlansView.vue') },
  { path: '/reports', name: 'Reports', component: () => import('@/views/ReportsView.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const token = localStorage.getItem('af_token')
  if (!to.meta.public && !token) {
    return '/login'
  }
  if (to.meta.public && token) {
    return '/'
  }
})

export default router
