<template>
  <div class="auth-page">
    <div class="bg-photo"></div>
    <div class="bg-gradient"></div>
    <div class="grain"></div>
    <div class="particles" ref="particlesRef"></div>

    <div class="page">
      <!-- Brand -->
      <div class="brand">
        <div class="brand-logo">
          <div class="brand-icon">🍔</div>
          <div class="brand-name">FastFood<span>YumMy</span></div>
        </div>
        <p class="brand-tagline">Ngon · Nhanh · Đỉnh</p>
      </div>

      <!-- Card -->
      <div class="card" ref="cardRef" @mousemove="onMouseMove" @mouseleave="onMouseLeave" @mouseenter="onMouseEnter">
        <div class="scanlines"></div>
        <div class="card-title">ĐĂNG KÝ TÀI KHOẢN</div>

        <div v-if="error" class="auth-error">⚠️ {{ error }}</div>

        <!-- Họ Tên -->
        <div class="field-row">
          <div class="form-group">
            <input v-model="form.lastName" type="text" placeholder="Họ" class="finput" autocomplete="family-name">
            <span class="field-icon">👤</span>
          </div>
          <div class="form-group">
            <input v-model="form.firstName" type="text" placeholder="Tên" class="finput" autocomplete="given-name">
          </div>
        </div>

        <!-- Email -->
        <div class="form-group anim-2">
          <input v-model="form.email" type="email" placeholder="E-mail" class="finput" autocomplete="email">
          <span class="field-icon">✉️</span>
        </div>

        <!-- Phone -->
        <div class="form-group anim-3">
          <input v-model="form.phone" type="tel" placeholder="Số điện thoại" class="finput" autocomplete="tel">
          <span class="field-icon">📱</span>
        </div>

        <!-- Password -->
        <div class="form-group anim-4">
          <input v-model="form.matKhau" :type="showPwd ? 'text' : 'password'" placeholder="Mật khẩu" class="finput" autocomplete="new-password">
          <button type="button" class="pwd-toggle" @click="showPwd = !showPwd">
            <span>{{ showPwd ? '🙈' : '👁️' }}</span>
          </button>
          <!-- Strength bar -->
          <div v-if="form.matKhau" class="strength-bar">
            <div class="strength-fill" :style="{ width: strength.pct + '%', background: strength.color }"></div>
          </div>
          <div v-if="form.matKhau" class="strength-label" :style="{ color: strength.color }">{{ strength.label }}</div>
        </div>

        <!-- Confirm Password -->
        <div class="form-group anim-5">
          <input
            v-model="form.confirm"
            type="password"
            placeholder="Xác nhận mật khẩu"
            class="finput"
            :class="{ 'input-error': form.confirm && form.confirm !== form.matKhau }"
            autocomplete="new-password"
          >
          <button type="button" class="pwd-toggle" @click="showPwd2 = !showPwd2">
            <span>{{ showPwd2 ? '🙈' : '👁️' }}</span>
          </button>
          <div v-if="form.confirm && form.confirm !== form.matKhau" class="field-error">Mật khẩu không khớp</div>
        </div>

        <!-- Terms -->
        <div class="terms-row">
          <input type="checkbox" id="agreeTerms" v-model="form.agree">
          <label for="agreeTerms">
            Tôi đồng ý với <a href="#">Điều khoản dịch vụ</a> và <a href="#">Chính sách bảo mật</a> của FastFoodYumMy
          </label>
        </div>

        <button class="btn-auth" :disabled="loading || !canSubmit" @click="register" @mousedown="createRipple">
          <span class="btn-text">{{ loading ? '⏳ ĐANG TẠO TÀI KHOẢN...' : 'ĐĂNG KÝ NGAY 🍟' }}</span>
        </button>

        <div class="auth-divider"><span></span><p>hoặc</p><span></span></div>

        <div class="register-row">
          Đã có tài khoản? <router-link to="/dang-nhap">Đăng nhập ngay 🍔</router-link>
        </div>
      </div>
    </div>

    <div class="footer">© 2025 FastFoodYumMy. All rights reserved.</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()
const cardRef = ref(null)
const particlesRef = ref(null)
const showPwd = ref(false)
const showPwd2 = ref(false)
const loading = ref(false)
const error = ref('')

const form = ref({
  lastName: '', firstName: '', email: '', phone: '',
  matKhau: '', confirm: '', agree: false
})

const strength = computed(() => {
  const p = form.value.matKhau
  if (!p) return { pct: 0, color: 'transparent', label: '' }
  let score = 0
  if (p.length >= 6) score++
  if (p.length >= 10) score++
  if (/[A-Z]/.test(p)) score++
  if (/[0-9]/.test(p)) score++
  if (/[^A-Za-z0-9]/.test(p)) score++
  const map = [
    { pct: 20, color: '#f87171', label: 'Rất yếu' },
    { pct: 40, color: '#fb923c', label: 'Yếu' },
    { pct: 60, color: '#facc15', label: 'Trung bình' },
    { pct: 80, color: '#4ade80', label: 'Mạnh' },
    { pct: 100, color: '#4ade80', label: 'Rất mạnh' },
  ]
  return map[Math.min(score, 4)]
})

const canSubmit = computed(() =>
  form.value.lastName.trim() &&
  form.value.firstName.trim() &&
  form.value.email.trim() &&
  form.value.phone.trim() &&
  form.value.matKhau.length >= 6 &&
  form.value.matKhau === form.value.confirm &&
  form.value.agree
)

function onMouseMove(e) {
  if (!cardRef.value) return
  const r = cardRef.value.getBoundingClientRect()
  const dx = (e.clientX - r.left - r.width / 2) / (r.width / 2)
  const dy = (e.clientY - r.top - r.height / 2) / (r.height / 2)
  cardRef.value.style.transform = `perspective(900px) rotateX(${-dy * 5}deg) rotateY(${dx * 5}deg) translateY(-2px)`
}
function onMouseLeave() {
  if (!cardRef.value) return
  cardRef.value.style.transition = 'transform 0.6s ease'
  cardRef.value.style.transform = 'perspective(900px) rotateX(0) rotateY(0) translateY(0)'
}
function onMouseEnter() {
  if (!cardRef.value) return
  cardRef.value.style.transition = 'transform 0.12s ease'
}

function createRipple(e) {
  const btn = e.currentTarget
  const rect = btn.getBoundingClientRect()
  const size = Math.max(btn.clientWidth, btn.clientHeight)
  const rip = document.createElement('span')
  rip.className = 'ripple'
  rip.style.cssText = `width:${size}px;height:${size}px;top:${e.clientY - rect.top - size / 2}px;left:${e.clientX - rect.left - size / 2}px;`
  btn.appendChild(rip)
  setTimeout(() => rip.remove(), 700)
}

async function register() {
  error.value = ''
  loading.value = true
  try {
    const hoTen = `${form.value.lastName} ${form.value.firstName}`.trim()
    await auth.register(hoTen, form.value.email, form.value.matKhau)
    router.push('/')
  } catch (e) {
    error.value = e.response?.data?.message || 'Đăng ký thất bại'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (!particlesRef.value) return
  const emojis = ['🍔','🍟','🌭','🍕','🍗','🥤','🧁','🍩','🍦','🌮']
  for (let i = 0; i < 20; i++) {
    const el = document.createElement('span')
    el.className = 'particle'
    el.textContent = emojis[Math.floor(Math.random() * emojis.length)]
    el.style.cssText = `left:${Math.random() * 100}%;font-size:${1 + Math.random() * 1.4}rem;animation-duration:${9 + Math.random() * 14}s;animation-delay:${-Math.random() * 14}s;`
    particlesRef.value.appendChild(el)
  }
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --red: #e8273a; --red-dark: #b8001a; --red-glow: rgba(232,39,58,0.6);
  --yellow: #ffcc00; --card-bg: rgba(12,10,10,0.78);
  --input-bg: rgba(255,255,255,0.06); --text: #f5ede6; --muted: rgba(245,237,230,0.45);
}

.auth-page {
  width: 100%; min-height: 100vh; font-family: 'Nunito', sans-serif;
  background: #0a0707; display: flex; align-items: center; justify-content: center;
  overflow-x: hidden; position: relative;
}

.bg-photo {
  position: fixed; inset: 0; z-index: 0;
  background: url('https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=1600&q=80') center/cover no-repeat;
  filter: blur(4px) brightness(0.25) saturate(1.2);
  transform: scale(1.08);
  animation: bgBreath 10s ease-in-out infinite alternate;
}
@keyframes bgBreath { from { transform: scale(1.08); } to { transform: scale(1.13); } }

.bg-gradient {
  position: fixed; inset: 0; z-index: 1;
  background: linear-gradient(125deg, rgba(232,39,58,0.30) 0%, transparent 45%, rgba(255,204,0,0.08) 100%);
  animation: gradientShift 8s ease-in-out infinite alternate;
}
@keyframes gradientShift { from { opacity: 0.7; } to { opacity: 1; } }

.particles { position: fixed; inset: 0; z-index: 2; pointer-events: none; overflow: hidden; }
:deep(.particle) {
  position: absolute; opacity: 0;
  animation: floatUp linear infinite;
  filter: drop-shadow(0 0 6px rgba(232,39,58,0.4));
}
@keyframes floatUp {
  0% { transform: translateY(110vh) rotate(0deg); opacity: 0; }
  10% { opacity: 0.22; } 90% { opacity: 0.15; }
  100% { transform: translateY(-15vh) rotate(360deg); opacity: 0; }
}

.grain {
  position: fixed; inset: 0; z-index: 3; pointer-events: none; opacity: 0.035;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 180px 180px;
}

.page {
  position: relative; z-index: 5;
  width: 100%; min-height: 100vh;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 24px; overflow-y: auto;
}

.brand {
  text-align: center; margin-bottom: 20px;
  animation: brandDrop 0.9s cubic-bezier(0.22,1,0.36,1) both;
}
@keyframes brandDrop {
  from { opacity: 0; transform: translateY(-40px) scale(0.85); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
.brand-logo { display: flex; align-items: center; justify-content: center; gap: 12px; margin-bottom: 6px; }
.brand-icon {
  width: 56px; height: 56px; background: #e8273a; border-radius: 16px;
  display: flex; align-items: center; justify-content: center; font-size: 30px;
  animation: iconPulse 2.5s ease-in-out infinite;
}
@keyframes iconPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(232,39,58,0.6); }
  50% { box-shadow: 0 0 0 14px transparent; }
}
.brand-name {
  font-family: 'Bebas Neue', sans-serif; font-size: 3rem;
  letter-spacing: 0.04em; color: #fff; line-height: 1;
  text-shadow: 0 0 30px rgba(232,39,58,0.4);
}
.brand-name span { color: #ffcc00; }
.brand-tagline { font-size: 0.8rem; letter-spacing: 0.28em; text-transform: uppercase; color: rgba(245,237,230,0.45); font-weight: 700; }

/* Card */
.card {
  position: relative; background: rgba(12,10,10,0.78);
  backdrop-filter: blur(28px) saturate(1.5);
  border: 1px solid rgba(255,255,255,0.09); border-radius: 24px;
  padding: 36px 42px 32px; width: 100%; max-width: 420px;
  box-shadow: 0 0 0 1px rgba(255,255,255,0.04) inset, 0 40px 90px rgba(0,0,0,0.65), 0 0 60px rgba(232,39,58,0.08);
  animation: cardRise 0.9s 0.15s cubic-bezier(0.22,1,0.36,1) both;
  overflow: hidden; transition: box-shadow 0.3s ease;
}
@keyframes cardRise {
  from { opacity: 0; transform: translateY(50px) scale(0.95); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
.card::before {
  content: ''; position: absolute; inset: -2px; border-radius: 26px; z-index: -1; opacity: 0;
  background: conic-gradient(from 0deg, transparent 0deg, #e8273a 60deg, #ffcc00 120deg, transparent 180deg);
  transition: opacity 0.4s; animation: rotateBorder 3s linear infinite;
}
.card:hover::before { opacity: 0.65; }
@keyframes rotateBorder { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

.scanlines {
  position: absolute; inset: 0; border-radius: 24px; pointer-events: none; z-index: 10;
  background: repeating-linear-gradient(0deg, transparent, transparent 3px, rgba(0,0,0,0.07) 3px, rgba(0,0,0,0.07) 4px);
  animation: scanFlicker 0.15s steps(1) infinite;
}
@keyframes scanFlicker { 0%, 100% { opacity: 0.4; } 50% { opacity: 0.55; } }

.card-title {
  font-family: 'Bebas Neue', sans-serif; font-size: 1.6rem;
  letter-spacing: 0.14em; color: #f5ede6; text-align: center; margin-bottom: 22px;
  animation: fadeUp 0.6s 0.3s ease both;
}
.card-title::after {
  content: ''; display: block; width: 0; height: 3px;
  background: linear-gradient(90deg, #e8273a, #ffcc00);
  border-radius: 2px; margin: 8px auto 0;
  animation: lineExpand 0.8s 0.7s ease forwards;
}
@keyframes lineExpand { to { width: 50px; } }

.auth-error {
  background: rgba(232,39,58,0.15); border: 1px solid rgba(232,39,58,0.45);
  border-radius: 10px; padding: 10px 14px;
  font-size: 0.85rem; color: #ff8090; font-weight: 700; margin-bottom: 14px;
  animation: errorPop 0.3s ease;
}
@keyframes errorPop { 0% { transform: scale(0.95); opacity: 0; } 60% { transform: scale(1.02); } 100% { transform: scale(1); opacity: 1; } }

/* Fields */
.form-group { margin-bottom: 13px; position: relative; }
.form-group.anim-2 { animation: fadeUp 0.6s 0.44s ease both; }
.form-group.anim-3 { animation: fadeUp 0.6s 0.50s ease both; }
.form-group.anim-4 { animation: fadeUp 0.6s 0.56s ease both; }
.form-group.anim-5 { animation: fadeUp 0.6s 0.62s ease both; }

.field-row {
  display: grid; grid-template-columns: 1fr 1fr; gap: 12px;
  animation: fadeUp 0.6s 0.38s ease both;
}
.field-row .form-group { margin-bottom: 0; }

.finput {
  width: 100%; background: rgba(255,255,255,0.06);
  border: 1.5px solid rgba(255,255,255,0.12); border-radius: 12px;
  padding: 13px 48px 13px 18px;
  font-family: 'Nunito', sans-serif; font-size: 0.95rem; font-weight: 700; color: #f5ede6;
  outline: none;
  transition: border-color 0.3s, background 0.3s, box-shadow 0.3s, transform 0.2s;
}
.finput::placeholder { color: rgba(245,237,230,0.45); font-weight: 600; }
.finput:focus {
  border-color: #e8273a; background: rgba(232,39,58,0.09);
  box-shadow: 0 0 0 4px rgba(232,39,58,0.18), 0 0 20px rgba(232,39,58,0.1);
  transform: translateY(-1px);
}
.finput.input-error { border-color: rgba(248,113,113,0.5); }

.field-icon {
  position: absolute; right: 16px; top: 50%; transform: translateY(-50%);
  font-size: 1.1rem; pointer-events: none; transition: transform 0.3s;
}
.finput:focus ~ .field-icon { transform: translateY(-50%) scale(1.25) rotate(10deg); }

.pwd-toggle {
  position: absolute; right: 16px; top: 16px;
  background: none; border: none; cursor: pointer; font-size: 1rem; padding: 0; line-height: 1;
  transition: transform 0.2s;
}
.pwd-toggle:hover { transform: scale(1.2); }

.field-error { font-size: 0.72rem; color: #f87171; font-weight: 700; margin-top: 4px; }

/* Strength */
.strength-bar {
  height: 3px; background: rgba(255,255,255,0.08); border-radius: 2px; margin-top: 6px; overflow: hidden;
}
.strength-fill { height: 100%; border-radius: 2px; transition: width 0.3s, background 0.3s; }
.strength-label { font-size: 0.68rem; font-weight: 700; margin-top: 3px; }

/* Terms */
.terms-row {
  display: flex; align-items: flex-start; gap: 10px;
  font-size: 0.82rem; color: rgba(245,237,230,0.5); margin-top: 2px; margin-bottom: 6px;
  animation: fadeUp 0.6s 0.68s ease both;
}
.terms-row input[type="checkbox"] { margin-top: 3px; accent-color: #e8273a; cursor: pointer; flex-shrink: 0; }
.terms-row a { color: #ffcc00; font-weight: 700; text-decoration: none; }
.terms-row a:hover { text-decoration: underline; }

/* Button */
.btn-auth {
  width: 100%; padding: 15px; margin-top: 6px;
  background: linear-gradient(135deg, #e8273a 0%, #c0182b 100%);
  color: #fff; font-family: 'Bebas Neue', sans-serif; font-size: 1.3rem; letter-spacing: 0.18em;
  border: none; border-radius: 12px; cursor: pointer; position: relative; overflow: hidden;
  transition: transform 0.2s, box-shadow 0.3s;
  box-shadow: 0 8px 28px rgba(232,39,58,0.45);
  animation: fadeUp 0.6s 0.72s ease both;
  margin-bottom: 12px;
}
.btn-auth::before {
  content: ''; position: absolute; top: 0; left: -100%; width: 60%; height: 100%;
  background: linear-gradient(120deg, transparent, rgba(255,255,255,0.18), transparent);
  transition: left 0.5s;
}
.btn-auth:hover::before { left: 150%; }
.btn-auth:hover:not(:disabled) {
  transform: translateY(-3px);
  box-shadow: 0 18px 40px rgba(232,39,58,0.6), 0 0 20px rgba(232,39,58,0.3);
}
.btn-auth:disabled { opacity: 0.38; cursor: not-allowed; }
:deep(.ripple) {
  position: absolute; border-radius: 50%; background: rgba(255,255,255,0.28);
  transform: scale(0); animation: rippleAnim 0.6s linear; pointer-events: none;
}
@keyframes rippleAnim { to { transform: scale(4); opacity: 0; } }

.auth-divider {
  display: flex; align-items: center; gap: 10px; margin: 8px 0 12px;
  animation: fadeUp 0.6s 0.78s ease both;
}
.auth-divider span { flex: 1; height: 1px; background: rgba(255,255,255,0.1); }
.auth-divider p { font-size: 0.75rem; color: rgba(245,237,230,0.45); font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; white-space: nowrap; }

.register-row {
  text-align: center; font-size: 0.88rem; color: rgba(245,237,230,0.45);
  animation: fadeUp 0.6s 0.82s ease both;
}
.register-row a {
  color: #ffcc00; font-weight: 900; text-decoration: none; position: relative;
}
.register-row a::after {
  content: ''; position: absolute; bottom: -2px; left: 0;
  width: 0; height: 2px; background: #ffcc00; transition: width 0.3s;
}
.register-row a:hover::after { width: 100%; }

.footer {
  position: fixed; bottom: 18px; left: 0; right: 0;
  text-align: center; font-size: 0.72rem; color: rgba(255,255,255,0.22);
  letter-spacing: 0.07em; z-index: 5;
}

@keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

@media (max-width: 480px) {
  .card { padding: 28px 18px 24px; }
  .brand-name { font-size: 2.4rem; }
  .field-row { grid-template-columns: 1fr; gap: 0; }
  .field-row .form-group { margin-bottom: 13px; }
}
</style>