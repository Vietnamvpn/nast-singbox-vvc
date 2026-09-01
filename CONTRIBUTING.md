# 🤝 CONTRIBUTING - Hướng Dẫn Đóng Góp

Cảm ơn bạn quan tâm đến Nast Sing-box VVC! Chúng tôi hoan nghênh các đóng góp từ cộng đồng.

## 🎯 Cách Đóng Góp

### 1️⃣ Báo Cáo Lỗi (Bug Report)

Nếu bạn tìm thấy bug, hãy:

1. **Kiểm tra xem lỗi đó đã được báo cáo chưa**
   - Vào [GitHub Issues](https://github.com/Vietnamvpn/nast-singbox-vvc/issues)
   - Tìm kiếm với từ khóa liên quan

2. **Tạo Issue mới** với thông tin:
   ```
   ### Mô tả lỗi
   [Mô tả chi tiết lỗi bạn gặp]
   
   ### Cách tái hiện
   1. Bước 1
   2. Bước 2
   3. Bước 3
   
   ### Kết quả mong muốn
   [Mô tả kết quả nên xảy ra]
   
   ### Kết quả thực tế
   [Mô tả kết quả hiện tại]
   
   ### Environment
   - OS: [Ubuntu 20.04, CentOS 8, etc.]
   - Sing-box version: [Phiên bản]
   - Script version: [Phiên bản script]
   ```

### 2️⃣ Đề Xuất Tính Năng (Feature Request)

1. **Kiểm tra xem tính năng đó đã có được đề xuất chưa**

2. **Tạo Issue mới** với:
   ```
   ### Tính năng đề xuất
   [Mô tả tính năng mới]
   
   ### Trường hợp sử dụng
   [Tại sao bạn cần tính năng này?]
   
   ### Giải pháp đề xuất
   [Cách triển khai tính năng]
   
   ### Thay thế
   [Có cách khác để làm điều này không?]
   ```

### 3️⃣ Gửi Pull Request (Code Contribution)

#### Quy trình:

1. **Fork repository**
   ```bash
   # Trên GitHub, click "Fork"
   ```

2. **Clone fork của bạn**
   ```bash
   git clone https://github.com/YOUR_USERNAME/nast-singbox-vvc.git
   cd nast-singbox-vvc
   ```

3. **Tạo branch mới**
   ```bash
   git checkout -b feature/your-feature-name
   # hoặc
   git checkout -b fix/bug-description
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "Add feature: [mô tả ngắn]"
   # Message format: "Add|Fix|Update|Refactor: [description]"
   ```

5. **Push to fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Tạo Pull Request**
   - Vào GitHub
   - Click "Compare & pull request"
   - Mô tả chi tiết thay đổi của bạn
   - Submit PR

#### PR Checklist:
- [ ] Mã nguồn đã được test
- [ ] Tài liệu đã được cập nhật
- [ ] Commit message rõ ràng
- [ ] Không có merge conflicts

### 4️⃣ Cải Thiện Tài Liệu

1. **Sửa lỗi chính tả/ngữ pháp**
2. **Thêm ví dụ**
3. **Cập nhật hướng dẫn**
4. **Dịch tài liệu**

---

## 📋 Hướng Dẫn Phát Triển

### Cấu Trúc Dự Án

```
nast-singbox-vvc/
├── modules/
│   ├── nodes.sh      # Quản lý node
│   ├── ssl.sh        # Quản lý SSL
│   ├── system.sh     # Quản lý Sing-box
│   └── utils.sh      # Hàm tiện ích
├── templates/        # Config templates
├── main.sh          # Entry point
├── install.sh       # Installation script
└── update.sh        # Update script
```

### Code Style

#### Bash Scripts:
```bash
# ✅ ĐÚNG:
#!/bin/bash

# Thêm header với mô tả file
# =========================================================
# File: modules/example.sh
# Chức năng: Mô tả chức năng
# =========================================================

# Sử dụng tên hàm rõ ràng
do_something_meaningful() {
    # Code với indent (4 spaces)
    local var="value"
    echo "message"
}

# Xử lý lỗi
if ! command >/dev/null 2>&1; then
    die "Error message"
fi
```

#### JSON Files:
```json
{
  "key": "value",
  "nested": {
    "property": "value"
  }
}
```

### Testing

Trước khi gửi PR:

1. **Test cài đặt**
   ```bash
   bash install.sh
   vvc  # Check menu
   ```

2. **Test các functions**
   ```bash
   source modules/utils.sh
   start_singbox
   check_singbox_status
   ```

3. **Test trên multiple OS**
   - Ubuntu 20.04+
   - Debian 10+
   - CentOS 8+

---

## 📝 Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Type:
- `feat`: Tính năng mới
- `fix`: Sửa lỗi
- `docs`: Cập nhật tài liệu
- `style`: Định dạng code (không ảnh hưởng logic)
- `refactor`: Tái cấu trúc code
- `test`: Thêm tests
- `chore`: Build, dependencies, etc.

### Ví dụ:
```
feat: Add Tuic protocol support

- Implement Tuic inbound configuration
- Add tuic node creation form
- Update documentation

Fixes #123
```

---

## 🎓 Cộng Đồng

### Liên Hệ
- **GitHub Issues:** Báo cáo lỗi, đề xuất tính năng
- **GitHub Discussions:** Thảo luận ý tưởng
- **GitHub Projects:** Theo dõi tiến độ phát triển

### Conduct
- ✅ Tôn trọng mọi người
- ✅ Đưa ra feedback xây dựng
- ✅ Làm việc nhóm
- ✅ Nói nhiều hơn về ý tưởng, ít hơn về con người

---

## 📚 Tài Liệu Hữu Ích

- [README.md](README.md) - Tổng quan dự án
- [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md) - Hướng dẫn chi tiết
- [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) - Tài liệu kỹ thuật
- [LICENSE](LICENSE) - MIT License

---

## ✨ Cảm Ơn!

Mỗi đóng góp - dù lớn hay nhỏ - đều giúp dự án trở nên tốt hơn! 🙏

**Vietnamvpn Team**
