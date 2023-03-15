#!/bin/bash
clear
echo ""
echo "   1. Cài đặt"
echo "   2. update config"
echo "   3. thêm node"
read -p "   Lựa chọn của bạn là (mặc định Cài đặt): " num
[ -z "${num}" ] && num="1"
    
pre_install(){
 clear
    read -p "  Nhập số Node cần cài (mặc định 1): " n
     [ -z "${n}" ] && n="1"
    a=0
  while [ $a -lt $n ]
 do
 read -p "  Nhập domain web (không cần https://): " api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
  echo "  Web của bạn là https://${api_host}"
  echo "--------------------------------"
  #key web
  read -p "  Nhập key của web: " api_key
    [ -z "${api_key}" ] && api_key=0
  echo "--------------------------------"
  echo "  Key của Web là ${api_key}"
  echo "--------------------------------"

  echo -e "  [1] V2ray"
  echo -e "  [2] Trojan"
   read -p "  Nhập loại Node: " NodeType
  if [ "$NodeType" == "1" ]; then
    NodeType="V2ray"
  elif [ "$NodeType" == "2" ]; then
    NodeType="Trojan"
  else 
   NodeType="V2ray"
  fi
  echo "-------------------------------"
  echo -e "  Loại Node là ${NodeType}"
  echo "-------------------------------"


  #node id
    read -p "  Nhập ID Node: " node_id
  [ -z "${node_id}" ] && node_id=0
  echo "-------------------------------"
  echo -e "  ID Node là ${node_id}"
  echo "-------------------------------"
  

  #giới hạn thiết bị
read -p "  Nhập giới hạn thiết bị: " DeviceLimit
  [ -z "${DeviceLimit}" ] && DeviceLimit="0"
  echo "-------------------------------"
  echo "  Thiết bị tối đa là ${DeviceLimit}"
  echo "-------------------------------"
  
  
  #IP vps
 read -p "  Nhập địa chỉ Node: " CertDomain
  [ -z "${CertDomain}" ] && CertDomain="0"
 echo "-------------------------------"
  echo "  Địa chỉ Node là ${CertDomain}"
 echo "-------------------------------"

 config
  a=$((a+1))
done
}


#clone node
clone_node(){
  clear
    read -p "  Nhập số Node cần cài thêm (mặc định 1): " n
     [ -z "${n}" ] && n="1"
    a=0
  while [ $a -lt $n ]
  do
  
  #link web 
   read -p "  Nhập domain web (không cần https://): " api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
  echo "  Web của bạn là https://${api_host}"
  echo "--------------------------------"
  #key web
  read -p "  Nhập key của web: " api_key
    [ -z "${api_key}" ] && api_key=0
  echo "--------------------------------"
  echo "  Key của web là ${api_key}"
  echo "--------------------------------"

  echo -e "  [1] V2ray"
  echo -e "  [2] Trojan"
   read -p "  Nhập loại Node: " NodeType
  if [ "$NodeType" == "1" ]; then
    NodeType="V2ray"
  elif [ "$NodeType" == "2" ]; then
    NodeType="Trojan"
  else 
   NodeType="V2ray"
  fi
  echo "-------------------------------"
  echo -e "  Loại Node là ${NodeType}"
  echo "-------------------------------"

  #node id
    read -p "  Nhập ID Node: " node_id
  [ -z "${node_id}" ] && node_id=0
  echo "-------------------------------"
  echo -e "  ID Node là ${node_id}"
  echo "-------------------------------"
  

  #giới hạn thiết bị
read -p "  Nhập giới hạn thiết bị: " DeviceLimit
  [ -z "${DeviceLimit}" ] && DeviceLimit="0"
  echo "-------------------------------"
  echo "  Thiết bị tối đa là ${DeviceLimit}"
  echo "-------------------------------"
  
  #IP vps
 read -p "  Nhập địa chỉ Node: " CertDomain
  [ -z "${CertDomain}" ] && CertDomain="0"
 echo "-------------------------------"
  echo "  Địa chỉ Node là ${CertDomain}"
 echo "-------------------------------"

 config
  a=$((a+1))
  done
}







config(){
cd /etc/XrayR
cat >>config.yml<<EOF
  -
    PanelType: "V2board" # Panel type: SSpanel, V2board, PMpanel, Proxypanel, V2RaySocks
    ApiConfig:
      ApiHost: "https://$api_host"
      ApiKey: "$api_key"
      NodeID: $node_id
      NodeType: $NodeType # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: $DeviceLimit # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/XrayR/rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      DisableUploadTraffic: false # Disable Upload Traffic to the panel
      DisableGetRule: false # Disable Get Rule from the panel
      DisableIVCheck: false # Disable the anti-reply protection for Shadowsocks
      DisableSniffing: True # Disable domain sniffing
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
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "$CertDomain" # Domain to cert
        CertFile: /etc/XrayR/443.crt # Provided if the CertMode is file
        KeyFile: /etc/XrayR/443.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
EOF

#   sed -i "s|ApiHost: \"https://domain.com\"|ApiHost: \"${api_host}\"|" ./config.yml
 # sed -i "s|ApiKey:.*|ApiKey: \"${ApiKey}\"|" 
#   sed -i "s|NodeID: 41|NodeID: ${node_id}|" ./config.yml
#   sed -i "s|DeviceLimit: 0|DeviceLimit: ${DeviceLimit}|" ./config.yml
#   sed -i "s|SpeedLimit: 0|SpeedLimit: ${SpeedLimit}|" ./config.yml
#   sed -i "s|CertDomain:\"node1.test.com\"|CertDomain: \"${CertDomain}\"|" ./config.yml
 }

case "${num}" in
1) bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/XrayR-release/main/install.sh)
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
pre_install
cd /root
xrayr start
 ;;
 2) cd /etc/XrayR
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
pre_install
cd /root
xrayr restart
 ;;
 3) cd /etc/XrayR
 clone_node
 cd /root
  xrayr restart
;;
esac
