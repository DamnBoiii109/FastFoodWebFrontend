<template>
  <div class="staff-wrap">

    <!-- ── SIDEBAR (giống StaffHoaDon) ── -->
    <aside class="sidebar">
      <div class="sb-brand">
        <div class="sb-icon">🍔</div>
        <div class="sb-name">FastFood<span>YumMy</span></div>
      </div>
      <nav class="sb-nav">
        <span class="nav-lbl">Nhân Viên</span>
        <router-link to="/staff/hoa-don" class="nav-item"><span>🧾</span>Tạo Hóa Đơn</router-link>
        <router-link to="/staff/lich-su" class="nav-item"><span>📋</span>Lịch Sử</router-link>
        <div class="nav-sep"></div>
        <router-link to="/staff/ho-so" class="nav-item active"><span>👤</span>Hồ Sơ</router-link>
        <button @click="logout" class="nav-item nav-logout"><span>🚪</span>Đăng Xuất</button>
      </nav>
      <div class="sb-foot">
        <div class="s-user">
          <div class="s-ava">{{ initials }}</div>
          <div>
            <div class="s-name">{{ auth.user?.hoTen }}</div>
            <div class="s-role">Thu Ngân</div>
          </div>
        </div>
      </div>
    </aside>

    <!-- ── MAIN ── -->
    <div class="staff-main">

      <!-- Topbar -->
      <header class="topbar">
        <div class="page-title">Hồ Sơ <span>Cá Nhân</span></div>
        <div class="topbar-r">
          <div class="clock-txt">{{ clock }}</div>
        </div>
      </header>

      <!-- Content ở giữa -->
      <div class="staff-content">

        <!-- Hero avatar -->
        <div class="profile-hero">
          <div class="hero-bg"></div>
          <div class="hero-inner">
            <div class="big-ava">{{ initials }}</div>
            <div class="hero-meta">
              <div class="hero-name">{{ auth.user?.hoTen }}</div>
              <div class="hero-badge">👔 Nhân Viên</div>
              <div class="hero-email">✉️ {{ auth.user?.email }}</div>
            </div>
          </div>
        </div>

        <!-- Cards -->
        <div class="cards-grid">

          <!-- Thông tin cá nhân -->
          <div class="pcard">
            <div class="pcard-title">Thông Tin <span>Cá Nhân</span></div>

            <div v-if="saveSuccess" class="msg-success">✅ Đã lưu thông tin thành công!</div>
            <div v-if="saveError"   class="msg-error">❌ {{ saveError }}</div>

            <div class="fgroup">
              <label>Họ Tên</label>
              <input v-model="form.hoTen" type="text" class="finput">
            </div>
            <div class="fgroup">
              <label>Email</label>
              <input :value="auth.user?.email" type="email" class="finput" readonly>
            </div>
            <div class="fgroup">
              <label>Chức Vụ</label>
              <input value="Nhân Viên" type="text" class="finput" readonly>
            </div>

            <div class="btn-row">
              <button class="btn-save" @click="saveInfo" :disabled="saving">
                {{ saving ? '⏳ Đang lưu...' : '💾 Lưu Thông Tin' }}
              </button>
            </div>
          </div>

          <!-- Đổi mật khẩu -->
          <div class="pcard">
            <div class="pcard-title">Đổi <span>Mật Khẩu</span></div>

            <div v-if="pwdSuccess" class="msg-success">✅ Đổi mật khẩu thành công!</div>
            <div v-if="pwdError"   class="msg-error">❌ {{ pwdError }}</div>

            <div class="fgroup">
              <label>Mật Khẩu Hiện Tại</label>
              <input v-model="pwd.cu" type="password" placeholder="••••••••" class="finput">
            </div>
            <div class="fgroup">
              <label>Mật Khẩu Mới</label>
              <input v-model="pwd.moi" type="password" placeholder="••••••••" class="finput">
            </div>
            <div class="fgroup">
              <label>Xác Nhận</label>
              <input
                v-model="pwd.confirm"
                type="password"
                placeholder="••••••••"
                class="finput"
                :class="{ 'input-error': pwd.confirm && pwd.confirm !== pwd.moi }"
              >
              <span v-if="pwd.confirm && pwd.confirm !== pwd.moi" class="field-err">
                Mật khẩu không khớp
              </span>
            </div>

            <div class="btn-row">
              <button class="btn-save" @click="changePwd" :disabled="changingPwd">
                {{ changingPwd ? '⏳...' : '🔒 Đổi Mật Khẩu' }}
              </button>
            </div>

            <button class="btn-logout" @click="logout">🚪 Đăng Xuất</button>
          </div>

        </div>
      </div>
    </div>

    <!-- Toast -->
    <div class="toast" :class="{ show: toastVisible }">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { taiKhoanAPI } from '../../services/api'

const auth   = useAuthStore()
const router = useRouter()

// Clock
const clock = ref('')
let timer
function tick() { clock.value = new Date().toLocaleTimeString('vi', { hour: '2-digit', minute: '2-digit' }) }
onMounted(() => { tick(); timer = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(timer))

// Initials
const initials = computed(() =>
  (auth.user?.hoTen || 'NV').split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
)

// Form
const form = ref({ hoTen: auth.user?.hoTen || '' })
const pwd  = ref({ cu: '', moi: '', confirm: '' })

const saving      = ref(false)
const changingPwd = ref(false)
const saveSuccess = ref(false)
const saveError   = ref('')
const pwdSuccess  = ref(false)
const pwdError    = ref('')
const toastMsg    = ref('')
const toastVisible = ref(false)

function showToast(msg) {
  toastMsg.value = msg
  toastVisible.value = true
  setTimeout(() => { toastVisible.value = false }, 2500)
}

async function saveInfo() {
  saveSuccess.value = false; saveError.value = ''
  if (!form.value.hoTen.trim()) { saveError.value = 'Họ tên không được để trống'; return }
  saving.value = true
  try {
    await taiKhoanAPI.update(auth.user.id, { hoTen: form.value.hoTen })
    auth.user.hoTen = form.value.hoTen
    localStorage.setItem('user', JSON.stringify(auth.user))
    saveSuccess.value = true
    showToast('✅ Đã lưu thông tin!')
    setTimeout(() => saveSuccess.value = false, 3000)
  } catch (e) {
    saveError.value = e.response?.data?.message || 'Lưu thất bại'
  } finally {
    saving.value = false
  }
}

async function changePwd() {
  pwdSuccess.value = false; pwdError.value = ''
  if (!pwd.value.cu)              { pwdError.value = 'Nhập mật khẩu hiện tại'; return }
  if (pwd.value.moi.length < 6)   { pwdError.value = 'Mật khẩu mới tối thiểu 6 ký tự'; return }
  if (pwd.value.moi !== pwd.value.confirm) { pwdError.value = 'Mật khẩu xác nhận không khớp'; return }
  changingPwd.value = true
  try {
    await taiKhoanAPI.update(auth.user.id, {
      matKhauCu:  pwd.value.cu,
      matKhauMoi: pwd.value.moi
    })
    pwdSuccess.value = true
    pwd.value = { cu: '', moi: '', confirm: '' }
    showToast('✅ Đổi mật khẩu thành công!')
    setTimeout(() => pwdSuccess.value = false, 3000)
  } catch (e) {
    pwdError.value = e.response?.data?.message || 'Đổi mật khẩu thất bại'
  } finally {
    changingPwd.value = false
  }
}

function logout() {
  auth.logout()
  router.push('/dang-nhap')
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');

/* ── Biến màu ── */
:root {
  --red: #e8273a; --yellow: #ffcc00; --dark: #0e0a0a;
  --text: #f5ede6; --muted: rgba(245,237,230,0.5);
  --border: rgba(255,255,255,0.08); --card: rgba(22,14,14,0.9);
}

/* ── Wrapper ── */
.staff-wrap {
  display: flex;
  min-height: 100vh;
  background: #0e0a0a;
  color: #f5ede6;
  font-family: 'Nunito', sans-serif;
}

/* ── Sidebar ── */
.sidebar {
  position: fixed; top: 0; left: 0; bottom: 0; width: 180px;
  background: rgba(10,6,6,.97);
  border-right: 1px solid rgba(255,255,255,.08);
  display: flex; flex-direction: column; z-index: 200;
}
.sb-brand { display:flex;align-items:center;gap:9px;padding:18px 14px;border-bottom:1px solid rgba(255,255,255,.08);text-decoration:none; }
.sb-icon  { width:32px;height:32px;background:#e8273a;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0; }
.sb-name  { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.06em;color:#fff;line-height:1; }
.sb-name span { color:#ffcc00; }
.sb-nav   { flex:1;padding:12px 8px;display:flex;flex-direction:column;gap:2px;overflow-y:auto; }
.nav-item {
  display:flex;align-items:center;gap:8px;padding:9px 10px;
  border-radius:10px;text-decoration:none;color:rgba(245,237,230,.5);
  font-size:.76rem;font-weight:800;letter-spacing:.04em;text-transform:uppercase;
  transition:all .2s;border:1px solid transparent;background:none;
  cursor:pointer;font-family:'Nunito',sans-serif;width:100%;text-align:left;
}
.nav-item:hover { background:rgba(255,255,255,.05);color:#f5ede6; }
.nav-item.active { background:rgba(232,39,58,.15);color:#e8273a;border-color:rgba(232,39,58,.2); }
.nav-item span { font-size:.9rem;width:16px;text-align:center;flex-shrink:0; }
.nav-logout:hover { background:rgba(248,113,113,.1);color:#f87171; }
.nav-sep  { height:1px;background:rgba(255,255,255,.08);margin:6px 10px; }
.nav-lbl  { font-size:.58rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:rgba(245,237,230,.4);padding:6px 10px 2px; }
.sb-foot  { padding:12px;border-top:1px solid rgba(255,255,255,.08); }
.s-user   { display:flex;align-items:center;gap:8px; }
.s-ava    { width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#f59e0b,#d97706);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:.78rem;color:#fff;flex-shrink:0; }
.s-name   { font-size:.74rem;font-weight:800;color:#f5ede6; }
.s-role   { font-size:.62rem;color:rgba(245,237,230,.4);font-weight:600; }

/* ── Main ── */
.staff-main {
  margin-left: 180px;
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #0e0a0a;
}

/* ── Topbar ── */
.topbar {
  height: 60px; flex-shrink: 0;
  background: rgba(14,10,10,.9);
  backdrop-filter: blur(18px);
  border-bottom: 1px solid rgba(255,255,255,.08);
  padding: 0 28px;
  display: flex; align-items: center; justify-content: space-between;
  position: sticky; top: 0; z-index: 100;
}
.page-title { font-family:'Bebas Neue',sans-serif;font-size:1.4rem;letter-spacing:.06em;color:#fff; }
.page-title span { color:#ffcc00; }
.clock-txt { font-size:.76rem;font-weight:700;color:rgba(245,237,230,.4);background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);padding:4px 12px;border-radius:50px; }

/* ── Content ── */
.staff-content {
  flex: 1;
  padding: 32px 40px;
  max-width: 960px;
  margin: 0 auto;
  width: 100%;
}

/* ── Profile Hero ── */
.profile-hero {
  position: relative;
  border-radius: 20px;
  overflow: hidden;
  margin-bottom: 24px;
  background: linear-gradient(135deg, #1d0808 0%, #2a0d0d 50%, #1d1400 100%);
  border: 1px solid rgba(232,39,58,.15);
}
.hero-bg {
  position: absolute; inset: 0;
  background: radial-gradient(ellipse at 80% 50%, rgba(232,39,58,.1), transparent 60%);
}
.hero-inner {
  position: relative;
  padding: 28px 32px;
  display: flex; align-items: center; gap: 22px;
}
.big-ava {
  width: 82px; height: 82px; border-radius: 50%;
  background: linear-gradient(135deg, #e8273a, #ffcc00);
  display: flex; align-items: center; justify-content: center;
  font-weight: 900; font-size: 1.9rem; color: #fff;
  border: 3px solid rgba(255,255,255,.12);
  flex-shrink: 0;
}
.hero-name  { font-family:'Bebas Neue',sans-serif;font-size:1.9rem;letter-spacing:.04em;color:#fff;line-height:1;margin-bottom:6px; }
.hero-badge {
  display: inline-block;
  padding: 3px 12px; border-radius: 50px; margin-bottom: 8px;
  font-size: .7rem; font-weight: 900; letter-spacing: .1em; text-transform: uppercase;
  background: rgba(255,204,0,.12); color: #ffcc00; border: 1px solid rgba(255,204,0,.2);
}
.hero-email { font-size: .82rem; font-weight: 600; color: rgba(245,237,230,.5); }

/* ── Cards grid ── */
.cards-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}
@media (max-width: 700px) { .cards-grid { grid-template-columns: 1fr; } }

/* ── Card ── */
.pcard {
  background: rgba(22,14,14,.9);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 18px;
  padding: 22px;
}
.pcard-title {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.1rem; letter-spacing: .08em; color: #fff;
  margin-bottom: 18px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(255,255,255,.08);
}
.pcard-title span { color: #ffcc00; }

/* ── Form ── */
.fgroup { display: flex; flex-direction: column; gap: 5px; margin-bottom: 14px; }
.fgroup label { font-size: .68rem; font-weight: 900; letter-spacing: .14em; text-transform: uppercase; color: rgba(245,237,230,.5); }
.finput {
  background: rgba(255,255,255,.05);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 11px;
  padding: 10px 13px;
  color: #f5ede6;
  font-family: 'Nunito', sans-serif;
  font-size: .88rem; font-weight: 600;
  outline: none;
  transition: border-color .2s;
  width: 100%;
}
.finput:focus { border-color: rgba(232,39,58,.4); }
.finput[readonly] { opacity: .5; cursor: not-allowed; }
.finput.input-error { border-color: rgba(248,113,113,.5); }
.field-err { font-size: .72rem; color: #f87171; font-weight: 700; }

.btn-row { display: flex; justify-content: flex-end; margin-top: 6px; }
.btn-save {
  padding: 10px 22px;
  background: #e8273a; border: none; border-radius: 50px;
  font-family: 'Nunito', sans-serif; font-size: .85rem; font-weight: 900;
  color: #fff; cursor: pointer;
  transition: all .2s;
  box-shadow: 0 4px 14px rgba(232,39,58,.4);
}
.btn-save:hover:not(:disabled) { background: #b8001a; transform: translateY(-2px); }
.btn-save:disabled { opacity: .4; cursor: not-allowed; }

.btn-logout {
  width: 100%; margin-top: 12px;
  padding: 10px;
  background: rgba(248,113,113,.07);
  border: 1px solid rgba(248,113,113,.15);
  border-radius: 11px;
  font-family: 'Nunito', sans-serif; font-size: .85rem; font-weight: 800;
  color: #f87171; cursor: pointer;
  transition: all .2s;
}
.btn-logout:hover { background: rgba(248,113,113,.15); }

/* ── Messages ── */
.msg-success {
  background: rgba(74,222,128,.1); border: 1px solid rgba(74,222,128,.2);
  border-radius: 9px; padding: 8px 12px;
  font-size: .78rem; font-weight: 700; color: #4ade80; margin-bottom: 14px;
}
.msg-error {
  background: rgba(248,113,113,.1); border: 1px solid rgba(248,113,113,.2);
  border-radius: 9px; padding: 8px 12px;
  font-size: .78rem; font-weight: 700; color: #f87171; margin-bottom: 14px;
}

/* ── Toast ── */
.toast {
  position: fixed; bottom: 26px; right: 26px; z-index: 999;
  background: rgba(14,10,10,.95); border: 1px solid rgba(255,255,255,.1);
  backdrop-filter: blur(12px); border-radius: 13px;
  padding: 12px 18px; font-size: .84rem; font-weight: 700; color: #f5ede6;
  transform: translateX(120%);
  transition: transform .4s cubic-bezier(.34,1.56,.64,1);
  min-width: 210px; font-family: 'Nunito', sans-serif;
}
.toast.show { transform: translateX(0); }
</style>