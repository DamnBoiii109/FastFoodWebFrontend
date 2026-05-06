<template>
  <div class="page">
    <div class="grain"></div>
    <div class="container">
      <!-- Hero -->
      <div class="profile-hero">
        <div class="hero-bg"></div>
        <div class="hero-content">
          <div class="avatar" @click="toast.show('📸 Tính năng sắp có!')">
            {{ initials }}
            <div class="avatar-edit">📷</div>
          </div>
          <div>
            <div class="user-name">{{ form.hoTen || auth.user?.hoTen }}</div>
            <div :class="['role-badge', roleClass]">{{ roleLabel }}</div>
            <div class="user-meta">
              <span>✉️ {{ auth.user?.email }}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="profile-grid">
        <!-- Thông tin cá nhân -->
        <div class="pcard">
          <div class="pcard-title">Thông Tin <span>Cá Nhân</span></div>

          <div v-if="saveSuccess" class="success-msg">✅ Đã lưu thông tin thành công!</div>
          <div v-if="saveError" class="error-msg">❌ {{ saveError }}</div>

          <div class="form-group">
            <label>Họ Tên</label>
            <input v-model="form.hoTen" type="text" class="finput">
          </div>
          <div class="form-group">
            <label>Email</label>
            <input :value="auth.user?.email" type="email" class="finput" readonly>
          </div>
          <div class="btn-row">
            <button @click="saveInfo" class="btn-save" :disabled="saving">
              {{ saving ? '⏳ Đang lưu...' : '💾 Lưu Thông Tin' }}
            </button>
          </div>
        </div>

        <!-- Đổi mật khẩu -->
        <div class="pcard">
          <div class="pcard-title">Đổi <span>Mật Khẩu</span></div>

          <div v-if="pwdSuccess" class="success-msg">✅ Đổi mật khẩu thành công!</div>
          <div v-if="pwdError" class="error-msg">❌ {{ pwdError }}</div>

          <div class="form-group">
            <label>Mật Khẩu Hiện Tại</label>
            <input v-model="pwd.cu" type="password" placeholder="••••••••" class="finput">
          </div>
          <div class="form-group">
            <label>Mật Khẩu Mới</label>
            <input v-model="pwd.moi" type="password" placeholder="••••••••" class="finput">
          </div>
          <div class="form-group">
            <label>Xác Nhận</label>
            <input v-model="pwd.confirm" type="password" placeholder="••••••••" class="finput"
                   :class="{ error: pwd.confirm && pwd.confirm !== pwd.moi }">
          </div>
          <div class="btn-row">
            <button @click="changePwd" class="btn-save" :disabled="changingPwd">
              {{ changingPwd ? '⏳...' : '🔒 Đổi Mật Khẩu' }}
            </button>
          </div>

          <button @click="logout" class="btn-logout">🚪 Đăng Xuất</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'
import { taiKhoanAPI } from '../services/api'

const auth  = useAuthStore()
const toast = useToastStore()
const router = useRouter()

const form = ref({ hoTen: auth.user?.hoTen || '' })
const pwd  = ref({ cu: '', moi: '', confirm: '' })

const saving      = ref(false)
const changingPwd = ref(false)
const saveSuccess = ref(false)
const saveError   = ref('')
const pwdSuccess  = ref(false)
const pwdError    = ref('')

const initials = computed(() => {
  const n = auth.user?.hoTen || 'U'
  return n.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
})

const roleLabel = computed(() => {
  const map = { admin: '⚙️ Quản Trị Viên', nhanvien: '👔 Nhân Viên', khachhang: '👤 Khách Hàng' }
  return map[auth.user?.vaiTro] || ''
})

const roleClass = computed(() => {
  const map = { admin: 'role-admin', nhanvien: 'role-staff', khachhang: 'role-customer' }
  return map[auth.user?.vaiTro] || 'role-customer'
})



async function saveInfo() {
  saveSuccess.value = false; saveError.value = ''
  saving.value = true
  try {
    await taiKhoanAPI.update(auth.user.id, { hoTen: form.value.hoTen })
    auth.user.hoTen = form.value.hoTen
    localStorage.setItem('user', JSON.stringify(auth.user))
    saveSuccess.value = true
    setTimeout(() => saveSuccess.value = false, 3000)
  } catch (e) {
    saveError.value = e.response?.data?.message || 'Lưu thất bại'
  } finally {
    saving.value = false
  }
}

async function changePwd() {
  pwdSuccess.value = false; pwdError.value = ''
  if (pwd.value.moi !== pwd.value.confirm) { pwdError.value = 'Mật khẩu xác nhận không khớp'; return }
  if (pwd.value.moi.length < 6) { pwdError.value = 'Mật khẩu mới phải ít nhất 6 ký tự'; return }
  changingPwd.value = true
  try {
    await taiKhoanAPI.update(auth.user.id, { matKhauCu: pwd.value.cu, matKhauMoi: pwd.value.moi })
    pwdSuccess.value = true
    pwd.value = { cu: '', moi: '', confirm: '' }
    setTimeout(() => pwdSuccess.value = false, 3000)
  } catch (e) {
    pwdError.value = e.response?.data?.message || 'Đổi mật khẩu thất bại'
  } finally {
    changingPwd.value = false
  }
}

function logout() {
  auth.logout()
  router.push('/')
}
</script>

<style scoped>
.page { min-height:100vh;background:#0e0a0a;color:#f5ede6;padding:80px 0 60px;position:relative }
.grain { position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px }
.container { max-width:900px;margin:0 auto;padding:0 24px;position:relative }
.profile-hero { background:linear-gradient(135deg,#1d0808 0%,#2a0d0d 50%,#1d1400 100%);border:1px solid rgba(232,39,58,.15);border-radius:22px;margin-bottom:22px;position:relative;overflow:hidden }
.hero-bg { position:absolute;inset:0;background:radial-gradient(ellipse at 80% 50%,rgba(232,39,58,.1) 0%,transparent 60%) }
.hero-content { position:relative;padding:30px 34px;display:flex;align-items:center;gap:24px }
.avatar { width:90px;height:90px;border-radius:50%;background:linear-gradient(135deg,#e8273a,#ffcc00);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:2rem;color:#fff;flex-shrink:0;border:3px solid rgba(255,255,255,.1);cursor:pointer;position:relative;transition:transform .3s }
.avatar:hover { transform:scale(1.05) }
.avatar-edit { position:absolute;bottom:2px;right:2px;width:24px;height:24px;background:#e8273a;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.65rem }
.user-name { font-family:'Bebas Neue',sans-serif;font-size:2rem;letter-spacing:.04em;color:#fff;margin-bottom:6px;line-height:1 }
.role-badge { display:inline-block;padding:3px 12px;border-radius:50px;font-size:.7rem;font-weight:900;letter-spacing:.1em;text-transform:uppercase;margin-bottom:10px }
.role-admin    { background:rgba(232,39,58,.2);color:#e8273a;border:1px solid rgba(232,39,58,.25) }
.role-staff    { background:rgba(255,204,0,.12);color:#ffcc00;border:1px solid rgba(255,204,0,.2) }
.role-customer { background:rgba(74,222,128,.1);color:#4ade80;border:1px solid rgba(74,222,128,.18) }
.user-meta { font-size:.82rem;font-weight:600;color:rgba(245,237,230,.5) }
.profile-grid { display:grid;grid-template-columns:1fr 1fr;gap:18px }
@media(max-width:700px){ .profile-grid{grid-template-columns:1fr} }
.pcard { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:22px }
.pcard-title { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.08em;color:#fff;margin-bottom:18px;padding-bottom:12px;border-bottom:1px solid rgba(255,255,255,.08) }
.pcard-title span { color:#ffcc00 }
.form-group { display:flex;flex-direction:column;gap:5px;margin-bottom:14px }
.form-group label { font-size:.68rem;font-weight:900;letter-spacing:.15em;text-transform:uppercase;color:rgba(245,237,230,.5) }
.finput { background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:11px;padding:10px 13px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:600;outline:none;transition:border-color .2s }
.finput:focus { border-color:rgba(232,39,58,.4) }
.finput[readonly] { opacity:.5;cursor:not-allowed }
.finput.error { border-color:rgba(248,113,113,.5) }
.btn-row { display:flex;justify-content:flex-end;margin-top:6px }
.btn-save { padding:10px 22px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;color:#fff;cursor:pointer;transition:all .2s;box-shadow:0 4px 14px rgba(232,39,58,.4) }
.btn-save:hover:not(:disabled) { background:#b8001a;transform:translateY(-2px) }
.btn-save:disabled { opacity:.4;cursor:not-allowed }
.btn-logout { width:100%;margin-top:12px;padding:10px;background:rgba(248,113,113,.07);border:1px solid rgba(248,113,113,.15);border-radius:11px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#f87171;cursor:pointer;transition:all .2s }
.btn-logout:hover { background:rgba(248,113,113,.15) }
.success-msg { background:rgba(74,222,128,.1);border:1px solid rgba(74,222,128,.2);border-radius:10px;padding:9px 13px;font-size:.8rem;font-weight:700;color:#4ade80;margin-bottom:14px }
.error-msg { background:rgba(248,113,113,.1);border:1px solid rgba(248,113,113,.2);border-radius:10px;padding:9px 13px;font-size:.8rem;font-weight:700;color:#f87171;margin-bottom:14px }
</style>