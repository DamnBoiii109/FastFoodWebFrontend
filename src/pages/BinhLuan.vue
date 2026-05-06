<template>
  <div class="binh-luan-page">
    <div class="grain"></div>

    <!-- Topbar / Navbar -->
    <nav class="navbar">
      <router-link to="/" class="nav-brand">
        <div class="nav-icon">🍔</div>
        <div class="nav-name">FastFood<span>YumMy</span></div>
      </router-link>
      <div class="nav-links">
        <router-link to="/thuc-don" class="nav-link">Thực Đơn</router-link>
        <router-link to="/" class="nav-link">Trang Chủ</router-link>
      </div>
    </nav>

    <!-- Hero header -->
    <div class="page-hero">
      <div class="page-hero-bg"></div>
      <div class="page-hero-content">
        <span class="section-label">Cộng Đồng YumMy</span>
        <h1 class="page-title">Đánh Giá <span>Từ Khách Hàng</span></h1>
        <p class="page-sub">
          {{ tongSo }} đánh giá thực từ khách hàng đã trải nghiệm —
          không filter, không chỉnh sửa.
        </p>
        <!-- Tổng điểm trung bình -->
        <div v-if="!loading && tongSo > 0" class="hero-rating">
          <div class="hero-rating-num">{{ trungBinh.toFixed(1) }}</div>
          <div>
            <div class="hero-stars">{{ renderStars(trungBinh) }}</div>
            <div class="hero-rating-sub">Điểm trung bình</div>
          </div>
        </div>
      </div>
    </div>

    <div class="page-body">

      <!-- Filter bar -->
      <div class="filter-bar">
        <div class="filter-left">
          <button
            v-for="f in filters"
            :key="f.value"
            class="filter-btn"
            :class="{ active: activeFilter === f.value }"
            @click="activeFilter = f.value"
          >{{ f.label }}</button>
        </div>
        <div class="sort-box">
          <select v-model="sortBy" class="sort-select">
            <option value="newest">Mới nhất</option>
            <option value="oldest">Cũ nhất</option>
            <option value="highest">Điểm cao nhất</option>
            <option value="lowest">Điểm thấp nhất</option>
          </select>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="reviews-grid">
        <div v-for="n in 6" :key="n" class="review-skeleton"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="filteredList.length === 0" class="reviews-empty">
        <span>💬</span>
        <p>Chưa có đánh giá nào. Hãy là người đầu tiên!</p>
        <router-link to="/thuc-don" class="btn-empty">Xem Thực Đơn →</router-link>
      </div>

      <!-- Reviews grid -->
      <div v-else class="reviews-grid">
        <div
          v-for="(rv, i) in filteredList"
          :key="rv.id"
          class="review-card"
          :class="{ visible: true }"
          :style="{ animationDelay: (i % 6 * 0.07) + 's' }"
        >
          <!-- Star rating -->
          <div class="rv-stars">{{ renderStars(rv.diemDanhGia) }}</div>

          <!-- Content -->
          <p class="rv-text">{{ rv.noiDung }}</p>

          <!-- Meta -->
          <div class="rv-meta">
            <div class="rv-avatar">{{ initials(rv.taiKhoan?.hoTen) }}</div>
            <div class="rv-info">
              <div class="rv-name">{{ rv.taiKhoan?.hoTen || 'Khách hàng' }}</div>
              <div class="rv-sub">
                <span v-if="rv.monAn">
                  <!-- Link đến trang chi tiết có section bình luận -->
                  <router-link :to="'/mon-an/' + rv.monAn.id" class="rv-mon-link">
                    🍔 {{ rv.monAn.tenMon }}
                  </router-link>
                </span>
                <span v-if="rv.ngayTao" class="rv-date">{{ fmtDate(rv.ngayTao) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Phân trang -->
      <div v-if="!loading && tongSo > pageSize" class="pagination">
        <button
          class="page-btn"
          :disabled="page === 1"
          @click="page--; loadData()"
        >‹</button>
        <span class="page-info">{{ page }} / {{ totalPages }}</span>
        <button
          class="page-btn"
          :disabled="page === totalPages"
          @click="page++; loadData()"
        >›</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { binhLuanAPI } from '../services/api'

const allList     = ref([])
const loading     = ref(true)
const tongSo      = ref(0)
const trungBinh   = ref(0)
const activeFilter = ref('all')
const sortBy      = ref('newest')
const page        = ref(1)
const pageSize    = 9

const filters = [
  { value: 'all', label: 'Tất Cả' },
  { value: '5',   label: '⭐⭐⭐⭐⭐ 5 sao' },
  { value: '4',   label: '⭐⭐⭐⭐ 4 sao' },
  { value: '3',   label: '⭐⭐⭐ 3 sao trở xuống' },
]

const filteredList = computed(() => {
  let list = [...allList.value]

  // Filter theo sao
  if (activeFilter.value === '5') list = list.filter(r => r.diemDanhGia === 5)
  else if (activeFilter.value === '4') list = list.filter(r => r.diemDanhGia === 4)
  else if (activeFilter.value === '3') list = list.filter(r => r.diemDanhGia <= 3)

  // Sort
  if (sortBy.value === 'newest')  list.sort((a,b) => new Date(b.ngayTao) - new Date(a.ngayTao))
  if (sortBy.value === 'oldest')  list.sort((a,b) => new Date(a.ngayTao) - new Date(b.ngayTao))
  if (sortBy.value === 'highest') list.sort((a,b) => b.diemDanhGia - a.diemDanhGia)
  if (sortBy.value === 'lowest')  list.sort((a,b) => a.diemDanhGia - b.diemDanhGia)

  return list
})

const totalPages = computed(() => Math.ceil(tongSo.value / pageSize))

function renderStars(score) {
  const full  = Math.floor(score || 0)
  return '★'.repeat(full) + '☆'.repeat(Math.max(0, 5 - full))
}
function initials(name) {
  return (name || 'KH').split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
}
function fmtDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('vi', { day:'2-digit', month:'2-digit', year:'numeric' })
}

async function loadData() {
  loading.value = true
  try {
    // GET /api/binh-luan?page=X&limit=9&sort=newest
    const res  = await binhLuanAPI.getAll({ page: page.value, limit: pageSize, sort: sortBy.value })
    const data = res.data.data
    if (Array.isArray(data)) {
      allList.value   = data
      tongSo.value    = data.length
    } else {
      allList.value   = data.binhLuans  || []
      tongSo.value    = data.tongSo     || allList.value.length
      trungBinh.value = data.trungBinh  || 0
    }
  } catch (e) {
    console.error('Load bình luận thất bại:', e)
    allList.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
watch(sortBy, () => { page.value = 1; loadData() })
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

.binh-luan-page {
  min-height: 100vh; background: #0e0a0a;
  color: #f5ede6; font-family: 'Nunito', sans-serif;
  position: relative; overflow-x: hidden;
}

.grain {
  position: fixed; inset: 0; z-index: 999; pointer-events: none; opacity: .025;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 180px;
}

/* Navbar */
.navbar {
  position: sticky; top: 0; z-index: 100;
  background: rgba(14,10,10,.9); backdrop-filter: blur(18px);
  border-bottom: 1px solid rgba(255,255,255,.08);
  padding: 0 60px; height: 64px;
  display: flex; align-items: center; justify-content: space-between;
}
.nav-brand { display: flex; align-items: center; gap: 10px; text-decoration: none; }
.nav-icon { width: 36px; height: 36px; background: #e8273a; border-radius: 9px; display: flex; align-items: center; justify-content: center; font-size: 18px; box-shadow: 0 0 12px rgba(232,39,58,.4); }
.nav-name { font-family: 'Bebas Neue', sans-serif; font-size: 1.2rem; letter-spacing: .06em; color: #fff; }
.nav-name span { color: #ffcc00; }
.nav-links { display: flex; gap: 24px; }
.nav-link { font-size: .82rem; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; color: rgba(245,237,230,.5); text-decoration: none; transition: color .2s; }
.nav-link:hover, .nav-link.router-link-active { color: #e8273a; }

/* Page Hero */
.page-hero { position: relative; padding: 80px 60px 60px; overflow: hidden; }
.page-hero-bg {
  position: absolute; inset: 0;
  background: linear-gradient(135deg, #1d0808 0%, rgba(14,10,10,0) 60%);
}
.page-hero-bg::after {
  content: '';
  position: absolute; inset: 0;
  background: radial-gradient(ellipse at 80% 50%, rgba(232,39,58,.08) 0%, transparent 60%);
}
.page-hero-content { position: relative; z-index: 1; max-width: 700px; }
.section-label { display: inline-block; font-size: .72rem; font-weight: 900; letter-spacing: .25em; text-transform: uppercase; color: #e8273a; margin-bottom: 12px; }
.page-title { font-family: 'Bebas Neue', sans-serif; font-size: clamp(2.5rem, 6vw, 4.5rem); letter-spacing: .04em; color: #fff; line-height: 1; margin-bottom: 14px; }
.page-title span { color: #ffcc00; }
.page-sub { font-size: 1rem; font-weight: 600; color: rgba(245,237,230,.5); line-height: 1.7; margin-bottom: 28px; }
.hero-rating { display: flex; align-items: center; gap: 16px; }
.hero-rating-num { font-family: 'Bebas Neue', sans-serif; font-size: 3.5rem; color: #ffcc00; letter-spacing: .04em; line-height: 1; }
.hero-stars { color: #ffcc00; font-size: 1.1rem; letter-spacing: 3px; margin-bottom: 4px; }
.hero-rating-sub { font-size: .75rem; font-weight: 700; color: rgba(245,237,230,.4); text-transform: uppercase; letter-spacing: .1em; }

/* Body */
.page-body { padding: 0 60px 80px; }

/* Filter bar */
.filter-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 32px; gap: 12px; flex-wrap: wrap; }
.filter-left { display: flex; gap: 8px; flex-wrap: wrap; }
.filter-btn { padding: 8px 18px; border-radius: 50px; font-family: 'Nunito', sans-serif; font-size: .78rem; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; border: 1px solid rgba(255,255,255,.08); background: rgba(255,255,255,.04); color: rgba(245,237,230,.5); cursor: pointer; transition: all .2s; }
.filter-btn:hover { background: rgba(255,255,255,.08); color: #f5ede6; }
.filter-btn.active { background: rgba(232,39,58,.15); border-color: rgba(232,39,58,.3); color: #e8273a; box-shadow: 0 0 10px rgba(232,39,58,.1); }
.sort-select { background: rgba(255,255,255,.05); border: 1px solid rgba(255,255,255,.08); border-radius: 10px; padding: 8px 14px; color: #f5ede6; font-family: 'Nunito', sans-serif; font-size: .82rem; font-weight: 700; outline: none; cursor: pointer; transition: border-color .2s; }
.sort-select:focus { border-color: rgba(232,39,58,.3); }

/* Skeleton */
.review-skeleton { background: rgba(255,255,255,.04); border-radius: 18px; height: 180px; animation: pulse 1.5s ease-in-out infinite; }
@keyframes pulse { 0%,100%{opacity:.4} 50%{opacity:.7} }

/* Grid */
.reviews-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }

/* Empty */
.reviews-empty { text-align: center; padding: 80px 24px; color: rgba(245,237,230,.4); }
.reviews-empty span { font-size: 3rem; display: block; margin-bottom: 12px; }
.reviews-empty p { font-size: 1rem; font-weight: 600; margin-bottom: 20px; }
.btn-empty { display: inline-block; padding: 11px 24px; background: rgba(232,39,58,.1); border: 1px solid rgba(232,39,58,.25); border-radius: 50px; font-size: .85rem; font-weight: 900; color: #e8273a; text-decoration: none; transition: all .2s; }
.btn-empty:hover { background: rgba(232,39,58,.2); }

/* Review card */
.review-card {
  background: rgba(22,14,14,.85); border: 1px solid rgba(255,255,255,.07);
  border-radius: 18px; padding: 24px;
  transition: transform .3s, border-color .3s, box-shadow .3s;
  animation: fadeUp .4s ease both; position: relative; overflow: hidden;
}
.review-card::before {
  content: ''; position: absolute; top: -20px; right: -20px;
  width: 80px; height: 80px; border-radius: 50%;
  background: radial-gradient(circle, rgba(232,39,58,.07), transparent 70%);
  pointer-events: none;
}
@keyframes fadeUp { from { opacity:0; transform: translateY(16px); } to { opacity:1; transform:translateY(0); } }
.review-card:hover { transform: translateY(-4px); border-color: rgba(232,39,58,.2); box-shadow: 0 12px 32px rgba(0,0,0,.4); }

.rv-stars { color: #ffcc00; font-size: .88rem; letter-spacing: 3px; margin-bottom: 12px; }
.rv-text {
  font-size: .88rem; font-weight: 600; color: rgba(245,237,230,.75);
  line-height: 1.7; margin-bottom: 18px; font-style: italic;
  display: -webkit-box; -webkit-line-clamp: 4; -webkit-box-orient: vertical; overflow: hidden;
}
.rv-text::before { content: '"'; font-family: 'Bebas Neue', sans-serif; font-size: 2rem; color: #e8273a; line-height: .4; vertical-align: -.3em; margin-right: 2px; }

.rv-meta { display: flex; align-items: flex-start; gap: 10px; }
.rv-avatar { width: 38px; height: 38px; border-radius: 50%; background: linear-gradient(135deg, #e8273a, #ffcc00); display: flex; align-items: center; justify-content: center; font-weight: 900; font-size: .8rem; color: #fff; flex-shrink: 0; }
.rv-info { flex: 1; min-width: 0; }
.rv-name { font-size: .85rem; font-weight: 800; color: #f5ede6; margin-bottom: 3px; }
.rv-sub { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.rv-mon-link { font-size: .7rem; font-weight: 700; color: rgba(232,39,58,.8); text-decoration: none; transition: color .2s; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 130px; }
.rv-mon-link:hover { color: #ffcc00; }
.rv-date { font-size: .68rem; font-weight: 600; color: rgba(245,237,230,.3); }

/* Pagination */
.pagination { display: flex; align-items: center; justify-content: center; gap: 12px; margin-top: 40px; }
.page-btn { width: 40px; height: 40px; border-radius: 10px; border: 1px solid rgba(255,255,255,.08); background: rgba(255,255,255,.04); color: rgba(245,237,230,.6); font-size: 1.1rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all .2s; }
.page-btn:hover:not(:disabled) { background: rgba(232,39,58,.15); border-color: rgba(232,39,58,.3); color: #e8273a; }
.page-btn:disabled { opacity: .3; cursor: not-allowed; }
.page-info { font-family: 'Bebas Neue', sans-serif; font-size: 1rem; letter-spacing: .08em; color: rgba(245,237,230,.5); }

/* Responsive */
@media (max-width: 1024px) { .reviews-grid { grid-template-columns: repeat(2,1fr); } }
@media (max-width: 768px) {
  .navbar { padding: 0 24px; }
  .page-hero { padding: 60px 24px 40px; }
  .page-body { padding: 0 24px 60px; }
  .reviews-grid { grid-template-columns: 1fr; }
  .filter-bar { flex-direction: column; align-items: flex-start; }
}
</style>