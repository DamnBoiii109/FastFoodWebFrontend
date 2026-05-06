<template>
  <header class="topbar">
    <div class="page-title">{{ title }} <span>{{ highlight }}</span></div>
    <div class="topbar-right">
      <div class="clock">{{ clock }}</div>
      <router-link to="/ho-so" class="icon-btn" title="Hồ Sơ">👤</router-link>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
defineProps({ title: String, highlight: String })
const clock = ref('')
let timer
function tick() { clock.value = new Date().toLocaleTimeString('vi', { hour: '2-digit', minute: '2-digit' }) }
onMounted(() => { tick(); timer = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@700;800;900&display=swap');

.topbar {
  position: sticky; top: 0; z-index: 100;
  background: rgba(14,10,10,0.88);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  border-bottom: 1px solid rgba(255,255,255,0.08);
  padding: 0 28px; height: 64px;
  display: flex; align-items: center; justify-content: space-between;
}

.page-title {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.5rem; letter-spacing: 0.06em; color: #fff;
}
.page-title span { color: #ffcc00; }

.topbar-right { display: flex; align-items: center; gap: 12px; }

.clock {
  font-size: 0.78rem; font-weight: 700; color: rgba(245,237,230,0.5);
  background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08);
  padding: 5px 12px; border-radius: 50px;
  letter-spacing: 0.04em;
}

.icon-btn {
  width: 38px; height: 38px;
  background: rgba(255,255,255,0.05);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 0.95rem; text-decoration: none;
  transition: background 0.2s, border-color 0.2s, box-shadow 0.2s;
}
.icon-btn:hover {
  background: rgba(232,39,58,0.15);
  border-color: rgba(232,39,58,0.25);
  box-shadow: 0 0 12px rgba(232,39,58,0.2);
}
</style>