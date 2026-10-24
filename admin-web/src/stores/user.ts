import { defineStore } from 'pinia'
import { adminLogin } from '../api/modules'

const TOKEN_KEY = 'admin_token'
const USERNAME_KEY = 'admin_username'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem(TOKEN_KEY) || '',
    username: localStorage.getItem(USERNAME_KEY) || ''
  }),
  getters: {
    loggedIn: (state) => !!state.token
  },
  actions: {
    async login(username: string, password: string) {
      const data: any = await adminLogin({ username, password })
      this.token = data.accessToken
      this.username = username
      localStorage.setItem(TOKEN_KEY, data.accessToken)
      localStorage.setItem(USERNAME_KEY, username)
    },
    logout() {
      this.token = ''
      this.username = ''
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USERNAME_KEY)
    }
  }
})
