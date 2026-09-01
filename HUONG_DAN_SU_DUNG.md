# 📘 HƯỚNG DẪN SỬ DỤNG NAST SING-BOX VVC

## 📌 Giới Thiệu

**Nast Sing-box VVC** là một hệ thống quản lý proxy server dựa trên Sing-box, được phát triển bởi **Vietnamvpn**. Hệ thống cung cấp giao diện dòng lệnh (CLI) thân thiện để quản lý:
- Các node server proxy
- Dịch vụ Sing-box
- Chứng chỉ SSL từ Cloudflare
- Cập nhật hệ thống

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT

### Yêu Cầu Hệ Thống
- **Hệ điều hành**: Linux (Ubuntu/Debian, CentOS, etc.)
- **Quyền truy cập**: Root hoặc sudo
- **Kết nối mạng**: Truy cập internet để cài đặt dependencies

### Các Bước Cài Đặt

#### 🖥️ CÀI ĐẶT TRÊN VPS SERVER

**Phương Pháp 1: Lệnh Nhanh Nhất** ⭐ (Khuyến Nghị)
```bash
bash <(curl -Ls https://raw.githubusercontent.com/Vietnamvpn/nast-singbox-vvc/main/install.sh)
```

Cách này sẽ:
- Tải `install.sh` từ GitHub
- Chạy script để cài đặt
- Tự động tải mã nguồn về `/root/nast-singbox-vvc`
- Cài đặt dependencies
- Thiết lập dịch vụ systemd cho Sing-box

---

**Phương Pháp 2: Clone từ GitHub (Thay Thế)**
```bash
sudo -i
git clone https://github.com/Vietnamvpn/nast-singbox-vvc.git /root/nast-singbox-vvc
cd /root/nast-singbox-vvc
bash install.sh
```

---

**Phương Pháp 3: Upload File Local Lên VPS (Thay Thế)**
1. Tải repository về local máy của bạn
2. Upload toàn bộ thư mục lên VPS (SCP hoặc SFTP)
3. SSH vào VPS và chạy:
```bash
cd /root/nast-singbox-vvc
bash install.sh
```
   - Cài đặt các gói phụ thuộc (curl, wget, jq, git, openssl, netcat, uuid-runtime)
   - Tải mã nguồn từ GitHub
   - Tạo các thư mục dữ liệu (`data/`, `certs/`)
   - Tạo chứng chỉ SSL tự ký mặc định
   - Thiết lập dịch vụ systemd cho Sing-box

3. **Xác Nhận Cài Đặt Thành Công**
   ```bash
   vvc
   ```
   Nếu hiển thị menu chính, cài đặt đã hoàn tất!

---

## 📋 MENU CHÍNH

Để truy cập menu chính, chạy lệnh:
```bash
vvc
```

### Các Tùy Chọn Chính

```
========================================================================
||                      MENU NAST SING-BOX VVC                      ||
========================================================================
 Tác Giả: Vietnamvpn    | Singbox Core: [Phiên bản]
 Trạng Thái : [Đang chạy/Đã dừng] | Trang Web: https://linksub24h.com
========================================================================
 1. Quản Lý Node Server    | 4. Cập Nhật Hệ Thống
 2. Quản Lý Sing-Box       | 5. Gỡ Cài Đặt Hệ Thống
 3. Quản Lý SSL Cloudflare | 0. Thoát Khỏi Hệ Thống
========================================================================
```

---

## 1️⃣ QUẢN LÝ NODE SERVER

### Truy Cập
Từ menu chính, chọn **1. Quản Lý Node Server**

### Menu Quản Lý Node (4 Tùy Chọn)

```
1. Danh sách Link kết nối    (Hiển thị proxy links)
2. Thêm Node mới             (Thêm node mới - chọn giao thức)
3. Cập nhật Node             (Chỉnh sửa node hiện có)
4. Xóa Node                  (Xóa 1 node hoặc tất cả)
0. Quay lại Menu chính
```

---

### ✨ Chi Tiết Từng Chức Năng

#### **1. Danh Sách Link Kết Nối**

**Mục đích:** Hiển thị các connection links (proxy URIs) mà bạn có thể chia sẻ cho clients

**Thông tin hiển thị:**
- Link kết nối đầy đủ cho mỗi node
- Format: `protocol://...` (vless://, hysteria2://, tuic://, v.v.)
- Có thể copy để chia sẻ hoặc import vào client

**Lưu ý:**
- Links được tạo tự động từ thông tin node
- UUID được lấy từ user mặc định (admin)
- Tất cả thông tin (port, domain, SNI, keys) được tính toán tự động

---

#### **2. Thêm Node Mới**

**Bước 1:** Chọn giao thức

```
1. VLESS REALITY (TCP)       ← Khuyến nghị, hiệu năng cao
2. VLESS WebSocket TLS       ← Dùng cho reverse proxy
3. VLESS gRPC REALITY        ← Tốt nhất cho network ổn định
4. Hysteria 2                ← Tối ưu cho network kém
5. TUIC                      ← Nhẹ, hiệu quả
0. Quay lại
```

**Bước 2:** Nhập thông tin Node

Tuỳ theo giao thức, bạn sẽ được hỏi:

**Port (Bắt buộc):**
- Để trống → Tự động chọn port ngẫu nhiên (2000-6000)
- Hoặc nhập số port cụ thể (1-65535)
- Tự động mở port trên firewall

**Domain (Tùy chọn):**
- Nhập tên miền hoặc IP VPS
- Để trống → Tự động lấy IP công cộng của VPS

**SNI (Chỉ VLESS Reality):**
- Tên miền giả để pass firewall
- Để trống → Tự động chọn từ danh sách (aws.amazon.com, itunes.apple.com, v.v.)

**Tag (Tên nhận dạng):**
- Tên duy nhất để phân biệt các node
- Để trống → Tự động tạo từ quốc gia + port (ví dụ: VN-2345)

**Chứng chỉ SSL:**
- Chọn từ danh sách chứng chỉ có sẵn
- Nếu không có, sẽ dùng cert mặc định (self-signed)

**Bước 3:** Hệ thống tự động

Sau khi nhập thông tin, script sẽ tự động:
- ✅ Sinh Reality Keypair (nếu VLESS Reality)
- ✅ Sinh Short ID (8 ký tự hex)
- ✅ Sinh UUID & Password
- ✅ Mở port trên firewall
- ✅ Lưu vào `data/nodes.json`
- ✅ Build config.json
- ✅ Khởi động lại Sing-box

**Thêm nhiều node liên tiếp:**
Sau khi thêm xong, script hỏi "Bạn có muốn thêm giao thức nữa không? (y/n)"
- Nếu chọn `y`: Quay lại bước 1, tiếp tục thêm
- Nếu chọn `n`: Kết thúc

---

#### **3. Cập Nhật Node**

**Chọn Node:**
Hiển thị danh sách tất cả nodes, chọn số thứ tự

**Chỉnh Sửa:**
- **Tag mới**: Đổi tên nhận dạng node
- **Domain mới**: Đổi tên miền/IP
- **Port mới**: Đổi port (tự kiểm tra port trống)
- **SSL Certificate**: Chọn lại chứng chỉ SSL

**Sau khi cập nhật:**
- Config.json được build lại tự động
- Sing-box khởi động lại để áp dụng thay đổi

---

#### **4. Xóa Node**

**Chọn Node:**
Hiển thị danh sách, chọn số thứ tự node cần xóa

**Các tùy chọn:**
```
- Nhập số: Xóa node đó (cần xác nhận)
- Để trống: Xóa TẤT CẢ node (cần xác nhận 2 lần)
- Nhập 0: Hủy
```

**Sau khi xóa:**
- ✅ Tự động đóng port trên firewall
- ✅ Xóa khỏi `nodes.json`
- ✅ Build config.json lại
- ✅ Khởi động lại Sing-box

---

## 2️⃣ QUẢN LÝ SING-BOX

### Truy Cập
Từ menu chính, chọn **2. Quản Lý Sing-Box**

### Các Chức Năng

#### **2.1 Khởi Động Sing-box**
```bash
> Chọn: 1
```
- **Tác vụ:** Khởi động dịch vụ Sing-box
- **Kiểm tra:** Nếu thành công, dịch vụ sẽ chạy trong background

#### **2.2 Dừng Sing-box**
```bash
> Chọn: 2
```
- **Tác vụ:** Dừng hoàn toàn dịch vụ Sing-box
- **Lưu ý:** Client sẽ mất kết nối

#### **2.3 Khởi Động Lại Sing-box**
```bash
> Chọn: 3
```
- **Tác vụ:** Dừng rồi khởi động lại dịch vụ
- **Khi dùng:** Khi cập nhật cấu hình hoặc thêm node mới

#### **2.4 Xem Nhật Ký Hoạt Động (Logs)**
```bash
> Chọn: 4
```
- **Tác vụ:** Hiển thị 50 dòng log gần nhất của Sing-box
- **Hữu ích để:** Kiểm tra lỗi hoặc giám sát trạng thái kết nối

### Trạng Thái Sing-box
- **ĐANG CHẠY** (xanh): Dịch vụ hoạt động bình thường
- **ĐÃ DỪNG** (đỏ): Dịch vụ không chạy

---

## 3️⃣ QUẢN LÝ SSL CLOUDFLARE

### Truy Cập
Từ menu chính, chọn **3. Quản Lý SSL Cloudflare**

### Các Chức Năng

#### **3.1 Đăng Ký Chứng Chỉ SSL Mới**
```bash
> Chọn: 1
```

**Các bước:**

1. **Nhập Tên Miền** (ví dụ: `sub.example.com`)
   - Miền này phải trỏ DNS đến VPS của bạn thông qua Cloudflare

2. **Nhập Cloudflare Account Email**
   - Email tài khoản Cloudflare của bạn

3. **Nhập Cloudflare Global API Key hoặc API Token**
   - Lấy từ: Cloudflare Dashboard → Account Settings → API Tokens

**Hoạt động tự động:**
- Kiểm tra và cài đặt `acme.sh` (ACME client)
- Xin chứng chỉ SSL từ ZeroSSL qua Cloudflare DNS
- Lưu chứng chỉ vào `/root/nast-singbox-vvc/certs/`
- Lưu thông tin domain vào `data/domain.json`

**Kết quả:**
- File chứng chỉ: `certs/[domain].crt`
- File khóa riêng: `certs/[domain].key`

#### **3.2 Xem Danh Sách Chứng Chỉ Hiện Có**
```bash
> Chọn: 2
```

- Hiển thị tất cả chứng chỉ `.crt` trong thư mục `certs/`
- Thông tin bao gồm: Tên file, Subject (chủ thể), hạn sử dụng (Not After)

---

## 4️⃣ CẬP NHẬT HỆ THỐNG

### Truy Cập
Từ menu chính, chọn **4. Cập Nhật Hệ Thống**

### Các Chức Năng

#### **4.1 Cập Nhật Mã Nguồn Script**
```bash
> Chọn: 1
```

**Tác vụ:**
- Kéo bản cập nhật mã nguồn từ GitHub
- Đồng bộ lại toàn bộ script
- **Dữ liệu bạn sẽ KHÔNG bị xoá** (thư mục `data/` và `certs/` không bị ảnh hưởng)

**Khi dùng:** Khi bạn muốn cập nhật các tính năng mới hoặc bản vá lỗi

#### **4.2 Cập Nhật Sing-box Core**
```bash
> Chọn: 2
```

**Tác vụ:**
- Kiểm tra phiên bản Sing-box mới nhất từ GitHub
- Tự động phát hiện kiến trúc CPU (x86_64, ARM64, v.v.)
- Tải phiên bản mới nhất
- Thay thế binary cũ

**Lợi ích:** Lấy những cải tiến bảo mật và tính năng mới của Sing-box

---

## 5️⃣ GỠ CÀI ĐẶT HỆ THỐNG

### ⚠️ CẢNH BÁO
Chức năng này sẽ **XOÁ TOÀN BỘ** dữ liệu, không thể khôi phục!

### Truy Cập
Từ menu chính, chọn **5. Gỡ Cài Đặt Hệ Thống**

### Hoạt Động
- Dừng các dịch vụ (sing-box, manager)
- Vô hiệu hóa systemd services
- Xóa binary Sing-box
- Xóa lệnh CLI `vvc`
- Xóa toàn bộ thư mục mã nguồn `/root/nast-singbox-vvc`

---

## 📁 CẤU TRÚC THƯ MỤC

```
/root/nast-singbox-vvc/
├── main.sh                          # Script entry point (menu chính)
├── install.sh                       # Script cài đặt ban đầu
├── update.sh                        # Script cập nhật hệ thống
├── modules/
│   ├── nodes.sh                     # Module quản lý node
│   ├── ssl.sh                       # Module quản lý SSL
│   ├── system.sh                    # Module quản lý Sing-box
│   └── utils.sh                     # Hàm tiện ích chung
├── templates/                       # Các template cấu hình
│   ├── config.base.json             # Cấu hình base
│   ├── manager.service              # Service file cho manager
│   ├── sing-box.service             # Service file cho sing-box
│   ├── inbound_hy2.json             # Template Hysteria2
│   ├── inbound_tuic.json            # Template Tuic
│   └── vless/
│       ├── vless-reality.json       # Template VLESS Reality
│       ├── vless-grpc-reality.json  # Template VLESS gRPC Reality
│       └── vless-ws-tls.json        # Template VLESS WebSocket TLS
├── data/                            # Thư mục dữ liệu (tạo tự động)
│   ├── nodes.json                   # Danh sách node
│   ├── domain.json                  # Danh sách domain
│   ├── users.json                   # Danh sách user
│   └── config.json                  # Cấu hình chính
├── certs/                           # Thư mục chứng chỉ SSL (tạo tự động)
│   ├── cert.crt                     # Chứng chỉ mặc định
│   ├── cert.key                     # Khóa riêng mặc định
│   └── [domain].crt/.key            # Chứng chỉ từ Cloudflare
```

---

## 🔌 CÁC LOẠI NODE HỖ TRỢ

### 1. VLESS Reality (TCP)
- **Giao thức:** VLESS
- **Đặc tính:** Giả mạo SNI, khó phát hiện
- **Hiệu năng:** Cao, ổn định
- **Port:** TCP

### 2. VLESS Reality (gRPC)
- **Giao thức:** VLESS qua gRPC
- **Đặc tính:** Sử dụng HTTP/2 multiplexing
- **Hiệu năng:** Rất cao
- **Port:** TCP

### 3. VLESS WebSocket (TLS)
- **Giao thức:** VLESS qua WebSocket với TLS
- **Đặc tính:** Dễ triển khai, có thể qua reverse proxy
- **Hiệu năng:** Khá tốt
- **Port:** TCP (443 thường dùng)

### 4. Hysteria 2 (Hy2)
- **Giao thức:** QUIC
- **Đặc tính:** Tối ưu cho network kém
- **Hiệu năng:** Xuất sắc trên đường truyền không ổn định
- **Port:** UDP

### 5. Tuic
- **Giao thức:** QUIC
- **Đặc tính:** Tương tự Hy2, nhưng nhẹ hơn
- **Hiệu năng:** Tốt trên network kém
- **Port:** UDP

---

## 🔐 QUẢN LÝ PORTS & FIREWALL

### Tự Động Mở/Đóng Port
- Khi thêm node, script **tự động mở port** trên tường lửa
- Khi xoá node, script **tự động đóng port**

### Hỗ Trợ Firewall
- **ufw** (Ubuntu/Debian)
- **iptables** (Linux chung)
- **firewall-cmd** (CentOS/RHEL)

### Xem Các Port Mở
```bash
ss -tuln | grep LISTEN
# hoặc
netstat -tuln | grep LISTEN
```

---

## 📊 QUẢN LÝ DỮ LIỆU

### Các File JSON

#### **data/nodes.json**
Chứa danh sách tất cả node, mỗi node có cấu trúc:
```json
{
  "tag": "VN-2345",
  "port": 2345,
  "protocol": "vless-reality",
  "domain": "vps.example.com",
  "sni": "aws.amazon.com",
  "cert": "/root/nast-singbox-vvc/certs/cert.crt",
  "key": "/root/nast-singbox-vvc/certs/cert.key",
  "uuid": "12345678-1234-1234-1234-123456789abc",
  "private_key": "...",
  "public_key": "...",
  "short_id": "abcd1234",
  "created_at": "2024-01-01 12:00:00"
}
```

#### **data/domain.json**
Danh sách tên miền:
```json
[
  {"domain": "sub.example.com"},
  {"domain": "vps.ip.address"}
]
```

#### **data/users.json**
Danh sách user (dành cho quản lý user/bandwidth)

#### **data/config.json**
Cấu hình Sing-box chính

---

## 🛠️ TÍNH NĂNG HỖ TRỢ TRONG CÁC MODULE

### Module: nodes.sh
| Chức năng | Mô tả |
|-----------|-------|
| `check_port_usage()` | Kiểm tra port đã sử dụng chưa |
| `get_random_port()` | Lấy port ngẫu nhiên từ 2000-6000 |
| `open_firewall_port()` | Mở port trên firewall |
| `close_firewall_port()` | Đóng port trên firewall |
| `generate_private_key()` | Sinh Reality Keypair |
| `generate_short_id()` | Sinh Short ID (8 ký tự hex) |
| `generate_uuid()` | Sinh UUID |
| `generate_password()` | Sinh mật khẩu ngẫu nhiên |
| `ask_port()`, `ask_sni()`, `ask_domain()`, `ask_tag()`, `ask_cert()` | Hỏi thông tin input từ user |
| `form_vless_reality()`, `form_vless_reality_grpc()`, `form_vless_ws_tls()`, `form_hy2()`, `form_tuic()` | Form tạo từng loại node |

### Module: ssl.sh
| Chức năng | Mô tả |
|-----------|-------|
| Đăng ký SSL Cloudflare | Sử dụng acme.sh + DNS challenge |
| Xem danh sách chứng chỉ | Liệt kê tất cả .crt files |

### Module: system.sh
| Chức năng | Mô tả |
|-----------|-------|
| Khởi động/Dừng/Restart | Điều khiển systemd service |
| Xem Logs | Hiển thị 50 dòng log gần nhất |

### Module: utils.sh
| Chức năng | Mô tả |
|-----------|-------|
| `die()`, `success()`, `info()` | In thông báo |
| `get_random_unused_port()` | Lấy port ngẫu nhiên trống |
| `start_singbox()`, `stop_singbox()`, `restart_singbox()` | Điều khiển Sing-box |
| `check_singbox_status()` | Kiểm tra trạng thái dịch vụ |
| `build_config_json()` | Xây dựng file cấu hình |

---

## 📝 VÍ DỤ THỰC TẾ

### Ví Dụ 1: Thêm Node VLESS Reality Mới

```bash
vvc
# Chọn: 1 (Quản Lý Node Server)
# Chọn: 1 (Thêm Node VLESS Reality TCP)
# Nhập Port: [Enter để tự động chọn]
# Nhập SNI: [Enter để tự chọn]
# Nhập Domain: example.com
# Nhập Tag: [Enter để tạo tự động]
# Chọn Chứng chỉ: [Chọn từ danh sách]
```

### Ví Dụ 2: Xin Chứng Chỉ SSL Mới

```bash
vvc
# Chọn: 3 (Quản Lý SSL Cloudflare)
# Chọn: 1 (Đăng Ký Chứng Chỉ SSL)
# Nhập Domain: sub.example.com
# Nhập Email Cloudflare: your@email.com
# Nhập API Key: [Global API Key từ Cloudflare]
```

### Ví Dụ 3: Khởi Động Lại Sing-box Sau Khi Thêm Node

```bash
vvc
# Chọn: 2 (Quản Lý Sing-Box)
# Chọn: 3 (Khởi Động Lại Sing-box)
# Đợi kết quả thành công
```

---

## 🔧 ĐIỀU CHỈNH CẤU HÌNH THỦ CÔNG

### Sửa File Cấu Hình
```bash
nano /root/nast-singbox-vvc/data/config.json
```

### Sửa Danh Sách Node
```bash
nano /root/nast-singbox-vvc/data/nodes.json
```

### Sau Khi Sửa, Khởi Động Lại Sing-box
```bash
vvc
# Chọn: 2 → 3 (Khởi Động Lại)
```

---

## 🐛 KHẮC PHỤC SỰ CỐ

### Sing-box Không Khởi Động
```bash
# Xem chi tiết lỗi
journalctl -u sing-box -e -n 50

# Kiểm tra cú pháp config
sing-box check -c /root/nast-singbox-vvc/data/config.json
```

### Port Bị Chiếm Dụng
```bash
# Tìm process chiếm port
ss -tuln | grep :[PORT]
lsof -i :[PORT]

# Kill process (nếu cần)
kill -9 [PID]
```

### Chứng Chỉ SSL Hết Hạn
```bash
# Xin lại chứng chỉ từ menu
vvc → 3 → 1
```

### Lỗi Kết Nối Cloudflare
- Kiểm tra API Key
- Kiểm tra email Cloudflare
- Kiểm tra tên miền trỏ DNS đúng Cloudflare

---

## 📞 LIÊN HỆ & HỖ TRỢ

- **Tác Giả:** Vietnamvpn
- **Trang Web:** https://linksub24h.com
- **GitHub:** https://github.com/Vietnamvpn/nast-singbox-vvc

---

## 📄 GHI CHÚ QUAN TRỌNG

1. **Luôn chạy với quyền Root**
   ```bash
   sudo -i
   vvc
   ```

2. **Backup dữ liệu trước khi cập nhật**
   ```bash
   cp -r /root/nast-singbox-vvc/data /root/nast-singbox-vvc/data.backup
   cp -r /root/nast-singbox-vvc/certs /root/nast-singbox-vvc/certs.backup
   ```

3. **Kiểm tra logs khi gặp lỗi**
   ```bash
   vvc → 2 → 4 (Xem Logs)
   ```

4. **Firewall phải mở đúng port** để client kết nối được

5. **Domain phải trỏ đúng VPS IP** để Cloudflare xin certificate được

---

**Phiên bản tài liệu:** 1.0  
**Cập nhật lần cuối:** 2024-01-01
