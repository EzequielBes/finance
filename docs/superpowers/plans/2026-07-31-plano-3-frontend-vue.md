# AnalisadorFinanceiro — Plano 3: Frontend Vue.js

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o frontend Vue.js 3 completo com design premium (dark mode, glassmorphism, animações), incluindo autenticação, dashboard com gráficos, listagem de transações, gestão de renda, planos com simulador interativo e a timeline visual.

**Architecture:** Vue 3 + Vite + Pinia (state) + Vue Router + Axios. Design system centralizado em `src/assets/main.css` com CSS variables. Componentes organizados por domínio. Chart.js para gráficos. TimelineMap é um componente Vue nativo com SVG/CSS.

**Tech Stack:** Vue 3.4+, Vite 5+, Pinia 2+, Vue Router 4+, Axios 1.6+, Chart.js 4+, vue-chartjs 5+

## Global Constraints

- Vue 3 Composition API com `<script setup>` em todos os componentes
- Pinia para state management — sem Vuex
- Dark mode como padrão visual — paleta escura com acentos vibrantes
- CSS variables para design tokens — sem Tailwind
- Todos os formulários têm validação de client-side antes do submit
- Erros de API exibidos como toast/notificação inline
- Backend em `http://localhost:8000` — configurado via `VITE_API_URL` no `.env`
- Token JWT armazenado em `localStorage` com chave `af_token`
- Rotas protegidas via navigation guard no Vue Router

---

### Task 10: Scaffolding do Frontend

**Files:**
- Create: `frontend/` (via Vite)
- Create: `frontend/.env`
- Create: `frontend/src/assets/main.css`
- Create: `frontend/src/services/api.js`

**Interfaces:**
- Produces: `api` (Axios instance) em `src/services/api.js` — usado por todos os stores
- Produces: Design system com CSS variables (cores, tipografia, espaçamentos, glassmorphism)

- [ ] **Step 1: Criar projeto Vue com Vite**

```bash
cd /home/ezequieltbeserra/Documentos/AnalisadorFinanceiro
npm create vite@latest frontend -- --template vue
cd frontend
npm install
npm install pinia vue-router axios chart.js vue-chartjs
```

- [ ] **Step 2: Criar frontend/.env**

```
VITE_API_URL=http://localhost:8000
```

- [ ] **Step 3: Substituir src/assets/main.css pelo design system**

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root {
  /* Cores base — Dark Mode */
  --bg-primary: #0A0E1A;
  --bg-secondary: #111827;
  --bg-card: rgba(255, 255, 255, 0.04);
  --bg-card-hover: rgba(255, 255, 255, 0.07);
  --bg-input: rgba(255, 255, 255, 0.06);

  /* Bordas */
  --border-subtle: rgba(255, 255, 255, 0.08);
  --border-focus: rgba(99, 102, 241, 0.6);

  /* Texto */
  --text-primary: #F1F5F9;
  --text-secondary: #94A3B8;
  --text-muted: #475569;

  /* Acentos */
  --accent-primary: #6366F1;    /* Indigo */
  --accent-primary-glow: rgba(99, 102, 241, 0.3);
  --accent-success: #10B981;    /* Emerald */
  --accent-warning: #F59E0B;    /* Amber */
  --accent-danger: #EF4444;     /* Red */
  --accent-info: #3B82F6;       /* Blue */

  /* Gradientes */
  --gradient-primary: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
  --gradient-success: linear-gradient(135deg, #10B981 0%, #059669 100%);
  --gradient-card: linear-gradient(145deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 100%);

  /* Glassmorphism */
  --glass-bg: rgba(255, 255, 255, 0.05);
  --glass-border: rgba(255, 255, 255, 0.1);
  --glass-blur: blur(20px);

  /* Sombras */
  --shadow-sm: 0 2px 8px rgba(0,0,0,0.3);
  --shadow-md: 0 4px 24px rgba(0,0,0,0.4);
  --shadow-glow: 0 0 30px rgba(99,102,241,0.2);

  /* Raios */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --radius-xl: 28px;

  /* Transições */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
  --transition-slow: 400ms ease;

  /* Tipografia */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { font-size: 16px; scroll-behavior: smooth; }

body {
  font-family: var(--font-sans);
  background: var(--bg-primary);
  color: var(--text-primary);
  min-height: 100vh;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}

/* Cards glassmorphism */
.card {
  background: var(--glass-bg);
  border: 1px solid var(--glass-border);
  backdrop-filter: var(--glass-blur);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  transition: background var(--transition-base), box-shadow var(--transition-base);
}
.card:hover { background: var(--bg-card-hover); box-shadow: var(--shadow-md); }

/* Botões */
.btn {
  display: inline-flex; align-items: center; gap: 0.5rem;
  padding: 0.625rem 1.25rem; border-radius: var(--radius-sm);
  font-size: var(--font-size-sm); font-weight: 500; font-family: var(--font-sans);
  cursor: pointer; border: none; transition: all var(--transition-fast);
  text-decoration: none;
}
.btn-primary {
  background: var(--gradient-primary); color: white;
  box-shadow: 0 4px 15px var(--accent-primary-glow);
}
.btn-primary:hover { transform: translateY(-1px); box-shadow: 0 6px 20px var(--accent-primary-glow); }
.btn-secondary {
  background: var(--bg-input); color: var(--text-primary);
  border: 1px solid var(--border-subtle);
}
.btn-secondary:hover { background: var(--bg-card-hover); }
.btn-danger { background: rgba(239,68,68,0.15); color: var(--accent-danger); border: 1px solid rgba(239,68,68,0.3); }
.btn-sm { padding: 0.375rem 0.875rem; font-size: var(--font-size-xs); }

/* Formulários */
.form-group { display: flex; flex-direction: column; gap: 0.375rem; }
.form-label { font-size: var(--font-size-sm); font-weight: 500; color: var(--text-secondary); }
.form-input {
  background: var(--bg-input); border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm); padding: 0.625rem 0.875rem;
  color: var(--text-primary); font-size: var(--font-size-base); font-family: var(--font-sans);
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  outline: none; width: 100%;
}
.form-input:focus { border-color: var(--accent-primary); box-shadow: 0 0 0 3px var(--accent-primary-glow); }
.form-input::placeholder { color: var(--text-muted); }
select.form-input { cursor: pointer; }

/* Badges */
.badge {
  display: inline-flex; align-items: center; gap: 0.25rem;
  padding: 0.2rem 0.6rem; border-radius: 999px;
  font-size: var(--font-size-xs); font-weight: 600;
}
.badge-success { background: rgba(16,185,129,0.15); color: var(--accent-success); }
.badge-warning { background: rgba(245,158,11,0.15); color: var(--accent-warning); }
.badge-danger { background: rgba(239,68,68,0.15); color: var(--accent-danger); }
.badge-info { background: rgba(99,102,241,0.15); color: var(--accent-primary); }

/* Progress bar */
.progress-bar { background: var(--bg-input); border-radius: 999px; height: 6px; overflow: hidden; }
.progress-fill {
  height: 100%; border-radius: 999px;
  background: var(--gradient-primary);
  transition: width var(--transition-slow);
}

/* Utilitários */
.text-success { color: var(--accent-success); }
.text-danger { color: var(--accent-danger); }
.text-warning { color: var(--accent-warning); }
.text-muted { color: var(--text-secondary); }
.text-sm { font-size: var(--font-size-sm); }
.font-bold { font-weight: 700; }
.font-semibold { font-weight: 600; }

/* Layout */
.page-layout { display: flex; min-height: 100vh; }
.main-content { flex: 1; padding: 2rem; overflow-y: auto; }
.page-header { margin-bottom: 2rem; }
.page-title { font-size: var(--font-size-3xl); font-weight: 700; }
.page-subtitle { color: var(--text-secondary); margin-top: 0.25rem; }
.grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; }
.grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1.5rem; }

/* Animações */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in { animation: fadeInUp var(--transition-slow) ease forwards; }

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
.skeleton {
  background: linear-gradient(90deg, var(--bg-card) 25%, var(--bg-card-hover) 50%, var(--bg-card) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: var(--radius-sm);
}

/* Responsividade básica */
@media (max-width: 768px) {
  .grid-2, .grid-3, .grid-4 { grid-template-columns: 1fr; }
  .main-content { padding: 1rem; }
}
```

- [ ] **Step 4: Criar src/services/api.js**

```javascript
import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  headers: { 'Content-Type': 'application/json' },
})

// Injetar token em todos os requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('af_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Redirecionar para login se 401
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('af_token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
```

- [ ] **Step 5: Verificar que o projeto roda**

```bash
cd frontend && npm run dev
```

Esperado: `VITE ready` em `http://localhost:5173`. Ctrl+C para parar.

- [ ] **Step 6: Commit**

```bash
git add frontend/
git commit -m "feat: scaffolding frontend Vue 3 + Vite + design system dark mode"
```

---

### Task 11: Auth Store + Login/Register View

**Files:**
- Create: `frontend/src/stores/auth.js`
- Create: `frontend/src/views/LoginView.vue`
- Create: `frontend/src/router/index.js`
- Modify: `frontend/src/main.js`
- Modify: `frontend/src/App.vue`

**Interfaces:**
- Produces: `useAuthStore()` em `src/stores/auth.js` com: `user`, `token`, `isAuthenticated`, `login(email, password)`, `register(name, email, password)`, `logout()`
- Produces: rota `/login` → `LoginView.vue` (pública)
- Produces: navigation guard: rotas sem `meta.public` exigem autenticação

- [ ] **Step 1: Criar src/stores/auth.js**

```javascript
import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useRouter } from 'vue-router'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('af_token') || null)
  const router = useRouter()

  const isAuthenticated = computed(() => !!token.value)

  async function login(email, password) {
    const { data } = await api.post('/auth/login', { email, password })
    token.value = data.access_token
    localStorage.setItem('af_token', data.access_token)
    await fetchMe()
    router.push('/')
  }

  async function register(name, email, password) {
    await api.post('/auth/register', { name, email, password })
    await login(email, password)
  }

  async function fetchMe() {
    if (!token.value) return
    try {
      const { data } = await api.get('/auth/me')
      user.value = data
    } catch {
      logout()
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('af_token')
    router.push('/login')
  }

  return { user, token, isAuthenticated, login, register, logout, fetchMe }
})
```

- [ ] **Step 2: Criar src/router/index.js**

```javascript
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
```

- [ ] **Step 3: Atualizar src/main.js**

```javascript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/main.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
```

- [ ] **Step 4: Criar src/views/LoginView.vue**

```vue
<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const mode = ref('login') // 'login' | 'register'
const name = ref('')
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    if (mode.value === 'login') {
      await auth.login(email.value, password.value)
    } else {
      await auth.register(name.value, email.value, password.value)
    }
  } catch (e) {
    error.value = e.response?.data?.detail || 'Ocorreu um erro. Tente novamente.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-bg">
    <div class="login-container animate-fade-in">
      <div class="login-logo">
        <span class="logo-icon">💰</span>
        <h1>AnalisadorFinanceiro</h1>
        <p class="text-muted text-sm">Controle total da sua vida financeira</p>
      </div>

      <div class="card login-card">
        <div class="tab-row">
          <button :class="['tab-btn', mode === 'login' && 'active']" @click="mode = 'login'">Entrar</button>
          <button :class="['tab-btn', mode === 'register' && 'active']" @click="mode = 'register'">Criar conta</button>
        </div>

        <form @submit.prevent="submit" class="form-stack">
          <div v-if="mode === 'register'" class="form-group">
            <label class="form-label">Nome</label>
            <input v-model="name" class="form-input" type="text" placeholder="Seu nome completo" required />
          </div>
          <div class="form-group">
            <label class="form-label">E-mail</label>
            <input v-model="email" class="form-input" type="email" placeholder="seu@email.com" required />
          </div>
          <div class="form-group">
            <label class="form-label">Senha</label>
            <input v-model="password" class="form-input" type="password" placeholder="••••••••" required />
          </div>

          <div v-if="error" class="error-msg">{{ error }}</div>

          <button type="submit" class="btn btn-primary" style="width:100%;justify-content:center" :disabled="loading">
            {{ loading ? 'Aguarde...' : (mode === 'login' ? 'Entrar' : 'Criar conta') }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-bg {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  background: radial-gradient(ellipse at 50% 0%, rgba(99,102,241,0.15) 0%, var(--bg-primary) 70%);
}
.login-container { width: 100%; max-width: 420px; padding: 1rem; display: flex; flex-direction: column; gap: 2rem; }
.login-logo { text-align: center; }
.logo-icon { font-size: 2.5rem; }
.login-logo h1 { font-size: var(--font-size-2xl); font-weight: 700; margin-top: 0.5rem; }
.login-card { padding: 2rem; }
.tab-row { display: flex; background: var(--bg-input); border-radius: var(--radius-sm); padding: 4px; margin-bottom: 1.5rem; }
.tab-btn { flex: 1; padding: 0.5rem; border: none; background: none; color: var(--text-secondary); border-radius: 6px; cursor: pointer; font-family: var(--font-sans); font-size: var(--font-size-sm); font-weight: 500; transition: all var(--transition-fast); }
.tab-btn.active { background: var(--accent-primary); color: white; }
.form-stack { display: flex; flex-direction: column; gap: 1rem; }
.error-msg { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 5: Atualizar App.vue**

```vue
<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
onMounted(() => auth.fetchMe())
</script>

<template>
  <RouterView />
</template>
```

- [ ] **Step 6: Criar views placeholder (para router não quebrar)**

Criar `src/views/DashboardView.vue`, `TransactionsView.vue`, `IncomeView.vue`, `PlansView.vue`, `ReportsView.vue` com template mínimo:

```vue
<template><div class="main-content"><h1 class="page-title">Em construção</h1></div></template>
```

- [ ] **Step 7: Testar login manualmente**

```bash
cd frontend && npm run dev
```

1. Abrir `http://localhost:5173` → redireciona para `/login`
2. Clicar em "Criar conta" → preencher nome, email, senha → submit → redireciona para `/`
3. Atualizar página → permanece autenticado (token no localStorage)
4. Testar login com e-mail errado → exibe mensagem de erro

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: auth store + login/register view com dark mode"
```

---

### Task 12: Sidebar + Layout Principal

**Files:**
- Create: `frontend/src/components/layout/AppSidebar.vue`
- Create: `frontend/src/components/layout/AppLayout.vue`
- Modify: views existentes para usar AppLayout

**Interfaces:**
- Produces: `AppLayout.vue` — wrapper com sidebar + slot para conteúdo
- Produces: `AppSidebar.vue` — navegação com links, avatar do usuário, botão de logout

- [ ] **Step 1: Criar src/components/layout/AppSidebar.vue**

```vue
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
```

- [ ] **Step 2: Criar src/components/layout/AppLayout.vue**

```vue
<template>
  <div class="page-layout">
    <AppSidebar />
    <main class="main-content">
      <slot />
    </main>
  </div>
</template>

<script setup>
import AppSidebar from './AppSidebar.vue'
</script>
```

- [ ] **Step 3: Testar layout visualmente**

```bash
npm run dev
```

Abrir `http://localhost:5173` — deve mostrar sidebar à esquerda com navegação e área de conteúdo à direita.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: sidebar + layout principal com navegação"
```

---

### Task 13: Dashboard View

**Files:**
- Create: `frontend/src/stores/dashboard.js`
- Create: `frontend/src/components/charts/DonutChart.vue`
- Create: `frontend/src/components/charts/LineChart.vue`
- Create: `frontend/src/components/dashboard/StatCard.vue`
- Create: `frontend/src/components/timeline/TimelineMap.vue`
- Modify: `frontend/src/views/DashboardView.vue`

**Interfaces:**
- Consumes: `GET /dashboard/summary`, `GET /dashboard/timeline`
- Produces: Dashboard com 4 stat cards, gráfico donut, gráfico de linha e mini-timeline

- [ ] **Step 1: Criar src/stores/dashboard.js**

```javascript
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useDashboardStore = defineStore('dashboard', () => {
  const summary = ref(null)
  const timeline = ref([])
  const loading = ref(false)

  async function fetchSummary(month, year) {
    loading.value = true
    try {
      const params = {}
      if (month) params.month = month
      if (year) params.year = year
      const { data } = await api.get('/dashboard/summary', { params })
      summary.value = data
    } finally {
      loading.value = false
    }
  }

  async function fetchTimeline(monthsAhead = 6) {
    const { data } = await api.get('/dashboard/timeline', { params: { months_ahead: monthsAhead } })
    timeline.value = data
  }

  return { summary, timeline, loading, fetchSummary, fetchTimeline }
})
```

- [ ] **Step 2: Criar src/components/charts/DonutChart.vue**

```vue
<script setup>
import { computed } from 'vue'
import { Doughnut } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
ChartJS.register(ArcElement, Tooltip, Legend)

const props = defineProps({ categories: { type: Array, default: () => [] } })

const chartData = computed(() => ({
  labels: props.categories.map(c => c.name),
  datasets: [{
    data: props.categories.map(c => c.total),
    backgroundColor: props.categories.map(c => c.color + 'CC'),
    borderColor: props.categories.map(c => c.color),
    borderWidth: 1,
    hoverOffset: 8,
  }]
}))

const options = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '70%',
  plugins: {
    legend: { position: 'right', labels: { color: '#94A3B8', font: { family: 'Inter' }, padding: 16, boxWidth: 12 } },
    tooltip: { callbacks: { label: (ctx) => ` R$ ${ctx.parsed.toFixed(2)}` } }
  }
}
</script>

<template>
  <div style="height:220px; position:relative;">
    <Doughnut v-if="categories.length" :data="chartData" :options="options" />
    <div v-else class="no-data">Sem gastos registrados</div>
  </div>
</template>

<style scoped>
.no-data { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--text-muted); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 3: Criar src/components/charts/LineChart.vue**

```vue
<script setup>
import { computed } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler } from 'chart.js'
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Filler)

const props = defineProps({
  labels: { type: Array, default: () => [] },
  incomeData: { type: Array, default: () => [] },
  expenseData: { type: Array, default: () => [] },
})

const chartData = computed(() => ({
  labels: props.labels,
  datasets: [
    {
      label: 'Receita', data: props.incomeData,
      borderColor: '#10B981', backgroundColor: 'rgba(16,185,129,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    },
    {
      label: 'Gasto', data: props.expenseData,
      borderColor: '#EF4444', backgroundColor: 'rgba(239,68,68,0.1)',
      fill: true, tension: 0.4, pointRadius: 4,
    }
  ]
}))

const options = {
  responsive: true, maintainAspectRatio: false,
  scales: {
    x: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#94A3B8' } },
    y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#94A3B8', callback: (v) => `R$${v}` } }
  },
  plugins: { legend: { labels: { color: '#94A3B8', font: { family: 'Inter' } } } }
}
</script>

<template>
  <div style="height:220px;">
    <Line :data="chartData" :options="options" />
  </div>
</template>
```

- [ ] **Step 4: Criar src/components/dashboard/StatCard.vue**

```vue
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
```

- [ ] **Step 5: Criar src/components/timeline/TimelineMap.vue**

```vue
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
```

- [ ] **Step 6: Atualizar src/views/DashboardView.vue**

```vue
<script setup>
import { onMounted, ref } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import DonutChart from '@/components/charts/DonutChart.vue'
import TimelineMap from '@/components/timeline/TimelineMap.vue'
import { useDashboardStore } from '@/stores/dashboard'

const dash = useDashboardStore()

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

onMounted(async () => {
  await dash.fetchSummary()
  await dash.fetchTimeline()
})
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h1 class="page-title">Dashboard</h1>
      <p class="page-subtitle">Visão geral das suas finanças</p>
    </div>

    <div v-if="dash.loading" class="grid-4" style="margin-bottom:1.5rem">
      <div v-for="i in 4" :key="i" class="skeleton card" style="height:100px" />
    </div>

    <div v-else>
      <!-- Stat Cards -->
      <div class="grid-4" style="margin-bottom:1.5rem">
        <StatCard label="Receita do mês" :value="formatCurrency(dash.summary?.total_income)" icon="💰" variant="success" />
        <StatCard label="Total gasto" :value="formatCurrency(dash.summary?.total_expense)" icon="💸" variant="danger" />
        <StatCard label="Saldo disponível" :value="formatCurrency(dash.summary?.balance)" icon="🏦" />
        <StatCard label="Economizado" :value="`${dash.summary?.savings_percent || 0}%`" icon="📈" variant="success" :subtitle="`do total recebido`" />
      </div>

      <!-- Gráfico + Timeline -->
      <div class="grid-2" style="margin-bottom:1.5rem">
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Gastos por categoria</h3>
          <DonutChart :categories="dash.summary?.by_category || []" />
        </div>
        <div class="card">
          <h3 class="font-semibold" style="margin-bottom:1rem">Mapa financeiro</h3>
          <TimelineMap :events="dash.timeline" />
        </div>
      </div>
    </div>
  </AppLayout>
</template>
```

- [ ] **Step 7: Testar dashboard manualmente**

```bash
npm run dev
```

1. Fazer login
2. Abrir Dashboard → deve exibir 4 stat cards, gráfico donut e timeline
3. Registrar algumas transações via API (`POST /transactions`) e recarregar → verificar que os dados aparecem

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: dashboard view com stat cards, donut chart e timeline visual"
```

---

### Task 14: Views de Transações e Renda

**Files:**
- Create: `frontend/src/stores/transactions.js`
- Create: `frontend/src/stores/income.js`
- Create: `frontend/src/components/transactions/TransactionForm.vue`
- Modify: `frontend/src/views/TransactionsView.vue`
- Modify: `frontend/src/views/IncomeView.vue`

**Interfaces:**
- Consumes: `GET/POST/DELETE /transactions`, `GET/POST/DELETE /income`, `GET /categories`
- Produces: listagem de transações com filtro por mês, formulário de cadastro com suporte a parcelado/recorrente
- Produces: listagem de renda com formulário de cadastro

- [ ] **Step 1: Criar src/stores/transactions.js**

```javascript
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useTransactionsStore = defineStore('transactions', () => {
  const items = ref([])
  const total = ref(0)
  const categories = ref([])
  const loading = ref(false)

  async function fetchTransactions(params = {}) {
    loading.value = true
    try {
      const { data } = await api.get('/transactions', { params })
      items.value = data.items
      total.value = data.total
    } finally {
      loading.value = false
    }
  }

  async function fetchCategories() {
    const { data } = await api.get('/categories')
    categories.value = data
  }

  async function createTransaction(payload) {
    await api.post('/transactions', payload)
  }

  async function deleteTransaction(id) {
    await api.delete(`/transactions/${id}`)
  }

  async function createCategory(payload) {
    const { data } = await api.post('/categories', payload)
    categories.value.push(data)
    return data
  }

  return { items, total, categories, loading, fetchTransactions, fetchCategories, createTransaction, deleteTransaction, createCategory }
})
```

- [ ] **Step 2: Criar src/stores/income.js**

```javascript
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useIncomeStore = defineStore('income', () => {
  const entries = ref([])
  const summary = ref(null)
  const loading = ref(false)

  async function fetchIncome(params = {}) {
    loading.value = true
    try {
      const { data } = await api.get('/income', { params })
      entries.value = data
    } finally {
      loading.value = false
    }
  }

  async function fetchSummary() {
    const { data } = await api.get('/income/summary')
    summary.value = data
  }

  async function createIncome(payload) {
    await api.post('/income', payload)
  }

  async function deleteIncome(id) {
    await api.delete(`/income/${id}`)
  }

  return { entries, summary, loading, fetchIncome, fetchSummary, createIncome, deleteIncome }
})
```

- [ ] **Step 3: Atualizar src/views/TransactionsView.vue**

```vue
<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useTransactionsStore } from '@/stores/transactions'

const store = useTransactionsStore()
const showForm = ref(false)

const form = ref({
  description: '', amount: '', date: new Date().toISOString().slice(0, 10),
  type: 'expense', category_id: null, is_recurring: false,
  recurrence_period: null, installments_total: null
})
const error = ref('')

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}

async function submit() {
  error.value = ''
  try {
    const payload = {
      ...form.value,
      amount: parseFloat(form.value.amount),
      installments_total: form.value.installments_total ? parseInt(form.value.installments_total) : null,
    }
    await store.createTransaction(payload)
    showForm.value = false
    form.value = { description: '', amount: '', date: new Date().toISOString().slice(0, 10), type: 'expense', category_id: null, is_recurring: false, recurrence_period: null, installments_total: null }
    await store.fetchTransactions()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

async function remove(id) {
  if (!confirm('Deletar transação?')) return
  await store.deleteTransaction(id)
  await store.fetchTransactions()
}

onMounted(async () => {
  await store.fetchCategories()
  await store.fetchTransactions()
})
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Transações</h1>
        <p class="page-subtitle">{{ store.total }} transação(ões) registradas</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Nova transação</button>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Nova transação</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Descrição</label>
          <input v-model="form.description" class="form-input" required placeholder="Ex: Conta de luz" />
        </div>
        <div class="form-group">
          <label class="form-label">Valor (R$)</label>
          <input v-model="form.amount" class="form-input" type="number" step="0.01" required placeholder="0,00" />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="form.date" class="form-input" type="date" required />
        </div>
        <div class="form-group">
          <label class="form-label">Tipo</label>
          <select v-model="form.type" class="form-input">
            <option value="expense">Gasto</option>
            <option value="income">Receita</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Categoria</label>
          <select v-model="form.category_id" class="form-input">
            <option :value="null">Sem categoria</option>
            <option v-for="cat in store.categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Recorrente?</label>
          <select v-model="form.is_recurring" class="form-input">
            <option :value="false">Não</option>
            <option :value="true">Sim</option>
          </select>
        </div>
        <div class="form-group" v-if="form.is_recurring">
          <label class="form-label">Período</label>
          <select v-model="form.recurrence_period" class="form-input">
            <option value="monthly">Mensal</option>
            <option value="weekly">Semanal</option>
            <option value="yearly">Anual</option>
          </select>
        </div>
        <div class="form-group" v-if="!form.is_recurring">
          <label class="form-label">Parcelas (1 = sem parcelamento)</label>
          <input v-model="form.installments_total" class="form-input" type="number" min="1" max="60" placeholder="1" />
        </div>
        <div v-if="error" class="error-msg" style="grid-column:1/-1">{{ error }}</div>
        <div style="grid-column:1/-1;display:flex;gap:0.75rem">
          <button type="submit" class="btn btn-primary">Salvar</button>
          <button type="button" class="btn btn-secondary" @click="showForm = false">Cancelar</button>
        </div>
      </form>
    </div>

    <!-- Lista -->
    <div class="card">
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">Nenhuma transação encontrada.</div>
      <table v-else class="tx-table">
        <thead>
          <tr>
            <th>Descrição</th><th>Data</th><th>Tipo</th><th>Valor</th><th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="tx in store.items" :key="tx.id">
            <td>
              {{ tx.description }}
              <span v-if="tx.installments_total" class="badge badge-info" style="margin-left:0.5rem">
                {{ tx.installments_current }}/{{ tx.installments_total }}
              </span>
              <span v-if="tx.is_recurring" class="badge badge-warning" style="margin-left:0.5rem">Recorrente</span>
            </td>
            <td class="text-muted">{{ formatDate(tx.date) }}</td>
            <td>
              <span :class="['badge', tx.type === 'income' ? 'badge-success' : 'badge-danger']">
                {{ tx.type === 'income' ? 'Receita' : 'Gasto' }}
              </span>
            </td>
            <td :class="tx.type === 'income' ? 'text-success' : 'text-danger'" class="font-semibold">
              {{ tx.type === 'income' ? '+' : '-' }}{{ formatCurrency(tx.amount) }}
            </td>
            <td>
              <button class="btn btn-danger btn-sm" @click="remove(tx.id)">Excluir</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppLayout>
</template>

<style scoped>
.tx-table { width: 100%; border-collapse: collapse; }
.tx-table th { text-align: left; padding: 0.5rem 0.75rem; font-size: var(--font-size-xs); color: var(--text-muted); font-weight: 600; border-bottom: 1px solid var(--border-subtle); }
.tx-table td { padding: 0.75rem; border-bottom: 1px solid var(--border-subtle); font-size: var(--font-size-sm); }
.tx-table tr:last-child td { border-bottom: none; }
.error-msg { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 4: Atualizar src/views/IncomeView.vue**

```vue
<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useIncomeStore } from '@/stores/income'

const store = useIncomeStore()
const showForm = ref(false)
const form = ref({ amount: '', date: new Date().toISOString().slice(0, 10), source: '', is_recurring: false, recurrence_period: null, notes: '' })
const error = ref('')

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}
function formatDate(d) {
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}

async function submit() {
  error.value = ''
  try {
    await store.createIncome({ ...form.value, amount: parseFloat(form.value.amount) })
    showForm.value = false
    form.value = { amount: '', date: new Date().toISOString().slice(0, 10), source: '', is_recurring: false, recurrence_period: null, notes: '' }
    await store.fetchIncome()
    await store.fetchSummary()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

async function remove(id) {
  if (!confirm('Deletar entrada de renda?')) return
  await store.deleteIncome(id)
  await store.fetchIncome()
  await store.fetchSummary()
}

onMounted(async () => {
  await store.fetchIncome()
  await store.fetchSummary()
})
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Renda</h1>
        <p class="page-subtitle">Gerencie suas fontes de receita</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Nova entrada</button>
    </div>

    <!-- Resumo de renda -->
    <div class="grid-2" style="margin-bottom:1.5rem" v-if="store.summary">
      <div class="card">
        <div class="text-muted text-sm">Média últimos 3 meses</div>
        <div class="font-bold text-success" style="font-size:var(--font-size-2xl)">{{ formatCurrency(store.summary.average_last_3_months) }}</div>
      </div>
      <div class="card">
        <div class="text-muted text-sm">Total este mês</div>
        <div class="font-bold" style="font-size:var(--font-size-2xl)">{{ formatCurrency(store.summary.total_this_month) }}</div>
      </div>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Nova entrada de renda</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group">
          <label class="form-label">Valor (R$)</label>
          <input v-model="form.amount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="form.date" class="form-input" type="date" required />
        </div>
        <div class="form-group">
          <label class="form-label">Fonte</label>
          <input v-model="form.source" class="form-input" required placeholder="Salário, Freela..." />
        </div>
        <div class="form-group">
          <label class="form-label">Recorrente?</label>
          <select v-model="form.is_recurring" class="form-input">
            <option :value="false">Não</option>
            <option :value="true">Sim</option>
          </select>
        </div>
        <div class="form-group" v-if="form.is_recurring">
          <label class="form-label">Período</label>
          <select v-model="form.recurrence_period" class="form-input">
            <option value="monthly">Mensal</option>
            <option value="weekly">Semanal</option>
            <option value="yearly">Anual</option>
          </select>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Observações</label>
          <input v-model="form.notes" class="form-input" placeholder="Opcional" />
        </div>
        <div v-if="error" class="error-msg" style="grid-column:1/-1">{{ error }}</div>
        <div style="grid-column:1/-1;display:flex;gap:0.75rem">
          <button type="submit" class="btn btn-primary">Salvar</button>
          <button type="button" class="btn btn-secondary" @click="showForm = false">Cancelar</button>
        </div>
      </form>
    </div>

    <!-- Lista -->
    <div class="card">
      <div v-if="!store.entries.length" style="text-align:center;padding:2rem;color:var(--text-muted)">Nenhuma entrada registrada.</div>
      <table v-else class="tx-table">
        <thead><tr><th>Fonte</th><th>Data</th><th>Valor</th><th>Tipo</th><th></th></tr></thead>
        <tbody>
          <tr v-for="entry in store.entries" :key="entry.id">
            <td>{{ entry.source }}</td>
            <td class="text-muted">{{ formatDate(entry.date) }}</td>
            <td class="text-success font-semibold">{{ formatCurrency(entry.amount) }}</td>
            <td><span :class="['badge', entry.is_recurring ? 'badge-info' : 'badge-warning']">{{ entry.is_recurring ? 'Recorrente' : 'Pontual' }}</span></td>
            <td><button class="btn btn-danger btn-sm" @click="remove(entry.id)">Excluir</button></td>
          </tr>
        </tbody>
      </table>
    </div>
  </AppLayout>
</template>

<style scoped>
.tx-table { width: 100%; border-collapse: collapse; }
.tx-table th { text-align: left; padding: 0.5rem 0.75rem; font-size: var(--font-size-xs); color: var(--text-muted); font-weight: 600; border-bottom: 1px solid var(--border-subtle); }
.tx-table td { padding: 0.75rem; border-bottom: 1px solid var(--border-subtle); font-size: var(--font-size-sm); }
.tx-table tr:last-child td { border-bottom: none; }
.error-msg { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 5: Testar manualmente**

1. Acessar `/transactions` → cadastrar gasto simples, recorrente e parcelado
2. Verificar que parcelado aparece com badge "1/3", "2/3", "3/3"
3. Acessar `/income` → cadastrar salário recorrente e renda extra pontual
4. Verificar que summary mostra média e total corretos

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: views de transações e renda com formulários e listagem"
```

---

### Task 15: View de Planos com Simulador

**Files:**
- Create: `frontend/src/stores/plans.js`
- Create: `frontend/src/components/plans/PlanCard.vue`
- Create: `frontend/src/components/plans/PlanSimulator.vue`
- Modify: `frontend/src/views/PlansView.vue`

**Interfaces:**
- Consumes: `GET/POST/PUT/DELETE /plans`, `POST /plans/{id}/contributions`, `GET /plans/{id}/simulate`
- Produces: listagem de planos com cards visuais, simulador interativo com slider, formulário de criação/edição

- [ ] **Step 1: Criar src/stores/plans.js**

```javascript
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const usePlansStore = defineStore('plans', () => {
  const plans = ref([])
  const loading = ref(false)

  async function fetchPlans() {
    loading.value = true
    try {
      const { data } = await api.get('/plans')
      plans.value = data
    } finally {
      loading.value = false
    }
  }

  async function createPlan(payload) {
    const { data } = await api.post('/plans', payload)
    return data
  }

  async function updatePlan(id, payload) {
    const { data } = await api.put(`/plans/${id}`, payload)
    return data
  }

  async function deletePlan(id) {
    await api.delete(`/plans/${id}`)
  }

  async function addContribution(planId, payload) {
    await api.post(`/plans/${planId}/contributions`, payload)
  }

  async function simulate(planId, monthlyContribution) {
    const { data } = await api.get(`/plans/${planId}/simulate`, {
      params: { monthly_contribution: monthlyContribution }
    })
    return data
  }

  return { plans, loading, fetchPlans, createPlan, updatePlan, deletePlan, addContribution, simulate }
})
```

- [ ] **Step 2: Criar src/components/plans/PlanCard.vue**

```vue
<script setup>
import { ref } from 'vue'
import { usePlansStore } from '@/stores/plans'

const props = defineProps({ plan: Object })
const emit = defineEmits(['refresh'])
const store = usePlansStore()

const showContrib = ref(false)
const contribAmount = ref('')
const contribDate = ref(new Date().toISOString().slice(0, 10))

const statusLabels = { active: 'Ativo', paused: 'Pausado', cancelled: 'Cancelado', completed: 'Concluído' }
const statusVariants = { active: 'badge-success', paused: 'badge-warning', cancelled: 'badge-danger', completed: 'badge-info' }

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

async function submitContrib() {
  await store.addContribution(props.plan.id, {
    amount: parseFloat(contribAmount.value),
    date: contribDate.value,
  })
  showContrib.value = false
  contribAmount.value = ''
  emit('refresh')
}

async function remove() {
  if (!confirm(`Deletar plano "${props.plan.name}"?`)) return
  await store.deletePlan(props.plan.id)
  emit('refresh')
}

async function toggleStatus(status) {
  await store.updatePlan(props.plan.id, { status })
  emit('refresh')
}
</script>

<template>
  <div class="card plan-card">
    <div class="plan-header">
      <div>
        <h3 class="font-semibold">{{ plan.name }}</h3>
        <span :class="['badge', statusVariants[plan.status]]">{{ statusLabels[plan.status] }}</span>
      </div>
      <div class="plan-actions">
        <button v-if="plan.status === 'active'" class="btn btn-secondary btn-sm" @click="toggleStatus('paused')">Pausar</button>
        <button v-if="plan.status === 'paused'" class="btn btn-secondary btn-sm" @click="toggleStatus('active')">Retomar</button>
        <button class="btn btn-danger btn-sm" @click="remove">Excluir</button>
      </div>
    </div>

    <div class="plan-amounts">
      <div>
        <div class="text-muted text-sm">Guardado</div>
        <div class="font-bold text-success">{{ formatCurrency(plan.current_savings) }}</div>
      </div>
      <div>
        <div class="text-muted text-sm">Meta</div>
        <div class="font-bold">{{ formatCurrency(plan.target_amount) }}</div>
      </div>
      <div v-if="plan.simulation">
        <div class="text-muted text-sm">Faltam</div>
        <div class="font-bold">
          {{ plan.simulation.months_to_goal != null ? `${plan.simulation.months_to_goal} meses` : '∞' }}
        </div>
      </div>
    </div>

    <div class="progress-bar" style="margin:0.75rem 0">
      <div class="progress-fill" :style="{ width: `${plan.simulation?.progress_percent || 0}%` }" />
    </div>
    <div class="text-muted text-sm" style="text-align:right">{{ (plan.simulation?.progress_percent || 0).toFixed(1) }}% concluído</div>

    <!-- Sub-planos -->
    <div v-if="plan.sub_plans?.length" class="sub-plans">
      <div class="text-muted text-sm font-semibold" style="margin-bottom:0.5rem">Sub-planos</div>
      <div v-for="sub in plan.sub_plans" :key="sub.id" class="sub-plan-item">
        <span>{{ sub.name }}</span>
        <span class="text-muted text-sm">{{ formatCurrency(sub.current_savings) }} / {{ formatCurrency(sub.target_amount) }}</span>
      </div>
    </div>

    <!-- Aporte -->
    <div style="margin-top:1rem">
      <button class="btn btn-secondary btn-sm" @click="showContrib = !showContrib">+ Registrar aporte</button>
      <form v-if="showContrib" @submit.prevent="submitContrib" style="margin-top:0.75rem;display:flex;gap:0.75rem;align-items:flex-end">
        <div class="form-group" style="flex:1">
          <label class="form-label">Valor (R$)</label>
          <input v-model="contribAmount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Data</label>
          <input v-model="contribDate" class="form-input" type="date" required />
        </div>
        <button type="submit" class="btn btn-primary btn-sm">Salvar</button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.plan-card { display: flex; flex-direction: column; gap: 0.5rem; }
.plan-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.75rem; }
.plan-actions { display: flex; gap: 0.5rem; }
.plan-amounts { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
.sub-plans { margin-top: 0.5rem; padding-top: 0.75rem; border-top: 1px solid var(--border-subtle); }
.sub-plan-item { display: flex; justify-content: space-between; padding: 0.375rem 0; font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 3: Criar src/components/plans/PlanSimulator.vue**

```vue
<script setup>
import { ref, watch } from 'vue'
import { usePlansStore } from '@/stores/plans'

const props = defineProps({ plan: Object })
const store = usePlansStore()

const contribution = ref(props.plan.monthly_contribution)
const result = ref(props.plan.simulation)
let debounceTimer = null

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

watch(contribution, async (newVal) => {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(async () => {
    if (newVal > 0) {
      result.value = await store.simulate(props.plan.id, newVal)
    }
  }, 400)
})
</script>

<template>
  <div class="simulator card" style="margin-top:0.75rem">
    <div class="font-semibold text-sm" style="margin-bottom:0.75rem">🧮 Simulador interativo</div>
    <div class="form-group">
      <label class="form-label">Contribuição mensal: {{ formatCurrency(contribution) }}</label>
      <input
        v-model.number="contribution" type="range"
        :min="100" :max="plan.target_amount" :step="50"
        class="slider"
      />
    </div>
    <div v-if="result" class="sim-result">
      <div>
        <div class="text-muted" style="font-size:0.7rem">Prazo</div>
        <div class="font-bold">{{ result.months_to_goal != null ? `${result.months_to_goal} meses` : 'Indefinido' }}</div>
      </div>
      <div v-if="result.estimated_date">
        <div class="text-muted" style="font-size:0.7rem">Data estimada</div>
        <div class="font-bold">{{ new Date(result.estimated_date + 'T00:00:00').toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }) }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.sim-result { display: flex; gap: 2rem; margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid var(--border-subtle); }
.slider { width: 100%; accent-color: var(--accent-primary); }
</style>
```

- [ ] **Step 4: Atualizar src/views/PlansView.vue**

```vue
<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import PlanCard from '@/components/plans/PlanCard.vue'
import PlanSimulator from '@/components/plans/PlanSimulator.vue'
import { usePlansStore } from '@/stores/plans'

const store = usePlansStore()
const showForm = ref(false)
const form = ref({
  name: '', description: '', target_amount: '', current_savings: '0',
  monthly_contribution: '', deadline: null, priority: 1, parent_plan_id: null
})
const error = ref('')

async function submit() {
  error.value = ''
  try {
    await store.createPlan({
      ...form.value,
      target_amount: parseFloat(form.value.target_amount),
      current_savings: parseFloat(form.value.current_savings || 0),
      monthly_contribution: parseFloat(form.value.monthly_contribution),
      parent_plan_id: form.value.parent_plan_id ? parseInt(form.value.parent_plan_id) : null,
      deadline: form.value.deadline || null,
    })
    showForm.value = false
    form.value = { name: '', description: '', target_amount: '', current_savings: '0', monthly_contribution: '', deadline: null, priority: 1, parent_plan_id: null }
    await store.fetchPlans()
  } catch (e) {
    error.value = e.response?.data?.detail || 'Erro ao salvar'
  }
}

onMounted(store.fetchPlans)
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Planos</h1>
        <p class="page-subtitle">Seus objetivos financeiros</p>
      </div>
      <button class="btn btn-primary" @click="showForm = !showForm">+ Novo plano</button>
    </div>

    <!-- Formulário -->
    <div v-if="showForm" class="card animate-fade-in" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Novo plano</h3>
      <form @submit.prevent="submit" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Nome do plano</label>
          <input v-model="form.name" class="form-input" required placeholder="Ex: Viagem ao Japão" />
        </div>
        <div class="form-group">
          <label class="form-label">Valor alvo (R$)</label>
          <input v-model="form.target_amount" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Já guardado (R$)</label>
          <input v-model="form.current_savings" class="form-input" type="number" step="0.01" />
        </div>
        <div class="form-group">
          <label class="form-label">Contribuição mensal (R$)</label>
          <input v-model="form.monthly_contribution" class="form-input" type="number" step="0.01" required />
        </div>
        <div class="form-group">
          <label class="form-label">Prazo máximo (opcional)</label>
          <input v-model="form.deadline" class="form-input" type="date" />
        </div>
        <div class="form-group">
          <label class="form-label">Plano pai (sub-plano de...)</label>
          <select v-model="form.parent_plan_id" class="form-input">
            <option :value="null">Nenhum (plano raiz)</option>
            <option v-for="p in store.plans.filter(p => !p.parent_plan_id)" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Descrição</label>
          <input v-model="form.description" class="form-input" placeholder="Opcional" />
        </div>
        <div v-if="error" class="error-msg" style="grid-column:1/-1">{{ error }}</div>
        <div style="grid-column:1/-1;display:flex;gap:0.75rem">
          <button type="submit" class="btn btn-primary">Criar plano</button>
          <button type="button" class="btn btn-secondary" @click="showForm = false">Cancelar</button>
        </div>
      </form>
    </div>

    <!-- Lista de planos -->
    <div v-if="store.loading" class="grid-2">
      <div v-for="i in 3" :key="i" class="skeleton" style="height:200px;border-radius:var(--radius-lg)" />
    </div>
    <div v-else-if="!store.plans.length" class="card" style="text-align:center;padding:3rem">
      <div style="font-size:3rem;margin-bottom:1rem">🎯</div>
      <p class="text-muted">Nenhum plano criado ainda. Crie seu primeiro objetivo!</p>
    </div>
    <div v-else class="grid-2">
      <div v-for="plan in store.plans" :key="plan.id">
        <PlanCard :plan="plan" @refresh="store.fetchPlans()" />
        <PlanSimulator v-if="plan.status === 'active'" :plan="plan" />
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.error-msg { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
```

- [ ] **Step 5: Testar a view de planos manualmente**

1. Criar um plano "Viagem Japão" com meta R$15.000, guardado R$1.000, contribuição R$800
2. Verificar que card mostra barra de progresso e "Faltam X meses"
3. Usar o slider do simulador e verificar que o prazo muda em tempo real
4. Criar sub-plano vinculado ao plano pai
5. Registrar um aporte e verificar que `current_savings` aumenta

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: view de planos com cards, sub-planos e simulador interativo"
```

---

### Task 16: README e Verificação Final

**Files:**
- Create: `README.md`
- Verify: todos os endpoints funcionando via Swagger UI

**Interfaces:** Nenhuma — documentação e verificação apenas.

- [ ] **Step 1: Criar README.md**

```markdown
# AnalisadorFinanceiro

Plataforma de análise e planejamento financeiro pessoal.

## Stack
- **Backend:** Python + FastAPI + SQLite (SQLAlchemy async) + JWT
- **Frontend:** Vue.js 3 + Vite + Pinia

## Como rodar localmente

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Docs disponíveis em: http://localhost:8000/docs

### Frontend
```bash
cd frontend
npm install
npm run dev
```

Acesse: http://localhost:5173

### Rodar testes do backend
```bash
cd backend
source .venv/bin/activate
pytest -v
```
```

- [ ] **Step 2: Verificação final end-to-end**

Com backend e frontend rodando simultaneamente:
1. Criar conta → fazer login
2. Cadastrar categorias (Energia, Transporte, Alimentação)
3. Cadastrar renda mensal (R$5.000)
4. Cadastrar conta de luz (R$250, recorrente, mensal)
5. Cadastrar tênis parcelado (R$100 x 3 meses)
6. Criar plano "Viagem Japão" (meta R$15.000, contribuição R$800)
7. Criar sub-plano "Passagem" (meta R$5.000, pai = Viagem Japão)
8. Verificar Dashboard: cards corretos, donut chart, timeline com eventos
9. Ajustar slider do simulador e ver prazo mudar
10. Registrar aporte de R$500 → verificar progresso aumenta

- [ ] **Step 3: Commit final**

```bash
git add .
git commit -m "docs: README e verificação final end-to-end"
```

---

## Self-Review do Plano 3

**Spec coverage:**
- ✅ Login/Register com JWT — Task 11
- ✅ Sidebar + layout dark mode glassmorphism — Task 12
- ✅ Dashboard: stat cards, donut chart, timeline visual — Task 13
- ✅ Transações: fixas, recorrentes, parceladas com badges — Task 14
- ✅ Renda: recorrente e pontual com summary — Task 14
- ✅ Planos com sub-planos, barra de progresso, aportes — Task 15
- ✅ Simulador interativo com slider em tempo real — Task 15
- ✅ Timeline visual com eventos coloridos e scroll — Task 13

**Placeholder scan:** Nenhum TBD encontrado. Todos os componentes têm código completo.

**Type consistency:**
- `store.plans` retorna `PlanDetailResponse[]` com campo `simulation` — `PlanCard.vue` usa `plan.simulation.months_to_goal` ✅
- `api.js` com interceptor JWT — todos os stores usam `api` importado de `@/services/api` ✅
- `formatCurrency` definida localmente em cada view (sem store compartilhado) — padrão consistente ✅
