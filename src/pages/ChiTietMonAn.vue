<template>
  <div class="chi-tiet-page">
    <div class="grain"></div>

    <!-- Back -->
    <div class="container">
      <router-link to="/thuc-don" class="back-link">← Quay lại thực đơn</router-link>

      <!-- Loading -->
      <div v-if="loading" class="sk-detail">
        <div class="sk-img"></div>
        <div class="sk-info">
          <div class="sk-line w60"></div>
          <div class="sk-line w40"></div>
          <div class="sk-line w80"></div>
        </div>
      </div>

      <!-- Not found -->
      <div v-else-if="!monAn" class="not-found">
        <div>🍽️</div>
        <p>Không tìm thấy món ăn này</p>
        <router-link to="/thuc-don" class="btn-primary">Xem thực đơn</router-link>
      </div>

      <!-- Content -->
      <div v-else class="detail-layout">

        <!-- Left: Ảnh -->
        <div class="detail-img-wrap">
          <img
            v-if="monAn.hinhAnh"
            :src="monAn.hinhAnh"
            :alt="monAn.tenMon"
            class="detail-img"
            @error="e => e.target.style.display='none'"
          >
          <div v-else class="detail-img-ph">{{ catEmoji }}</div>
        </div>

        <!-- Right: Info -->
        <div class="detail-info">
          <div class="detail-cat">{{ monAn.loaiMonAn?.tenLoai }}</div>
          <h1 class="detail-name">{{ monAn.tenMon }}</h1>

          <!-- Rating inline -->
          <div class="detail-rating" v-if="ratingData.soLuong > 0">
            <span class="stars">{{ renderStars(ratingData.trungBinh) }}</span>
            <span class="rating-val">{{ ratingData.trungBinh.toFixed(1) }}</span>
            <span class="rating-cnt">({{ ratingData.soLuong }} đánh giá)</span>
          </div>

          <div class="detail-price">{{ fmt(monAn.gia) }}</div>

          <div class="detail-status" :class="monAn.trangThai ? 'in-stock' : 'out-stock'">
            {{ monAn.trangThai ? '✅ Còn hàng' : '❌ Hết hàng' }}
          </div>

          <!-- Add to cart -->
          <div class="detail-actions">
            <div class="qty-control">
              <button @click="qty > 1 ? qty-- : null" class="qty-btn">−</button>
              <span class="qty-num">{{ qty }}</span>
              <button @click="qty++" class="qty-btn">+</button>
            </div>
            <button
              class="btn-add-cart"
              :disabled="!monAn.trangThai"
              @click="addToCart"
            >🛒 Thêm Vào Giỏ</button>
          </div>

          <!-- Tags -->
          <div class="detail-tags">
            <span class="tag">{{ monAn.loaiMonAn?.tenLoai || 'Món ăn' }}</span>
            <span class="tag" v-if="ratingData.trungBinh >= 4.5">⭐ Được yêu thích</span>
          </div>
        </div>
      </div>

      <!-- Bình luận component -->
      <BinhLuan
        v-if="monAn"
        :mon-an-id="monAn.id"
        :ten-mon="monAn.tenMon"
        @rating-updated="onRatingUpdated"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useCartStore } from '../stores/cart'
import { useToastStore } from '../stores/toast'
import { monAnAPI } from '../services/api'
import BinhLuan from '../components/BinhLuan.vue'

const route = useRoute()
const cart  = useCartStore()
const toast = useToastStore()

const monAn   = ref(null)
const loading = ref(true)
const qty     = ref(1)
const ratingData = ref({ trungBinh: 0, soLuong: 0 })

const emojiMap = {
  'Burger':'🍔','Pizza':'🍕','Gà Rán':'🍗','Combo':'🥤',
  'Đồ Uống':'🧃','Tráng Miệng':'🧁','Khai Vị':'🍟'
}
const catEmoji = computed(() =>
  emojiMap[monAn.value?.loaiMonAn?.tenLoai] || '🍽️'
)

function fmt(n)   { return Number(n||0).toLocaleString('vi') + 'đ' }
function renderStars(s) {
  return '★'.repeat(Math.floor(s||0)) + '☆'.repeat(5-Math.floor(s||0))
}

function addToCart() {
  for (let i = 0; i < qty.value; i++) cart.addItem(monAn.value)
  toast.show(`✅ Đã thêm ${qty.value}x ${monAn.value.tenMon}!`)
}

function onRatingUpdated(data) {
  ratingData.value = data
}

onMounted(async () => {
  const id = route.params.id
  try {
    const res = await monAnAPI.getById(id)
    monAn.value = res.data.data
  } catch { monAn.value = null }
  finally { loading.value = false }
})
</script>

<style scoped>
.chi-tiet-page { min-height:100vh;background:#0e0a0a;color:#f5ede6;padding:100px 0 60px;position:relative;font-family:'Nunito',sans-serif; }
.grain { position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px }
.container { max-width:1100px;margin:0 auto;padding:0 24px;position:relative; }
.back-link { display:inline-flex;align-items:center;gap:6px;font-size:.82rem;font-weight:800;color:rgba(245,237,230,.5);text-decoration:none;margin-bottom:28px;transition:color .2s; }
.back-link:hover { color:#e8273a; }

/* Skeleton */
.sk-detail { display:grid;grid-template-columns:1fr 1fr;gap:40px;margin-bottom:40px; }
.sk-img { background:rgba(255,255,255,.05);border-radius:20px;aspect-ratio:1;animation:skp 1.5s ease-in-out infinite; }
.sk-info { display:flex;flex-direction:column;gap:14px;padding-top:20px; }
.sk-line { background:rgba(255,255,255,.05);border-radius:8px;height:20px;animation:skp 1.5s ease-in-out infinite; }
.w40{width:40%}.w60{width:60%}.w80{width:80%}
@keyframes skp{0%,100%{opacity:.4}50%{opacity:.7}}

/* Not found */
.not-found { text-align:center;padding:80px;color:rgba(245,237,230,.4); }
.not-found div { font-size:4rem;margin-bottom:14px; }
.not-found p { font-size:.95rem;font-weight:600;margin-bottom:20px; }
.btn-primary { padding:11px 26px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:900;color:#fff;text-decoration:none;transition:all .2s; }

/* Detail layout */
.detail-layout { display:grid;grid-template-columns:1fr 1fr;gap:52px;align-items:flex-start;margin-bottom:48px; }
@media(max-width:768px){.detail-layout{grid-template-columns:1fr}}

/* Image */
.detail-img-wrap { border-radius:22px;overflow:hidden;background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);aspect-ratio:1;display:flex;align-items:center;justify-content:center; }
.detail-img { width:100%;height:100%;object-fit:cover;display:block; }
.detail-img-ph { font-size:8rem;opacity:.3; }

/* Info */
.detail-cat { font-size:.7rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:#e8273a;margin-bottom:8px; }
.detail-name { font-family:'Bebas Neue',sans-serif;font-size:clamp(2rem,4vw,3rem);letter-spacing:.04em;color:#fff;line-height:1;margin-bottom:12px; }
.detail-rating { display:flex;align-items:center;gap:7px;margin-bottom:14px; }
.stars { color:#ffcc00;font-size:.9rem;letter-spacing:2px; }
.rating-val { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.04em;color:#ffcc00; }
.rating-cnt { font-size:.75rem;color:rgba(245,237,230,.4);font-weight:700; }
.detail-price { font-family:'Bebas Neue',sans-serif;font-size:2.4rem;letter-spacing:.04em;color:#ffcc00;margin-bottom:10px; }
.detail-status { display:inline-block;font-size:.78rem;font-weight:800;margin-bottom:22px;padding:4px 12px;border-radius:50px; }
.in-stock  { background:rgba(74,222,128,.1);color:#4ade80;border:1px solid rgba(74,222,128,.2); }
.out-stock { background:rgba(248,113,113,.1);color:#f87171;border:1px solid rgba(248,113,113,.2); }

/* Actions */
.detail-actions { display:flex;align-items:center;gap:14px;margin-bottom:20px;flex-wrap:wrap; }
.qty-control { display:flex;align-items:center;gap:10px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:50px;padding:6px 16px; }
.qty-btn { background:none;border:none;color:#f5ede6;font-size:1.2rem;cursor:pointer;width:22px;display:flex;align-items:center;justify-content:center;transition:color .2s; }
.qty-btn:hover { color:#e8273a; }
.qty-num { font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.04em;color:#ffcc00;min-width:22px;text-align:center; }
.btn-add-cart { padding:12px 28px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.9rem;font-weight:900;color:#fff;cursor:pointer;transition:all .2s;box-shadow:0 6px 20px rgba(232,39,58,.4); }
.btn-add-cart:hover:not(:disabled) { background:#b8001a;transform:translateY(-2px); }
.btn-add-cart:disabled { opacity:.4;cursor:not-allowed; }

/* Tags */
.detail-tags { display:flex;gap:8px;flex-wrap:wrap; }
.tag { padding:4px 12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50px;font-size:.72rem;font-weight:800;color:rgba(245,237,230,.6); }

/* Divider trước bình luận */
.binh-luan-section { border-top:1px solid rgba(255,255,255,.08);margin-top:8px; }
</style>