# Reset password bằng Single Mode trên Console

Truy cập màn hình Console của VM

## 1. Ubuntu 18.04
**Bước 1:** Sau khi truy cập màn hình Console, tiến hành restart VM (tùy vào hệ thống sử dụng có những cách restart khác nhau)

**Bước 2:** Truy cập hệ thống **Grub boot menu**. Thường thì hệ thống sẽ tự động hiển thị Grub boot menu. Nếu không thấy, hãy thử khởi động lại VM và nhấn phím Shift vài lần.

<img src="https://i.imgur.com/nWUyCr7.png">

**Bước 3:** Trên Grub boot menu chọn Kernel đang chạy và bấm phím **E** để edit

<img src="https://i.imgur.com/MQjcmmm.png">

**Bước 4:** Di chuyển đến dòng `linux /boot/vmlinuz..`

<img src="https://i.imgur.com/kgjpzwV.png">

**Bước 5:** Sửa các tham số `ro net.ifname=0 biosdevname=0 ...` thành `rw init=/bin/bash`

<img src="https://i.imgur.com/scueU5b.png">

**Bước 6:** Nhấn tổ hợp phím **Ctrl + X** hoặc nhấn phím **F10** để vào **Single Mode**. Sau đó thực hiện các lệnh sau:
```
# Đổi mật khẩu
passwd root
 
# Đồng bộ dữ liệu
sync
 
# Khởi động lại hệ thống
reboot -f
```

<img src="https://i.imgur.com/8Qx0pc2.png">

**Bước 7:** Đăng nhập bằng password mới và kiểm tra


## 2. Ubuntu 20.04
**Bước 1:** Sau khi truy cập màn hình Console, tiến hành restart VM (tùy vào hệ thống sử dụng có những cách restart khác nhau)

**Bước 2:** Truy cập hệ thống **Grub boot menu**. Thường thì hệ thống sẽ tự động hiển thị Grub boot menu. Nếu không thấy, hãy thử khởi động lại VM và nhấn phím Shift vài lần.

<img src="https://i.imgur.com/f8FaLcE.png">

**Bước 3:** Trên Grub boot menu chọn Kernel đang chạy và bấm phím **E** để edit

<img src="https://i.imgur.com/4rNxC4a.png">

**Bước 4:** Di chuyển đến dòng `linux /boot/vmlinuz..`

<img src="https://i.imgur.com/dHxvDOy.png">

**Bước 5:** Sửa phần tham số `ro ...` thành `rw init=/bin/bash`

<img src="https://i.imgur.com/cBCZp2K.png">

**Bước 6:** Nhấn tổ hợp phím **Ctrl + X** hoặc nhấn phím **F10** để vào **Single Mode**. Sau đó thực hiện các lệnh sau:
```
# Đổi mật khẩu
passwd root
 
# Đồng bộ dữ liệu
sync
 
# Khởi động lại hệ thống
reboot -f
```

<img src="https://i.imgur.com/eNiQFFa.png">

**Bước 7:** Đăng nhập bằng password mới và kiểm tra