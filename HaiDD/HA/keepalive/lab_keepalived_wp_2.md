# Cấu hình Keepalived cho 2 node Wordpress

## Mô hình:

<img src="..\images\keepalive\Screenshot_8.png">

**Phân hoạch IP:**

<img src="..\images\keepalive\Screenshot_9.png">

# Cấu hình
## Trên node SQL
Khai báo repo MariaDB 10.2:
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
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
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
```

Giải nén file `latest.tar.gz`
```
tar xvfz latest.tar.gz
```

Tạo file cấu hình từ file mẫu:
```
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
```

