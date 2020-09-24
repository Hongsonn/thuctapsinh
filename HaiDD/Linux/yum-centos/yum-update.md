# Ghi chép về yum update

# Update version nhưng giữ nguyên version Kernel
## Phiên bản OS và kernel ban đầu của server CentOS-7
Chuẩn bị 1 máy chạy CentOS phiên bản thấp hơn phiên bản mới nhất hiện tại.

Kiểm tra phiên bản:
```
cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core)
```

Kiểm tra phiên bản Kernel
```
uname -r
3.10.0-957.el7.x86_64
```

## Update bình thường
Khi update bình thường bằng lệnh
```
yum update -y
```

Sau khi thực hiện xong, ta kiểm tra lại phiên bản OS và kernel của máy:

Bây giờ, phiên bản OS của máy đã được update lên phiên bản mới nhất.
```
cat /etc/redhat-release
CentOS Linux release 7.8.2003 (Core)
```

Phiên bản Kernel thì ta có thể thấy vẫn giữ nguyên. Tuy nhiên khi reboot lại máy, ta có thể chọn giữa phiên bản mới vừa update hoặc phiên bản trước đó trong giao diện console khi boot lại máy. Mặc định không chọn thì máy sẽ tự chọn phiên bản mới mà ta vừa update:
```
uname -r
3.10.0-957.el7.x86_64
```

<img src = "..\images\Screenshot_1.png">

<img src = "..\images\Screenshot_2.png">

Phiên bản Kernel sau update:
```
uname -r
3.10.0-1127.19.1.el7.x86_64
```

# Update - giữ nguyên phiên bản Kernel
Phiên bản OS và Kernel ban đầu:
```
CentOS Linux release 7.6.1810 (Core)
3.10.0-957.el7.x86_64
```

Câu lệnh update tất cả ngoại trừ Kernel:
```
yum -y --exclude=kernel\* update
```

Kiểm tra lại phiên bản OS và Kernel:
```
CentOS Linux release 7.8.2003 (Core)
3.10.0-957.el7.x86_64
```

Reboot thì cũng chỉ có 1 phiên bản Kernel cũ

<img src = "..\images\Screenshot_3.png">

### Ngăn việc update Kernel khi update
Để ngăn việc update Kernel vĩnh viễn. Tức là ta vẫn sử dụng update `yum update -y` nhưng sẽ không update Kernel:

Chỉnh sửa file `/etc/yum.conf`.
```
vi /etc/yum.conf
```
Thêm dòng dưới vào sau section `[main]` :
```
exclude=kernel*
```

Bây giờ ta có thể chạy câu lệnh update mà không lo Kernel update lên:
```
yum -y update
```

# Update lên một phiên bản mới hơn chỉ định
Phiên bản OS và Kernel ban đầu:
```
CentOS Linux release 7.6.1810 (Core)
3.10.0-957.el7.x86_64
```

## Thực hiện
Chỉnh sửa file: `/etc/yum.repos.d/CentOS-Base.repo`
```
vi /etc/yum.repos.d/CentOS-Base.repo
```

- Comment các dòng `mirrorlist=...`
- Thêm mới dòng dưới vào các section
    ```
    baseurl=http://vault.centos.org/$releasever/os/$basearch/
    ```

    <img src = "..\images\Screenshot_4.png">

File mẫu:
```conf
[base]
name=CentOS-$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
baseurl=http://vault.centos.org/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
baseurl=http://vault.centos.org/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
baseurl=http://vault.centos.org/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
baseurl=http://vault.centos.org/$releasever/os/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
```

Thực hiện update bằng câu lệnh:
```
yum update -y --releasever=7.7.1908
```
Trong đó:
- `--releasever` : chỉ định phiên bản ta muốn update lên. Tên phiên bản là tên thư mục theo đúng phiên bản theo đường dẫn: http://vault.centos.org/

    <img src = "..\images\Screenshot_5.png">

### **Chú ý:** Ta chỉ có thể update lên phiên bản cập mới hơn trong. Ví dụ: Đang là Centos 7.7.1908 thì ta chỉ có thể udpate lên 1 phiên bản Centos 7 mới hơn. Không thể xuống phiên bản cập nhật thấp hơn hay là lên Centos 8

## Chỉ định chỉ sử dụng 1 phiên bản cập nhật
Thay biến `$releasever` tại phần `baseurl` trong file `/etc/yum.repos.d/CentOS-Base.repo` thành phiên bản chỉ định muốn sử dụng:
```
vi /etc/yum.repos.d/CentOS-Base.repo
```

<img src = "..\images\Screenshot_6.png">

Khi đó, việc thực hiện update, ta không cần chỉ định version nữa. Nó sẽ tự động dùng phiên bản ta chỉ định trong file trên
```

```