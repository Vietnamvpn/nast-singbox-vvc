# 🔧 NAST SING-BOX VVC - TECHNICAL REFERENCE

## 📚 Tài Liệu Kỹ Thuật Chi Tiết

---

## 1. CẤU TRÚC DỮ LIỆU

### 1.1 Structure of nodes.json
```json
[
  {
    "tag": "VN-2345",                          // Nhận dạng duy nhất
    "port": 2345,                              // Port server
    "protocol": "vless-reality",               // Loại giao thức
    "domain": "vps.example.com",               // Domain/IP VPS
    "server_name": "aws.amazon.com",           // SNI (server_name)
    "cert_path": "/root/nast-singbox-vvc/certs/cert.crt",   // Đường dẫn cert
    "key_path": "/root/nast-singbox-vvc/certs/cert.key",    // Đường dẫn key
    "uuid": "12345678-1234-1234-1234-123456789abc",    // VLESS UUID
    "private_key": "KF...",                   // Reality Private Key
    "public_key": "...",                      // Reality Public Key
    "short_id": "abcd1234",                   // Reality Short ID
    "password": "secretpass123",              // Mật khẩu (Hy2/Tuic)
    "ws_path": "/ws-abc123",                  // WebSocket path
    "service_name": "grpc-service",           // gRPC service name
    "up_mbps": 1000,                          // Bandwidth up (Hy2)
    "down_mbps": 1000                         // Bandwidth down (Hy2)
  }
]
```

### 1.2 Structure of domain.json
```json
[
  {
    "tag": "node-tag",                        // Tag node
    "domain": "sub.example.com"               // Tên miền
  }
]
```

### 1.3 Structure of users.json
```json
[
  {
    "user_id": "user123",
    "email": "user@example.com",
    "bandwidth_limit": 104857600000,          // 100GB bytes
    "bandwidth_used": 0,
    "created_at": "2024-01-01",
    "nodes": ["VN-2345", "VN-3456"]           // Danh sách nodes cho user
  }
]
```

### 1.4 config.json Structure (Build từ Template)
```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "listen": "::",
      "listen_port": 2345,
      "tag": "vless-reality-in",
      "users": [
        {
          "uuid": "12345678-1234-1234-1234-123456789abc",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "certificate_path": "/root/nast-singbox-vvc/certs/cert.crt",
        "key_path": "/root/nast-singbox-vvc/certs/cert.key",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "aws.amazon.com",
            "server_port": 443
          },
          "private_key": "KF...",
          "short_id": ["abcd1234"],
          "max_time_diff": 0
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "freedom",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": []
  }
}
```

---

## 2. MODULE FUNCTIONS REFERENCE

### 2.1 modules/utils.sh

#### Color Definitions
```bash
RED='\033[0;31m'        # Màu đỏ cho lỗi
GREEN='\033[0;32m'      # Màu xanh cho thành công
YELLOW='\033[0;33m'     # Màu vàng cho cảnh báo
BLUE='\033[0;34m'       # Màu xanh dương cho thông tin
CYAN='\033[0;36m'       # Màu lục cho chi tiết
NC='\033[0m'            # Reset màu
```

#### Output Functions
```bash
# In thông báo lỗi và thoát
die "Error message"

# In thông báo thành công
success "Success message"

# In thông báo thông tin
info "Information message"
```

#### Port Management
```bash
# Lấy port ngẫu nhiên trống (2000-6000)
PORT=$(get_random_unused_port)
```

#### Sing-box Service Control
```bash
# Khởi động dịch vụ
start_singbox

# Dừng dịch vụ
stop_singbox

# Khởi động lại dịch vụ
restart_singbox

# Kiểm tra trạng thái
STATUS=$(check_singbox_status)
```

#### Configuration Building
```bash
# Xây dựng config.json từ nodes.json
build_config_json
# Output: /root/nast-singbox-vvc/data/config.json
```

---

### 2.2 modules/nodes.sh

#### Port Management Functions
```bash
# Kiểm tra port đã sử dụng chưa
# Return: 0 (có sẵn), 1 (đã dùng)
check_port_usage PORT

# Lấy random port không sử dụng
PORT=$(get_random_port)

# Mở port trên firewall
open_firewall_port PORT

# Đóng port trên firewall
close_firewall_port PORT
```

**Firewall Support:**
- ufw (Ubuntu/Debian)
- iptables (Linux chung)
- firewall-cmd (CentOS/RHEL)

#### Data Management
```bash
# Lưu domain mapping
save_domain_mapping TAG DOMAIN
# Ví dụ: save_domain_mapping "node-1" "vps.example.com"
```

#### Interactive Input Functions
```bash
# Hỏi port, lưu vào ASKED_PORT
ask_port

# Hỏi SNI, lưu vào ASKED_SNI
ask_sni

# Hỏi domain, lưu vào ASKED_DOMAIN
ask_domain

# Hỏi tag, lưu vào ASKED_TAG
ask_tag "prefix"

# Hỏi chứng chỉ, lưu vào ASKED_CERT và ASKED_KEY
ask_cert
```

**Đặc điểm:**
- Để trống → tự động tạo/chọn giá trị mặc định
- ASKED_* variables được sử dụng bởi form functions

#### Key Generation Functions
```bash
# Sinh Reality Keypair
generate_private_key
# Variables: AUTO_PK (private), AUTO_PUBK (public)

# Sinh 8-character hex Short ID
generate_short_id
# Variable: AUTO_SHORT_ID

# Sinh UUID
generate_uuid
# Variable: AUTO_UUID

# Sinh 16-character random password
generate_password
# Variable: AUTO_PASS
```

#### Validation Functions
```bash
# Kiểm tra tag đã tồn tại chưa
# Return: 0 (tồn tại), 1 (chưa tồn tại)
check_tag_exists
```

#### Node Creation Forms
```bash
# Form VLESS Reality (TCP)
form_vless_reality

# Form VLESS gRPC Reality
form_vless_grpc_reality

# Form VLESS WebSocket TLS
form_vless_ws_tls

# Form Hysteria2
form_hy2

# Form Tuic
form_tuic
```

**Flow trong mỗi form:**
1. Gọi `ask_*` functions để lấy input
2. Gọi `generate_*` functions để sinh keys/IDs
3. Xây dựng JSON object
4. Lưu vào `nodes.json` bằng `jq`
5. Gọi `open_firewall_port` để mở port
6. Khởi động lại Sing-box tự động

---

### 2.3 modules/ssl.sh

#### SSL Certificate Management
```bash
# User input:
domain                 # Tên miền (vd: sub.example.com)
cf_email              # Email Cloudflare
cf_key                # API Key hoặc API Token

# Environment variables:
export CF_Key="$cf_key"
export CF_Email="$cf_email"
```

#### ACME Installation
```bash
# Tự động cài đặt acme.sh nếu chưa có
~/.acme.sh/acme.sh --set-default-ca --server zerossl
```

#### Certificate Request
```bash
# Xin certificate via Cloudflare DNS
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$domain"
```

#### Certificate Installation
```bash
# Cài đặt certificate (không ghi đè)
~/.acme.sh/acme.sh --install-cert -d "$domain" \
    --key-file "$BASE_DIR/certs/${domain}.key" \
    --fullchain-file "$BASE_DIR/certs/${domain}.crt"
```

---

### 2.4 modules/system.sh

#### Service Management
```bash
# Khởi động Sing-box
systemctl start sing-box

# Dừng Sing-box
systemctl stop sing-box

# Khởi động lại
systemctl restart sing-box

# Xem status
systemctl status sing-box

# Xem logs (50 dòng gần nhất)
journalctl -u sing-box -n 50 --no-pager

# Xem logs real-time
journalctl -u sing-box -f
```

---

## 3. PROTOCOL SPECIFICATIONS

### 3.1 VLESS Reality

**Characteristics:**
- Giao thức: VLESS
- Encapsulation: TLS
- Obfuscation: Reality (giả mạo SNI)
- Flow: xtls-rprx-vision

**Configuration:**
```json
{
  "type": "vless",
  "listen_port": PORT,
  "users": [{
    "uuid": "UUID",
    "flow": "xtls-rprx-vision"
  }],
  "tls": {
    "enabled": true,
    "certificate_path": "path/to/cert.crt",
    "key_path": "path/to/key.key",
    "reality": {
      "enabled": true,
      "handshake": {
        "server": "FAKE_SNI",
        "server_port": 443
      },
      "private_key": "PRIVATE_KEY",
      "short_id": ["SHORT_ID"],
      "max_time_diff": 0
    }
  }
}
```

### 3.2 VLESS WebSocket TLS

**Characteristics:**
- Giao thức: VLESS
- Transport: WebSocket
- Encapsulation: TLS
- Best for: Reverse proxy

**Configuration:**
```json
{
  "type": "vless",
  "listen_port": PORT,
  "transport": {
    "type": "ws",
    "path": "/ws"
  },
  "tls": {
    "enabled": true,
    "certificate_path": "path/to/cert.crt",
    "key_path": "path/to/key.key"
  }
}
```

### 3.3 VLESS gRPC Reality

**Characteristics:**
- Giao thức: VLESS
- Transport: gRPC
- Encapsulation: TLS + Reality
- Obfuscation: Reality (giả mạo SNI)
- Best for: Stable network

**Configuration:**
```json
{
  "type": "vless",
  "listen_port": PORT,
  "users": [{
    "uuid": "UUID"
  }],
  "transport": {
    "type": "grpc",
    "service_name": "SERVICE_NAME"
  },
  "tls": {
    "enabled": true,
    "server_name": "FAKE_SNI",
    "reality": {
      "enabled": true,
      "handshake": {
        "server": "FAKE_SNI",
        "server_port": 443
      },
      "private_key": "PRIVATE_KEY",
      "short_id": ["SHORT_ID"]
    }
  }
}
```

### 3.4 Hysteria 2

**Characteristics:**
- Giao thức: QUIC
- Tối ưu: Network kém, tắc đường
- Bandwidth: Adaptable

**Configuration:**
```json
{
  "type": "hysteria2",
  "listen_port": PORT,
  "users": [{
    "password": "PASSWORD"
  }],
  "tls": {
    "enabled": true,
    "certificate_path": "path/to/cert.crt",
    "key_path": "path/to/key.key"
  }
}
```

### 3.5 Tuic

**Characteristics:**
- Giao thức: QUIC
- Tương tự: Hy2 nhưng nhẹ hơn
- Bandwidth: Adaptable

**Configuration:**
```json
{
  "type": "tuic",
  "listen_port": PORT,
  "users": [{
    "uuid": "UUID",
    "password": "PASSWORD"
  }],
  "tls": {
    "enabled": true,
    "certificate_path": "path/to/cert.crt",
    "key_path": "path/to/key.key"
  }
}
```

---

## 4. SYSTEMD SERVICES

### 4.1 sing-box.service
```ini
[Unit]
Description=Sing-box Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/nast-singbox-vvc
ExecStart=/usr/local/bin/sing-box run -c /root/nast-singbox-vvc/data/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### 4.2 Commands
```bash
# Reload systemd daemon
systemctl daemon-reload

# Enable service on startup
systemctl enable sing-box

# Disable service on startup
systemctl disable sing-box

# Start service
systemctl start sing-box

# Stop service
systemctl stop sing-box

# Restart service
systemctl restart sing-box

# View status
systemctl status sing-box

# View logs
journalctl -u sing-box -e
```

---

## 5. ERROR HANDLING

### Common Errors

#### E001: Port Already in Use
```bash
# Tìm process chiếm port
ss -tuln | grep :PORT
lsof -i :PORT

# Kill process
kill -9 PID
```

#### E002: Certificate Not Found
```bash
# Xin chứng chỉ mới
vvc → 3 → 1

# Hoặc tạo self-signed cert
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /root/nast-singbox-vvc/certs/cert.key \
    -out /root/nast-singbox-vvc/certs/cert.crt \
    -subj "/C=VN/ST=State/L=City/O=Org/CN=localhost"
```

#### E003: Sing-box Won't Start
```bash
# Kiểm tra cú pháp config
sing-box check -c /root/nast-singbox-vvc/data/config.json

# Xem chi tiết log
journalctl -u sing-box -e -n 100

# Kiểm tra quyền file
ls -la /root/nast-singbox-vvc/data/config.json
```

#### E004: Firewall Rules Not Applied
```bash
# Kiểm tra ufw
sudo ufw status
sudo ufw allow PORT/tcp
sudo ufw allow PORT/udp

# Hoặc iptables
sudo iptables -tuln | grep PORT
sudo iptables -I INPUT -p tcp --dport PORT -j ACCEPT
```

---

## 6. PERFORMANCE TUNING

### System Optimization
```bash
# Increase file descriptors
ulimit -n 1000000

# Add to /etc/security/limits.conf:
* soft nofile 1000000
* hard nofile 1000000

# BBR Congestion Control (for Hy2/Tuic)
sysctl net.ipv4.tcp_congestion_control=bbr
```

### Network Optimization
```bash
# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf
sysctl -p
```

---

## 7. BACKUP & RESTORE

### Backup
```bash
# Backup all data
tar -czf /root/nast-singbox-backup-$(date +%Y%m%d).tar.gz \
    /root/nast-singbox-vvc/data \
    /root/nast-singbox-vvc/certs

# Move to external storage
mv /root/nast-singbox-backup-*.tar.gz /mnt/backup/
```

### Restore
```bash
# Extract backup
tar -xzf /root/nast-singbox-backup-*.tar.gz -C /

# Restart service
systemctl restart sing-box
```

---

## 8. DEVELOPER NOTES

### Adding New Node Type

1. **Create template** in `templates/inbound_[protocol].json`
2. **Add form function** in `modules/nodes.sh`:
   ```bash
   form_[protocol]() {
       # Input prompts
       # Key generation
       # JSON construction
       # Save to nodes.json
   }
   ```
3. **Add menu option** in `modules/nodes.sh`
4. **Test thoroughly**

### Extending utils.sh

1. Add new function with clear documentation:
   ```bash
   # Description: What it does
   # Usage: function_name arg1 arg2
   # Return: What it returns
   function_name() {
       # Implementation
   }
   ```

2. Use consistent naming conventions:
   - get_* for retrieval
   - set_* for modification
   - check_* for validation
   - *_singbox for Sing-box operations

---

## 9. CONFIGURATION GENERATION FLOW

```
nodes.sh (ask_* functions)
    ↓
Generate keys/IDs (generate_* functions)
    ↓
Build JSON object from template
    ↓
Append to data/nodes.json (jq)
    ↓
Call utils.sh:build_config_json()
    ↓
Merge all inbounds → config.json
    ↓
open_firewall_port
    ↓
restart_singbox
    ↓
✅ Node ready for use
```

---

## 10. CLI COMMANDS REFERENCE

```bash
# Main menu
vvc

# Direct daemon mode
vvc daemon

# Manual operations
systemctl start/stop/restart sing-box
journalctl -u sing-box -f
sing-box version
sing-box check -c config.json
```

---

**Version:** 1.0  
**Last Updated:** 2024-01-01  
**Author:** Vietnamvpn Technical Team
