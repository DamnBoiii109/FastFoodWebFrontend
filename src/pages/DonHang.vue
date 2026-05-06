<template>
  <div class="page">
    <div class="grain"></div>
    <div class="container">
      <div class="page-header">
        <div class="page-label">Tài Khoản</div>
        <h1 class="page-title">Đơn Hàng <span>Của Tôi</span></h1>
      </div>
      <div class="status-tabs">
        <button v-for="tab in tabs" :key="tab.value" class="status-tab" :class="{ active: activeTab === tab.value }" @click="activeTab = tab.value">
          {{ tab.label }}
          <span class="tab-count" v-if="countByStatus(tab.value) > 0">{{ countByStatus(tab.value) }}</span>
        </button>
      </div>
      <div v-if="loading" class="loading-list">
        <div v-for="n in 4" :key="n" class="skeleton-row"></div>
      </div>
      <div v-else-if="filteredOrders.length === 0" class="empty-state">
        <div class="empty-icon">📋</div>
        <p>Chưa có đơn hàng nào</p>
        <router-link to="/thuc-don" class="btn-order-now">🍔 Đặt Ngay</router-link>
      </div>
      <div v-else class="order-list">
        <div v-for="hd in filteredOrders" :key="hd.id" class="order-card" @click="openDetail(hd)">
          <div class="order-top">
            <div class="order-id"><span class="id-label">Đơn hàng</span><span class="id-val">#{{ pad(hd.id) }}</span></div>
            <div :class="['status-badge', statusClass(hd.trangThai)]">{{ statusLabel(hd.trangThai) }}</div>
          </div>
          
          <div v-if="hd.trangThai === 'cho_thanh_toan'" class="pay-alert" @click.stop="openQR(hd)">
            <span>💳</span><span>Chưa thanh toán — nhấn để quét QR hoàn tất</span><span class="pay-alert-arrow">→</span>
          </div>
          <div class="order-items-preview">
            <span v-for="(ct, i) in (hd.chiTietHoaDons||[]).slice(0,3)" :key="i" class="item-chip">{{ ct.monAn?.tenMon }} ×{{ ct.soLuong }}</span>
            <span v-if="(hd.chiTietHoaDons||[]).length > 3" class="item-chip more">+{{ hd.chiTietHoaDons.length - 3 }} món</span>
          </div>
          <div class="order-footer">
            <div class="order-date">📅 {{ fmtDate(hd.ngayLap) }}</div>
            <div class="order-total">{{ fmt(hd.tongTien) }}</div>
            <div class="order-arrow">→</div>
          </div>
        </div>
      </div>
    </div>

    <!-- DETAIL MODAL -->
    <div class="overlay" :class="{ open: !!selectedOrder }" @click.self="selectedOrder = null">
      <div class="detail-modal" v-if="selectedOrder">
        <div class="dm-head">
          <div><div class="dm-label">Chi Tiết Đơn Hàng</div><div class="dm-id">#{{ pad(selectedOrder.id) }}</div></div>
          <div class="dm-head-r">
            <div :class="['status-badge', 'sm', statusClass(selectedOrder.trangThai)]">{{ statusLabel(selectedOrder.trangThai) }}</div>
            
            <button class="dm-close" @click="selectedOrder = null">✕</button>
          </div>
        </div>
        <div class="progress-wrap" v-if="selectedOrder.trangThai !== 'cho_thanh_toan' && selectedOrder.trangThai !== 'da_huy'">
          <div v-for="(step, i) in progressSteps" :key="step.value" class="progress-step">
            <div class="ps-line-left" v-if="i > 0" :class="{ done: stepIdx >= i }"></div>
            <div class="ps-dot" :class="{ done: stepIdx >= i, current: stepIdx === i }">{{ step.icon }}</div>
            <div class="ps-line-right" v-if="i < progressSteps.length - 1" :class="{ done: stepIdx > i }"></div>
            <div class="ps-label" :class="{ active: stepIdx === i }">{{ step.label }}</div>
          </div>
        </div>
        <div v-if="selectedOrder.trangThai === 'cho_thanh_toan'" class="qr-pending-banner">
          <div class="qpb-icon">💳</div>
          <div><div class="qpb-title">Đơn Chờ Thanh Toán</div><div class="qpb-sub">Hoàn tất QR để tiến hành giao hàng.</div></div>
          <button class="btn-pay-now" @click="openQR(selectedOrder)">Thanh Toán →</button>
        </div>
        <div class="dm-info-section">
          <div class="dm-info-head">
            <div class="dm-section-title">📍 Thông Tin Đơn</div>
            <button v-if="canEdit(selectedOrder)" class="btn-edit-info" @click="openEditInfo(selectedOrder)">✏️ Sửa Thông Tin</button>
          </div>
          <div class="info-grid">
            <div class="ig-row"><span>Mã đơn</span><span>#{{ pad(selectedOrder.id) }}</span></div>
            <div class="ig-row"><span>Ngày đặt</span><span>{{ fmtDate(selectedOrder.ngayLap) }}</span></div>
            <div class="ig-row"><span>Địa chỉ</span><span>{{ selectedOrder.diaChi || '—' }}</span></div>
            <div class="ig-row"><span>Ghi chú</span><span>{{ selectedOrder.ghiChu || '—' }}</span></div>
            <div class="ig-row"><span>Thanh toán</span><span>{{ payLabel(selectedOrder.phuongThucThanhToan) }}</span></div>
            <div class="ig-row"><span>Trạng thái TT</span><span :style="{ color: selectedOrder.daThanhToan ? '#4ade80' : '#fb923c' }">{{ selectedOrder.daThanhToan ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán' }}</span></div>
            <div class="ig-row" v-if="selectedOrder.khuyenMai"><span>Voucher</span><span style="color:#ffcc00">{{ selectedOrder.khuyenMai.tenKhuyenMai }} (-{{ selectedOrder.khuyenMai.phanTramGiam }}%)</span></div>
          </div>
        </div>
        <div class="dm-items-section">
          <div class="dm-info-head">
            <div class="dm-section-title">🍔 Món Đã Đặt</div>
            <button v-if="canEdit(selectedOrder)" class="btn-edit-info" @click="openEditItems(selectedOrder)">✏️ Sửa Món</button>
          </div>
          <div v-if="canEdit(selectedOrder)" class="edit-warning">⚠️ Sửa thông tin hoặc món sẽ ảnh hưởng đến đơn hàng và thanh toán</div>
          <div v-for="ct in selectedOrder.chiTietHoaDons || []" :key="ct.id" class="item-row">
            <img v-if="ct.monAn?.hinhAnh" :src="ct.monAn.hinhAnh" class="item-img" @error="e=>e.target.style.display='none'">
            <div v-else class="item-img item-img-ph">🍔</div>
            <div class="item-info"><div class="item-name">{{ ct.monAn?.tenMon }}</div><div class="item-unit">{{ fmt(ct.donGia) }} / món</div></div>
            <div class="item-qty">×{{ ct.soLuong }}</div>
            <div class="item-total">{{ fmt(ct.donGia * ct.soLuong) }}</div>
          </div>
        </div>
        <div class="dm-footer">
          <div class="dm-row sub" v-if="selectedOrder.khuyenMai"><span>Giảm giá ({{ selectedOrder.khuyenMai.phanTramGiam }}%)</span><span style="color:#e8273a">-{{ fmt(discountAmt(selectedOrder)) }}</span></div>
          <div class="dm-row total"><span>TỔNG CỘNG</span><span class="total-amt">{{ fmt(selectedOrder.tongTien) }}</span></div>
        </div>
        <div class="dm-actions">
          <button v-if="canEdit(selectedOrder)" class="btn-cancel-order" @click="cancelOrder(selectedOrder)" :disabled="cancelling">❌ Huỷ Đơn Hàng</button>
        </div>
      </div>
    </div>

    <!-- EDIT INFO MODAL -->
    <div class="overlay" style="z-index:700" :class="{ open: showEditInfo }" @click.self="showEditInfo = false">
      <div class="edit-modal" v-if="showEditInfo">
        <div class="edit-modal-head"><div class="edit-modal-title">Sửa <span>Thông Tin</span></div><button class="dm-close" @click="showEditInfo = false">✕</button></div>
        <div class="edit-warning mb">⚠️ Thay đổi địa chỉ có thể ảnh hưởng đến quá trình giao hàng</div>
        <div class="edit-body">
          <div class="fgroup"><label>Địa Chỉ Giao Hàng</label><input v-model="editForm.diaChi" class="finput" placeholder="Số nhà, đường, quận..."></div>
          <div class="fgroup"><label>Ghi Chú</label><textarea v-model="editForm.ghiChu" class="finput ftextarea" placeholder="Không hành, ít cay..."></textarea></div>
        </div>
        <div class="edit-footer">
          <button class="btn-cancel-e" @click="showEditInfo = false">Huỷ</button>
          <button class="btn-save-e" @click="saveInfo" :disabled="savingInfo">{{ savingInfo ? '⏳...' : '💾 Lưu' }}</button>
        </div>
      </div>
    </div>

    <!-- EDIT ITEMS MODAL -->
    <div class="overlay" style="z-index:700" :class="{ open: showEditItems }" @click.self="showEditItems = false">
      <div class="edit-modal wide" v-if="showEditItems">
        <div class="edit-modal-head"><div class="edit-modal-title">Sửa <span>Món Ăn</span></div><button class="dm-close" @click="showEditItems = false">✕</button></div>
        <div class="edit-warning mb">⚠️ Sửa món sẽ tính lại tổng tiền. Nếu đã chuyển khoản, hãy liên hệ shop để xử lý chênh lệch.</div>
        <div class="edit-body">
          <div v-for="(item, idx) in editItems" :key="idx" class="edit-item-row">
            <div class="ei-name">{{ item.tenMon }}</div>
            <div class="ei-price">{{ fmt(item.gia) }}</div>
            <div class="ei-qty-ctrl">
              <button class="qty-b" @click="changeEditQty(idx,-1)">−</button>
              <span class="qty-n">{{ item.soLuong }}</span>
              <button class="qty-b" @click="changeEditQty(idx,1)">+</button>
            </div>
            <div class="ei-total">{{ fmt(item.gia * item.soLuong) }}</div>
            <button class="ei-del" @click="editItems.splice(idx,1)">🗑️</button>
          </div>
          <div v-if="editItems.length === 0" class="edit-empty">Không có món nào</div>
          <div class="edit-total-row"><span>Tổng mới</span><span class="edit-total-val">{{ fmt(editItemsSubtotal) }}</span></div>
        </div>
        <div class="edit-footer">
          <button class="btn-cancel-e" @click="showEditItems = false">Huỷ</button>
          <button class="btn-save-e" @click="saveItems" :disabled="savingItems || editItems.length === 0">{{ savingItems ? '⏳...' : '💾 Lưu' }}</button>
        </div>
      </div>
    </div>

    <!-- QR OVERLAY -->
    <div v-if="showQROverlay" class="qr-overlay">
      <div class="qr-card">
        <div class="qr-head"><div class="qr-title">Thanh Toán <span>QR</span></div><button class="dm-close" @click="closeQR">✕</button></div>
        <p class="qr-label">Nội dung chuyển khoản:</p>
        <p class="qr-content">FASTFOOD HD{{ qrOrderId }}</p>
        <div class="qr-img-wrap"><img :src="qrUrl" alt="QR" class="qr-img"></div>
        <div class="qr-timer"><div class="timer-bar-wrap"><div class="timer-bar" :style="{ width: (qrCountdown/300*100)+'%' }"></div></div><span>Hết hạn sau {{ fmtCountdown(qrCountdown) }}</span></div>
        <div class="qr-status"><div class="qr-pulse"></div><span>Đang chờ xác nhận...</span></div>
        <p class="qr-bank-info">TPBank — 10002998539<br>TRUONG KIM LONG</p>
        <div class="qr-actions"><button class="btn-qr-done" @click="mockDoneQR">✅ Tôi Đã Chuyển Khoản</button></div>
      </div>
    </div>

    <div class="toast" :class="{ show: toastVisible }">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { hoaDonAPI } from '../services/api'

const orders = ref([]), loading = ref(true), activeTab = ref('all')
const selectedOrder = ref(null), cancelling = ref(false)
const toastMsg = ref(''), toastVisible = ref(false)
const showEditInfo = ref(false), editForm = ref({ diaChi:'', ghiChu:'' }), savingInfo = ref(false)
const showEditItems = ref(false), editItems = ref([]), savingItems = ref(false)
const showQROverlay = ref(false), qrOrderId = ref(null), qrCountdown = ref(300)
let pollingTimer = null, countdownTimer = null

const tabs = [
  { value:'all', label:'Tất Cả' },
  { value:'cho_thanh_toan', label:'💳 Chờ Thanh Toán' },
  { value:'cho_xac_nhan',   label:'Chờ Xác Nhận' },
  { value:'dang_chuan_bi',  label:'Đang Chuẩn Bị' },
  { value:'dang_giao',      label:'Đang Giao' },
  { value:'hoan_thanh',     label:'Hoàn Thành' },
  { value:'da_huy',         label:'Đã Hủy' },
]
const progressSteps = [
    { value:'cho_thanh_toan', icon:'💳', label:'Chờ TT' },
  { value:'cho_xac_nhan', icon:'⏳', label:'Chờ XN' },
  { value:'dang_chuan_bi', icon:'👨‍🍳', label:'Chuẩn Bị' },
  { value:'dang_giao', icon:'🛵', label:'Đang Giao' },
  { value:'hoan_thanh', icon:'✅', label:'Hoàn Thành' },
]
const stepIdx = computed(() => { const i = progressSteps.findIndex(s => s.value === selectedOrder.value?.trangThai); return i === -1 ? 0 : i })
const filteredOrders = computed(() => activeTab.value === 'all' ? orders.value : orders.value.filter(o => o.trangThai === activeTab.value))
const editItemsSubtotal = computed(() => editItems.value.reduce((s,i) => s+i.gia*i.soLuong, 0))
const qrUrl = computed(() => !qrOrderId.value ? '' : `https://qr.sepay.vn/img?acc=10002998539&bank=TPBank&amount=0&des=${encodeURIComponent('FASTFOOD HD'+qrOrderId.value)}&template=compact`)

function canEdit(hd) { return hd.trangThai === 'cho_thanh_toan' || hd.trangThai === 'cho_xac_nhan' }
function countByStatus(s) { return s === 'all' ? 0 : orders.value.filter(o => o.trangThai === s).length }
function pad(id) { return String(id).padStart(4,'0') }
function fmt(n) { return Number(n||0).toLocaleString('vi') + 'đ' }
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('vi') : '—' }
function fmtCountdown(s) { return `${Math.floor(s/60)}:${String(s%60).padStart(2,'0')}` }
function discountAmt(hd) { if (!hd.khuyenMai) return 0; const sub = (hd.chiTietHoaDons||[]).reduce((s,ct)=>s+ct.donGia*ct.soLuong,0); return Math.round(sub*hd.khuyenMai.phanTramGiam/100) }
function payLabel(p) { return { tien_mat:'💵 Tiền Mặt', the:'💳 Thẻ', qr:'📱 QR / Ví' }[p] || p || '—' }
function statusLabel(s) { return { cho_thanh_toan:'💳 Chờ TT', cho_xac_nhan:'⏳ Chờ XN', dang_chuan_bi:'👨‍🍳 Chuẩn Bị', dang_giao:'🛵 Đang Giao', hoan_thanh:'✅ Hoàn Thành', da_huy:'❌ Đã Hủy' }[s] || s }
function statusClass(s) { return { cho_thanh_toan:'awaiting-pay', cho_xac_nhan:'pending', dang_chuan_bi:'preparing', dang_giao:'delivering', hoan_thanh:'done', da_huy:'cancelled' }[s] || '' }
function showToast(msg) { toastMsg.value = msg; toastVisible.value = true; setTimeout(()=>toastVisible.value=false,2500) }
function openDetail(hd) { selectedOrder.value = hd }
async function cancelOrder(hd) {
  if (!confirm(`Huỷ đơn #${pad(hd.id)}?`)) return
  cancelling.value = true
  try { await hoaDonAPI.updateStatus(hd.id,'da_huy'); hd.trangThai='da_huy'; selectedOrder.value={...hd}; showToast('❌ Đã huỷ đơn') } catch { showToast('Huỷ thất bại') } finally { cancelling.value = false }
}
function openEditInfo(hd) { editForm.value={diaChi:hd.diaChi||'',ghiChu:hd.ghiChu||''}; showEditInfo.value=true }
async function saveInfo() {
  savingInfo.value = true
  try {
    const res = await hoaDonAPI.updateInfo(selectedOrder.value.id, editForm.value)
    const u = res.data.data
    selectedOrder.value.diaChi = u.diaChi; selectedOrder.value.ghiChu = u.ghiChu
    const idx = orders.value.findIndex(o=>o.id===selectedOrder.value.id)
    if (idx!==-1) { orders.value[idx].diaChi=u.diaChi; orders.value[idx].ghiChu=u.ghiChu }
    showEditInfo.value = false; showToast('✅ Đã cập nhật thông tin!')
  } catch(e) { showToast('❌ '+(e.response?.data?.message||'Lỗi')) } finally { savingInfo.value=false }
}
function openEditItems(hd) {
  editItems.value = (hd.chiTietHoaDons||[]).map(ct=>({ monAnId:ct.monAn?.id, tenMon:ct.monAn?.tenMon||'', gia:ct.donGia||ct.monAn?.gia||0, soLuong:ct.soLuong }))
  showEditItems.value = true
}
function changeEditQty(idx,d) { editItems.value[idx].soLuong+=d; if(editItems.value[idx].soLuong<=0) editItems.value.splice(idx,1) }
async function saveItems() {
  if (!editItems.value.length) return
  savingItems.value = true
  try {
    const items = editItems.value.map(i=>({monAnId:i.monAnId,soLuong:i.soLuong}))
    const res = await hoaDonAPI.updateItems(selectedOrder.value.id, items)
    const u = res.data.data
    selectedOrder.value.chiTietHoaDons = u.chiTietHoaDons; selectedOrder.value.tongTien = u.tongTien
    const idx = orders.value.findIndex(o=>o.id===selectedOrder.value.id)
    if (idx!==-1) orders.value[idx]={...orders.value[idx],...u}
    showEditItems.value = false; showToast('✅ Đã cập nhật món!')
  } catch(e) { showToast('❌ '+(e.response?.data?.message||'Lỗi')) } finally { savingItems.value=false }
}
function openQR(hd) { qrOrderId.value=hd.id; qrCountdown.value=300; showQROverlay.value=true; selectedOrder.value=null; startQRPolling(hd.id); startQRCountdown() }
function closeQR() { stopQRTimers(); showQROverlay.value=false }
function startQRPolling(id) {
  pollingTimer = setInterval(async()=>{
    try {
      const r = await hoaDonAPI.getById(id); const hd=r.data.data
      if (hd.trangThai==='cho_xac_nhan'||hd.trangThai==='hoan_thanh') {
        stopQRTimers(); showQROverlay.value=false
        const idx=orders.value.findIndex(o=>o.id===id); if(idx!==-1) orders.value[idx]=hd
        showToast('✅ Thanh toán xác nhận thành công!')
      }
    } catch {}
  }, 3000)
}
function startQRCountdown() { countdownTimer=setInterval(()=>{ if(--qrCountdown.value<=0) stopQRTimers() },1000) }
function stopQRTimers() { if(pollingTimer){clearInterval(pollingTimer);pollingTimer=null} if(countdownTimer){clearInterval(countdownTimer);countdownTimer=null} }
async function mockDoneQR() {
  stopQRTimers()
  try { await hoaDonAPI.xacNhanThanhToan(qrOrderId.value); showQROverlay.value=false; await loadOrders(); showToast('✅ Xác nhận thành công! Đơn chuyển sang Chờ Xác Nhận.') } catch { showToast('❌ Lỗi xác nhận') }
}
async function loadOrders() { const res=await hoaDonAPI.getAll(); orders.value=res.data.data }
onMounted(async()=>{ try{await loadOrders()}catch(e){console.error(e)}finally{loading.value=false} })
onUnmounted(stopQRTimers)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');
.page{min-height:100vh;background:#0e0a0a;color:#f5ede6;padding:100px 0 60px;position:relative;font-family:'Nunito',sans-serif}
.grain{position:fixed;inset:0;z-index:0;pointer-events:none;opacity:.025;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-size:180px}
.container{max-width:800px;margin:0 auto;padding:0 24px;position:relative}
.page-label{font-size:.72rem;font-weight:900;letter-spacing:.25em;text-transform:uppercase;color:#e8273a;margin-bottom:8px}
.page-title{font-family:'Bebas Neue',sans-serif;font-size:clamp(2rem,5vw,3rem);letter-spacing:.04em;color:#fff;margin-bottom:28px}
.page-title span{color:#ffcc00}
.status-tabs{display:flex;gap:6px;margin-bottom:24px;flex-wrap:wrap}
.status-tab{padding:8px 16px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.78rem;font-weight:800;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(245,237,230,.5);cursor:pointer;transition:all .2s;display:flex;align-items:center;gap:6px}
.status-tab:hover,.status-tab.active{background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.3);color:#e8273a}
.tab-count{width:18px;height:18px;background:#e8273a;border-radius:50%;font-size:.65rem;font-weight:900;color:#fff;display:flex;align-items:center;justify-content:center}
.order-list{display:flex;flex-direction:column;gap:14px}
.order-card{background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:18px 20px;cursor:pointer;transition:all .25s}
.order-card:hover{border-color:rgba(232,39,58,.25);transform:translateX(4px);box-shadow:0 8px 20px rgba(0,0,0,.4)}
.order-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px}
.id-label{font-size:.68rem;font-weight:900;letter-spacing:.12em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-right:6px}
.id-val{font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.08em;color:#fff}
.pay-alert{background:rgba(255,204,0,.07);border:1px solid rgba(255,204,0,.2);border-radius:9px;padding:8px 12px;font-size:.76rem;font-weight:700;color:#ffcc00;display:flex;align-items:center;gap:8px;margin-bottom:10px;cursor:pointer;transition:background .2s}
.pay-alert:hover{background:rgba(255,204,0,.12)}
.pay-alert-arrow{margin-left:auto}
.order-items-preview{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:12px}
.item-chip{padding:3px 10px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50px;font-size:.7rem;font-weight:700;color:rgba(245,237,230,.6)}
.item-chip.more{background:rgba(232,39,58,.1);border-color:rgba(232,39,58,.2);color:#e8273a}
.order-footer{display:flex;align-items:center;gap:12px}
.order-date{font-size:.75rem;font-weight:600;color:rgba(245,237,230,.4);flex:1}
.order-total{font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.04em;color:#ffcc00}
.order-arrow{color:rgba(245,237,230,.2);font-size:1rem}
.order-card:hover .order-arrow{color:#e8273a}
.status-badge{padding:4px 12px;border-radius:50px;font-size:.7rem;font-weight:900;letter-spacing:.06em;text-transform:uppercase}
.status-badge.sm{padding:3px 9px;font-size:.64rem}
.awaiting-pay{background:rgba(255,204,0,.15);color:#ffcc00;border:1px solid rgba(255,204,0,.3)}
.pending{background:rgba(251,146,60,.12);color:#fb923c;border:1px solid rgba(251,146,60,.2)}
.preparing{background:rgba(96,165,250,.12);color:#60a5fa;border:1px solid rgba(96,165,250,.2)}
.delivering{background:rgba(167,139,250,.12);color:#a78bfa;border:1px solid rgba(167,139,250,.2)}
.done{background:rgba(74,222,128,.12);color:#4ade80;border:1px solid rgba(74,222,128,.2)}
.cancelled{background:rgba(248,113,113,.1);color:#f87171;border:1px solid rgba(248,113,113,.2)}
.overlay{position:fixed;inset:0;background:rgba(0,0,0,.8);backdrop-filter:blur(10px);z-index:600;display:none;align-items:flex-start;justify-content:center;overflow-y:auto;padding:24px}
.overlay.open{display:flex}
.detail-modal{background:#130a0a;border:1px solid rgba(232,39,58,.2);border-radius:22px;width:100%;max-width:660px;margin:auto}
.dm-head{display:flex;align-items:flex-start;justify-content:space-between;padding:22px 24px 0}
.dm-label{font-size:.68rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:#e8273a;margin-bottom:4px}
.dm-id{font-family:'Bebas Neue',sans-serif;font-size:2.2rem;letter-spacing:.06em;color:#fff;line-height:1}
.dm-head-r{display:flex;align-items:center;gap:10px}
.dm-close{width:30px;height:30px;border-radius:50%;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:.85rem;color:#f5ede6}
.dm-close:hover{background:rgba(232,39,58,.2)}
.qr-pending-banner{display:flex;align-items:center;gap:14px;background:rgba(255,204,0,.07);border:1px solid rgba(255,204,0,.18);border-radius:12px;padding:14px 18px;margin:16px 24px;flex-wrap:wrap}
.qpb-icon{font-size:1.8rem;flex-shrink:0}
.qpb-title{font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.06em;color:#ffcc00;margin-bottom:3px}
.qpb-sub{font-size:.75rem;color:rgba(245,237,230,.5);font-weight:600}
.btn-pay-now{padding:9px 18px;background:#ffcc00;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.78rem;font-weight:900;color:#0e0a0a;cursor:pointer;transition:all .2s;white-space:nowrap;flex-shrink:0;margin-left:auto}
.btn-pay-now:hover{background:#e6b800}
.progress-wrap{display:flex;align-items:flex-start;justify-content:center;padding:20px 24px;gap:0}
.progress-step{display:flex;flex-direction:column;align-items:center;position:relative;flex:1}
.ps-dot{width:40px;height:40px;border-radius:50%;background:rgba(255,255,255,.08);border:2px solid rgba(255,255,255,.12);display:flex;align-items:center;justify-content:center;font-size:1rem;z-index:2;transition:all .3s}
.ps-dot.done{background:rgba(232,39,58,.2);border-color:#e8273a}
.ps-dot.current{background:rgba(232,39,58,.3);border-color:#e8273a;box-shadow:0 0 0 4px rgba(232,39,58,.2)}
.ps-label{font-size:.58rem;font-weight:900;letter-spacing:.08em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-top:6px;text-align:center}
.ps-label.active{color:#e8273a}
.ps-line-left,.ps-line-right{position:absolute;top:20px;height:2px;width:50%;background:rgba(255,255,255,.08);transition:background .3s}
.ps-line-left{left:0;transform:translateX(-50%)}
.ps-line-right{right:0;transform:translateX(50%)}
.ps-line-left.done,.ps-line-right.done{background:#e8273a}
.dm-info-section,.dm-items-section{padding:0 24px 16px}
.dm-info-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px}
.dm-section-title{font-family:'Bebas Neue',sans-serif;font-size:.95rem;letter-spacing:.1em;color:rgba(245,237,230,.5);text-transform:uppercase}
.btn-edit-info{padding:5px 14px;background:rgba(255,204,0,.1);border:1px solid rgba(255,204,0,.25);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.72rem;font-weight:900;color:#ffcc00;cursor:pointer;transition:all .2s}
.btn-edit-info:hover{background:rgba(255,204,0,.2)}
.edit-warning{background:rgba(251,146,60,.08);border:1px solid rgba(251,146,60,.2);border-radius:8px;padding:7px 11px;font-size:.72rem;font-weight:700;color:#fb923c;margin-bottom:10px}
.edit-warning.mb{margin:0 0 14px}
.info-grid{background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:12px;padding:12px}
.ig-row{display:flex;justify-content:space-between;font-size:.8rem;font-weight:700;color:rgba(245,237,230,.55);padding:5px 0;border-bottom:1px solid rgba(255,255,255,.04)}
.ig-row:last-child{border-bottom:none}
.ig-row span:last-child{color:#f5ede6;text-align:right;max-width:60%}
.item-row{display:flex;align-items:center;gap:10px;padding:9px 0;border-bottom:1px solid rgba(255,255,255,.05)}
.item-row:last-child{border-bottom:none}
.item-img{width:42px;height:42px;border-radius:9px;object-fit:cover;flex-shrink:0}
.item-img-ph{background:rgba(255,255,255,.06);display:flex;align-items:center;justify-content:center;font-size:1.3rem}
.item-info{flex:1}
.item-name{font-size:.82rem;font-weight:800;color:#f5ede6}
.item-unit{font-size:.68rem;color:rgba(245,237,230,.4);font-weight:600}
.item-qty{font-size:.8rem;font-weight:800;color:rgba(245,237,230,.5);min-width:28px;text-align:center}
.item-total{font-family:'Bebas Neue',sans-serif;font-size:.95rem;letter-spacing:.04em;color:#ffcc00;min-width:80px;text-align:right}
.dm-footer{padding:12px 24px 16px;border-top:1px solid rgba(255,255,255,.07)}
.dm-row{display:flex;justify-content:space-between;margin-bottom:6px}
.dm-row.sub{font-size:.78rem;font-weight:700;color:rgba(245,237,230,.5)}
.dm-row.total{margin-top:8px;padding-top:8px;border-top:1px solid rgba(255,255,255,.08)}
.dm-row.total span:first-child{font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.1em;color:#fff}
.total-amt{font-family:'Bebas Neue',sans-serif;font-size:1.4rem;letter-spacing:.04em;color:#ffcc00}
.dm-actions{padding:0 24px 20px}
.btn-cancel-order{width:100%;padding:10px;background:rgba(248,113,113,.08);border:1px solid rgba(248,113,113,.2);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#f87171;cursor:pointer;transition:all .2s}
.btn-cancel-order:hover:not(:disabled){background:rgba(248,113,113,.18)}
.btn-cancel-order:disabled{opacity:.4;cursor:not-allowed}
.edit-modal{background:#130a0a;border:1px solid rgba(255,204,0,.18);border-radius:20px;width:100%;max-width:500px;margin:auto}
.edit-modal.wide{max-width:600px}
.edit-modal-head{display:flex;align-items:center;justify-content:space-between;padding:20px 22px 0}
.edit-modal-title{font-family:'Bebas Neue',sans-serif;font-size:1.3rem;letter-spacing:.06em;color:#fff}
.edit-modal-title span{color:#ffcc00}
.edit-body{padding:14px 22px}
.fgroup{display:flex;flex-direction:column;gap:5px;margin-bottom:14px}
.fgroup label{font-size:.68rem;font-weight:900;letter-spacing:.14em;text-transform:uppercase;color:rgba(245,237,230,.5)}
.finput{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:11px;padding:10px 13px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:600;outline:none;transition:border-color .2s;width:100%}
.finput:focus{border-color:rgba(255,204,0,.4)}
.ftextarea{resize:vertical;min-height:70px}
.edit-footer{display:flex;gap:8px;padding:0 22px 20px;justify-content:flex-end}
.btn-cancel-e{padding:9px 18px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:50px;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:800;color:rgba(245,237,230,.6);cursor:pointer}
.btn-save-e{padding:9px 18px;background:#e8273a;border:none;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:900;color:#fff;cursor:pointer;transition:all .2s}
.btn-save-e:hover:not(:disabled){background:#b8001a}
.btn-save-e:disabled{opacity:.4;cursor:not-allowed}
.edit-item-row{display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid rgba(255,255,255,.05)}
.ei-name{flex:1;font-size:.82rem;font-weight:800;color:#f5ede6}
.ei-price{font-size:.78rem;color:rgba(245,237,230,.4);font-weight:600;min-width:70px;text-align:right}
.ei-qty-ctrl{display:flex;align-items:center;gap:6px}
.qty-b{width:22px;height:22px;border-radius:50%;background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.1);color:#f5ede6;font-size:.85rem;cursor:pointer;display:flex;align-items:center;justify-content:center}
.qty-b:hover{background:rgba(232,39,58,.2)}
.qty-n{font-family:'Bebas Neue',sans-serif;font-size:.95rem;color:#ffcc00;min-width:20px;text-align:center}
.ei-total{font-family:'Bebas Neue',sans-serif;font-size:.9rem;color:#ffcc00;min-width:70px;text-align:right}
.ei-del{background:rgba(248,113,113,.08);border:1px solid rgba(248,113,113,.15);border-radius:7px;width:26px;height:26px;display:flex;align-items:center;justify-content:center;font-size:.7rem;cursor:pointer;color:#f87171}
.edit-empty{text-align:center;padding:20px;color:rgba(245,237,230,.3);font-size:.82rem;font-weight:600}
.edit-total-row{display:flex;justify-content:space-between;padding:10px 0 0;border-top:1px solid rgba(255,255,255,.08);margin-top:8px;font-size:.8rem;font-weight:700;color:rgba(245,237,230,.5)}
.edit-total-val{font-family:'Bebas Neue',sans-serif;font-size:1.1rem;color:#ffcc00}
.qr-overlay{position:fixed;inset:0;background:rgba(0,0,0,.85);backdrop-filter:blur(12px);z-index:700;display:flex;align-items:center;justify-content:center;padding:16px}
.qr-card{background:#0d0707;border:1px solid rgba(255,204,0,.2);border-radius:22px;padding:28px 24px;max-width:380px;width:100%;text-align:center}
.qr-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px}
.qr-title{font-family:'Bebas Neue',sans-serif;font-size:1.4rem;letter-spacing:.06em;color:#fff}
.qr-title span{color:#ffcc00}
.qr-label{font-size:.76rem;color:rgba(245,237,230,.5);font-weight:700;margin-bottom:4px}
.qr-content{font-family:'Bebas Neue',sans-serif;font-size:1.2rem;letter-spacing:.08em;color:#ffcc00;margin-bottom:14px}
.qr-img-wrap{background:#fff;border-radius:12px;padding:8px;display:inline-block;margin-bottom:14px}
.qr-img{width:190px;height:190px;display:block}
.qr-timer{margin-bottom:10px}
.qr-timer span{font-size:.72rem;color:rgba(245,237,230,.4);font-weight:700;display:block;margin-top:4px}
.timer-bar-wrap{height:4px;background:rgba(255,255,255,.08);border-radius:2px;overflow:hidden}
.timer-bar{height:100%;background:linear-gradient(90deg,#e8273a,#ffcc00);border-radius:2px;transition:width 1s linear}
.qr-status{display:flex;align-items:center;justify-content:center;gap:8px;font-size:.76rem;color:rgba(245,237,230,.4);font-weight:600;margin-bottom:8px}
.qr-pulse{width:8px;height:8px;border-radius:50%;background:#ffcc00;animation:pulse-qr 1.2s ease-in-out infinite}
@keyframes pulse-qr{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.3;transform:scale(.7)}}
.qr-bank-info{font-size:.72rem;color:rgba(245,237,230,.3);font-weight:600;margin-bottom:16px;line-height:1.6}
.qr-actions{display:flex;flex-direction:column;gap:8px}
.btn-qr-done{width:100%;padding:11px;background:rgba(74,222,128,.15);border:1px solid rgba(74,222,128,.3);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:800;color:#4ade80;cursor:pointer;transition:all .2s}
.btn-qr-done:hover{background:rgba(74,222,128,.25)}
.skeleton-row{background:rgba(255,255,255,.04);border-radius:16px;height:120px;margin-bottom:14px;animation:pulse 1.5s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.7}}
.loading-list{margin-top:8px}
.empty-state{text-align:center;padding:80px 20px}
.empty-icon{font-size:4rem;margin-bottom:16px;opacity:.3}
.empty-state p{color:rgba(245,237,230,.5);font-size:.95rem;font-weight:600;margin-bottom:20px}
.btn-order-now{display:inline-block;padding:12px 28px;background:#e8273a;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:900;color:#fff;text-decoration:none}
.toast{position:fixed;bottom:26px;right:26px;z-index:999;background:rgba(14,10,10,.95);border:1px solid rgba(255,255,255,.1);backdrop-filter:blur(12px);border-radius:13px;padding:12px 18px;font-size:.84rem;font-weight:700;color:#f5ede6;transform:translateX(120%);transition:transform .4s cubic-bezier(.34,1.56,.64,1);min-width:200px;font-family:'Nunito',sans-serif}
.toast.show{transform:translateX(0)}
</style>