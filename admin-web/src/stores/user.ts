import { defineStore } from 'pinia'
import { adminLogin } from '../api/modules'

const TOKEN_KEY = 'admin_token'
const USERNAME_KEY = 'admin_username'
const ADMIN_ROLE_KEY = 'admin_role'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem(TOKEN_KEY) || '',
    username: localStorage.getItem(USERNAME_KEY) || '',
    // SUPER_ADMIN / OPERATOR（RBAC 2.1.8，决定菜单与操作可见性）
    adminRole: localStorage.getItem(ADMIN_ROLE_KEY) || 'OPERATOR'
  }),
  getters: {
    loggedIn: (state) => !!state.token,
    isSuperAdmin: (state) => state.adminRole === 'SUPER_ADMIN'
  },
  actions: {
    async login(username: string, password: string) {
      const data: any = await adminLogin({ username, password })
      this.token = data.accessToken
      this.username = username
      this.adminRole = data.adminRole ?? 'OPERATOR'
      localStorage.setItem(TOKEN_KEY, data.accessToken)
      localStorage.setItem(USERNAME_KEY, username)
      localStorage.setItem(ADMIN_ROLE_KEY, this.adminRole)
    },
    logout() {
      this.token = ''
      this.username = ''
      this.adminRole = 'OPERATOR'
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USERNAME_KEY)
      localStorage.removeItem(ADMIN_ROLE_KEY)
    }
  }
})
