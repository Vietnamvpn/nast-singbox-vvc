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
    systemctl start sing-box
    success "Đã ra lệnh khởi động Sing-box."
}

stop_singbox() {
    systemctl stop sing-box
    success "Đã ra lệnh dừng Sing-box."
}

restart_singbox() {
    systemctl restart sing-box
    success "Đã ra lệnh khởi động lại Sing-box."
}

check_singbox_status() {
    if systemctl is-active --quiet sing-box; then
        echo -e "${GREEN}Đang chạy${NC}"
    else
        echo -e "${RED}Đã dừng${NC}"
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
            if [[ "$protocol" == "vless"* ]]; then
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
                if .tls != null then
                    if .tls.reality != null then
                        .tls.server_name = $node.server_name |
                        .tls.reality.handshake.server = $node.server_name |
                        .tls.reality.private_key = $node.private_key |
                        .tls.reality.short_id = [$node.short_id]
                    else
                        if $node.cert_path != null and $node.cert_path != "" then
                            .tls.certificate_path = $node.cert_path |
                            .tls.key_path = $node.key_path
                        else . end
                    end
                else . end
                |
                if .transport != null and .transport.type == "grpc" then
                    .transport.service_name = $node.service_name
                else . end
            ' "$tpl_file" > "$node_tmp"

            # Đẩy inbound vừa build xong vào mảng inbounds_tmp
            jq ". + [$(cat "$node_tmp")]" "$inbounds_tmp" > "${inbounds_tmp}.tmp" && mv "${inbounds_tmp}.tmp" "$inbounds_tmp"
            
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