# XRayR
Một khung phụ trợ Xray có thể dễ dàng hỗ trợ nhiều bảng.

Một khung công tác back-end dựa trên Xray, hỗ trợ các giao thức V2ay, Trojan, Shadowsocks, cực kỳ dễ dàng mở rộng và hỗ trợ kết nối nhiều bảng điều khiển

Tìm mã nguồn tại đây: [XrayR-project/XrayR](https://github.com/XrayR-project/XrayR)

## Hướng dẫn chi tiết
[Hướng dẫn](https://crackair.gitbook.io/xrayr-project/)

## Cài đặt 
```
bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/XrayR-release/main/install.sh)
```
## Cấu hình xrayr
Vào thư mục này để cấu hình
```
vi /etc/XrayR/config.yml
```
1: dòng `pannel` : ví dụ `V2board`, `SSpanel`,... (chữ đầu viết hoa)

2: dòng `Api` : ví dụ `https://domain.com/` (thêm / đằng sau)

3: dòng `key` : key của web

4: dòng `cert mode` : `http`

5: dòng `cert domain` : `IP` của server muốn đưa lên web
Thêm dòng này trên đầu `listenip` để fix lỗi zalo 
```
DisableSniffing: true
```

Dòng nào có ngoặc kép nhớ để ý viết trong ngoặc kép

Cấu hình xong nhớ khởi động lại xrayr nhé.
