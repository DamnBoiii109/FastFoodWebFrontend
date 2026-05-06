<template>
  <div class="admin-layout">
    <AdminSidebar active="hoa-don" />
    <div class="main-wrap">
      <AdminTopbar title="Quản Lý" highlight="Hóa Đơn" />

      <div class="content">
        <!-- Stats -->
        <div class="stats-row">
          <div class="stat-card"><span class="stat-emoji">📋</span><div class="stat-label">Tổng Đơn</div><div class="stat-val">{{ orders.length }}</div><div class="stat-sub">Tất cả thời gian</div></div>
          <div class="stat-card"><span class="stat-emoji">⏳</span><div class="stat-label">Chờ Xác Nhận</div><div class="stat-val red">{{ countBy('cho_xac_nhan') }}</div><div class="stat-sub">Cần xử lý</div></div>
          <div class="stat-card"><span class="stat-emoji">✅</span><div class="stat-label">Hoàn Thành</div><div class="stat-val green">{{ countBy('hoan_thanh') }}</div><div class="stat-sub">Đã giao thành công</div></div>
          <div class="stat-card"><span class="stat-emoji">💰</span><div class="stat-label">Doanh Thu</div><div class="stat-val yellow">{{ fmtAmt(tongDoanhThu) }}</div><div class="stat-sub">Đơn hoàn thành</div></div>
        </div>

        <!-- Toolbar -->
        <div class="toolbar">
          <div class="toolbar-left">
            <button v-for="tab in statusTabs" :key="tab.value" class="filter-btn" :class="{ active: activeTab === tab.value }" @click="activeTab = tab.value">
              {{ tab.label }}
              <span v-if="tab.value !== 'all' && countByFiltered(tab.value)" class="tab-count">{{ countByFiltered(tab.value) }}</span>
            </button>
          </div>
          <div class="toolbar-right">
            <!-- Date range filter -->
            <div class="date-range-wrap">
              <span class="date-range-icon">📅</span>
              <input
                type="date"
                v-model="dateFrom"
                class="date-inp"
                :max="dateTo || todayStr"
                placeholder="Từ ngày"
              >
              <span class="date-sep">→</span>
              <input
                type="date"
                v-model="dateTo"
                class="date-inp"
                :min="dateFrom"
                :max="todayStr"
                placeholder="Đến ngày"
              >
              <button v-if="dateFrom || dateTo" class="btn-clr" @click="clearDate" title="Xoá lọc ngày">✕</button>
            </div>
            <div class="search-box">
              <span>🔍</span>
              <input v-model="search" placeholder="Tìm mã đơn, khách hàng..." class="search-input">
            </div>
          </div>
        </div>

        <!-- Date filter summary -->
        <div v-if="dateFrom || dateTo" class="date-summary-bar">
          <span>📅 Đang lọc:</span>
          <strong>{{ dateFrom ? fmtDateLabel(dateFrom) : 'Đầu' }}</strong>
          <span>→</span>
          <strong>{{ dateTo ? fmtDateLabel(dateTo) : 'Nay' }}</strong>
          <span class="ds-count">{{ filteredOrders.length }} đơn</span>
          <span class="ds-rev">Doanh thu: {{ fmtAmt(tongDoanhThu) }}</span>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="table-wrap table-loading">
          <div v-for="n in 6" :key="n" class="skeleton-row"></div>
        </div>

        <!-- Empty -->
        <div v-else-if="filteredOrders.length === 0" class="table-wrap">
          <div class="table-empty"><span>📋</span> Không có hóa đơn nào</div>
        </div>

        <!-- Table -->
        <div v-else class="table-wrap">
          <div class="table-head">
            <div class="th" style="width:80px">Mã Đơn</div>
            <div class="th flex2">Khách Hàng</div>
            <div class="th flex2">Món Đã Đặt</div>
            <div class="th">Tổng Tiền</div>
            <div class="th">Ngày Đặt</div>
            <div class="th">Trạng Thái</div>
            <div class="th" style="width:130px">Thao Tác</div>
          </div>

          <div v-for="hd in filteredOrders" :key="hd.id" class="table-row">
            <!-- Mã -->
            <div style="width:80px">
              <span class="order-id">#{{ pad(hd.id) }}</span>
            </div>

            <!-- Khách -->
            <div class="flex2">
              <div class="td-name">{{ hd.taiKhoan?.hoTen || 'Khách lẻ' }}</div>
              <div class="td-sub">{{ hd.taiKhoan?.email || '' }}</div>
            </div>

            <!-- Món đã đặt inline -->
            <div class="flex2">
              <div class="items-inline">
                <span
                  v-for="(ct, i) in (hd.chiTietHoaDons || []).slice(0, 2)"
                  :key="i"
                  class="item-pill"
                >{{ ct.monAn?.tenMon }} ×{{ ct.soLuong }}</span>
                <span
                  v-if="(hd.chiTietHoaDons || []).length > 2"
                  class="item-pill more"
                  @click.stop="openDetail(hd)"
                >+{{ hd.chiTietHoaDons.length - 2 }} món</span>
              </div>
            </div>

            <!-- Tổng -->
            <div class="td price-td">{{ fmt(hd.tongTien) }}</div>

            <!-- Ngày -->
            <div class="td date-td">{{ fmtDate(hd.ngayLap) }}</div>

            <!-- Trạng thái -->
            <div class="td">
              <span :class="['oc-badge', statusClass(hd.trangThai)]">{{ statusLabel(hd.trangThai) }}</span>
            </div>

            <!-- Actions -->
            <div class="td row-actions" style="width:130px">
              <button class="act-btn" @click="openDetail(hd)" title="Xem chi tiết">🔍</button>
              <select
                class="quick-select"
                :value="hd.trangThai"
                @change="quickUpdate(hd, $event.target.value)"
                @click.stop
              >
                <option v-for="s in allStatuses" :key="s.value" :value="s.value">{{ s.icon }} {{ s.label }}</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- DETAIL MODAL -->
    <div class="modal-overlay" :class="{ open: !!selected }" @click.self="selected = null">
      <div class="detail-modal" v-if="selected">
        <div class="dm-head">
          <div>
            <div class="dm-label">Chi Tiết Đơn Hàng</div>
            <div class="dm-id">#{{ pad(selected.id) }}</div>
          </div>
          <div class="dm-head-r">
            <div :class="['oc-badge', statusClass(selected.trangThai)]">{{ statusLabel(selected.trangThai) }}</div>
            <button class="modal-close" @click="selected = null">✕</button>
          </div>
        </div>

        <!-- Progress -->
        <div class="progress-wrap">
          <div v-for="(step, i) in progressSteps" :key="step.value" class="progress-step">
            <div class="ps-line-left"  v-if="i > 0"                           :class="{ done: stepIndex >= i }"></div>
            <div class="ps-dot" :class="{ done: stepIndex >= i, current: stepIndex === i }">{{ step.icon }}</div>
            <div class="ps-line-right" v-if="i < progressSteps.length - 1"    :class="{ done: stepIndex > i }"></div>
            <div class="ps-label" :class="{ active: stepIndex === i }">{{ step.label }}</div>
          </div>
        </div>

        <!-- Info + Update -->
        <div class="dm-body">
          <div class="info-card">
            <div class="info-title">Thông Tin Đơn</div>
            <div class="info-row"><span>Mã đơn</span><span>#{{ pad(selected.id) }}</span></div>
            <div class="info-row"><span>Khách hàng</span><span>{{ selected.taiKhoan?.hoTen || 'Khách lẻ' }}</span></div>
            <div class="info-row"><span>Email</span><span>{{ selected.taiKhoan?.email || '—' }}</span></div>
            <div class="info-row"><span>Ngày đặt</span><span>{{ fmtDate(selected.ngayLap) }}</span></div>
            <div class="info-row" v-if="selected.khuyenMai">
              <span>Voucher</span>
              <span style="color:#ffcc00">{{ selected.khuyenMai.tenKhuyenMai }} (-{{ selected.khuyenMai.phanTramGiam }}%)</span>
            </div>
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
              <option v-for="s in allStatuses" :key="s.value" :value="s.value">{{ s.icon }} {{ s.label }}</option>
            </select>
            <button class="btn-update" @click="updateStatus" :disabled="updating || newStatus === selected.trangThai">
              {{ updating ? '⏳ Đang cập nhật...' : '✅ Cập Nhật' }}
            </button>
          </div>
        </div>

        <!-- Items -->
        <div class="items-section">
          <div class="info-title">Món Đã Đặt</div>
          <div v-for="ct in selected.chiTietHoaDons || []" :key="ct.id" class="item-row">
            <img v-if="ct.monAn?.hinhAnh" :src="ct.monAn.hinhAnh" class="item-img" @error="e=>e.target.style.display='none'">
            <div v-else class="item-img item-img-ph">🍔</div>
            <div class="item-info">
              <div class="item-name">{{ ct.monAn?.tenMon }}</div>
              <div class="item-unit">{{ fmt(ct.donGia) }} / món</div>
            </div>
            <div class="item-qty">×{{ ct.soLuong }}</div>
            <div class="item-total">{{ fmt(ct.donGia * ct.soLuong) }}</div>
          </div>
        </div>

        <!-- Tổng -->
        <div class="dm-footer">
          <div class="dm-row sub" v-if="selected.khuyenMai">
            <span>Tạm tính</span><span>{{ fmt(subTotal(selected)) }}</span>
          </div>
          <div class="dm-row sub" v-if="selected.khuyenMai">
            <span>Giảm giá ({{ selected.khuyenMai.phanTramGiam }}%)</span>
            <span style="color:#e8273a">-{{ fmt(discountAmt(selected)) }}</span>
          </div>
          <div class="dm-row total">
            <span>TỔNG CỘNG</span>
            <span class="total-amt">{{ fmt(selected.tongTien) }}</span>
          </div>
        </div>
      </div>
    </div>

    <Toast :msg="toastMsg" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import AdminSidebar from '../../components/admin/AdminSidebar.vue'
import AdminTopbar  from '../../components/admin/AdminTopbar.vue'
import Toast        from '../../components/Toast.vue'
import { hoaDonAPI } from '../../services/api'
import { useToastStore } from '../../stores/toast'

const toast  = useToastStore()
const orders = ref([])
const loading = ref(true)
const activeTab = ref('all')
const search    = ref('')
const selected  = ref(null)
const newStatus = ref('')
const updating  = ref(false)
const toastMsg  = ref('')

// ── Date filter ──
const dateFrom = ref('')
const dateTo   = ref('')
const todayStr = new Date().toISOString().slice(0, 10)

function clearDate() { dateFrom.value = ''; dateTo.value = '' }

function fmtDateLabel(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('vi', { day:'2-digit', month:'2-digit', year:'numeric' })
}
function payLabel(p) {
  return { tien_mat:'💵 Tiền Mặt', the:'💳 Thẻ', qr:'📱 QR/Ví' }[p] || p || '—'
}
function inDateRange(dateStr) {
  if (!dateFrom.value && !dateTo.value) return true
  if (!dateStr) return false
  const d = new Date(dateStr).setHours(0,0,0,0)
  if (dateFrom.value) {
    const from = new Date(dateFrom.value + 'T00:00:00').setHours(0,0,0,0)
    if (d < from) return false
  }
  if (dateTo.value) {
    const to = new Date(dateTo.value + 'T23:59:59').setHours(23,59,59,999)
    if (d > to) return false
  }
  return true
}

const statusTabs = [
  { value:'all',          label:'Tất Cả' },
  { value:'cho_xac_nhan', label:'⏳ Chờ XN' },
  { value:'cho_thanh_toan', label:'💳 Chờ TT' },
  { value:'dang_chuan_bi',label:'👨‍🍳 Chuẩn Bị' },
  { value:'dang_giao',    label:'🛵 Đang Giao' },
  { value:'hoan_thanh',   label:'✅ Hoàn Thành' },
  { value:'da_huy',       label:'❌ Đã Huỷ' },
]

const allStatuses = [
  { value:'cho_xac_nhan',  icon:'⏳', label:'Chờ Xác Nhận' },
  { value:'dang_chuan_bi', icon:'👨‍🍳', label:'Đang Chuẩn Bị' },
  { value:'cho_thanh_toan', icon:'💳', label:'Chờ Thanh Toán' },
  { value:'dang_giao',     icon:'🛵', label:'Đang Giao' },
  { value:'hoan_thanh',    icon:'✅', label:'Hoàn Thành' },
  { value:'da_huy',        icon:'❌', label:'Đã Huỷ' },
]

const progressSteps = [
  { value:'cho_xac_nhan',  icon:'⏳', label:'Chờ XN' },
  { value:'dang_chuan_bi', icon:'👨‍🍳', label:'Chuẩn Bị' },
  { value:'cho_thanh_toan', icon:'💳', label:'Chờ TT' },
  { value:'dang_giao',     icon:'🛵', label:'Đang Giao' },
  { value:'hoan_thanh',    icon:'✅', label:'Hoàn Thành' },
]

const stepIndex = computed(() => {
  const idx = progressSteps.findIndex(s => s.value === selected.value?.trangThai)
  return idx === -1 ? 0 : idx
})

// Danh sách sau khi lọc ngày (dùng cho stats)
const dateFilteredOrders = computed(() => {
  if (!dateFrom.value && !dateTo.value) return orders.value
  return orders.value.filter(o => inDateRange(o.ngayLap))
})

const filteredOrders = computed(() => {
  let list = dateFilteredOrders.value
  if (activeTab.value !== 'all') list = list.filter(o => o.trangThai === activeTab.value)
  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(o =>
      String(o.id).includes(q) ||
      (o.taiKhoan?.hoTen || '').toLowerCase().includes(q) ||
      (o.taiKhoan?.email || '').toLowerCase().includes(q)
    )
  }
  return list
})

// countBy dùng danh sách đã lọc ngày
function countByFiltered(status) {
  return dateFilteredOrders.value.filter(o => o.trangThai === status).length
}

const tongDoanhThu = computed(() =>
  dateFilteredOrders.value.filter(o => o.trangThai === 'hoan_thanh')
    .reduce((s, o) => s + (o.tongTien || 0), 0)
)

function countBy(status) { return orders.value.filter(o => o.trangThai === status).length }
function fmt(n)   { return Number(n||0).toLocaleString('vi') + 'đ' }
function fmtAmt(n){ return n >= 1e6 ? (n/1e6).toFixed(1) + 'M đ' : fmt(n) }
function pad(id)  { return String(id).padStart(4,'0') }
function fmtDate(d) {
  if (!d) return '—'
  const dt = new Date(d)
  return dt.toLocaleTimeString('vi',{hour:'2-digit',minute:'2-digit'}) + ' ' + dt.toLocaleDateString('vi')
}
const daTTSelected = computed(() => {
  if (!selected.value) return false
  return selected.value.daThanhToan === true
})
function statusLabel(s) {
  return { cho_xac_nhan:'⏳ Chờ XN', dang_chuan_bi:'👨‍🍳 Chuẩn Bị',cho_thanh_toan:'💳 Chờ TT', dang_giao:'🛵 Đang Giao', hoan_thanh:'✅ Hoàn Thành', da_huy:'❌ Đã Huỷ' }[s] || s
}
function statusClass(s) {
  return { cho_xac_nhan:'st-pending', dang_chuan_bi:'st-preparing', cho_thanh_toan:'st-payment', dang_giao:'st-delivering', hoan_thanh:'st-done', da_huy:'st-cancelled' }[s] || ''
}
function subTotal(hd)     { return (hd.chiTietHoaDons||[]).reduce((s,ct)=>s+ct.donGia*ct.soLuong,0) }
function discountAmt(hd)  { if(!hd.khuyenMai) return 0; return Math.round(subTotal(hd)*hd.khuyenMai.phanTramGiam/100) }

function openDetail(hd) { selected.value = hd; newStatus.value = hd.trangThai }

async function updateStatus() {
  if (!selected.value) return
  updating.value = true
  try {
    await hoaDonAPI.updateStatus(selected.value.id, newStatus.value)
    const idx = orders.value.findIndex(o => o.id === selected.value.id)
    if (idx !== -1) orders.value[idx].trangThai = newStatus.value
    selected.value.trangThai = newStatus.value
    toast.show('Đã cập nhật trạng thái!')
  } catch { toast.show('Cập nhật thất bại', 'error') }
  finally { updating.value = false }
}

async function quickUpdate(hd, status) {
  try {
    await hoaDonAPI.updateStatus(hd.id, status)
    hd.trangThai = status
    toast.show('Đã cập nhật #' + pad(hd.id))
  } catch { toast.show('Cập nhật thất bại', 'error') }
}

onMounted(async () => {
  try { const res = await hoaDonAPI.getAll(); orders.value = res.data.data }
  catch (e) { console.error(e) }
  finally { loading.value = false }
})
</script>

<style>
/* Dùng chung từ admin.css */
.st-payment { background:rgba(99,102,241,.12);color:#818cf8;border:1px solid rgba(99,102,241,.22); }
.tab-count { display:inline-flex;align-items:center;justify-content:center;width:16px;height:16px;background:#e8273a;border-radius:50%;font-size:.6rem;font-weight:900;color:#fff;margin-left:3px; }
.order-id { font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.06em;color:#fff; }
.td-name { font-size:.82rem;font-weight:800;color:#f5ede6; }
.td-sub  { font-size:.7rem;color:rgba(245,237,230,.4);font-weight:600;margin-top:2px; }
.date-td { font-size:.76rem;font-weight:700;color:rgba(245,237,230,.6); }
.items-inline { display:flex;gap:5px;flex-wrap:wrap; }
.item-pill { padding:2px 8px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50px;font-size:.65rem;font-weight:700;color:rgba(245,237,230,.65); }
.item-pill.more { background:rgba(232,39,58,.1);border-color:rgba(232,39,58,.2);color:#e8273a;cursor:pointer; }
.quick-select { background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:7px;padding:4px 6px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.7rem;font-weight:700;outline:none;cursor:pointer;max-width:100px; }
.quick-select option { background:#130a0a; }
/* Status badges */
.oc-badge { display:inline-block;padding:3px 9px;border-radius:50px;font-size:.64rem;font-weight:900;letter-spacing:.07em;text-transform:uppercase; }
.st-pending    { background:rgba(251,146,60,.12);color:#fb923c;border:1px solid rgba(251,146,60,.22); }
.st-preparing  { background:rgba(96,165,250,.12);color:#60a5fa;border:1px solid rgba(96,165,250,.22); }
.st-delivering { background:rgba(167,139,250,.12);color:#a78bfa;border:1px solid rgba(167,139,250,.22); }
.st-done       { background:rgba(74,222,128,.12);color:#4ade80;border:1px solid rgba(74,222,128,.22); }
.st-cancelled  { background:rgba(248,113,113,.1);color:#f87171;border:1px solid rgba(248,113,113,.2); }
/* Detail modal */
.detail-modal { background:#130a0a;border:1px solid rgba(232,39,58,.2);border-radius:22px;width:100%;max-width:720px;margin:auto;max-height:90vh;overflow-y:auto; }
.dm-head { display:flex;align-items:flex-start;justify-content:space-between;padding:24px 28px 0; }
.dm-label { font-size:.68rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:#e8273a;margin-bottom:4px; }
.dm-id { font-family:'Bebas Neue',sans-serif;font-size:2.4rem;letter-spacing:.06em;color:#fff;line-height:1; }
.dm-head-r { display:flex;align-items:center;gap:10px; }
/* Progress */
.progress-wrap { display:flex;align-items:flex-start;justify-content:center;padding:24px 28px;gap:0; }
.progress-step { display:flex;flex-direction:column;align-items:center;position:relative;flex:1; }
.ps-dot { width:42px;height:42px;border-radius:50%;background:rgba(255,255,255,.08);border:2px solid rgba(255,255,255,.12);display:flex;align-items:center;justify-content:center;font-size:1rem;z-index:2;transition:all .3s; }
.ps-dot.done    { background:rgba(232,39,58,.2);border-color:#e8273a; }
.ps-dot.current { background:rgba(232,39,58,.3);border-color:#e8273a;box-shadow:0 0 0 4px rgba(232,39,58,.2); }
.ps-label { font-size:.58rem;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-top:6px;text-align:center; }
.ps-label.active { color:#e8273a; }
.ps-line-left,.ps-line-right { position:absolute;top:21px;height:2px;width:50%;background:rgba(255,255,255,.08);transition:background .3s; }
.ps-line-left  { left:0;transform:translateX(-50%); }
.ps-line-right { right:0;transform:translateX(50%); }
.ps-line-left.done,.ps-line-right.done { background:#e8273a; }
/* dm body */
.dm-body { display:grid;grid-template-columns:1fr 1fr;gap:14px;padding:0 28px 20px; }
.info-card,.update-card { background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:14px;padding:16px; }
.info-title { font-family:'Bebas Neue',sans-serif;font-size:.9rem;letter-spacing:.1em;color:rgba(245,237,230,.5);margin-bottom:12px;text-transform:uppercase; }
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
.item-row { display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.05); }
.item-row:last-child { border-bottom:none; }
.item-img { width:44px;height:44px;border-radius:10px;object-fit:cover;flex-shrink:0; }
.item-img-ph { background:rgba(255,255,255,.06);display:flex;align-items:center;justify-content:center;font-size:1.3rem; }
.item-info { flex:1; }
.item-name { font-size:.84rem;font-weight:800;color:#f5ede6; }
.item-unit { font-size:.7rem;color:rgba(245,237,230,.4);font-weight:600;margin-top:2px; }
.item-qty { font-size:.82rem;font-weight:800;color:rgba(245,237,230,.5);min-width:30px;text-align:center; }
.item-total { font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.04em;color:#ffcc00;min-width:88px;text-align:right; }
/* Footer */
.dm-footer { padding:16px 28px 24px;border-top:1px solid rgba(255,255,255,.07); }
.dm-row { display:flex;justify-content:space-between;margin-bottom:7px; }
.dm-row.sub { font-size:.8rem;font-weight:700;color:rgba(245,237,230,.5); }
.dm-row.total { margin-top:10px;padding-top:10px;border-top:1px solid rgba(255,255,255,.08); }
.dm-row.total span:first-child { font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.1em;color:#fff; }
.total-amt { font-family:'Bebas Neue',sans-serif;font-size:1.55rem;letter-spacing:.04em;color:#ffcc00; }
/* Date filter */
.date-range-wrap { display:flex;align-items:center;gap:5px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.1);border-radius:10px;padding:6px 10px; }
.date-range-icon { font-size:.85rem;flex-shrink:0; }
.date-inp { background:none;border:none;outline:none;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.76rem;font-weight:700;width:110px;cursor:pointer; }
.date-inp::-webkit-calendar-picker-indicator { filter:invert(1);opacity:.4;cursor:pointer; }
.date-sep { font-size:.8rem;color:rgba(245,237,230,.3);font-weight:700; }
.btn-clr { width:20px;height:20px;border-radius:50%;background:rgba(248,113,113,.1);border:1px solid rgba(248,113,113,.2);color:#f87171;font-size:.6rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s;flex-shrink:0; }
.btn-clr:hover { background:rgba(248,113,113,.25); }
.date-summary-bar { display:flex;align-items:center;gap:8px;background:rgba(255,204,0,.06);border:1px solid rgba(255,204,0,.15);border-radius:10px;padding:8px 14px;margin-bottom:12px;font-size:.78rem;font-weight:700;color:rgba(245,237,230,.6);flex-wrap:wrap; }
.date-summary-bar strong { color:#ffcc00; }
.ds-count { margin-left:auto;background:rgba(255,255,255,.06);padding:2px 9px;border-radius:50px;font-size:.7rem; }
.ds-rev   { color:#4ade80;font-weight:800; }
</style>