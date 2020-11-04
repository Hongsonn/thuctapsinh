# Triển khai HAProxy cho Apache trên CentOS-7

HAProxy viết tắt của High Availability Proxy, là công cụ mã nguồn mở nổi tiếng ứng dụng cho giải pháp cân bằng tải TCP/HTTP cũng như giải pháp máy chủ Proxy (Proxy Server). HAProxy có thể chạy trên các mỗi trường Linux, Solaris, FreeBSD. Công dụng phổ biến nhất của HAProxy là cải thiện hiệu năng, tăng độ tin cậy của hệ thống máy chủ bằng cách phân phối khối lượng công việc trên nhiều máy chủ (như Web, App, cơ sở dữ liệu). HAProxy hiện đã và đang được sử dụng bởi nhiều website lớn như GoDaddy, GitHub, Bitbucket, Stack Overflow, Reddit, Speedtest.net, Twitter và trong nhiều sản phẩm cung cấp bởi Amazon Web Service.

Dịch vụ keepalived sử dụng với mục đích tạo ra virtual ip address (IP VIP) cho hệ thống. Tiến trình keepalived có thể tự động giám sát dịch vụ hoặc hệ thống và có khả năng chịu lỗi cho hệ thống khi dịch vụ hoặc hệ điều hành xảy ra vấn đề. Trong bài hướng dẫn, tôi sẽ sử dụng keepalived để tăng tính sẵn sàng cho dịch vụ cân bằng tải.

# Phần 1: Chuẩn bị
**Phân hoạch IP:**

<img src="..\images\haproxy\Screenshot_4.png">

**Mô hình**

Mô hình triển khai:

<img src="..\images\haproxy\Screenshot_5.png">

Mô hình triển khai:

<img src="..\images\haproxy\Screenshot_6.png">

# Phần 2: Cấu hình Apache
Thực hiện trên `node1`
```
yum install httpd -y

cat /etc/httpd/conf/httpd.conf | grep 'Listen 80'
sed -i "s/Listen 80/Listen 10.10.34.164:8081/g" /etc/httpd/conf/httpd.conf

echo '<h1>Chào mừng tới (Web1)</h1>' > /var/www/html/index.html

systemctl start httpd
systemctl enable httpd
```

Thực hiện trên `node2`
```
yum install httpd -y

cat /etc/httpd/conf/httpd.conf | grep 'Listen 80'
sed -i "s/Listen 80/Listen 10.10.34.165:8081/g" /etc/httpd/conf/httpd.conf

echo '<h1>Chào mừng tới (Web2)</h1>' > /var/www/html/index.html

systemctl start httpd
systemctl enable httpd
```

Thực hiện trên `node3`
```
yum install httpd -y

cat /etc/httpd/conf/httpd.conf | grep 'Listen 80'
sed -i "s/Listen 80/Listen 10.10.34.166:8081/g" /etc/httpd/conf/httpd.conf

echo '<h1>Chào mừng tới (Web3)</h1>' > /var/www/html/index.html

systemctl start httpd
systemctl enable httpd
```

# Phần 3: Triển khai Keepalived
Xem thêm tại : [Cấu hình Keepalived trên 2 node CentOS 7](../keepalive/lab_keepalived_1.md)

Cài đặt gói Keepalive trên cả 3 node
```
yum install keepalived -y
```

Trên `node1`:
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

Trên `node2`:
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

Trên `node2`:
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
    priority 98
    virtual_ipaddress {
        10.10.35.170/24
    }
    track_script {
        chk_httpd
    }
}' > /etc/keepalived/keepalived.conf
```

Khởi động dịch vụ trên 3 node:
```
systemctl start keepalived
systemctl enable keepalived
```

Kiểm tra node1, ta sẽ thấy IP VIP do keepalived quản lý:

<img src="..\images\haproxy\Screenshot_7.png">

# Phần 4: Cài đặt HAProxy 1.8
> ## Thực hiện trên tất cả node

Cài đặt
```
yum install wget socat -y

wget http://cbs.centos.org/kojifiles/packages/haproxy/1.8.1/5.el7/x86_64/haproxy18-1.8.1-5.el7.x86_64.rpm 

yum install haproxy18-1.8.1-5.el7.x86_64.rpm -y
```

Tạo bản backup cho cấu hình mặc định và chỉnh sửa cấu hình HAproxy
```
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

Cấu hình Haproxy
```
echo 'global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    maxconn                 8000
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    retries                 3
    timeout http-request    20s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s

listen stats
    bind *:8080 interface eth0
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats admin if TRUE

listen web-backend
    bind *:80
    balance  roundrobin
    cookie SERVERID insert indirect nocache
    mode  http
    option  httpchk
    option  httpclose
    option  httplog
    option  forwardfor
    server node1 10.10.34.164:8081 check cookie node1 inter 5s fastinter 2s rise 3 fall 3
    server node2 10.10.34.165:8081 check cookie node2 inter 5s fastinter 2s rise 3 fall 3
    server node3 10.10.34.166:8081 check cookie node3 inter 5s fastinter 2s rise 3 fall 3' > /etc/haproxy/haproxy.cfg
```

Cấu hình Log cho HAProxy
```
sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/g" /etc/rsyslog.conf
sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/g" /etc/rsyslog.conf
echo '$UDPServerAddress 127.0.0.1' >> /etc/rsyslog.conf

echo 'local2.*    /var/log/haproxy.log' > /etc/rsyslog.d/haproxy.conf

systemctl restart rsyslog
```

Bổ sung cấu hình cho phép kernel có thể binding tới IP VIP
```
echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf
```

Kiểm tra
```
sysctl -p
```
OUPUT
```
net.ipv4.ip_nonlocal_bind = 1
```

Start service HAProxy
```
systemctl restart haproxy
systemctl enable haproxy
```

Truy cập:
```
http://10.10.35.170:8080/stats
```

Kết quả:

<img src="..\images\haproxy\Screenshot_8.png">

Do cấu hình sticky session trên request vì vậy trong một thời điểm chỉ có thể kết nối tới 1 webserver. Để truy cập tới các webserver còn lại, các bạn có thể tạo phiên ẩn danh và truy cập lại.

<img src="..\images\haproxy\Screenshot_9.png">

Khi truy cập trình ẩn danh

<img src="..\images\haproxy\Screenshot_10.png">