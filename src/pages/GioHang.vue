<template>
  <div class="gio-hang-page">
    <div class="grain"></div>

    <div class="container">
      <!-- Header -->
      <div class="page-header">
        <div>
          <div class="page-label">Giỏ Hàng</div>
          <h1 class="page-title">Đơn Hàng <span>Của Bạn</span></h1>
        </div>
        <router-link to="/thuc-don" class="btn-outline">
          ← Thêm Món
        </router-link>
      </div>

      <!-- Empty cart -->
      <div v-if="cart.items.length === 0" class="empty-cart">
        <div class="empty-icon">🛒</div>
        <h2>Giỏ hàng trống</h2>
        <p>Hãy thêm món ngon vào giỏ của bạn nhé!</p>
        <router-link to="/thuc-don" class="btn-primary">
          🍔 Xem Thực Đơn
        </router-link>
      </div>

      <!-- Cart content -->
      <div v-else class="cart-layout">

        <!-- Left: items -->
        <div class="cart-items">
          <div class="section-title-sm">
            {{ cart.totalItems }} Món Đã Chọn
          </div>

          <div class="item-list">
            <div
              v-for="item in cart.items"
              :key="item.id"
              class="cart-item"
            >
              <!-- Image -->
              <div class="item-img">
                <img
                  v-if="item.hinhAnh"
                  :src="item.hinhAnh"
                  :alt="item.tenMon"
                  @error="e => e.target.style.display='none'"
                >
                <span v-else class="item-img-placeholder">🍔</span>
              </div>

              <!-- Info -->
              <div class="item-info">
                <div class="item-name">{{ item.tenMon }}</div>
                <div class="item-price-unit">{{ fmt(item.gia) }} / món</div>
              </div>

              <!-- Quantity -->
              <div class="item-qty">
                <button @click="cart.updateQty(item.id, item.soLuong - 1)" class="qty-btn">−</button>
                <span class="qty-num">{{ item.soLuong }}</span>
                <button @click="cart.updateQty(item.id, item.soLuong + 1)" class="qty-btn">+</button>
              </div>

              <!-- Subtotal -->
              <div class="item-subtotal">{{ fmt(item.gia * item.soLuong) }}</div>

              <!-- Remove -->
              <button @click="cart.removeItem(item.id)" class="item-remove">✕</button>
            </div>
          </div>

          <!-- Clear all -->
          <button @click="confirmClear" class="btn-clear">
            🗑️ Xóa Tất Cả
          </button>
        </div>

        <!-- Right: summary -->
        <div class="cart-summary">
          <div class="summary-card">
            <div class="summary-title">Tổng Thanh Toán</div>

            <!-- Voucher -->
            <div class="voucher-section">
              <div class="voucher-label">Mã Giảm Giá</div>
              <div v-if="cart.khuyenMai" class="voucher-applied">
                <span>🎟️ {{ cart.khuyenMai.tenKhuyenMai }}</span>
                <span class="voucher-discount">-{{ cart.khuyenMai.phanTramGiam }}%</span>
                <button @click="cart.removeKhuyenMai()" class="voucher-remove">✕</button>
              </div>
              <div v-else class="voucher-input-row">
                <input
                  v-model="voucherCode"
                  type="text"
                  placeholder="Nhập mã voucher..."
                  class="voucher-input"
                  @keyup.enter="applyVoucher"
                >
                <button @click="applyVoucher" class="btn-apply" :disabled="applyingVoucher">
                  {{ applyingVoucher ? '...' : 'Áp Dụng' }}
                </button>
              </div>
              <div v-if="voucherError" class="voucher-error">{{ voucherError }}</div>
            </div>

            <!-- Breakdown -->
            <div class="summary-rows">
              <div class="sum-row">
                <span>Tạm tính</span>
                <span>{{ fmt(cart.subtotal) }}</span>
              </div>
              <div class="sum-row discount" v-if="cart.discountAmount > 0">
                <span>Giảm giá ({{ cart.khuyenMai.phanTramGiam }}%)</span>
                <span>-{{ fmt(cart.discountAmount) }}</span>
              </div>
              <div class="sum-row">
                <span>VAT (8%)</span>
                <span>{{ fmt(cart.vat) }}</span>
              </div>
              <div class="sum-row">
                <span>Phí giao hàng</span>
                <span class="free">Miễn phí</span>
              </div>
            </div>

            <div class="sum-divider"></div>

            <div class="sum-total">
              <span>TỔNG CỘNG</span>
              <span class="total-amount">{{ fmt(cart.total) }}</span>
            </div>

            <!-- Checkout button -->
            <router-link
              v-if="auth.isLoggedIn"
              to="/thanh-toan"
              class="btn-checkout"
            >
              🧾 Tiến Hành Thanh Toán
            </router-link>
            <router-link v-else to="/dang-nhap" class="btn-checkout">
              🔐 Đăng Nhập Để Thanh Toán
            </router-link>

            <!-- Notes -->
            <div class="checkout-note">
              🔒 Thanh toán an toàn & bảo mật<br>
              ⚡ Giao hàng trong 30 phút
            </div>
          </div>

          <!-- Recommended (simple) -->
          <div class="recommend-section">
            <div class="recommend-title">Thêm Vào Đơn?</div>
            <div class="recommend-list">
              <div
                v-for="mon in recommended"
                :key="mon.id"
                class="recommend-item"
                @click="addRecommended(mon)"
              >
                <img
                  v-if="mon.hinhAnh"
                  :src="mon.hinhAnh"
                  :alt="mon.tenMon"
                  class="rec-img"
                >
                <div v-else class="rec-img rec-placeholder">🍟</div>
                <div class="rec-info">
                  <div class="rec-name">{{ mon.tenMon }}</div>
                  <div class="rec-price">{{ fmt(mon.gia) }}</div>
                </div>
                <button class="rec-add">+</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { khuyenMaiAPI, monAnAPI } from '../services/api'

const cart = useCartStore()
const auth = useAuthStore()

const voucherCode = ref('')
const voucherError = ref('')
const applyingVoucher = ref(false)
const recommended = ref([])

// Format tiền VND
function fmt(n) {
  return Number(n).toLocaleString('vi') + 'đ'
}

// Áp dụng voucher
async function applyVoucher() {
  if (!voucherCode.value.trim()) return
  voucherError.value = ''
  applyingVoucher.value = true
  try {
    const res = await khuyenMaiAPI.getActive()
    const vouchers = res.data.data
    const found = vouchers.find(v =>
      v.tenKhuyenMai.toUpperCase() === voucherCode.value.toUpperCase()
    )
    if (found) {
      cart.applyKhuyenMai(found)
      voucherCode.value = ''
    } else {
      voucherError.value = 'Mã không hợp lệ hoặc đã hết hạn'
    }
  } catch {
    voucherError.value = 'Không thể kiểm tra voucher'
  } finally {
    applyingVoucher.value = false
  }
}

// Xóa tất cả giỏ hàng
function confirmClear() {
  if (confirm('Bạn có chắc muốn xóa tất cả?')) cart.clearCart()
}

// Thêm món gợi ý
function addRecommended(mon) {
  cart.addItem(mon)
}

// Load gợi ý (lấy vài món không có trong giỏ)
onMounted(async () => {
  try {
    const res = await monAnAPI.getAll()
    const all = res.data.data
    const inCart = new Set(cart.items.map(i => i.id))
    recommended.value = all.filter(m => !inCart.has(m.id)).slice(0, 3)
  } catch {}
})
</script>

<style scoped>
.gio-hang-page {
  min-height: 100vh;
  background: var(--dark, #0e0a0a);
  color: var(--text, #f5ede6);
  padding: 100px 0 60px;
  position: relative;
}
.grain {
  position: fixed; inset: 0; z-index: 0; pointer-events: none; opacity: .025;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  background-size: 180px;
}
.container { max-width: 1200px; margin: 0 auto; padding: 0 24px; position: relative; }
.page-header { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 36px; }
.page-label { font-size: .72rem; font-weight: 900; letter-spacing: .25em; text-transform: uppercase; color: #e8273a; margin-bottom: 8px; }
.page-title { font-family: 'Bebas Neue', sans-serif; font-size: clamp(2rem, 5vw, 3.2rem); letter-spacing: .04em; color: #fff; }
.page-title span { color: #ffcc00; }
.btn-outline { padding: 10px 22px; border: 1.5px solid rgba(255,255,255,.2); border-radius: 50px; font-size: .85rem; font-weight: 800; color: #f5ede6; text-decoration: none; transition: all .2s; }
.btn-outline:hover { border-color: #e8273a; color: #e8273a; }

/* Empty state */
.empty-cart { text-align: center; padding: 80px 20px; }
.empty-icon { font-size: 5rem; margin-bottom: 20px; opacity: .4; }
.empty-cart h2 { font-family: 'Bebas Neue', sans-serif; font-size: 2rem; letter-spacing: .06em; color: #fff; margin-bottom: 10px; }
.empty-cart p { color: rgba(245,237,230,.5); font-size: .95rem; margin-bottom: 28px; }
.btn-primary { display: inline-flex; align-items: center; gap: 8px; padding: 14px 32px; background: #e8273a; border: none; border-radius: 50px; font-family: 'Nunito', sans-serif; font-size: 1rem; font-weight: 900; color: #fff; text-decoration: none; cursor: pointer; transition: all .2s; box-shadow: 0 6px 20px rgba(232,39,58,.4); }
.btn-primary:hover { background: #b8001a; transform: translateY(-2px); }

/* Layout */
.cart-layout { display: grid; grid-template-columns: 1fr 380px; gap: 24px; align-items: start; }
@media (max-width: 900px) { .cart-layout { grid-template-columns: 1fr; } }

/* Items */
.cart-items { background: rgba(22,14,14,.9); border: 1px solid rgba(255,255,255,.08); border-radius: 20px; overflow: hidden; }
.section-title-sm { padding: 18px 22px; font-family: 'Bebas Neue', sans-serif; font-size: 1.1rem; letter-spacing: .08em; color: #fff; border-bottom: 1px solid rgba(255,255,255,.08); }
.item-list { padding: 8px 0; }
.cart-item { display: flex; align-items: center; gap: 14px; padding: 14px 20px; border-bottom: 1px solid rgba(255,255,255,.04); transition: background .2s; }
.cart-item:hover { background: rgba(255,255,255,.02); }
.cart-item:last-child { border-bottom: none; }
.item-img { width: 56px; height: 56px; border-radius: 12px; overflow: hidden; flex-shrink: 0; background: rgba(255,255,255,.06); display: flex; align-items: center; justify-content: center; }
.item-img img { width: 100%; height: 100%; object-fit: cover; }
.item-img-placeholder { font-size: 1.8rem; }
.item-info { flex: 1; min-width: 0; }
.item-name { font-weight: 800; font-size: .9rem; color: #f5ede6; margin-bottom: 3px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.item-price-unit { font-size: .75rem; color: rgba(245,237,230,.5); font-weight: 600; }
.item-qty { display: flex; align-items: center; gap: 8px; }
.qty-btn { width: 26px; height: 26px; border-radius: 50%; background: rgba(255,255,255,.08); border: 1px solid rgba(255,255,255,.1); color: #f5ede6; font-size: .9rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all .2s; }
.qty-btn:hover { background: rgba(232,39,58,.2); border-color: rgba(232,39,58,.3); }
.qty-num { font-family: 'Bebas Neue', sans-serif; font-size: 1.1rem; color: #ffcc00; width: 22px; text-align: center; }
.item-subtotal { font-family: 'Bebas Neue', sans-serif; font-size: 1.1rem; letter-spacing: .04em; color: #fff; min-width: 80px; text-align: right; }
.item-remove { width: 26px; height: 26px; border-radius: 7px; background: rgba(248,113,113,.08); border: 1px solid rgba(248,113,113,.15); color: #f87171; font-size: .75rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all .2s; }
.item-remove:hover { background: rgba(248,113,113,.2); }
.btn-clear { margin: 12px 20px; padding: 8px 18px; background: transparent; border: 1px solid rgba(248,113,113,.2); border-radius: 50px; color: rgba(248,113,113,.7); font-family: 'Nunito', sans-serif; font-size: .78rem; font-weight: 800; cursor: pointer; transition: all .2s; }
.btn-clear:hover { background: rgba(248,113,113,.1); color: #f87171; }

/* Summary */
.cart-summary { display: flex; flex-direction: column; gap: 16px; }
.summary-card { background: rgba(10,6,6,.97); border: 1px solid rgba(255,255,255,.08); border-radius: 20px; padding: 22px; }
.summary-title { font-family: 'Bebas Neue', sans-serif; font-size: 1.2rem; letter-spacing: .08em; color: #fff; margin-bottom: 18px; }
.voucher-section { margin-bottom: 18px; }
.voucher-label { font-size: .7rem; font-weight: 900; letter-spacing: .15em; text-transform: uppercase; color: rgba(245,237,230,.5); margin-bottom: 8px; }
.voucher-applied { display: flex; align-items: center; gap: 8px; background: rgba(255,204,0,.08); border: 1px solid rgba(255,204,0,.2); border-radius: 10px; padding: 8px 12px; font-size: .82rem; font-weight: 700; color: #ffcc00; }
.voucher-discount { margin-left: auto; }
.voucher-remove { background: none; border: none; color: rgba(255,204,0,.6); cursor: pointer; font-size: .8rem; }
.voucher-input-row { display: flex; gap: 7px; }
.voucher-input { flex: 1; background: rgba(255,255,255,.05); border: 1px solid rgba(255,255,255,.08); border-radius: 10px; padding: 9px 12px; color: #f5ede6; font-family: 'Nunito', sans-serif; font-size: .82rem; font-weight: 600; outline: none; text-transform: uppercase; }
.voucher-input:focus { border-color: rgba(255,204,0,.3); }
.btn-apply { padding: 0 14px; background: rgba(255,204,0,.1); border: 1px solid rgba(255,204,0,.22); border-radius: 10px; color: #ffcc00; font-family: 'Nunito', sans-serif; font-size: .78rem; font-weight: 900; cursor: pointer; transition: all .2s; white-space: nowrap; }
.btn-apply:hover:not(:disabled) { background: rgba(255,204,0,.2); }
.btn-apply:disabled { opacity: .5; }
.voucher-error { font-size: .75rem; color: #f87171; margin-top: 5px; font-weight: 700; }
.summary-rows { display: flex; flex-direction: column; gap: 8px; margin-bottom: 14px; }
.sum-row { display: flex; justify-content: space-between; font-size: .82rem; font-weight: 700; color: rgba(245,237,230,.6); }
.sum-row.discount { color: #e8273a; }
.free { color: #4ade80; }
.sum-divider { height: 1px; background: rgba(255,255,255,.08); margin: 12px 0; }
.sum-total { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }
.sum-total span:first-child { font-family: 'Bebas Neue', sans-serif; font-size: 1rem; letter-spacing: .1em; color: #fff; }
.total-amount { font-family: 'Bebas Neue', sans-serif; font-size: 1.6rem; letter-spacing: .04em; color: #ffcc00; }
.btn-checkout { display: block; width: 100%; padding: 14px; background: #e8273a; border: none; border-radius: 12px; font-family: 'Bebas Neue', sans-serif; font-size: 1.15rem; letter-spacing: .1em; color: #fff; text-align: center; text-decoration: none; cursor: pointer; transition: all .2s; box-shadow: 0 5px 18px rgba(232,39,58,.45); margin-bottom: 12px; }
.btn-checkout:hover { background: #b8001a; transform: translateY(-2px); box-shadow: 0 9px 26px rgba(232,39,58,.6); }
.checkout-note { font-size: .72rem; color: rgba(245,237,230,.4); font-weight: 600; line-height: 1.8; text-align: center; }

/* Recommend */
.recommend-section { background: rgba(22,14,14,.9); border: 1px solid rgba(255,255,255,.08); border-radius: 20px; padding: 18px; }
.recommend-title { font-family: 'Bebas Neue', sans-serif; font-size: 1rem; letter-spacing: .08em; color: rgba(245,237,230,.6); margin-bottom: 12px; }
.recommend-list { display: flex; flex-direction: column; gap: 10px; }
.recommend-item { display: flex; align-items: center; gap: 10px; padding: 8px; border-radius: 12px; border: 1px solid rgba(255,255,255,.06); cursor: pointer; transition: all .2s; }
.recommend-item:hover { background: rgba(232,39,58,.06); border-color: rgba(232,39,58,.2); }
.rec-img { width: 40px; height: 40px; border-radius: 8px; object-fit: cover; flex-shrink: 0; background: rgba(255,255,255,.06); }
.rec-placeholder { display: flex; align-items: center; justify-content: center; font-size: 1.2rem; }
.rec-info { flex: 1; }
.rec-name { font-size: .78rem; font-weight: 800; color: #f5ede6; }
.rec-price { font-size: .7rem; color: #ffcc00; font-weight: 700; }
.rec-add { width: 26px; height: 26px; border-radius: 50%; background: #e8273a; border: none; color: #fff; font-size: 1rem; cursor: pointer; display: flex; align-items: center; justify-content: center; }
</style>