#!/bin/bash

read -p "Nhập Domain Web (không cần https://): " domain_web
domain_web="https://$domain_web"
read -p "Nhập API Key (ApiKey): " api_key

read -p "Nhập Node ID - 80 vmess: " node_80
read -p "Nhập Node ID - 443 trojan: " node_443

echo "1. Có"
echo "2. Không"
read -p "Bạn muốn cài đặt chứng chỉ SSL không?: " ssl

clear

echo "Thông tin bạn đã nhập:"
echo "Địa chỉ Web: $domain_web"
echo "API Key: $api_key"
echo "Node ID 80 vmess: $node_80"
echo "Node ID 443 trojan: $node_443"
echo "Cài đặt chứng chỉ SSL: $( [ "$ssl" -eq 1 ] && echo "Có" || echo "Không" )"

echo "Bạn có muốn tiếp tục cài đặt không?"
echo "1. Có"
echo "2. Hủy"
read -p "Nhập lựa chọn: " confirm

if [ "$confirm" -eq 1 ]; then
    echo "Đang cài đặt..."
    bash <(curl -ls https://raw.githubusercontent.com/AikoPanel/AikoServer/master/install.sh)

    cd /etc/Aiko-Server
    mkdir cert

    cat >aiko.yml <<EOF
Nodes:
  - PanelType: "AikoPanel"
    ApiConfig:
      ApiHost: "$domain_web"
      ApiKey: "$api_key"
      NodeID: ${node_80}
      NodeType: V2ray
      Timeout: 30
      EnableVless: false
    ControllerConfig:
      DisableLocalREALITYConfig: false
      EnableREALITY: false
      REALITYConfigs:
        Show: true
      CertConfig:
        CertMode: none
        CertFile: /etc/Aiko-Server/cert/aiko_server.cert
        KeyFile: /etc/Aiko-Server/cert/aiko_server.key
  - PanelType: "AikoPanel"
    ApiConfig:
      ApiHost: "$domain_web"
      ApiKey: "$api_key"
      NodeID: ${node_443}
      NodeType: Trojan
      Timeout: 30
      EnableVless: false
    ControllerConfig:
      DisableLocalREALITYConfig: false
      EnableREALITY: false
      REALITYConfigs:
        Show: true
      CertConfig:
        CertMode: file
        CertFile: /etc/Aiko-Server/cert/aiko_server.cert
        KeyFile: /etc/Aiko-Server/cert/aiko_server.key     
EOF

    if [ "$ssl" -eq 1 ]; then
        echo "Đang cài đặt chứng chỉ SSL..."
        aiko-server cert
    else
        echo "Bạn đã không cài đặt chứng chỉ SSL"
    fi

    cd /root

else
    echo "Cài đặt đã bị hủy."
fi
