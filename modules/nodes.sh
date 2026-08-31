#!/bin/bash

# =========================================================
# File: modules/nodes.sh
# Chức năng: Quản lý nodes, sửa lỗi bắt biến menu chứng chỉ SSL
# =========================================================

BASE_DIR="/root/nast-singbox-vvc"
source "$BASE_DIR/modules/utils.sh"

ensure_admin_user() {
    if [[ ! -f "$DATA_DIR/users.json" ]]; then
        local admin_uuid=$(uuidgen)
        echo "[{\"name\": \"admin\", \"uuid\": \"$admin_uuid\"}]" > "$DATA_DIR/users.json"
    fi
}

# Lấy mã quốc gia từ IP của VPS (mặc định VN nếu lỗi)
get_country_code() {
    local cc=$(curl -s ipinfo.io/country 2>/dev/null)
    if [[ -z "$cc" || "$cc" == "null" ]]; then
        cc="VN"
    fi
    echo "$cc" | tr '[:lower:]' '[:upper:]'
}

# Hàm chọn chứng chỉ SSL theo số thứ tự (menu) - Đã fix xuất thông báo ra stderr để không làm bẩn biến
select_certificate_menu() {
    local cert_files=("$BASE_DIR/certs/"*.crt)
    
    echo -e "${CYAN}--- CHỌN CHỨNG CHỈ SSL CHO NODE ---${NC}" >&2
    if [[ ! -e "${cert_files[0]}" ]]; then
        echo -e "${YELLOW}Không tìm thấy chứng chỉ domain nào trong certs/. Hệ thống sẽ dùng chứng chỉ tự ký mặc định.${NC}" >&2
        echo "$BASE_DIR/certs/cert.crt|$BASE_DIR/certs/private.key"
        return
    fi
    
    echo " [0] Dùng chứng chỉ tự ký mặc định (cert.crt)" >&2
    local i=1
    for f in "${cert_files[@]}"; do
        echo " [$i] $(basename "$f")" >&2
        ((i++))
    done
    
    read -p "Nhập số thứ tự chọn chứng chỉ: " cert_choice >&2
    
    if [[ "$cert_choice" =~ ^[0-9]+$ ]] && (( cert_choice > 0 && cert_choice <= ${#cert_files[@]} )); then
        local selected_crt="${cert_files[$((cert_choice-1))]}"
        local selected_key="${selected_crt%.crt}.key"
        echo "${selected_crt}|${selected_key}"
    else
        echo "$BASE_DIR/certs/cert.crt|$BASE_DIR/certs/private.key"
    fi
}

while true; do
    ensure_admin_user
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}            QUẢN LÝ NODE & KẾT NỐI${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN} 1.${NC} Thêm Node mới"
    echo -e "${GREEN} 2.${NC} Xóa Node"
    echo -e "${GREEN} 3.${NC} Hiển thị danh sách Link kết nối"
    echo -e "${GREEN} 0.${NC} Quay lại menu chính"
    echo -e "${BLUE}=================================================${NC}"
    read -p "Nhập lựa chọn của bạn: " node_choice

    case "$node_choice" in
        1)
            while true; do
                clear
                echo -e "${CYAN}--- CHỌN GIAO THỨC NODE ---${NC}"
                echo " 1. Hysteria 2"
                echo " 2. TUIC"
                echo " 3. VLESS Reality (TCP Vision)"
                echo " 4. VLESS gRPC Reality"
                echo " 5. VLESS WS TLS"
                read -p "Chọn giao thức (1-5): " proto_choice
                
                proto=""
                case "$proto_choice" in
                    1) proto="hysteria2" ;;
                    2) proto="tuic" ;;
                    3) proto="vless-reality" ;;
                    4) proto="vless-grpc-reality" ;;
                    5) proto="vless-ws-tls" ;;
                    *) echo -e "${RED}Lựa chọn sai!${NC}"; sleep 1; continue ;;
                endcase

                # 1. Nhập Port
                read -p "Nhập Port (Để trống tự động chọn ngẫu nhiên 2000-6000): " port
                if [[ -z "$port" ]]; then
                    port=$(get_random_unused_port)
                    info "Đã tự động chọn port ngẫu nhiên: $port"
                fi

                # 2. Nhập Tag
                read -p "Nhập Tag/Tên node (Để trống tự động theo quốc gia + port): " tag
                if [[ -z "$tag" ]]; then
                    cc=$(get_country_code)
                    tag="${cc}-${port}"
                    info "Đã tự động tạo Tag: $tag"
                fi

                # 3. Nhập Domain / SNI
                read -p "Nhập Domain hoặc SNI (Để trống tự động lấy từ domain.json hoặc mặc định): " sni
                if [[ -z "$sni" ]]; then
                    if [[ -f "$DATA_DIR/domain.json" ]] && [[ $(jq '. | length' "$DATA_DIR/domain.json") -gt 0 ]]; then
                        sni=$(jq -r '.[0].domain' "$DATA_DIR/domain.json")
                    else
                        sni="cloudflare.com"
                    fi
                    info "Đã tự động gán SNI/Domain: $sni"
                fi

                pbk=""
                sid=""
                grpc_service=""
                cert_path=""
                key_path=""
                private_key=""

                if [[ "$proto" == "vless-reality"* ]]; then
                    info "Đang tạo cặp khóa Reality (X25519) tự động..."
                    keypair=$(sing-box generate reality-keypair 2>/dev/null)
                    private_key=$(echo "$keypair" | grep "PrivateKey" | awk '{print $2}')
                    pbk=$(echo "$keypair" | grep "PublicKey" | awk '{print $2}')
                    
                    if [[ -z "$private_key" ]]; then
                        private_key=$(openssl rand -base64 32)
                        pbk=$(openssl rand -base64 32)
                    fi
                    sid=$(openssl rand -hex 4)
                elif [[ "$proto" == "vless-ws-tls" || "$proto" == "hysteria2" || "$proto" == "tuic" ]]; then
                    cert_info=$(select_certificate_menu)
                    cert_path=$(echo "$cert_info" | cut -d'|' -f1)
                    key_path=$(echo "$cert_info" | cut -d'|' -f2)
                fi

                if [[ "$proto" == "vless-grpc-reality" ]]; then
                    read -p "Nhập gRPC ServiceName (Để trống mặc định 'grpc'): " grpc_service
                    [[ -z "$grpc_service" ]] && grpc_service="grpc"
                fi

                new_node=$(jq -n \
                    --arg protocol "$proto" \
                    --arg tag "$tag" \
                    --argjson port "$port" \
                    --arg sni "$sni" \
                    --arg pbk "$pbk" \
                    --arg priv "$private_key" \
                    --arg sid "$sid" \
                    --arg grpc "$grpc_service" \
                    --arg cert "$cert_path" \
                    --arg key "$key_path" \
                    '{
                        protocol: $protocol,
                        tag: $tag,
                        port: $port,
                        server_name: $sni,
                        public_key: $pbk,
                        private_key: $priv,
                        short_id: $sid,
                        service_name: $grpc,
                        cert_path: $cert,
                        key_path: $key
                    }')

                jq --argjson node "$new_node" '. + [$node]' "$DATA_DIR/nodes.json" > "$DATA_DIR/nodes.json.tmp" && mv "$DATA_DIR/nodes.json.tmp" "$DATA_DIR/nodes.json"
                success "Đã thêm giao thức [${tag}] vào danh sách tạm thời!"

                echo ""
                read -p "Bạn có muốn thêm giao thức khác không? (Nhấn 'y' để tiếp tục, 'n' để dừng và lưu): " continue_add
                if [[ "$continue_add" != "y" && "$continue_add" != "Y" ]]; then
                    break
                fi
            done

            info "Đang tiến hành build lại cấu hình và khởi động Sing-box..."
            build_config_json
            restart_singbox
            success "Đã cập nhật toàn bộ cấu hình node thành công!"
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        2)
            clear
            echo -e "${CYAN}--- DANH SÁCH NODE HIỆN TẠI ---${NC}"
            count=$(jq '. | length' "$DATA_DIR/nodes.json")
            if [[ "$count" -eq 0 ]]; then
                echo -e "${YELLOW}Chưa có node nào được tạo.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                continue
            fi
            
            for (( i=0; i<$count; i++ )); do
                t=$(jq -r ".[$i].tag" "$DATA_DIR/nodes.json")
                p=$(jq -r ".[$i].protocol" "$DATA_DIR/nodes.json")
                echo " [$i] Tag: $t | Protocol: $p"
            done
            
            read -p "Nhập số thứ tự (index) node muốn xóa: " idx
            if [[ -n "$idx" ]]; then
                jq "del(.[$idx])" "$DATA_DIR/nodes.json" > "$DATA_DIR/nodes.json.tmp" && mv "$DATA_DIR/nodes.json.tmp" "$DATA_DIR/nodes.json"
                build_config_json
                restart_singbox
                success "Đã xóa node thành công!"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        3)
            clear
            vps_ip=$(curl -s4 icanhazip.com 2>/dev/null)
            users_count=$(jq '. | length' "$DATA_DIR/users.json")
            nodes_count=$(jq '. | length' "$DATA_DIR/nodes.json")
            
            if [[ "$nodes_count" -eq 0 ]]; then
                echo -e "${YELLOW}Chưa có node nào được tạo.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                continue
            fi

            for (( u=0; u<$users_count; u++ )); do
                uname=$(jq -r ".[$u].name" "$DATA_DIR/users.json")
                uuuid=$(jq -r ".[$u].uuid" "$DATA_DIR/users.json")
                
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${YELLOW}   DANH SÁCH LINK KẾT NỐI CHO USER: ${GREEN}${uname}${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
                for (( i=0; i<$nodes_count; i++ )); do
                    protocol=$(jq -r ".[$i].protocol" "$DATA_DIR/nodes.json")
                    port=$(jq -r ".[$i].port" "$DATA_DIR/nodes.json")
                    tag=$(jq -r ".[$i].tag" "$DATA_DIR/nodes.json")
                    sni=$(jq -r ".[$i].server_name // empty" "$DATA_DIR/nodes.json")
                    pbk=$(jq -r ".[$i].public_key // empty" "$DATA_DIR/nodes.json")
                    sid=$(jq -r ".[$i].short_id // empty" "$DATA_DIR/nodes.json")
                    grpc_service=$(jq -r ".[$i].service_name // empty" "$DATA_DIR/nodes.json")
                    
                    link=$(build_link "$protocol" "$uuuid" "$vps_ip" "$port" "$tag" "$sni" "$pbk" "$sid" "$grpc_service")
                    
                    echo -e "${CYAN}Node: ${tag} (${protocol})${NC}"
                    echo -e "${GREEN}${link}${NC}"
                    echo -e "-------------------------------------------------"
                done
            done
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        0)
            break
            ;;
        *)
            echo -e "${RED}[LỖI] Lựa chọn không hợp lệ!${NC}"
            sleep 1
            ;;
    esac
done