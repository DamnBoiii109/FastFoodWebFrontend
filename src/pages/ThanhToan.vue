<!-- ============================================================
  ThanhToan.vue  —  /thanh-toan
============================================================ -->
<template>
  <div class="page">
    <div class="grain"></div>
    <div class="container">
      <div class="page-header">
        <div class="page-label">Bước Cuối</div>
        <h1 class="page-title">Thanh <span>Toán</span></h1>
      </div>

      <div class="checkout-layout">
        <!-- Left: form -->
        <div class="checkout-form">
          <div class="form-section">
            <div class="form-section-title">📍 Thông Tin Giao Hàng</div>
            <div class="form-row">
              <div class="form-group">
                <label>Họ Tên</label>
                <input v-model="form.hoTen" type="text" :placeholder="auth.user?.hoTen" class="finput">
              </div>
              <div class="form-group">
                <label>Số Điện Thoại</label>
                <input v-model="form.sdt" type="tel" placeholder="0901 234 567" class="finput">
              </div>
            </div>
            <div class="form-group">
              <label>Địa Chỉ Giao Hàng</label>
              <input v-model="form.diaChi" type="text" placeholder="Số nhà, đường, quận, thành phố..." class="finput">
            </div>
            <div class="form-group">
              <label>Ghi Chú (không bắt buộc)</label>
              <textarea v-model="form.ghiChu" placeholder="VD: Không hành, nhiều sốt..." class="finput ftextarea"></textarea>
            </div>
          </div>

          <div class="form-section">
            <div class="form-section-title">💳 Phương Thức Thanh Toán</div>
            <div class="pay-methods">
              <div
                v-for="method in payMethods"
                :key="method.id"
                class="pay-card"
                :class="{ active: selectedPay === method.id }"
                @click="selectedPay = method.id"
              >
                <div class="pay-icon">{{ method.icon }}</div>
                <div class="pay-name">{{ method.name }}</div>
                <div class="pay-check" v-if="selectedPay === method.id">✓</div>
              </div>
            </div>

            <!-- [THÊM MỚI] Thông báo khi chọn QR -->
            <div v-if="selectedPay === 'qr'" class="qr-notice">
              <span>ℹ️</span>
              <span>Đơn sẽ lưu trạng thái <strong>Chờ Thanh Toán</strong>. Bạn có thể quay lại thanh toán sau trong "Đơn Hàng Của Tôi".</span>
            </div>
          </div>
        </div>

        <!-- Right: order summary -->
        <div class="order-summary">
          <div class="summary-card">
            <div class="summary-title">Đơn Hàng ({{ cart.totalItems }} món)</div>
            <div class="order-items">
              <div v-for="item in cart.items" :key="item.id" class="order-item">
                <span class="oi-name">{{ item.tenMon }}</span>
                <span class="oi-qty">×{{ item.soLuong }}</span>
                <span class="oi-price">{{ fmt(item.gia * item.soLuong) }}</span>
              </div>
            </div>
            <div class="sum-divider"></div>
            <div class="sum-row"><span>Tạm tính</span><span>{{ fmt(cart.subtotal) }}</span></div>
            <div class="sum-row discount" v-if="cart.discountAmount > 0">
              <span>Giảm giá</span><span>-{{ fmt(cart.discountAmount) }}</span>
            </div>
            <div class="sum-row"><span>VAT (8%)</span><span>{{ fmt(cart.vat) }}</span></div>
            <div class="sum-row"><span>Phí ship</span><span class="free">Miễn phí</span></div>
            <div class="sum-divider"></div>
            <div class="sum-total">
              <span>TỔNG</span>
              <span class="total-val">{{ fmt(cart.total) }}</span>
            </div>

            <button
              @click="submitOrder"
              class="btn-order"
              :disabled="submitting || cart.items.length === 0"
            >
              <!-- [SỬA] label nút đổi khi chọn QR -->
              {{ submitting ? '⏳ Đang Xử Lý...' : (selectedPay === 'qr' ? '📱 Tạo Đơn & Hiện QR' : '🎉 Đặt Hàng Ngay') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- ── Success overlay ── -->
    <div v-if="orderSuccess" class="success-overlay">
      <div class="success-card">
        <div class="success-icon">✅</div>
        <h2>Đặt Hàng Thành Công!</h2>
        <p>Mã đơn: <strong>#{{ orderId }}</strong></p>
        <p>Chúng tôi sẽ giao trong <strong>30 phút</strong>!</p>
        <div class="success-actions">
          <router-link to="/don-hang" class="btn-primary">Xem Đơn Hàng</router-link>
          <router-link to="/" class="btn-ghost">Về Trang Chủ</router-link>
        </div>
      </div>
    </div>

    <!-- ── QR Payment overlay ── -->
    <div v-if="showQR" class="success-overlay">
      <div class="success-card qr-card">
        <div class="success-icon">📱</div>
        <h2>Quét Mã QR Thanh Toán</h2>

        <p class="qr-label">Nội dung chuyển khoản:</p>
        <p class="qr-content"><strong>FASTFOOD HD{{ qrOrderId }}</strong></p>

        <div class="qr-img-wrap">
          <img :src="qrUrl" alt="QR Code" class="qr-img">
        </div>

        <!-- Đếm ngược timeout -->
        <div class="qr-timer" v-if="countdown > 0">
          <div class="timer-bar-wrap">
            <div class="timer-bar" :style="{ width: (countdown / 300 * 100) + '%' }"></div>
          </div>
          <span>Hết hạn sau {{ fmtCountdown(countdown) }}</span>
        </div>
        <div class="qr-timer expired" v-else>
          ⚠️ QR hết hạn — vào Đơn Hàng để tạo lại
        </div>

        <!-- Trạng thái polling -->
        <div class="qr-status">
          <div class="qr-pulse"></div>
          <span>Đang chờ xác nhận thanh toán...</span>
        </div>

        <p class="qr-bank-info">
          {{ bankName }} — {{ bankAccount }}<br>{{ accountName }}
        </p>

        <!-- [THÊM MỚI] Notice box -->
        <div class="qr-info-box">
          💡 Đơn đã lưu với trạng thái <strong>Chờ Thanh Toán</strong>. Bạn có thể thoát và quay lại thanh toán bất cứ lúc nào.
        </div>

        <div class="qr-actions">
          <!-- [SỬA] cancelQR → goToOrder, đổi text nút -->
          <button class="btn-qr-cancel" @click="goToOrder">
            📋 Vào Đơn Hàng Của Tôi
          </button>
          <button class="btn-qr-done" @click="markDone">
            ✅ Tôi Đã Chuyển Khoản
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useCartStore } from '../stores/cart'
import { useAuthStore } from '../stores/auth'
import { hoaDonAPI } from '../services/api'

const router = useRouter()
const cart   = useCartStore()
const auth   = useAuthStore()

// ── Form ──
const form        = ref({ hoTen: '', sdt: '', diaChi: '', ghiChu: '' })
const selectedPay = ref('tien_mat')
const submitting  = ref(false)
const orderSuccess = ref(false)
const orderId     = ref(null)

// ── QR ──
const showQR       = ref(false)
const qrOrderId    = ref(null)
const qrAmount     = ref(0)          // [THÊM MỚI] lưu số tiền thực để truyền vào QR
const countdown    = ref(300)
let pollingTimer   = null
let countdownTimer = null

// Thông tin ngân hàng
const bankAccount = '10002998539'
const bankName    = 'TPBank'
const accountName = 'TRUONG KIM LONG'

const payMethods = [
  { id: 'tien_mat', icon: '💵', name: 'Tiền Mặt' },
  { id: 'the',      icon: '💳', name: 'Thẻ Ngân Hàng' },
  { id: 'qr',       icon: '📱', name: 'QR / Ví Điện Tử' }
]

// [SỬA] qrUrl dùng số tiền thực thay vì 0
const qrUrl = computed(() => {
  if (!qrOrderId.value) return ''
  const content = encodeURIComponent(`FASTFOOD HD${qrOrderId.value}`)
  return `https://qr.sepay.vn/img?acc=${bankAccount}&bank=TPBank&amount=${qrAmount.value}&des=${content}&template=compact`
})

function fmt(n) { return Number(n || 0).toLocaleString('vi') + 'đ' }

function fmtCountdown(sec) {
  const m = Math.floor(sec / 60)
  const s = sec % 60
  return `${m}:${String(s).padStart(2, '0')}`
}

// ── Submit đơn hàng ──
async function submitOrder() {
  if (!form.value.diaChi.trim()) {
    alert('Vui lòng nhập địa chỉ giao hàng')
    return
  }
  submitting.value = true
  try {
    const payload = {
      ...cart.toOrderPayload(),
      phuongThucThanhToan: selectedPay.value,
      diaChi: form.value.diaChi,
      ghiChu: form.value.ghiChu,
      // [THÊM MỚI] QR → cho_thanh_toan (chưa xác nhận, chưa thanh toán)
      // Khác → cho_xac_nhan như bình thường
      trangThai: selectedPay.value === 'qr' ? 'cho_thanh_toan' : 'cho_xac_nhan',
    }
    const res        = await hoaDonAPI.create(payload)
    const newOrder   = res.data.data
    const newOrderId = newOrder.id
    cart.clearCart()

    if (selectedPay.value === 'qr') {
      qrOrderId.value = newOrderId
      qrAmount.value  = newOrder.tongTien   // [THÊM MỚI] lưu số tiền thực
      showQR.value    = true
      countdown.value = 300
      startPolling(newOrderId)
      startCountdown()
    } else {
      orderId.value      = newOrderId
      orderSuccess.value = true
    }
  } catch (e) {
    alert('Đặt hàng thất bại: ' + (e.response?.data?.message || e.message))
  } finally {
    submitting.value = false
  }
}

// ── Polling — chỉ check trangThai = hoan_thanh do BE SePay webhook set ──
function startPolling(id) {
  pollingTimer = setInterval(async () => {
    try {
      const r = await hoaDonAPI.getById(id)
      const hd = r.data.data
      if (hd.trangThai === 'hoan_thanh') {
        stopTimers()
        showQR.value       = false
        orderId.value      = id
        orderSuccess.value = true
      }
    } catch (e) {
      console.error('Polling error:', e)
    }
  }, 3000)
}

// ── Đếm ngược 5 phút ──
function startCountdown() {
  countdownTimer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) {
      // [SỬA] Chỉ dừng đếm, KHÔNG đóng QR, KHÔNG auto-complete
      clearInterval(countdownTimer)
      countdownTimer = null
    }
  }, 1000)
}

function stopTimers() {
  if (pollingTimer)   { clearInterval(pollingTimer);   pollingTimer = null }
  if (countdownTimer) { clearInterval(countdownTimer); countdownTimer = null }
}

// [SỬA] goToOrder thay cancelQR — đơn đã ở trạng thái cho_thanh_toan, vào xem chi tiết
function goToOrder() {
  stopTimers()
  showQR.value = false
  router.push('/don-hang/')
}

// User tự xác nhận đã CK — BE SePay webhook mới là nguồn sự thật
// Hàm này chỉ hiện success UI, không thay đổi trạng thái BE
async function markDone() {
  stopTimers()
  showQR.value = false
  try {
    await hoaDonAPI.xacNhanThanhToan(qrOrderId.value)
  } catch (e) {
    console.error('markDone error:', e)
  }
  orderId.value      = qrOrderId.value
  orderSuccess.value = true
}

onUnmounted(stopTimers)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');

.page { min-height:100vh;background:#0e0a0a;color:#f5ede6;padding:100px 0 60px;position:relative;font-family:'Nunito',sans-serif; }
.grain { position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px }
.container { max-width:1100px;margin:0 auto;padding:0 24px;position:relative }
.page-label { font-size:.72rem;font-weight:900;letter-spacing:.25em;text-transform:uppercase;color:#e8273a;margin-bottom:8px }
.page-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(2rem,5vw,3rem);letter-spacing:.04em;color:#fff;margin-bottom:32px }
.page-title span { color:#ffcc00 }

/* Layout */
.checkout-layout { display:grid;grid-template-columns:1fr 360px;gap:24px;align-items:start }
@media(max-width:860px){.checkout-layout{grid-template-columns:1fr}}

/* Form */
.form-section { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:22px;margin-bottom:16px }
.form-section-title { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.08em;color:#fff;margin-bottom:18px }
.form-row { display:grid;grid-template-columns:1fr 1fr;gap:14px }
.form-group { display:flex;flex-direction:column;gap:6px;margin-bottom:14px }
.form-group label { font-size:.7rem;font-weight:900;letter-spacing:.15em;text-transform:uppercase;color:rgba(245,237,230,.5) }
.finput { background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:11px;padding:11px 14px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.9rem;font-weight:600;outline:none;transition:border-color .2s }
.finput:focus { border-color:rgba(232,39,58,.4) }
.ftextarea { resize:vertical;min-height:70px }

/* Pay methods */
.pay-methods { display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:12px }
.pay-card { padding:14px 10px;border-radius:12px;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);cursor:pointer;text-align:center;transition:all .2s;position:relative }
.pay-card:hover,.pay-card.active { background:rgba(232,39,58,.1);border-color:rgba(232,39,58,.3) }
.pay-icon { font-size:1.5rem;margin-bottom:5px }
.pay-name { font-size:.72rem;font-weight:800;color:rgba(245,237,230,.7) }
.pay-check { position:absolute;top:8px;right:8px;width:16px;height:16px;background:#e8273a;border-radius:50%;font-size:.6rem;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:900 }

/* [THÊM MỚI] QR notice */
.qr-notice { background:rgba(255,204,0,.07);border:1px solid rgba(255,204,0,.2);border-radius:10px;padding:10px 13px;font-size:.78rem;font-weight:600;color:rgba(255,204,0,.8);display:flex;align-items:flex-start;gap:8px;line-height:1.5 }
.qr-notice strong { color:#ffcc00 }

/* Summary */
.summary-card { background:rgba(10,6,6,.97);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:20px }
.summary-title { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.08em;color:#fff;margin-bottom:14px }
.order-items { margin-bottom:12px }
.order-item { display:flex;align-items:center;gap:6px;font-size:.8rem;padding:5px 0;border-bottom:1px solid rgba(255,255,255,.04) }
.oi-name { flex:1;font-weight:700;color:#f5ede6 }
.oi-qty { color:rgba(245,237,230,.5);font-weight:600 }
.oi-price { font-family:'Bebas Neue',sans-serif;font-size:.9rem;color:#fff }
.sum-divider { height:1px;background:rgba(255,255,255,.08);margin:10px 0 }
.sum-row { display:flex;justify-content:space-between;font-size:.8rem;font-weight:700;color:rgba(245,237,230,.6);margin-bottom:6px }
.sum-row.discount { color:#e8273a }
.free { color:#4ade80 }
.sum-total { display:flex;justify-content:space-between;align-items:center;margin-bottom:16px }
.sum-total span:first-child { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.1em;color:#fff }
.total-val { font-family:'Bebas Neue',sans-serif;font-size:1.5rem;letter-spacing:.04em;color:#ffcc00 }
.btn-order { width:100%;padding:13px;background:#e8273a;border:none;border-radius:11px;font-family:'Bebas Neue',sans-serif;font-size:1.15rem;letter-spacing:.1em;color:#fff;cursor:pointer;transition:all .2s;box-shadow:0 5px 16px rgba(232,39,58,.45) }
.btn-order:hover:not(:disabled) { background:#b8001a;transform:translateY(-2px) }
.btn-order:disabled { opacity:.4;cursor:not-allowed }

/* Overlay chung */
.success-overlay { position:fixed;inset:0;background:rgba(0,0,0,.82);backdrop-filter:blur(10px);z-index:999;display:flex;align-items:center;justify-content:center;padding:16px }
.success-card { background:#0d0707;border:1px solid rgba(74,222,128,.25);border-radius:22px;padding:36px 28px;text-align:center;max-width:420px;width:100%;max-height:90vh;overflow-y:auto }
.success-icon { font-size:3.5rem;margin-bottom:14px }
.success-card h2 { font-family:'Bebas Neue',sans-serif;font-size:1.9rem;letter-spacing:.06em;color:#fff;margin-bottom:12px }
.success-card p { font-size:.9rem;color:rgba(245,237,230,.7);font-weight:600;margin-bottom:6px }
.success-card strong { color:#ffcc00 }
.success-actions { display:flex;gap:10px;margin-top:22px;justify-content:center }
.btn-primary { padding:12px 24px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;color:#fff;text-decoration:none;transition:all .2s }
.btn-ghost { padding:12px 24px;background:transparent;border:2px solid rgba(255,255,255,.2);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:900;color:#f5ede6;text-decoration:none;transition:all .2s }

/* QR card */
.qr-card { border-color:rgba(255,204,0,.2) }
.qr-label { font-size:.78rem;font-weight:700;color:rgba(245,237,230,.5);margin-bottom:4px }
.qr-content { font-family:'Bebas Neue',sans-serif;font-size:1.3rem;letter-spacing:.08em;color:#ffcc00;margin-bottom:14px }
.qr-img-wrap { background:#fff;border-radius:14px;padding:10px;display:inline-block;margin-bottom:14px }
.qr-img { width:200px;height:200px;display:block }

/* Timer */
.qr-timer { margin-bottom:12px }
.qr-timer span { font-size:.75rem;font-weight:700;color:rgba(245,237,230,.4);display:block;margin-top:5px }
.qr-timer.expired span { color:#f87171 }
.timer-bar-wrap { height:4px;background:rgba(255,255,255,.08);border-radius:2px;overflow:hidden }
.timer-bar { height:100%;background:linear-gradient(90deg,#e8273a,#ffcc00);border-radius:2px;transition:width 1s linear }

/* Status pulse */
.qr-status { display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:10px;font-size:.78rem;color:rgba(255,255,255,.4);font-weight:600 }
.qr-pulse { width:8px;height:8px;border-radius:50%;background:#ffcc00;animation:pulse-dot 1.2s ease-in-out infinite }
@keyframes pulse-dot { 0%,100%{opacity:1;transform:scale(1)}50%{opacity:.3;transform:scale(.7)} }

.qr-bank-info { font-size:.74rem;color:rgba(245,237,230,.3);font-weight:600;margin-bottom:12px;line-height:1.6 }

/* [THÊM MỚI] Info box */
.qr-info-box { background:rgba(255,204,0,.06);border:1px solid rgba(255,204,0,.15);border-radius:10px;padding:10px 13px;font-size:.74rem;font-weight:600;color:rgba(255,204,0,.7);line-height:1.55;margin-bottom:14px;text-align:left }
.qr-info-box strong { color:#ffcc00 }

/* QR actions */
.qr-actions { display:flex;flex-direction:column;gap:8px;width:100% }
.btn-qr-cancel { width:100%;padding:11px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.12);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:rgba(245,237,230,.6);cursor:pointer;transition:all .2s }
.btn-qr-cancel:hover { background:rgba(255,255,255,.1);color:#f5ede6 }
.btn-qr-done { width:100%;padding:11px;background:rgba(74,222,128,.15);border:1px solid rgba(74,222,128,.3);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#4ade80;cursor:pointer;transition:all .2s }
.btn-qr-done:hover { background:rgba(74,222,128,.25) }
</style>