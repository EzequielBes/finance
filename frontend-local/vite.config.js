import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    vue(),
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'AnalisadorFinanceiro (Local)',
        short_name: 'AF Local',
        description: 'Controle financeiro pessoal, 100% local no dispositivo.',
        theme_color: '#1a1613',
        background_color: '#1a1613',
        display: 'standalone',
        icons: [
          {
            src: '/icon-placeholder.svg',
            sizes: '192x192',
            type: 'image/svg+xml',
          },
          {
            src: '/icon-placeholder.svg',
            sizes: '512x512',
            type: 'image/svg+xml',
          },
        ],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5174,
  },
})
