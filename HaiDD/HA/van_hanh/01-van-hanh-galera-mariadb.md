# Vận hành, giải quyết sự cố MariaDB

# **Các Case Vận hành**
## **Case 1. Thêm node vào Galera MariaDB Cluster**
```
10.10.35.164 node1 (cũ)
10.10.35.165 node2 (cũ)
10.10.35.166 node3 (cũ)

10.10.35.167 node4 (mới)
```

### Cài đặt môi trường ban đầu cho `node4`
- Set hostname
    ```
    hostnamectl set-hostname node4
    bash
    ```
- Đồng bộ thời gian với chrony về NTP server chung mà cluster sử dụng
- Disable Selinux, firewalld:
    ```
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    systemctl stop firewalld
    systemctl disable firewalld
    init 6
    ```
- Cấu hình file `/etc/hosts`
    ```
    echo "10.10.35.164 node1" >> /etc/hosts
    echo "10.10.35.165 node2" >> /etc/hosts
    echo "10.10.35.166 node3" >> /etc/hosts
    echo "10.10.35.167 node4" >> /etc/hosts
    ```

### Bước 1: Cài đặt MariaDB trên `node4` (mới)
Cài đặt MariaDB cùng phiên bản với các node cũ. Tại đây là phiên bản 10.2
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo

yum -y update

yum install -y mariadb mariadb-server

yum install -y galera rsync

systemctl stop mariadb
```

### Bước 2: Cấu hình Galera Cluster trên `node4`
Cấu hình:
```
echo '[server]
[mysqld]
bind-address=10.10.35.167

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.10.34.164,10.10.34.165,10.10.34.166,10.10.35.167"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.10.35.167
# this server ip, change for each server
wsrep_node_address="10.10.34.167"
# this server name, change for each server
wsrep_node_name="node4"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
' > /etc/my.cnf.d/server.cnf
```

**Lưu ý:** `wsrep_cluster_address` đầy đủ IP các node

Khởi động lại dịch vụ
```
systemctl restart mariadb
systemctl enable mariadb
```

**Lưu ý:** Node mới sẽ tự join vào Cluster đã có từ trước

Kiểm tra
```
[root@node4 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_incoming_addresses'"
+--------------------------+-------------------------------------------------------------------------+
| Variable_name            | Value                                                                   |
+--------------------------+-------------------------------------------------------------------------+
| wsrep_incoming_addresses | 10.10.35.166:3306,10.10.35.167:3306,10.10.35.164:3306,10.10.35.165:3306 |
+--------------------------+-------------------------------------------------------------------------+
```

### Bước 3: Thay đổi cấu hình trên các node cũ `node1`, `node2`, `node3`
> ### Thực hiện trên các node : `node1`, `node2`, `node3`
- Thêm cấu hình file `/etc/hosts`
    ```
    echo "10.10.35.167 node4" >> /etc/hosts
    ```
- Thay đổi settings `wsrep_cluster_address` trong file `/etc/my.cnf.d/server.cnf`, điền đầy đủ IP các node thuộc cluser hiện tại, sau đó restart dịch vụ.

**Trên `node1`:**
```
[root@node1 ~]# cat /etc/my.cnf.d/server.cnf
[server]
[mysqld]
bind-address=10.10.35.164

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.10.34.164,10.10.34.165,10.10.34.166,10.10.34.167"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.10.35.164
# this server ip, change for each server
wsrep_node_address="10.10.34.164"
# this server name, change for each server
wsrep_node_name="node1"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
```

Khởi động lại dịch vụ
```
systemctl restart mariadb
```

**Trên `node2`:**
```
[root@node2 ~]# cat /etc/my.cnf.d/server.cnf
[server]
[mysqld]
bind-address=10.10.35.165

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.10.34.164,10.10.34.165,10.10.34.166,10.10.34.167"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.10.35.165
# this server ip, change for each server
wsrep_node_address="10.10.34.165"
# this server name, change for each server
wsrep_node_name="node2"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
```

Khởi động lại dịch vụ
```
systemctl restart mariadb
```

**Trên `node3`:**
```
[root@node3 ~]# cat /etc/my.cnf.d/server.cnf
[server]
[mysqld]
bind-address=10.10.35.166

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.10.34.164,10.10.34.165,10.10.34.166,10.10.34.167"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.10.35.166
# this server ip, change for each server
wsrep_node_address="10.10.34.166"
# this server name, change for each server
wsrep_node_name="node3"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
```

Khởi động lại dịch vụ
```
systemctl restart mariadb
```

### Bước 4: Kiểm tra
```
[root@node1 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_incoming_addresses'"
+--------------------------+-------------------------------------------------------------------------+
| Variable_name            | Value                                                                   |
+--------------------------+-------------------------------------------------------------------------+
| wsrep_incoming_addresses | 10.10.35.166:3306,10.10.35.167:3306,10.10.35.164:3306,10.10.35.165:3306 |
+--------------------------+-------------------------------------------------------------------------+
```

## **Case 2. Thay thế 1 node Galera Cluster**
```
10.10.35.164 node1 (cũ)
10.10.35.165 node2 (cũ)
10.10.35.166 node3 (cũ - thay thế)

10.10.35.166 node3-1 (mới)
```

### Bước 1: Tắt hẳn `node3` (cũ)
```
[root@node3 ~]# init 0
```

**Lưu ý:**
- node3-1 (Mới) sẽ nắm IP của node3 (Cũ) phục vụ cho công việc thay node.
- Sau khi thay node, node3 (Cũ) không được bật nếu không sẽ ảnh hướng tới cluster
- Có thể thay IP của node3 (Cũ) phục vụ nhu cầu backup dữ liệu

### Bước 2: Thay IP cho `node3-1` (mới)
> ### Thực hiện trên `node3-1` (mới)
Cấu hình IP:
```
nmcli con mod eth0 ipv4.address 10.10.35.166/24
nmcli con mod eth0 ipv4.gateway 10.10.35.1
nmcli con mod eth0 ipv4.dns 8.8.8.8
nmcli con mod eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

nmcli con mod eth1 ipv4.address 10.10.34.166/24
nmcli con mod eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes

systemctl restart network
```

**Lưu ý:** Nếu đang ssh, khi restart network ta cần ssh lại phiên mới theo IP mới đặt

Kiểm tra lại 
```
[root@node3-1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:e3:95:09 brd ff:ff:ff:ff:ff:ff
    inet 10.10.35.166/24 brd 10.10.35.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fee3:9509/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:35:29:02 brd ff:ff:ff:ff:ff:ff
    inet 10.10.34.166/24 brd 10.10.34.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::9a3f:daf3:166:2ed6/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

### Bước 3: Cài đặt môi trường cơ bản
- Đồng bộ thời gian với chrony về NTP server chung mà cluster sử dụng
- Disable Selinux, firewalld:
    ```
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    systemctl stop firewalld
    systemctl disable firewalld
    init 6
    ```
- Cấu hình file `/etc/hosts`
    ```
    echo "10.10.35.164 node1" >> /etc/hosts
    echo "10.10.35.165 node2" >> /etc/hosts
    echo "10.10.35.166 node3-1" >> /etc/hosts
    ```

### Bước 4: Cài đặt MariaDB
Cài đặt MariaDB cùng phiên bản với các node cũ. Tại đây là phiên bản 10.2
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo

yum -y update

yum install -y mariadb mariadb-server

yum install -y galera rsync

systemctl stop mariadb
```

### Bước 5: Cấu hình Galera Cluster
Cấu hình
```
cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf.bak

echo '[server]
[mysqld]
bind-address=10.10.35.166

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#add your node ips here
wsrep_cluster_address="gcomm://10.10.34.164,10.10.34.165,10.10.34.166"
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
#Cluster name
wsrep_cluster_name="portal_cluster"
# Allow server to accept connections on all interfaces.
bind-address=10.10.35.166
# this server ip, change for each server
wsrep_node_address="10.10.34.166"
# this server name, change for each server
wsrep_node_name="node3-1"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
'> /etc/my.cnf.d/server.cnf
```

Khởi động lại dịch vụ
```
systemctl restart mariadb
systemctl enable mariadb
```

### Bước 6: Kiểm tra
```
[root@node3-1 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_incoming_addresses'"
+--------------------------+-------------------------------------------------------+
| Variable_name            | Value                                                 |
+--------------------------+-------------------------------------------------------+
| wsrep_incoming_addresses | 10.10.35.166:3306,10.10.35.164:3306,10.10.35.165:3306 |
+--------------------------+-------------------------------------------------------+

[root@node3-1 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_local_state_comment'"
+---------------------------+--------+
| Variable_name             | Value  |
+---------------------------+--------+
| wsrep_local_state_comment | Synced |
+---------------------------+--------+

[root@node3-1 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
```

# **Các Case xử lý sự cố**
**Trường hợp xảy ra sự cố có 2 loại:**
- An toàn: Tức dịch vụ tắt bình thường `systemctl stop mariadb`
- Không an toàn: Khi tiến trình bị crash, os xảy ra vấn đề, mất điện ....

## **Case 1: 1 node xảy ra vấn đề**
### Mô tả
Trong mô hình 3 node, nếu 1 node xảy ra vấn đề (Crash OS, mất điện, Crash tiến trình, tắt ...), cụm 2 node vẫn hoạt động bình thường.

### Giải quyết
Khởi động lại OS và tiến trình database, dịch vụ hoạt động bình thường
```
systemctl start mariadb
```

## **Case 2: 2 node xảy ra vấn đề**
Có 2 trường hợp:
- 2 node down dịch vụ an toàn
- 2 node down dịch vụ không an toàn

**Lưu ý:** Trong mô hình 3 node, khi 2 node có vấn đề thì không được phép restart service trên node còn lại

### Trường hợp dịch vụ down an toàn
- Với mô hình 3 node, 2 node down an toàn dịch vụ chạy bình thường, không xảy ra vấn đề
- Khi bật lại dịch vụ tại 2 node down an toàn, dịch vụ mariadb trở lại hoạt động bình thường.

### Trường hợp dịch vụ down không an toàn
- Nếu dịch vụ tại 2 trong 3 node down không an toàn, dịch vụ mariadb tại cả 3 node sẽ không thể hoạt động do cơ chế quorum nhằm tránh dữ liệu bị phân mảnh, khác nhau tại 3 node
- Để lab được trường hợp này sử dụng tắt nóng trên Webvirt (Force off)

-> Trong hợp hợp này cụm đã bị split brain, để giải quyết ta cần khởi tạo lại quorum của cụm

**Cách giải quyết:**
- Bước 1: Chắc chắn tắt hẳn 2 node trong trạng thái lỗi (Tắt nóng (Force off) hoặc nút nguồn server).
- Bước 2: Tại node không lỗi, thực hiện lệnh:
    ```
    mysql -u root -e "SET GLOBAL wsrep_provider_options='pc.bootstrap=1';"
    ```
    
    Ví dụ:
    ```
    [root@node3 ~]# mysql -u root -e "SET GLOBAL wsrep_provider_options='pc.bootstrap=1';"
    [root@node3 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 1     |
    +--------------------+-------+
    ```

    - Sau 2 bước trên cluster sẽ hoạt động trở lại

- Bước 3: Bật lại các node xảy ra sự cố bình thường. Dịch vụ mariadb tại các node lỗi sẽ tự join Cluster

- Bước 4: Kiểm tra lại trên các node
    ```
    mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3     |
    +--------------------+-------+
    ```

## **Case 3: 3 node xảy ra sự cố**
Có 2 trường hợp:
- 3 node down dịch vụ an toàn
- 3 node down dịch vụ không an toàn

### Trường hợp dịch vụ down an toàn
- Trong trường hợp các node down an toàn, kiểm tra giá trị `seqno` trong file `/var/lib/mysql/grastate.dat`. Node có giá trị lớn nhất sẽ là node khởi tạo lại cluster

    ```
    # node1
    [root@node1 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   892
    safe_to_bootstrap: 0

    # node2
    [root@node2 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   892
    safe_to_bootstrap: 0

    # node3
    [root@node3 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   893
    safe_to_bootstrap: 0
    ```

- Như trường hợp trên, `node3` có giá trị `seqno` cao nhất, tức là đây là node down sau cùng. Vì vậy, ta sẽ thao tác khởi tạo cluster tại `node3`.

- Để khởi tạo lại cluster, thay đổi giá trị `safe_to_bootstrap` bằng 1 và chạy câu lệnh `galera_new_cluster`. Sau khi chạy câu lệnh `galera_new_cluster` cluster sẽ khởi tạo trở lại.

    ```
    [root@node3 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   893
    safe_to_bootstrap: 1

    [root@node3 ~]# galera_new_cluster

    [root@node3 ~]# systemctl status mariadb
    ● mariadb.service - MariaDB 10.2.35 database server
    Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor preset: disabled)
    Drop-In: /etc/systemd/system/mariadb.service.d
            └─migrated-from-my.cnf-settings.conf
    Active: active (running) since Thu 2020-11-12 10:49:21 +07; 4s ago
    ```

- Start service 2 node còn lại theo cách thông thường:
    ```
    # node1
    [root@node1 ~]# systemctl start mariadb

    # node2
    [root@node2 ~]# systemctl start mariadb
    ```

- Kiểm tra lại Cluster trên các node
    ```
    mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3     |
    +--------------------+-------+
    ```

### Trường hợp dịch vụ down không an toàn
- Trong trường hợp tốt này, trạng thái database sẽ được lưu lại, khi các node hoạt động trở lại Cluster sẽ tự khôi phục
- Trong trường hợp xấu, cụm không thể khởi động lại, lần vết cụm down sau cùng (tốt nhất) hoặc chọn 1 node bất kỳ thực hiện. Sẽ có rủi ro mất mát dữ liệu

**Cách giải quyết:**
- Bật lại các node
- Thực hiện trên tất cả các node: kill tiến trình mysql và stop service mariadb:
    ```
    pkill -KILL -u mysql
    systemctl stop mariadb
    ```

Trên node down sau cùng (tốt nhất). 
- Chỉnh giá trị `safe_to_bootstrap` trong file `/var/lib/mysql/grastate.dat` thành `1`
    ```
    [root@node2 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   -1
    safe_to_bootstrap: 1
    ```

- Tắt dịch vụ mariadb, khôi phục cluster
    ```
    systemctl stop mariadb
    galera_recovery
    galera_new_cluster
    ```

- Kiểm tra dịch vụ:
    ```
    [root@node2 ~]# systemctl status mariadb
    ● mariadb.service - MariaDB 10.2.35 database server
    Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor preset: disabled)
    Drop-In: /etc/systemd/system/mariadb.service.d
            └─migrated-from-my.cnf-settings.conf
    Active: active (running) since Thu 2020-11-12 11:12:27 +07; 5s ago
    ```

Trên các node còn lại, thực hiện khởi động lại service mariadb:
```
systemctl restart mariadb
```

Kiểm tra lại Cluster trên các node
```
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
```

## Case 4: Khởi động lại Cluster
- Trong trường hợp khởi động cluster (restart OS), cluster không hoạt động
- Trong trường hợp xấu cụm không thể khởi động lại, lần vết cụm down sau cùng (tốt nhất, ít rủi ro mất mát dữ liệu) hoặc chọn 1 node bất kỳ thực hiện(sẽ có rủi ro mất mát dữ liệu):

**Cách giải quyết:**
- Chỉnh giá trị `safe_to_bootstrap` trong file `/var/lib/mysql/grastate.dat` thành `1`
    ```
    [root@node2 ~]# cat /var/lib/mysql/grastate.dat
    # GALERA saved state
    version: 2.1
    uuid:    2491db5f-2338-11eb-a952-3f1bac1e04b4
    seqno:   -1
    safe_to_bootstrap: 1
    ```

- Tắt dịch vụ mariadb, khôi phục cluster
    ```
    systemctl stop mariadb
    galera_recovery
    galera_new_cluster
    ```

- Kiểm tra lại service:
    ```
    [root@node2 ~]# systemctl status mariadb
    ● mariadb.service - MariaDB 10.2.35 database server
    Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor preset: disabled)
    Drop-In: /etc/systemd/system/mariadb.service.d
            └─migrated-from-my.cnf-settings.conf
    Active: active (running) since Thu 2020-11-12 11:24:10 +07; 6s ago
    ```

- Trên các node còn lại, thực hiện restart service:
    ```
    systemctl restart mariadb
    ```

- Kiểm tra :
    ```
    mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
    +--------------------+-------+
    | Variable_name      | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3     |
    +--------------------+-------+
    ```