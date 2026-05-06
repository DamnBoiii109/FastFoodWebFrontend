import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useToastStore = defineStore('toast', () => {
  const msg  = ref('')
  const icon = ref('✅')
  let timer  = null

  function show(message, type = 'success') {
    const iconMap = { success: '✅', error: '❌', warning: '⚠️', info: 'ℹ️', delete: '🗑️' }
    icon.value = iconMap[type] || '✅'
    msg.value  = message
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => { msg.value = '' }, 2500)
  }

  return { msg, icon, show }
})