# 🐛 NAST SING-BOX VVC - TROUBLESHOOTING GUIDE

## 🔍 Hướng Dẫn Khắc Phục Sự Cố

---

## 📋 MỤC LỤC
1. [Vấn Đề Cài Đặt](#vấn-đề-cài-đặt)
2. [Vấn Đề Sing-box Service](#vấn-đề-sing-box-service)
3. [Vấn Đề Node](#vấn-đề-node)
4. [Vấn Đề SSL/Chứng Chỉ](#vấn-đề-sslchứng-chỉ)
5. [Vấn Đề Kết Nối](#vấn-đề-kết-nối)
6. [Vấn Đề Hiệu Năng](#vấn-đề-hiệu-năng)
7. [Vấn Đề Firewall/Port](#vấn-đề-firewallport)
8. [Vấn Đề Cơ Sở Dữ Liệu](#vấn-đề-cơ-sở-dữ-liệu)
9. [Logs & Debugging](#logs--debugging)
10. [FAQ - Câu Hỏi Thường Gặp](#faq---câu-hỏi-thường-gặp)

---

## 🔧 VẤN ĐỀ CÀI ĐẶT

### ❌ Lỗi: "Permission denied"
**Nguyên nhân:** Không chạy với quyền root

**Giải pháp:**
```bash
sudo -i
bash install.sh
```

**Kiểm tra quyền:**
```bash
whoami  # Phải hiển thị "root"
```

---

### ❌ Lỗi: "Không thể kết nối GitHub"
**Nguyên nhân:** Kết nối mạng yếu hoặc GitHub bị chặn

**Giải pháp:**
```bash
# 1. Kiểm tra kết nối
ping github.com
curl -I https://github.com

# 2. Thử lại cài đặt
bash install.sh

# 3. Nếu GitHub chậm, clone thủ công
git clone https://github.com/Vietnamvpn/nast-singbox-vvc.git /root/nast-singbox-vvc
cd /root/nast-singbox-vvc
chmod +x *.sh modules/*.sh
```

---

### ❌ Lỗi: "Gói không tìm thấy" (apt-get)
**Nguyên nhân:** Repository chưa cập nhật

**Giải pháp:**
```bash
# Update repositories
apt-get update

# Xoá dependencies cũ
apt-get autoremove -y

# Cài lại
bash install.sh
```

---

### ❌ Lỗi: "Cannot execute binary file"
**Nguyên nhân:** Kiến trúc CPU không hỗ trợ hoặc binary bị hỏng

**Giải pháp:**
```bash
# Kiểm tra kiến trúc CPU
uname -m

# Hỗ trợ: x86_64, aarch64 (ARM64)
# Không hỗ trợ: i386, armv7l

# Nếu không tương thích, cần VPS khác
```

---

## 🛑 VẤN ĐỀ SING-BOX SERVICE

### ❌ Lỗi: "sing-box failed to start"
**Nguyên nhân:** Cấu hình JSON sai cú pháp hoặc port chiếm dụng

**Giải pháp (Bước 1): Kiểm tra cú pháp**
```bash
sing-box check -c /root/nast-singbox-vvc/data/config.json
```

Nếu có lỗi, sẽ hiển thị chi tiết. Ví dụ:
```
Error: invalid JSON: expected '}' at line 15
```

**Giải pháp (Bước 2): Sửa config**
```bash
nano /root/nast-singbox-vvc/data/config.json
# Sửa lỗi theo hướng dẫn
```

**Giải pháp (Bước 3): Khởi động lại**
```bash
systemctl restart sing-box
systemctl status sing-box
```

---

### ❌ Lỗi: "Address already in use"
**Nguyên nhân:** Port hoặc address đã được process khác dùng

**Giải pháp:**
```bash
# 1. Tìm process chiếm port
ss -tuln | grep LISTEN
lsof -i -P -n

# 2. Xác định PID
lsof -i :PORT

# 3. Kill process (nếu cần)
kill -9 PID

# 4. Hoặc dừng Sing-box
systemctl stop sing-box
```

---

### ❌ Lỗi: "TLS handshake failed"
**Nguyên nhân:** Chứng chỉ SSL hết hạn, không hợp lệ, hoặc sai đường dẫn

**Giải pháp:**
```bash
# 1. Kiểm tra tệp cert & key tồn tại
ls -la /root/nast-singbox-vvc/certs/

# 2. Xem thông tin chứng chỉ
openssl x509 -in /root/nast-singbox-vvc/certs/cert.crt -text -noout

# 3. Kiểm tra ngày hết hạn (Not After)
# Nếu hết hạn, xin chứng chỉ mới:
vvc → 3 → 1

# 4. Xác minh cert & key khớp
openssl x509 -noout -modulus -in /root/nast-singbox-vvc/certs/cert.crt | md5sum
openssl rsa -noout -modulus -in /root/nast-singbox-vvc/certs/cert.key | md5sum
# Hai giá trị MD5 phải giống nhau
```

---

### ❌ Lỗi: "reality: short_id mismatch"
**Nguyên nhân:** Short ID client không khớp với server

**Giải pháp:**
```bash
# 1. Xem short_id trong config
jq '.inbounds[] | select(.reality) | .tls.reality.short_id' /root/nast-singbox-vvc/data/config.json

# 2. Xác nhận client sử dụng đúng short_id
# 3. Khởi động lại Sing-box
systemctl restart sing-box
```

---

### ❌ Lỗi: "connections: in: listen failed"
**Nguyên nhân:** Firewall chặn hoặc port không được phép sử dụng

**Giải pháp:**
```bash
# 1. Kiểm tra firewall
systemctl status ufw
systemctl status firewalld

# 2. Nếu ufw đang bật
sudo ufw allow PORT/tcp
sudo ufw allow PORT/udp
sudo ufw status

# 3. Nếu iptables
sudo iptables -I INPUT -p tcp --dport PORT -j ACCEPT
sudo iptables -I INPUT -p udp --dport PORT -j ACCEPT

# 4. Kiểm tra port có quyền sử dụng (ports < 1024 cần root)
```

---

## 📍 VẤN ĐỀ NODE

### ❌ Lỗi: "Tag already exists"
**Nguyên nhân:** Đã có node với tag này

**Giải pháp:**
```bash
# 1. Xem danh sách node
vvc → 1 → 6

# 2. Xoá node cũ
vvc → 1 → 7

# 3. Thêm node mới với tag khác
vvc → 1 → [1-5]
```

---

### ❌ Lỗi: "Port already in use"
**Nguyên nhân:** Port đã được sử dụng bởi node khác

**Giải pháp:**
```bash
# 1. Để trống port khi thêm node (tự động chọn)
# Port: [Nhấn Enter]

# 2. Hoặc chỉ định port khác
# Port: 5000 (thay đổi số)

# 3. Kiểm tra ports đang dùng
grep "\"port\"" /root/nast-singbox-vvc/data/nodes.json
```

---

### ❌ Lỗi: "Certificate not found"
**Nguyên nhân:** Chứng chỉ không tồn tại hoặc sai đường dẫn

**Giải pháp:**
```bash
# 1. Liệt kê chứng chỉ có sẵn
ls -la /root/nast-singbox-vvc/certs/

# 2. Khi thêm node, chọn chứng chỉ mặc định
# Chọn số: 1 (thường là cert.crt)

# 3. Hoặc xin chứng chỉ SSL mới
vvc → 3 → 1
```

---

### ❌ Node không hoạt động sau khi thêm
**Nguyên nhân:** Sing-box không tự động reload config

**Giải pháp:**
```bash
# 1. Khởi động lại Sing-box
systemctl restart sing-box

# 2. Hoặc thông qua menu
vvc → 2 → 3

# 3. Kiểm tra status
systemctl status sing-box
```

---

## 🔐 VẤN ĐỀ SSL/CHỨNG CHỈ

### ❌ Lỗi: "Challenge failed"
**Nguyên nhân:** Tên miền không trỏ DNS đúng Cloudflare

**Giải pháp:**
```bash
# 1. Kiểm tra DNS resolution
nslookup sub.example.com
dig sub.example.com

# Output phải là IP của VPS

# 2. Kiểm tra domain trỏ Cloudflare
# Vào: Cloudflare Dashboard → Domain → DNS Settings
# Chắc chắn: A record → sub.example.com → VPS IP

# 3. Chờ DNS propagate (5-10 phút)

# 4. Thử lại xin chứng chỉ
vvc → 3 → 1
```

---

### ❌ Lỗi: "Invalid API Key"
**Nguyên nhân:** Cloudflare API Key sai hoặc hết hạn

**Giải pháp:**
```bash
# 1. Lấy API Key mới
# Truy cập: https://dash.cloudflare.com/
# → My Profile → API Tokens → Global API Key → View

# 2. Hoặc tạo API Token mới
# My Profile → API Tokens → Create Token
# Permissions: Zone.Zone.Read, Zone.DNS.Edit

# 3. Thử lại xin chứng chỉ
vvc → 3 → 1
```

---

### ❌ Lỗi: "Certificate expired"
**Nguyên nhân:** Chứng chỉ đã hết hạn

**Giải pháp:**
```bash
# 1. Xoá chứng chỉ cũ
rm /root/nast-singbox-vvc/certs/[domain].crt
rm /root/nast-singbox-vvc/certs/[domain].key

# 2. Xin chứng chỉ mới
vvc → 3 → 1

# 3. Khởi động lại Sing-box
systemctl restart sing-box
```

---

### ❌ Lỗi: "acme.sh: command not found"
**Nguyên nhân:** acme.sh chưa cài đặt

**Giải pháp:**
```bash
# 1. Cài đặt acme.sh
curl https://get.acme.sh | sh -s email="your@email.com"

# 2. Reload shell
source ~/.bashrc

# 3. Thử lại xin chứng chỉ
vvc → 3 → 1
```

---

## 🌐 VẤN ĐỀ KẾT NỐI

### ❌ Client không kết nối được
**Nguyên nhân:** Firewall chặn, port không mở, hoặc cấu hình client sai

**Giải pháp (Bước 1): Kiểm tra port mở**
```bash
# 1. Liệt kê ports đang lắng nghe
ss -tuln | grep LISTEN

# Output có PORT? Nếu có thì OK

# 2. Hoặc dùng netstat
netstat -tuln | grep LISTEN
```

**Giải pháp (Bước 2): Kiểm tra firewall**
```bash
# 1. Nếu ufw
sudo ufw status
sudo ufw allow PORT/tcp
sudo ufw allow PORT/udp
sudo ufw reload

# 2. Nếu firewalld
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=PORT/tcp --permanent
sudo firewall-cmd --reload

# 3. Nếu iptables
sudo iptables -tuln | grep PORT
sudo iptables -I INPUT -p tcp --dport PORT -j ACCEPT
```

**Giải pháp (Bước 3): Kiểm tra cấu hình client**
```
Đảm bảo client có:
- IP/Domain: VPS IP hoặc domain chính xác
- Port: Đúng port đã tạo
- UUID: Đúng UUID từ server (VLESS)
- Password: Đúng password (Hy2/Tuic)
- SNI: Đúng SNI (Reality)
- Protocol: Đúng protocol (VLESS/Hy2/Tuic)
```

**Giải pháp (Bước 4): Test kết nối**
```bash
# 1. Test TCP
nc -zv VPS_IP PORT

# 2. Test UDP (Hy2/Tuic)
nc -zuv VPS_IP PORT

# 3. Nếu thành công: Connection succeeded
```

---

### ❌ Lỗi: "Connection timeout"
**Nguyên nhân:** Firewall chặn hoặc server không chạy

**Giải pháp:**
```bash
# 1. Kiểm tra Sing-box chạy
systemctl status sing-box

# 2. Nếu dừng, khởi động
systemctl start sing-box

# 3. Kiểm tra firewall
sudo ufw allow PORT/tcp UDP
sudo ufw reload

# 4. Test lại kết nối từ client
```

---

### ❌ Lỗi: "Connection refused"
**Nguyên nhân:** Dịch vụ Sing-box không chạy hoặc port không đúng

**Giải pháp:**
```bash
# 1. Xác nhận Sing-box chạy
systemctl start sing-box
systemctl status sing-box

# 2. Xác nhận port đúng
grep "\"port\":" /root/nast-singbox-vvc/data/config.json

# 3. Test từ server
curl -v telnet://127.0.0.1:PORT
```

---

## ⚡ VẤN ĐỀ HIỆU NĂNG

### ❌ Tốc độ chậm
**Nguyên nhân:** Server tải cao, hoặc kết nối network yếu

**Giải pháp:**
```bash
# 1. Kiểm tra tài nguyên server
top  # Xem CPU, Memory
free -h  # Xem RAM
df -h  # Xem disk

# 2. Optimize Linux
# Thêm vào /etc/sysctl.conf:
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=5000
net.ipv4.tcp_congestion_control=bbr

# Apply:
sysctl -p

# 3. Kiểm tra số connection
netstat -an | grep ESTABLISHED | wc -l

# 4. Nếu quá nhiều, limit clients hoặc thêm node
```

---

### ❌ Memory leak
**Nguyên nhân:** Bug trong Sing-box hoặc cấu hình không tối ưu

**Giải pháp:**
```bash
# 1. Kiểm tra memory usage
ps aux | grep sing-box

# 2. Nếu tăng liên tục, cập nhật Sing-box
vvc → 4 → 2

# 3. Hoặc restart định kỳ
# Thêm vào crontab:
# 0 3 * * * systemctl restart sing-box

# 4. Để kích hoạt:
crontab -e
# Thêm dòng trên
```

---

## 🔌 VẤN ĐỀ FIREWALL/PORT

### ❌ Lỗi: "Port denied"
**Nguyên nhân:** Firewall chặn port

**Giải pháp (ufw):**
```bash
# Xem trạng thái
sudo ufw status verbose

# Nếu tắt
sudo ufw enable

# Mở port
sudo ufw allow PORT/tcp
sudo ufw allow PORT/udp

# Reload
sudo ufw reload
```

**Giải pháp (iptables):**
```bash
# Xem quy tắc
sudo iptables -tuln

# Thêm rule
sudo iptables -I INPUT -p tcp --dport PORT -j ACCEPT
sudo iptables -I INPUT -p udp --dport PORT -j ACCEPT

# Lưu
sudo netfilter-persistent save
```

**Giải pháp (firewalld):**
```bash
# Xem ports
sudo firewall-cmd --list-ports

# Thêm port
sudo firewall-cmd --add-port=PORT/tcp --permanent
sudo firewall-cmd --add-port=PORT/udp --permanent

# Reload
sudo firewall-cmd --reload
```

---

### ❌ Lỗi: "Permission denied" cho port < 1024
**Nguyên nhân:** Ports 1-1024 cần quyền root

**Giải pháp:**
```bash
# 1. Chạy Sing-box với root (mặc định đã làm)
# Hoặc dùng ports > 1024

# 2. Hoặc redirect port
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 14430
```

---

## 💾 VẤN ĐỀ CƠ SỞ DỮ LIỆU

### ❌ Lỗi: "nodes.json corrupted"
**Nguyên nhân:** File JSON sai format

**Giải pháp:**
```bash
# 1. Xem content
cat /root/nast-singbox-vvc/data/nodes.json

# 2. Validate JSON
jq . /root/nast-singbox-vvc/data/nodes.json

# Nếu có lỗi, sửa thủ công:
nano /root/nast-singbox-vvc/data/nodes.json

# 3. Hoặc restore từ backup
cp /root/nast-singbox-vvc/data.backup/nodes.json \
   /root/nast-singbox-vvc/data/nodes.json
```

---

### ❌ Lỗi: "Cannot write to data directory"
**Nguyên nhân:** Quyền file không đúng

**Giải pháp:**
```bash
# Fix quyền
sudo chmod -R 755 /root/nast-singbox-vvc/data
sudo chmod -R 755 /root/nast-singbox-vvc/certs
sudo chown -R root:root /root/nast-singbox-vvc/

# Verify
ls -la /root/nast-singbox-vvc/data/
```

---

## 📊 LOGS & DEBUGGING

### Xem Logs Chi Tiết
```bash
# 50 dòng log gần nhất
journalctl -u sing-box -n 50

# Xem real-time
journalctl -u sing-box -f

# Xem lỗi (ERROR level)
journalctl -u sing-box -p err

# Xem từ một thời gian
journalctl -u sing-box --since "1 hour ago"

# Lưu logs ra file
journalctl -u sing-box > /tmp/sing-box.log
```

---

### Debug Mode
```bash
# 1. Sửa log level trong config
nano /root/nast-singbox-vvc/data/config.json

# Thay:
"log": { "level": "info" }

# Thành:
"log": { "level": "debug" }

# 2. Khởi động lại
systemctl restart sing-box

# 3. Xem logs debug
journalctl -u sing-box -f
```

---

### Trace Network
```bash
# Xem traffic từ port
sudo tcpdump -i any port PORT -n

# Xem traffic chi tiết
sudo tcpdump -i any port PORT -A

# Save to file
sudo tcpdump -i any port PORT -w /tmp/capture.pcap
```

---

## ❓ FAQ - CÂU HỎI THƯỜNG GẶP

### Q: Làm sao biết Sing-box đang chạy?
**A:** Chạy lệnh:
```bash
systemctl status sing-box
# hoặc
ps aux | grep sing-box
```

---

### Q: Có thể đổi port sau khi thêm node?
**A:** Có, nhưng cần:
1. Xoá node cũ (đóng port cũ)
2. Thêm node mới (mở port mới)
3. Hoặc sửa config thủ công rồi restart

---

### Q: Chứng chỉ tự ký có bảo mật?
**A:** Có bảo mật cho Reality/gRPC. Nhưng để an toàn hơn, nên sử dụng chứng chỉ từ Cloudflare.

---

### Q: Có thể chạy nhiều Sing-box instance?
**A:** Có, nhưng cần:
- Ports khác nhau
- Config files khác nhau
- Services khác nhau

---

### Q: Làm sao cập nhật mà không mất dữ liệu?
**A:** Script update tự động bảo toàn data/ và certs/ folders.

```bash
vvc → 4 → 1
# Dữ liệu sẽ được bảo toàn
```

---

### Q: Có thể backup config?
**A:** Có:
```bash
tar -czf /root/backup-$(date +%Y%m%d).tar.gz \
    /root/nast-singbox-vvc/data \
    /root/nast-singbox-vvc/certs
```

---

### Q: Node bị chậm phải làm sao?
**A:** Kiểm tra:
1. CPU/Memory server (`top`)
2. Network bandwidth
3. Số lượng connections
4. Cấp protocol tối ưu (gRPC > TCP)

---

### Q: Có log client connections?
**A:** Có, xem debug logs:
```bash
journalctl -u sing-box -p debug -f
```

---

### Q: Làm sao reset toàn bộ?
**A:** Gỡ cài đặt rồi cài lại:
```bash
vvc → 5  # Gỡ cài đặt
bash install.sh  # Cài lại
```
⚠️ **SẼ XOÁ TẤT CẢ DỮ LIỆU**

---

### Q: Có thế giới hạn bandwidth per user?
**A:** Hiện tại không có. Có thể tùy chỉnh bằng cách:
1. Sửa config JSON
2. Thêm traffic middleware
3. Hoặc viết script riêng

---

## 📞 Liên Hệ Hỗ Trợ

Nếu vẫn gặp vấn đề, hãy:
1. Kiểm tra logs: `journalctl -u sing-box -e`
2. Xem TECHNICAL_REFERENCE.md
3. Liên hệ: https://github.com/Vietnamvpn/nast-singbox-vvc/issues

---

**Version:** 1.0  
**Last Updated:** 2024-01-01
