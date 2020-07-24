# Hướng dẫn đóng image Ubuntu 20.04 với cloud-init và QEMU Guest Agent (không dùng LVM)

## Chú ý:
- Hướng dẫn này dành cho các image không sử dụng LVM
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- OS cài đặt KVM là Ubuntu 20.04
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

# Bước 1: Tạo máy ảo bằng WebvirtCloud
## 1. Trên Webvirt Cloud
### 1.1. Tạo file disk máy ảo
<img src="..\images\Screenshot_27.png">

### 1.2. Tạo máy ảo
- Create Instance: với 1 vCPU, 1 GB RAM. Nhớ chọn dải mạng có DHCP

    <img src="..\images\Screenshot_28.png">

> ### Snapshot VM
<img src="..\images\Screenshot_29.png">

- Sang tab Setting -> Disk -> Mount file ISO Ubuntu 20.04

    <img src="..\images\Screenshot_30.png">

- Về mục Boot (Setting), chọn boot từ file iso. Nhớ thứ tự boot phải từ file ISO rồi đến disk

    <img src="..\images\Screenshot_31.png">

- Chọn tab Power -> Power on

    <img src="..\images\Screenshot_32.png">

- Chuyển tab Access -> Console

    <img src="..\images\Screenshot_33.png">

### 1.3. Cài đặt OS
- Chọn ngôn ngữ `English`
    <img src="..\images\Screenshot_10.png">

- Chọn `Continue without updating`
    <img src="..\images\Screenshot_11.png">

- Chọn kiểu bàn phím:
    <img src="..\images\Screenshot_12.png">

- Chọn card mạng sử dụng DHCP:
    <img src="..\images\Screenshot_13.png">

- Chọn không dùng proxy
    <img src="..\images\Screenshot_14.png">

- Để mirror Ubuntu mặc định
    <img src="..\images\Screenshot_15.png">

- Tích chọn `Use an entire disk`
    <img src="..\images\Screenshot_16.png">

- Chỉnh sửa cấu hình ổ cứng (nếu cần)
    <img src="..\images\Screenshot_17.png">

- Chọn `Continue`
    <img src="..\images\Screenshot_18.png">

- Điền các thông tin máy ảo, user mặc định đặt là `ubuntu`
    <img src="..\images\Screenshot_19.png">

- Tích chọn `Install OpenSSH server` bằng cách dùng dấu Space
    <img src="..\images\Screenshot_20.png">

- Không chọn bất kỳ option nào
    <img src="..\images\Screenshot_21.png">

- Đợi cài đặt
    <img src="..\images\Screenshot_22.png">

- Sau khi cài đặt xong, ta chọn reboot
    <img src="..\images\Screenshot_23.png">

- Shutdown máy để remove CDROM
    <img src="..\images\Screenshot_36.png">

- Remove CD ROM: Setting -> Disk -> Umount
    <img src="..\images\Screenshot_35.png">

> ## Snapshot VM
<img src="..\images\Screenshot_36.png">


- Chỉnh sửa file `.xml` của máy ảo, bổ sung thêm channel trong (để máy host giao tiếp với máy ảo sử dụng `qemu-guest-agent`), sau đó save lại:
    ```
    virsh edit ubuntu20
    ```

    - với `ubuntu20` là tên máy ảo

    ```xml
    ...
    <devices>
    <channel type='unix'>
        <target type='virtio' name='org.qemu.guest_agent.0'/>
        <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    </devices>
    ...
    ```

    <img src="..\images\Screenshot_38.png">

**Chú ý:** Nếu đã tồn tại channel đổi port channel này về `port='2'` và add channel bình thường
    
<img src="..\images\Screenshot_25.png">


## 2. Thực hiện trên máy ảo
Bật máy ảo, truy cập bằng tài user `ubuntu` và bắt đầu thực hiện cài đặt môi trường.

### Đặt pass cho `root` và xóa user `ubuntu`
- Đặt mật khẩu cho `root`
    ```
    sudo su

    # Đặt mật khẩu cho root
    passwd
    Enter new UNIX password: <root_passwd>
    Retype new UNIX password: <root_passwd>
    ```

- Cấu hình cho phép ssh bằng user `root`  `/etc/ssh/sshd_config`
    ```
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'g /etc/ssh/sshd_config

    service sshd restart
    ```

- Disable firewalld
    ```
    systemctl disable ufw
    systemctl stop ufw
    systemctl status ufw
    ```

- Logout ra khỏi VM:
    ```
    logout
    ```

- Login lại bằng user `root`

- Xóa user `ubuntu`
    ```
    userdel ubuntu
    rm -rf /home/ubuntu
    ```

- Đổi timezone về Asia/Ho_Chi_Minh
    ```
    timedatectl set-timezone Asia/Ho_Chi_Minh
    ```

- Bổ sung env locale
    ```
    echo "export LC_ALL=C" >>  ~/.bashrc
    ```

- Disable ipv6
    ```
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf 
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf 
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p

    cat /proc/sys/net/ipv6/conf/all/disable_ipv6
    ```
    **OUTPUT**: 1: OK, 0: Not OK

- Kiểm tra và xóa swap:

    - Kiểm tra swap:
        ```
        cat /proc/swaps
        Filename                                Type            Size    Used    Priority
        /swap.img                               file            2009084 780     -2
        ```
    
    - Xóa swap
        ```
        swapoff -a
        rm -rf /swap.img
        ```
    
    - Xóa cấu hình swap file trong file /etc/fstab
        ```
        sed -Ei '/swap.img/d' /etc/fstab
        ```

    - Kiểm tra lại:
        ```
        free -m
                      total        used        free      shared  buff/cache   available
        Mem:            981         134         223           0         623         690
        Swap:             0           0           0
        ```

### Cài đặt một số gói cần thiết
- Update
    ```
    apt-get update -y 
    apt-get upgrade -y 
    apt-get dist-upgrade -y
    apt-get autoremove 
    ```

- Cài đặt các gói 
    ```
    apt -y install linux-virtual pollinate
    ```

- Cấu hình file grub để instance báo log ra console và đổi name Card mạng về eth* thay vì ens, eno
    ```
    sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="maybe-ubiquity"|GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0"|g' /etc/default/grub

    sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 console=tty1 console=ttyS0"|g' /etc/default/grub

    update-grub
    ```

### Cấu hình network sử dụng ifupdown thay vì netplan

- Disable netplan
    ```
    apt-get --purge remove netplan.io -y
    rm -rf /usr/share/netplan
    rm -rf /etc/netplan

    apt-get update
    apt-get install -y ifupdown
    ```

- Tạo file interface
    ```
    cat << EOF > /etc/network/interfaces
    auto lo
    iface lo inet loopback
    auto eth0
    iface eth0 inet dhcp
    EOF
    ```

### Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:
```
apt-get install netplug -y

wget https://raw.githubusercontent.com/danghai1996/thuctapsinh/master/HaiDD/CreateImage/scripts/netplug_ubuntu -O netplug

mv netplug /etc/netplug/netplug

chmod +x /etc/netplug/netplug
```

### Cài đặt cloud-init và cấu hình user default
```
apt-get install -y cloud-init

sed -i 's/name: ubuntu/name: root/g' /etc/cloud/cloud.cfg
```

### Disable default config route
```
sed -i 's|link-local 169.254.0.0|#link-local 169.254.0.0|g' /etc/networks
```

### Cài đặt qemu-agent
**Chú ý:** qemu-guest-agent là một daemon chạy trong máy ảo, giúp quản lý và hỗ trợ máy ảo khi cần (có thể cân nhắc việc cài thành phần này lên máy ảo)

Để có thể thay đổi password máy ảo bằng nova-set password thì phiên bản qemu-guest-agent phải >= 2.5.0
```
apt-get install software-properties-common -y
apt-get update -y
apt-get install qemu-guest-agent -y
service qemu-guest-agent start
```

Kiểm tra phiên bản qemu-ga bằng lệnh:
```
qemu-ga --version
service qemu-guest-agent status
```

### Cấu hình datasource
Bỏ chọn mục NoCloud bằng cách dùng dấu SPACE, sau đó ấn ENTER
```
dpkg-reconfigure cloud-init
```

<img src="..\images\Screenshot_39.png">

### Clean cấu hình và restart service
**Lưu ý:** Việc restart có thể mất 2-3 phút hoặc hơn
```
cloud-init clean
systemctl restart cloud-init
systemctl enable cloud-init
systemctl status cloud-init
```

Clear toàn bộ history
```
apt-get clean all
rm -f /var/log/wtmp /var/log/btmp
history -c
```

### Tắt máy
Tắt máy trên WebvirtCloud:

<img src="..\images\Screenshot_40.png">


> ## Snapshot VM
<img src="..\images\Screenshot_41.png">


# Bước 2: Thực hiện trên host KVM
Sử dụng lệnh `virt-sysprep` để xóa toàn bộ thông tin máy ảo:
```
virt-sysprep -d OPS_Ubuntu_2004
```

Dùng lệnh sau để tối ưu kích thước image:
```
virt-sparsify --compress --convert qcow2 /var/lib/libvirt/images/OPS_Ubuntu_2004.qcow2 OPS_Ubuntu_2004
```

**Lưu ý:** đường dẫn và tên image

# Bước 3: Upload image lên OPS
Upload image lên sử dụng

<img src="..\images\Screenshot_42.png">

**Chú ý:**
- Thêm metadata `hw_qemu_guest_agent=yes`

<img src="..\images\Screenshot_43.png">

# Bước 4: Tạo VM từ image
Tạo VM và thêm config:
```
#cloud-config
password: hai1996
chpasswd: {expire: False}
ssh_pwauth: True
```

<img src="..\images\Screenshot_44.png">

**Lưu ý:** Sử dụng mật khẩu tùy chọn