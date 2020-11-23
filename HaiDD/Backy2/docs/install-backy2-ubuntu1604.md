# Cài đặt Backy2 trên Ubuntu 16.04

# Chuẩn bị:
Yêu cầu:
- OS: Ubuntu 16.04
- Cấu hình:
    - CPU: 4 Core
    - RAM: 4 GB
    - DISK: 100 GB
    - Network:
        - MNGT: eth0: 10.10.34.167/24
        - CEPH-COM: eth0: 10.10.33.167/24

# Phần 1: Chuẩn bị
> ### Thực hiện trên node `ceph-backy2`
Đặt hostname
```
hostnamectl set-hostname ceph-backy2
```

Cài đặt chronyd. Đồng bọ từ NTP server: `10.10.34.130`
```
apt-get install chrony -y
systemctl restart chrony
systemctl status chrony
systemctl enable  chrony
```

# Phần 2: Cài đặt và cấu hình CEPH Client
> ### Thực hiện trên node `ceph-backy2`

Thêm repolist
```
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

echo deb https://download.ceph.com/debian-luminous/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
```

Update và cài đặt ceph-common
```
apt-get -y update
apt-get install -y ceph-common
```

Kiểm tra kết nối đến đường CEPH-com
```
ping 10.10.33.166
```

> ### Thực hiện trên node `ceph-aio`
```
scp /etc/ceph/* root@10.10.34.167:/etc/ceph/
```

Kết quả
```
[root@cephaio ~]# scp /etc/ceph/* root@10.10.34.167:/etc/ceph/
The authenticity of host '10.10.34.167 (10.10.34.167)' can't be established.
ECDSA key fingerprint is SHA256:oMYLrqLxlfmlq87hz9qXfQg8AD3IMFC633qpGVMHG5w.
ECDSA key fingerprint is MD5:10:1e:e4:22:8e:20:63:9a:8a:28:60:ba:4a:1b:3e:ff.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '10.10.34.167' (ECDSA) to the list of known hosts.
root@10.10.34.167's password:
ceph.client.admin.keyring                                                                                      100%   63    56.8KB/s   00:00
ceph.client.nova.keyring                                                                                       100%   62    75.0KB/s   00:00
ceph.conf                                                                                                      100%  413   452.4KB/s   00:00
rbdmap                                                                                                         100%   92   129.0KB/s   00:00
tmpB3CxIg                                                                                                      100%    0     0.0KB/s   00:00
```

> ### Thực hiện trên node `ceph-backy2`
Kiểm tra kết nối ceph
```
ceph -s
```

Kết quả
```
root@ceph-backy2:~# ceph -s
  cluster:
    id:     f81764ee-c551-4ea4-8dfc-356bce4dbbb5
    health: HEALTH_OK

  services:
    mon: 1 daemons, quorum cephaio
    mgr: cephaio(active)
    osd: 3 osds: 3 up, 3 in

  data:
    pools:   4 pools, 120 pgs
    objects: 77 objects, 176MiB
    usage:   10.1GiB used, 140GiB / 150GiB avail
    pgs:     120 active+clean

  io:
    client:   7.58KiB/s rd, 8op/s rd, 0op/s wr
```

# Phần 3: Cài đặt và cấu hình Backy2
> ### Thực hiện trên node `ceph-backy2`

## Cài đặt Backy2
```
wget https://github.com/wamdam/backy2/releases/download/v2.9.17/backy2_2.9.17_all.deb

dpkg -i backy2_2.9.17_all.deb 
apt-get -f -y install
```

## Cài đặt PostgreSQL-10
Cài đặt Postgre
```
sudo apt-get install software-properties-common -y
sudo apt-get install apt-transport-https -y
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -y update
sudo apt-get -y install postgresql-10
```

Khởi động Postgre
```
systemctl start postgresql
systemctl enable postgresql
```

Đăng nhập root
```
sudo -u postgres psql
```

Đặt mật khẩu user postgres
```sql
ALTER USER postgres PASSWORD 'Cloud365a@123';
```

Kết quả
```
postgres=# ALTER USER postgres PASSWORD 'Cloud365a@123';
ALTER ROLE
postgres=#
```

Thoát `\q`
```
postgres=# \q
```

Đăng nhập với mật khẩu mới. `Cloud365a@123`
```
psql -U postgres -h localhost
```

Khởi tạo User, DB và phân quyền user vừa tạo
```sql
CREATE USER backy2_user with PASSWORD 'Cloud365aA123';
CREATE DATABASE backy2_db;
GRANT ALL PRIVILEGES ON DATABASE backy2_db TO backy2_user;
\q
```

Đăng nhập User vừa tạo. Pass: `Cloud365aA123`
```
psql -U backy2_user -h localhost  -d backy2_db
```
Kết quả
```
root@ceph-backy2:~# psql -U backy2_user -h localhost  -d backy2_db
Password for user backy2_user:
psql (10.15 (Ubuntu 10.15-1.pgdg16.04+1))
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

backy2_db=> \q
```

Cài đặt psycopg requirement để backy2 kết nối vào PostgreSQL
```
sudo apt-get install python3-psycopg2
```

## Chuẩn bị thư mục chứa backup dữ liệu
Tạo thư mục chứa
```
mkdir -p /backy2_backup
```

## Cấu hình Backy2
Chỉnh sửa config
```
sed -i 's|disallow_rm_when_younger_than_days: 6|disallow_rm_when_younger_than_days: 15|g' /etc/backy.cfg
sed -i 's|engine: sqlite:////var/lib/backy2/backy.sqlite|engine: postgresql://backy2_user:Cloud365aA123@localhost/backy2_db|g' /etc/backy.cfg
sed -i 's|path: /var/lib/backy2/data|path: /backy2_backup|g' /etc/backy.cfg
```

Cấu hình thay đổi:
- Thời gian lưu backup 15 ngày
- DB sử dụng Prosgre
- Điều chỉnh thư mục chưa backup

Khởi tạo DB
```
backy2 initdb 
```

Kiểm tra database
```
psql -U backy2_user -h localhost  -d backy2_db
\dt
```

Kết quả
```
root@ceph-backy2:~# psql -U backy2_user -h localhost  -d backy2_db
Password for user backy2_user:
psql (10.15 (Ubuntu 10.15-1.pgdg16.04+1))
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

backy2_db=> \dt
               List of relations
 Schema |      Name       | Type  |    Owner
--------+-----------------+-------+-------------
 public | alembic_version | table | backy2_user
 public | blocks          | table | backy2_user
 public | deleted_blocks  | table | backy2_user
 public | stats           | table | backy2_user
 public | tags            | table | backy2_user
 public | versions        | table | backy2_user
(6 rows)

backy2_db=> \q
```

# Phần 4: Thao tác với backy2
Backup VM:
```
backy2 backup -t <tag_backup> rbd://volumes/$VOLUME_ID $VOLUME_ID
```

Lưu ý: `$VOLUME_ID` phải có tiền tố `volume-`
Ví dụ: `volume-78194e51-211d-4d05-b9c2-3369e610ec11`

Ví dụ
```
root@ceph-backy2:~# backy2 backup -t test_bk1 rbd://volumes/volume-52d7c7e1-1802-4f41-803e-da9b88729841 volume-52d7c7e1-1802-4f41-803e-da9b887298                                                41
    INFO: $ /usr/bin/backy2 backup -t test_bk1 rbd://volumes/volume-52d7c7e1-1802-4f41-803e-da9b88729841 volume-52d7c7e1-1802-4f41-803e-da9b88729                                                841
    INFO: Backed up 1/2560 blocks (0.0%)
    INFO: Backed up 14/2560 blocks (0.5%)
    INFO: Backed up 27/2560 blocks (1.1%)
    INFO: Backed up 40/2560 blocks (1.6%)
    INFO: Backed up 53/2560 blocks (2.1%)
    ....
    INFO: Backed up 2523/2560 blocks (98.6%)
    INFO: Backed up 2536/2560 blocks (99.1%)
    INFO: Backed up 2549/2560 blocks (99.6%)
    INFO: Backed up 2560/2560 blocks (100.0%)
    INFO: New version: bba500fa-2d5c-11eb-b8fa-525400137544 (Tags: [test_bk1])
    INFO: Backy complete.
```

Kiểm tra bản backup
```
backy2 ls
```

Kết quả:
```
root@ceph-backy2:~# backy2 ls
    INFO: $ /usr/bin/backy2 ls
+----------------------------+---------------------------------------------+---------------+------+-------------+--------------------------------------+-------+-----------+----------+
|            date            | name                                        | snapshot_name | size |  size_bytes |                 uid                  | valid | protected | tags     |
+----------------------------+---------------------------------------------+---------------+------+-------------+--------------------------------------+-------+-----------+----------+
| 2020-11-23 14:23:07.349997 | volume-52d7c7e1-1802-4f41-803e-da9b88729841 |               | 2560 | 10737418240 | bba500fa-2d5c-11eb-b8fa-525400137544 |   1   |     0     | test_bk1 |
+----------------------------+---------------------------------------------+---------------+------+-------------+--------------------------------------+-------+-----------+----------+
    INFO: Backy complete.
```

Kiểm tra thư mục chứa dữ liệu
```
root@ceph-backy2:~# ll /backy2_backup/
total 40
drwxr-xr-x 10 root root 4096 Nov 23 14:23 ./
drwxr-xr-x 24 root root 4096 Nov 23 14:05 ../
drwxr-xr-x  3 root root 4096 Nov 23 14:23 12/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 25/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 47/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 56/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 59/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 98/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 a1/
drwxr-xr-x  3 root root 4096 Nov 23 14:23 ba/
```
