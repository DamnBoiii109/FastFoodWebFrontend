<template>
  <div class="trang-chu">
    <!-- Custom cursor -->
    <div class="cursor-dot" ref="cursorDot"></div>
    <div class="cursor-ring" ref="cursorRing"></div>
    <div class="grain"></div>

    <!-- Scroll to top -->
    <button class="scroll-top" :class="{ show: showScrollTop }" @click="scrollToTop">↑</button>

    <!-- ══════════ HERO ══════════ -->
    <section id="hero">
      <div class="hero-bg"></div>
      <div class="hero-overlay"></div>
      <div class="hero-stripe"></div>
      <div class="hero-stripe"></div>

      <div class="hero-content">
        <div class="hero-badge">
          <span class="badge-dot"></span> Giao hàng nhanh 30 phút
        </div>

        <h1 class="hero-title">
          Đói Bụng?
          <span class="accent">Gọi Ngay</span>
          <span class="outline">YumMy!</span>
        </h1>

        <p class="hero-desc">
          Đồ ăn nhanh chuẩn vị, giao tận nơi siêu tốc.
          Hơn {{ monAns.length || 50 }}+ món ngon từ burger, pizza đến gà rán —
          tất cả chỉ vài click!
        </p>

        <div class="hero-actions">
          <a href="#menu" class="btn-hero" @click.prevent="scrollTo('menu')">🍔 Đặt Món Ngay</a>
          <router-link to="/thuc-don" class="btn-ghost">Xem Thực Đơn</router-link>
        </div>

        <div class="hero-stats" ref="heroStats">
          <div class="stat" v-for="s in stats" :key="s.label">
            <div class="stat-num">{{ s.display }}</div>
            <div class="stat-label">{{ s.label }}</div>
          </div>
        </div>
      </div>

      <div class="hero-food">
        <div class="hero-food-ring"></div>
        <div class="hero-food-ring2"></div>
        <img src="https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80" alt="Burger">
      </div>
    </section>

    <!-- ══════════ TICKER ══════════ -->
    <div class="ticker">
      <div class="ticker-track">
        <span class="ticker-item" v-for="item in tickerItems" :key="item">{{ item }}</span>
        <span class="ticker-item" v-for="item in tickerItems" :key="'r'+item">{{ item }}</span>
      </div>
    </div>

    <!-- ══════════ CATEGORIES ══════════ -->
    <section id="categories">
      <div class="cats-header">
        <div>
          <span class="section-label">Danh Mục</span>
          <h2 class="section-title">Món <span>Yêu Thích</span></h2>
        </div>
        <router-link to="/thuc-don" class="link-all">Xem tất cả →</router-link>
      </div>

      <div class="cat-grid">
        <router-link
          v-for="(cat, i) in displayCategories"
          :key="cat.id"
          :to="'/thuc-don?loai=' + cat.id"
          class="cat-card"
          :class="{ visible: catsVisible }"
          :style="{ animationDelay: (i * 0.08) + 's' }"
        >
          <div class="cat-emoji">{{ cat.emoji }}</div>
          <div class="cat-name">{{ cat.tenLoai }}</div>
        </router-link>
      </div>
    </section>

    <!-- ══════════ FEATURED MENU ══════════ -->
    <section id="menu">
      <div class="menu-header">
        <div>
          <span class="section-label">Thực Đơn</span>
          <h2 class="section-title">Món <span>Hot</span> Nhất</h2>
        </div>
        <router-link to="/thuc-don" class="link-all">Xem tất cả →</router-link>
      </div>

      <div class="menu-tabs">
        <button class="tab" :class="{ active: activeTab === null }" @click="activeTab = null">Tất Cả</button>
        <button
          v-for="cat in displayCategories.slice(0,5)"
          :key="cat.id"
          class="tab"
          :class="{ active: activeTab === cat.id }"
          @click="activeTab = cat.id"
        >{{ cat.tenLoai }}</button>
      </div>

      <div v-if="loadingMenu" class="food-grid">
        <div v-for="n in 4" :key="n" class="food-card-skeleton"></div>
      </div>

      <div v-else class="food-grid">
        <div
          v-for="(mon, i) in featuredMenu"
          :key="mon.id"
          class="food-card"
          :class="{ visible: menuVisible }"
          :style="{ animationDelay: (i * 0.1) + 's' }"
        >
          <div class="food-img-wrap" @click="$router.push('/mon-an/' + mon.id)">
            <img
              v-if="mon.hinhAnh"
              :src="mon.hinhAnh"
              :alt="mon.tenMon"
              class="food-img"
              @error="e => e.target.style.display='none'"
            >
            <div v-else class="food-img-ph">{{ catEmoji(mon.loaiMonAn?.tenLoai) }}</div>
            <span class="food-badge hot" v-if="i < 2">🔥 Bán Chạy</span>
            <span class="food-badge new" v-else-if="i === 2">✨ Mới</span>
          </div>

          <div class="food-fav" :class="{ liked: favorites.has(mon.id) }" @click="toggleFav(mon.id)">
            {{ favorites.has(mon.id) ? '❤️' : '🤍' }}
          </div>

          <div class="food-body">
            <div class="food-rating">
              <span class="stars">★★★★★</span>
              <span>({{ 100 + mon.id * 13 }})</span>
            </div>
            <div class="food-name">{{ mon.tenMon.toUpperCase() }}</div>
            <div class="food-desc">{{ mon.loaiMonAn?.tenLoai || 'Món ăn đặc biệt' }} — thơm ngon, đảm bảo chất lượng</div>
            <div class="food-footer">
              <div class="food-price">{{ fmt(mon.gia) }}</div>
              <button class="btn-add" @click="addToCart(mon)">+</button>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════ PROMO ══════════ -->
    <section id="promo">
      <div class="promo-head">
        <span class="section-label">Ưu Đãi</span>
        <h2 class="section-title">Khuyến Mãi <span>Hôm Nay</span></h2>
      </div>
      <div class="promo-grid">
        <div
          v-for="(km, i) in activeVouchers.slice(0,2)"
          :key="km.id"
          class="promo-card"
          :class="i === 0 ? 'promo-card-1' : 'promo-card-2'"
        >
          <span class="promo-emoji">{{ i === 0 ? '🍔' : '🥤' }}</span>
          <div class="promo-tag">Giảm {{ km.phanTramGiam }}%</div>
          <div class="promo-title">{{ km.tenKhuyenMai }}<br>ƯU ĐÃI LỚN</div>
          <div class="promo-desc">
            Áp dụng mã <strong>{{ km.tenKhuyenMai }}</strong> khi thanh toán.
            Còn {{ km.soLuong ?? '∞' }} lượt sử dụng.
          </div>
          <router-link to="/thuc-don" class="btn-promo">Đặt Ngay →</router-link>
        </div>

        <template v-if="activeVouchers.length === 0 && !loadingVouchers">
          <div class="promo-card promo-card-1">
            <span class="promo-emoji">🍔</span>
            <div class="promo-tag">Giảm 30%</div>
            <div class="promo-title">BURGER<br>NGÀY THỨ 6</div>
            <div class="promo-desc">Mua 1 tặng 1 toàn bộ burger mỗi thứ Sáu. Áp dụng đến hết tháng!</div>
            <router-link to="/thuc-don" class="btn-promo">Đặt Ngay →</router-link>
          </div>
          <div class="promo-card promo-card-2">
            <span class="promo-emoji">🥤</span>
            <div class="promo-tag">Miễn Phí</div>
            <div class="promo-title">ĐỒ UỐNG<br>MIỄN PHÍ</div>
            <div class="promo-desc">Đơn hàng từ 150k được tặng 1 nước uống theo ý muốn.</div>
            <router-link to="/thuc-don" class="btn-promo">Xem Chi Tiết →</router-link>
          </div>
        </template>
      </div>
    </section>

    <!-- ══════════ WHY US ══════════ -->
    <section id="why">
      <div class="why-grid">
        <div class="why-visual">
          <img src="https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=800&q=80" alt="Kitchen">
          <div class="why-badge">
            <span>10+</span>
            <span>Năm Kinh Nghiệm</span>
          </div>
        </div>
        <div>
          <span class="section-label">Tại Sao Chọn Chúng Tôi</span>
          <h2 class="section-title">Chất Lượng <span>Không<br>Thỏa Hiệp</span></h2>
          <p class="section-sub">Từng món ăn đều được chế biến cẩn thận với nguyên liệu tươi sạch, đảm bảo hương vị chuẩn nhất mỗi ngày.</p>
          <div class="why-items">
            <div
              class="why-item"
              v-for="(item, i) in whyItems"
              :key="i"
              :class="{ visible: whyVisible }"
              :style="{ animationDelay: (i * 0.15) + 's' }"
            >
              <div class="why-icon">{{ item.icon }}</div>
              <div class="why-text">
                <h4>{{ item.title }}</h4>
                <p>{{ item.desc }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════ REVIEWS ══════════ -->
    <section id="reviews">
      <div class="reviews-head">
        <div>
          <span class="section-label">Đánh Giá</span>
          <h2 class="section-title">Khách Hàng <span>Nói Gì</span></h2>
        </div>
        <router-link to="/binh-luan" class="link-all reviews-link-all">
          Xem tất cả đánh giá →
        </router-link>
      </div>

      <div v-if="loadingReviews" class="reviews-grid">
        <div v-for="n in 3" :key="n" class="review-skeleton"></div>
      </div>

      <div v-else class="reviews-grid">
        <div
          class="review-card"
          v-for="(rv, i) in displayReviews"
          :key="rv.id || i"
          :class="{ visible: reviewsVisible }"
          :style="{ animationDelay: (i * 0.12) + 's' }"
        >
          <div class="review-stars">{{ renderStars(rv.diemDanhGia ?? rv.stars) }}</div>
          <p class="review-text">{{ rv.noiDung ?? rv.text }}</p>
          <div class="reviewer">
            <div class="reviewer-avatar">
              {{ rv.taiKhoan ? initials(rv.taiKhoan.hoTen) : rv.avatar }}
            </div>
            <div>
              <div class="reviewer-name">{{ rv.taiKhoan?.hoTen ?? rv.name }}</div>
              <div class="reviewer-role">
                <template v-if="rv.monAn">
                  <router-link :to="'/mon-an/' + rv.monAn.id" class="review-mon-link">
                    🍔 {{ rv.monAn.tenMon }}
                  </router-link>
                </template>
                <template v-else>{{ rv.role }}</template>
              </div>
            </div>
            <div class="review-date" v-if="rv.ngayTao">{{ fmtDate(rv.ngayTao) }}</div>
          </div>
        </div>
      </div>

      <div v-if="!loadingReviews && tongSoBinhLuan > 3" class="reviews-more">
        <router-link to="/binh-luan" class="btn-reviews-more">
          Xem thêm {{ tongSoBinhLuan - 3 }} đánh giá khác →
        </router-link>
      </div>
    </section>

    <!-- ══════════ CTA ══════════ -->
    <section id="cta">
      <div class="cta-inner">
        <div>
          <h2 class="cta-title">
            Đói Rồi? Đặt Ngay<br>
            <span>Nhận Ưu Đãi 20%</span><br>
            Cho Đơn Đầu Tiên!
          </h2>
          <p class="cta-sub">
            Nhập code <strong style="color:var(--yellow)">YUMMY20</strong> khi thanh toán.
            Áp dụng cho khách hàng mới.
          </p>
        </div>
        <div class="cta-actions">
          <router-link v-if="!auth.isLoggedIn" to="/dang-ky" class="btn-hero" style="font-size:1rem;font-weight:900">
            🍔 Đăng Ký & Đặt Món
          </router-link>
          <router-link v-else to="/thuc-don" class="btn-hero" style="font-size:1rem;font-weight:900">
            🍔 Đặt Món Ngay
          </router-link>
          <router-link v-if="!auth.isLoggedIn" to="/dang-nhap" class="btn-ghost" style="font-size:1rem;font-weight:900">
            Đăng Nhập
          </router-link>
        </div>
      </div>
    </section>

    <!-- ══════════ FOOTER ══════════ -->
    <footer>
      <div class="footer-top">
        <div class="footer-brand">
          <div class="footer-logo">
            <div class="footer-logo-icon">🍔</div>
            <div class="footer-logo-name">FastFood<span>YumMy</span></div>
          </div>
          <p>Đồ ăn nhanh chuẩn vị, giao tận nơi siêu tốc. Phục vụ từ 7:00 — 23:00 mỗi ngày.</p>
          <div class="footer-socials">
            <a class="social-btn" href="#">📘</a>
            <a class="social-btn" href="#">📸</a>
            <a class="social-btn" href="#">🎵</a>
            <a class="social-btn" href="#">▶️</a>
          </div>
        </div>
        <div class="footer-col">
          <h5>Thực Đơn</h5>
          <ul>
            <li v-for="cat in displayCategories.slice(0,5)" :key="cat.id">
              <router-link :to="'/thuc-don?loai=' + cat.id">{{ cat.tenLoai }}</router-link>
            </li>
          </ul>
        </div>
        <div class="footer-col">
          <h5>Hỗ Trợ</h5>
          <ul>
            <li><a href="#">Hướng dẫn đặt hàng</a></li>
            <li><a href="#">Chính sách đổi trả</a></li>
            <li><router-link to="/don-hang">Theo dõi đơn hàng</router-link></li>
            <li><a href="#">Liên hệ</a></li>
          </ul>
        </div>
        <div class="footer-col">
          <h5>Liên Hệ</h5>
          <ul>
            <li><a href="#">📞 1900-xxxx</a></li>
            <li><a href="#">✉️ hello@fastfoodyummy.vn</a></li>
            <li><a href="#">📍 TP. Hồ Chí Minh</a></li>
            <li><a href="#">🕐 7:00 - 23:00</a></li>
          </ul>
        </div>
      </div>
      <div class="footer-bottom">
        <p>© 2025 FastFoodYumMy. All rights reserved. Made with <span>❤️</span></p>
        <p>Chính sách bảo mật · Điều khoản sử dụng</p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useCartStore } from '../stores/cart'
import { useToastStore } from '../stores/toast'
import { monAnAPI, loaiMonAnAPI, khuyenMaiAPI, binhLuanAPI } from '../services/api'

const auth  = useAuthStore()
const cart  = useCartStore()
const toast = useToastStore()

// ── Data ──
const monAns          = ref([])
const categories      = ref([])
const activeVouchers  = ref([])
const loadingMenu     = ref(true)
const loadingVouchers = ref(true)
const activeTab       = ref(null)
const favorites       = ref(new Set())

// ── Reviews từ DB ──
const dbReviews      = ref([])
const loadingReviews = ref(true)
const tongSoBinhLuan = ref(0)

const fallbackReviews = [
  { stars:5, text:'Burger ngon nhất tôi từng ăn ở Sài Gòn! Giao hàng siêu nhanh, đóng gói cẩn thận. Sẽ order tiếp nhé!', avatar:'AN', name:'Nguyễn Anh',   role:'Khách hàng thân thiết' },
  { stars:5, text:'Combo gia đình quá xứng đáng! 4 người ăn no căng mà giá vừa phải. Gà rán giòn tan, phải thử ngay!',    avatar:'LH', name:'Lê Hương',     role:'Mẹ hai con' },
  { stars:4, text:'App đặt đồ dễ dùng, nhiều lựa chọn. Pizza 4 loại phô mai ăn là ghiền, tuần nào cũng order ít nhất 2 lần.', avatar:'TM', name:'Trần Minh', role:'Sinh viên' },
]

const displayReviews = computed(() =>
  dbReviews.value.length > 0 ? dbReviews.value : fallbackReviews
)

// ── Visibility ──
const showScrollTop  = ref(false)
const catsVisible    = ref(false)
const menuVisible    = ref(false)
const whyVisible     = ref(false)
const reviewsVisible = ref(false)

// ── Refs ──
const cursorDot  = ref(null)
const cursorRing = ref(null)

// ── Ticker ──
const tickerItems = [
  '🍔 Burger Bò Đặc Biệt', '🍟 Khoai Tây Giòn', '🍕 Pizza Phô Mai',
  '🥤 Combo Tiết Kiệm', '🍗 Gà Rán Giòn', '🧁 Dessert Siêu Ngon',
  '🌮 Taco Gà Cay', '🌭 Hotdog Xúc Xích',
]

// ── Stats ──
const stats = computed(() => [
  { display: monAns.value.length ? monAns.value.length + '+' : '50+', label: 'Món Ngon' },
  { display: '10K+', label: 'Khách Hàng' },
  { display: '30',   label: 'Phút Giao' },
  { display: '4.9',  label: 'Điểm Đánh Giá' },
])

const emojiMap = {
  'Burger':'🍔','Pizza':'🍕','Gà Rán':'🍗','Combo':'🥤',
  'Đồ Uống':'🧃','Tráng Miệng':'🧁','Khai Vị':'🍟',
}
function catEmoji(tenLoai) { return emojiMap[tenLoai] || '🍽️' }

const displayCategories = computed(() =>
  categories.value.map(c => ({ ...c, emoji: emojiMap[c.tenLoai] || '🍽️' }))
)

const featuredMenu = computed(() => {
  let list = monAns.value.filter(m => m.trangThai)
  if (activeTab.value) list = list.filter(m => m.loaiMonAn?.id === activeTab.value)
  return list.slice(0, 8)
})

const whyItems = [
  { icon:'🥩', title:'Nguyên Liệu Tươi 100%', desc:'Nhập trực tiếp từ trang trại mỗi sáng sớm, không chất bảo quản, an toàn cho cả gia đình.' },
  { icon:'⚡', title:'Giao Hàng Siêu Tốc',    desc:'Cam kết giao trong 30 phút hoặc hoàn tiền. Đội shipper chuyên nghiệp, phủ khắp thành phố.' },
  { icon:'💰', title:'Giá Cả Hợp Lý',          desc:'Ngon như nhà hàng, giá bình dân. Thường xuyên có combo ưu đãi và chương trình tích điểm.' },
]

// ── Helpers ──
function fmt(n) { return Number(n || 0).toLocaleString('vi') + 'đ' }
function scrollTo(id) { document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' }) }
function scrollToTop() { window.scrollTo({ top: 0, behavior: 'smooth' }) }

function renderStars(score) {
  const full  = Math.floor(score || 0)
  const empty = 5 - full
  return '★'.repeat(full) + '☆'.repeat(Math.max(0, empty))
}
function initials(name) {
  return (name || 'KH').split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
}
function fmtDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('vi', { day:'2-digit', month:'2-digit', year:'numeric' })
}

// ── Cart ──
function addToCart(mon) {
  cart.addItem(mon)
  toast.show(`Đã thêm "${mon.tenMon}" vào giỏ!`)
}
function toggleFav(id) {
  const next = new Set(favorites.value)
  next.has(id) ? next.delete(id) : next.add(id)
  favorites.value = next
}

// ── Custom cursor ──
let mx = 0, my = 0, rx = 0, ry = 0, rafId = null
function onMouseMove(e) {
  mx = e.clientX; my = e.clientY
  if (cursorDot.value) {
    cursorDot.value.style.left = mx + 'px'
    cursorDot.value.style.top  = my + 'px'
  }
}
function animateCursor() {
  rx += (mx - rx) * 0.12; ry += (my - ry) * 0.12
  if (cursorRing.value) {
    cursorRing.value.style.left = rx + 'px'
    cursorRing.value.style.top  = ry + 'px'
  }
  rafId = requestAnimationFrame(animateCursor)
}

function onScroll() { showScrollTop.value = window.scrollY > 400 }

function makeObserver(setter) {
  return new IntersectionObserver(entries => {
    entries.forEach(e => { if (e.isIntersecting) setter(true) })
  }, { threshold: 0.1 })
}

// ── Lifecycle ──
onMounted(async () => {
  // Menu + categories
  try {
    const [monRes, loaiRes] = await Promise.all([monAnAPI.getAll(), loaiMonAnAPI.getAll()])

    // [FIX] thêm optional chaining và fallback [] để tránh lỗi khi data undefined
    monAns.value     = monRes.data?.data   ?? monRes.data   ?? []
    const loaiRaw    = loaiRes.data?.data  ?? loaiRes.data  ?? []
    categories.value = Array.isArray(loaiRaw) ? loaiRaw.filter(c => c.trangThai) : []

  } catch (e) { console.error('Load menu error:', e) }
  finally { loadingMenu.value = false }

  // Vouchers
  try {
    const vcRes = await khuyenMaiAPI.getActive()
    // [FIX] optional chaining tương tự
    activeVouchers.value = vcRes.data?.data ?? vcRes.data ?? []
  } catch {}
  finally { loadingVouchers.value = false }

  // Bình luận từ DB — getRecent đã được thêm vào api.js
  try {
    const blRes = await binhLuanAPI.getRecent(3)
    const data  = blRes.data?.data ?? blRes.data ?? []
    if (Array.isArray(data)) {
      dbReviews.value      = data
      tongSoBinhLuan.value = data.length
    } else {
      dbReviews.value      = data.binhLuans  || []
      tongSoBinhLuan.value = data.tongSo     || dbReviews.value.length
    }
  } catch (e) {
    console.warn('Không thể load bình luận từ DB, dùng fallback:', e.message)
    dbReviews.value = []
  }
  finally { loadingReviews.value = false }

  // Cursor
  document.addEventListener('mousemove', onMouseMove)
  animateCursor()

  // Scroll
  window.addEventListener('scroll', onScroll)

  // Intersection observers
  const els = {
    categories: v => catsVisible.value    = v,
    menu:       v => menuVisible.value    = v,
    why:        v => whyVisible.value     = v,
    reviews:    v => reviewsVisible.value = v,
  }
  Object.entries(els).forEach(([id, setter]) => {
    const el = document.getElementById(id)
    if (el) makeObserver(setter).observe(el)
  })
})

onUnmounted(() => {
  document.removeEventListener('mousemove', onMouseMove)
  window.removeEventListener('scroll', onScroll)
  if (rafId) cancelAnimationFrame(rafId)
})
</script>

<style scoped>
/* ── Variables ── */
:root {
  --red:#e8273a; --red-dark:#b8001a; --yellow:#ffcc00;
  --dark:#0e0a0a; --dark2:#1a0f0f; --card:rgba(22,14,14,0.85);
  --text:#f5ede6; --muted:rgba(245,237,230,0.5); --border:rgba(255,255,255,0.08);
}

.trang-chu { font-family:'Nunito',sans-serif;background:#0e0a0a;color:#f5ede6;overflow-x:hidden;cursor:none; }

/* ── Cursor ── */
.cursor-dot { position:fixed;width:8px;height:8px;background:#e8273a;border-radius:50%;pointer-events:none;z-index:9999;transform:translate(-50%,-50%);transition:transform .1s; }
.cursor-ring { position:fixed;width:36px;height:36px;border:2px solid rgba(232,39,58,.5);border-radius:50%;pointer-events:none;z-index:9998;transform:translate(-50%,-50%); }

/* ── Grain ── */
.grain { position:fixed;inset:0;z-index:1000;pointer-events:none;opacity:.03;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px; }

.scroll-top { position:fixed;bottom:30px;right:30px;z-index:400;width:44px;height:44px;background:#e8273a;border:none;border-radius:50%;color:#fff;font-size:1.2rem;cursor:pointer;display:flex;align-items:center;justify-content:center;box-shadow:0 6px 20px rgba(232,39,58,.5);transform:translateY(80px);opacity:0;transition:transform .3s,opacity .3s; }
.scroll-top.show { transform:translateY(0);opacity:1; }
.scroll-top:hover { transform:translateY(-3px); }

section { padding:100px 60px; }
.section-label { display:inline-block;font-size:.72rem;font-weight:900;letter-spacing:.25em;text-transform:uppercase;color:#e8273a;margin-bottom:12px; }
.section-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(2.2rem,5vw,3.8rem);letter-spacing:.04em;line-height:1;color:#fff;margin-bottom:16px; }
.section-title span { color:#ffcc00; }
.section-sub { font-size:1rem;color:rgba(245,237,230,.5);font-weight:600;max-width:480px;line-height:1.7; }
.link-all { font-size:.85rem;font-weight:800;color:#e8273a;text-decoration:none; }
.link-all:hover { color:#ffcc00; }

/* ── HERO ── */
#hero { min-height:100vh;position:relative;display:flex;align-items:center;overflow:hidden;padding:100px 60px 60px; }
.hero-bg { position:absolute;inset:0;z-index:0;background:url('https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1600&q=80') center/cover no-repeat;filter:brightness(.2) saturate(1.2);transform:scale(1.05);animation:bgBreath 12s ease-in-out infinite alternate; }
@keyframes bgBreath { from{transform:scale(1.05)}to{transform:scale(1.1)} }
.hero-overlay { position:absolute;inset:0;z-index:1;background:linear-gradient(110deg,rgba(14,10,10,.95) 40%,rgba(14,10,10,.3) 100%); }
.hero-stripe { position:absolute;z-index:2;top:-10%;right:25%;width:5px;height:130%;background:linear-gradient(180deg,transparent,#e8273a,transparent);opacity:.25;transform:rotate(-12deg); }
.hero-stripe:nth-child(3) { right:28%;opacity:.12;width:2px; }
.hero-content { position:relative;z-index:5;max-width:650px; }
.hero-badge { display:inline-flex;align-items:center;gap:8px;background:rgba(232,39,58,.15);border:1px solid rgba(232,39,58,.3);border-radius:50px;padding:6px 16px;font-size:.75rem;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#e8273a;margin-bottom:24px;animation:fadeUp .7s .2s ease both; }
.badge-dot { width:6px;height:6px;background:#e8273a;border-radius:50%;animation:blink 1.2s infinite; }
@keyframes blink { 0%,100%{opacity:1}50%{opacity:0} }
.hero-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(3.5rem,8vw,7rem);line-height:.92;letter-spacing:.02em;color:#fff;margin-bottom:24px;animation:fadeUp .7s .35s ease both; }
.hero-title .accent { color:#ffcc00;display:block; }
.hero-title .outline { -webkit-text-stroke:2px rgba(255,255,255,.25);color:transparent;display:block; }
.hero-desc { font-size:1.05rem;font-weight:600;color:rgba(245,237,230,.5);line-height:1.7;max-width:460px;margin-bottom:36px;animation:fadeUp .7s .5s ease both; }
.hero-actions { display:flex;align-items:center;gap:16px;flex-wrap:wrap;animation:fadeUp .7s .62s ease both; }
.btn-hero { padding:15px 36px;background:#e8273a;font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.14em;color:#fff;text-decoration:none;border-radius:50px;border:none;cursor:pointer;position:relative;overflow:hidden;transition:transform .2s,box-shadow .3s;box-shadow:0 8px 32px rgba(232,39,58,.5); }
.btn-hero::before { content:'';position:absolute;top:0;left:-100%;width:60%;height:100%;background:linear-gradient(120deg,transparent,rgba(255,255,255,.2),transparent);transition:left .5s; }
.btn-hero:hover::before { left:150%; }
.btn-hero:hover { transform:translateY(-3px);box-shadow:0 16px 40px rgba(232,39,58,.65); }
.btn-ghost { padding:15px 36px;background:transparent;border:2px solid rgba(255,255,255,.2);border-radius:50px;font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.14em;color:#f5ede6;text-decoration:none;transition:border-color .3s,color .3s,transform .2s; }
.btn-ghost:hover { border-color:#ffcc00;color:#ffcc00;transform:translateY(-3px); }
.hero-stats { position:relative;z-index:5;display:flex;gap:40px;margin-top:60px;animation:fadeUp .7s .75s ease both; }
.stat { text-align:center; }
.stat-num { font-family:'Bebas Neue',sans-serif;font-size:2.4rem;color:#ffcc00;line-height:1;letter-spacing:.04em; }
.stat-label { font-size:.75rem;font-weight:800;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.5); }
.hero-food { position:absolute;right:5%;top:50%;transform:translateY(-50%);z-index:5;width:420px;animation:heroFloat 4s ease-in-out infinite alternate,fadeRight .9s .5s ease both; }
.hero-food img { width:100%;border-radius:50%;object-fit:cover; }
.hero-food-ring { position:absolute;inset:-16px;border-radius:50%;border:2px dashed rgba(232,39,58,.3);animation:spinSlow 20s linear infinite; }
.hero-food-ring2 { position:absolute;inset:-32px;border-radius:50%;border:1px dashed rgba(255,204,0,.2);animation:spinSlow 30s linear infinite reverse; }
@keyframes heroFloat { from{transform:translateY(-50%) translateX(0)}to{transform:translateY(-52%) translateX(10px)} }
@keyframes spinSlow { to{transform:rotate(360deg)} }
@keyframes fadeRight { from{opacity:0;transform:translateY(-50%) translateX(60px)}to{opacity:1;transform:translateY(-50%) translateX(0)} }
@keyframes fadeUp { from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)} }

/* ── TICKER ── */
.ticker { background:#e8273a;overflow:hidden;padding:14px 0;position:relative;z-index:10; }
.ticker-track { display:flex;white-space:nowrap;animation:tickerMove 25s linear infinite; }
@keyframes tickerMove { from{transform:translateX(0)}to{transform:translateX(-50%)} }
.ticker-item { display:inline-flex;align-items:center;gap:10px;padding:0 32px;font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.12em;color:#fff; }
.ticker-item::before { content:'★';color:#ffcc00;font-size:.8rem; }

/* ── CATEGORIES ── */
#categories { background:#1a0f0f; }
.cats-header { display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:48px; }
.cat-grid { display:grid;grid-template-columns:repeat(6,1fr);gap:16px; }
.cat-card { background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:20px;padding:28px 16px;display:flex;flex-direction:column;align-items:center;gap:12px;text-decoration:none;cursor:pointer;transition:transform .3s,background .3s,border-color .3s,box-shadow .3s;position:relative;overflow:hidden;opacity:0;transform:translateY(30px); }
.cat-card.visible { animation:fadeUp .5s ease forwards; }
.cat-card:hover { transform:translateY(-8px);background:rgba(232,39,58,.08);border-color:rgba(232,39,58,.3);box-shadow:0 20px 40px rgba(0,0,0,.4); }
.cat-emoji { font-size:2.8rem;line-height:1; }
.cat-name { font-size:.82rem;font-weight:800;letter-spacing:.06em;text-transform:uppercase;color:rgba(245,237,230,.5);text-align:center; }
.cat-card:hover .cat-name { color:#fff; }

/* ── MENU ── */
#menu { background:#0e0a0a; }
.menu-header { display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:32px; }
.menu-tabs { display:flex;gap:8px;margin-bottom:32px;border-bottom:1px solid rgba(255,255,255,.08);padding-bottom:0; }
.tab { padding:10px 24px;border:none;background:none;cursor:pointer;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:rgba(245,237,230,.5);border-bottom:2px solid transparent;margin-bottom:-1px;transition:color .25s,border-color .25s; }
.tab.active { color:#ffcc00;border-bottom-color:#ffcc00; }
.tab:hover:not(.active) { color:#f5ede6; }
.food-grid { display:grid;grid-template-columns:repeat(4,1fr);gap:24px; }
.food-card { background:rgba(22,14,14,.85);border:1px solid rgba(255,255,255,.08);border-radius:20px;overflow:hidden;position:relative;transition:transform .3s,box-shadow .3s;opacity:0;transform:translateY(30px); }
.food-card.visible { animation:fadeUp .5s ease forwards; }
.food-card:hover { transform:translateY(-6px);box-shadow:0 24px 50px rgba(0,0,0,.5),0 0 0 1px rgba(232,39,58,.2); }
.food-card-skeleton { background:rgba(255,255,255,.04);border-radius:20px;height:320px;animation:pulse 1.5s ease-in-out infinite; }
@keyframes pulse { 0%,100%{opacity:.4}50%{opacity:.7} }
.food-img-wrap { position:relative;height:200px;overflow:hidden;cursor:pointer; }
.food-img { width:100%;height:100%;object-fit:cover;transition:transform .5s;display:block; }
.food-card:hover .food-img { transform:scale(1.06); }
.food-img-ph { width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:4rem;background:rgba(255,255,255,.03); }
.food-badge { position:absolute;top:14px;left:14px;border-radius:50px;padding:4px 12px;font-size:.72rem;font-weight:900;letter-spacing:.08em;text-transform:uppercase; }
.food-badge.hot { background:#e8273a;color:#fff; }
.food-badge.new { background:#ffcc00;color:#0e0a0a; }
.food-fav { position:absolute;top:14px;right:14px;width:34px;height:34px;background:rgba(14,10,10,.7);border:1px solid rgba(255,255,255,.08);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.9rem;cursor:pointer;transition:transform .2s,background .2s;z-index:2; }
.food-fav:hover { transform:scale(1.2);background:rgba(232,39,58,.2); }
.food-fav.liked { background:rgba(232,39,58,.3);border-color:#e8273a; }
.food-body { padding:18px; }
.food-rating { display:flex;align-items:center;gap:4px;margin-bottom:10px; }
.stars { color:#ffcc00;font-size:.75rem;letter-spacing:2px; }
.food-rating span { font-size:.75rem;color:rgba(245,237,230,.5);font-weight:700; }
.food-name { font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.06em;color:#f5ede6;margin-bottom:5px; }
.food-desc { font-size:.78rem;color:rgba(245,237,230,.5);font-weight:600;line-height:1.5;margin-bottom:14px; }
.food-footer { display:flex;align-items:center;justify-content:space-between; }
.food-price { font-family:'Bebas Neue',sans-serif;font-size:1.3rem;letter-spacing:.04em;color:#ffcc00; }
.btn-add { width:36px;height:36px;background:#e8273a;border:none;border-radius:50%;color:#fff;font-size:1.3rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:transform .2s,box-shadow .2s;box-shadow:0 4px 14px rgba(232,39,58,.45); }
.btn-add:hover { transform:scale(1.15) rotate(90deg);box-shadow:0 8px 20px rgba(232,39,58,.6); }

/* ── PROMO ── */
#promo { background:#1a0f0f;padding:0 60px 100px; }
.promo-head { padding:100px 0 48px; }
.promo-grid { display:grid;grid-template-columns:1fr 1fr;gap:24px; }
.promo-card { border-radius:24px;padding:44px 40px;position:relative;overflow:hidden;min-height:220px;display:flex;flex-direction:column;justify-content:center; }
.promo-card-1 { background:linear-gradient(135deg,#1a0505,#3d0a0a);border:1px solid rgba(232,39,58,.25); }
.promo-card-2 { background:linear-gradient(135deg,#1a1500,#3d3000);border:1px solid rgba(255,204,0,.25); }
.promo-emoji { position:absolute;right:30px;top:50%;transform:translateY(-50%);font-size:6rem;opacity:.25;animation:promoFloat 3s ease-in-out infinite alternate; }
@keyframes promoFloat { from{transform:translateY(-50%) rotate(-5deg)}to{transform:translateY(-55%) rotate(5deg)} }
.promo-tag { display:inline-block;padding:4px 12px;border-radius:50px;font-size:.72rem;font-weight:900;letter-spacing:.12em;text-transform:uppercase;margin-bottom:12px; }
.promo-card-1 .promo-tag { background:rgba(232,39,58,.2);color:#e8273a; }
.promo-card-2 .promo-tag { background:rgba(255,204,0,.2);color:#ffcc00; }
.promo-title { font-family:'Bebas Neue',sans-serif;font-size:2.2rem;letter-spacing:.06em;color:#fff;line-height:1;margin-bottom:10px; }
.promo-desc { font-size:.88rem;color:rgba(245,237,230,.5);font-weight:600;max-width:260px;margin-bottom:20px; }
.promo-desc strong { color:#ffcc00; }
.btn-promo { display:inline-flex;align-items:center;gap:8px;padding:10px 24px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;text-decoration:none;transition:transform .2s;width:fit-content; }
.promo-card-1 .btn-promo { background:#e8273a;color:#fff;box-shadow:0 6px 20px rgba(232,39,58,.4); }
.promo-card-2 .btn-promo { background:#ffcc00;color:#0e0a0a;box-shadow:0 6px 20px rgba(255,204,0,.35); }
.btn-promo:hover { transform:translateY(-2px); }

/* ── WHY ── */
#why { background:#0e0a0a; }
.why-grid { display:grid;grid-template-columns:1fr 1fr;gap:80px;align-items:center; }
.why-visual { position:relative;aspect-ratio:1; }
.why-visual img { width:100%;height:100%;object-fit:cover;border-radius:30px;filter:brightness(.85); }
.why-badge { position:absolute;bottom:-20px;right:-20px;background:#e8273a;border-radius:50%;width:120px;height:120px;display:flex;flex-direction:column;align-items:center;justify-content:center;box-shadow:0 12px 40px rgba(232,39,58,.5);animation:badgePop .6s .8s ease both; }
@keyframes badgePop { from{opacity:0;transform:scale(0)}to{opacity:1;transform:scale(1)} }
.why-badge span:first-child { font-family:'Bebas Neue',sans-serif;font-size:1.8rem;color:#fff;line-height:1; }
.why-badge span:last-child { font-size:.6rem;font-weight:900;letter-spacing:.1em;color:rgba(255,255,255,.7);text-transform:uppercase; }
.why-items { display:flex;flex-direction:column;gap:28px;margin-top:40px; }
.why-item { display:flex;gap:18px;align-items:flex-start;opacity:0;transform:translateX(30px); }
.why-item.visible { animation:fadeLeft .5s ease forwards; }
@keyframes fadeLeft { to{opacity:1;transform:translateX(0)} }
.why-icon { width:52px;height:52px;flex-shrink:0;background:rgba(232,39,58,.1);border:1px solid rgba(232,39,58,.2);border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:1.4rem;transition:transform .3s,background .3s; }
.why-item:hover .why-icon { transform:scale(1.1) rotate(5deg);background:rgba(232,39,58,.2); }
.why-text h4 { font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.08em;color:#f5ede6;margin-bottom:4px; }
.why-text p { font-size:.85rem;color:rgba(245,237,230,.5);font-weight:600;line-height:1.6; }

/* ══════════ REVIEWS ══════════ */
#reviews { background:#1a0f0f; }
.reviews-head { display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:48px;flex-wrap:wrap;gap:16px; }
.reviews-link-all { font-size:.85rem;font-weight:800;color:#e8273a;text-decoration:none;white-space:nowrap;display:inline-flex;align-items:center;gap:5px;transition:color .2s,transform .2s; }
.reviews-link-all:hover { color:#ffcc00;transform:translateX(3px); }
.reviews-grid { display:grid;grid-template-columns:repeat(3,1fr);gap:24px; }
.review-skeleton { background:rgba(255,255,255,.04);border-radius:20px;height:200px;animation:pulse 1.5s ease-in-out infinite; }
.review-card { background:rgba(22,14,14,.85);border:1px solid rgba(255,255,255,.08);border-radius:20px;padding:28px;transition:transform .3s,border-color .3s,box-shadow .3s;opacity:0;transform:translateY(30px);position:relative;overflow:hidden; }
.review-card.visible { animation:fadeUp .5s ease forwards; }
.review-card:hover { transform:translateY(-4px);border-color:rgba(232,39,58,.2);box-shadow:0 16px 40px rgba(0,0,0,.4); }
.review-card::before { content:'';position:absolute;top:-30px;right:-30px;width:100px;height:100px;border-radius:50%;background:radial-gradient(circle,rgba(232,39,58,.08),transparent 70%);pointer-events:none; }
.review-stars { color:#ffcc00;font-size:.85rem;letter-spacing:3px;margin-bottom:14px; }
.review-text { font-size:.9rem;color:rgba(245,237,230,.7);font-weight:600;line-height:1.7;margin-bottom:20px;font-style:italic; }
.review-text::before { content:'"';font-family:'Bebas Neue',sans-serif;font-size:2.5rem;color:#e8273a;line-height:.5;vertical-align:-.4em;margin-right:4px; }
.reviewer { display:flex;align-items:center;gap:12px; }
.reviewer-avatar { width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#e8273a,#ffcc00);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:1rem;color:#fff;flex-shrink:0; }
.reviewer-name { font-weight:800;font-size:.9rem;color:#f5ede6; }
.reviewer-role { font-size:.75rem;color:rgba(245,237,230,.5);font-weight:600; }
.review-mon-link { font-size:.72rem;font-weight:700;color:rgba(232,39,58,.8);text-decoration:none;transition:color .2s; }
.review-mon-link:hover { color:#ffcc00; }
.review-date { margin-left:auto;font-size:.68rem;font-weight:600;color:rgba(245,237,230,.3);flex-shrink:0; }
.reviews-more { text-align:center;margin-top:36px; }
.btn-reviews-more { display:inline-flex;align-items:center;gap:8px;padding:12px 28px;background:rgba(232,39,58,.08);border:1px solid rgba(232,39,58,.25);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;color:#e8273a;text-decoration:none;transition:all .2s; }
.btn-reviews-more:hover { background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.4);transform:translateY(-2px);box-shadow:0 8px 20px rgba(232,39,58,.2); }

/* ── CTA ── */
#cta { background:#0e0a0a;padding:100px 60px; }
.cta-inner { background:linear-gradient(135deg,#1d0808,#2a0d0d 50%,#1d1400);border:1px solid rgba(232,39,58,.2);border-radius:30px;padding:70px 60px;display:flex;align-items:center;justify-content:space-between;position:relative;overflow:hidden; }
.cta-inner::before { content:'';position:absolute;top:-50%;right:-10%;width:500px;height:500px;border-radius:50%;background:radial-gradient(circle,rgba(232,39,58,.12),transparent 70%); }
.cta-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(2rem,4vw,3.2rem);letter-spacing:.04em;color:#fff;line-height:1.05;margin-bottom:14px; }
.cta-title span { color:#ffcc00; }
.cta-sub { font-size:1rem;color:rgba(245,237,230,.5);font-weight:600;max-width:400px; }
.cta-actions { display:flex;gap:14px;flex-shrink:0; }

/* ── FOOTER ── */
footer { background:#070404;border-top:1px solid rgba(255,255,255,.08);padding:60px 60px 30px; }
.footer-top { display:grid;grid-template-columns:1.5fr 1fr 1fr 1fr;gap:60px;margin-bottom:50px; }
.footer-logo { display:inline-flex;align-items:center;gap:10px;margin-bottom:14px; }
.footer-logo-icon { width:36px;height:36px;background:#e8273a;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px; }
.footer-logo-name { font-family:'Bebas Neue',sans-serif;font-size:1.4rem;letter-spacing:.06em;color:#fff; }
.footer-logo-name span { color:#ffcc00; }
.footer-brand p { font-size:.88rem;color:rgba(245,237,230,.5);line-height:1.7;max-width:260px; }
.footer-socials { display:flex;gap:10px;margin-top:20px; }
.social-btn { width:36px;height:36px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.85rem;text-decoration:none;transition:background .25s,transform .2s,border-color .25s; }
.social-btn:hover { background:rgba(232,39,58,.15);border-color:#e8273a;transform:translateY(-3px); }
.footer-col h5 { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.14em;color:#f5ede6;margin-bottom:18px; }
.footer-col ul { list-style:none;display:flex;flex-direction:column;gap:10px; }
.footer-col ul li a { text-decoration:none;font-size:.85rem;color:rgba(245,237,230,.5);font-weight:600;transition:color .25s,padding-left .25s; }
.footer-col ul li a:hover { color:#e8273a;padding-left:4px; }
.footer-bottom { border-top:1px solid rgba(255,255,255,.08);padding-top:24px;display:flex;justify-content:space-between;align-items:center; }
.footer-bottom p { font-size:.8rem;color:rgba(245,237,230,.5);font-weight:600; }
.footer-bottom span { color:#e8273a; }

/* ── Responsive ── */
@media (max-width:1100px) {
  .hero-food { display:none; }
  .food-grid { grid-template-columns:repeat(2,1fr); }
  .cat-grid  { grid-template-columns:repeat(3,1fr); }
  .footer-top { grid-template-columns:1fr 1fr;gap:40px; }
  .reviews-grid { grid-template-columns:repeat(2,1fr); }
}
@media (max-width:768px) {
  section { padding:70px 24px; }
  #hero { padding:90px 24px 60px; }
  #promo { padding:0 24px 70px; }
  #cta { padding:70px 24px; }
  footer { padding:40px 24px 20px; }
  .hero-title { font-size:3rem; }
  .hero-stats { gap:24px; }
  .food-grid  { grid-template-columns:1fr; }
  .cat-grid   { grid-template-columns:repeat(2,1fr); }
  .promo-grid,.why-grid,.reviews-grid { grid-template-columns:1fr; }
  .cta-inner  { flex-direction:column;gap:30px;padding:40px 24px; }
  .footer-top { grid-template-columns:1fr;gap:30px; }
  .footer-bottom { flex-direction:column;gap:10px;text-align:center; }
  .cursor-dot,.cursor-ring { display:none; }
  .trang-chu { cursor:auto; }
  .reviews-head { flex-direction:column;align-items:flex-start; }
}
</style>