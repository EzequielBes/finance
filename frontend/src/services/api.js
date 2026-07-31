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
