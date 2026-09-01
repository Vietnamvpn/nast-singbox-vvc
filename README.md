# 🎯 NAST SING-BOX VVC - Hệ Thống Quản Lý Proxy Server

![Version](https://img.shields.io/badge/Version-1.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Author](https://img.shields.io/badge/Author-Vietnamvpn-orange)

**Nast Sing-box VVC** là một hệ thống quản lý proxy server dựa trên **Sing-box**, cung cấp giao diện dòng lệnh (CLI) thân thiện để quản lý các node proxy, chứng chỉ SSL, và dịch vụ Sing-box.

---

## 📚 Tài Liệu

Dự án này cung cấp 4 file tài liệu chi tiết:

### 🚀 [QUICK_START.md](QUICK_START.md) - **Bắt Đầu Nhanh** ⭐
**Dành cho:** Người dùng muốn bắt đầu trong **5 phút**
- ✅ Cài đặt một lệnh
- ✅ Thêm node đầu tiên
- ✅ Các lệnh thường dùng
- ✅ Backup dữ liệu

**Đọc trước nếu bạn mới bắt đầu!**

---

### 📘 [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md) - **Hướng Dẫn Sử Dụng Chi Tiết**
**Dành cho:** Người dùng muốn hiểu **đầy đủ** tất cả tính năng
- 📋 Hướng dẫn cài đặt từng bước
- 🔌 5 loại node hỗ trợ (VLESS, Hy2, Tuic, v.v.)
- 📊 Quản lý Node, SSL, Sing-box
- 🔐 Quản lý Ports & Firewall
- 💾 Cấu trúc thư mục & dữ liệu
- 📝 Ví dụ thực tế

**Đây là hướng dẫn chính, phổ biến nhất.**

---

### 🔧 [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) - **Tài Liệu Kỹ Thuật**
**Dành cho:** Developer & người dùng nâng cao
- 📊 Cấu trúc dữ liệu JSON chi tiết
- 🔌 Tham khảo hàm trong từng module
- 🎯 Protocol specifications (VLESS, Hy2, Tuic)
- 🛠️ Systemd services
- 💡 Performance tuning
- 🔍 Configuration generation flow

**Để mở rộng hoặc tích hợp với hệ thống khác.**

---

### 🐛 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - **Hướng Dẫn Khắc Phục Sự Cố**
**Dành cho:** Khi gặp lỗi hoặc vấn đề
- ❌ Lỗi cài đặt & cách giải
- 🛑 Lỗi Sing-box service
- 📍 Lỗi node
- 🔐 Lỗi SSL/Chứng chỉ
- 🌐 Lỗi kết nối
- ⚡ Lỗi hiệu năng
- 📊 Logs & Debug
- ❓ FAQ

**Tra cứu nhanh khi gặp sự cố!**

---

## ⚡ Bắt Đầu Nhanh

### Lệnh Cài Đặt (Chạy Trên VPS):

**Lệnh Nhanh Nhất** ⭐ (Khuyến Nghị)
```bash
bash <(curl -Ls https://raw.githubusercontent.com/Vietnamvpn/nast-singbox-vvc/main/install.sh)
```

Hoặc dùng Git Clone:
```bash
sudo -i
git clone https://github.com/Vietnamvpn/nast-singbox-vvc.git /root/nast-singbox-vvc
cd /root/nast-singbox-vvc
bash install.sh
```

### Mở Menu
```bash
vvc
```

✅ **Xong!** Bây giờ bạn có thể thêm nodes, quản lý SSL, và điều khiển Sing-box từ menu.

**Muốn hiểu rõ hơn?** → Đọc [QUICK_START.md](QUICK_START.md) (5 phút)

---

## 🎯 Chọn Tài Liệu Phù Hợp

### 🆕 Bạn là người mới?
```
QUICK_START.md → HUONG_DAN_SU_DUNG.md
```
Làm theo từng bước, không bỏ sót chi tiết.

---

### 👨‍💼 Bạn là admin/operator?
```
HUONG_DAN_SU_DUNG.md → TROUBLESHOOTING.md
```
Quản lý hệ thống hàng ngày, khắc phục sự cố.

---

### 👨‍💻 Bạn là developer?
```
TECHNICAL_REFERENCE.md → HUONG_DAN_SU_DUNG.md
```
Hiểu cấu trúc, mở rộng tính năng.

---

### 🆘 Bạn gặp lỗi?
```
TROUBLESHOOTING.md
```
Tra cứu nhanh lỗi và cách giải.

---

## 📋 Tính Năng Chính

### ✅ Quản Lý Node Server
- 🔌 5 loại node: VLESS Reality (TCP/gRPC), VLESS WebSocket, Hysteria2, Tuic
- 🎯 Tự động sinh keys, UUIDs, passwords
- 📍 Tự động mở/đóng firewall ports
- 📊 Xem danh sách node
- 🗑️ Xoá node an toàn

### ✅ Quản Lý Sing-box
- ▶️ Khởi động/Dừng/Khởi động lại dịch vụ
- 📊 Xem status & logs
- 🔄 Tự động load config

### ✅ Quản Lý SSL Cloudflare
- 🔐 Xin chứng chỉ SSL tự động via Cloudflare
- 📝 Lưu chứng chỉ riêng biệt (không ghi đè)
- 📋 Xem danh sách chứng chỉ

### ✅ Cập Nhật & Bảo Trì
- 🔄 Cập nhật mã nguồn từ Git (dữ liệu bảo toàn)
- 📦 Cập nhật Sing-box core
- 🗑️ Gỡ cài đặt an toàn

---

## 🗂️ Cấu Trúc Dự Án

```
/root/nast-singbox-vvc/
├── 📄 README.md                       ← Bạn đang đọc file này
├── 📚 QUICK_START.md                  ← Bắt đầu nhanh (5 phút)
├── 📘 HUONG_DAN_SU_DUNG.md           ← Hướng dẫn chi tiết
├── 🔧 TECHNICAL_REFERENCE.md         ← Tài liệu kỹ thuật
├── 🐛 TROUBLESHOOTING.md             ← Khắc phục sự cố
├── install.sh                         # Cài đặt ban đầu
├── main.sh                            # Menu chính
├── update.sh                          # Cập nhật hệ thống
├── 📁 modules/
│   ├── nodes.sh                      # Quản lý node
│   ├── ssl.sh                        # Quản lý SSL
│   ├── system.sh                     # Quản lý Sing-box
│   └── utils.sh                      # Tiện ích chung
├── 📁 templates/                     # Templates cấu hình
├── 📁 data/                          # Dữ liệu (tự động tạo)
│   ├── nodes.json                   # Danh sách node
│   ├── domain.json                  # Danh sách domain
│   ├── users.json                   # Danh sách user
│   └── config.json                  # Cấu hình chính
└── 📁 certs/                         # Chứng chỉ SSL
    ├── cert.crt                     # Cert mặc định
    └── cert.key                     # Key mặc định
```

---

## 🔌 Loại Node Hỗ Trợ

| Loại | Giao Thức | Transport | Hiệu Năng | Tối Ưu Cho |
|------|----------|-----------|----------|-----------|
| **VLESS Reality (TCP)** | VLESS | TCP | ⭐⭐⭐ | Mọi tình huống |
| **VLESS Reality (gRPC)** | VLESS | gRPC/HTTP2 | ⭐⭐⭐⭐ | Network ổn định |
| **VLESS WebSocket (TLS)** | VLESS | WebSocket | ⭐⭐⭐ | Reverse proxy |
| **Hysteria2 (Hy2)** | QUIC | UDP | ⭐⭐⭐⭐ | Network kém |
| **Tuic** | QUIC | UDP | ⭐⭐⭐ | Network kém |

---

## 🚀 Yêu Cầu Hệ Thống

- **OS:** Linux (Ubuntu/Debian, CentOS, AlmaLinux, v.v.)
- **Quyền:** Root hoặc sudo
- **RAM:** 512MB tối thiểu
- **Disk:** 1GB tối thiểu
- **Network:** Kết nối internet ổn định

---

## 📊 Menu Chính

```
========================================================================
||                      MENU NAST SING-BOX VVC                      ||
========================================================================
 Tác Giả: Vietnamvpn    | Singbox Core: [Phiên bản]
 Trạng Thái: [ĐANG CHẠY/ĐÃ DỪNG] | Website: https://linksub24h.com
========================================================================
 1. Quản Lý Node Server    | 4. Cập Nhật Hệ Thống
 2. Quản Lý Sing-Box       | 5. Gỡ Cài Đặt Hệ Thống
 3. Quản Lý SSL Cloudflare | 0. Thoát Khỏi Hệ Thống
========================================================================
```

---

## 📝 Ví Dụ Sử Dụng

### Ví Dụ 1: Thêm Node VLESS Reality
```bash
vvc
# → Chọn: 1 (Quản Lý Node)
# → Chọn: 1 (Thêm VLESS Reality)
# → Port: [Enter] (tự động)
# → SNI: [Enter] (tự chọn)
# → Domain: example.com
# → Tag: [Enter] (tự động)
```

### Ví Dụ 2: Xin SSL Cloudflare
```bash
vvc
# → Chọn: 3 (Quản Lý SSL)
# → Chọn: 1 (Đăng Ký SSL)
# → Domain: sub.example.com
# → Email CF: your@email.com
# → API Key: [Nhập API Key]
```

### Ví Dụ 3: Khởi Động Lại
```bash
vvc
# → Chọn: 2 (Quản Lý Sing-Box)
# → Chọn: 3 (Khởi Động Lại)
```

---

## 🎓 Học Tập Theo Mức Độ

### 🟢 Beginner (Người Mới)
1. Đọc [QUICK_START.md](QUICK_START.md) (5 phút)
2. Cài đặt (`bash install.sh`)
3. Thêm node đầu tiên

**Tiếp theo:** Đọc phần 1-3 của [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md)

---

### 🟡 Intermediate (Người Dùng)
1. Đọc [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md) đầy đủ
2. Quản lý nhiều node
3. Xin chứng chỉ SSL từ Cloudflare
4. Giám sát logs

**Khi có vấn đề:** Tra cứu [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

### 🔴 Advanced (Developer)
1. Đọc [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
2. Hiểu cấu trúc JSON & functions
3. Tùy chỉnh config
4. Mở rộng tính năng

---

## 🔐 Bảo Mật

### ⚠️ Lưu Ý Quan Trọng
- ✅ Luôn chạy với quyền root
- ✅ Backup dữ liệu định kỳ
- ✅ Cập nhật hệ thống thường xuyên
- ✅ Giám sát logs để phát hiện bất thường
- ⚠️ Không chia sẻ API keys/tokens
- ⚠️ Không để certificate files công khai

### Backup Dữ Liệu
```bash
tar -czf /root/backup-$(date +%Y%m%d).tar.gz \
    /root/nast-singbox-vvc/data \
    /root/nast-singbox-vvc/certs
```

---

## 📞 Hỗ Trợ & Liên Hệ

### Tài Nguyên
- 🌐 **Website:** https://linksub24h.com
- 📦 **GitHub:** https://github.com/Vietnamvpn/nast-singbox-vvc
- 🐛 **Issues:** https://github.com/Vietnamvpn/nast-singbox-vvc/issues
- 🤝 **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
- � **Code of Conduct:** [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- 👤 **Tác Giả:** Vietnamvpn

### Khi Gặp Vấn Đề
1. Tra cứu [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Xem logs: `journalctl -u sing-box -e`
3. Mở issue trên GitHub (tham khảo [CONTRIBUTING.md](CONTRIBUTING.md))

---

## 📄 License

MIT License - Tự do sử dụng cho mục đích cá nhân & thương mại.

---

## 🎯 Tìm Kiếm Nhanh

| Tìm kiếm | Đọc file |
|----------|----------|
| Cài đặt nhanh (< 10 phút) | [QUICK_START.md](QUICK_START.md) |
| Hướng dẫn chi tiết | [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md) |
| Function reference | [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) |
| Lỗi & giải pháp | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Cấu trúc dữ liệu | TECHNICAL_REFERENCE.md → Section 1 |
| Module functions | TECHNICAL_REFERENCE.md → Section 2 |
| Protocol details | TECHNICAL_REFERENCE.md → Section 3 |

---

## 🚀 Bắt Đầu Ngay

```bash
# 1. Cải đặt
sudo -i
bash install.sh

# 2. Mở menu
vvc

# 3. Thêm node từ menu
# Chọn: 1 → 1 → Nhập thông tin
```

**Xong! Hệ thống sẵn sàng sử dụng.** 🎉

---

## 📊 Thống Kê

- ✅ 5 loại node
- ✅ 4 file tài liệu (500+ KB)
- ✅ 100+ lệnh bash
- ✅ 10+ templates config
- ✅ Hỗ trợ 3 loại firewall
- ✅ Tương thích Linux chung

---

## 📄 License

MIT License - Tự do sử dụng cho mục đích cá nhân & thương mại.

Xem chi tiết: [LICENSE](LICENSE)

---

**Version:** 1.0  
**Last Updated:** 2024-01-01  
**Maintained By:** Vietnamvpn Community

---

**Bạn chưa biết bắt đầu từ đâu?** → Đọc [QUICK_START.md](QUICK_START.md) ngay! ⚡
