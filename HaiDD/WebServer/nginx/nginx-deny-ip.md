# Deny/Allow IP/dải IP truy cập vào website bằng Nginx

## Deny IPs:
Trong file cấu hình của trang web:
```
/etc/nginx/conf.d/domain.com.conf
```

Ví dụ:
```
/etc/nginx/conf.d/thongke.dangdohai.xyz.conf
```

1. Chặn 1 địa chỉ IP:
```
server {
    server_name thongke.dangdohai.xyz;
    ...
    deny 10.10.10.10;
    ...
}
```

2. Chặn 1 dải địa chỉ
```
server {
    server_name thongke.dangdohai.xyz;
    ...
    deny 10.10.10.0/24;
    ...
}
```

3. Chặn tất cả IP
```
server {
    server_name thongke.dangdohai.xyz;
    ...
    deny all;
    ...
}
```

Sau đó lưu lại cấu hình. Kiểm tra lại:
```
nginx -t

nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Restart service
```
systemctl restart nginx
```

## Allow IP
Cho phép 1 IP truy cập:
```
allow 1.2.3.4;
```

## Kết hợp để chỉ cho phép 1 IP truy cập:
```
allow 1.2.3.4;
deny all;
```

## Allow / Deny theo danh sách
Tạo file `/etc/nginx/allow-block-ip.conf` có nội dung tương tự sau:
```
allow 333.444.555.666;
deny 11.22.33.44;
deny 123.567.897/24;
```

Thêm dòng sau vào thẻ server của vhost
```
include /etc/nginx/allow-block-ip.conf;
```

**Lưu ý:** Khi sử dụng kết hợp `deny` và `allow` thì rule  nào khai báo trước sẽ được thực hiện trước.

Ví dụ: bạn để `deny all;` trước sau đó khai báo `allow` thì các rule `allow` sẽ không có tác dụng