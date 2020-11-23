# Hướng dẫn backup restore với Backy2

# Phần 1: Hướng dẫn Backup
## Bước 1: Chuẩn bị dữ liệu demo Ceph
Tại cụm OPS:
- Boot 1 VM (VM trong bài sử dụng Ubuntu20.04)
- VM có IP: 
- VM có volume ID: 

Cài đặt HTTP Apache:
```
apt install apache2 -y
echo '<h1>Chào mừng tới Backy2</h1>' > /var/www/html/index.html
systemctl start apache2
systemctl enable apache2
```

Tạo 1 số file
```
cd /opt/
touch demo{001..100}.txt
```

## Bước 2: Tạo bản backup
> ### Thực hiện trên node `CEPH-AIO`
