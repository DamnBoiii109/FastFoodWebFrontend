<template>
  <div class="staff-wrap">

    <!-- SIDEBAR -->
    <aside class="sidebar">
      <div class="sb-brand">
        <div class="sb-icon">🍔</div>
        <div class="sb-name">FastFood<span>YumMy</span></div>
      </div>
      <nav class="sb-nav">
        <span class="nav-lbl">Nhân Viên</span>
        <router-link to="/staff/hoa-don" class="nav-item"><span>🧾</span>Tạo Hóa Đơn</router-link>
        <router-link to="/staff/lich-su" class="nav-item active"><span>📋</span>Lịch Sử</router-link>
        <div class="nav-sep"></div>
        <router-link to="/staff/ho-so"   class="nav-item"><span>👤</span>Hồ Sơ</router-link>
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

    <!-- MAIN -->
    <div class="staff-main">
      <header class="topbar">
        <div class="page-title">Lịch Sử <span>Hóa Đơn</span></div>
        <div class="topbar-r">
          <div class="clock-txt">{{ clock }}</div>
        </div>
      </header>

      <div class="staff-content">

        <!-- Filter tabs -->
        <div class="filter-bar">
          <button
            v-for="tab in statusTabs" :key="tab.value"
            class="ftab"
            :class="{ active: activeTab === tab.value }"
            @click="activeTab = tab.value"
          >
            {{ tab.label }}
            <span v-if="countByStatus(tab.value)" class="ftab-badge">{{ countByStatus(tab.value) }}</span>
          </button>

          <div class="search-wrap">
            <span>🔍</span>
            <input v-model="search" placeholder="Tìm theo mã đơn..." class="search-in">
          </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="sk-list">
          <div v-for="n in 5" :key="n" class="sk-row"></div>
        </div>

        <!-- Empty -->
        <div v-else-if="filteredOrders.length === 0" class="empty-state">
          <div>📋</div>
          <p>Không có hóa đơn nào</p>
        </div>

        <!-- Orders list -->
        <div v-else class="order-list">
          <div
            v-for="hd in filteredOrders"
            :key="hd.id"
            class="order-card"
            @click="openDetail(hd)"
          >
            <div class="oc-left">
              <div class="oc-id">#{{ pad(hd.id) }}</div>
              <div class="oc-customer">{{ hd.taiKhoan?.hoTen || 'Khách lẻ' }}</div>
              <div class="oc-date">📅 {{ fmtDate(hd.ngayLap) }}</div>
            </div>
            <div class="oc-mid">
              <div class="oc-items-preview">
                <span v-for="(ct, i) in (hd.chiTietHoaDons || []).slice(0,2)" :key="i" class="oc-item-chip">
                  {{ ct.monAn?.tenMon }} ×{{ ct.soLuong }}
                </span>
                <span v-if="(hd.chiTietHoaDons||[]).length > 2" class="oc-item-chip more">
                  +{{ hd.chiTietHoaDons.length - 2 }} món
                </span>
              </div>
            </div>
            <div class="oc-right">
              <div class="oc-total">{{ fmt(hd.tongTien) }}</div>
              <div :class="['oc-badge', statusClass(hd.trangThai)]">{{ statusLabel(hd.trangThai) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- DETAIL MODAL -->
    <div class="overlay" :class="{ open: !!selected }" @click.self="selected = null">
      <div class="detail-modal" v-if="selected">

        <!-- Header -->
        <div class="dm-head">
          <div>
            <div class="dm-label">Chi Tiết Đơn Hàng</div>
            <div class="dm-id">#{{ pad(selected.id) }}</div>
          </div>
          <div class="dm-head-right">
            <div :class="['oc-badge', statusClass(selected.trangThai)]">
              {{ statusLabel(selected.trangThai) }}
            </div>
            <button class="dm-close" @click="selected = null">✕</button>
          </div>
        </div>

        <!-- Progress bar -->
        <div class="progress-wrap">
          <div v-for="(step, i) in progressSteps" :key="step.value" class="progress-step">
            <div class="ps-line-left"  v-if="i > 0"                         :class="{ done: stepIndex >= i }"></div>
            <div class="ps-dot" :class="{ done: stepIndex >= i, current: stepIndex === i }">
              {{ step.icon }}
            </div>
            <div class="ps-line-right" v-if="i < progressSteps.length - 1"  :class="{ done: stepIndex > i }"></div>
            <div class="ps-label" :class="{ active: stepIndex === i }">{{ step.label }}</div>
          </div>
        </div>

        <!-- Info + Update status -->
        <div class="dm-body">
          <div class="info-card">
            <div class="info-title">Thông Tin Đơn</div>
            <div class="info-row"><span>Mã đơn</span><span>#{{ pad(selected.id) }}</span></div>
            <div class="info-row"><span>Khách hàng</span><span>{{ selected.taiKhoan?.hoTen || 'Khách lẻ' }}</span></div>
            <div class="info-row"><span>Ngày đặt</span><span>{{ fmtDate(selected.ngayLap) }}</span></div>
            <div class="info-row" v-if="selected.khuyenMai">
              <span>Voucher</span><span>{{ selected.khuyenMai.tenKhuyenMai }}</span>
            </div>
            <!-- ✅ Thêm mới: địa chỉ, ghi chú, thanh toán, trạng thái TT -->
            <div class="info-row"><span>Địa chỉ</span><span>{{ selected.diaChi || '—' }}</span></div>
            <div class="info-row"><span>Ghi chú</span><span>{{ selected.ghiChu || '—' }}</span></div>
            <div class="info-row">
              <span>Thanh toán</span>
              <span>{{ payLabel(selected.phuongThucThanhToan) }}</span>
            </div>
            <div class="info-row">
              <span>Trạng thái TT</span>
              <span :style="{ color: daTTSelected ? '#4ade80' : '#fb923c' }">
                {{ daTTSelected ? '✅ Đã TT' : '⏳ Chưa TT' }}
              </span>
            </div>
          </div>

          <div class="update-card">
            <div class="info-title">Cập Nhật Trạng Thái</div>
            <select v-model="newStatus" class="status-select">
              <option v-for="s in allStatuses" :key="s.value" :value="s.value">
                {{ s.icon }} {{ s.label }}
              </option>
            </select>
            <button
              class="btn-update"
              @click="updateStatus"
              :disabled="updating || newStatus === selected.trangThai"
            >
              {{ updating ? '⏳ Đang cập nhật...' : '✅ Cập Nhật' }}
            </button>
          </div>
        </div>

        <!-- Items -->
        <div class="items-section">
          <div class="items-title">Món Đã Đặt</div>
          <div v-for="ct in selected.chiTietHoaDons || []" :key="ct.id" class="item-row">
            <img
              v-if="ct.monAn?.hinhAnh"
              :src="ct.monAn.hinhAnh"
              class="item-img"
              @error="e => e.target.style.display='none'"
            >
            <div v-else class="item-img item-img-ph">🍔</div>
            <div class="item-info">
              <div class="item-name">{{ ct.monAn?.tenMon }}</div>
              <div class="item-price-unit">{{ fmt(ct.donGia) }} / món</div>
            </div>
            <div class="item-qty">×{{ ct.soLuong }}</div>
            <div class="item-total">{{ fmt(ct.donGia * ct.soLuong) }}</div>
          </div>
        </div>

        <!-- Tổng -->
        <div class="dm-footer">
          <div class="dm-footer-row sub">
            <span>Tạm tính</span>
            <span>{{ fmt(subTotal(selected)) }}</span>
          </div>
          <div class="dm-footer-row sub" v-if="selected.khuyenMai">
            <span>Giảm giá ({{ selected.khuyenMai.phanTramGiam }}%)</span>
            <span style="color:#e8273a">-{{ fmt(discountAmt(selected)) }}</span>
          </div>
          <div class="dm-footer-row total">
            <span>TỔNG CỘNG</span>
            <span class="total-amt">{{ fmt(selected.tongTien) }}</span>
          </div>
        </div>
      </div>
    </div>

    <div class="toast" :class="{ show: toastVisible }">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { hoaDonAPI } from '../../services/api'

const auth   = useAuthStore()
const router = useRouter()

// Clock
const clock = ref('')
let timer
function tick() { clock.value = new Date().toLocaleTimeString('vi', { hour:'2-digit', minute:'2-digit' }) }
onMounted(() => { tick(); timer = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(timer))

const initials = computed(() =>
  (auth.user?.hoTen || 'NV').split(' ').map(w => w[0]).slice(-2).join('').toUpperCase()
)
function logout() { auth.logout(); router.push('/dang-nhap') }

// Data
const orders    = ref([])
const loading   = ref(true)
const activeTab = ref('all')
const search    = ref('')
const selected  = ref(null)
const newStatus = ref('')
const updating  = ref(false)
const toastMsg  = ref('')
const toastVisible = ref(false)

const statusTabs = [
  { value: 'all',          label: 'Tất Cả' },
  { value: 'cho_xac_nhan', label: '⏳ Chờ Xác Nhận' },
  { value: 'cho_thanh_toan', label: '💳 Chờ Thanh Toán' },
  { value: 'dang_chuan_bi',label: '👨‍🍳 Chuẩn Bị' },
  { value: 'dang_giao',    label: '🛵 Đang Giao' },
  { value: 'hoan_thanh',   label: '✅ Hoàn Thành' },
  { value: 'da_huy',       label: '❌ Đã Huỷ' },
]

const allStatuses = [
  { value: 'cho_thanh_toan', icon: '💳', label: 'Chờ Thanh Toán' },
  { value: 'cho_xac_nhan',  icon: '⏳', label: 'Chờ Xác Nhận' },
  { value: 'dang_chuan_bi', icon: '👨‍🍳', label: 'Đang Chuẩn Bị' },
  { value: 'dang_giao',     icon: '🛵', label: 'Đang Giao' },
  { value: 'hoan_thanh',    icon: '✅', label: 'Hoàn Thành' },
  { value: 'da_huy',        icon: '❌', label: 'Đã Huỷ' },
]

const progressSteps = [
  { value: 'cho_thanh_toan',icon:'💳', label: ' Chờ Thanh Toán' },
  { value: 'cho_xac_nhan',  icon: '⏳', label: 'Chờ Xác Nhận' },
  { value: 'dang_chuan_bi', icon: '👨‍🍳', label: 'Đang Chuẩn Bị' },
  { value: 'dang_giao',     icon: '🛵', label: 'Đang Giao' },
  { value: 'hoan_thanh',    icon: '✅', label: 'Hoàn Thành' },
]

const stepIndex = computed(() => {
  const idx = progressSteps.findIndex(s => s.value === selected.value?.trangThai)
  return idx === -1 ? 0 : idx
})

// Logic thanh toán:
// - Thẻ / QR → luôn Đã TT
// - Tiền mặt → chỉ Đã TT khi đơn Hoàn Thành
const daTTSelected = computed(() => {
  if (!selected.value) return false
  return selected.value.daThanhToan === true
})

const filteredOrders = computed(() => {
  let list = orders.value
  if (activeTab.value !== 'all') list = list.filter(o => o.trangThai === activeTab.value)
  if (search.value.trim()) {
    list = list.filter(o => String(o.id).includes(search.value.trim()))
  }
  return list
})

function countByStatus(status) {
  if (status === 'all') return 0
  return orders.value.filter(o => o.trangThai === status).length
}

function payLabel(p) {
  return { tien_mat:'💵 Tiền Mặt', the:'💳 Thẻ Ngân Hàng', qr:'📱 QR / Ví Điện Tử' }[p] || p || '—'
}
function statusLabel(s) {
  return { cho_xac_nhan:'⏳ Chờ XN', cho_thanh_toan:'💳 Chờ TT', dang_chuan_bi:'👨‍🍳 Chuẩn Bị', dang_giao:'🛵 Đang Giao', hoan_thanh:'✅ Hoàn Thành', da_huy:'❌ Đã Huỷ' }[s] || s
}
function statusClass(s) {
  return { cho_xac_nhan:'st-pending', cho_thanh_toan:'st-payment', dang_chuan_bi:'st-preparing', dang_giao:'st-delivering', hoan_thanh:'st-done', da_huy:'st-cancelled' }[s] || ''
}

function fmt(n)  { return Number(n||0).toLocaleString('vi') + 'đ' }
function pad(id) { return String(id).padStart(4, '0') }
function fmtDate(d) {
  if (!d) return '—'
  const dt = new Date(d)
  return dt.toLocaleTimeString('vi',{hour:'2-digit',minute:'2-digit'}) + ' ' + dt.toLocaleDateString('vi')
}

function subTotal(hd) {
  return (hd.chiTietHoaDons || []).reduce((s, ct) => s + ct.donGia * ct.soLuong, 0)
}
function discountAmt(hd) {
  if (!hd.khuyenMai) return 0
  return Math.round(subTotal(hd) * hd.khuyenMai.phanTramGiam / 100)
}

function openDetail(hd) {
  selected.value  = hd
  newStatus.value = hd.trangThai
}

async function updateStatus() {
  if (!selected.value) return
  updating.value = true
  try {
    await hoaDonAPI.updateStatus(selected.value.id, newStatus.value)
    const idx = orders.value.findIndex(o => o.id === selected.value.id)
    if (idx !== -1) orders.value[idx].trangThai = newStatus.value
    selected.value.trangThai = newStatus.value
    showToast('✅ Đã cập nhật trạng thái!')
  } catch {
    showToast('❌ Cập nhật thất bại')
  } finally {
    updating.value = false
  }
}

function showToast(msg) {
  toastMsg.value = msg; toastVisible.value = true
  setTimeout(() => toastVisible.value = false, 2500)
}

onMounted(async () => {
  try {
    const res = await hoaDonAPI.getAll()
    orders.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');
.st-payment { background:rgba(99,102,241,.12);color:#818cf8;border:1px solid rgba(99,102,241,.22); }

.staff-wrap { display:flex;min-height:100vh;background:#0e0a0a;color:#f5ede6;font-family:'Nunito',sans-serif; }

/* Sidebar */
.sidebar { position:fixed;top:0;left:0;bottom:0;width:180px;background:rgba(10,6,6,.97);border-right:1px solid rgba(255,255,255,.08);display:flex;flex-direction:column;z-index:200; }
.sb-brand { display:flex;align-items:center;gap:9px;padding:18px 14px;border-bottom:1px solid rgba(255,255,255,.08);text-decoration:none; }
.sb-icon { width:32px;height:32px;background:#e8273a;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0; }
.sb-name { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.06em;color:#fff;line-height:1; }
.sb-name span { color:#ffcc00; }
.sb-nav { flex:1;padding:12px 8px;display:flex;flex-direction:column;gap:2px;overflow-y:auto; }
.nav-item { display:flex;align-items:center;gap:8px;padding:9px 10px;border-radius:10px;text-decoration:none;color:rgba(245,237,230,.5);font-size:.76rem;font-weight:800;letter-spacing:.04em;text-transform:uppercase;transition:all .2s;border:1px solid transparent;background:none;cursor:pointer;font-family:'Nunito',sans-serif;width:100%;text-align:left; }
.nav-item:hover { background:rgba(255,255,255,.05);color:#f5ede6; }
.nav-item.active { background:rgba(232,39,58,.15);color:#e8273a;border-color:rgba(232,39,58,.2); }
.nav-item span { font-size:.9rem;width:16px;text-align:center;flex-shrink:0; }
.nav-logout:hover { background:rgba(248,113,113,.1);color:#f87171; }
.nav-sep { height:1px;background:rgba(255,255,255,.08);margin:6px 10px; }
.nav-lbl { font-size:.58rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:rgba(245,237,230,.4);padding:6px 10px 2px; }
.sb-foot { padding:12px;border-top:1px solid rgba(255,255,255,.08); }
.s-user { display:flex;align-items:center;gap:8px; }
.s-ava { width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#f59e0b,#d97706);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:.78rem;color:#fff;flex-shrink:0; }
.s-name { font-size:.74rem;font-weight:800;color:#f5ede6; }
.s-role { font-size:.62rem;color:rgba(245,237,230,.4);font-weight:600; }

/* Main */
.staff-main { margin-left:180px;flex:1;display:flex;flex-direction:column;min-height:100vh;background:#0e0a0a; }
.topbar { height:60px;flex-shrink:0;background:rgba(14,10,10,.9);backdrop-filter:blur(18px);border-bottom:1px solid rgba(255,255,255,.08);padding:0 28px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100; }
.page-title { font-family:'Bebas Neue',sans-serif;font-size:1.4rem;letter-spacing:.06em;color:#fff; }
.page-title span { color:#ffcc00; }
.clock-txt { font-size:.76rem;font-weight:700;color:rgba(245,237,230,.4);background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);padding:4px 12px;border-radius:50px; }
.staff-content { padding:24px 28px;flex:1; }

/* Filter bar */
.filter-bar { display:flex;align-items:center;gap:8px;margin-bottom:20px;flex-wrap:wrap; }
.ftab { padding:7px 14px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.74rem;font-weight:800;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(245,237,230,.5);cursor:pointer;transition:all .2s;display:flex;align-items:center;gap:5px; }
.ftab:hover,.ftab.active { background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.3);color:#e8273a; }
.ftab-badge { width:17px;height:17px;background:#e8273a;border-radius:50%;font-size:.62rem;font-weight:900;color:#fff;display:flex;align-items:center;justify-content:center; }
.search-wrap { display:flex;align-items:center;gap:7px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:10px;padding:7px 13px;margin-left:auto; }
.search-in { background:none;border:none;outline:none;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:600;width:160px; }
.search-in::placeholder { color:rgba(245,237,230,.4); }

/* Loading / empty */
.sk-list { display:flex;flex-direction:column;gap:10px; }
.sk-row { background:rgba(255,255,255,.04);border-radius:14px;height:70px;animation:pulse 1.5s ease-in-out infinite; }
@keyframes pulse { 0%,100%{opacity:.4}50%{opacity:.7} }
.empty-state { text-align:center;padding:60px;color:rgba(245,237,230,.4);font-size:.9rem;font-weight:700; }
.empty-state div { font-size:3rem;margin-bottom:12px; }

/* Order list */
.order-list { display:flex;flex-direction:column;gap:10px; }
.order-card { display:flex;align-items:center;gap:16px;background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:14px 18px;cursor:pointer;transition:all .2s; }
.order-card:hover { border-color:rgba(232,39,58,.25);transform:translateX(3px);box-shadow:0 6px 20px rgba(0,0,0,.4); }
.oc-left { flex-shrink:0;min-width:120px; }
.oc-id { font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.08em;color:#fff; }
.oc-customer { font-size:.78rem;font-weight:800;color:#f5ede6;margin-top:2px; }
.oc-date { font-size:.7rem;color:rgba(245,237,230,.4);font-weight:600;margin-top:2px; }
.oc-mid { flex:1;display:flex;gap:6px;flex-wrap:wrap; }
.oc-item-chip { padding:3px 9px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50px;font-size:.68rem;font-weight:700;color:rgba(245,237,230,.6); }
.oc-item-chip.more { background:rgba(232,39,58,.1);border-color:rgba(232,39,58,.2);color:#e8273a; }
.oc-right { flex-shrink:0;text-align:right; }
.oc-total { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.04em;color:#ffcc00;margin-bottom:5px; }

/* Status badges */
.oc-badge { display:inline-block;padding:3px 10px;border-radius:50px;font-size:.65rem;font-weight:900;letter-spacing:.07em;text-transform:uppercase; }
.st-pending    { background:rgba(251,146,60,.12);color:#fb923c;border:1px solid rgba(251,146,60,.22); }
.st-preparing  { background:rgba(96,165,250,.12);color:#60a5fa;border:1px solid rgba(96,165,250,.22); }
.st-delivering { background:rgba(167,139,250,.12);color:#a78bfa;border:1px solid rgba(167,139,250,.22); }
.st-done       { background:rgba(74,222,128,.12);color:#4ade80;border:1px solid rgba(74,222,128,.22); }
.st-cancelled  { background:rgba(248,113,113,.1);color:#f87171;border:1px solid rgba(248,113,113,.2); }

/* Overlay */
.overlay { position:fixed;inset:0;background:rgba(0,0,0,.75);backdrop-filter:blur(8px);z-index:500;display:none;align-items:flex-start;justify-content:center;overflow-y:auto;padding:24px; }
.overlay.open { display:flex; }

/* Detail modal */
.detail-modal { background:#130a0a;border:1px solid rgba(232,39,58,.2);border-radius:22px;width:100%;max-width:720px;margin:auto; }
.dm-head { display:flex;align-items:flex-start;justify-content:space-between;padding:24px 28px 0; }
.dm-label { font-size:.68rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:#e8273a;margin-bottom:4px; }
.dm-id { font-family:'Bebas Neue',sans-serif;font-size:2.5rem;letter-spacing:.06em;color:#fff;line-height:1; }
.dm-head-right { display:flex;align-items:center;gap:10px; }
.dm-close { width:30px;height:30px;border-radius:50%;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:.85rem;color:#f5ede6;transition:background .2s; }
.dm-close:hover { background:rgba(232,39,58,.2); }

/* Progress */
.progress-wrap { display:flex;align-items:flex-start;justify-content:center;padding:24px 28px;gap:0;position:relative; }
.progress-step { display:flex;flex-direction:column;align-items:center;position:relative;flex:1; }
.ps-dot { width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.08);border:2px solid rgba(255,255,255,.12);display:flex;align-items:center;justify-content:center;font-size:1.1rem;z-index:2;transition:all .3s; }
.ps-dot.done    { background:rgba(232,39,58,.2);border-color:#e8273a; }
.ps-dot.current { background:rgba(232,39,58,.3);border-color:#e8273a;box-shadow:0 0 0 4px rgba(232,39,58,.2); }
.ps-label { font-size:.62rem;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-top:7px;text-align:center; }
.ps-label.active { color:#e8273a; }
.ps-line-left,.ps-line-right { position:absolute;top:22px;height:2px;width:50%;background:rgba(255,255,255,.08);transition:background .3s; }
.ps-line-left  { left:0;transform:translateX(-50%); }
.ps-line-right { right:0;transform:translateX(50%); }
.ps-line-left.done,.ps-line-right.done { background:#e8273a; }

/* Body cards */
.dm-body { display:grid;grid-template-columns:1fr 1fr;gap:14px;padding:0 28px 20px; }
.info-card,.update-card { background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:14px;padding:16px; }
.info-title { font-family:'Bebas Neue',sans-serif;font-size:.95rem;letter-spacing:.1em;color:rgba(245,237,230,.5);margin-bottom:12px;text-transform:uppercase; }
.info-row { display:flex;justify-content:space-between;font-size:.8rem;font-weight:700;color:rgba(245,237,230,.55);padding:5px 0;border-bottom:1px solid rgba(255,255,255,.04); }
.info-row:last-child { border-bottom:none; }
.info-row span:last-child { color:#f5ede6; }
.status-select { width:100%;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:10px;padding:10px 13px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:700;outline:none;margin-bottom:10px;cursor:pointer; }
.status-select option { background:#130a0a; }
.btn-update { width:100%;padding:11px;background:#e8273a;border:none;border-radius:10px;font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.08em;color:#fff;cursor:pointer;transition:all .2s;box-shadow:0 4px 14px rgba(232,39,58,.4); }
.btn-update:hover:not(:disabled) { background:#b8001a;transform:translateY(-1px); }
.btn-update:disabled { opacity:.4;cursor:not-allowed; }

/* Items */
.items-section { padding:0 28px 20px; }
.items-title { font-family:'Bebas Neue',sans-serif;font-size:.95rem;letter-spacing:.1em;color:rgba(245,237,230,.5);margin-bottom:12px;text-transform:uppercase; }
.item-row { display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05); }
.item-row:last-child { border-bottom:none; }
.item-img { width:46px;height:46px;border-radius:10px;object-fit:cover;flex-shrink:0; }
.item-img-ph { background:rgba(255,255,255,.06);display:flex;align-items:center;justify-content:center;font-size:1.4rem; }
.item-info { flex:1; }
.item-name { font-size:.85rem;font-weight:800;color:#f5ede6; }
.item-price-unit { font-size:.7rem;color:rgba(245,237,230,.4);font-weight:600;margin-top:2px; }
.item-qty { font-size:.82rem;font-weight:800;color:rgba(245,237,230,.5);min-width:32px;text-align:center; }
.item-total { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.04em;color:#ffcc00;min-width:90px;text-align:right; }

/* Footer */
.dm-footer { padding:16px 28px 24px;border-top:1px solid rgba(255,255,255,.07); }
.dm-footer-row { display:flex;justify-content:space-between;margin-bottom:7px; }
.dm-footer-row.sub { font-size:.8rem;font-weight:700;color:rgba(245,237,230,.5); }
.dm-footer-row.total { margin-top:10px;padding-top:10px;border-top:1px solid rgba(255,255,255,.08); }
.dm-footer-row.total span:first-child { font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.1em;color:#fff; }
.total-amt { font-family:'Bebas Neue',sans-serif;font-size:1.6rem;letter-spacing:.04em;color:#ffcc00; }

/* Toast */
.toast { position:fixed;bottom:26px;right:26px;z-index:999;background:rgba(14,10,10,.95);border:1px solid rgba(255,255,255,.1);backdrop-filter:blur(12px);border-radius:13px;padding:12px 18px;font-size:.84rem;font-weight:700;color:#f5ede6;transform:translateX(120%);transition:transform .4s cubic-bezier(.34,1.56,.64,1);min-width:200px;font-family:'Nunito',sans-serif; }
.toast.show { transform:translateX(0); }
</style>