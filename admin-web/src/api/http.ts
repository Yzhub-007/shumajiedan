import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

const TOKEN_KEY = 'admin_token'

const http = axios.create({
  baseURL: '',
  timeout: 15000
})

http.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 后端统一响应：{ code, message, data }，code=0 成功
http.interceptors.response.use(
  (resp): any => {
    const body = resp.data
    if (body && typeof body.code === 'number') {
      if (body.code === 0) return body.data
      if (body.code === 40100) {
        localStorage.removeItem(TOKEN_KEY)
        router.push('/login')
      }
      ElMessage.error(body.message || '请求失败')
      return Promise.reject(body)
    }
    return body
  },
  (error) => {
    const message = error?.response?.data?.message || '网络异常，请稍后再试'
    ElMessage.error(message)
    return Promise.reject(error)
  }
)

export default http
