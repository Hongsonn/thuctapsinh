# Cài đặt Guacamelo centos 7 - Webterminal

## Disable IPv6

## 1. Cài đặt các gói và thư viện cần thiết
```
yum -y install epel-release wget
```
```
yum -y install cairo-devel freerdp-devel gcc java-1.8.0-openjdk.x86_64 libguac libguac-client-rdp libguac-client-ssh libguac-client-vnc libjpeg-turbo-devel libpng-devel libssh2-devel libtelnet-devel libvncserver-devel libvorbis-devel libwebp-devel openssl-devel pango-devel pulseaudio-libs-devel terminus-fonts tomcat tomcat-admin-webapps tomcat-webapps uuid-devel libavcodec-dev libwebsockets libwebsockets-devel
```
```
yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y

yum install ffmpeg ffmpeg-devel -y
```

## 2. Cài đặt guacamole
```
mkdir ~/guacamole && cd ~

wget http://mirror.math.princeton.edu/pub/apache/guacamole/1.1.0/source/guacamole-server-1.1.0.tar.gz
```

```
tar -xzf guacamole-server-1.1.0.tar.gz && cd guacamole-server-1.1.0

./configure --with-init-dir=/etc/init.d

make

make install

ldconfig
```

## 3. Cài đặt guacamole WEB interface
```
mkdir -p /var/lib/guacamole && cd /var/lib/guacamole/
wget http://apache.mirrors.ionfish.org/guacamole/1.1.0/binary/guacamole-1.1.0.war -O guacamole.war
```
```
ln -s /var/lib/guacamole/guacamole.war /var/lib/tomcat/webapps/
rm -rf /usr/lib64/freerdp/guacdr.so
ln -s /usr/local/lib/freerdp/guacdr.so /usr/lib64/freerdp2/
```

## 4. Cài đặt Mariadb làm database cho guacamole
```
yum -y install mariadb mariadb-server
```

## 5. Cài đặt thư viện jdbc và mysql-connector hỗ trợ java thao tác với mariadb
```
mkdir -p ~/guacamole/sqlauth && cd ~/guacamole/sqlauth
wget http://apache.mirrors.ionfish.org/guacamole/1.1.0/binary/guacamole-auth-jdbc-1.1.0.tar.gz
tar -zxf guacamole-auth-jdbc-1.1.0.tar.gz
```
```
wget http://dev.mysql.com/get/Downloads/Connector/j/mysql-connector-java-5.1.38.tar.gz
tar -zxf mysql-connector-java-5.1.38.tar.gz
```
```
mkdir -p /usr/share/tomcat/.guacamole/{extensions,lib}
mv guacamole-auth-jdbc-1.1.0/mysql/guacamole-auth-jdbc-mysql-1.1.0.jar /usr/share/tomcat/.guacamole/extensions/
mv mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar /usr/share/tomcat/.guacamole/lib/
```

## 6. Tạo User và DB cho guacamole
```
systemctl restart mariadb.service
systemctl enable mariadb
```
```
mysql -u root -p
```
```
create database guacdb;
create user 'guacuser'@'localhost' identified by 'Nhanhoa123123';
grant select,insert,update,delete on guacdb.* to 'guacuser'@'localhost';
flush privileges;
quit;
```

## 7. Đồng bộ cấu trúc bảng mẫu
```
cd ~/guacamole/sqlauth/guacamole-auth-jdbc-1.1.0/mysql/schema/
cat ./*.sql | mysql -u root -p guacdb
```

## 8. Tạo file cấu hình cho guacamole
```
mkdir -p /etc/guacamole/ && vi /etc/guacamole/guacamole.properties
```

Thêm nội dung sau
```
# MySQL properties
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacdb
mysql-username: guacuser
mysql-password: Nhanhoa123123

# Additional settings
mysql-default-max-connections-per-user: 0
mysql-default-max-group-connections-per-user: 0
```

## 9. Cleanup
```
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/
cd ~ && rm -rf guacamole*
systemctl enable tomcat.service && systemctl enable mariadb.service && chkconfig guacd on
reboot
```

## 10. Truy cập guacamole web
```
http://<địa_chỉ_IP>:8080/guacamole

Tài khoản/mật khẩu:
guacadmin / guacadmin
```