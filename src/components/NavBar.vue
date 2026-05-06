<!-- ============================================================
  components/NavBar.vue  —  Navbar dùng chung cho public pages
============================================================ -->
<template>
  <nav class="navbar" :class="{ scrolled: isScrolled }">
    <router-link to="/" class="nav-brand">
      <div class="brand-icon">🍔</div>
      <div class="brand-name">FastFood<span>YumMy</span></div>
    </router-link>

    <ul class="nav-links">
      <li><router-link to="/" active-class="active">Trang Chủ</router-link></li>
      <li><router-link to="/thuc-don" active-class="active">Thực Đơn</router-link></li>
      <li><a href="#promo"   @click.prevent="goSection('promo')"   :class="{ active: route.path === '/' && activeSection === 'promo' }">Khuyến Mãi</a></li>
      <li><a href="#reviews" @click.prevent="goSection('reviews')" :class="{ active: route.path === '/' && activeSection === 'reviews' }">Đánh Giá</a></li>
    </ul>

    <div class="nav-actions">
      <template v-if="auth.isLoggedIn">
        <!-- Cart badge -->
        <router-link to="/gio-hang" class="cart-btn">
          🛒
          <span v-if="cart.totalItems > 0" class="cart-badge">{{ cart.totalItems }}</span>
        </router-link>

        <!-- User menu -->
        <div class="user-menu" @click="menuOpen = !menuOpen" ref="menuRef">
          <div class="user-avatar">{{ initials }}</div>
          <div v-if="menuOpen" class="dropdown">
            <div class="dropdown-name">{{ auth.user?.hoTen }}</div>
  <div class="dropdown-role">{{ roleLabel }}</div>
  <div class="dropdown-divider"></div>

  <!-- Khách hàng -->
  <template v-if="!auth.isAdmin && !auth.isNhanVien">
    <router-link to="/don-hang" class="dropdown-item">📋 Đơn Hàng</router-link>
    <router-link to="/ho-so" class="dropdown-item">👤 Hồ Sơ</router-link>
  </template>

  <!-- Admin -->
  <template v-if="auth.isAdmin">
    <router-link to="/ho-so" class="dropdown-item">👤 Hồ Sơ</router-link>
    <router-link to="/admin" class="dropdown-item">⚙️ Quản Trị</router-link>
  </template>
  <div class="dropdown-divider"></div>
  <button @click="logout" class="dropdown-item logout">🚪 Đăng Xuất</button>
</div>
        </div>
      </template>
      <template v-else>
        <router-link to="/dang-nhap" class="btn-outline">Đăng Nhập</router-link>
        <router-link to="/dang-ky" class="btn-cta">Đăng Ký</router-link>
        <router-link to="/gio-hang" class="cart-btn">
          🛒
          <span v-if="cart.totalItems > 0" class="cart-badge">{{ cart.totalItems }}</span>
        </router-link>
      </template>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useCartStore } from '../stores/cart'

const auth = useAuthStore()
const cart = useCartStore()
const route  = useRoute()
const router = useRouter()
const activeSection = ref('')

function goSection(id) {
  if (route.path === '/') {
    // Đang ở trang chủ — scroll thẳng
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' })
    activeSection.value = id
  } else {
    // Trang khác — về trang chủ rồi scroll
    router.push('/').then(() => {
      setTimeout(() => {
        document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' })
        activeSection.value = id
      }, 400)
    })
  }
}

const isScrolled = ref(false)
const menuOpen = ref(false)
const menuRef = ref(null)

const initials = computed(() => {
  if (!auth.user?.hoTen) return 'U'
  return auth.user.hoTen.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
})

const roleLabel = computed(() => {
  const map = { admin: 'Quản Trị Viên', nhanvien: 'Nhân Viên', khachhang: 'Khách Hàng' }
  return map[auth.user?.vaiTro] || ''
})

function logout() {
  auth.logout()
  menuOpen.value = false
  router.push('/')
}

function handleScroll() { isScrolled.value = window.scrollY > 50 }
function handleClickOutside(e) {
  if (menuRef.value && !menuRef.value.contains(e.target)) menuOpen.value = false
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
  document.addEventListener('click', handleClickOutside)
})
onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.navbar { position:fixed;top:0;left:0;right:0;z-index:500;display:flex;align-items:center;justify-content:space-between;padding:0 60px;height:72px;background:rgba(14,10,10,.75);backdrop-filter:blur(18px);border-bottom:1px solid rgba(255,255,255,.08);transition:background .3s,box-shadow .3s }
.navbar.scrolled { background:rgba(14,10,10,.95);box-shadow:0 4px 30px rgba(0,0,0,.5) }
.nav-brand { display:flex;align-items:center;gap:10px;text-decoration:none }
.brand-icon { width:40px;height:40px;background:#e8273a;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:20px }
.brand-name { font-family:'Bebas Neue',sans-serif;font-size:1.6rem;letter-spacing:.05em;color:#fff }
.brand-name span { color:#ffcc00 }
.nav-links { display:flex;align-items:center;gap:36px;list-style:none }
.nav-links a { text-decoration:none;font-size:.88rem;font-weight:800;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.5);position:relative;transition:color .25s }
.nav-links a::after { content:'';position:absolute;bottom:-4px;left:0;width:0;height:2px;background:#e8273a;transition:width .3s }
.nav-links a:hover { color:#fff }
.nav-links a:hover::after,.nav-links a.active::after { width:100% }
.nav-links a.active { color:#ffcc00 }
.nav-links a.active::after { background:#ffcc00 }
.nav-actions { display:flex;align-items:center;gap:14px }
.cart-btn { position:relative;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50%;width:40px;height:40px;display:flex;align-items:center;justify-content:center;font-size:1.1rem;cursor:pointer;text-decoration:none;transition:all .2s }
.cart-btn:hover { background:rgba(232,39,58,.15);transform:scale(1.1) }
.cart-badge { position:absolute;top:-4px;right:-4px;width:18px;height:18px;background:#e8273a;border-radius:50%;font-size:.65rem;font-weight:900;color:#fff;display:flex;align-items:center;justify-content:center }
.btn-outline { padding:9px 22px;border:1.5px solid rgba(255,255,255,.2);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#f5ede6;text-decoration:none;transition:all .25s }
.btn-outline:hover { border-color:#e8273a;color:#e8273a }
.btn-cta { padding:9px 22px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#fff;text-decoration:none;cursor:pointer;transition:all .25s;box-shadow:0 4px 16px rgba(232,39,58,.4) }
.btn-cta:hover { background:#b8001a;transform:translateY(-2px) }
.user-menu { position:relative;cursor:pointer }
.user-avatar { width:38px;height:38px;border-radius:50%;background:linear-gradient(135deg,#e8273a,#ffcc00);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:.88rem;color:#fff;border:2px solid rgba(232,39,58,.3) }
.dropdown { position:absolute;top:calc(100% + 10px);right:0;background:#130a0a;border:1px solid rgba(232,39,58,.2);border-radius:14px;padding:8px;min-width:180px;box-shadow:0 20px 40px rgba(0,0,0,.6);animation:dropIn .2s ease }
@keyframes dropIn { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
.dropdown-name { padding:6px 10px;font-weight:900;font-size:.88rem;color:#f5ede6 }
.dropdown-role { padding:0 10px 8px;font-size:.7rem;color:rgba(245,237,230,.4);font-weight:700 }
.dropdown-divider { height:1px;background:rgba(255,255,255,.08);margin:4px 0 }
.dropdown-item { display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:8px;text-decoration:none;font-size:.82rem;font-weight:800;color:rgba(245,237,230,.7);transition:all .2s;width:100%;text-align:left;background:none;border:none;cursor:pointer;font-family:'Nunito',sans-serif }
.dropdown-item:hover { background:rgba(232,39,58,.1);color:#f5ede6 }
.dropdown-item.logout { color:rgba(248,113,113,.7) }
.dropdown-item.logout:hover { background:rgba(248,113,113,.1);color:#f87171 }
@media(max-width:768px){.nav-links{display:none}.navbar{padding:0 20px}}
</style>