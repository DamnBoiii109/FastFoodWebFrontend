<template>
  <div class="admin-layout">
    <AdminSidebar active="mon-an" />
    <div class="main-wrap">
      <AdminTopbar title="Quản Lý" :highlight="'Đồ Ăn'" />

      <div class="content">
        <!-- Stats -->
        <div class="stats-row">
          <div class="stat-card" v-for="s in stats" :key="s.label">
            <span class="stat-emoji">{{ s.emoji }}</span>
            <div class="stat-label">{{ s.label }}</div>
            <div class="stat-val" :class="s.color">{{ s.val }}</div>
            <div class="stat-sub">{{ s.sub }}</div>
          </div>
        </div>

        <!-- Toolbar -->
        <div class="toolbar">
          <div class="toolbar-left">
            <button
              v-for="f in catFilters" :key="f.value"
              class="filter-btn"
              :class="{ active: catFilter === f.value }"
              @click="catFilter = f.value"
            >{{ f.label }}</button>
          </div>
          <div class="toolbar-right">
            <div class="search-box">
              <span>🔍</span>
              <input v-model="search" placeholder="Tìm món ăn..." class="search-input">
            </div>
            <button class="btn-primary" @click="openModal()">＋ Thêm Món Mới</button>
          </div>
        </div>

        <!-- Table -->
        <div class="table-wrap">
          <div class="table-head">
            <div class="th" style="width:56px"></div>
            <div class="th flex2">Tên Món</div>
            <div class="th">Danh Mục</div>
            <div class="th">Giá Bán</div>
            <div class="th">Trạng Thái</div>
            <div class="th" style="width:110px">Thao Tác</div>
          </div>

          <div v-if="loading" class="table-loading">
            <div v-for="n in 5" :key="n" class="skeleton-row"></div>
          </div>

          <div v-else-if="filteredItems.length === 0" class="table-empty">
            <span>🍽️</span> Không có món nào phù hợp
          </div>

          <div
            v-for="mon in filteredItems"
            :key="mon.id"
            class="table-row"
          >
            <div style="width:56px">
              <img v-if="mon.hinhAnh" :src="mon.hinhAnh" class="food-thumb" @error="e=>e.target.style.display='none'">
              <div v-else class="food-thumb-ph">🍔</div>
            </div>
            <div class="flex2">
              <div class="food-name-text">{{ mon.tenMon }}</div>
            </div>
            <div class="td">{{ mon.loaiMonAn?.tenLoai || '—' }}</div>
            <div class="td price-td">{{ fmt(mon.gia) }}</div>
            <div class="td">
              <span :class="['badge', mon.trangThai ? 'badge-on' : 'badge-off']">
                {{ mon.trangThai ? '● Đang Bán' : '⏸ Tạm Dừng' }}
              </span>
            </div>
            <div class="td row-actions">
              <button class="act-btn" @click="openModal(mon)" title="Sửa">✏️</button>
              <button class="act-btn del" @click="deleteItem(mon)" title="Xoá">🗑️</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div class="modal-overlay" :class="{ open: modalOpen }" @click.self="closeModal">
      <div class="modal">
        <div class="modal-head">
          <div class="modal-title">
            {{ editItem ? 'Chỉnh Sửa' : 'Thêm' }} <span>Món Ăn</span>
          </div>
          <button class="modal-close" @click="closeModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-row">
            <div class="form-group">
              <label>Tên Món</label>
              <input v-model="form.tenMon" class="finput" placeholder="VD: Burger Bò Wagyu">
            </div>
            <div class="form-group">
              <label>Danh Mục</label>
              <select v-model="form.loaiId" class="finput">
                <option value="">-- Chọn danh mục --</option>
                <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                  {{ cat.tenLoai }}
                </option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Giá Bán (đ)</label>
              <input v-model.number="form.gia" type="number" class="finput" placeholder="89000">
            </div>
            <div class="form-group">
              <label>Trạng Thái</label>
              <select v-model="form.trangThai" class="finput">
                <option :value="true">● Đang Bán</option>
                <option :value="false">⏸ Tạm Dừng</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>URL Hình Ảnh</label>
            <input v-model="form.hinhAnh" class="finput" placeholder="https://...">
            <img v-if="form.hinhAnh" :src="form.hinhAnh" class="img-preview" @error="e=>e.target.style.display='none'">
          </div>
          <div v-if="formError" class="form-error">{{ formError }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">Huỷ</button>
          <button class="btn-primary" @click="saveItem" :disabled="saving">
            {{ saving ? '⏳...' : '💾 Lưu Món' }}
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
import AdminTopbar from '../../components/admin/AdminTopbar.vue'
import { monAnAPI, loaiMonAnAPI } from '../../services/api'

const items      = ref([])
const categories = ref([])
const toast      = useToastStore()
const loading    = ref(true)
const search     = ref('')
const catFilter  = ref('all')
const modalOpen  = ref(false)
const editItem   = ref(null)
const saving     = ref(false)
const formError  = ref('')

const form = ref({ tenMon:'', loaiId:'', gia:0, hinhAnh:'', trangThai:true })

const catFilters = computed(() => [
  { value:'all', label:`Tất Cả (${items.value.length})` },
  ...categories.value.map(c => ({ value:c.id, label:c.tenLoai }))
])

const filteredItems = computed(() => {
  let list = items.value
  if (catFilter.value !== 'all') list = list.filter(m => m.loaiMonAn?.id === catFilter.value)
  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(m => m.tenMon.toLowerCase().includes(q))
  }
  return list
})

const stats = computed(() => [
  { emoji:'🍔', label:'Tổng Món',   val: items.value.length,                                color:'',       sub:'Trong hệ thống' },
  { emoji:'🔥', label:'Đang Bán',   val: items.value.filter(m=>m.trangThai).length,          color:'red',    sub:'Đang hoạt động' },
  { emoji:'⏸',  label:'Tạm Dừng',  val: items.value.filter(m=>!m.trangThai).length,         color:'',       sub:'Cần kiểm tra' },
  { emoji:'📦', label:'Danh Mục',   val: categories.value.length,                            color:'yellow', sub:'Loại món ăn' },
])

function fmt(n) { return Number(n||0).toLocaleString('vi') + 'đ' }



function openModal(item = null) {
  editItem.value = item
  formError.value = ''
  if (item) {
    form.value = { tenMon:item.tenMon, loaiId:item.loaiMonAn?.id||'', gia:item.gia, hinhAnh:item.hinhAnh||'', trangThai:item.trangThai }
  } else {
    form.value = { tenMon:'', loaiId:'', gia:0, hinhAnh:'', trangThai:true }
  }
  modalOpen.value = true
}
function closeModal() { modalOpen.value = false }

async function saveItem() {
  if (!form.value.tenMon.trim()) { formError.value = 'Vui lòng nhập tên món'; return }
  if (!form.value.gia || form.value.gia <= 0) { formError.value = 'Vui lòng nhập giá hợp lệ'; return }
  saving.value = true; formError.value = ''
  try {
    const payload = { tenMon:form.value.tenMon, gia:form.value.gia, hinhAnh:form.value.hinhAnh||null, trangThai:form.value.trangThai, loaiId:form.value.loaiId||null }
    if (editItem.value) {
      await monAnAPI.update(editItem.value.id, payload)
      toast.show('✅ Đã cập nhật món ăn!')
    } else {
      await monAnAPI.create(payload)
      toast.show('✅ Đã thêm món ăn mới!')
    }
    await loadData()
    closeModal()
  } catch (e) {
    formError.value = e.response?.data?.message || 'Lỗi lưu dữ liệu'
  } finally {
    saving.value = false
  }
}

async function deleteItem(mon) {
  if (!confirm(`Xoá món "${mon.tenMon}"?`)) return
  try {
    await monAnAPI.delete(mon.id)
    await loadData()
    toast.show('🗑️ Đã xoá món ăn!')
  } catch { toast.show('❌ Xoá thất bại') }
}

async function loadData() {
  const [monRes, loaiRes] = await Promise.all([monAnAPI.getAll(), loaiMonAnAPI.getAll()])
  items.value = monRes.data.data
  categories.value = loaiRes.data.data.filter(c => c.trangThai)
}

onMounted(async () => {
  try { await loadData() } finally { loading.value = false }
})
</script>

<style>
.img-preview { width:100%;height:120px;object-fit:cover;border-radius:10px;margin-top:8px }
.food-thumb { width:42px;height:42px;border-radius:9px;object-fit:cover }
.food-thumb-ph { width:42px;height:42px;border-radius:9px;background:rgba(255,255,255,.06);display:flex;align-items:center;justify-content:center;font-size:1.3rem }
</style>