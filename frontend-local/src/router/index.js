import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', redirect: '/transactions' },
  { path: '/transactions', name: 'Transactions', component: () => import('@/views/TransactionsView.vue') },
  { path: '/income', name: 'Income', component: () => import('@/views/IncomeView.vue') },
  { path: '/categories', name: 'Categories', component: () => import('@/views/CategoriesView.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
