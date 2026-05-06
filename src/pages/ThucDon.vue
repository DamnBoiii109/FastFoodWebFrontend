<template>
  <div class="thuc-don-page">
    <div class="grain"></div>

    <!-- Hero nhỏ -->
    <div class="page-hero">
      <div class="hero-content">
        <div class="page-label">Thực Đơn</div>
        <h1 class="page-title">Chọn Món <span>Yêu Thích</span></h1>
        <p class="page-sub">{{ filteredItems.length }} món ngon đang chờ bạn 🍔</p>
      </div>
    </div>

    <div class="container">
      <!-- Search + Filter bar -->
      <div class="filter-bar">
        <div class="search-box">
          <span class="search-icon">🔍</span>
          <input
            v-model="search"
            type="text"
            placeholder="Tìm món ăn..."
            class="search-input"
          >
          <button v-if="search" @click="search = ''" class="clear-btn">✕</button>
        </div>

        <div class="cat-tabs">
          <button
            class="cat-tab"
            :class="{ active: selectedCat === null }"
            @click="selectedCat = null"
          >
            Tất Cả
          </button>
          <button
            v-for="cat in categories"
            :key="cat.id"
            class="cat-tab"
            :class="{ active: selectedCat === cat.id }"
            @click="selectedCat = cat.id"
          >
            {{ cat.tenLoai }}
          </button>
        </div>

        <div class="sort-box">
          <select v-model="sortBy" class="sort-select">
            <option value="default">Mặc định</option>
            <option value="price_asc">Giá tăng dần</option>
            <option value="price_desc">Giá giảm dần</option>
            <option value="name">Tên A-Z</option>
          </select>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="loading-grid">
        <div v-for="n in 8" :key="n" class="skeleton-card"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="filteredItems.length === 0" class="empty-state">
        <div class="empty-icon">🍽️</div>
        <p>Không tìm thấy món nào phù hợp</p>
        <button @click="resetFilter" class="btn-reset">Xem tất cả món</button>
      </div>

      <!-- Grid -->
      <div v-else class="food-grid">
        <div
          v-for="mon in filteredItems"
          :key="mon.id"
          class="food-card"
        >
          <!-- Image -->
          <div class="card-img-wrap">
            <img
              v-if="mon.hinhAnh"
              :src="mon.hinhAnh"
              :alt="mon.tenMon"
              class="card-img"
              @error="e => e.target.style.display='none'"
            >
            <div v-else class="card-img-placeholder">🍔</div>

            <!-- Badge -->
            <span class="card-badge hot" v-if="mon.id <= 3">🔥 Hot</span>
            <span class="card-badge new" v-else-if="mon.id >= 10">✨ Mới</span>

            <!-- Quick add -->
            <button
              class="quick-add"
              @click.stop="addToCart(mon)"
              :class="{ added: justAdded === mon.id }"
            >
              {{ justAdded === mon.id ? '✓' : '+' }}
            </button>
          </div>

          <!-- Body -->
          <div class="card-body" @click="$router.push('/mon-an/' + mon.id)">
            <div class="card-cat">{{ mon.loaiMonAn?.tenLoai || 'Món ăn' }}</div>
            <div class="card-name">{{ mon.tenMon }}</div>
            <div class="card-footer">
              <div class="card-price">{{ fmt(mon.gia) }}</div>
              <button class="btn-add-cart" @click.stop="addToCart(mon)">
                Thêm vào giỏ
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast nhỏ -->
    <div class="mini-toast" :class="{ show: toastVisible }">
      🛒 Đã thêm vào giỏ hàng!
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useCartStore } from '../stores/cart'
import { monAnAPI, loaiMonAnAPI } from '../services/api'

const cart = useCartStore()

const items = ref([])
const categories = ref([])
const loading = ref(true)
const search = ref('')
const selectedCat = ref(null)
const sortBy = ref('default')
const justAdded = ref(null)
const toastVisible = ref(false)

const filteredItems = computed(() => {
  let list = [...items.value]

  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(m => m.tenMon.toLowerCase().includes(q))
  }

  if (selectedCat.value) {
    list = list.filter(m => m.loaiMonAn?.id === selectedCat.value)
  }

  if (sortBy.value === 'price_asc')  list.sort((a, b) => a.gia - b.gia)
  if (sortBy.value === 'price_desc') list.sort((a, b) => b.gia - a.gia)
  if (sortBy.value === 'name')       list.sort((a, b) => a.tenMon.localeCompare(b.tenMon))

  return list
})

function fmt(n) { return Number(n).toLocaleString('vi') + 'đ' }

function addToCart(mon) {
  cart.addItem(mon)
  justAdded.value = mon.id
  toastVisible.value = true
  setTimeout(() => { justAdded.value = null; toastVisible.value = false }, 1500)
}

function resetFilter() {
  search.value = ''
  selectedCat.value = null
}

onMounted(async () => {
  try {
    const [monRes, loaiRes] = await Promise.all([
      monAnAPI.getAll(),
      loaiMonAnAPI.getAll()
    ])
    items.value = monRes.data.data
    categories.value = loaiRes.data.data.filter(c => c.trangThai)
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.thuc-don-page { min-height:100vh;background:#0e0a0a;color:#f5ede6;position:relative }
.grain { position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px }
.page-hero { padding:120px 60px 50px;background:linear-gradient(110deg,rgba(14,10,10,.98) 50%,rgba(26,15,15,.8));position:relative }
.page-label { font-size:.72rem;font-weight:900;letter-spacing:.25em;text-transform:uppercase;color:#e8273a;margin-bottom:10px }
.page-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(2.5rem,6vw,4.5rem);letter-spacing:.04em;color:#fff;margin-bottom:10px;line-height:1 }
.page-title span { color:#ffcc00 }
.page-sub { font-size:1rem;color:rgba(245,237,230,.5);font-weight:600 }
.container { max-width:1200px;margin:0 auto;padding:0 24px 60px;position:relative }
.filter-bar { display:flex;align-items:center;gap:14px;margin-bottom:32px;flex-wrap:wrap }
.search-box { display:flex;align-items:center;gap:8px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:10px 16px;flex:1;min-width:220px }
.search-icon { flex-shrink:0;opacity:.5 }
.search-input { background:none;border:none;outline:none;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:600;flex:1 }
.search-input::placeholder { color:rgba(245,237,230,.4) }
.clear-btn { background:none;border:none;color:rgba(245,237,230,.4);cursor:pointer;font-size:.8rem }
.cat-tabs { display:flex;gap:7px;flex-wrap:wrap }
.cat-tab { padding:8px 16px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.75rem;font-weight:800;letter-spacing:.06em;text-transform:uppercase;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(245,237,230,.5);cursor:pointer;transition:all .2s }
.cat-tab:hover,.cat-tab.active { background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.3);color:#e8273a }
.sort-select { background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:10px;padding:9px 12px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:600;outline:none;cursor:pointer }
.sort-select option { background:#130a0a }
.food-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:20px }
.food-card { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;overflow:hidden;transition:transform .3s,box-shadow .3s,border-color .3s;cursor:pointer }
.food-card:hover { transform:translateY(-5px);box-shadow:0 20px 40px rgba(0,0,0,.5);border-color:rgba(232,39,58,.2) }
.card-img-wrap { position:relative;height:180px;overflow:hidden;background:rgba(255,255,255,.03) }
.card-img { width:100%;height:100%;object-fit:cover;transition:transform .5s }
.food-card:hover .card-img { transform:scale(1.06) }
.card-img-placeholder { width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:4rem;opacity:.3 }
.card-badge { position:absolute;top:12px;left:12px;padding:3px 10px;border-radius:50px;font-size:.68rem;font-weight:900;letter-spacing:.08em;text-transform:uppercase }
.card-badge.hot { background:#e8273a;color:#fff }
.card-badge.new { background:#ffcc00;color:#0e0a0a }
.quick-add { position:absolute;bottom:12px;right:12px;width:34px;height:34px;border-radius:50%;background:#e8273a;border:none;color:#fff;font-size:1.2rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .25s;box-shadow:0 4px 12px rgba(232,39,58,.5) }
.quick-add:hover { transform:scale(1.15) }
.quick-add.added { background:#4ade80;transform:scale(1.1) }
.card-body { padding:16px }
.card-cat { font-size:.68rem;font-weight:900;letter-spacing:.12em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-bottom:5px }
.card-name { font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.05em;color:#fff;margin-bottom:12px;line-height:1.2 }
.card-footer { display:flex;align-items:center;justify-content:space-between }
.card-price { font-family:'Bebas Neue',sans-serif;font-size:1.3rem;letter-spacing:.04em;color:#ffcc00 }
.btn-add-cart { padding:6px 14px;background:rgba(232,39,58,.15);border:1px solid rgba(232,39,58,.3);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.72rem;font-weight:800;color:#e8273a;cursor:pointer;transition:all .2s }
.btn-add-cart:hover { background:#e8273a;color:#fff }
.skeleton-card { background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.06);border-radius:18px;height:300px;animation:pulse 1.5s ease-in-out infinite }
@keyframes pulse { 0%,100%{opacity:.4} 50%{opacity:.7} }
.loading-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:20px }
.empty-state { text-align:center;padding:80px 20px }
.empty-icon { font-size:4rem;margin-bottom:16px;opacity:.3 }
.empty-state p { color:rgba(245,237,230,.5);font-size:.95rem;font-weight:600;margin-bottom:20px }
.btn-reset { padding:10px 24px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;color:#fff;cursor:pointer }
.mini-toast { position:fixed;bottom:30px;left:50%;transform:translateX(-50%) translateY(80px);background:rgba(14,10,10,.95);border:1px solid rgba(255,255,255,.1);backdrop-filter:blur(12px);border-radius:50px;padding:11px 22px;font-size:.85rem;font-weight:700;color:#f5ede6;transition:transform .4s cubic-bezier(.34,1.56,.64,1);z-index:900 }
.mini-toast.show { transform:translateX(-50%) translateY(0) }
@media(max-width:768px){ .page-hero{padding:100px 24px 36px} .filter-bar{flex-direction:column;align-items:stretch} .search-box{min-width:unset} }
</style>