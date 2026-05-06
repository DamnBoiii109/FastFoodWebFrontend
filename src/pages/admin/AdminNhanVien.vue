<template>
  <div class="admin-layout">
    <AdminSidebar active="nhan-vien" />
    <div class="main-wrap">
      <AdminTopbar title="Quản Lý" highlight="Nhân Viên" />
      <div class="content">

        <!-- Stats -->
        <div class="stats-row">
          <div class="stat-card"><span class="stat-emoji">👥</span><div class="stat-label">Tổng Nhân Viên</div><div class="stat-val">{{ staff.length }}</div><div class="stat-sub">Trong hệ thống</div></div>
          <div class="stat-card"><span class="stat-emoji">✅</span><div class="stat-label">Đang Hoạt Động</div><div class="stat-val green">{{ staff.filter(s=>s.hoatDong).length }}</div><div class="stat-sub">Tài khoản active</div></div>
          <div class="stat-card"><span class="stat-emoji">🔴</span><div class="stat-label">Quản Lý</div><div class="stat-val red">{{ staff.filter(s=>s.vaiTro==='admin').length }}</div><div class="stat-sub">Quyền admin</div></div>
          <div class="stat-card"><span class="stat-emoji">🟡</span><div class="stat-label">Nhân Viên</div><div class="stat-val yellow">{{ staff.filter(s=>s.vaiTro==='nhanvien').length }}</div><div class="stat-sub">Quyền nhân viên</div></div>
          <div class="stat-card">
  <span class="stat-emoji">🟢</span>
  <div class="stat-label">Khách Hàng</div>
  <div class="stat-val">{{ staff.filter(s=>s.vaiTro==='khachhang').length }}</div>
  <div class="stat-sub">Đã đăng ký</div>
</div>
        </div>

        <!-- Toolbar -->
        <div class="toolbar">
          <div class="toolbar-left">
            <button class="filter-btn" :class="{active:roleFilter==='all'}"      @click="roleFilter='all'">Tất Cả</button>
            <button class="filter-btn" :class="{active:roleFilter==='admin'}"    @click="roleFilter='admin'">🔴 Quản Lý</button>
            <button class="filter-btn" :class="{active:roleFilter==='nhanvien'}" @click="roleFilter='nhanvien'">🟡 Nhân Viên</button>
            <button class="filter-btn" :class="{active:roleFilter==='khachhang'}" @click="roleFilter='khachhang'">
  🟢 Khách Hàng
</button>
          </div>
          <div class="toolbar-right">
            <div class="search-box">
              <span>🔍</span>
              <input v-model="search" placeholder="Tìm nhân viên..." class="search-input">
            </div>
            <button class="btn-primary" @click="openModal()">＋ Thêm Nhân Viên</button>
          </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="staff-grid">
          <div v-for="n in 6" :key="n" class="skeleton-staff"></div>
        </div>

        <!-- Staff cards -->
        <div v-else-if="filteredStaff.length === 0" class="table-empty">
          <span>👥</span> Không có nhân viên nào
        </div>

        <div v-else class="staff-grid">
          <div v-for="s in filteredStaff" :key="s.id" class="staff-card">
            <div class="sc-top">
              <div class="sc-ava" :style="{ background: avatarColor(s.id) }">
                {{ initials(s.hoTen) }}
                <div class="sc-dot" :class="s.hoatDong ? 'dot-on' : 'dot-off'"></div>
              </div>
              <div>
                <div class="sc-name">{{ s.hoTen }}</div>
                <div class="sc-email">{{ s.email }}</div>
                <div :class="['sc-role', roleClass(s.vaiTro)]">{{ roleLabel(s.vaiTro) }}</div>
              </div>
            </div>
            <div class="sc-footer">
              <div class="sc-status" :class="s.hoatDong ? 'status-on' : 'status-off'">
                {{ s.hoatDong ? '● Hoạt Động' : '⏸ Đã Khoá' }}
              </div>
              <div class="row-actions">
                <button class="act-btn" @click="openModal(s)">✏️</button>
                <button class="act-btn del" @click="toggleActive(s)">
                  {{ s.hoatDong ? '🔒' : '🔓' }}
                </button>
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
          <div class="modal-title">{{ editItem ? 'Chỉnh Sửa' : 'Thêm' }} <span>Nhân Viên</span></div>
          <button class="modal-close" @click="closeModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-row">
            <div class="form-group">
              <label>Họ Tên</label>
              <input v-model="form.hoTen" class="finput" placeholder="Nguyễn Văn A">
            </div>
            <div class="form-group">
              <label>Email</label>
              <input v-model="form.email" type="email" class="finput" placeholder="nv@yummy.vn" :readonly="!!editItem">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Chức Vụ</label>
              <select v-model="form.vaiTro" class="finput">
  <option value="admin">👑 Quản Lý</option>
  <option value="nhanvien">🟡 Nhân Viên</option>
  <option value="khachhang">🟢 Khách Hàng</option>
</select>
            </div>
            <div class="form-group">
              <label>Trạng Thái</label>
              <select v-model="form.hoatDong" class="finput">
                <option :value="true">● Hoạt Động</option>
                <option :value="false">⏸ Khoá</option>
              </select>
            </div>
          </div>
          <div v-if="!editItem" class="form-group">
            <label>Mật Khẩu Ban Đầu</label>
            <input v-model="form.matKhau" type="password" class="finput" placeholder="Tối thiểu 6 ký tự">
          </div>
          <div v-if="formError" class="form-error">{{ formError }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">Huỷ</button>
          <button class="btn-primary" @click="saveItem" :disabled="saving">
            {{ saving ? '⏳...' : '👤 Lưu' }}
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
import { taiKhoanAPI } from '../../services/api'

const staff      = ref([])
const toast      = useToastStore()
const loading    = ref(true)
const search     = ref('')
const roleFilter = ref('all')
const modalOpen  = ref(false)
const editItem   = ref(null)
const saving     = ref(false)
const formError  = ref('')

const blankForm = () => ({ hoTen:'', email:'', vaiTro:'nhanvien', hoatDong:true, matKhau:'' })
const form = ref(blankForm())

// Sửa filteredStaff — bỏ filter loại khachhang, thêm khachhang vào roleFilter
const filteredStaff = computed(() => {
  let list = staff.value // Không filter bỏ khachhang nữa
  if (roleFilter.value !== 'all') list = list.filter(s => s.vaiTro === roleFilter.value)
  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(s => s.hoTen?.toLowerCase().includes(q) || s.email?.toLowerCase().includes(q))
  }
  return list
})

const COLORS = ['linear-gradient(135deg,#e8273a,#b8001a)','linear-gradient(135deg,#f59e0b,#d97706)','linear-gradient(135deg,#10b981,#059669)','linear-gradient(135deg,#6366f1,#4f46e5)','linear-gradient(135deg,#ec4899,#db2777)','linear-gradient(135deg,#8b5cf6,#7c3aed)']
function avatarColor(id) { return COLORS[id % COLORS.length] }
function initials(name) { return (name||'NV').split(' ').map(w=>w[0]).slice(-2).join('').toUpperCase() }
function roleLabel(r) { return { admin:'Quản Lý', nhanvien:'Nhân Viên', khachhang:'Khách Hàng' }[r]||r }
function roleClass(r) { return { admin:'role-admin', nhanvien:'role-staff', khachhang:'role-cus' }[r]||'' }


function openModal(item=null) {
  editItem.value = item; formError.value = ''
  form.value = item
    ? { hoTen:item.hoTen, email:item.email, vaiTro:item.vaiTro, hoatDong:item.hoatDong, matKhau:'' }
    : blankForm()
  modalOpen.value = true
}
function closeModal() { modalOpen.value = false }

async function saveItem() {
  if (!form.value.hoTen.trim()) { formError.value = 'Vui lòng nhập họ tên'; return }
  if (!editItem.value && !form.value.email.trim()) { formError.value = 'Vui lòng nhập email'; return }
  if (!editItem.value && form.value.matKhau.length < 6) { formError.value = 'Mật khẩu tối thiểu 6 ký tự'; return }
  saving.value = true; formError.value = ''
  try {
    const payload = { hoTen:form.value.hoTen, vaiTro:form.value.vaiTro, hoatDong:form.value.hoatDong }
    if (!editItem.value) { payload.email = form.value.email; payload.matKhau = form.value.matKhau }
    if (editItem.value) {
      await taiKhoanAPI.update(editItem.value.id, payload)
      toast.show('✅ Đã cập nhật nhân viên!')
    } else {
      await taiKhoanAPI.create(payload)
      toast.show('✅ Đã thêm nhân viên mới!')
    }
    await loadData(); closeModal()
  } catch (e) {
    formError.value = e.response?.data?.message || 'Lỗi lưu dữ liệu'
  } finally { saving.value = false }
}

async function toggleActive(s) {
  const action = s.hoatDong ? 'khoá' : 'mở khoá'
  if (!confirm(`Bạn muốn ${action} tài khoản "${s.hoTen}"?`)) return
  try {
    await taiKhoanAPI.update(s.id, { hoatDong: !s.hoatDong })
    await loadData()
    toast(`✅ Đã ${action} tài khoản!`)
  } catch { toast.show('❌ Thao tác thất bại') }
}

async function loadData() {
  const res = await taiKhoanAPI.getAll()
  staff.value = res.data.data
}
onMounted(async () => { try { await loadData() } finally { loading.value = false } })
</script>

<style>
.staff-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px }
.staff-card { background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:20px;transition:transform .3s,border-color .3s; }
.staff-card:hover { transform:translateY(-3px);border-color:rgba(232,39,58,.18); }
.sc-top { display:flex;align-items:center;gap:13px;margin-bottom:16px; }
.sc-ava { width:50px;height:50px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:1.1rem;color:#fff;flex-shrink:0;position:relative; }
.sc-dot { position:absolute;bottom:1px;right:1px;width:11px;height:11px;border-radius:50%;border:2px solid rgba(22,14,14,.9); }
.dot-on  { background:#4ade80; }
.dot-off { background:rgba(245,237,230,.3); }
.sc-name { font-weight:900;font-size:.92rem;color:#f5ede6;margin-bottom:2px; }
.sc-email { font-size:.7rem;color:rgba(245,237,230,.4);font-weight:600;margin-bottom:5px; }
.sc-role { display:inline-block;padding:2px 8px;border-radius:50px;font-size:.62rem;font-weight:900;letter-spacing:.08em;text-transform:uppercase; }
.role-admin { background:rgba(232,39,58,.15);color:#e8273a;border:1px solid rgba(232,39,58,.2); }
.role-staff { background:rgba(255,204,0,.1);color:#ffcc00;border:1px solid rgba(255,204,0,.18); }
.role-cus   { background:rgba(74,222,128,.08);color:#4ade80;border:1px solid rgba(74,222,128,.15); }
.sc-footer { display:flex;align-items:center;justify-content:space-between;padding-top:12px;border-top:1px solid rgba(255,255,255,.06); }
.sc-status { font-size:.72rem;font-weight:800; }
.status-on  { color:#4ade80; }
.status-off { color:rgba(245,237,230,.4); }
.skeleton-staff { background:rgba(255,255,255,.04);border-radius:18px;height:160px;animation:pulse 1.5s ease-in-out infinite; }
@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.7}}
</style>