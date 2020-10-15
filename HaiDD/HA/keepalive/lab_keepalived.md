# Cấu hình Keepalived trên 2 node CentOS 7

**Chuẩn bị 2 máy chạy CentOS-7:**

1. Máy 1:
    - eth0: 10.10.35.164

2. Máy 2:
    - eth0: 10.10.35.165

VIP: 10.10.35.170

## 1. Cài đặt chương trình Keepalived
Thực hiện cài đặt Keepalived trên cả 2 node
```
yum install keepalived -y
```

## 2. Cài đặt chương trình Web Server trên 2 node
```
yum install httpd -y
```

Start service:
```
systemctl start httpd
systemctl enable httpd
```

Thêm file để xác nhận 2 web khi ta truy cập bằng VIP:
- Trên máy 1:
    ```
    echo '<h1>Máy 01 - 10.10.35.164</h1>' > /var/www/html/index.html
    ```

- Trên máy 2:
    ```
    echo '<h1>Máy 02 - 10.10.35.165</h1>' > /var/www/html/index.html
    ```

## 3. Cấu hình Keepalived
Cấu hình cho phép gắn địa chỉ IP ảo lên card mạng và IP Forward.
```
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

File cấu hình của keepalived: `/etc/keepalived/keepalived.conf`

Một số block cấu hình đáng chú ý trong file này như sau:

- `global_defs`: cấu hình thông tin toàn cục (global) cho keepalived như gửi email thông báo tới đâu, tên của cluster đang cấu hình.
- `vrrp_script`: chứa script, lệnh thực thi hoặc đường dẫn tới script kiểm tra dịch vụ (Ví dụ: nếu dịch vụ này down thì keepalived sẽ tự chuyển VIP sang 1 server khác).
- `vrrp_instance`: thông tin chi tiết về 1 server vật lý trong nhóm dùng chung VRRP. Gồm các thông tin như interface dùng để liên lạc của server này, độ ưu tiên để, virtual IP tương ứng với interface, cách thức chứng thực, script kiểm tra dịch vụ….

**Chú thích cấu hình block vrrp_instance**
– Trong các phần giải thích dưới, router sẽ đồng nghĩa với máy chủ dịch vụ .

- `state` (MASTER|BACKUP): chỉ trạng thái MASTER hoặc BACKUP được sử dụng bởi máy chủ. Nếu là MASTER thì máy chủ này có nhiệm vụ nhận và xử lý các gói tin từ host đi lên. Nếu con MASTER down, những con BACKUP này sẽ dựa vào 1 cơ chế bầu chọn và nhảy lên làm Master.
- `interface`: chỉ định cổng mạng nào sẽ sử dụng cho hoạt động IP Failover – VRRP
- `mcast_src_ip`: địa chỉ IP thực của card mạng Interface của máy chủ tham gia vào VRRP. Các gói tin trao đổi giữa các VRRP Router sử dụng địa chỉ thực này.
- `virtual_router_id`: định danh cho các router (ở đây là máy chủ dịch vụ) thuộc cùng 1 nhóm VRRP. Hiểu nôm na là 1 router có thể tham gia nhiều nhóm VRRP (các nhóm hoạt động động lập nhau), và VRRP-ID là tên gọi của từng nhóm.
- `priority`: chỉ định độ ưu tiên của VRRP router (tức độ ưu tiên máy chủ dịch vụ trong quá trình bầu chọn MASTER). Các VRRP Router trong cùng một VRRP Group tiến hành bầu chọn Master sử dụng giá trị priority đã cấu hình cho máy chủ đó. Priority có giá trị từ 0 đến 255. Nguyên tắc có bản: Priority cao nhất thì nó là Master, nếu priority bằng nhau thì IP cao hơn là Master.
- `advert_int`: thời gian giữa các lần gởi gói tin VRRP advertisement (đơn vị giây).
- `smtp_alert`: kích hoạt thông báo bằng email SMTP khi trạng thái MASTER có sự thay đổi.
- `authentication`: chỉ định hình thức chứng thực trong VRRP. ‘auth_type‘, sử dụng hình thức mật khẩu plaintext hay mã hoá AH. ‘auth_pass‘, chuỗi mật khẩu chỉ chấp nhận 8 kí tự.
- `virtual_ipaddress`: Địa chỉ IP ảo của nhóm VRRP đó (Chính là địa chỉ dùng làm gateway cho các host). Các gói tin trao đổi, làm việc với host đều sử dụng địa chỉ ảo này.
- `notify_master`: chỉ định chạy shell script nếu có sự kiện thay đổi về trạng thái MASTER.
- `notify_backup`: chỉ định chạy shell script nếu có sự kiện thay đổi về trạng thái BACKUP.
- `notify_fault`: chỉ định chạy shell script nếu có sự kiện thay đổi về trạng thái thất bại (fault).

## Cấu hình trên 2 node:
Ta sẽ sử dụng keepalive để kiếm tra trạng thái của 2 web trong mỗi 2 giây, và nếu kiếm tra thành công node sẽ được + 2 điểm.
```
vrrp_script chk_httpd {
    script "killall -0 httpd" # check the httpd process
    interval 2 # every 2 seconds
    weight 2 # add 2 points if OK
}
```

Tiếp theo chúng ta sẽ tạo block với tên vrrp_instance. Đây là thành phần chính khi cấu hình HA cho dịch vụ HAProxy. Theo bài, tôi cấu hình cho keepalived kết nối với các dịch vụ tương tự nó thuộc các node khác thông giao diện mạng `eth0`

Mô hình keepalive là `MASTER` - `SLAVE` nên chúng ta cần chỉ định node Master và node Slave. Trong bài ta sẽ cấu hình node1 làm node master với tham số state bằng `MASTER`. node2 làm node slave với cấu hình state bằng `BACKUP`.

Tiếp theo, chúng ta cần quan tâm tới giá trị priority trên mỗi node. Giá trị ưu tiên lần lượt trên node1 node2 sẽ bằng 100 99.
```
# Trên Node1
vrrp_instance VI_1 {
    ..
    priority 100
    ..
}

# Trên Node2
vrrp_instance VI_1 {
    ..
    priority 99
    ..
}
```

Cụm cần chỉ định một ID chia sẽ giữa các node. Tôi sẽ sử dụng giá trị 51 trong bài.
```
vrrp_instance VI_1 {
    ..
    virtual_router_id 51
    ..
}
```

Để khai báo IP VIP cho cụm 2 node. Tôi sẽ sử dụng block `virtual_ipaddress`, khai báo 1 IP cùng dải `eth0`. Ở đây tôi chọn ip 10.10.35.70
```
vrrp_instance VI_1 {
    ..
    virtual_ipaddress {
        10.10.35.70/24 # virtual ip address 
    }
    ..
}
```

Cuối cùng là `track_script`. track-`script` giúp keepalived xác định node nào sẽ nắm IP VIP. Như trong bài node1 được cấu hình với độ ưu tiên bằng 100. Nếu node1 kiểm tra dịch vụ httpd thành công thì độ ưu tiên của nó không đổi nhưng nếu kiếm tra thất bại thì độ ưu tiên của node1 sẽ giảm đi 2 và thập hơn node2. Khi đó node2 sẽ được chuyển IP VIP sang. Đây là cách dịch vụ keepalived hoạt động.
```
vrrp_instance VI_1 {
    ..
    track_script {
        chk_httpd
    }
    ..
}
```

=> Cấu hình đầy đủ keepalived
#### Trên node 1:
```
echo '
vrrp_script chk_httpd {
    script "killall -0 httpd"
    interval 2
    weight 2 
}
vrrp_instance VI_1 {
    interface eth0
    state MASTER
    virtual_router_id 51
    priority 100
    virtual_ipaddress {
        10.10.35.170/24
    }
    track_script {
        chk_httpd
    }
}' > /etc/keepalived/keepalived.conf
```

#### Trên node 2:
```
echo '
vrrp_script chk_httpd {
    script "killall -0 httpd"
    interval 2
    weight 2 
}
vrrp_instance VI_1 {
    interface eth0
    state BACKUP
    virtual_router_id 51
    priority 99
    virtual_ipaddress {
        10.10.35.170/24
    }
    track_script {
        chk_httpd
    }
}' > /etc/keepalived/keepalived.conf
```

Khởi động dịch vụ trên 2 node:
```
systemctl start keepalived
systemctl enable keepalived
```

Kiểm tra node1, ta sẽ thấy IP VIP do keepalived quản lý:

<img src="..\images\keepalive\Screenshot_5.png">