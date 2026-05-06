<template>
  <div class="admin-layout">
    <AdminSidebar active="dashboard" />
    <div class="main-wrap">
      <AdminTopbar title="Admin" highlight="Dashboard" />
      <div class="content">

        <!-- Stats tổng quan -->
        <div class="stats-row">
          <div class="stat-card" v-for="s in summaryStats" :key="s.label">
            <span class="stat-emoji">{{ s.emoji }}</span>
            <div class="stat-label">{{ s.label }}</div>
            <div class="stat-val" :class="s.color">
              <span v-if="loading">—</span>
              <span v-else>{{ s.val }}</span>
            </div>
            <div class="stat-sub">{{ s.sub }}</div>
          </div>
        </div>
<div class="period-tabs">
  <button v-for="p in periods" :key="p.value"
    class="period-tab" :class="{ active: period === p.value }"
    @click="period = p.value; loadData()">
    {{ p.label }}
  </button>
</div>
        <div class="dash-grid">
          <!-- Hóa đơn theo trạng thái -->
          <div class="dash-card">
            <div class="dash-card-title">Hóa Đơn <span>Hôm Nay</span></div>
            <div v-if="loading" class="dash-loading">
              <div v-for="n in 5" :key="n" class="skeleton-row"></div>
            </div>
            <div v-else class="status-list">
              <div v-for="(count, status) in thongKe.hoaDonTheoTrangThai" :key="status" class="status-item">
                <div :class="['status-dot', statusDotClass(status)]"></div>
                <div class="status-name">{{ statusLabel(status) }}</div>
                <div class="status-count">{{ count }}</div>
                <div class="status-bar">
                  <div
                    class="status-bar-fill"
                    :class="statusDotClass(status)"
                    :style="{ width: barPct(count) + '%' }"
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Doanh thu 7 ngày -->
          <div class="dash-card">
            <div class="dash-card-title">Doanh Thu <span>7 Ngày</span></div>
            <div v-if="loading" class="dash-loading">
              <div v-for="n in 7" :key="n" class="skeleton-row" style="height:36px"></div>
            </div>
            <div v-else-if="!thongKe.doanhThu7Ngay?.length" class="dash-empty">Chưa có dữ liệu</div>
            <div v-else class="revenue-bars">
              <div v-for="row in thongKe.doanhThu7Ngay" :key="row[0]" class="rev-row">
                <div class="rev-date">{{ fmtDate(row[0]) }}</div>
                <div class="rev-bar-wrap">
                  <div class="rev-bar" :style="{ width: revPct(row[1]) + '%' }"></div>
                </div>
                <div class="rev-amt">{{ fmtAmt(row[1]) }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick actions -->
        <div class="quick-actions">
          <div class="qa-title">Thao Tác Nhanh</div>
          <div class="qa-grid">
            <router-link to="/admin/mon-an"    class="qa-card"><span>🍔</span>Quản Lý Món Ăn</router-link>
            <router-link to="/admin/voucher"   class="qa-card"><span>🎟️</span>Quản Lý Voucher</router-link>
            <router-link to="/admin/nhan-vien" class="qa-card"><span>👥</span>Quản Lý Nhân Viên</router-link>
            <router-link to="/admin/hoa-don"   class="qa-card"><span>📋</span>Danh Sách Đơn</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import AdminSidebar from '../../components/admin/AdminSidebar.vue'
import AdminTopbar  from '../../components/admin/AdminTopbar.vue'
import { thongKeAPI } from '../../services/api'

const thongKe = ref({})
const loading = ref(true)

const summaryStats = computed(() => [
  { emoji:'📋', label:'Tổng Hóa Đơn',  val: thongKe.value.tongHoaDon  ?? '—', color:'',       sub:'Kể từ đầu' },
  { emoji:'💰', label:'Doanh Thu',      val: fmtAmt(thongKe.value.tongDoanhThu), color:'yellow', sub:'Tổng cộng' },
  { emoji:'🍔', label:'Tổng Món Ăn',   val: thongKe.value.tongMonAn    ?? '—', color:'red',    sub:'Trong menu' },
  { emoji:'👥', label:'Người Dùng',     val: thongKe.value.tongNguoiDung?? '—', color:'',       sub:'Đã đăng ký' },
])
const period = ref('tuan')
const periods = [
  { value:'tuan',  label:'7 Ngày' },
  { value:'thang', label:'30 Ngày' },
  { value:'nam',   label:'12 Tháng' },
]

// Sửa onMounted và thêm loadData function
async function loadData() {
  loading.value = true
  try {
    const res = await thongKeAPI.get(period.value)
    thongKe.value = res.data.data
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}
onMounted(loadData)
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('vi',{day:'2-digit',month:'2-digit'}) : '' }
function fmtAmt(n)  { if (!n) return '0đ'; return n >= 1e6 ? (n/1e6).toFixed(1)+'M đ' : Number(n).toLocaleString('vi')+'đ' }

function statusLabel(s) {
  return { cho_xac_nhan:'Chờ xác nhận', dang_chuan_bi:'Đang chuẩn bị', dang_giao:'Đang giao', hoan_thanh:'Hoàn thành', da_huy:'Đã huỷ' }[s] || s
}
function statusDotClass(s) {
  return { cho_xac_nhan:'amber', dang_chuan_bi:'blue', dang_giao:'purple', hoan_thanh:'green', da_huy:'red' }[s] || 'gray'
}
function barPct(count) {
  const all = Object.values(thongKe.value.hoaDonTheoTrangThai || {})
  const max = Math.max(...all, 1)
  return Math.round((count/max)*100)
}
function revPct(amt) {
  const rows = thongKe.value.doanhThu7Ngay || []
  const max = Math.max(...rows.map(r=>Number(r[1])), 1)
  return Math.round((Number(amt)/max)*100)
}

onMounted(async () => {
  try { const res = await thongKeAPI.get(); thongKe.value = res.data.data }
  catch (e) { console.error(e) }
  finally { loading.value = false }
})
</script>

<style>
.period-tabs { display:flex;gap:8px;margin-bottom:16px; }
.period-tab { padding:7px 16px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.76rem;font-weight:800;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(245,237,230,.5);cursor:pointer;transition:all .2s; }
.period-tab.active,.period-tab:hover { background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.3);color:#e8273a; }
.dash-grid { display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px; }
.dash-card { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:20px; }
.dash-card-title { font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.08em;color:#fff;margin-bottom:16px; }
.dash-card-title span { color:#ffcc00; }
.dash-loading { display:flex;flex-direction:column;gap:8px; }
.dash-empty { color:rgba(245,237,230,.4);font-size:.84rem;font-weight:600;text-align:center;padding:20px; }
.status-list { display:flex;flex-direction:column;gap:10px; }
.status-item { display:flex;align-items:center;gap:8px; }
.status-dot { width:8px;height:8px;border-radius:50%;flex-shrink:0; }
.status-dot.amber  { background:#fb923c; }
.status-dot.blue   { background:#60a5fa; }
.status-dot.purple { background:#a78bfa; }
.status-dot.green  { background:#4ade80; }
.status-dot.red    { background:#f87171; }
.status-dot.gray   { background:rgba(245,237,230,.3); }
.status-name { font-size:.78rem;font-weight:700;color:rgba(245,237,230,.7);flex:1;white-space:nowrap; }
.status-count { font-family:'Bebas Neue',sans-serif;font-size:.95rem;color:#fff;min-width:28px;text-align:right; }
.status-bar { flex:1;height:5px;background:rgba(255,255,255,.07);border-radius:3px;overflow:hidden; }
.status-bar-fill { height:100%;border-radius:3px;transition:width .6s ease; }
.status-bar-fill.amber  { background:#fb923c; }
.status-bar-fill.blue   { background:#60a5fa; }
.status-bar-fill.purple { background:#a78bfa; }
.status-bar-fill.green  { background:#4ade80; }
.status-bar-fill.red    { background:#f87171; }
.revenue-bars { display:flex;flex-direction:column;gap:8px; }
.rev-row { display:flex;align-items:center;gap:8px; }
.rev-date { font-size:.7rem;font-weight:700;color:rgba(245,237,230,.5);width:46px;flex-shrink:0; }
.rev-bar-wrap { flex:1;height:12px;background:rgba(255,255,255,.06);border-radius:6px;overflow:hidden; }
.rev-bar { height:100%;background:linear-gradient(90deg,#e8273a,#ffcc00);border-radius:6px;transition:width .6s ease; }
.rev-amt { font-size:.7rem;font-weight:800;color:#ffcc00;min-width:55px;text-align:right; }
.quick-actions { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:20px; }
.qa-title { font-family:'Bebas Neue',sans-serif;font-size:1.05rem;letter-spacing:.08em;color:rgba(245,237,230,.5);margin-bottom:14px; }
.qa-grid { display:grid;grid-template-columns:repeat(4,1fr);gap:10px; }
.qa-card { display:flex;flex-direction:column;align-items:center;gap:8px;padding:18px 10px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);border-radius:13px;text-decoration:none;font-size:.78rem;font-weight:800;letter-spacing:.04em;color:rgba(245,237,230,.6);transition:all .2s;text-transform:uppercase; }
.qa-card span { font-size:1.6rem; }
.qa-card:hover { background:rgba(232,39,58,.1);border-color:rgba(232,39,58,.25);color:#f5ede6;transform:translateY(-2px); }
@media(max-width:800px){ .dash-grid{grid-template-columns:1fr} .qa-grid{grid-template-columns:repeat(2,1fr)} }
</style>