<template>
  <div class="page">
    <div class="grain"></div>
    <div class="container">

      <!-- Back -->
      <router-link to="/don-hang" class="back-link">← Quay lại đơn hàng</router-link>

      <!-- Loading -->
      <div v-if="loading" class="skeleton-wrap">
        <div class="skeleton-block"></div>
        <div class="skeleton-block short"></div>
      </div>

      <!-- Not found -->
      <div v-else-if="!order" class="empty-state">
        <div class="empty-icon">📋</div>
        <p>Không tìm thấy đơn hàng</p>
        <router-link to="/don-hang" class="btn-back">← Về danh sách</router-link>
      </div>

      <template v-else>
        <!-- Header -->
        <div class="order-header">
          <div>
            <div class="page-label">Chi Tiết Đơn Hàng</div>
            <h1 class="page-title">#{{ String(order.id).padStart(4,'0') }}</h1>
          </div>
          <div :class="['status-badge', statusClass(order.trangThai)]">
            {{ statusLabel(order.trangThai) }}
          </div>
        </div>

        <!-- [THÊM MỚI] Banner chờ thanh toán QR -->
        <div v-if="order.trangThai === 'cho_thanh_toan'" class="qr-pending-banner">
          <div class="qr-pending-left">
            <div class="qr-pending-icon">💳</div>
            <div>
              <div class="qr-pending-title">Đơn Chưa Được Thanh Toán</div>
              <div class="qr-pending-sub">
                Nhấn "Thanh Toán QR" để hoàn tất. Bạn cũng có thể sửa địa chỉ/ghi chú trước khi thanh toán.
              </div>
            </div>
          </div>
          <button class="btn-pay-qr" @click="openQR">
            📱 Thanh Toán QR
          </button>
        </div>
<!-- Thêm trước timeline -->
<div v-if="order.trangThai === 'cho_thanh_toan'" class="payment-banner">
  <div class="pb-icon">💳</div>
  <div class="pb-text">
    <div class="pb-title">Đơn Chờ Thanh Toán</div>
    <div class="pb-sub">Hoàn tất QR để tiến hành giao hàng.</div>
  </div>
  <button class="pb-btn" @click="goToPayment">Thanh Toán →</button>
</div>

<!-- Ẩn timeline nếu cho_thanh_toan -->
<div class="timeline" v-if="order.trangThai !== 'cho_thanh_toan'">
  ...
</div>
        <!-- Timeline trạng thái (ẩn khi cho_thanh_toan) -->
        <div class="timeline" v-if="order.trangThai !== 'cho_thanh_toan'">
          <div
            v-for="(step, i) in timeline"
            :key="i"
            :class="['step', stepStatus(step.value, order.trangThai)]"
          >
            <div class="step-dot">{{ step.icon }}</div>
            <div class="step-line" v-if="i < timeline.length - 1"></div>
            <div class="step-label">{{ step.label }}</div>
          </div>
        </div>

        <!-- Info grid -->
        <div class="info-grid">
          <!-- Card 1: Thông tin đơn (luôn hiện) -->
          <div class="info-card">
            <div class="info-title">Thông Tin Đơn</div>
            <div class="info-row"><span>Mã đơn</span><span>#{{ String(order.id).padStart(4,'0') }}</span></div>
            <div class="info-row"><span>Ngày đặt</span><span>{{ fmtDate(order.ngayLap) }}</span></div>
            <div class="info-row" v-if="order.khuyenMai">
              <span>Khuyến mãi</span>
              <span class="yellow">{{ order.khuyenMai.tenKhuyenMai }} (-{{ order.khuyenMai.phanTramGiam }}%)</span>
            </div>
            <div class="info-row"><span>Địa chỉ</span><span>{{ order.diaChi || '—' }}</span></div>
            <div class="info-row"><span>Ghi chú</span><span>{{ order.ghiChu || '—' }}</span></div>
            <div class="info-row">
              <span>Thanh toán</span>
              <span>{{ payLabel(order.phuongThucThanhToan) }}</span>
            </div>
            <!-- [SỬA] daTT: chỉ true khi hoan_thanh (webhook BE set) -->
            <div class="info-row">
              <span>Trạng thái TT</span>
              <span :style="{ color: daTT ? '#4ade80' : '#fb923c' }">
                {{ daTT ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán' }}
              </span>
            </div>
          </div>

          <!-- Card 2: Admin/NV cập nhật trạng thái -->
          <div class="info-card" v-if="auth.isAdmin || auth.isNhanVien">
            <div class="info-title">Cập Nhật Trạng Thái</div>
            <select v-model="newStatus" class="status-select">
              <!-- [THÊM MỚI] thêm option cho_thanh_toan -->
              <option value="cho_thanh_toan">💳 Chờ Thanh Toán</option>
              <option value="cho_xac_nhan">⏳ Chờ Xác Nhận</option>
              <option value="dang_chuan_bi">👨‍🍳 Đang Chuẩn Bị</option>
              <option value="dang_giao">🛵 Đang Giao</option>
              <option value="hoan_thanh">✅ Hoàn Thành</option>
              <option value="da_huy">❌ Đã Huỷ</option>
            </select>
            <button class="btn-update" @click="updateStatus"
              :disabled="updating || newStatus === order.trangThai">
              {{ updating ? '⏳ Đang cập nhật...' : '✅ Cập Nhật' }}
            </button>
          </div>

          <!-- Card 2: Khách hàng — cho_thanh_toan: sửa địa chỉ/ghi chú + hủy -->
          <div class="info-card" v-else-if="order.trangThai === 'cho_thanh_toan'">
            <div class="info-title">Chỉnh Sửa Đơn</div>
            <p class="edit-hint">Đơn chưa thanh toán, bạn có thể sửa địa chỉ và ghi chú.</p>
            <div class="form-group-inline">
              <label>Địa Chỉ</label>
              <input v-model="editForm.diaChi" class="finput-sm" placeholder="Địa chỉ giao hàng">
            </div>
            <div class="form-group-inline">
              <label>Ghi Chú</label>
              <textarea v-model="editForm.ghiChu" class="finput-sm ftextarea-sm" placeholder="Ghi chú..."></textarea>
            </div>
            <div class="edit-actions">
              <button class="btn-save-edit" @click="saveEdit" :disabled="updating">
                {{ updating ? '⏳...' : '💾 Lưu' }}
              </button>
              <button class="btn-cancel-order" @click="cancelOrder" :disabled="updating">
                ❌ Hủy Đơn
              </button>
            </div>
          </div>

          <!-- Card 2: Khách hàng — cho_xac_nhan: chỉ hủy -->
          <div class="info-card" v-else-if="order.trangThai === 'cho_xac_nhan'">
            <div class="info-title">Hành Động</div>
            <p class="cancel-hint">Bạn có thể hủy đơn khi đơn chưa được xác nhận.</p>
            <button class="btn-cancel-order" @click="cancelOrder" :disabled="updating">
              {{ updating ? '⏳...' : '❌ Hủy Đơn Hàng' }}
            </button>
          </div>
        </div>

        <!-- Chi tiết món -->
        <div class="items-section">
          <div class="section-title">Món Đã Đặt</div>
          <div class="items-list">
            <div v-for="ct in order.chiTietHoaDons" :key="ct.id" class="item-row">
              <img
                v-if="ct.monAn?.hinhAnh"
                :src="ct.monAn.hinhAnh"
                class="item-img"
                @error="e => e.target.style.display='none'"
              >
              <div v-else class="item-img-ph">🍔</div>
              <div class="item-info">
                <div class="item-name">{{ ct.monAn?.tenMon }}</div>
                <div class="item-price-unit">{{ fmt(ct.donGia) }} / món</div>
              </div>
              <div class="item-qty">×{{ ct.soLuong }}</div>
              <div class="item-subtotal">{{ fmt(ct.donGia * ct.soLuong) }}</div>
            </div>
          </div>
          <div class="total-section">
            <div class="total-row"><span>Tổng cộng</span><span class="yellow">{{ fmt(order.tongTien) }}</span></div>
          </div>
        </div>
      </template>
    </div>

    <!-- [THÊM MỚI] QR Modal cho đơn cho_thanh_toan -->
    <div v-if="showQR" class="overlay" @click.self="closeQR">
      <div class="qr-modal">
        <div class="qr-modal-head">
          <div class="qr-title">Thanh Toán <span>QR</span></div>
          <div class="qr-badge">#{{ String(order?.id).padStart(4,'0') }}</div>
        </div>

        <div class="ck-info">
          <div class="ck-row"><span>Ngân hàng</span><strong>{{ bankName }}</strong></div>
          <div class="ck-row"><span>Số TK</span><strong>{{ bankAccount }}</strong></div>
          <div class="ck-row"><span>Chủ TK</span><strong>{{ accountName }}</strong></div>
          <div class="ck-row hl">
            <span>Nội dung CK</span>
            <strong class="ck-code">FASTFOOD HD{{ order?.id }}</strong>
          </div>
          <div class="ck-row hl">
            <span>Số tiền</span>
            <strong class="ck-amt">{{ fmt(order?.tongTien) }}</strong>
          </div>
        </div>

        <div class="qr-img-wrap">
          <img :src="qrModalUrl" alt="QR Code" class="qr-img">
        </div>

        <div class="qr-timer" :class="{ expired: qrCountdown <= 0 }">
          <div class="timer-track"><div class="timer-fill" :style="{ width: (qrCountdown/300*100)+'%' }"></div></div>
          <span v-if="qrCountdown > 0">⏱ Hết hạn sau {{ fmtCD(qrCountdown) }}</span>
          <span v-else>⚠️ QR hết hạn</span>
        </div>

        <div class="qr-poll">
          <div class="pulse-dot"></div>
          <span>Đang chờ xác nhận từ ngân hàng...</span>
        </div>

        <div class="qr-actions-modal">
          <button class="btn-qr-refresh" v-if="qrCountdown <= 0" @click="refreshQR">🔄 Làm Mới QR</button>
          <button class="btn-qr-close" @click="closeQR">Đóng</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { hoaDonAPI } from '../services/api'

const route  = useRoute()
const router = useRouter()
const auth   = useAuthStore()

const order     = ref(null)
const loading   = ref(true)
const newStatus = ref('')
const updating  = ref(false)

// [THÊM MỚI] edit form cho đơn cho_thanh_toan
const editForm = ref({ diaChi: '', ghiChu: '' })

// [THÊM MỚI] QR modal state
const showQR       = ref(false)
const qrCountdown  = ref(300)
let qrPollingTimer   = null
let qrCountdownTimer = null

const bankAccount = '10002998539'
const bankName    = 'TPBank'
const accountName = 'TRUONG KIM LONG'

const timeline = [
  { value: 'cho_xac_nhan',  icon: '⏳', label: 'Chờ Xác Nhận' },
  { value: 'dang_chuan_bi', icon: '👨‍🍳', label: 'Đang Chuẩn Bị' },
  { value: 'dang_giao',     icon: '🛵', label: 'Đang Giao' },
  { value: 'hoan_thanh',    icon: '✅', label: 'Hoàn Thành' },
]

// [SỬA] daTT: chỉ true khi hoan_thanh — BE SePay webhook là nguồn sự thật
// Không dùng pttt === 'qr' để tự suy ra "đã TT" nữa
const daTT = computed(() => {
  if (!order.value) return false
  return order.value.trangThai === 'hoan_thanh'
})

// [THÊM MỚI] QR URL cho modal
const qrModalUrl = computed(() => {
  if (!order.value) return ''
  const des = encodeURIComponent(`FASTFOOD HD${order.value.id}`)
  return `https://qr.sepay.vn/img?acc=${bankAccount}&bank=TPBank&amount=${order.value.tongTien}&des=${des}&template=compact`
})

const statusOrder = [,'cho_thanh_toan','cho_xac_nhan','dang_chuan_bi','dang_giao','hoan_thanh']
function goToPayment() {
  router.push('/thanh-toan?orderId=' + order.value.id)
}
function stepStatus(stepVal, currentVal) {
  if (currentVal === 'da_huy') return stepVal === 'cho_xac_nhan' ? 'done' : 'inactive'
  const si = statusOrder.indexOf(stepVal)
  const ci = statusOrder.indexOf(currentVal)
  if (si < ci)  return 'done'
  if (si === ci) return 'active'
  return 'inactive'
}
function payLabel(p) {
  return { tien_mat:'💵 Tiền Mặt', the:'💳 Thẻ Ngân Hàng', qr:'📱 QR / Ví Điện Tử' }[p] || p || '—'
}
function statusLabel(s) {
  return {
    // [THÊM MỚI]
    cho_thanh_toan: '💳 Chờ Thanh Toán',
    cho_xac_nhan:   '⏳ Chờ Xác Nhận',
    dang_chuan_bi:  '👨‍🍳 Đang Chuẩn Bị',
    dang_giao:      '🛵 Đang Giao',
    hoan_thanh:     '✅ Hoàn Thành',
    da_huy:         '❌ Đã Huỷ'
  }[s] || s
}
function statusClass(s) {
  return {
    // [THÊM MỚI]
    cho_thanh_toan: 'awaiting-pay',
    cho_xac_nhan:   'pending',
    dang_chuan_bi:  'preparing',
    dang_giao:      'delivering',
    hoan_thanh:     'done',
    da_huy:         'cancelled'
  }[s] || 'pending'
}
function fmt(n)     { return Number(n||0).toLocaleString('vi') + 'đ' }
function fmtDate(d) { return d ? new Date(d).toLocaleString('vi', { day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit' }) : '—' }
function fmtCD(s)   { return `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}` }

async function updateStatus() {
  updating.value = true
  try {
    await hoaDonAPI.updateStatus(order.value.id, newStatus.value)
    const res = await hoaDonAPI.getById(order.value.id)
    order.value = res.data.data
    newStatus.value = order.value.trangThai
  } catch (e) { console.error(e) }
  finally { updating.value = false }
}

async function cancelOrder() {
  if (!confirm('Bạn chắc chắn muốn hủy đơn hàng này?')) return
  updating.value = true
  try {
    await hoaDonAPI.updateStatus(order.value.id, 'da_huy')
    const res = await hoaDonAPI.getById(route.params.id)
    order.value = res.data.data
    newStatus.value = order.value.trangThai
  } catch (e) { console.error(e) }
  finally { updating.value = false }
}

// [THÊM MỚI] Lưu chỉnh sửa địa chỉ / ghi chú
async function saveEdit() {
  updating.value = true
  try {
    await hoaDonAPI.update(order.value.id, {
      diaChi: editForm.value.diaChi,
      ghiChu: editForm.value.ghiChu,
    })
    const res = await hoaDonAPI.getById(route.params.id)
    order.value = res.data.data
    newStatus.value = order.value.trangThai
  } catch (e) { console.error(e) }
  finally { updating.value = false }
}

// [THÊM MỚI] Mở QR modal + polling
function openQR() {
  showQR.value     = true
  qrCountdown.value = 300
  startQRPolling()
  startQRCountdown()
}
function closeQR() {
  showQR.value = false
  stopQRTimers()
}
function refreshQR() {
  qrCountdown.value = 300
  startQRCountdown()
  startQRPolling()
}
function startQRPolling() {
  if (qrPollingTimer) { clearInterval(qrPollingTimer); qrPollingTimer = null }
  qrPollingTimer = setInterval(async () => {
    try {
      const r  = await hoaDonAPI.getById(order.value.id)
      const hd = r.data.data
      if (hd.trangThai === 'hoan_thanh') {
        stopQRTimers()
        showQR.value    = false
        order.value     = hd
        newStatus.value = hd.trangThai
      }
    } catch {}
  }, 3000)
}
function startQRCountdown() {
  if (qrCountdownTimer) { clearInterval(qrCountdownTimer); qrCountdownTimer = null }
  qrCountdownTimer = setInterval(() => {
    if (--qrCountdown.value <= 0) {
      clearInterval(qrCountdownTimer); qrCountdownTimer = null
      if (qrPollingTimer) { clearInterval(qrPollingTimer); qrPollingTimer = null }
    }
  }, 1000)
}
function stopQRTimers() {
  if (qrPollingTimer)   { clearInterval(qrPollingTimer);   qrPollingTimer   = null }
  if (qrCountdownTimer) { clearInterval(qrCountdownTimer); qrCountdownTimer = null }
}

onMounted(async () => {
  try {
    const res = await hoaDonAPI.getById(route.params.id)
    order.value = res.data.data
    newStatus.value = order.value.trangThai
    // [THÊM MỚI] pre-fill edit form
    editForm.value = { diaChi: order.value.diaChi || '', ghiChu: order.value.ghiChu || '' }
  } catch { order.value = null }
  finally { loading.value = false }
})
onUnmounted(stopQRTimers)
</script>

<style scoped>
.payment-banner {
  display:flex;align-items:center;gap:14px;
  background:rgba(99,102,241,.1);border:1px solid rgba(99,102,241,.25);
  border-radius:14px;padding:16px 20px;margin-bottom:24px;
}
.pb-icon { font-size:2rem; }
.pb-title { font-weight:900;color:#818cf8;margin-bottom:3px; }
.pb-sub { font-size:.78rem;color:rgba(245,237,230,.5);font-weight:600; }
.pb-btn {
  margin-left:auto;padding:9px 18px;
  background:#6366f1;border:none;border-radius:9px;
  font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:900;
  color:#fff;cursor:pointer;white-space:nowrap;
}
/* ── Giữ nguyên toàn bộ style cũ ── */
.cancel-hint { font-size:.78rem;font-weight:600;color:rgba(245,237,230,.4);margin-bottom:12px;line-height:1.5; }
.btn-cancel-order { width:100%;padding:10px;background:rgba(248,113,113,.15);border:1px solid rgba(248,113,113,.3);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:900;color:#f87171;cursor:pointer;transition:all .2s; }
.btn-cancel-order:hover:not(:disabled) { background:rgba(248,113,113,.25); }
.btn-cancel-order:disabled { opacity:.4;cursor:not-allowed; }
.page { min-height:100vh;background:#0e0a0a;color:#f5ede6;padding:100px 0 60px;position:relative }
.grain { position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px }
.container { max-width:800px;margin:0 auto;padding:0 24px;position:relative }
.back-link { display:inline-flex;align-items:center;gap:6px;font-size:.8rem;font-weight:800;color:rgba(245,237,230,.4);text-decoration:none;margin-bottom:24px;transition:color .2s }
.back-link:hover { color:#e8273a }
.page-label { font-size:.72rem;font-weight:900;letter-spacing:.25em;text-transform:uppercase;color:#e8273a;margin-bottom:6px }
.page-title { font-family:'Bebas Neue',sans-serif;font-size:clamp(2rem,5vw,3rem);letter-spacing:.04em;color:#fff }
.order-header { display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px }
.status-badge { padding:6px 16px;border-radius:50px;font-size:.75rem;font-weight:900;letter-spacing:.06em;text-transform:uppercase }
/* [THÊM MỚI] badge màu vàng */
.status-badge.awaiting-pay { background:rgba(255,204,0,.15);color:#ffcc00;border:1px solid rgba(255,204,0,.3) }
.status-badge.pending    { background:rgba(251,146,60,.12);color:#fb923c;border:1px solid rgba(251,146,60,.2) }
.status-badge.preparing  { background:rgba(96,165,250,.12);color:#60a5fa;border:1px solid rgba(96,165,250,.2) }
.status-badge.delivering { background:rgba(167,139,250,.12);color:#a78bfa;border:1px solid rgba(167,139,250,.2) }
.status-badge.done       { background:rgba(74,222,128,.12);color:#4ade80;border:1px solid rgba(74,222,128,.2) }
.status-badge.cancelled  { background:rgba(248,113,113,.1);color:#f87171;border:1px solid rgba(248,113,113,.2) }

/* [THÊM MỚI] QR Pending Banner */
.qr-pending-banner { background:rgba(255,204,0,.07);border:1px solid rgba(255,204,0,.25);border-radius:16px;padding:18px 20px;display:flex;align-items:center;justify-content:space-between;gap:16px;margin-bottom:22px;flex-wrap:wrap }
.qr-pending-left { display:flex;align-items:center;gap:14px }
.qr-pending-icon { font-size:2rem }
.qr-pending-title { font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.06em;color:#ffcc00;margin-bottom:3px }
.qr-pending-sub { font-size:.76rem;font-weight:600;color:rgba(255,204,0,.6);max-width:340px;line-height:1.5 }
.btn-pay-qr { padding:12px 22px;background:#ffcc00;border:none;border-radius:50px;font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.08em;color:#0e0a0a;cursor:pointer;transition:all .2s;box-shadow:0 5px 16px rgba(255,204,0,.35);white-space:nowrap;flex-shrink:0 }
.btn-pay-qr:hover { background:#e6b800;transform:translateY(-2px) }

/* Timeline */
.timeline { display:flex;align-items:flex-start;gap:0;margin-bottom:28px;overflow-x:auto;padding-bottom:4px }
.step { display:flex;flex-direction:column;align-items:center;position:relative;flex:1;min-width:70px }
.step-dot { width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:1rem;border:2px solid rgba(255,255,255,.1);background:rgba(255,255,255,.04);margin-bottom:6px;transition:all .3s;flex-shrink:0 }
.step.active .step-dot  { border-color:#e8273a;background:rgba(232,39,58,.15);box-shadow:0 0 12px rgba(232,39,58,.3) }
.step.done .step-dot    { border-color:#4ade80;background:rgba(74,222,128,.1) }
.step.inactive .step-dot{ opacity:.3 }
.step-line { position:absolute;top:18px;left:calc(50% + 18px);right:calc(-50% + 18px);height:2px;background:rgba(255,255,255,.08) }
.step.done .step-line   { background:#4ade80 }
.step-label { font-size:.62rem;font-weight:800;letter-spacing:.06em;text-transform:uppercase;color:rgba(245,237,230,.4);text-align:center;line-height:1.3 }
.step.active .step-label { color:#e8273a }
.step.done .step-label  { color:#4ade80 }

/* Info grid */
.info-grid { display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:24px }
.info-card { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:18px 20px }
.info-title { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.08em;color:rgba(245,237,230,.5);margin-bottom:14px }
.info-row { display:flex;justify-content:space-between;align-items:center;font-size:.82rem;font-weight:700;margin-bottom:10px;color:rgba(245,237,230,.6) }
.info-row span:last-child { color:#f5ede6 }
.yellow { color:#ffcc00 !important }
.status-select { width:100%;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:10px;padding:10px 12px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:700;outline:none;margin-bottom:10px;transition:border-color .2s }
.status-select:focus { border-color:rgba(232,39,58,.4) }
.status-select option { background:#130a0a }
.btn-update { width:100%;padding:10px;background:#e8273a;border:none;border-radius:10px;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:900;color:#fff;cursor:pointer;transition:all .2s }
.btn-update:hover:not(:disabled) { background:#b8001a }
.btn-update:disabled { opacity:.4;cursor:not-allowed }

/* [THÊM MỚI] edit form inline */
.edit-hint { font-size:.76rem;font-weight:600;color:rgba(245,237,230,.4);margin-bottom:12px;line-height:1.5 }
.form-group-inline { display:flex;flex-direction:column;gap:4px;margin-bottom:10px }
.form-group-inline label { font-size:.64rem;font-weight:900;letter-spacing:.12em;text-transform:uppercase;color:rgba(245,237,230,.4) }
.finput-sm { background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:9px;padding:8px 11px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:600;outline:none;transition:border-color .2s;width:100% }
.finput-sm:focus { border-color:rgba(232,39,58,.4) }
.ftextarea-sm { resize:vertical;min-height:50px }
.edit-actions { display:flex;gap:7px;margin-top:4px }
.btn-save-edit { flex:1;padding:9px;background:#e8273a;border:none;border-radius:9px;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:900;color:#fff;cursor:pointer;transition:all .2s }
.btn-save-edit:hover:not(:disabled) { background:#b8001a }
.btn-save-edit:disabled { opacity:.4;cursor:not-allowed }

/* Items */
.items-section { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:20px;margin-bottom:20px }
.section-title { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.08em;color:rgba(245,237,230,.5);margin-bottom:16px }
.items-list { display:flex;flex-direction:column;gap:2px }
.item-row { display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05) }
.item-row:last-child { border-bottom:none }
.item-img { width:44px;height:44px;border-radius:9px;object-fit:cover;flex-shrink:0 }
.item-img-ph { width:44px;height:44px;border-radius:9px;background:rgba(255,255,255,.05);display:flex;align-items:center;justify-content:center;font-size:1.3rem;flex-shrink:0 }
.item-info { flex:1 }
.item-name { font-weight:800;font-size:.86rem;color:#f5ede6;margin-bottom:2px }
.item-price-unit { font-size:.72rem;color:rgba(245,237,230,.4);font-weight:600 }
.item-qty { font-size:.82rem;font-weight:800;color:rgba(245,237,230,.5);min-width:30px;text-align:center }
.item-subtotal { font-family:'Bebas Neue',sans-serif;font-size:1rem;color:#ffcc00;min-width:80px;text-align:right }
.total-section { border-top:1px solid rgba(255,255,255,.08);padding-top:14px;margin-top:4px }
.total-row { display:flex;justify-content:space-between;align-items:center }
.total-row span:first-child { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.08em;color:rgba(245,237,230,.5) }
.total-row .yellow { font-family:'Bebas Neue',sans-serif;font-size:1.5rem;letter-spacing:.04em }

/* Skeleton */
.skeleton-wrap { margin-top:20px }
.skeleton-block { background:rgba(255,255,255,.04);border-radius:16px;height:180px;margin-bottom:14px;animation:pulse 1.5s ease-in-out infinite }
.skeleton-block.short { height:100px }
@keyframes pulse { 0%,100%{opacity:.4}50%{opacity:.7} }
.empty-state { text-align:center;padding:80px 20px }
.empty-icon { font-size:4rem;margin-bottom:16px;opacity:.3 }
.empty-state p { color:rgba(245,237,230,.5);font-weight:600;margin-bottom:20px }
.btn-back { display:inline-block;padding:10px 24px;background:#e8273a;border-radius:50px;font-weight:900;color:#fff;text-decoration:none }

/* [THÊM MỚI] QR Modal overlay */
.overlay { position:fixed;inset:0;background:rgba(0,0,0,.82);backdrop-filter:blur(10px);z-index:900;display:flex;align-items:center;justify-content:center;padding:16px }
.qr-modal { background:#0d0707;border:1px solid rgba(255,204,0,.22);border-radius:22px;padding:26px 22px;max-width:420px;width:100%;max-height:90vh;overflow-y:auto }
.qr-modal::-webkit-scrollbar { width:3px }
.qr-modal::-webkit-scrollbar-thumb { background:rgba(255,255,255,.08) }
.qr-modal-head { display:flex;align-items:center;justify-content:space-between;margin-bottom:16px }
.qr-title { font-family:'Bebas Neue',sans-serif;font-size:1.35rem;letter-spacing:.06em;color:#fff }
.qr-title span { color:#ffcc00 }
.qr-badge { background:rgba(255,204,0,.1);border:1px solid rgba(255,204,0,.25);border-radius:50px;padding:3px 12px;font-family:'Bebas Neue',sans-serif;font-size:.9rem;letter-spacing:.08em;color:#ffcc00 }
.ck-info { background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:12px 15px;margin-bottom:14px }
.ck-row { display:flex;justify-content:space-between;align-items:center;font-size:.76rem;padding:5px 0;border-bottom:1px solid rgba(255,255,255,.05) }
.ck-row:last-child { border-bottom:none }
.ck-row span { font-weight:600;color:rgba(245,237,230,.45) }
.ck-row strong { font-weight:800;color:#f5ede6 }
.ck-row.hl { margin-top:4px;padding-top:8px;border-top:1px dashed rgba(255,255,255,.08);border-bottom:none }
.ck-code { color:#ffcc00;letter-spacing:.06em;font-family:'Bebas Neue',sans-serif;font-size:1rem }
.ck-amt { color:#4ade80;font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.04em }
.qr-img-wrap { background:#fff;border-radius:12px;padding:10px;display:flex;align-items:center;justify-content:center;margin-bottom:12px }
.qr-img { width:185px;height:185px;display:block }
.qr-timer { margin-bottom:10px }
.qr-timer span { font-size:.72rem;font-weight:700;color:rgba(245,237,230,.4);display:block;margin-top:5px;text-align:center }
.qr-timer.expired span { color:#f87171 }
.timer-track { height:4px;background:rgba(255,255,255,.08);border-radius:2px;overflow:hidden }
.timer-fill { height:100%;background:linear-gradient(90deg,#e8273a,#ffcc00);border-radius:2px;transition:width 1s linear }
.qr-poll { display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:14px;font-size:.74rem;color:rgba(255,255,255,.4);font-weight:600 }
.pulse-dot { width:7px;height:7px;border-radius:50%;background:#ffcc00;animation:pd 1.2s ease-in-out infinite }
@keyframes pd { 0%,100%{opacity:1;transform:scale(1)}50%{opacity:.3;transform:scale(.7)} }
.qr-actions-modal { display:flex;gap:8px }
.btn-qr-refresh,.btn-qr-close { flex:1;padding:11px;border-radius:10px;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:800;cursor:pointer;transition:all .2s }
.btn-qr-refresh { background:rgba(255,204,0,.12);border:1px solid rgba(255,204,0,.25);color:#ffcc00 }
.btn-qr-refresh:hover { background:rgba(255,204,0,.22) }
.btn-qr-close { background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.12);color:rgba(245,237,230,.7) }
.btn-qr-close:hover { background:rgba(255,255,255,.1);color:#f5ede6 }

@media(max-width:600px) {
  .info-grid { grid-template-columns:1fr }
  .timeline { gap:0 }
  .qr-pending-banner { flex-direction:column }
}
</style>