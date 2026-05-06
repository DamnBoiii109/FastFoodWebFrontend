import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useCartStore = defineStore('cart', () => {
  // Khôi phục giỏ từ localStorage
  const items = ref(JSON.parse(localStorage.getItem('cart') || '[]'))
  const khuyenMai = ref(null)

  // Tổng số lượng
  const totalItems = computed(() =>
    items.value.reduce((s, i) => s + i.soLuong, 0))

  // Tổng tiền trước giảm
  const subtotal = computed(() =>
    items.value.reduce((s, i) => s + i.gia * i.soLuong, 0))

  // Số tiền được giảm
  const discountAmount = computed(() => {
    if (!khuyenMai.value) return 0
    return Math.round(subtotal.value * khuyenMai.value.phanTramGiam / 100)
  })

  // VAT 8%
  const vat = computed(() => Math.round((subtotal.value - discountAmount.value) * 0.08))

  // Tổng cuối
  const total = computed(() => subtotal.value - discountAmount.value + vat.value)

  function saveToLocal() {
    localStorage.setItem('cart', JSON.stringify(items.value))
  }

  function addItem(monAn) {
    const existing = items.value.find(i => i.id === monAn.id)
    if (existing) {
      existing.soLuong++
    } else {
      items.value.push({
        id: monAn.id,
        tenMon: monAn.tenMon,
        gia: monAn.gia,
        hinhAnh: monAn.hinhAnh,
        soLuong: 1
      })
    }
    saveToLocal()
  }

  function removeItem(monAnId) {
    items.value = items.value.filter(i => i.id !== monAnId)
    saveToLocal()
  }

  function updateQty(monAnId, qty) {
    const item = items.value.find(i => i.id === monAnId)
    if (!item) return
    if (qty <= 0) {
      removeItem(monAnId)
    } else {
      item.soLuong = qty
      saveToLocal()
    }
  }

  function applyKhuyenMai(km) { khuyenMai.value = km }
  function removeKhuyenMai() { khuyenMai.value = null }

  function clearCart() {
    items.value = []
    khuyenMai.value = null
    localStorage.removeItem('cart')
  }

  // Chuyển giỏ thành payload cho API
  function toOrderPayload() {
    return {
      items: items.value.map(i => ({ monAnId: i.id, soLuong: i.soLuong })),
      khuyenMaiId: khuyenMai.value?.id || null
    }
  }

  return {
    items, khuyenMai, totalItems, subtotal, discountAmount, vat, total,
    addItem, removeItem, updateQty, applyKhuyenMai, removeKhuyenMai,
    clearCart, toOrderPayload
  }
})