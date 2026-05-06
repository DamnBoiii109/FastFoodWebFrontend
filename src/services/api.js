import axios from 'axios'

// ================================================================
//  SỬA DÒNG NÀY GIỐNG VỚI vite.config.js
//  CONTEXT_PATH = '/FastFoodYumMy'  hoặc  ''
// ================================================================
const CONTEXT_PATH = ''  // QUAN TRỌNG

const api = axios.create({
  baseURL: `${CONTEXT_PATH}/api`,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' }
})

// Tự gắn JWT vào header mỗi request
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Tự logout khi token hết hạn (401)
api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/dang-nhap'
    }
    return Promise.reject(err)
  }
)

// ---- Auth ----
export const authAPI = {
  login:    (data) => api.post('/auth/login', data),
  register: (data) => api.post('/auth/register', data),
  me:       ()     => api.get('/auth/me')
}

// ---- Món ăn ----
export const monAnAPI = {
  getAll:  (params)   => api.get('/mon-an', { params }),
  getById: (id)       => api.get(`/mon-an/${id}`),
  create:  (data)     => api.post('/mon-an', data),
  update:  (id, data) => api.put(`/mon-an/${id}`, data),
  delete:  (id)       => api.delete(`/mon-an/${id}`)
}

// ---- Loại món ăn ----
export const loaiMonAnAPI = {
  getAll: () => api.get('/loai-mon-an')
}

// ---- Khuyến mãi ----
export const khuyenMaiAPI = {
  getAll:    ()           => api.get('/khuyen-mai'),
  getActive: ()           => api.get('/khuyen-mai', { params: { active: 'true' } }),
  getById:   (id)         => api.get(`/khuyen-mai/${id}`),
  create:    (data)       => api.post('/khuyen-mai', data),
  update:    (id, data)   => api.put(`/khuyen-mai/${id}`, data),
  delete:    (id)         => api.delete(`/khuyen-mai/${id}`)
}

// ---- Hóa đơn ----
export const hoaDonAPI = {
  getAll:       (params)        => api.get('/hoa-don', { params }),
  getById:      (id)            => api.get(`/hoa-don/${id}`),
  create:       (data)          => api.post('/hoa-don', data),
  // [THÊM] update dùng cho sửa diaChi/ghiChu ở đơn cho_thanh_toan
  update:       (id, data)      => api.put(`/hoa-don/${id}`, data),
  updateStatus: (id, trangThai) => api.put(`/hoa-don/${id}`, { trangThai }),
  xacNhanThanhToan: (id) => api.put(`/hoa-don/${id}`, {
    trangThai:   'cho_xac_nhan',
    daThanhToan: true
  }),
  updateInfo:   (id, data) => api.put(`/hoa-don/${id}`, data),
  updateItems:  (id, items) => api.put(`/hoa-don/${id}/items`, { items }),
}


// ---- Tài khoản ----
export const taiKhoanAPI = {
  getAll:  ()           => api.get('/tai-khoan'),
  getById: (id)         => api.get(`/tai-khoan/${id}`),
  create:  (data)       => api.post('/tai-khoan', data),
  update:  (id, data)   => api.put(`/tai-khoan/${id}`, data),
  delete:  (id)         => api.delete(`/tai-khoan/${id}`)
}

// ---- Thống kê ----
export const thongKeAPI = {
  get: () => api.get('/thong-ke')
}

// ---- Bình luận ----
export const binhLuanAPI = {
  // Lấy bình luận theo món ăn
  getByMonAn: (monAnId) => api.get('/binh-luan', { params: { monAnId } }),

  // [THÊM] Lấy tất cả bình luận (dùng cho trang /binh-luan)
  getAll:     (params)  => api.get('/binh-luan', { params }),

  // [THÊM] Lấy N bình luận mới nhất — dùng cho trang chủ
  // Yêu cầu BE có endpoint: GET /api/binh-luan/recent?limit=3
  // Nếu BE chưa có, sẽ catch error và dùng fallback tự động
  getRecent:  (limit = 3) => api.get('/binh-luan/recent', { params: { limit } }),

  create:  (data)       => api.post('/binh-luan', data),
  update:  (id, data)   => api.put(`/binh-luan/${id}`, data),
  delete:  (id)         => api.delete(`/binh-luan/${id}`)
}

export default api