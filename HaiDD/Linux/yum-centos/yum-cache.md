# Ghi chép về yum cache

Mặc định thì `yum` sẽ xóa những file cài đặt sau khi thực hiện xong. Điều đó giúp cho giảm dung lượng lưu trữ của disk.

Tuy nhiên, ta có thể sử dụng `caching` để các gói tải về vẫn ở trong thư mục bộ nhớ đệm. Bằng cách sử dụng dữ liệu cache, ta có thể thực hiện một số hoạt động nhất định mà không cần kết nối mạng, hoặc có thể sao chép để sử dụng lại chúng ở nơi khác.


Yum lưu trữ các tệp tạm thời tại thư mục `/var/cache/yum/$basearch/$releasever/`.

- `$basearch` : là biến đại diện cho kiến base architecture
- `$releasever` : là phiên bản của  Red Hat Enterprise Linux

Mỗi kho lưu trữ được lưu tại 1 thư mục.

Ví dụ: Thư mục `/var/cache/yum/$basearch/$releasever/development/packages/` chưa các gói được tải xuống từ development repository.

## Enable Cache
Để giữ lại các gói cài đặt sau khi cài đặt xong, Chỉnh sửa giá trị của `keepcache` thành `1` trong section `[main]` trong file `/etc/yum.conf`
```
[main]
...
cachedir=/root/yum/cache
keepcache=1
...
```

Ngoài ra, bạn có thể thay đổi thư mục lưu trữ file cache tại option `cachedir`

<img src = "..\images\Screenshot_7.png">

Ta sẽ tạo 1 thư mục bên ngoài để tiện theo dõi:
```
cachedir=/root/yum/cache
```

Khi bạn đã bật cache, mọi thao tác `yum` có thể tải xuống các package từ các repo đã định sẵn trong cấu hình.

Để tải xuống và sử dụng tất cả metadata cho các repo hiện được kích hoạt, hãy sử dụng lệnh:
```
yum makecache
```

Điều này sẽ hữu ích khi bạn muốn đảm bảo rằng bộ nhớ cache được update đầy đủ với metadata.

Sau khi chạy lệnh, kiểm tra trong thư mục lưu cache, ta sẽ thấy:

<img src = "..\images\Screenshot_8.png">

Để đặt thời gian hết hạn của metadata, ta sử dụng option `metadata-expire` trong section `[main]`
- `metadata-expire` : tính bằng giây. Mặc định nếu không thêm thì giá trị của nó sẽ là 6 giờ.

## Dùng `yum` với `cache-only`
Để dùng `yum` mà không cần kết nối internet, và đã có cache.
```
yum install -C <tên_gói>
```
hoặc
```
yum install --cacheonly <tên_gói>
```

Khi sử dụng tùy chọn này, ta có thể cài đặt mà kiểm tra bất kỳ repo nào trên mạng. Mà chỉ sử dụng các file được lưu trữ trong cache của 1 thao tác trước đó.

để liệt kê các gói sử dụng dữ liệu được lưu trong bộ nhớ cache có chứa "wget"
```
yum -C list wget 
Loaded plugins: fastestmirror
Available Packages
wget.x86_64                                                        1.14-18.el7_6.1                                                         base
```

## Xóa bộ nhớ Cache
```
yum clean all
```

Lệnh này sẽ xóa toàn bộ package đã lưu trong cache.

# Tham khảo
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-Configuring_Yum_and_Yum_Repositories
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-working_with_yum_cache