# Cài đặt Pritunl VPN trên Cloud365

**Docs**: https://docs.pritunl.com/docs

## Giới thiệu
Pritunl là phần mềm mã nguồn mở được sử dụng để ảo hóa VPN server trên hạ tầng các trung tâm dữ liệu. Đồng thời cung cấp phương thức truy cập từ xa đơn giản trong vòng vài phút

## Mô hình

<img src="https://i.imgur.com/b0lcoe9.png">

<img src="https://i.imgur.com/bmT3Ibs.png">

## Mục tiêu
Khi sử dụng Cloud trên hệ thống Cloud365, người dùng hoàn toàn có thể setup hệ thống LAN private giữa các VM với nhau và đi ra ngoài theo 1 IP public duy nhất. Khi đó, người dùng có thể dùng Pritunl Server làm VPN Server để các Client connect vào, sau đó kết nối tới các máy ảo thông qua đường Private LAN.

**Mục tiêu theo mô hình**: Từ Client ping được tới VM

## Cấu hình
### 1. Cài đặt server
```
sudo tee /etc/yum.repos.d/mongodb-org-4.2.repo << EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

sudo tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/centos/7/
gpgcheck=1
enabled=1
EOF

sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp
sudo yum -y install pritunl mongodb-org
sudo systemctl start mongod pritunl
sudo systemctl enable mongod pritunl
```

## 2. Cấu hình
### 1. Cấu hình mở thêm open file limit (Tùy chọn)
    ```
    sudo sh -c 'echo "* hard nofile 64000" >> /etc/security/limits.conf'
    sudo sh -c 'echo "* soft nofile 64000" >> /etc/security/limits.conf'
    sudo sh -c 'echo "root hard nofile 64000" >> /etc/security/limits.conf'
    sudo sh -c 'echo "root soft nofile 64000" >> /etc/security/limits.conf'
    ```

### 2. Cấu hình hệ thống
**Cấu hình truy cập**
- Sinh setup-keys:
    ```
    pritunl setup-key
    ```

- Truy cập vào đường dẫn: `<IP_pub_printnl_server>`

- Nhập setup-key vừa sinh. MongoDB URI để mặc định

    <img src="https://i.imgur.com/PrWbx0R.png">

- Click nút **Save**

- Chạy lệnh dưới server để lấy default password và user:
    ```
    pritunl default-password
    ```

    <img src="https://i.imgur.com/eCvcn8t.png">

- Nhập username và password trên giao diện web và click **Sign in**

    <img src="https://i.imgur.com/Qb482Qn.png">

- Sau khi đăng nhập, hệ thống sẽ yêu cầu đổi mật khẩu:

    <img src="https://i.imgur.com/LFFTpN2.png">

### 3. Cấu hình
1. Chọn tab **Users** -> **Add Organization**

    <img src="https://i.imgur.com/qMogfWq.png">

2. Đặt tên Organization

    <img src="https://i.imgur.com/JSSmb92.png">

3. Sau khi tạo Organization, ta tạo User bằng cách click nút Add User

    <img src="https://i.imgur.com/JSXFGfB.png">

4. Nhập tên user1 và mã PIN sau đó nhấn nút **Add**

    <img src="https://i.imgur.com/f061DDi.png">

5. Chọn tab **Server** -> **Add server**

    <img src="https://i.imgur.com/QGuRMVd.png">

6. Nhập thông tin server
    - Tên Server
    - Port và giao thức truy cập
    - Virtual network: đây là dải mạng cấp cho Client connect (TUN)

    <img src="https://i.imgur.com/8LK0n6W.png">

7. Sau khi add thành công, chọn phần **Add Route** để add thêm route về dải Private Network:

    <img src="https://i.imgur.com/KMFTlRy.png">

8. Nhập dải mạng private -> **Attach**

    <img src="https://i.imgur.com/wElYdVj.png">

9. Sau khi add xong Server, tiếp tục chọn mục **Attach Organization**

    <img src="https://i.imgur.com/mz0OHJi.png">

10. Chọn Organization và Server

    <img src="https://i.imgur.com/4IT4kQ5.png">

11. Click **Start Server**

    <img src="https://i.imgur.com/wfQQIxb.png">

## 3.1. Cấu hình Client trên Windown
Link tải các gói client: https://github.com/pritunl/pritunl-client/releases

1. Tại mục User -> Chọn biểu tượng như hình

    <img src="https://i.imgur.com/Xuwe6QB.png">

2. Truy cập đường dẫn tại mục `Temporary url to view profile links, expires after 24 hours`

    <img src="https://i.imgur.com/vFMB1mZ.png">

3. Trên tab mới mở ra, ta chọn **Download Client**

    <img src="https://i.imgur.com/YpmBcFR.png">

4. Tại đây, ta có thể chọn hệ điều hành của Client để thiết lập. Trong bài này, ta dùng Windown nên sẽ tải file cài đặt về **Download installer**. Copy Profile URI Link

    <img src="https://i.imgur.com/MbQdoKW.png">

5. Sau khi cài đặt, và khởi động, ta chọn **Import Profile URI**

    <img src="https://i.imgur.com/5r9APLe.png">

6. DÁn link vào ô đường dẫn vào chọn **Import**

    <img src="https://i.imgur.com/Kftxg3c.png">

7. Chọn biểu tượng như hình
    
    <img src= "https://i.imgur.com/RUZWOT8.png">

8. Chọn **Connect**

    <img src="https://i.imgur.com/bnr2Ayy.png">

9. Nhập mã PIN và chọn **OK**

    <img src="https://i.imgur.com/5tL2xvY.png">

10. Đợi vài giây sẽ thấy Client Address là IP dải ta tạo trên Pritunl Server là thành công

    <img src="https://i.imgur.com/iJjBPM2.png">

11. Ping thử tới VM trong dải mảng Private OK.

    <img src="https://i.imgur.com/rsyuEzb.png">

## 3.2. Cấu hình Client trên Linux
Cài đặt theo tùy OS tại đây: https://client.pritunl.com/#install

CentOS-7
```
sudo tee -a /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Stable Repository
baseurl=https://repo.pritunl.com/stable/yum/centos/7/
gpgcheck=1
enabled=1
EOF

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A

gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp

sudo yum install pritunl-client-gtk
```

Sau khi cài đặt xong, ta tải file profile về máy.

Trên Linux server thì nên bật Byobu:
- Chạy lệnh sau:
    ```
    openvpn --config <đường_dẫn_file_profile>
    ```

- Nhập user/password

- Ping thử vào dải private của VPN OK.