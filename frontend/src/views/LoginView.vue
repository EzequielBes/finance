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
      <div class="login-brand">
        <div class="login-mark">Finança</div>
        <h1 class="login-title">Bem-vindo de volta</h1>
        <p class="login-sub text-muted">Controle total da sua vida financeira</p>
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
  background: radial-gradient(ellipse at 50% 20%, #241d17 0%, var(--bg-primary) 65%);
}
.login-container { width: 100%; max-width: 400px; padding: 1rem; }
.login-brand { text-align: center; margin-bottom: 2.5rem; }
.login-mark {
  font-family: var(--font-sans); font-size: var(--font-size-sm); letter-spacing: 0.15em;
  text-transform: uppercase; color: var(--accent-primary); margin-bottom: 0.625rem;
}
.login-title { font-family: var(--font-serif); font-size: 1.875rem; font-weight: 500; color: var(--text-primary); }
.login-sub { font-family: var(--font-sans); font-size: var(--font-size-sm); margin-top: 0.5rem; }
.login-card { padding: 2rem; }
.tab-row {
  display: flex; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-subtle);
  font-family: var(--font-sans); font-size: var(--font-size-sm);
}
.tab-btn {
  padding: 0.5rem 0; margin-right: 1.5rem; color: var(--text-muted);
  background: none; border: none; cursor: pointer; position: relative;
  font-family: var(--font-sans); font-size: var(--font-size-sm);
  transition: color var(--transition-fast);
}
.tab-btn.active { color: var(--text-primary); }
.tab-btn.active::after {
  content: ''; position: absolute; bottom: -1px; left: 0; right: 0;
  height: 2px; background: var(--accent-primary);
}
.form-stack { display: flex; flex-direction: column; gap: 1rem; }
.error-msg { background: rgba(184,86,58,0.12); border: 1px solid rgba(184,86,58,0.3); color: var(--accent-danger); padding: 0.625rem; border-radius: var(--radius-sm); font-size: var(--font-size-sm); }
</style>
