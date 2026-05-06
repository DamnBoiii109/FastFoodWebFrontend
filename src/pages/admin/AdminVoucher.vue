<template>
  <div class="admin-layout">
    <AdminSidebar active="voucher" />
    <div class="main-wrap">
      <AdminTopbar title="Quản Lý" highlight="Voucher" />
      <div class="content">

        <!-- Stats -->
        <div class="stats-row">
          <div class="stat-card"><span class="stat-emoji">🎟️</span><div class="stat-label">Tổng Voucher</div><div class="stat-val">{{ items.length }}</div><div class="stat-sub">Trong hệ thống</div></div>
          <div class="stat-card"><span class="stat-emoji">✅</span><div class="stat-label">Đang Hoạt Động</div><div class="stat-val green">{{ items.filter(v=>v.trangThai).length }}</div><div class="stat-sub">Đã kích hoạt</div></div>
          <div class="stat-card"><span class="stat-emoji">⏸</span><div class="stat-label">Hết Hạn / Dừng</div><div class="stat-val">{{ items.filter(v=>!v.trangThai).length }}</div><div class="stat-sub">Cần kiểm tra</div></div>
          <div class="stat-card"><span class="stat-emoji">💰</span><div class="stat-label">Tổng Lượt Dùng</div><div class="stat-val yellow">—</div><div class="stat-sub">Theo kỳ</div></div>
        </div>

        <!-- Toolbar -->
        <div class="toolbar">
          <div class="toolbar-left">
            <button class="filter-btn" :class="{active:filter==='all'}"    @click="filter='all'">Tất Cả ({{ items.length }})</button>
            <button class="filter-btn" :class="{active:filter==='active'}" @click="filter='active'">Đang Chạy</button>
            <button class="filter-btn" :class="{active:filter==='off'}"    @click="filter='off'">Hết Hạn/Dừng</button>
          </div>
          <button class="btn-primary" @click="openModal()">＋ Tạo Voucher Mới</button>
        </div>

        <!-- Voucher Cards -->
        <div v-if="loading" class="vc-grid">
          <div v-for="n in 4" :key="n" class="skeleton-card"></div>
        </div>

        <div v-else-if="filteredItems.length === 0" class="table-empty">
          <span>🎟️</span> Không có voucher nào
        </div>

        <div v-else class="vc-grid">
          <div
            v-for="v in filteredItems"
            :key="v.id"
            class="vc-card"
            :class="{ expired: !v.trangThai }"
          >
            <div class="vc-top">
              <div class="vc-type">Giảm {{ v.phanTramGiam }}%</div>
              <div class="vc-code">{{ v.tenKhuyenMai }}</div>
              <div :class="['vc-status', v.trangThai ? 'vc-on' : 'vc-off']">
                {{ v.trangThai ? '● Đang Chạy' : '⏸ Dừng' }}
              </div>
              <div class="vc-bg-pct">{{ v.phanTramGiam }}%</div>
            </div>
            <div class="vc-divider"></div>
            <div class="vc-bottom">
              <div class="vc-meta">
                <div class="vc-meta-row">Còn lại: <span>{{ v.soLuong ?? '∞' }} lượt</span></div>
                <div class="vc-meta-row">Hết hạn: <span>{{ fmtDate(v.ngayKetThuc) }}</span></div>
              </div>
              <div class="row-actions">
                <button class="act-btn" @click="openModal(v)">✏️</button>
                <button class="act-btn del" @click="deleteItem(v)">🗑️</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div class="modal-overlay" :class="{ open: modalOpen }" @click.self="closeModal">
      <div class="modal">
        <div class="modal-head">
          <div class="modal-title">{{ editItem ? 'Chỉnh Sửa' : 'Tạo' }} <span>Voucher</span></div>
          <button class="modal-close" @click="closeModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Mã Voucher (Tên)</label>
            <div class="input-gen">
              <input v-model="form.tenKhuyenMai" class="finput" placeholder="VD: SUMMER25" style="text-transform:uppercase;flex:1">
              <button class="btn-gen" @click="genCode">⚡ Tự Tạo</button>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Phần Trăm Giảm (%)</label>
              <input v-model.number="form.phanTramGiam" type="number" min="0" max="100" class="finput" placeholder="20">
            </div>
            <div class="form-group">
              <label>Số Lượt Dùng Tối Đa</label>
              <input v-model.number="form.soLuong" type="number" class="finput" placeholder="500 (bỏ trống = không giới hạn)">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Ngày Bắt Đầu</label>
              <input v-model="form.ngayBatDau" type="datetime-local" class="finput">
            </div>
            <div class="form-group">
              <label>Ngày Kết Thúc</label>
              <input v-model="form.ngayKetThuc" type="datetime-local" class="finput">
            </div>
          </div>
          <div class="form-group">
            <label>Trạng Thái</label>
            <select v-model="form.trangThai" class="finput">
              <option :value="true">● Kích Hoạt</option>
              <option :value="false">⏸ Tạm Dừng</option>
            </select>
          </div>
          <div v-if="formError" class="form-error">{{ formError }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">Huỷ</button>
          <button class="btn-primary" @click="saveItem" :disabled="saving">
            {{ saving ? '⏳...' : '🎟️ Lưu Voucher' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useToastStore } from '../../stores/toast'
import AdminSidebar from '../../components/admin/AdminSidebar.vue'
import AdminTopbar  from '../../components/admin/AdminTopbar.vue'
import Toast        from '../../components/Toast.vue'
import { khuyenMaiAPI } from '../../services/api'

const items     = ref([])
const toast     = useToastStore()
const loading   = ref(true)
const filter    = ref('all')
const modalOpen = ref(false)
const editItem  = ref(null)
const saving    = ref(false)
const formError = ref('')

const blankForm = () => ({ tenKhuyenMai:'', phanTramGiam:20, soLuong:null, trangThai:true, ngayBatDau:'', ngayKetThuc:'' })
const form = ref(blankForm())

const filteredItems = computed(() => {
  if (filter.value === 'active') return items.value.filter(v => v.trangThai)
  if (filter.value === 'off')    return items.value.filter(v => !v.trangThai)
  return items.value
})

function fmtDate(d) { return d ? new Date(d).toLocaleDateString('vi') : '∞' }


function genCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let code = 'YUMMY'
  for (let i=0;i<4;i++) code += chars[Math.floor(Math.random()*chars.length)]
  form.value.tenKhuyenMai = code
}

function toLocalDT(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const pad = n => String(n).padStart(2,'0')
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function openModal(item = null) {
  editItem.value = item; formError.value = ''
  form.value = item
    ? { tenKhuyenMai:item.tenKhuyenMai, phanTramGiam:item.phanTramGiam, soLuong:item.soLuong, trangThai:item.trangThai, ngayBatDau:toLocalDT(item.ngayBatDau), ngayKetThuc:toLocalDT(item.ngayKetThuc) }
    : blankForm()
  modalOpen.value = true
}
function closeModal() { modalOpen.value = false }

async function saveItem() {
  if (!form.value.tenKhuyenMai.trim()) { formError.value = 'Vui lòng nhập mã voucher'; return }
  saving.value = true; formError.value = ''
  try {
    const payload = {
      tenKhuyenMai: form.value.tenKhuyenMai.toUpperCase(),
      phanTramGiam: form.value.phanTramGiam,
      soLuong:      form.value.soLuong || null,
      trangThai:    form.value.trangThai,
      ngayBatDau:   form.value.ngayBatDau ? new Date(form.value.ngayBatDau).toISOString().slice(0,19) : null,
      ngayKetThuc:  form.value.ngayKetThuc ? new Date(form.value.ngayKetThuc).toISOString().slice(0,19) : null,
    }
    if (editItem.value) {
      await khuyenMaiAPI.update(editItem.value.id, payload)
      toast.show('✅ Đã cập nhật voucher!')
    } else {
      await khuyenMaiAPI.create(payload)
      toast.show('✅ Đã tạo voucher mới!')
    }
    await loadData(); closeModal()
  } catch (e) {
    formError.value = e.response?.data?.message || 'Lỗi lưu dữ liệu'
  } finally { saving.value = false }
}

async function deleteItem(v) {
  if (!confirm(`Xoá voucher "${v.tenKhuyenMai}"?`)) return
  try { await khuyenMaiAPI.delete(v.id); await loadData(); toast.show('🗑️ Đã xoá voucher!') }
  catch { toast.show('❌ Xoá thất bại') }
}

async function loadData() {
  const res = await khuyenMaiAPI.getAll()
  items.value = res.data.data
}
onMounted(async () => { try { await loadData() } finally { loading.value = false } })
</script>

<style>
.vc-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(270px,1fr));gap:18px;margin-top:4px }
.vc-card { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;overflow:hidden;transition:transform .3s,border-color .3s; }
.vc-card:hover { transform:translateY(-3px);border-color:rgba(232,39,58,.22); }
.vc-card.expired { opacity:.5; }
.vc-top { padding:20px 20px 14px;position:relative;overflow:hidden; }
.vc-type { font-size:.62rem;font-weight:900;letter-spacing:.16em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-bottom:6px; }
.vc-code { font-family:'Bebas Neue',sans-serif;font-size:1.8rem;letter-spacing:.1em;color:#ffcc00;margin-bottom:6px; }
.vc-status { display:inline-block;padding:3px 9px;border-radius:50px;font-size:.62rem;font-weight:900;letter-spacing:.08em;text-transform:uppercase; }
.vc-on  { background:rgba(74,222,128,.12);color:#4ade80;border:1px solid rgba(74,222,128,.2); }
.vc-off { background:rgba(255,255,255,.06);color:rgba(245,237,230,.5);border:1px solid rgba(255,255,255,.08); }
.vc-bg-pct { position:absolute;right:16px;bottom:10px;font-family:'Bebas Neue',sans-serif;font-size:3.5rem;color:rgba(232,39,58,.1);line-height:1;pointer-events:none; }
.vc-divider { border:none;height:0;border-top:2px dashed rgba(255,255,255,.07);margin:0 18px; }
.vc-bottom { padding:12px 20px;display:flex;align-items:center;justify-content:space-between; }
.vc-meta-row { font-size:.72rem;font-weight:700;color:rgba(245,237,230,.45);margin-bottom:3px; }
.vc-meta-row span { color:#f5ede6; }
.skeleton-card { background:rgba(255,255,255,.04);border-radius:18px;height:180px;animation:pulse 1.5s ease-in-out infinite; }
@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.7}}
.input-gen { display:flex;gap:7px; }
.btn-gen { padding:0 14px;background:rgba(255,204,0,.1);border:1px solid rgba(255,204,0,.22);border-radius:10px;color:#ffcc00;font-family:'Nunito',sans-serif;font-size:.74rem;font-weight:900;cursor:pointer;white-space:nowrap;transition:all .2s; }
.btn-gen:hover { background:rgba(255,204,0,.2); }
</style>