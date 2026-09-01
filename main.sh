#!/bin/bash

# =========================================================
# File: main.sh
# Chức năng: Entry point cho lệnh CLI 'vvc' / Daemon service
# =========================================================

BASE_DIR="/root/nast-singbox-vvc"

# Xử lý Service chạy ngầm
if [[ "$1" == "daemon" ]]; then
    while true; do
        # Các logic xử lý ngầm (api, reset pass, monitor port...) có thể để ở đây
        sleep 60
    done
    exit 0
fi

# Load thư viện utils dùng chung
source "$BASE_DIR/modules/utils.sh"

# Kiểm tra quyền khi chạy lệnh vvc
if [[ "$EUID" -ne 0 ]]; then
    die "Vui lòng chạy lệnh bằng quyền root."
fi

# Hàm xử lý gỡ cài đặt an toàn
uninstall_system() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "${RED}       CẢNH BÁO: GỠ CÀI ĐẶT TOÀN BỘ HỆ THỐNG     ${NC}"
    echo -e "${RED}=================================================${NC}"
    echo -e "${YELLOW}Thao tác này sẽ xoá TOÀN BỘ:${NC}"
    echo -e " 1. Mã nguồn quản lý."
    echo -e " 2. Database (User, Nodes, Cấu hình)."
    echo -e " 3. Chứng chỉ SSL."
    echo -e " 4. Lõi Sing-box core."
    echo -e "${RED}DỮ LIỆU SẼ KHÔNG THỂ KHÔI PHỤC!${NC}"
    echo -e "${RED}=================================================${NC}"
    
    read -p "Bạn có CHẮC CHẮN muốn xoá toàn bộ? (y/N): " confirm_1
    if [[ "$confirm_1" != "y" && "$confirm_1" != "Y" ]]; then
        info "Đã huỷ thao tác gỡ cài đặt."
        return
    fi
    
    info "Đang tiến hành dừng các dịch vụ ngầm..."
    systemctl stop sing-box manager
    systemctl disable sing-box manager
    
    info "Đang xoá systemd services..."
    rm -f /etc/systemd/system/sing-box.service
    rm -f /etc/systemd/system/manager.service
    systemctl daemon-reload
    
    info "Đang xoá lõi Sing-box..."
    rm -f /usr/local/bin/sing-box
    
    info "Đang xoá lệnh CLI 'vvc'..."
    rm -f /usr/local/bin/vvc
    
    info "Đang xoá thư mục mã nguồn và dữ liệu..."
    rm -rf "$BASE_DIR"
    
    success "Đã gỡ cài đặt thành công toàn bộ hệ thống Nast Sing-box."
    exit 0
}

# Vòng lặp hiển thị Menu CLI
while true; do
    clear
    CORE_VER=$(/usr/local/bin/sing-box version 2>/dev/null | grep -i version | awk '{print $3}')
    CORE_VER=${CORE_VER:-"Chưa cài đặt"}
    SYS_STATUS=$(check_singbox_status | grep -v "Thông tin:" | head -n 1)

    echo -e "${BLUE}=================================================================================================${NC}"
    echo -e "${GREEN}                               MENU NAST SING-BOX VVC                                  ${NC}"
    echo -e "${BLUE}=================================================================================================${NC}"
    echo -e " ${GREEN}Tác giả${NC}: Vietnamvpn         | ${GREEN}Singbox core${NC}: ${CORE_VER}"
    echo -e " ${GREEN}Trạng thái${NC} : ${SYS_STATUS}  | ${GREEN}Trang web${NC}  : https://linksub24h.com"
    echo -e "${BLUE}=================================================================================================${NC}"
    echo -e "${YELLOW} 1.${NC} Quản Lý Node Server"
    echo -e "${YELLOW} 2.${NC} Quản Lý Sing-Box"
    echo -e "${YELLOW} 3.${NC} Quản Lý SSL Cloudflare"
    echo -e "${YELLOW} 4.${NC} Cập Nhật Hệ Thống"
    echo -e "${RED} 5.${NC} Gỡ Cài Đặt Toàn Bộ Hệ Thống"
    echo -e "${YELLOW} 0.${NC} Thoát"
    echo -e "${BLUE}=================================================================================================${NC}"
    read -p "Vui lòng nhập lựa chọn của bạn: " main_choice

    case "$main_choice" in
        1)
            bash "$BASE_DIR/modules/nodes.sh"
            ;;
        2)
            bash "$BASE_DIR/modules/system.sh"
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        3)
            bash "$BASE_DIR/modules/ssl.sh"
            ;;
        4)
            bash "$BASE_DIR/update.sh"
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        5)
            uninstall_system
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        0)
            echo -e "${GREEN}Đã thoát Nast Sing-box Manager.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[LỖI] Lựa chọn không hợp lệ, vui lòng thử lại!${NC}"
            sleep 2
            ;;
    esac
done