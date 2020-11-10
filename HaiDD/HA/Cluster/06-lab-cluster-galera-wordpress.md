# Lab cấu hình 1 node wordpress kết nối tới cluster Galera

Cấu hình HAProxy pacemaker cluster galera 3 node theo [tài liệu](./05-lab-haproxy-pacemaker-cluster-galera.md).


# Mô hình

<img src="..\images\cluster\Screenshot_19.png">

# 1. Cấu hình database trên node trong Cluster
> ### Thực hiện trên 1 node `node1`
Tạo database cho wordpress:
```
mysql -u root
```

Tạo Database cho Wordpress. Đặt tên db là: wp_db
```sql
CREATE DATABASE wp_db;
```

Tạo tài khoản riêng để quản lí DB. Tên tài khoản: `wp_user`, Mật khẩu: `nhanhoa2020`
```sql
CREATE USER wp_user;
```

Cấp quyền quản lý databases cho node wordpress:
```sql
GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@10.10.35.168 IDENTIFIED BY 'nhanhoa2020';

GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@'node1' IDENTIFIED BY 'nhanhoa2020';

GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@'node2' IDENTIFIED BY 'nhanhoa2020';

GRANT ALL PRIVILEGES ON wp_db.* TO wp_user@'node2' IDENTIFIED BY 'nhanhoa2020';
```

Sau đó xác thực lại những thay đổi về quyền và thoát giao diện mariadb
```sql
FLUSH PRIVILEGES;

exit
```

# 2. Cài đặt và cấu hình wordpress
> ## Thực hiện trên node wordpress
### 1. Cài Apache
```
yum install httpd -y
```

Start service
```
systemctl start httpd
systemctl enable httpd
```

### 2. Cài đặt PHP
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

### 3. Cài đặt Wordpress
```
cd
wget https://wordpress.org/latest.tar.gz
```

Giải nén file latest.tar.gz
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

Chỉnh sửa file cấu hình wp-config.php. Chỉnh lại tên database, username, password đã đặt ở trên.

- `db_name`: `wp_db`,
- `db_user`: `wp_user`
- `db_password`: `nhanhoa2020`
- `db_host` : `10.10.35.170` -> VIP của cluster galera

```
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

# 3. Kiểm tra
- Truy cập IP của node wordpress tạo bài viết
- Tắt node đang giữ VIP
- Kiểm tra lại trang wordpress vẫn hoạt động bình thường