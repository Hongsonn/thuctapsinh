# Hướng dẫn đóng image Ubuntu 20.04 với cloud-init và QEMU Guest Agent (không dùng LVM)

## Chú ý:
- Hướng dẫn này dành cho các image không sử dụng LVM
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- OS cài đặt KVM là Ubuntu 20.04
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

# Bước 1: Tạo máy ảo bằng virt-manager
## 1. Trên Host KVM
### 1.1. Tạo file disk máy ảo
- Tạo file disk máy ảo:
    ```
    qemu-img create -f qcow2 /var/lib/libvirt/images/haidd-u20.qcow2 10G
    ```

- Chạy virt-manager để tạo VM
    ```
    virt-manager
    ```

- Chọn Import existing disk image:

    <img src="..\images\Screenshot_1.png">

- Chọn OS Type: Linux, Version: Ubuntu 18.04, Chọn đường dẫn tới file disk vừa tạo:

    <img src="..\images\Screenshot_2.png">

    <img src="..\images\Screenshot_3.png">

- Chọn dung lượng RAM và CPU, ta đặt 1G RAM và 1 CPU
    <img src="..\images\Screenshot_4.png">

- Đặt tên VM và tích vào dòng `Customize configuration before install`. Sau đó chọn **Finish**
    <img src="..\images\Screenshot_5.png">

- Chỉnh mode card mạng thành virtio và chọn dải có DHCP cấp IP:
    <img src="..\images\Screenshot_6.png">

- Mount file ISO bằng cách thêm CDROM. Chọn **Add Hardware** => **Storage** => **Manage**, sau đó chọn file iso Ubuntu Server 20.04. Chú ý chọn Device type là **CDROM device**.

    <img src="..\images\Screenshot_7.png">

- Chỉnh sửa Boot Option, chọn boot từ CDROM đầu tiên để cài đặt từ file ISO.

    <img src="..\images\Screenshot_8.png">

- Sau đó chọn **Begin Installation** để bắt đầu cài đặt

    <img src="..\images\Screenshot_9.png">

###  1.2. Cài đặt OS
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
    <img src="..\images\Screenshot_24.png">

- Remove CD ROM
    <img src="..\images\Screenshot_26.png">

### 1.3. Tắt máy ảo, xử lý trên KVM host
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

**Chú ý:** Nếu đã tồn tại channel đổi port channel này về `port='2'` và add channel bình thường
    
<img src="..\images\Screenshot_25.png">

## 2. Thực hiện trên máy ảo cài đặt các dịch vụ cần thiết
### 2.1. Setup môi trường
Bật máy ảo lên, truy cập vào máy ảo. Lưu ý với lần đầu boot, bạn phải sử dụng tài khoản `ubuntu` tạo trong quá trình cài os, chuyển đổi nó sang tài khoản root để sử dụng.

Cấu hình cho phép ssh bằng user root và xóa user ubuntu chỉnh `/etc/ssh/sshd_config`
```
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'g /etc/ssh/sshd_config

service sshd restart
```

Đặt passwd cho root
```
sudo su 
# Đặt passwd cho root user
passwd
Enter new UNIX password: <root_passwd>
Retype new UNIX password: <root_passwd>
```

Restart sshd
```
sudo service ssh restart
```

Disable firewalld
```
systemctl disable ufw
systemctl stop ufw
systemctl status ufw
```

Logout ra khỏi VM:
```
logout
```

Login lại bằng user `root` và xóa user `ubuntu`:
```
userdel ubuntu
rm -rf /home/ubuntu
```

Đổi timezone về **Asia/Ho_Chi_Minh**
```
timedatectl set-timezone Asia/Ho_Chi_Minh
```

Bổ sung env locale
```
echo "export LC_ALL=C" >>  ~/.bashrc
```

Disable ipv6
```
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
```
- Output: 1: OK, 0: Not OK

Update
```
apt-get update -y 
apt-get upgrade -y 
apt-get dist-upgrade -y
apt-get autoremove 
```

Kiểm tra và xóa swap:
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
    Mem:            981         128         244           1         608         694
    Swap:             0           0           0
    ```

Cấu hình để instance báo log ra console và đổi name Card mạng về eth* thay vì ens, eno
```
sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 console=tty1 console=ttyS0"|g' /etc/default/grub

update-grub
```

Cấu hình network sử dụng ifupdown thay vì netplan

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

> ### Shutdown và snapshot lại VM

## 3. Cài đặt các agent cho VM
Bật lại VM

Để máy ảo khi boot sẽ tự giãn phân vùng theo dung lượng mới, ta cài các gói sau:
```
apt-get update -y
apt-get install -y cloud-init
apt-get install cloud-utils cloud-initramfs-growroot -y
```

Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:
```
apt-get install netplug -y

wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/netplug_ubuntu -O netplug

mv netplug /etc/netplug/netplug

chmod +x /etc/netplug/netplug
```

Cấu hình user default.
```
sed -i 's/name: ubuntu/name: root/g' /etc/cloud/cloud.cfg
```


Disable default config route
```
sed -i 's|link-local 169.254.0.0|#link-local 169.254.0.0|g' /etc/networks
```

Cài đặt `qemu-guest-agent`

**Chú ý:** `qemu-guest-agent` là một daemon chạy trong máy ảo, giúp quản lý và hỗ trợ máy ảo khi cần (có thể cân nhắc việc cài thành phần này lên máy ảo)

- Để có thể thay đổi password máy ảo bằng nova-set password thì phiên bản `qemu-guest-agent` phải `>= 2.5.0`

    ```
    apt-get install software-properties-common -y
    apt-get update -y
    apt-get install qemu-guest-agent -y
    service qemu-guest-agent start
    ```

- Kiểm tra phiên bản qemu-ga bằng lệnh:
    ```
    qemu-ga --version
    service qemu-guest-agent status
    ```

Cấu hình datasource

- Bỏ chọn mục NoCloud bằng cách dùng dấu SPACE, sau đó ấn ENTER
    ```
    dpkg-reconfigure cloud-init
    ```

Clean cấu hình và restart service : Việc restart có thể mất 2-3 phút hoặc hơn
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

Shutdown máy:
```
init 0
```

## 4. Thực hiện trên host KVM
Sử dụng lệnh virt-sysprep để xóa toàn bộ thông tin máy ảo:
```
virt-sysprep -d ubuntu20
```

Dùng lệnh sau để tối ưu kích thước image:
```
virt-sparsify --compress --convert qcow2 /var/lib/libvirt/images/haidd-u20.qcow2 ubuntu20
```

**Lưu ý:** đường dẫn và tên image


## 5. Upload image lên sử dụng
Chú ý: 
- Thêm metadata `hw_qemu_guest_agent=yes`