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

> ### Snapshot lại bản ban đầu
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

> ### Snapshot
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
