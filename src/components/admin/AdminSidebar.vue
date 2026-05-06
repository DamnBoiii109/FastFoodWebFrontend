<template>
  <aside class="sidebar">
    <!-- Grain overlay -->
    <div class="sb-grain"></div>

    <router-link to="/" class="sb-brand">
      <div class="sb-icon">🍔</div>
      <div class="sb-name">FastFood<span>YumMy</span></div>
    </router-link>

    <nav class="sb-nav">
      <span class="nav-lbl">Quản Lý</span>
      <router-link to="/admin"           class="nav-item" :class="{ active: active==='dashboard' }"><span>📊</span>Dashboard</router-link>
      <router-link to="/admin/mon-an"    class="nav-item" :class="{ active: active==='mon-an' }"><span>🍔</span>Đồ Ăn</router-link>
      <router-link to="/admin/voucher"   class="nav-item" :class="{ active: active==='voucher' }"><span>🎟️</span>Voucher</router-link>
      <router-link to="/admin/nhan-vien" class="nav-item" :class="{ active: active==='nhan-vien' }"><span>👥</span>Nhân Viên</router-link>
      <router-link to="/admin/hoa-don"   class="nav-item" :class="{ active: active==='hoa-don' }"><span>📋</span>Hóa Đơn</router-link>
      <router-link to="/admin/loai-mon-an" class="nav-item" :class="{ active: active==='loai-mon-an' }"><span>🗂️</span>Loại Món
</router-link>
      <div class="nav-sep"></div>
      <span class="nav-lbl">Hệ Thống</span>
      <router-link to="/ho-so" class="nav-item" :class="{ active: active==='ho-so' }"><span>👤</span>Hồ Sơ</router-link>
      <router-link to="/"      class="nav-item"><span>🏠</span>Trang Chủ</router-link>
      <button @click="logout"  class="nav-item nav-logout"><span>🚪</span>Đăng Xuất</button>
    </nav>

    <div class="sb-foot">
      <div class="s-user">
        <div class="s-ava">{{ initials }}</div>
        <div>
          <div class="s-name">{{ auth.user?.hoTen }}</div>
          <div class="s-role">{{ roleLabel }}</div>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

defineProps({ active: { type: String, default: '' } })

const auth   = useAuthStore()
const router = useRouter()

const initials = computed(() => {
  const n = auth.user?.hoTen || 'U'
  return n.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
})
const roleLabel = computed(() => {
  const map = { admin: 'Quản Trị Viên', nhanvien: 'Nhân Viên', khachhang: 'Khách Hàng' }
  return map[auth.user?.vaiTro] || ''
})
function logout() { auth.logout(); router.push('/dang-nhap') }
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');

.sidebar {
  position: fixed; top: 0; left: 0; bottom: 0; width: 180px;
  background: rgba(10,6,6,0.97);
  border-right: 1px solid rgba(255,255,255,0.08);
  display: flex; flex-direction: column; z-index: 200;
  overflow: hidden;
}

/* Subtle grain on sidebar */
.sb-grain {
  position: absolute; inset: 0; z-index: 0; pointer-events: none; opacity: 0.04;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 180px;
}

.sb-brand {
  display: flex; align-items: center; gap: 9px;
  padding: 20px 16px; border-bottom: 1px solid rgba(255,255,255,0.08);
  text-decoration: none; position: relative; z-index: 1;
}
.sb-icon {
  width: 34px; height: 34px; background: #e8273a; border-radius: 9px;
  display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0;
  box-shadow: 0 0 12px rgba(232,39,58,0.4);
  transition: box-shadow 0.3s;
}
.sb-brand:hover .sb-icon { box-shadow: 0 0 20px rgba(232,39,58,0.7); }
.sb-name {
  font-family: 'Bebas Neue', sans-serif; font-size: 1.05rem;
  letter-spacing: 0.06em; color: #fff; line-height: 1;
}
.sb-name span { color: #ffcc00; }

.sb-nav {
  flex: 1; padding: 14px 8px; display: flex; flex-direction: column;
  gap: 3px; overflow-y: auto; position: relative; z-index: 1;
}
.sb-nav::-webkit-scrollbar { width: 2px; }
.sb-nav::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.08); }

.nav-item {
  display: flex; align-items: center; gap: 9px; padding: 9px 10px;
  border-radius: 11px; text-decoration: none;
  color: rgba(245,237,230,0.5); font-size: 0.78rem; font-weight: 800;
  letter-spacing: 0.04em; text-transform: uppercase;
  transition: background 0.2s, color 0.2s;
  border: 1px solid transparent; background: none; cursor: pointer;
  font-family: 'Nunito', sans-serif; width: 100%; text-align: left;
}
.nav-item:hover { background: rgba(255,255,255,0.05); color: #f5ede6; }
.nav-item.active {
  background: rgba(232,39,58,0.15); color: #e8273a;
  border-color: rgba(232,39,58,0.2);
  box-shadow: 0 0 10px rgba(232,39,58,0.1);
}
.nav-item span { font-size: 0.9rem; width: 16px; text-align: center; flex-shrink: 0; }
.nav-logout:hover { background: rgba(248,113,113,0.1); color: #f87171; }
.nav-sep { height: 1px; background: rgba(255,255,255,0.08); margin: 6px 10px; }
.nav-lbl {
  font-size: 0.6rem; font-weight: 900; letter-spacing: 0.2em;
  text-transform: uppercase; color: rgba(245,237,230,0.4); padding: 6px 10px 2px;
}

.sb-foot {
  padding: 12px; border-top: 1px solid rgba(255,255,255,0.08);
  position: relative; z-index: 1;
}
.s-user { display: flex; align-items: center; gap: 9px; }
.s-ava {
  width: 34px; height: 34px; border-radius: 50%;
  background: linear-gradient(135deg, #e8273a, #ffcc00);
  display: flex; align-items: center; justify-content: center;
  font-weight: 900; font-size: 0.82rem; color: #fff; flex-shrink: 0;
  box-shadow: 0 0 10px rgba(232,39,58,0.3);
}
.s-name { font-size: 0.76rem; font-weight: 800; color: #f5ede6; }
.s-role { font-size: 0.64rem; color: rgba(245,237,230,0.4); font-weight: 600; }
</style>