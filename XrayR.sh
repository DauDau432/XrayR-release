#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "  lỗi: Tập lệnh này phải được chạy với tư cách người dùng gốc！\n" && exit 1

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
    echo -e "  Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản！${plain}\n" && exit 1
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
        echo -e "  Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "  Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "  Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [mặc định$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "  Có khởi động lại XrayR không" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "  Nhấn enter để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/XrayR-release/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "  Nhập phiên bản được chỉ định (phiên bản mới nhất mặc định): " && read version
    else
        version=$2
    fi
#    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}已取消${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/XrayR-release/main/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "  Cập nhật hoàn tất, XrayR đã được khởi động lại tự động, vui lòng sử dụng XrayR log để xem nhật ký đang chạy ${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "  XrayR sẽ tự động khởi động lại sau khi sửa đổi cấu hình"
    vi /etc/XrayR/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "  Trạng thái XrayR: đã được chạy${plain}"
            ;;
        1)
            echo -e "  Nó được phát hiện rằng bạn không khởi động XrayR hoặc XrayR không tự khởi động lại, hãy kiểm tra nhật ký？[Y/n]" && echo
            read -e -p "(mặc định: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "  Trạng thái XrayR: Chưa được cài đặt${plain}"
    esac
}

uninstall() {
    confirm "  Bạn có chắc chắn muốn gỡ cài đặt XrayR không?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR
    systemctl disable XrayR
    rm /etc/systemd/system/XrayR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/XrayR/ -rf
    rm /usr/local/XrayR/ -rf

    echo ""
    echo -e "  Gỡ cài đặt thành công, " # nếu bạn muốn xóa tập lệnh này, hãy chạy sau khi thoát tập lệnh rm /usr/bin/XrayR -f xóa"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "  XrayR đã chạy rồi, không cần khởi động lại, nếu muốn khởi động lại, vui lòng chọn khởi động lại${plain}"
    else
        systemctl start XrayR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "  XrayR đã khởi động thành công, vui lòng sử dụng XrayR log để xem nhật ký đang chạy${plain}"
        else
            echo -e "  XrayR có thể không khởi động được, vui lòng sử dụng XrayR log để xem thông tin nhật ký sau này${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop XrayR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "  XrayR đã dừng thành công ${plain}"
    else
        echo -e "  XrayR không dừng được, có thể do thời gian dừng vượt quá hai giây, vui lòng kiểm tra thông tin nhật ký sau${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "  XrayR đã khởi động lại thành công, vui lòng sử dụng XrayR log để xem nhật ký đang chạy${plain}"
    else
        echo -e "  XrayR có thể không khởi động được, vui lòng sử dụng XrayR log để xem thông tin nhật ký sau này${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "  XrayR được thiết lập để khởi động thành công${plain}"
    else
        echo -e "  Thiết lập XrayR không thể tự động khởi động khi khởi động${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "  XrayR đã hủy khởi động tự động khởi động thành công${plain}"
    else
        echo -e "  XrayR không thể hủy tự động khởi động khởi động${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}安装 bbr 成功，请重启服务器${plain}"
    #else
    #    echo ""
    #    echo -e "${red}下载 bbr 安装脚本失败，请检查本机能否连接 Github${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/XrayR -N --no-check-certificate https://raw.githubusercontent.com/DauDau432/XrayR-release/main/XrayR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "  Không tải được script xuống, vui lòng kiểm tra xem máy có thể kết nối với Github không${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/XrayR
        echo -e "  Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh ${plain}" && exit 0
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

check_enabled() {
    temp=$(systemctl is-enabled XrayR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "  XrayR đã được cài đặt, vui lòng không cài đặt lại${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "  Vui lòng cài đặt XrayR trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "  Trạng thái XrayR: đã được chạy${plain}"
            show_enable_status
            ;;
        1)
            echo -e "  Trạng thái XrayR: Không chạy${plain}"
            show_enable_status
            ;;
        2)
            echo -e "  Trạng thái XrayR: Chưa được cài đặt${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "  Có tự động bắt đầu không: Có${plain}"
    else
        echo -e "  Có tự động khởi động hay không: Không${plain}"
    fi
}

show_XrayR_version() {
    echo -n "  Phiên bản XrayR："
    /usr/local/XrayR/XrayR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo ''
    echo "------------[Đậu Đậu việt hóa]------------"
    echo "  Cách sử dụng tập lệnh quản lý XrayR: "
    echo "------------------------------------------"
    echo "  XrayR              - Hiển thị menu quản trị (nhiều chức năng hơn) "
    echo "  XrayR start        - Khởi động XrayR "
    echo "  XrayR stop         - Dừng XrayR"
    echo "  XrayR restart      - Khởi động lại XrayR"
    echo "  XrayR status       - Xem trạng thái XrayR"
    echo "  XrayR enable       - Đặt XrayR để bắt đầu tự động"
    echo "  XrayR disable      - Hủy tự động khởi động XrayR"
    echo "  XrayR log          - Xem nhật ký XrayR"
    echo "  XrayR update       - Cập nhật XrayR"
    echo "  XrayR update x.x.x - Cập nhật phiên bản được chỉ định XrayR"
    echo "  XrayR install      - Cài đặt XrayR"
    echo "  XrayR uninstall    - Gỡ cài đặt XrayR "
    echo "  XrayR version      - Xem các phiên bản XrayR"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
    Các tập lệnh quản lý phụ trợ XrayR，không hoạt động với docker${plain}
    ${green}--- [Đậu Đậu việt hóa] ---${plain}
    0. Thay đổi cài đặt
————————————————————————————————
    1. Cài đặt XrayR
    2. Cập nhật XrayR
    3. Gỡ cài đặt XrayR
————————————————————————————————
    4. Khởi động XrayR
    5. Dừng XrayR
    6. Khởi động lại XrayR
    7. Xem trạng thái XrayR
    8. Xem nhật ký XrayR
————————————————————————————————
    9. Đặt XrayR để bắt đầu tự động
   10. Hủy tự động khởi động XrayR
————————————————————————————————
   11. Một cú nhấp chuột cài đặt bbr (hạt nhân mới nhất)
   12. Xem các phiên bản XrayR
   13. Nâng cấp Tập lệnh Bảo trì
————————————————————————————————   
 "
 #Các bản cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "  Vui lòng nhập một lựa chọn [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_XrayR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "  Vui lòng nhập số chính xác [0-13]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
