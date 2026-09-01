#!/bin/bash

# =========================================================
# File: modules/nodes.sh
# Chức năng: Quản lý nodes, tự động mở/đóng cổng, sửa node, SNI ngẫu nhiên cho Reality và chỉ mục menu từ 1
# =========================================================

BASE_DIR="/root/nast-singbox-vvc"
source "$BASE_DIR/modules/utils.sh"

ensure_admin_user() {
    if [[ ! -f "$DATA_DIR/users.json" ]]; then
        local admin_uuid=$(uuidgen)
        echo "[{\"name\": \"admin\", \"uuid\": \"$admin_uuid\"}]" > "$DATA_DIR/users.json"
    fi
}

ensure_nodes_file() {
    if [[ ! -f "$DATA_DIR/nodes.json" ]]; then
        echo "[]" > "$DATA_DIR/nodes.json"
    fi
}

ensure_domain_file() {
    if [[ ! -f "$DATA_DIR/domain.json" ]]; then
        echo "[]" > "$DATA_DIR/domain.json"
    fi
}

get_country_code() {
    local cc=$(curl -s ipinfo.io/country 2>/dev/null)
    if [[ -z "$cc" || "$cc" == "null" ]]; then
        cc="VN"
    fi
    echo "$cc" | tr '[:lower:]' '[:upper:]'
}

get_random_sni() {
    local domains=("yahoo.com" "microsoft.com" "apple.com" "cloudflare.com" "speedtest.net" "ig.com" "discord.com")
    local rand_index=$((RANDOM % ${#domains[@]}))
    echo "${domains[$rand_index]}"
}

open_port() {
    local port="$1"
    local proto="$2"
    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        if [[ "$proto" == "hysteria2" || "$proto" == "tuic" ]]; then
            sudo ufw allow "$port"/udp &>/dev/null
        else
            sudo ufw allow "$port"/tcp &>/dev/null
        fi
    fi
}

close_port() {
    local port="$1"
    local proto="$2"
    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        if [[ "$proto" == "hysteria2" || "$proto" == "tuic" ]]; then
            sudo ufw delete allow "$port"/udp &>/dev/null
        else
            sudo ufw delete allow "$port"/tcp &>/dev/null
        fi
    fi
}

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
    ensure_nodes_file
    ensure_domain_file
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}            QUẢN LÝ NODE & KẾT NỐI${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN} 1.${NC} Thêm Giao Thức Mới"
    echo -e "${GREEN} 2.${NC} Cập Nhật Giao Thức"
    echo -e "${GREEN} 3.${NC} Xóa Giao Thức"
    echo -e "${GREEN} 4.${NC} Hiển Thị Link Kết Nối"
    echo -e "${RED} 0.${NC} Quay lại menu chính"
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

                read -p "Nhập Port (Để trống tự động chọn ngẫu nhiên 2000-6000): " port
                if [[ -z "$port" ]]; then
                    port=$(get_random_unused_port)
                    info "Đã tự động chọn port ngẫu nhiên: $port"
                fi

                read -p "Nhập Tag/Tên node (Để trống tự động theo quốc gia + port): " tag
                if [[ -z "$tag" ]]; then
                    cc=$(get_country_code)
                    tag="${cc}-${port}"
                    info "Đã tự động tạo Tag: $tag"
                fi

                vps_ip=$(curl -s4 icanhazip.com 2>/dev/null)

                read -p "Nhập Domain hoặc SNI (Để trống tự động lấy ngẫu nhiên cho Reality hoặc IP/domain.json): " sni
                if [[ -z "$sni" ]]; then
                    if [[ "$proto" == *"reality"* ]]; then
                        sni=$(get_random_sni)
                    elif [[ -f "$DATA_DIR/domain.json" ]] && [[ $(jq '. | length' "$DATA_DIR/domain.json" 2>/dev/null) -gt 0 ]]; then
                        sni=$(jq -r '.[0].domain' "$DATA_DIR/domain.json")
                    else
                        sni="$vps_ip"
                    fi
                    info "Đã tự động gán SNI/Domain: $sni"
                fi

                domain_entry=$(jq -n --arg tag "$tag" --arg domain "$sni" '{tag: $tag, domain: $domain}')
                jq --argjson entry "$domain_entry" '
                    if any(.[] ; .tag == $entry.tag) then
                        map(if .tag == $entry.tag then .domain = $entry.domain else . end)
                    else
                        . + [$entry]
                    end
                ' "$DATA_DIR/domain.json" > "$DATA_DIR/domain.json.tmp" && mv "$DATA_DIR/domain.json.tmp" "$DATA_DIR/domain.json"

                pbk=""
                sid=""
                grpc_service=""
                cert_path=""
                key_path=""
                private_key=""
                up_mbps=""
                down_mbps=""

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
                
                # Tự động mở cổng tường lửa
                open_port "$port" "$proto"
                success "Đã thêm giao thức [${tag}] và mở cổng ${port} thành công!"

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
            echo -e "${CYAN}--- SỬA NODE ---${NC}"
            count=$(jq '. | length' "$DATA_DIR/nodes.json" 2>/dev/null || echo 0)
            if [[ "$count" -eq 0 ]]; then
                echo -e "${YELLOW}Chưa có node nào được tạo.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                continue
            fi
            
            for (( i=0; i<$count; i++ )); do
                local display_num=$((i+1))
                t=$(jq -r ".[$i].tag" "$DATA_DIR/nodes.json")
                p=$(jq -r ".[$i].protocol" "$DATA_DIR/nodes.json")
                prt=$(jq -r ".[$i].port" "$DATA_DIR/nodes.json")
                echo " [$display_num] Tag: $t | Protocol: $p | Port: $prt"
            done
            echo " [0] Hủy bỏ"
            
            read -p "Nhập số thứ tự node muốn sửa (1-$count, 0 để hủy): " edit_idx
            if [[ "$edit_idx" == "0" ]]; then
                continue
            fi
            
            if [[ "$edit_idx" =~ ^[0-9]+$ ]] && (( edit_idx > 0 && edit_idx <= count )); then
                local real_idx=$((edit_idx-1))
                local old_port=$(jq -r ".[$real_idx].port" "$DATA_DIR/nodes.json")
                local old_proto=$(jq -r ".[$real_idx].protocol" "$DATA_DIR/nodes.json")
                local old_tag=$(jq -r ".[$real_idx].tag" "$DATA_DIR/nodes.json")
                
                echo -e "${CYAN}Đang sửa node: $old_tag ($old_proto trên port $old_port)${NC}"
                echo "Để trống nếu muốn giữ nguyên giá trị cũ."

                read -p "Nhập Port mới [$old_port]: " new_port
                [[ -z "$new_port" ]] && new_port="$old_port"

                read -p "Nhập Tag mới [$old_tag]: " new_tag
                [[ -z "$new_tag" ]] && new_tag="$old_tag"

                local old_sni=$(jq -r ".[$real_idx].server_name // empty" "$DATA_DIR/nodes.json")
                read -p "Nhập SNI/Domain mới [$old_sni]: " new_sni
                [[ -z "$new_sni" ]] && new_sni="$old_sni"

                # Cập nhật thông số vào node hiện tại qua jq
                jq --argjson idx "$real_idx" --argjson port "$new_port" --arg tag "$new_tag" --arg sni "$new_sni" '
                    .[$idx].port = $port |
                    .[$idx].tag = $tag |
                    .[$idx].server_name = $sni
                ' "$DATA_DIR/nodes.json" > "$DATA_DIR/nodes.json.tmp" && mv "$DATA_DIR/nodes.json.tmp" "$DATA_DIR/nodes.json"

                # Đóng cổng cũ, mở cổng mới nếu thay đổi port hoặc giao thức
                if [[ "$old_port" != "$new_port" ]]; then
                    close_port "$old_port" "$old_proto"
                    open_port "$new_port" "$old_proto"
                fi

                build_config_json
                restart_singbox
                success "Đã cập nhật và sửa node thành công!"
            else
                echo -e "${RED}[LỖI] Số thứ tự không hợp lệ!${NC}"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        3)
            clear
            echo -e "${CYAN}--- XÓA NODE ---${NC}"
            count=$(jq '. | length' "$DATA_DIR/nodes.json" 2>/dev/null || echo 0)
            if [[ "$count" -eq 0 ]]; then
                echo -e "${YELLOW}Chưa có node nào được tạo.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                continue
            fi
            
            for (( i=0; i<$count; i++ )); do
                local display_num=$((i+1))
                t=$(jq -r ".[$i].tag" "$DATA_DIR/nodes.json")
                p=$(jq -r ".[$i].protocol" "$DATA_DIR/nodes.json")
                prt=$(jq -r ".[$i].port" "$DATA_DIR/nodes.json")
                echo " [$display_num] Tag: $t | Protocol: $p | Port: $prt"
            done
            echo " [0] Hủy bỏ"
            
            read -p "Nhập số thứ tự node muốn xóa (1-$count, 0 để hủy): " idx
            if [[ "$idx" == "0" ]]; then
                continue
            fi
            
            if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx > 0 && idx <= count )); then
                local real_idx=$((idx-1))
                del_tag=$(jq -r ".[$real_idx].tag" "$DATA_DIR/nodes.json")
                del_port=$(jq -r ".[$real_idx].port" "$DATA_DIR/nodes.json")
                del_proto=$(jq -r ".[$real_idx].protocol" "$DATA_DIR/nodes.json")
                
                jq "del(.[$real_idx])" "$DATA_DIR/nodes.json" > "$DATA_DIR/nodes.json.tmp" && mv "$DATA_DIR/nodes.json.tmp" "$DATA_DIR/nodes.json"
                
                if [[ -f "$DATA_DIR/domain.json" ]]; then
                    jq --arg tag "$del_tag" '[.[] | select(.tag != $tag)]' "$DATA_DIR/domain.json" > "$DATA_DIR/domain.json.tmp" && mv "$DATA_DIR/domain.json.tmp" "$DATA_DIR/domain.json"
                fi

                # Đóng cổng tường lửa tương ứng
                close_port "$del_port" "$del_proto"

                build_config_json
                restart_singbox
                success "Đã xóa node và đóng cổng ${del_port} thành công!"
            else
                echo -e "${RED}[LỖI] Số thứ tự không hợp lệ!${NC}"
            fi
            read -p "Nhấn Enter để tiếp tục..."
            ;;
        4)
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