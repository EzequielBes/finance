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
