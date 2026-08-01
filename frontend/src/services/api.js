import axios from 'axios'
import router from '@/router'

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

const AUTH_ENDPOINTS = ['/auth/login', '/auth/register']

// Redirecionar para login se 401 em uma rota autenticada (não na própria tentativa de login/registro)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isAuthEndpoint = AUTH_ENDPOINTS.some((path) => error.config?.url?.includes(path))
    if (error.response?.status === 401 && !isAuthEndpoint) {
      localStorage.removeItem('af_token')
      if (router.currentRoute.value.name !== 'Login') {
        router.push('/login')
      }
    }
    return Promise.reject(error)
  }
)

export default api
