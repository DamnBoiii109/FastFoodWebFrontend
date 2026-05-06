<template>
  <div class="toast" :class="{ show: !!toast.msg }">
    <span>{{ toast.icon }}</span>
    <span class="toast-text">{{ toast.msg }}</span>
  </div>
</template>

<script setup>
import { useToastStore } from '../stores/toast'
const toast = useToastStore()
</script>

<style scoped>
.toast {
  position: fixed; bottom: 28px; right: 28px; z-index: 9999;
  background: rgba(14,10,10,.95); border: 1px solid rgba(255,255,255,.1);
  backdrop-filter: blur(12px); border-radius: 13px;
  padding: 12px 18px; display: flex; align-items: center; gap: 9px;
  transform: translateX(120%);
  transition: transform .4s cubic-bezier(.34,1.56,.64,1);
  min-width: 210px; font-family: 'Nunito', sans-serif;
  pointer-events: none;
}
.toast.show { transform: translateX(0); }
.toast-text { font-size: .84rem; font-weight: 700; color: #f5ede6; }
</style>