# Hướng dẫn cài đặt Benji trên CentOS-7

# Chuẩn bị
- OS : CentOS-7
- Cấu hình:
    - CPU: 4 Core
    - RAM: 4 GB
    - DISK: 100 GB
    - Network:
        - MNGT: eth0: 10.10.34.168/24
        - CEPH-COM: eth0: 10.10.33.168/24

- Tắt Firewall, SELinux, cài đặt chronyd

Cài đặt các gói bổ sung
```
yum install -y epel-release
yum install -y python36-devel python36-pip python36-libs python36-setuptools
yum install -y git gcc make python36-devel python36-pip python36-libs python36-setuptools librados-devel librbd-devel
```

Cài đặt các gói hỗ trợ Ceph (Docs cài theo luminous)
```
cat <<EOF> /etc/yum.repos.d/ceph.repo
[ceph]
name=Ceph packages for $basearch
baseurl=https://download.ceph.com/rpm-luminous/el7/x86_64/
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-luminous/el7/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-luminous/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF

yum update -y
yum install ceph-common -y

yum install python36-rados python36-rbd -y
```

Chuyển file admin keyring và ceph config tới thư mục `/etc/ceph/` tại node benji

Thực hiện trên node CephAIO:
```
[root@cephaio ~]# scp /etc/ceph/ceph.client.admin.keyring root@10.10.34.168:/etc/ceph/

[root@cephaio ~]# scp /etc/ceph/ceph.conf root@10.10.34.168:/etc/ceph/
```
Kiểm tra trên node Benji 
```
[root@ceph-benji ceph]# ls
ceph.client.admin.keyring  ceph.conf  rbdmap
```

# Phần 1: Cài đặt PostgreSQL
Disable version mặc định, sửa `vi /etc/yum.repos.d/CentOS-Base.repo`

Thêm dòng `exclude=postgresql*` vào phần `[base]` và `[updates]`
```
[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
exclude=postgresql*

#released updates
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
exclude=postgresql*
```

Cài đặt PostgreSQL
```
yum install centos-release-scl -y

yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y
```

Kiểm các gói hiện tại
```
yum list postgresql*
```

Cài đặt Postgre
```
yum install postgresql11 postgresql11-devel postgresql11-libs postgresql11-server -y
```

Khởi tạo DB
```
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
```

Khởi động DB
```
sudo systemctl start postgresql-11

sudo systemctl enable postgresql-11
```

Cấu hình kết nối , Chỉnh sửa `vi /var/lib/pgsql/11/data/pg_hba.conf` còn lại như sau
```
[root@ceph-benji ~]# cat /var/lib/pgsql/11/data/pg_hba.conf | grep -Ev '^#|^$'
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

Khởi động Postgre
```
sudo systemctl restart postgresql-11
```

Đổi mật khẩu ADMIN
```
sudo -u postgres psql
ALTER USER postgres PASSWORD 'Cloud365a@123';
```

Tạo tài khoản mới
```
CREATE USER benji_user with PASSWORD 'Cloud365aA123';
CREATE DATABASE benji_db;
GRANT ALL PRIVILEGES ON DATABASE benji_db TO benji_user;
```

Kiểm tra tài khoản
```
sudo su - postgres

psql -U benji_user -d benji_db -h localhost
```

Kết quả
```
[root@ceph-benji ~]# sudo su - postgres
-bash-4.2$ psql -U benji_user -d benji_db -h localhost
Password for user benji_user:
psql (11.10)
Type "help" for help.

benji_db=>

```

# Phần 2: Cài đặt Benji
Tạo mới thư mục chứa backups
```
mkdir -p /backups
```

Cài đặt Benji bản 8
```
pip3.6 install benji==0.8.0
```

Cài đặt psycopg2-binary
```
pip3.6 install psycopg2-binary
```

Tạo file cấu hình Benji
```
vi /etc/benji.yaml
```
Nội dung:
```yaml
configurationVersion: '1'
databaseEngine: postgresql://benji_user:Cloud365aA123@localhost/benji_db
defaultStorage: storage-1
logFile: /var/log/benji.log
storages:
  - name: storage-1
    storageId: 1
    module: file
    configuration:
      path: /backups
ios:
  - name: file
    module: file
  - name: rbd
    module: rbd
    configuration:
      simultaneousReads: 3
      simultaneousWrites: 3
      cephConfigFile: /etc/ceph/ceph.conf
      clientIdentifier: admin
      newImageFeatures:
        - RBD_FEATURE_LAYERING
        - RBD_FEATURE_EXCLUSIVE_LOCK
        - RBD_FEATURE_STRIPINGV2
        - RBD_FEATURE_OBJECT_MAP
        - RBD_FEATURE_FAST_DIFF
        - RBD_FEATURE_DEEP_FLATTEN
```

Khởi tạo Database
```
benji database-init
```

Kiểm tra
```
psql -U benji_user -h localhost  -d benji_db
\dt
```
Kết quả
```
[root@ceph-benji ~]# psql -U benji_user -h localhost  -d benji_db
Password for user benji_user:
psql (11.10)
Type "help" for help.

benji_db=> \dt
               List of relations
 Schema |      Name       | Type  |   Owner
--------+-----------------+-------+------------
 public | alembic_version | table | benji_user
 public | blocks          | table | benji_user
 public | deleted_blocks  | table | benji_user
 public | labels          | table | benji_user
 public | locks           | table | benji_user
 public | storages        | table | benji_user
 public | versions        | table | benji_user
(7 rows)
```

# Tạo Backup và restore
## Tạo backups
```
benji backup rbd:volumes/<VOLUME_ID> <BACKUP_VOLUME_NAME>
```

Ví dụ:
```
[root@ceph-benji ~]# benji backup rbd:volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 volume-backups001
    INFO: $ /usr/local/bin/benji backup rbd:volumes/volume-3fd52a42-ae4f-42c7-a8d6-042730dee644 volume-backups001
    INFO: Backed up 13/2560 blocks (0.5%)
    INFO: Backed up 26/2560 blocks (1.0%)
    INFO: Backed up 39/2560 blocks (1.5%)
    INFO: Backed up 52/2560 blocks (2.0%)
    INFO: Backed up 65/2560 blocks (2.5%)
    INFO: Backed up 78/2560 blocks (3.0%)
    ....
    INFO: Backed up 2535/2560 blocks (99.0%)
    INFO: Backed up 2548/2560 blocks (99.5%)
    INFO: Backed up 2560/2560 blocks (100.0%)
    INFO: Set status of version volume-backups001-f6xq39 to valid.
    INFO: Backed up metadata of version volume-backups001-f6xq39.
    INFO: New version volume-backups001-f6xq39 created, backup successful.
```

Kiểm tra:
```
[root@ceph-benji ~]# benji ls
    INFO: $ /usr/local/bin/benji ls
+---------------------+--------------------------+-------------------+----------+---------+------------+--------+-----------+-----------+
|         date        | uid                      | volume            | snapshot |    size | block_size | status | protected | storage   |
+---------------------+--------------------------+-------------------+----------+---------+------------+--------+-----------+-----------+
| 2020-11-24T14:31:24 | volume-backups001-f6xq39 | volume-backups001 |          | 10.0GiB |     4.0MiB | valid  |   False   | storage-1 |
+---------------------+--------------------------+-------------------+----------+---------+------------+--------+-----------+-----------+
```

## Restore
Câu lệnh
```
benji restore --sparse <VOLUME_BACKUP_ID> rbd:volumes/<VOLUME_ID> --force
```