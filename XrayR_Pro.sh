#!/bin/bash

clear

# Hỏi thông tin chung
echo ""
read -p "  Nhập domain web (không cần https://): " api_host
[ -z "${api_host}" ] && { echo "  Domain không được để trống."; exit 1; }
read -p "  Nhập key của web: " api_key
[ -z "${api_key}" ] && { echo "  Key không được để trống."; exit 1; }

# Hỏi số lượng node
read -p "  Nhập số lượng node cần cài (1 hoặc 2, mặc định 1): " node_count
echo "--------------------------------"
[ -z "${node_count}" ] && node_count="1"
if [[ "$node_count" != "1" && "$node_count" != "2" ]]; then
  echo "  Số lượng node không hợp lệ, chỉ chấp nhận 1 hoặc 2."
  exit 1
fi

# Lấy địa chỉ IP của VPS
vps_ip=$(hostname -I | awk '{print $1}')

# Khai báo mảng lưu thông tin node
declare -A nodes

# Hỏi thông tin cho từng node
for i in $(seq 1 $node_count); do
  echo ""
  echo "  [1] Vmess"
  echo "  [2] Vless"
  echo "  [3] Trojan"
  read -p "  Chọn loại Node: " NodeType
  if [ "$NodeType" == "1" ]; then
      NodeType="V2ray"
      NodeName="Vmess"
      EnableVless="false"
  elif [ "$NodeType" == "2" ]; then
      NodeType="V2ray"
      NodeName="Vless"
      EnableVless="true"
  elif [ "$NodeType" == "3" ]; then
      NodeType="Trojan"
      NodeName="Trojan"
      EnableVless="false"
  else
      echo "  Loại Node không hợp lệ, mặc định là Vmess"
      NodeType="V2ray"
      NodeName="Vmess"
      EnableVless="false"
  fi

  read -p "  Nhập ID Node: " node_id
  [ -z "${node_id}" ] && { echo "  ID Node không được để trống."; exit 1; }

  nodes[$i,NodeType]=$NodeType
  nodes[$i,NodeName]=$NodeName
  nodes[$i,node_id]=$node_id
  nodes[$i,CertDomain]=$vps_ip
  nodes[$i,EnableVless]=$EnableVless
done

# Hiển thị thông tin đã nhập và yêu cầu xác nhận
clear
echo ""
echo "  Thông tin cấu hình"
echo "--------------------------------"
echo "  Domain web: https://${api_host}"
echo "  Key web: ${api_key}"
echo "  Địa chỉ Node: ${nodes[$i,CertDomain]}"
for i in $(seq 1 $node_count); do
  echo ""
  echo "  Loại Node: ${nodes[$i,NodeName]}"
  echo "  ID Node: ${nodes[$i,node_id]}"
done
echo "--------------------------------"
read -p "  Bạn có muốn tiếp tục cài đặt không? (y/n, mặc định y): " confirm
confirm=${confirm:-y}
if [ "$confirm" != "y" ]; then
  echo "  Hủy bỏ cài đặt."
  exit 0
fi

# Hàm cài đặt
install_node() {
  local i=$1
  local NodeType=${nodes[$i,NodeType]}
  local node_id=${nodes[$i,node_id]}
  local CertDomain=${nodes[$i,CertDomain]}
  local EnableVless=${nodes[$i,EnableVless]}

  cat >>/etc/XrayR/config.yml<<EOF
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel, Proxypanel, V2RaySocks
    ApiConfig:
      ApiHost: "https://${api_host}"
      ApiKey: "${api_key}"
      NodeID: ${node_id}
      NodeType: ${NodeType} # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: ${EnableVless} # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/XrayR/rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send package
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      DisableUploadTraffic: false # Disable Upload Traffic to the panel
      DisableGetRule: false # Disable Get Rule from the panel
      DisableIVCheck: false # Disable the anti-reply protection for Shadowsocks
      DisableSniffing: true # Disable domain sniffing
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      AutoSpeedLimitConfig:
        Limit: 0 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 0 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 0 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 0 # How many minutes will the limiting last (unit: minute)
      GlobalDeviceLimitConfig:
        Limit: 0 # The global device limit of a user, 0 means disable
        RedisAddr: 127.0.0.1:6379 # The redis server address
        RedisPassword: YOUR PASSWORD # Redis password
        RedisDB: 0 # Redis DB
        Timeout: 5 # Timeout for redis request
        Expiry: 60 # Expiry time (second)
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "${CertDomain}" # Domain to cert
        CertFile: /etc/XrayR/443.crt # Provided if the CertMode is file
        KeyFile: /etc/XrayR/443.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
EOF
}

# Cài đặt XrayR và cấu hình
bash <(curl -Ls https://raw.githubusercontent.com/qtai2901/XrayR-release/main/install.sh)
openssl req -newkey rsa:2048 -x509 -sha256 -days 365 -nodes -out /etc/XrayR/443.crt -keyout /etc/XrayR/443.key -subj "/C=JP/ST=Tokyo/L=Chiyoda-ku/O=Google Trust Services LLC/CN=google.com"
cd /etc/XrayR
cat >config.yml <<EOF
Log:
  Level: none # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB  
Nodes:
EOF

# Gọi hàm cài đặt cho từng node
for i in $(seq 1 $node_count); do
  install_node $i
done

cd /root
clear
echo ""
xrayr restart
