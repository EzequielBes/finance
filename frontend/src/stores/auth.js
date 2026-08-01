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
