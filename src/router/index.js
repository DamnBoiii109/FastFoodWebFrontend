import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const ChiTietMonAn  = () => import('../pages/ChiTietMonAn.vue')
const TrangChu       = () => import('../pages/TrangChu.vue')
const ThucDon        = () => import('../pages/ThucDon.vue')
const GioHang        = () => import('../pages/GioHang.vue')
const ThanhToan      = () => import('../pages/ThanhToan.vue')
const DonHang        = () => import('../pages/DonHang.vue')
const DangNhap       = () => import('../pages/DangNhap.vue')
const DangKy         = () => import('../pages/DangKy.vue')
const HoSo           = () => import('../pages/HoSo.vue')
const AdminDashboard = () => import('../pages/admin/AdminDashboard.vue')
const AdminMonAn     = () => import('../pages/admin/AdminMonAn.vue')
const AdminVoucher   = () => import('../pages/admin/AdminVoucher.vue')
const AdminNhanVien  = () => import('../pages/admin/AdminNhanVien.vue')
const StaffHoaDon    = () => import('../pages/staff/StaffHoaDon.vue')
const StaffLichSu = () => import('../pages/staff/StaffLichSu.vue')
const StaffHoSo      = () => import('../pages/staff/StaffHoSo.vue')
const AdminHoaDon    = () => import('../pages/admin/AdminHoaDon.vue')
const DonHangChiTiet = () => import('../pages/DonHangChiTiet.vue')
const BinhLuan       = () => import('../pages/BinhLuan.vue')
// Thêm vào routes:
const AdminLoaiMonAn = () => import('../pages/admin/AdminLoaiMonAn.vue')

const routes = [
  { path: '/',              component: TrangChu },
  { path: '/admin/loai-mon-an', component: AdminLoaiMonAn, meta: { requiresAdmin: true } },
  { path: '/mon-an/:id', component: ChiTietMonAn },
  { path: '/thuc-don',      component: ThucDon },
  { path: '/gio-hang',      component: GioHang },
  { path: '/thanh-toan',    component: ThanhToan,      meta: { requiresAuth: true } },
  { path: '/don-hang', component: DonHang, meta: { requiresAuth: true } },
  { path: '/dang-nhap',     component: DangNhap },
  { path: '/dang-ky',       component: DangKy },
  { path: '/ho-so',         component: HoSo,           meta: { requiresAuth: true } },
  { path: '/admin',              component: AdminDashboard, meta: { requiresAdmin: true } },
  { path: '/admin/mon-an',       component: AdminMonAn,     meta: { requiresAdmin: true } },
  { path: '/admin/voucher',      component: AdminVoucher,   meta: { requiresAdmin: true } },
  { path: '/admin/nhan-vien',    component: AdminNhanVien,  meta: { requiresAdmin: true } },
  { path: '/staff/hoa-don', component: StaffHoaDon,    meta: { requiresStaff: true } },
  { path: '/staff/lich-su', component: StaffLichSu, meta: { requiresStaff: true } },
  { path: '/don-hang/:id', component: DonHangChiTiet, meta: { requiresAuth: true } },
  { path: '/staff/ho-so',   component: StaffHoSo,      meta: { requiresStaff: true } },
  { path: '/binh-luan',    component: BinhLuan },
  { path: '/admin/hoa-don', component: AdminHoaDon,    meta: { requiresAdmin: true } },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach((to) => {
  const auth = useAuthStore()

  // Chưa login → đăng nhập
  if (to.meta.requiresAuth && !auth.isLoggedIn) return '/dang-nhap'

  // Trang admin: chỉ admin
  if (to.meta.requiresAdmin && !auth.isAdmin) return '/'

  // Trang staff POS: admin hoặc nhân viên
  if (to.meta.requiresStaff && !auth.isAdmin && !auth.isNhanVien) return '/'
})

export default router