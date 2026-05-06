import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authAPI } from '../services/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))
  const token = ref(localStorage.getItem('token') || null)

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.vaiTro === 'admin')
  const isNhanVien = computed(() =>
    user.value?.vaiTro === 'nhanvien' || user.value?.vaiTro === 'admin')

  async function login(email, matKhau) {
    const res = await authAPI.login({ email, matKhau })
    const data = res.data.data
    token.value = data.token
    user.value = { id: data.id, hoTen: data.hoTen, email: data.email, vaiTro: data.vaiTro }
    localStorage.setItem('token', data.token)
    localStorage.setItem('user', JSON.stringify(user.value))
    return data
  }

  async function register(hoTen, email, matKhau) {
    const res = await authAPI.register({ hoTen, email, matKhau })
    const data = res.data.data
    token.value = data.token
    user.value = { id: data.id, hoTen: data.hoTen, email: data.email, vaiTro: data.vaiTro }
    localStorage.setItem('token', data.token)
    localStorage.setItem('user', JSON.stringify(user.value))
    return data
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  async function fetchMe() {
    if (!token.value) return
    try {
      const res = await authAPI.me()
      user.value = res.data.data
      localStorage.setItem('user', JSON.stringify(user.value))
    } catch {
      logout()
    }
  }
async function loginWithGoogle(credential) {
  const res = await authAPI.loginWithGoogle(credential)
  const data = res.data.data
  token.value = data.token
  user.value = { id: data.id, hoTen: data.hoTen, email: data.email, vaiTro: data.vaiTro }
  localStorage.setItem('token', data.token)
  localStorage.setItem('user', JSON.stringify(user.value))
  return data
}
  return { user, token, isLoggedIn, isAdmin, isNhanVien, login, register, logout, fetchMe, loginWithGoogle }
})