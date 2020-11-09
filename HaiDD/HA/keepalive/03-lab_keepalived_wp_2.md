# Cấu hình Keepalived cho 2 node Wordpress

## Mô hình:

<img src="..\images\keepalive\Screenshot_8.png">

**Phân hoạch IP:**

<img src="..\images\keepalive\Screenshot_9.png">

# Cấu hình Wordpress
## Trên node SQL
Khai báo repo MariaDB 10.2:
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
```

Cài đặt MariaDB server:
```
yum install mariadb-server -y
```

Kiểm tra phiên bản:
```
mysql -V
mysql  Ver 15.1 Distrib 10.2.34-MariaDB, for Linux (x86_64) using readline 5.1
```

Start service:
```
systemctl enable mariadb.service
systemctl restart mariadb.service
```

Cài đặt khởi đầu cho MariaDB:
```
mysql_secure_installation
```

**Tạo cơ sở dữ liệu và tài khoản cho Wordpress**

Đăng nhập vào tài khoản root của database:
```
mysql -u root -p
```

Tạo Database cho Wordpress. Đặt tên db là: `wp_db`
```sql
CREATE DATABASE wp_db;
```

Tạo tài khoản riêng để quản lí DB. Tên tài khoản: `wp_user`, Mật khẩu: `nhanhoa2020`
```sql
CREATE USER wp_user;
```

Bây giờ ta sẽ cấp quyền quản lí cơ sở dữ liệu cho user mới tạo trên 2 node
```sql
GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@10.10.34.164 IDENTIFIED BY 'nhanhoa2020';

GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@10.10.34.165 IDENTIFIED BY 'nhanhoa2020';
```

Sau đó xác thực lại những thay đổi về quyền và thoát giao diện mariadb
```
FLUSH PRIVILEGES;

exit
```

## Trên node WP1 và WP2
### 1. Cài Apache
```
yum install httpd -y
```

Start service
```
systemctl start httpd
systemctl enable httpd
```

Truy cập IP của 2 node sẽ thấy giao diện của Apache:

<img src="..\images\keepalive\Screenshot_10.png">

### 2. Cài PHP
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
PHP 7.4.11 (cli) (built: Sep 29 2020 10:17:06) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.11, Copyright (c), by Zend Technologies
```

Thêm file info.php
```
echo "<?php phpinfo();?>" > /var/www/html/info.php
```

Restart Apache
```
systemctl restart httpd
```

Vào trình duyệt gõ địa chỉ trên thanh url theo dạng sau:
```
<địa chỉ ip>/info.php
```

<img src="..\images\keepalive\Screenshot_11.png">

### 3. Cài đặt Worrdpress
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

Chỉnh sửa file cấu hình `wp-config.php`. Chỉnh lại tên database, username, password đã đặt ở trên. 
- `db_name`: `wp_db`,
- `db_user`: `wp_user`
- `db_password`: `nhanhoa2020`
- `db_host` : `10.10.34.168` -> IP của node cài đặt databases
```
vi /var/www/html/wp-config.php
```
```
/** The name of the database for WordPress */
define( 'DB_NAME', 'wp_db' );

/** MySQL database username */
define( 'DB_USER', 'wp_user' );

/** MySQL database password */
define( 'DB_PASSWORD', 'nhanhoa2020' );

/** MySQL hostname */
define( 'DB_HOST', '10.10.34.168' );
```

<img src="..\images\keepalive\Screenshot_12.png">

Phân quyền
```
chown -R apache:apache /var/www/html/*
chown -R root:root /var/www/html/wp-config.php
```

Truy cập địa chỉ IP của 1 node WP và và thiết lập cài đặt. Sau khi đặt xong thì trên node WP còn lại ta không cần thiết lập tài khoản nữa. Do 2 node WP dùng chung databases.

# Cấu hình Keepalived
## 1. Cài đặt Keepalived:
Thực hiện trên cả 2 node WP:
```
yum install keepalived -y
```

## 2. Cấu hình Keepalived
Cấu hình cho phép gắn địa chỉ IP ảo lên card mạng và IP Forward. Thực hiện trên cả 2 node Wordpress
```
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

Backups file cấu hình Keepalived trên 2 node:
```
cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
```

Thực hiện cấu hình Keepalived trên từng node:

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


Cấu hình IP của URL trang wordpress: 

<img src="..\images\keepalive\Screenshot_13.png">

# Kiểm tra:
Kiểm tra IP trên node 1: ta sẽ thấy VIP được quản lý bởi node 1:

<img src="..\images\keepalive\Screenshot_15.png">

Truy cập VIP: 10.10.35.170:

<img src="..\images\keepalive\Screenshot_14.png">

Tắt node 10.10.35.164 đi, reload lại trang, ta vẫn thấy trang web vẫn truy cập bình thường.

