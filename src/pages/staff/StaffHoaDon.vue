<template>
  <div class="pos-wrap">
    <!-- Sidebar (dùng lại AdminSidebar nhưng staff menu) -->
    <aside class="sidebar">
      <div class="sb-brand">
        <div class="sb-icon">🍔</div>
        <div class="sb-name">FastFood<span>YumMy</span></div>
      </div>
      <nav class="sb-nav">
        <span class="nav-lbl">Nhân Viên</span>
        <router-link to="/staff/hoa-don" class="nav-item active"><span>🧾</span>Tạo Hóa Đơn</router-link>
        <router-link to="/staff/lich-su" class="nav-item"><span>📋</span>Lịch Sử</router-link>
        <div class="nav-sep"></div>
        <router-link to="/staff/ho-so" class="nav-item"><span>👤</span>Hồ Sơ</router-link>
        <button @click="logout" class="nav-item nav-logout"><span>🚪</span>Đăng Xuất</button>
      </nav>
      <div class="sb-foot">
        <div class="s-user">
          <div class="s-ava">{{ initials }}</div>
          <div><div class="s-name">{{ auth.user?.hoTen }}</div><div class="s-role">Thu Ngân</div></div>
        </div>
      </div>
    </aside>

    <!-- MAIN -->
    <div class="pos-main">
      <!-- Topbar -->
      <header class="topbar">
        <div class="page-title">Tạo <span>Hóa Đơn</span></div>
        <div class="topbar-r">
          <div class="clock">{{ clock }}</div>
        </div>
      </header>

      <!-- POS body -->
      <div class="pos-body">

        <!-- LEFT: Menu -->
        <div class="pos-left">
          <div class="left-top">
            <div class="search-bar">
              <span>🔍</span>
              <input v-model="search" type="text" placeholder="Tìm món ăn..." @input="filterBySearch">
            </div>
            <div class="cat-tabs">
              <button class="cat-tab" :class="{active:selCat===null}" @click="selCat=null">Tất Cả</button>
              <button
                v-for="c in categories" :key="c.id"
                class="cat-tab"
                :class="{active:selCat===c.id}"
                @click="selCat=c.id"
              >{{ c.tenLoai }}</button>
            </div>
          </div>

          <div class="menu-scroll">
            <div v-if="menuLoading" class="menu-grid">
              <div v-for="n in 9" :key="n" class="skeleton-card"></div>
            </div>
            <div v-else class="menu-grid">
              <div
                v-for="mon in filteredMenu"
                :key="mon.id"
                class="mitem"
                @click="addToCart(mon)"
              >
                <img v-if="mon.hinhAnh" :src="mon.hinhAnh" class="mitem-img" @error="e=>e.target.style.display='none'">
                <div v-else class="mitem-img mitem-ph">🍔</div>
                <div class="mitem-body">
                  <div class="mitem-name">{{ mon.tenMon }}</div>
                  <div class="mitem-price">{{ fmt(mon.gia) }}</div>
                </div>
                <div class="mitem-foot">
                  <button class="add-btn" @click.stop="addToCart(mon)">+</button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- RIGHT: Bill -->
        <div class="pos-right">
          <div class="bill-head">
            <div class="bill-title">Hóa Đơn <span>#{{ billNoStr }}</span></div>
            <div class="bill-time">{{ billTime }}</div>
          </div>

          <!-- Table / Type / Guest -->
          <div class="tbl-row">
            <div class="tbl-btn" @click="tableModalOpen=true">
              <div class="tbl-lbl">Bàn Số</div>
              <div class="tbl-val">{{ selectedTable || '—' }}</div>
            </div>
            <div class="tbl-btn" @click="toggleType">
              <div class="tbl-lbl">Loại</div>
              <div class="tbl-val">{{ orderType }}</div>
            </div>
            <div class="tbl-btn" @click="guestCount = guestCount >= 10 ? 1 : guestCount+1">
              <div class="tbl-lbl">Khách</div>
              <div class="tbl-val">{{ guestCount }}</div>
            </div>
          </div>

          <!-- Cart -->
          <div class="cart-scroll">
            <div v-if="cartItems.length === 0" class="cart-empty">
              <div>🛒</div>
              <div>Chọn món từ menu bên trái</div>
            </div>
            <div v-for="(item, idx) in cartItems" :key="idx" class="citem">
              <div class="ci-name">{{ item.tenMon }}</div>
              <div class="ci-qty">
                <button class="q-btn" @click="changeQty(idx,-1)">−</button>
                <span class="q-num">{{ item.soLuong }}</span>
                <button class="q-btn" @click="changeQty(idx,1)">+</button>
              </div>
              <div class="ci-price">{{ fmt(item.gia * item.soLuong) }}</div>
              <button class="ci-del" @click="removeItem(idx)">✕</button>
            </div>
          </div>

          <!-- Summary -->
          <div class="bill-summary">
            <div class="srow"><span>Tạm tính</span><span>{{ fmt(subtotal) }}</span></div>
            <div class="srow red" v-if="discountAmt > 0"><span>Giảm giá ({{ appliedVoucher?.phanTramGiam }}%)</span><span>-{{ fmt(discountAmt) }}</span></div>
            <div class="srow"><span>VAT (8%)</span><span>{{ fmt(vat) }}</span></div>
            <div class="sdiv"></div>
            <div class="stotal"><span>TỔNG CỘNG</span><span class="total-val">{{ fmt(total) }}</span></div>

            <!-- Voucher -->
            <div class="voucher-row">
              <input v-if="!appliedVoucher" v-model="voucherCode" placeholder="Mã giảm giá..." class="vc-input" @keyup.enter="applyVoucher">
              <div v-else class="vc-applied">
                🎟️ {{ appliedVoucher.tenKhuyenMai }} (-{{ appliedVoucher.phanTramGiam }}%)
                <button @click="appliedVoucher=null" class="vc-rm">✕</button>
              </div>
              <button v-if="!appliedVoucher" class="btn-vc" @click="applyVoucher">Áp Dụng</button>
            </div>

            <!-- Payment -->
            <div class="pays">
              <div v-for="p in payMethods" :key="p.id" class="pay" :class="{active:selectedPay===p.id}" @click="selectedPay=p.id">
                <span>{{ p.icon }}</span>{{ p.label }}
              </div>
            </div>

            <button class="btn-checkout" :disabled="cartItems.length===0 || submitting" @click="checkout">
              {{ submitting ? '⏳ Đang xử lý...' : '🧾 Thanh Toán' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Table modal -->
    <div class="modal-overlay" :class="{open:tableModalOpen}" @click.self="tableModalOpen=false">
      <div class="modal" style="width:380px;border-color:rgba(255,204,0,.2)">
        <div class="modal-head">
          <div class="modal-title">Chọn <span>Bàn</span></div>
          <button class="modal-close" @click="tableModalOpen=false">✕</button>
        </div>
        <div class="modal-body">
          <div class="table-grid">
            <div
              v-for="n in 12" :key="n"
              :class="['tcell', occupiedTables.includes(n) ? 'busy' : 'free']"
              @click="chooseTable(n)"
            >
              <div class="tclbl">Bàn</div>
              <div class="tcnum">{{ n }}</div>
              <div class="tcst">{{ occupiedTables.includes(n) ? 'Đang dùng' : 'Trống' }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Success modal -->
    <div class="modal-overlay" :class="{open:successOpen}" @click.self="successOpen=false">
      <div class="modal" style="border-color:rgba(74,222,128,.25);text-align:center">
        <div style="font-size:3rem;padding:24px 0 6px">✅</div>
        <div style="font-family:'Bebas Neue',sans-serif;font-size:1.7rem;color:#fff;margin-bottom:4px">Thanh Toán <span style="color:#4ade80">Thành Công!</span></div>
        <div class="rcpt">
          <div class="rrow"><span>Hóa đơn</span><span>#{{ billNoStr }}</span></div>
          <div class="rrow"><span>Bàn</span><span>{{ selectedTable ? 'Bàn '+selectedTable : 'Mang về' }}</span></div>
          <div class="rrow"><span>Thanh toán</span><span>{{ payMethods.find(p=>p.id===selectedPay)?.label }}</span></div>
          <div style="border-top:1px dashed rgba(255,255,255,.08);margin:8px 0"></div>
          <div class="rrow" style="font-size:.9rem"><span>Tổng tiền</span><span style="color:#ffcc00">{{ fmt(total) }}</span></div>
        </div>
        <div style="display:flex;gap:9px;padding:0 24px 22px">
          <button class="btn-new" @click="newBill">📄 Hóa Đơn Mới</button>
          <button class="btn-print" @click="successOpen=false">🖨️ In Hóa Đơn</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { useToastStore } from '../../stores/toast'
import { monAnAPI, loaiMonAnAPI, khuyenMaiAPI, hoaDonAPI } from '../../services/api'

const auth   = useAuthStore()
const toast  = useToastStore()
const router = useRouter()

// Clock
const clock    = ref('')
const billTime = ref('')
let timer
function tick() {
  const now = new Date()
  clock.value    = now.toLocaleTimeString('vi',{hour:'2-digit',minute:'2-digit'})
  billTime.value = now.toLocaleDateString('vi') + ' ' + clock.value
}
onMounted(()=>{ tick(); timer=setInterval(tick,1000) })
onUnmounted(()=>clearInterval(timer))

// Auth
const initials = computed(() => (auth.user?.hoTen||'NV').split(' ').map(w=>w[0]).slice(-2).join('').toUpperCase())
function logout() { auth.logout(); router.push('/dang-nhap') }

// Menu
const allMenu    = ref([])
const categories = ref([])
const menuLoading = ref(true)
const search     = ref('')
const selCat     = ref(null)

const filteredMenu = computed(() => {
  let list = allMenu.value
  if (selCat.value) list = list.filter(m => m.loaiMonAn?.id === selCat.value)
  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(m => m.tenMon.toLowerCase().includes(q))
  }
  return list
})
function filterBySearch() {}

// Cart
const cartItems  = ref([])
const voucherCode = ref('')
const appliedVoucher = ref(null)
const selectedPay = ref('tien_mat')
const selectedTable = ref(null)
const orderType  = ref('Tại Chỗ')
const guestCount = ref(1)
const submitting = ref(false)
const successOpen = ref(false)
const tableModalOpen = ref(false)
let billCounter  = 87
const occupiedTables = ref([2,5,8])

const billNoStr = computed(() => String(billCounter).padStart(4,'0'))

const subtotal     = computed(() => cartItems.value.reduce((s,i) => s + i.gia * i.soLuong, 0))
const discountAmt  = computed(() => appliedVoucher.value ? Math.round(subtotal.value * appliedVoucher.value.phanTramGiam / 100) : 0)
const vat          = computed(() => Math.round((subtotal.value - discountAmt.value) * 0.08))
const total        = computed(() => Math.max(0, subtotal.value - discountAmt.value + vat.value))

const payMethods = [
  { id:'tien_mat', icon:'💵', label:'Tiền Mặt' },
  { id:'the',      icon:'💳', label:'Thẻ' },
  { id:'qr',       icon:'📱', label:'QR/Ví' },
]

function fmt(n) { return Number(n||0).toLocaleString('vi') + 'đ' }


function addToCart(mon) {
  const ex = cartItems.value.find(i => i.id === mon.id)
  if (ex) { ex.soLuong++; return }
  cartItems.value.push({ id:mon.id, tenMon:mon.tenMon, gia:mon.gia, soLuong:1 })
}
function changeQty(idx, d) {
  cartItems.value[idx].soLuong += d
  if (cartItems.value[idx].soLuong <= 0) cartItems.value.splice(idx,1)
}
function removeItem(idx) { cartItems.value.splice(idx,1) }
function toggleType() { orderType.value = orderType.value === 'Tại Chỗ' ? 'Mang Về' : 'Tại Chỗ' }
function chooseTable(n) {
  if (occupiedTables.value.includes(n)) return
  selectedTable.value = n
  tableModalOpen.value = false
}

async function applyVoucher() {
  if (!voucherCode.value.trim()) return
  try {
    const res = await khuyenMaiAPI.getActive()
    const found = res.data.data.find(v => v.tenKhuyenMai.toUpperCase() === voucherCode.value.toUpperCase())
    if (found) { appliedVoucher.value = found; voucherCode.value = ''; toast.show('🎟️ Áp dụng voucher thành công!') }
    else toast.show('❌ Mã không hợp lệ hoặc hết hạn')
  } catch { toast.show('❌ Không thể kiểm tra voucher') }
}

async function checkout() {
  if (!cartItems.value.length) return
  submitting.value = true
  try {
    const payload = {
      items: cartItems.value.map(i => ({ monAnId: i.id, soLuong: i.soLuong })),
      khuyenMaiId: appliedVoucher.value?.id || null,
    }
    await hoaDonAPI.create(payload)
    successOpen.value = true
  } catch (e) {
    toast('❌ Thanh toán thất bại: ' + (e.response?.data?.message || e.message))
  } finally { submitting.value = false }
}

function newBill() {
  successOpen.value = false
  cartItems.value = []
  appliedVoucher.value = null
  selectedTable.value = null
  guestCount.value = 1
  voucherCode.value = ''
  billCounter++
  toast.show('📄 Bắt đầu hóa đơn mới!')
}

onMounted(async () => {
  try {
    const [monRes, loaiRes] = await Promise.all([monAnAPI.getAll(), loaiMonAnAPI.getAll()])
    allMenu.value    = monRes.data.data
    categories.value = loaiRes.data.data.filter(c => c.trangThai)
  } finally { menuLoading.value = false }
})
</script>

<style scoped>
.st-payment { background:rgba(99,102,241,.12);color:#818cf8;border:1px solid rgba(99,102,241,.22); }
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Nunito:wght@400;600;700;800;900&display=swap');
:root{--red:#e8273a;--red-dark:#b8001a;--yellow:#ffcc00;--dark:#0e0a0a;--card:rgba(22,14,14,.9);--text:#f5ede6;--muted:rgba(245,237,230,.5);--border:rgba(255,255,255,.08)}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html,body{height:100%;overflow:hidden;font-family:'Nunito',sans-serif;background:#0e0a0a;color:#f5ede6}
.pos-wrap{display:flex;height:100vh;overflow:hidden}
/* Sidebar */
.sidebar{position:fixed;top:0;left:0;bottom:0;width:180px;background:rgba(10,6,6,.97);border-right:1px solid rgba(255,255,255,.08);display:flex;flex-direction:column;z-index:200}
.sb-brand{display:flex;align-items:center;gap:9px;padding:18px 14px;border-bottom:1px solid rgba(255,255,255,.08);text-decoration:none}
.sb-icon{width:32px;height:32px;background:#e8273a;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0}
.sb-name{font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.06em;color:#fff;line-height:1}
.sb-name span{color:#ffcc00}
.sb-nav{flex:1;padding:12px 8px;display:flex;flex-direction:column;gap:2px;overflow-y:auto}
.nav-item{display:flex;align-items:center;gap:8px;padding:9px 10px;border-radius:10px;text-decoration:none;color:rgba(245,237,230,.5);font-size:.76rem;font-weight:800;letter-spacing:.04em;text-transform:uppercase;transition:all .2s;border:none;background:none;cursor:pointer;font-family:'Nunito',sans-serif;width:100%;text-align:left}
.nav-item:hover{background:rgba(255,255,255,.05);color:#f5ede6}
.nav-item.active{background:rgba(232,39,58,.15);color:#e8273a;border:1px solid rgba(232,39,58,.2)}
.nav-item span{font-size:.9rem;width:16px;text-align:center;flex-shrink:0}
.nav-logout:hover{background:rgba(248,113,113,.1);color:#f87171}
.nav-sep{height:1px;background:rgba(255,255,255,.08);margin:6px 10px}
.nav-lbl{font-size:.58rem;font-weight:900;letter-spacing:.2em;text-transform:uppercase;color:rgba(245,237,230,.4);padding:6px 10px 2px}
.sb-foot{padding:12px;border-top:1px solid rgba(255,255,255,.08)}
.s-user{display:flex;align-items:center;gap:8px}
.s-ava{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#f59e0b,#d97706);display:flex;align-items:center;justify-content:center;font-weight:900;font-size:.78rem;color:#fff;flex-shrink:0}
.s-name{font-size:.74rem;font-weight:800;color:#f5ede6}
.s-role{font-size:.62rem;color:rgba(245,237,230,.4);font-weight:600}
/* Main */
.pos-main{margin-left:180px;flex:1;display:flex;flex-direction:column;height:100vh;overflow:hidden}
.topbar{height:58px;flex-shrink:0;background:rgba(14,10,10,.9);backdrop-filter:blur(18px);border-bottom:1px solid rgba(255,255,255,.08);padding:0 24px;display:flex;align-items:center;justify-content:space-between}
.page-title{font-family:'Bebas Neue',sans-serif;font-size:1.35rem;letter-spacing:.06em;color:#fff}
.page-title span{color:#ffcc00}
.clock{font-size:.76rem;font-weight:700;color:rgba(245,237,230,.4);background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);padding:4px 12px;border-radius:50px}
.pos-body{flex:1;display:grid;grid-template-columns:1fr 360px;min-height:0}
/* Left panel */
.pos-left{display:flex;flex-direction:column;border-right:1px solid rgba(255,255,255,.08);min-height:0}
.left-top{padding:12px 16px 10px;border-bottom:1px solid rgba(255,255,255,.08);flex-shrink:0}
.search-bar{display:flex;align-items:center;gap:7px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:10px;padding:8px 13px;margin-bottom:10px}
.search-bar input{background:none;border:none;outline:none;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.84rem;font-weight:600;width:100%}
.search-bar input::placeholder{color:rgba(245,237,230,.4)}
.cat-tabs{display:flex;gap:5px;flex-wrap:wrap}
.cat-tab{padding:5px 12px;border-radius:50px;font-family:'Nunito',sans-serif;font-size:.7rem;font-weight:800;letter-spacing:.05em;text-transform:uppercase;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);color:rgba(245,237,230,.5);cursor:pointer;transition:all .2s}
.cat-tab:hover,.cat-tab.active{background:rgba(232,39,58,.15);border-color:rgba(232,39,58,.3);color:#e8273a}
.menu-scroll{flex:1;overflow-y:auto;padding:12px 14px}
.menu-scroll::-webkit-scrollbar{width:3px}
.menu-scroll::-webkit-scrollbar-thumb{background:rgba(255,255,255,.08)}
.menu-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.mitem{background:rgba(22,14,14,.9);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;cursor:pointer;transition:all .22s}
.mitem:hover{border-color:rgba(232,39,58,.3);transform:translateY(-2px);box-shadow:0 6px 16px rgba(0,0,0,.4)}
.mitem-img{width:100%;height:78px;object-fit:cover;display:block}
.mitem-ph{height:78px;display:flex;align-items:center;justify-content:center;font-size:2.2rem;background:rgba(255,255,255,.03)}
.mitem-body{padding:7px 9px 2px}
.mitem-name{font-weight:800;font-size:.72rem;color:#f5ede6;margin-bottom:2px;line-height:1.3}
.mitem-price{font-family:'Bebas Neue',sans-serif;font-size:.88rem;letter-spacing:.04em;color:#ffcc00}
.mitem-foot{display:flex;justify-content:flex-end;padding:2px 9px 7px}
.add-btn{width:22px;height:22px;border-radius:50%;background:#e8273a;border:none;color:#fff;font-size:1rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:transform .2s;box-shadow:0 2px 7px rgba(232,39,58,.4)}
.add-btn:hover{transform:scale(1.18)}
/* Right / Bill */
.pos-right{display:flex;flex-direction:column;background:rgba(10,6,6,.97);min-height:0}
.bill-head{padding:12px 15px;border-bottom:1px solid rgba(255,255,255,.08);display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.bill-title{font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.06em;color:#fff}
.bill-title span{color:#ffcc00}
.bill-time{font-size:.62rem;font-weight:700;color:rgba(245,237,230,.4);background:rgba(255,255,255,.04);padding:3px 8px;border-radius:50px;border:1px solid rgba(255,255,255,.07)}
.tbl-row{display:flex;gap:6px;padding:8px 12px;border-bottom:1px solid rgba(255,255,255,.08);flex-shrink:0}
.tbl-btn{flex:1;padding:7px 5px;border-radius:8px;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.03);cursor:pointer;text-align:center;transition:all .2s}
.tbl-btn:hover{background:rgba(232,39,58,.08);border-color:rgba(232,39,58,.2)}
.tbl-lbl{font-size:.55rem;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-bottom:2px}
.tbl-val{font-family:'Bebas Neue',sans-serif;font-size:1rem;letter-spacing:.04em;color:#f5ede6}
.cart-scroll{flex:1;overflow-y:auto;min-height:0}
.cart-scroll::-webkit-scrollbar{width:2px}
.cart-scroll::-webkit-scrollbar-thumb{background:rgba(255,255,255,.08)}
.cart-empty{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:8px;opacity:.3;font-size:.8rem;font-weight:700;color:rgba(245,237,230,.5)}
.cart-empty div:first-child{font-size:2.2rem}
.citem{display:flex;align-items:center;gap:6px;padding:7px 12px;border-bottom:1px solid rgba(255,255,255,.04)}
.ci-name{flex:1;font-size:.76rem;font-weight:800;color:#f5ede6;line-height:1.3}
.ci-qty{display:flex;align-items:center;gap:4px}
.q-btn{width:20px;height:20px;border-radius:50%;background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.08);color:#f5ede6;font-size:.75rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s}
.q-btn:hover{background:rgba(232,39,58,.2)}
.q-num{font-family:'Bebas Neue',sans-serif;font-size:.9rem;color:#ffcc00;width:16px;text-align:center}
.ci-price{font-family:'Bebas Neue',sans-serif;font-size:.9rem;color:#f5ede6;min-width:60px;text-align:right}
.ci-del{width:18px;height:18px;border-radius:5px;background:rgba(248,113,113,.07);border:1px solid rgba(248,113,113,.14);color:#f87171;font-size:.6rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s}
.ci-del:hover{background:rgba(248,113,113,.2)}
/* Summary */
.bill-summary{padding:10px 13px;border-top:1px solid rgba(255,255,255,.08);flex-shrink:0}
.srow{display:flex;justify-content:space-between;font-size:.74rem;font-weight:700;color:rgba(245,237,230,.55);margin-bottom:5px}
.srow.red{color:#e8273a}
.sdiv{height:1px;background:rgba(255,255,255,.08);margin:7px 0}
.stotal{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.stotal span:first-child{font-family:'Bebas Neue',sans-serif;font-size:.98rem;letter-spacing:.08em;color:#fff}
.total-val{font-family:'Bebas Neue',sans-serif;font-size:1.35rem;letter-spacing:.04em;color:#ffcc00}
.voucher-row{display:flex;gap:6px;margin-bottom:8px}
.vc-input{flex:1;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:8px;padding:7px 10px;color:#f5ede6;font-family:'Nunito',sans-serif;font-size:.76rem;font-weight:600;outline:none;text-transform:uppercase}
.vc-input:focus{border-color:rgba(255,204,0,.3)}
.vc-applied{flex:1;background:rgba(255,204,0,.08);border:1px solid rgba(255,204,0,.2);border-radius:8px;padding:7px 10px;font-size:.72rem;font-weight:700;color:#ffcc00;display:flex;align-items:center;gap:6px}
.vc-rm{background:none;border:none;color:rgba(255,204,0,.6);cursor:pointer;margin-left:auto}
.btn-vc{padding:0 11px;background:rgba(255,204,0,.1);border:1px solid rgba(255,204,0,.2);border-radius:8px;color:#ffcc00;font-family:'Nunito',sans-serif;font-size:.72rem;font-weight:900;cursor:pointer;white-space:nowrap}
.pays{display:grid;grid-template-columns:repeat(3,1fr);gap:5px;margin-bottom:8px}
.pay{padding:6px 3px;border-radius:8px;border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);cursor:pointer;text-align:center;font-size:.6rem;font-weight:800;letter-spacing:.04em;text-transform:uppercase;color:rgba(245,237,230,.5);transition:all .2s;display:flex;flex-direction:column;gap:3px;align-items:center}
.pay:hover,.pay.active{background:rgba(74,222,128,.08);border-color:rgba(74,222,128,.25);color:#4ade80}
.pay span{font-size:.95rem}
.btn-checkout{width:100%;padding:11px;background:#e8273a;border:none;border-radius:10px;font-family:'Bebas Neue',sans-serif;font-size:1.1rem;letter-spacing:.1em;color:#fff;cursor:pointer;transition:all .2s;box-shadow:0 4px 14px rgba(232,39,58,.4)}
.btn-checkout:hover:not(:disabled){background:#b8001a;transform:translateY(-1px)}
.btn-checkout:disabled{opacity:.4;cursor:not-allowed}
/* Table grid */
.table-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:7px}
.tcell{padding:9px 5px;border-radius:10px;text-align:center;transition:all .2s}
.tcell.free{border:1px solid rgba(255,255,255,.08);background:rgba(255,255,255,.04);cursor:pointer}
.tcell.free:hover{background:rgba(74,222,128,.08);border-color:rgba(74,222,128,.25)}
.tcell.busy{border:1px solid rgba(232,39,58,.25);background:rgba(232,39,58,.07);opacity:.5;cursor:not-allowed}
.tclbl{font-size:.54rem;font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:rgba(245,237,230,.4);margin-bottom:3px}
.tcnum{font-family:'Bebas Neue',sans-serif;font-size:1.2rem;color:#f5ede6}
.tcell.busy .tcnum{color:#e8273a}
.tcst{font-size:.55rem;font-weight:700;color:#4ade80}
.tcell.busy .tcst{color:#e8273a}
/* Modal shared */
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.75);backdrop-filter:blur(7px);z-index:500;display:none;align-items:center;justify-content:center}
.modal-overlay.open{display:flex}
.modal{background:#0d0707;border:1px solid rgba(232,39,58,.2);border-radius:20px;width:440px;max-width:95vw;max-height:90vh;overflow-y:auto;animation:mIn .3s cubic-bezier(.34,1.56,.64,1)}
@keyframes mIn{from{opacity:0;transform:scale(.9) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)}}
.modal-head{display:flex;align-items:center;justify-content:space-between;padding:20px 22px 0}
.modal-title{font-family:'Bebas Neue',sans-serif;font-size:1.3rem;letter-spacing:.06em;color:#fff}
.modal-title span{color:#ffcc00}
.modal-close{width:28px;height:28px;border-radius:50%;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:.82rem}
.modal-close:hover{background:rgba(232,39,58,.2)}
.modal-body{padding:16px 22px 20px}
/* Receipt */
.rcpt{margin:12px 22px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.08);border-radius:11px;padding:13px}
.rrow{display:flex;justify-content:space-between;font-size:.78rem;font-weight:700;color:rgba(245,237,230,.5);margin-bottom:6px}
.rrow:last-child{margin-bottom:0}
.rrow span:last-child{color:#f5ede6}
.btn-new{flex:1;padding:10px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);border-radius:10px;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:800;color:#f5ede6;cursor:pointer;transition:all .2s}
.btn-new:hover{background:rgba(255,255,255,.1)}
.btn-print{flex:1;padding:10px;background:#4ade80;border:none;border-radius:10px;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:900;color:#030a06;cursor:pointer}
.skeleton-card{background:rgba(255,255,255,.04);border-radius:12px;height:140px;animation:pulse 1.5s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:.4}50%{opacity:.7}}
</style>