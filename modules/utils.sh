#!/bin/bash

# =========================================================
# File: modules/utils.sh
# Chức năng: Các hàm tiện ích dùng chung cho hệ thống
# =========================================================

# =================== MÀU SẮC ===================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Không màu

BASE_DIR="/root/nast-singbox-vvc"
DATA_DIR="$BASE_DIR/data"
TPL_DIR="$BASE_DIR/templates"

# =================== TIỆN ÍCH HỆ THỐNG ===================

# In thông báo lỗi và thoát
die() {
    echo -e "${RED}[LỖI] $1${NC}"
    exit 1
}

# In thông báo thành công
success() {
    echo -e "${GREEN}[THÀNH CÔNG] $1${NC}"
}

# In thông báo thông tin
info() {
    echo -e "${CYAN}[THÔNG TIN] $1${NC}"
}

# =================== XỬ LÝ PORT NGẪU NHIÊN ===================

# Lấy ngẫu nhiên một port trống từ 2000 đến 6000
# Áp dụng cho logic: Nếu người dùng để trống khi nhập port thì sẽ tự lấy port này
get_random_unused_port() {
    while true; do
        # RANDOM trả về 0-32767. Lấy module 4001 cộng 2000 sẽ ra dải 2000-6000
        local check_port=$((RANDOM % 4001 + 2000))
        # Dùng netcat kiểm tra port. Nếu lệnh lỗi (nghĩa là port chưa mở/chưa bị chiếm), break loop
        if ! nc -z -w1 127.0.0.1 $check_port 2>/dev/null; then
            echo "$check_port"
            break
        fi
    done
}

# =================== ĐIỀU KHIỂN SING-BOX ===================

start_singbox() {
    info "Đang tiến hành khởi động dịch vụ Sing-box..."
    systemctl start sing-box
    if systemctl is-active --quiet sing-box; then
        success "Dịch vụ Sing-box đã được khởi động thành công và đang hoạt động bình thường!"
    else
        die "Khởi động Sing-box thất bại! Vui lòng kiểm tra lại cấu hình hoặc log bằng lệnh 'journalctl -u sing-box -e'."
    fi
}

stop_singbox() {
    info "Đang tiến hành dừng dịch vụ Sing-box..."
    systemctl stop sing-box
    if ! systemctl is-active --quiet sing-box; then
        success "Dịch vụ Sing-box đã được dừng hoàn toàn."
    else
        die "Không thể dừng dịch vụ Sing-box. Vui lòng kiểm tra lại tiến trình!"
    fi
}

restart_singbox() {
    info "Đang tiến hành khởi động lại dịch vụ Sing-box..."
    systemctl restart sing-box
    if systemctl is-active --quiet sing-box; then
        success "Dịch vụ Sing-box đã khởi động lại thành công và áp dụng cấu hình mới!"
    else
        die "Khởi động lại Sing-box thất bại! Cấu hình mới có thể có lỗi cú pháp. Hãy kiểm tra log bằng lệnh 'journalctl -u sing-box -e'."
    fi
}

check_singbox_status() {
    echo -n "Trạng thái dịch vụ Sing-box hiện tại: "
    if systemctl is-active --quiet sing-box; then
        echo -e "${GREEN}[ĐANG CHẠY - RUNNING]${NC}"
        # Hiển thị thêm thông tin chi tiết uptime nếu service đang chạy
        local uptime_info=$(systemctl show sing-box --property=ActiveEnterTimestamp 2>/dev/null)
        echo -e "${CYAN}Thông tin: $uptime_info${NC}"
    else
        echo -e "${RED}[ĐÃ DỪNG - STOPPED / LỖI]${NC}"
    fi
}

# =================== BUILD CONFIG.JSON ===================

build_config_json() {
    local config_out="$DATA_DIR/config.json"
    
    # Reset config về base
    cp "$TPL_DIR/config.base.json" "$config_out"
    
    if [[ ! -f "$DATA_DIR/nodes.json" ]] || [[ ! -f "$DATA_DIR/users.json" ]]; then
        echo -e "${YELLOW}Chưa có dữ liệu nodes.json hoặc users.json. Bỏ qua việc build inbounds.${NC}"
        return
    fi

    # Mảng tạm chứa toàn bộ inbounds
    local inbounds_tmp=$(mktemp)
    echo "[]" > "$inbounds_tmp"
    
    # Đọc số lượng node
    local nodes_count=$(jq '. | length' "$DATA_DIR/nodes.json")
    
    for (( i=0; i<$nodes_count; i++ )); do
        local protocol=$(jq -r ".[$i].protocol" "$DATA_DIR/nodes.json")
        local node_json=$(jq ".[$i]" "$DATA_DIR/nodes.json")
        local tpl_file=""
        
        # Ánh xạ giao thức với file template
        case "$protocol" in
            "hysteria2") tpl_file="$TPL_DIR/inbound_hy2.json" ;;
            "tuic") tpl_file="$TPL_DIR/inbound_tuic.json" ;;
            "vless-reality") tpl_file="$TPL_DIR/vless/vless-reality.json" ;;
            "vless-grpc-reality") tpl_file="$TPL_DIR/vless/vless-grpc-reality.json" ;;
            "vless-ws-tls") tpl_file="$TPL_DIR/vless/vless-ws-tls.json" ;;
            *) continue ;;
        esac

        if [[ -f "$tpl_file" ]]; then
            # Format object users.json cho tương thích từng giao thức
            local users_tmp=$(mktemp)
            if [[ "$protocol" == "vless-reality" ]]; then
                # TCP Vision cần flow
                jq '[.[] | {uuid: .uuid, flow: "xtls-rprx-vision", name: .name}]' "$DATA_DIR/users.json" > "$users_tmp"
            elif [[ "$protocol" == "vless-grpc-reality" || "$protocol" == "vless-ws-tls" ]]; then
                jq '[.[] | {uuid: .uuid, name: .name}]' "$DATA_DIR/users.json" > "$users_tmp"
            elif [[ "$protocol" == "hysteria2" ]]; then
                jq '[.[] | {password: .uuid, name: .name}]' "$DATA_DIR/users.json" > "$users_tmp"
            elif [[ "$protocol" == "tuic" ]]; then
                jq '[.[] | {uuid: .uuid, password: .uuid, name: .name}]' "$DATA_DIR/users.json" > "$users_tmp"
            fi

            # Merge template cùng thông số node (port, tls, reality, cert, grpc)
            local node_tmp=$(mktemp)
            jq --argjson node "$node_json" --slurpfile users "$users_tmp" '
                .tag = $node.tag |
                .listen_port = ($node.port | tonumber) |
                .users = $users[0] |
                
                # Sửa lỗi string/int cho tốc độ Hysteria2
                if .type == "hysteria2" then
                    .up_mbps = 1000 |
                    .down_mbps = 1000
                else . end |
                
                # Cấu hình TLS / Reality
                if .tls != null then
                    if .tls.reality != null and .tls.reality.enabled == true then
                        .tls.server_name = $node.server_name |
                        .tls.reality.handshake.server = $node.server_name |
                        .tls.reality.private_key = $node.private_key |
                        .tls.reality.short_id = [$node.short_id]
                    else
                        .tls.certificate_path = $node.cert_path |
                        .tls.key_path = $node.key_path |
                        if .tls.server_name != null then
                            .tls.server_name = $node.server_name
                        else . end
                    end
                else . end |
                
                # Cấu hình Transport
                if .transport != null then
                    if .transport.type == "grpc" then
                        .transport.service_name = $node.service_name
                    elif .transport.type == "ws" then
                        .transport.path = "/"
                    else . end
                else . end
            ' "$tpl_file" > "$node_tmp"

            # Đẩy inbound vừa build xong vào mảng inbounds_tmp một cách an toàn
            jq --slurpfile new_node "$node_tmp" '. + $new_node' "$inbounds_tmp" > "${inbounds_tmp}.tmp" && mv "${inbounds_tmp}.tmp" "$inbounds_tmp"
            
            # Xoá file rác
            rm -f "$node_tmp" "$users_tmp"
        fi
    done

    # Ghi đè mảng inbounds vào file config.json chính thức
    jq --slurpfile inbounds "$inbounds_tmp" '.inbounds = $inbounds[0]' "$config_out" > "${config_out}.tmp" && mv "${config_out}.tmp" "$config_out"
    rm -f "$inbounds_tmp"
    
    success "Đã build cấu hình config.json mới thành công!"
}

# =================== RÁP LINK KẾT NỐI (URI) ===================

build_link() {
    local protocol="$1"
    local uuid="$2"
    local vps_ip="$3"
    local port="$4"
    local tag="$5"
    local sni="$6"
    local pbk="$7"
    local sid="$8"
    local grpc_service="$9"
    
    local link=""
    
    case "$protocol" in
        "hysteria2")
            link="hysteria2://${uuid}@${vps_ip}:${port}/?sni=${sni}&insecure=1#${tag}"
            ;;
        "tuic")
            link="tuic://${uuid}:${uuid}@${vps_ip}:${port}/?sni=${sni}&congestion_control=bbr&alpn=h3#${tag}"
            ;;
        "vless-reality")
            link="vless://${uuid}@${vps_ip}:${port}?security=reality&encryption=none&pbk=${pbk}&headerType=none&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=${sni}&sid=${sid}#${tag}"
            ;;
        "vless-grpc-reality")
            link="vless://${uuid}@${vps_ip}:${port}?security=reality&encryption=none&pbk=${pbk}&fp=chrome&type=grpc&serviceName=${grpc_service}&sni=${sni}&sid=${sid}#${tag}"
            ;;
        "vless-ws-tls")
            link="vless://${uuid}@${vps_ip}:${port}?security=tls&encryption=none&type=ws&path=/&sni=${sni}#${tag}"
            ;;
    esac
    
    echo "$link"
}