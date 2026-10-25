import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 代理目标可用环境变量覆盖：容器内编排时指向 http://backend:8080（见 docker-compose.local.yml）
const apiTarget = process.env.VITE_PROXY_TARGET || 'http://localhost:8080'
const wsTarget = process.env.VITE_WS_PROXY_TARGET || 'ws://localhost:8080'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    port: 5173,
    proxy: {
      '/api': apiTarget,
      '/admin': apiTarget,
      '/uploads': apiTarget,
      '/ws': { target: wsTarget, ws: true }
    }
  }
})
