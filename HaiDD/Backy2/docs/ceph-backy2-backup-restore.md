# Hướng dẫn backup restore với Backy2

# Phần 1: Hướng dẫn Backup
## Bước 1: Chuẩn bị dữ liệu demo Ceph
Tại cụm OPS:
- Boot 1 VM (VM trong bài sử dụng Cirros)
- VM có IP: 10.10.31.168
- VM có volume ID: `3fd52a42-ae4f-42c7-a8d6-042730dee644`

Tạo 1 số file
```
cd /opt/
sudo touch demo01.txt demo02.txt demo03.txt
```
Kết quả
```
$ ls /opt/
demo01.txt  demo02.txt  demo03.txt
```

## Bước 2: Tạo bản backup
> ### Thực hiện trên node `CEPH-Backy2`
Ta có volume ID của VM là: `3fd52a42-ae4f-42c7-a8d6-042730dee644`

Kiểm tra thông tin image rbd
```
root@ceph-backy2:~# rbd info volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644
rbd image 'volume-3fd52a42-ae4f-42c7-a8d6-042730dee644':
        size 10GiB in 2560 objects
        order 22 (4MiB objects)
        block_name_prefix: rbd_data.166936b8b4567
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        flags:
        create_timestamp: Tue Nov 24 09:20:40 2020
```

Tạo Backup, thao tác mất 3-5 phút tùy vào dung lượng Image
```
weekonyear=$(date +"%V")

backy2 backup -t weekly_$weekonyear rbd://volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 volume-3fd52a42-ae4f-42c7-a8d6-042730dee644
```

Kết quả
```
root@ceph-backy2:~# backy2 backup -t weekly_$weekonyear rbd://volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 volume-3fd52a42-ae4f-42c7-a8d6-042730dee644
    INFO: $ /usr/bin/backy2 backup -t weekly_48 rbd://volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 volume-3fd52a42-ae4f-42c7-a8d6-042730dee644
    INFO: Backed up 1/2560 blocks (0.0%)
    INFO: Backed up 14/2560 blocks (0.5%)
    INFO: Backed up 27/2560 blocks (1.1%)
    INFO: Backed up 40/2560 blocks (1.6%)
    ....
    INFO: Backed up 2523/2560 blocks (98.6%)
    INFO: Backed up 2536/2560 blocks (99.1%)
    INFO: Backed up 2549/2560 blocks (99.6%)
    INFO: Backed up 2560/2560 blocks (100.0%)
    INFO: New version: 6b3207c0-2dfd-11eb-b8fa-525400137544 (Tags: [weekly_48])
    INFO: Backy complete.
```

Kiểm tra bản backup vừa tạo
```
backy2 ls | grep -E '3fd52a42-ae4f-42c7-a8d6-042730dee644|size'
```
Kết quả
```
root@ceph-backy2:~# backy2 ls | grep -E '3fd52a42-ae4f-42c7-a8d6-042730dee644|size'
|            date            | name                                        | snapshot_name | size |  size_bytes |                 uid                  | valid | protected | tags      |
| 2020-11-24 09:33:21.349251 | volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 |               | 2560 | 10737418240 | 6b3207c0-2dfd-11eb-b8fa-525400137544 |   1   |     0     | weekly_48 |
```

**Lưu ý:** 
- ID của bản backup là: `6b3207c0-2dfd-11eb-b8fa-525400137544` . Nó sẽ được sử dụng trong phần restore

# Phần 2: Hướng dẫn Restore
**Lý thuyết Restore:**
- Bản thân VM trên Openstack boot với volume Cinder
- Sau khi tích hợp Cinder với Ceph, bản thân Volume tạo trên Openstack sẽ mapping với 1 Volume hoặc Image RBD dưới Ceph
- Backy2 backup bằng việc dump toàn bộ data của volume hay Image RBD từ Ceph ra phân vùng backup của backy2
- Việc restore giống như thay nội dung dữ liệu volume hoặc image RBD lưu dưới Ceph, backy2 sẽ lấy bản dump dữ liệu ghi đè vào phân vùng volume hay image RBD tại Ceph

**Lưu ý:** Tài liệu hướng dẫn restore dữ liệu backup sang 1 VM mới

## Bước 1: Tạo VM mới với cấu hình y hệt
Thực hiện tạo VM trên Openstack:

**Lưu ý:** VM tạo mới có thông tin như sau:
- Dung lượng disk phải bằng với dung lượng disk của VM cần restore
- Sử dụng chung image
- VM mới có IP: 10.10.31.171
- Disk VM: `d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf`
- Khi thực hiện restore, VM mới sẽ phải được tắt đi. Tại đây, ta sẽ tắt VM 

## Bước 2: Kiểm tra thông tin volume
> ### Thực hiện trên node `CEPH-Backy2`
```
rbd info volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
```
Kết quả
```
root@ceph-backy2:~# rbd info volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
rbd image 'volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf':
        size 10GiB in 2560 objects
        order 22 (4MiB objects)
        block_name_prefix: rbd_data.167c76b8b4567
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        flags:
        create_timestamp: Tue Nov 24 09:43:52 2020
```

## Bước 3: Remove image RBD dưới CEPH
> ### Thực hiện trên node `CEPH-Backy2`
Lưu ý: Phải tắt VM trên OPS đi, nếu không sẽ gặp lỗi như dưới đây
```
root@ceph-backy2:~# rbd rm volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
2020-11-24 09:49:00.229785 7fda867fc700 -1 librbd::image::RemoveRequest: 0x55ddd9fdaa50 handle_exclusive_lock: cannot obtain exclusive lock - not removing
Removing image: 0% complete...failed.
rbd: error: image still has watchers
This means the image is still open or the client using it crashed. Try again after closing/unmapping it or waiting 30s for the crashed client to timeout.
```

Tắt VM trên OPS

Xóa volume
```
rbd rm volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
```

Kết quả
```
root@ceph-backy2:~# rbd rm volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
Removing image: 100% complete...done.
```

## Bước 4: Restore bản backup từ Backy2 vào Ceph
> ### Thực hiện trên node `CEPH-Backy2`
Lấy ID bản backups `6b3207c0-2dfd-11eb-b8fa-525400137544` và volume ID

Lưu ý:
- volume ID có dạng: `volume-<VOLUME_ID`

```
backy2 restore $RESTORE_ID rbd://volumes/$VOLUME_ID
```

Thực hiện:
- Restore ID: `6b3207c0-2dfd-11eb-b8fa-525400137544`
- Volume_ID: `volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf`

```
backy2 restore 6b3207c0-2dfd-11eb-b8fa-525400137544 rbd://volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
```

**Lưu ý:**
Quá trình Restore mất rất nhiều thời gian (20-30 phút) tùy vào dung lượng Volume, năng lực của cụm Ceph ..

Kết quả
```
root@ceph-backy2:~# rbd rm volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
Removing image: 100% complete...done.
root@ceph-backy2:~# backy2 restore 6b3207c0-2dfd-11eb-b8fa-525400137544 rbd://volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
    INFO: $ /usr/bin/backy2 restore 6b3207c0-2dfd-11eb-b8fa-525400137544 rbd://volumes/volume-d6e16ad6-29eb-48c5-9d1c-5c6b2e8d0bcf
    INFO: Restored 1/8 blocks (12.5%)
    INFO: Restored 2/8 blocks (25.0%)
    INFO: Restored 3/8 blocks (37.5%)
    INFO: Restored 4/8 blocks (50.0%)
    INFO: Restored 5/8 blocks (62.5%)
    INFO: Restored 6/8 blocks (75.0%)
    INFO: Restored 7/8 blocks (87.5%)
    INFO: Restored 8/8 blocks (100.0%)
    INFO: Backy complete.
```

Tới đây đã backup xong.

# Kiểm tra VM vừa restore
Khởi động VM vừa restore.

Mật khẩu VM restore sẽ là mật khẩu truyền từ cloud init

Lưu ý, VM restore có thể sẽ không login được => Sử dụng câu lệnh `nova set-password <VM-ID>` hoặc truy cập single mode để lấy lại mật khẩu VM.

Đối với Cirros, thì mật khẩu vẫn là mật khẩu mặc định

Kiểm tra
```
ssh cirros@10.10.31.171
ip a
$ ls /opt/
```

Kết quả
```
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast qlen 1000
    link/ether fa:16:3e:92:6e:fc brd ff:ff:ff:ff:ff:ff
    inet 10.10.31.171/24 brd 10.10.31.255 scope global eth0
    inet6 fe80::f816:3eff:fe92:6efc/64 scope link
       valid_lft forever preferred_lft forever
$
$
$ ls /opt/
demo01.txt  demo02.txt  demo03.txt
$
```