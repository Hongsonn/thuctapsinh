# Triển khai HAProxy Pacemaker cho Cluster 3 node chạy Wordpress trên CentOS-7

## Phân hoạch

<img src="..\images\cluster\Screenshot_16.png">

## Mô hình
Mô hình triển khai:

<img src="..\images\cluster\Screenshot_15.png">


# Cài đặt wordpress
> ## Cài đặt wordpress trên cả 3 node trong Cluster

## 1. Cài đặt Galera

## 2. Cài đặt Apache
```
yum install httpd -y
```

Start service
```
systemctl start httpd
systemctl enable httpd
```

## 3. Cài đặt PHP
Cài đặt PHP 7.4
```
yum install -y epel-release yum-utils
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php74
yum install -y php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysqlnd php-xml
```

Kiểm tra lại phiên bản php
```
php -v
PHP 7.4.12 (cli) (built: Oct 27 2020 15:01:52) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.12, Copyright (c), by Zend Technologies
```

Restart Apache
```
systemctl restart httpd
```

## 4. Cài đặt Wordpress
```
cd
wget https://wordpress.org/latest.tar.gz
```

Giải nén file `latest.tar.gz`
```
tar xvfz latest.tar.gz
```

Copy các file vừa giải nén vào thư mục `/var/www/html/`:
```
cp -Rvf /root/wordpress/* /var/www/html
```

Tạo file cấu hình từ file mẫu:
```
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
```

Cấu hình các thông tin của cơ sở dữ liệu trong file: `/var/www/html/wp-config.php`

Chỉnh sửa file cấu hình wp-config.php. Chỉnh lại tên `database`, `username`, `password` đã đặt ở trên.
```
db_name: wp_db,
db_user: wp_user
db_password: nhanhoa2020
db_host : 10.10.35.170 -> VIP của cluster galera
define( 'DB_NAME', 'wp_db' );

/** MySQL database username */
define( 'DB_USER', 'wp_user' );

/** MySQL database password */
define( 'DB_PASSWORD', 'nhanhoa2020' );

/** MySQL hostname */
define( 'DB_HOST', '10.10.35.170' );
```

Phân quyền
```
chown -R apache:apache /var/www/html/*
chown -R root:root /var/www/html/wp-config.php
```

# Cấu hình HAProxy
## Cấu hình Listen port cho dịch vụ HTTP theo dải internal
Chỉnh sửa file `/etc/httpd/conf/httpd.conf`
```
vi /etc/httpd/conf/httpd.conf
```

Node1:
```
Listen 10.10.34.164:80
```

Node2:
```
Listen 10.10.34.165:80
```

Node3:
```
Listen 10.10.34.164:80
```

## Thêm cấu hình HAProxy
> ### Thực hiện trên cả 3 node
Thêm đoạn cấu hình sau vào cuối file `/etc/haproxy/haproxy.cfg`
```
vi /etc/haproxy/haproxy.cfg
```

Nội dung
```
listen web-wp
    bind 10.10.35.170:80
    balance  source
    cookie SERVERID insert indirect nocache
    mode  http
    option  httpchk
    option  httpclose
    option  httplog
    option  forwardfor
    server node1 10.10.34.164:80 check cookie node1 inter 5s fastinter 2s rise 3 fall 3
    server node2 10.10.34.165:80 check cookie node2 inter 5s fastinter 2s rise 3 fall 3
    server node3 10.10.34.166:80 check cookie node3 inter 5s fastinter 2s rise 3 fall 3
```

Restart service haproxy trên node đang active:
```
systemctl restart haproxy
```

Truy cập VIP :
```
http://10.10.35.170:8080/stats
```

<img src="..\images\cluster\Screenshot_21.png">

Ta có thể truy cập trang wordpress thông qua VIP, và IP của các node dải Internal
```
# IP VIP
http://10.10.35.170/

# IP dải Internal
http://10.10.34.164/
http://10.10.34.165/
http://10.10.34.166/
```

<img src="..\images\cluster\Screenshot_22.png">

# Kiểm tra
Thực hiện kiểm tra node đang active:
```
pcs status

Cluster name: ha_cluster
Stack: corosync
Current DC: node3 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Wed Nov 11 11:50:02 2020
Last change: Wed Nov 11 10:56:49 2020 by hacluster via crmd on node1

3 nodes configured
2 resources configured

Online: [ node1 node2 node3 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node1
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Ta thấy node đang nhận VIP là `node1`

Tiến hành tắt `node1`

Kiểm tra lại trên trang stat **HAProxy** và truy cập trang web:

<img src="..\images\cluster\Screenshot_23.png">

-> `node1` đã báo `DOWN`

Trang web vẫn truy cập bình thường:

<img src="..\images\cluster\Screenshot_22.png">