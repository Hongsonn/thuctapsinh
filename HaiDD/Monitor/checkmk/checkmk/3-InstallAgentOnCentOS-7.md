# Cài đặt Agent trên CentOS-7

Hướng dẫn cài đặt Agent trên host cần giám sát chạy CentOS-7

<img src="https://i.imgur.com/fOwE3ND.png">

## Chuẩn bị
- [Cài đặt Checkmk server](2-InstallCheckmkOnCentOS7.md)

## Cài đặt
1. Lấy link tải agent theo từng hệ điều hành

    <img src="https://i.imgur.com/VEJt4zP.png">

2. Cài đặt gói wget
    ```
    yum install wget -y 
    ```

3. Dùng gói wget download agent đã chọn ở bước trên
    ```
    wget http://10.10.34.161/monitoring/check_mk/agents/check-mk-agent-1.6.0p12-1.noarch.rpm
    ```

4. Cấp quyền thực thi cho file vừa download về
    ```
    chmod +x check-mk-agent-1.6.0p12-1.noarch.rpm
    ```

5. Cài đặt agent
    ```
    rpm -ivh check-mk-agent-1.6.0p12-1.noarch.rpm
    ```

6. Cài đặt xinetd
    ```
    yum install xinetd -y
    ```

7. Khởi động xinetd
    ```
    systemctl start xinetd
    systemctl enable xinetd
    ```

8. Cài đặt gói net-tools để kiểm tra dễ dàng hơn
    ```
    yum install net-tools -y
    ```

9. Mở port trên client để có thể giao tiếp với check_mk server
    ```
    vi /etc/xinetd.d/check_mk
    ```
    Sửa các thông số sau
    ```
    only_from      = 10.10.34.161
    disable        = 0
    port           = 6556
    ```

10. Kiểm tra port mặc định của check_mk sử dụng để giám sát được chưa
    ```
    netstat -npl | grep 6556

    tcp6       0      0 :::6556                 :::*                    LISTEN      1/systemd
    ```

11. Mở port trên firewall
    ```
    firewall-cmd --add-port=6556/tcp --permanent
    
    firewall-cmd --reload
    ```