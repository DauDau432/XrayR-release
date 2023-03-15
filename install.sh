#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "  lỗi：${plain} Tập lệnh này phải được chạy với quyềb root \n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
echo ""
    echo -e "  Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản！${plain}\n" && exit 1
    echo ""
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "  Không phát hiện được giản đồ, hãy sử dụng lược đồ mặc định: ${arch}${plain}"
  echo ""
fi
echo ""
echo "  phiên bản của hệ điều hành: ${arch}"
echo ""

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo ""
    echo "  Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), nếu phát hiện sai, vui lòng liên hệ với tác giả"
    echo ""
    exit 2
fi

os_version=""

# phiên bản của hệ điều hành
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
    echo ""
        echo -e "  Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
    echo ""
        echo -e "  Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
    echo ""
        echo -e "  Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: đang chạy, 1: không chạy, 2: chưa cài đặt
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_XrayR() {
    if [[ -e /usr/local/XrayR/ ]]; then
        rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/
    
    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/XrayR-project/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
	echo ""
            echo -e "  Phát hiện phiên bản XrayR không thành công, có thể vượt quá giới hạn GIthub API, vui lòng thử lại sau hoặc chỉ định cài đặt phiên bản XrayR theo cách thủ công${plain}"
	    echo ""
            exit 1
        fi
	echo ""
        echo -e "  Phiên bản mới nhất của XrayR đã được phát hiện：${last_version}，Bắt đầu cài đặt"
	echo ""
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
	echo ""
            echo -e "  Tải xuống XrayR thất bại, hãy chắc chắn rằng máy chủ của bạn có thể tải về các tập tin Github${plain}"
	    echo ""
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip"
	echo ""
        echo -e "  Bắt đầu cài đặt XrayR v$1"
	echo ""
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
	echo ""
            echo -e "  Tải xuống XrayR v$1 Thất bại, hãy chắc chắn rằng phiên bản này tồn tại"
	    echo ""
            exit 1
        fi
    fi

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    rm /etc/systemd/system/XrayR.service -f
    file="https://github.com/DauDau432/XrayR-release/raw/main/XrayR.service"
    wget -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    #cp -f XrayR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo ""
    echo -e "  XrayR ${last_version} Quá trình cài đặt hoàn tất, nó đã được bật để khởi động tự động"
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 

    if [[ ! -f /etc/XrayR/config.yml ]]; then
        cp config.yml /etc/XrayR/
        echo -e ""
        echo -e "  Cài đặt mới, vui lòng tham khảo hướng dẫn trước：https://github.com/DauDau432/XrayR-release，Định cấu hình nội dung cần thiết"
	echo ""
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "  XrayR đã khởi động lại thành công${plain}"
        else
            echo -e "  XrayR không khởi động được, vui lòng sử dụng XrayR log để kiểm tra thông tin nhật ký sau này, "
	    echo "  nếu không khởi động được, định dạng cấu hình có thể đã bị thay đổi, vui lòng liên hệ：https://zalo.me/0983538806 để được hộ trợ"
        fi
    fi

    if [[ ! -f /etc/XrayR/dns.json ]]; then
        cp dns.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/route.json ]]; then
        cp route.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/XrayR/
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/scan/main/vps)
    curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/DauDau432/XrayR-release/main/XrayR.sh
    chmod +x /usr/bin/XrayR
    ln -s /usr/bin/XrayR /usr/bin/xrayr # chữ thường tương thích
    chmod +x /usr/bin/xrayr
 
    echo -e ""
    echo "------------[Đậu Đậu việt hóa]------------"
    echo "  Cách sử dụng tập lệnh quản lý XrayR"
    echo "------------------------------------------"
    echo "  XrayR                    - Hiển thị menu quản lý (nhiều chức năng hơn)"
    echo "  XrayR start              - Khởi động XrayR"
    echo "  XrayR stop               - Dừng XrayR"
    echo "  XrayR restart            - Khởi động lại XrayR"
    echo "  XrayR status             - Xem trạng thái XrayR"
    echo "  XrayR enable             - Bật tự động khởi động XrayR"
    echo "  XrayR disable            - Hủy tự động khởi động XrayR"
    echo "  XrayR log                - Xem nhật ký XrayR"
    echo "  XrayR update             - Cập nhật XrayR"
    echo "  XrayR update x.x.x       - Cập nhật phiên bản XrayR"
    echo "  XrayR config             - hiển thị nội dung tệp cấu hình"
    echo "  XrayR install            - Cài đặt XrayR"
    echo "  XrayR uninstall          - Gỡ cài đặt XrayR"
    echo "  XrayR version            - Xem phiên bản XrayR"
    echo "------------------------------------------"
}

echo -e "  bắt đầu cài đặt ${plain}"
install_base
install_acme
install_XrayR $1
