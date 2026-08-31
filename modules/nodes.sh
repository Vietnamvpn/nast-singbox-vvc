#!/bin/bash

# =========================================================
# File: modules/nodes.sh
# Chức năng: Quản lý nodes, tối ưu hóa lưu trữ thông số theo từng giao thức riêng biệt
# =========================================================

BASE_DIR="/root/nast-singbox-vvc"
source "$BASE_DIR/modules/utils.sh"

ensure_admin_user() {
    if [[ ! -f "$DATA_DIR/users.json" ]]; then
        local admin_uuid=$(uuidgen)
        echo "[{\"name\": \"admin\", \"uuid\": \"$admin_uuid\"}]" > "$DATA_DIR/users.json"
    fi
}

# Đảm bảo file nodes.json luôn tồn tại dưới dạng mảng JSON hợp lệ
ensure_nodes_file() {
    if [[ ! -f "$DATA_DIR/nodes.json" ]]; then
        echo "[]" > "$DATA_DIR/nodes.json"
    fi
}

# Đảm bảo file domain.json luôn tồn tại dưới dạng mảng JSON hợp lệ
ensure_domain_file() {
    if [[ ! -f "$DATA_DIR/domain.json" ]]; then
        echo "[]" > "$DATA_DIR/domain.json"
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
    
    # Kiểm tra xem file có thực sự tồn tại (do globbing "*.crt" có thể trả về chính chuỗi "*.crt" nếu không có file)
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
    ensure_nodes_file
    ensure_domain_file
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
                esac

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

                vps_ip=$(curl -s4 icanhazip.com 2>/dev/null)

                # 3. Nhập Domain / SNI
                read -p "Nhập Domain hoặc SNI (Để trống tự động lấy từ domain.json hoặc IP/mặc định): " sni
                if [[ -z "$sni" ]]; then
                    if [[ -f "$DATA_DIR/domain.json" ]] && [[ $(jq '. | length' "$DATA_DIR/domain.json" 2>/dev/null) -gt 0 ]]; then
                        sni=$(jq -r '.[0].domain' "$DATA_DIR/domain.json")
                    else
                        if [[ "$proto" == *"reality"* ]]; then
                            sni="cloudflare.com"
                        else
                            sni="$vps_ip"
                        fi
                    fi
                    info "Đã tự động gán SNI/Domain: $sni"
                fi

                # Tự động lưu tag và domain/IP tương ứng vào domain.json nếu chưa có
                domain_entry=$(jq -n --arg tag "$tag" --arg domain "$sni" '{tag: $tag, domain: $domain}')
                jq --argjson entry "$domain_entry" '
                    if any(.[] ; .tag == $entry.tag) then
                        map(if .tag == $entry.tag then .domain = $entry.domain else . end)
                    else
                        . + [$entry]
                    end
                ' "$DATA_DIR/domain.json" > "$DATA_DIR/domain.json.tmp" && mv "$DATA_DIR/domain.json.tmp" "$DATA_DIR/domain.json"

                # Khởi tạo các biến tùy chọn theo từng giao thức
                pbk=""
                sid=""
                grpc_service=""
                cert_path=""
                key_path=""
                private_key=""
                up_mbps=""
                down_mbps=""

                # Thu thập thông số riêng biệt tùy thuộc vào giao thức được chọn
                case "$proto" in
                    "vless-reality"|"vless-grpc-reality")
                        info "Đang tạo cặp khóa Reality (X25519) tự động..."
                        keypair=$(sing-box generate reality-keypair 2>/dev/null)
                        private_key=$(echo "$keypair" | grep "PrivateKey" | awk '{print $2}')
                        pbk=$(echo "$keypair" | grep "PublicKey" | awk '{print $2}')
                        
                        if [[ -z "$private_key" ]]; then
                            private_key=$(openssl rand -base64 32)
                            pbk=$(openssl rand -base64 32)
                        fi
                        sid=$(openssl rand -hex 4)

                        if [[ "$proto" == "vless-grpc-reality" ]]; then
                            read -p "Nhập gRPC ServiceName (Để trống mặc định 'grpc'): " grpc_service
                            [[ -z "$grpc_service" ]] && grpc_service="grpc"
                        fi
                        ;;
                    "vless-ws-tls"|"hysteria2"|"tuic")
                        cert_info=$(select_certificate_menu)
                        cert_path=$(echo "$cert_info" | cut -d'|' -f1)
                        key_path=$(echo "$cert_info" | cut -d'|' -f2)

                        if [[ "$proto" == "hysteria2" ]]; then
                            read -p "Nhập tốc độ Upload (Mbps) (Để trống mặc định 1000): " up_mbps
                            [[ -z "$up_mbps" ]] && up_mbps="1000"
                            
                            read -p "Nhập tốc độ Download (Mbps) (Để trống mặc định 1000): " down_mbps
                            [[ -z "$down_mbps" ]] && down_mbps="1000"
                        fi
                        ;;
                esac

                # Xây dựng đối tượng JSON gọn gàng, chỉ chứa thông số thực sự cần thiết theo từng giao thức
                case "$proto" in
                    "hysteria2")
                        new_node=$(jq -n \
                            --arg protocol "$proto" \
                            --arg tag "$tag" \
                            --argjson port "$port" \
                            --arg sni "$sni" \
                            --arg cert "$cert_path" \
                            --arg key "$key_path" \
                            --arg up "$up_mbps" \
                            --arg down "$down_mbps" \
                            '{
                                protocol: $protocol,
                                tag: $tag,
                                port: $port,
                                server_name: $sni,
                                cert_path: $cert,
                                key_path: $key,
                                up_mbps: ($up | tonumber),
                                down_mbps: ($down | tonumber)
                            }')
                        ;;
                    "tuic")
                        new_node=$(jq -n \
                            --arg protocol "$proto" \
                            --arg tag "$tag" \
                            --argjson port "$port" \
                            --arg sni "$sni" \
                            --arg cert "$cert_path" \
                            --arg key "$key_path" \
                            '{
                                protocol: $protocol,
                                tag: $tag,
                                port: $port,
                                server_name: $sni,
                                cert_path: $cert,
                                key_path: $key
                            }')
                        ;;
                    "vless-reality")
                        new_node=$(jq -n \
                            --arg protocol "$proto" \
                            --arg tag "$tag" \
                            --argjson port "$port" \
                            --arg sni "$sni" \
                            --arg pbk "$pbk" \
                            --arg priv "$private_key" \
                            --arg sid "$sid" \
                            '{
                                protocol: $protocol,
                                tag: $tag,
                                port: $port,
                                server_name: $sni,
                                public_key: $pbk,
                                private_key: $priv,
                                short_id: $sid
                            }')
                        ;;
                    "vless-grpc-reality")
                        new_node=$(jq -n \
                            --arg protocol "$proto" \
                            --arg tag "$tag" \
                            --argjson port "$port" \
                            --arg sni "$sni" \
                            --arg pbk "$pbk" \
                            --arg priv "$private_key" \
                            --arg sid "$sid" \
                            --arg grpc "$grpc_service" \
                            '{
                                protocol: $protocol,
                                tag: $tag,
                                port: $port,
                                server_name: $sni,
                                public_key: $pbk,
                                private_key: $priv,
                                short_id: $sid,
                                service_name: $grpc
                            }')
                        ;;
                    "vless-ws-tls")
                        new_node=$(jq -n \
                            --arg protocol "$proto" \
                            --arg tag "$tag" \
                            --argjson port "$port" \
                            --arg sni "$sni" \
                            --arg cert "$cert_path" \
                            --arg key "$key_path" \
                            '{
                                protocol: $protocol,
                                tag: $tag,
                                port: $port,
                                server_name: $sni,
                                cert_path: $cert,
                                key_path: $key
                            }')
                        ;;
                esac

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
            count=$(jq '. | length' "$DATA_DIR/nodes.json" 2>/dev/null || echo 0)
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
            if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 0 && idx < count )); then
                # Lấy tag của node sắp xóa để dọn dẹp domain.json tương ứng nếu cần
                del_tag=$(jq -r ".[$idx].tag" "$DATA_DIR/nodes.json")
                
                jq "del(.[$idx])" "$DATA_DIR/nodes.json" > "$DATA_DIR/nodes.json.tmp" && mv "$DATA_DIR/nodes.json.tmp" "$DATA_DIR/nodes.json"
                
                # Xóa tag tương ứng trong domain.json
                if [[ -f "$DATA_DIR/domain.json" ]]; then
                    jq --arg tag "$del_tag" '[.[] | select(.tag != $tag)]' "$DATA_DIR/domain.json" > "$DATA_DIR/domain.json.tmp" && mv "$DATA_DIR/domain.json.tmp" "$DATA_DIR/domain.json"
                fi

                build_config_json
                restart_singbox
                success "Đã xóa node thành công!"
            else
                echo -e "${RED}[LỖI] Số thứ tự không hợp lệ!${NC}"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        3)
            clear
            vps_ip=$(curl -s4 icanhazip.com 2>/dev/null)
            users_count=$(jq '. | length' "$DATA_DIR/users.json" 2>/dev/null || echo 0)
            nodes_count=$(jq '. | length' "$DATA_DIR/nodes.json" 2>/dev/null || echo 0)
            
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