# ⚡ NAST SING-BOX VVC - QUICK START GUIDE

## 🚀 Bắt Đầu Nhanh Trong 5 Phút

### ⚠️ CHỌN CÁCH CÀI ĐẶT CỦA BẠN:

#### 🖥️ Nếu Cài Trên VPS Server:
```bash
sudo -i
git clone https://github.com/Vietnamvpn/nast-singbox-vvc.git /root/nast-singbox-vvc
cd /root/nast-singbox-vvc
bash install.sh
```

#### 💻 Nếu Cài Trên Local/Client Machine (⭐ Khuyến Nghị):
```bash
bash <(curl -Ls https://raw.githubusercontent.com/Vietnamvpn/nast-singbox-vvc/main/install.sh)
```

### Bước 2: Mở Menu Chính
```bash
vvc
```

### Bước 3: Thêm Node Đầu Tiên
```
Chọn: 1 (Quản Lý Node Server)
Chọn: 1 (Thêm Node VLESS Reality TCP)
Port: [Nhấn Enter]
SNI: [Nhấn Enter]  
Domain: [Nhập IP hoặc domain VPS]
Tag: [Nhấn Enter]
Cert: 1 (mặc định)
```

### Bước 4: Khởi Động Sing-box
```
Chọn: 2 (Quản Lý Sing-Box)
Chọn: 1 (Khởi Động)
```

✅ **Xong! Node đầu tiên đã sẵn sàng.**

---

## 📊 Các Lệnh Thường Dùng

| Tác vụ | Lệnh |
|--------|------|
| Mở menu chính | `vvc` |
| Xem logs | `vvc` → 2 → 4 |
| Khởi động lại | `vvc` → 2 → 3 |
| Xin SSL | `vvc` → 3 → 1 |
| Cập nhật | `vvc` → 4 → 1 |

---

## 🎯 Các Sĩ Việc Phổ Biến

### ✅ Xin SSL từ Cloudflare
1. Chắc chắn domain trỏ DNS đến Cloudflare
2. Vào `vvc` → 3 → 1
3. Nhập: Domain, Email CF, API Key
4. Chứng chỉ sẽ lưu tại `/root/nast-singbox-vvc/certs/`

### ✅ Thêm Nhiều Node
- Lặp lại bước 3 trong "Bắt Đầu Nhanh" nhiều lần
- Mỗi node có port riêng

### ✅ Xem Thông Tin Node
1. Vào `vvc` → 1
2. Chọn 6 (Xem danh sách)
3. Chọn 8 (Xuất config)

### ✅ Xoá Node
1. Vào `vvc` → 1 → 7
2. Chọn node cần xoá
3. Confirm xoá

### ✅ Cập Nhật Sing-box Core
1. Vào `vvc` → 4
2. Chọn 2 (Cập nhật Core)

---

## 💾 Backup Dữ Liệu
```bash
cp -r /root/nast-singbox-vvc/data /root/nast-singbox-vvc/data.backup
cp -r /root/nast-singbox-vvc/certs /root/nast-singbox-vvc/certs.backup
```

---

## 🔍 Kiểm Tra Trạng Thái
```bash
# Xem trạng thái dịch vụ
systemctl status sing-box

# Xem logs real-time
journalctl -u sing-box -f

# Liệt kê ports mở
ss -tuln | grep LISTEN
```

---

## ❌ Gỡ Cài Đặt
```bash
vvc → 5 (Gỡ Cài Đặt)
# ⚠️ Sẽ xóa toàn bộ dữ liệu!
```

---

## 📚 Tài Liệu Chi Tiết
Xem file `HUONG_DAN_SU_DUNG.md` để có hướng dẫn đầy đủ.

---

**Hợp Tác Phát Triển Bởi Vietnamvpn**
