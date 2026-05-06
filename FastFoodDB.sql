-- =============================================
-- TẠO DATABASE
-- =============================================
CREATE DATABASE FastFoodDB;
GO

USE FastFoodDB;
GO

-- =============================================
-- BẢNG 1: TaiKhoan
-- (phải tạo trước vì HoaDon tham chiếu)
-- =============================================
CREATE DATABASE FastFoodDB;
GO

USE FastFoodDB;
GO

-- =============================================
-- TaiKhoan
-- =============================================
CREATE TABLE TaiKhoan (
    id          INT IDENTITY PRIMARY KEY,
    Email       NVARCHAR(150) NOT NULL UNIQUE,
    Mat_Khau    NVARCHAR(255) NOT NULL,
    Ho_ten      NVARCHAR(150),
    vai_tro     NVARCHAR(20)  DEFAULT 'khachhang',
    hoat_dong   BIT DEFAULT 1
);

-- =============================================
-- LoaiMonAn
-- =============================================
CREATE TABLE LoaiMonAn (
    id          INT IDENTITY PRIMARY KEY,
    Ten_loai    NVARCHAR(100) NOT NULL,
    Mo_ta       NVARCHAR(255),
    Trang_thai  BIT DEFAULT 1
);

-- =============================================
-- KhuyenMai
-- =============================================
CREATE TABLE KhuyenMai (
    id              INT IDENTITY PRIMARY KEY,
    Ten_khuyen_mai  NVARCHAR(150) NOT NULL,
    Phan_tram_giam  INT CHECK (Phan_tram_giam BETWEEN 0 AND 100),
    Ngay_bat_dau    DATETIME,
    Ngay_ket_thuc   DATETIME,
    Trang_thai      BIT DEFAULT 1,
    So_luong        INT
);

-- =============================================
-- MonAn
-- =============================================
CREATE TABLE MonAn (
    id          INT IDENTITY PRIMARY KEY,
    Ten_mon     NVARCHAR(150) NOT NULL,
    Gia         DECIMAL(10,2) NOT NULL CHECK (Gia >= 0),
    Hinh_anh    NVARCHAR(255),
    Trang_thai  BIT DEFAULT 1,
    Loai_id     INT,

    FOREIGN KEY (Loai_id) REFERENCES LoaiMonAn(id)
);

-- =============================================
-- HoaDon (ĐÃ GOM FULL FIELD)
-- =============================================
CREATE TABLE HoaDon (
    id            INT IDENTITY PRIMARY KEY,
    Tai_khoan_id  INT,
    Khuyen_mai_id INT,

    Tong_tien     DECIMAL(10,2) CHECK (Tong_tien >= 0),
    Trang_thai    NVARCHAR(50),

    -- thêm trực tiếp vào đây (không cần ALTER nữa)
    dia_chi       NVARCHAR(255),
    ghi_chu       NVARCHAR(500),
    phuong_thuc_thanh_toan NVARCHAR(50),
    da_thanh_toan BIT DEFAULT 0,

    Ngay_lap      DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (Tai_khoan_id)  REFERENCES TaiKhoan(id),
    FOREIGN KEY (Khuyen_mai_id) REFERENCES KhuyenMai(id)
);

-- =============================================
-- ChiTietHoaDon
-- =============================================
CREATE TABLE ChiTietHoaDon (
    id          INT IDENTITY PRIMARY KEY,
    Hoa_don_id  INT,
    Mon_an_id   INT,

    So_luong    INT CHECK (So_luong > 0),
    Don_gia     DECIMAL(10,2) CHECK (Don_gia >= 0),

    FOREIGN KEY (Hoa_don_id) REFERENCES HoaDon(id),
    FOREIGN KEY (Mon_an_id)  REFERENCES MonAn(id)
);

-- =============================================
-- BinhLuan
-- =============================================
CREATE TABLE BinhLuan (
    id              INT IDENTITY PRIMARY KEY,
    Tai_khoan_id    INT NOT NULL,
    Mon_an_id       INT NOT NULL,

    Noi_dung        NVARCHAR(1000) NOT NULL,
    Diem_danh_gia   TINYINT CHECK (Diem_danh_gia BETWEEN 1 AND 5),

    Ngay_tao        DATETIME DEFAULT GETDATE(),
    Trang_thai      BIT DEFAULT 1,

    FOREIGN KEY (Tai_khoan_id) REFERENCES TaiKhoan(id),
    FOREIGN KEY (Mon_an_id)    REFERENCES MonAn(id)
);

-- =============================================
-- INDEX
-- =============================================
CREATE INDEX IX_HoaDon_TaiKhoan ON HoaDon(Tai_khoan_id);
CREATE INDEX IX_CTHD_HoaDon     ON ChiTietHoaDon(Hoa_don_id);
CREATE INDEX IX_MonAn_Loai      ON MonAn(Loai_id);
CREATE INDEX IX_BinhLuan_MonAn  ON BinhLuan(Mon_an_id);
CREATE INDEX IX_BinhLuan_TK     ON BinhLuan(Tai_khoan_id);

-- =============================================
-- DỮ LIỆU MẪU
-- =============================================

-- TaiKhoan
INSERT INTO TaiKhoan (Email, Mat_Khau, Ho_ten, vai_tro, hoat_dong) VALUES
('admin@yummy.vn',    '123456', N'Admin YumMy',       'admin',     1),
('nv01@yummy.vn',     '123456', N'Trần Văn Minh',     'nhanvien',  1),
('nv02@yummy.vn',     '123456', N'Nguyễn Thị Thu',    'nhanvien',  1),
('khach01@gmail.com', '123456', N'Phạm Thị Lan',      'khachhang', 1),
('khach02@gmail.com', '123456', N'Nguyễn Văn An',     'khachhang', 1),
('khach03@gmail.com', '123456', N'Hoàng Minh Tuấn',   'khachhang', 1);
GO

-- LoaiMonAn
INSERT INTO LoaiMonAn (Ten_loai, Mo_ta, Trang_thai) VALUES
(N'Burger',       N'Hamburger bò, gà các loại',     1),
(N'Pizza',        N'Pizza đế mỏng và đế dày',        1),
(N'Gà Rán',      N'Gà chiên giòn các kiểu',         1),
(N'Combo',        N'Bộ combo tiết kiệm',              1),
(N'Đồ Uống',     N'Nước ngọt, trà, nước ép tươi',   1),
(N'Tráng Miệng', N'Bánh ngọt, kem, dessert',         1),
(N'Khai Vị',     N'Khoai tây, nugget, salad',        1);
GO

-- MonAn
INSERT INTO MonAn (Ten_mon, Gia, Hinh_anh, Trang_thai, Loai_id) VALUES
(N'Burger Bò Đặc Biệt',   89000,  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', 1, 1),
(N'Burger Gà Giòn',        69000,  'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400',   1, 1),
(N'Burger Phô Mai Kép',    109000, 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400', 1, 1),
(N'Burger Tôm Cay',        79000,  'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=400',   1, 1),
(N'Pizza Phô Mai 4 Loại',  115000, 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400', 1, 2),
(N'Pizza Gà BBQ',           125000, 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400', 1, 2),
(N'Pizza Hải Sản',          135000, 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=400', 1, 2),
(N'Gà Rán Giòn Cay',       75000,  'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400', 1, 3),
(N'Cánh Gà Sốt Cay',       85000,  'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400', 1, 3),
(N'Gà Popcorn',              55000,  NULL,                                                                  1, 3),
(N'Combo Gia Đình',          299000, 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400', 1, 4),
(N'Combo Đôi Yêu',           169000, 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400', 1, 4),
(N'Combo 1 Mình',             99000, 'https://images.unsplash.com/photo-1561758033-7e924f619b47?w=400',   1, 4),
(N'Coca Cola Lớn',            25000, NULL, 1, 5),
(N'Trà Đào Cam Sả',          35000, NULL, 1, 5),
(N'Nước Cam Tươi',            30000, NULL, 1, 5),
(N'Trà Sữa Trân Châu',       45000, NULL, 1, 5),
(N'Kem Vani Cone',            20000, NULL, 1, 6),
(N'Cheesecake Dâu',           45000, NULL, 1, 6),
(N'Khoai Tây Chiên Lớn',     45000, NULL, 1, 7),
(N'Nugget Gà 6 Miếng',       55000, NULL, 1, 7),
(N'Khoai Tây Lốc Xoáy',      50000, NULL, 1, 7);
GO

-- KhuyenMai
INSERT INTO KhuyenMai (Ten_khuyen_mai, Phan_tram_giam, Ngay_bat_dau, Ngay_ket_thuc, Trang_thai, So_luong) VALUES
(N'YUMMY20',  20, GETDATE(), DATEADD(month, 3, GETDATE()), 1, 500),
(N'FRIDAY30', 30, GETDATE(), DATEADD(month, 1, GETDATE()), 1, 100),
(N'COMBO15',  15, GETDATE(), DATEADD(month, 2, GETDATE()), 1, 200),
(N'NEWBIE10', 10, GETDATE(), DATEADD(month, 6, GETDATE()), 1, 1000);
GO

-- HoaDon
INSERT INTO HoaDon (Tai_khoan_id, Khuyen_mai_id, Tong_tien, Trang_thai, Ngay_lap) VALUES
(4, 1,    171720, N'hoan_thanh',  DATEADD(day, -6, GETDATE())),
(5, NULL, 299000, N'hoan_thanh',  DATEADD(day, -5, GETDATE())),
(6, 2,    255500, N'hoan_thanh',  DATEADD(day, -4, GETDATE())),
(4, NULL, 169000, N'hoan_thanh',  DATEADD(day, -3, GETDATE())),
(5, NULL, 193000, N'hoan_thanh',  DATEADD(day, -2, GETDATE())),
(6, NULL, 245000, N'hoan_thanh',  DATEADD(day, -1, GETDATE())),
(4, NULL, 169000, N'dang_giao',   GETDATE()),
(5, 4,    180000, N'cho_xac_nhan',GETDATE()),
(6, NULL,  89000, N'da_huy',      GETDATE());
GO

-- ChiTietHoaDon
INSERT INTO ChiTietHoaDon (Hoa_don_id, Mon_an_id, So_luong, Don_gia) VALUES
(1, 1,  2, 89000),  (1, 20, 2, 45000),  (1, 14, 2, 25000),
(2, 11, 1, 299000),
(3, 5,  1, 115000), (3, 8,  2, 75000),  (3, 14, 2, 25000),
(4, 12, 1, 169000),
(5, 3,  1, 109000), (5, 21, 1, 55000),  (5, 16, 1, 30000),
(6, 1,  2, 89000),  (6, 14, 2, 25000),  (6, 20, 1, 45000),
(7, 12, 1, 169000),
(8, 5,  1, 115000), (8, 16, 1, 30000),  (8, 19, 1, 45000), (8, 20, 1, 45000),
(9, 1,  1, 89000);
GO

-- Kiểm tra
SELECT 'TaiKhoan'       AS Bang, COUNT(*) AS SoLuong FROM TaiKhoan       UNION ALL
SELECT 'LoaiMonAn',              COUNT(*)             FROM LoaiMonAn      UNION ALL
SELECT 'MonAn',                  COUNT(*)             FROM MonAn          UNION ALL
SELECT 'KhuyenMai',              COUNT(*)             FROM KhuyenMai      UNION ALL
SELECT 'HoaDon',                 COUNT(*)             FROM HoaDon         UNION ALL
SELECT 'ChiTietHoaDon',          COUNT(*)             FROM ChiTietHoaDon;
GO
USE FastFoodDB;
GO

-- =============================================
-- BẢNG BinhLuan
-- Phụ thuộc: TaiKhoan, MonAn
-- =============================================


-- =============================================
-- DỮ LIỆU MẪU
-- Tai_khoan_id 4,5,6 = khách hàng
-- Mon_an_id theo thứ tự insert trước
-- =============================================
INSERT INTO BinhLuan (Tai_khoan_id, Mon_an_id, Noi_dung, Diem_danh_gia, Ngay_tao) VALUES
(4, 1, N'Burger bò ngon tuyệt! Thịt mềm, sốt BBQ đậm đà. Sẽ order lại!', 5, DATEADD(day,-5,GETDATE())),
(5, 1, N'Khá ngon nhưng hơi mặn một chút. Lần sau bảo ít muối xem sao.', 4, DATEADD(day,-3,GETDATE())),
(6, 1, N'Giao nhanh, đóng gói cẩn thận. Burger còn nóng khi nhận được!', 5, DATEADD(day,-1,GETDATE())),
(4, 5, N'Pizza phô mai 4 loại là yêu thích của cả nhà. Đế giòn, phô mai kéo sợi đẹp lắm.', 5, DATEADD(day,-4,GETDATE())),
(5, 5, N'Ngon nhưng hơi nhỏ so với giá. Mong shop có size lớn hơn.', 3, DATEADD(day,-2,GETDATE())),
(6, 8, N'Gà rán giòn cay chuẩn vị! Không bị ngấy, ăn hoài không chán.', 5, DATEADD(day,-6,GETDATE())),
(4, 8, N'Cay vừa phải, phù hợp cả nhà. Con mình 8 tuổi ăn được.', 4, DATEADD(day,-2,GETDATE())),
(5, 11, N'Combo gia đình quá đỉnh! 4 người ăn no mà giá rất hợp lý.', 5, DATEADD(day,-7,GETDATE())),
(6, 2, N'Burger gà giòn, không bị khô. Sốt mayo ngon. Recommend!', 4, DATEADD(day,-1,GETDATE())),
(4, 12, N'Combo đôi lãng mạn lắm haha. Phần ăn đủ cho 2 người no.', 5, DATEADD(day,-3,GETDATE()));
GO
select * from TaiKhoan
-- Kiểm tra
use FastFoodDB
select * from MonAn
select * from TaiKhoan
select * from HoaDon
Update HoaDon
set da_thanh_toan = 1
where id = 1021
use fastfooddb
select * from khuyenmai
update khuyenmai
set So_luong = 1
where id = 10
select * from hoadon
select * from TaiKhoan
SELECT Trang_thai, COUNT(*) AS SoLuong
FROM HoaDon
GROUP BY Trang_thai
ORDER BY SoLuong DESC;
GO
UPDATE HoaDon
SET Trang_thai = 'cho_thanh_toan'
WHERE phuong_thuc_thanh_toan = 'qr'
AND da_thanh_toan = 0
AND Trang_thai = 'cho_xac_nhan';
select * from taikhoan