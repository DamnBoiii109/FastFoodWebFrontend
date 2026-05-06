<template>
  <div class="admin-layout">
    <AdminSidebar active="loai-mon-an" />
    <div class="main-wrap">
      <AdminTopbar title="Quản Lý" highlight="Loại Món Ăn" />
      <div class="content">

        <div class="toolbar">
          <div class="toolbar-left">
            <button class="filter-btn" :class="{active:filter==='all'}" @click="filter='all'">Tất Cả ({{ items.length }})</button>
            <button class="filter-btn" :class="{active:filter==='on'}"  @click="filter='on'">✅ Đang Dùng</button>
            <button class="filter-btn" :class="{active:filter==='off'}" @click="filter='off'">⏸ Tạm Dừng</button>
          </div>
          <button class="btn-primary" @click="openModal()">＋ Thêm Loại Mới</button>
        </div>

        <div v-if="loading" class="table-wrap table-loading">
          <div v-for="n in 5" :key="n" class="skeleton-row"></div>
        </div>

        <div v-else class="table-wrap">
          <div class="table-head">
            <div class="th flex2">Tên Loại</div>
            <div class="th flex2">Mô Tả</div>
            <div class="th">Trạng Thái</div>
            <div class="th" style="width:120px">Thao Tác</div>
          </div>
          <div v-if="filteredItems.length === 0" class="table-empty">
            <span>🗂️</span> Không có loại món nào
          </div>
          <div v-for="item in filteredItems" :key="item.id" class="table-row">
            <div class="flex2">
              <div class="td" style="font-weight:800;color:#f5ede6">{{ item.tenLoai }}</div>
            </div>
            <div class="flex2">
              <div class="td" style="color:rgba(245,237,230,.5);font-size:.8rem">{{ item.moTa || '—' }}</div>
            </div>
            <div class="td">
              <span :class="['badge', item.trangThai ? 'badge-on' : 'badge-off']">
                {{ item.trangThai ? '● Đang Dùng' : '⏸ Tạm Dừng' }}
              </span>
            </div>
            <div class="td row-actions" style="width:120px">
              <button class="act-btn" @click="openModal(item)">✏️</button>
              <button class="act-btn del" @click="deleteItem(item)">🗑️</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div class="modal-overlay" :class="{ open: modalOpen }" @click.self="closeModal">
      <div class="modal">
        <div class="modal-head">
          <div class="modal-title">{{ editItem ? 'Chỉnh Sửa' : 'Thêm' }} <span>Loại Món</span></div>
          <button class="modal-close" @click="closeModal">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Tên Loại</label>
            <input v-model="form.tenLoai" class="finput" placeholder="VD: Burger, Pizza...">
          </div>
          <div class="form-group">
            <label>Mô Tả</label>
            <input v-model="form.moTa" class="finput" placeholder="Mô tả ngắn...">
          </div>
          <div class="form-group">
            <label>Trạng Thái</label>
            <select v-model="form.trangThai" class="finput">
              <option :value="true">● Đang Dùng</option>
              <option :value="false">⏸ Tạm Dừng</option>
            </select>
          </div>
          <div v-if="formError" class="form-error">{{ formError }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">Huỷ</button>
          <button class="btn-primary" @click="saveItem" :disabled="saving">
            {{ saving ? '⏳...' : '💾 Lưu' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import AdminSidebar from '../../components/admin/AdminSidebar.vue'
import AdminTopbar  from '../../components/admin/AdminTopbar.vue'
import { loaiMonAnAPI } from '../../services/api'
import { useToastStore } from '../../stores/toast'

const toast    = useToastStore()
const items    = ref([])
const loading  = ref(true)
const filter   = ref('all')
const modalOpen = ref(false)
const editItem  = ref(null)
const saving    = ref(false)
const formError = ref('')
const form = ref({ tenLoai:'', moTa:'', trangThai:true })

const filteredItems = computed(() => {
  if (filter.value === 'on')  return items.value.filter(i => i.trangThai)
  if (filter.value === 'off') return items.value.filter(i => !i.trangThai)
  return items.value
})

function openModal(item = null) {
  editItem.value = item; formError.value = ''
  form.value = item
    ? { tenLoai:item.tenLoai, moTa:item.moTa||'', trangThai:item.trangThai }
    : { tenLoai:'', moTa:'', trangThai:true }
  modalOpen.value = true
}
function closeModal() { modalOpen.value = false }

async function saveItem() {
  if (!form.value.tenLoai.trim()) { formError.value = 'Vui lòng nhập tên loại'; return }
  saving.value = true; formError.value = ''
  try {
    if (editItem.value) {
      await loaiMonAnAPI.update(editItem.value.id, form.value)
      toast.show('✅ Đã cập nhật loại món!')
    } else {
      await loaiMonAnAPI.create(form.value)
      toast.show('✅ Đã thêm loại món mới!')
    }
    await loadData(); closeModal()
  } catch (e) {
    formError.value = e.response?.data?.message || 'Lỗi lưu dữ liệu'
  } finally { saving.value = false }
}

async function deleteItem(item) {
  if (!confirm(`Xoá loại "${item.tenLoai}"? Các món thuộc loại này sẽ mất danh mục!`)) return
  try {
    await loaiMonAnAPI.delete(item.id)
    await loadData()
    toast.show('🗑️ Đã xoá loại món!')
  } catch { toast.show('❌ Xoá thất bại') }
}

async function loadData() {
  const res = await loaiMonAnAPI.getAll()
  items.value = res.data.data
}
onMounted(async () => { try { await loadData() } finally { loading.value = false } })
</script>

<style scoped>
@import '../../assets/admin.css';
</style>