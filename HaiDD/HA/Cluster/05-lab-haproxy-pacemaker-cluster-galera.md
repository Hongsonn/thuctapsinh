# Hướng dẫn triển khai HAProxy cho Cluster Galera 3 node trên CentOS-7

# Tổng quan
**MariaDB Galera Cluster** là giải pháp sao chép đồng bộ nâng cao tính sẵn sàng cho MariaDB. Galera hỗ trợ chế độ Active-Active tức có thể truy cập, ghi dữ liệu đồng thời trên tất các node MariaDB thuộc Galera Cluster.

# Phần 1: Chuẩn bị
## Phân hoạch

<img src="..\images\cluster\Screenshot_16.png">

## Mô hình
Mô hình triển khai:

<img src="..\images\cluster\Screenshot_15.png">

Mô hình hoạt động:

<img src="..\images\cluster\Screenshot_17.png">

## Cấu hình Galera 3 node
### Thiết lập ban đầu
#### **Tại node1**
Cấu hình hostname
```
hostnamectl set-hostname node1
```

Cấu hình network
```
nmcli con mod eth0 ipv4.addresses 10.10.35.164/24
nmcli con mod eth0 ipv4.gateway 10.10.35.1
nmcli con mod eth0 ipv4.dns 8.8.8.8
nmcli con mod eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

nmcli con mod eth1 ipv4.addresses 10.10.34.164/24
nmcli con mod eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes
```

Tắt Firewall, SELinux, Khởi động lại
```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
init 6
```

Cấu hình host
```
echo "10.10.35.164 node1" >> /etc/hosts
echo "10.10.35.165 node2" >> /etc/hosts
echo "10.10.35.166 node3" >> /etc/hosts
```

#### **Tại node2**
Cấu hình hostname
```
hostnamectl set-hostname node2
```

Cấu hình network
```
nmcli con mod eth0 ipv4.addresses 10.10.35.165/24
nmcli con mod eth0 ipv4.gateway 10.10.35.1
nmcli con mod eth0 ipv4.dns 8.8.8.8
nmcli con mod eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

nmcli con mod eth1 ipv4.addresses 10.10.34.165/24
nmcli con mod eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes
```

Tắt Firewall, SELinux, Khởi động lại
```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
init 6
```

Cấu hình host
```
echo "10.10.35.164 node1" >> /etc/hosts
echo "10.10.35.165 node2" >> /etc/hosts
echo "10.10.35.166 node3" >> /etc/hosts
```

#### **Tại node3**
Cấu hình hostname
```
hostnamectl set-hostname node3
```

Cấu hình network
```
nmcli con mod eth0 ipv4.addresses 10.10.35.166/24
nmcli con mod eth0 ipv4.gateway 10.10.35.1
nmcli con mod eth0 ipv4.dns 8.8.8.8
nmcli con mod eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

nmcli con mod eth1 ipv4.addresses 10.10.34.166/24
nmcli con mod eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes
```

Tắt Firewall, SELinux, Khởi động lại
```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
init 6
```

Cấu hình host
```
echo "10.10.35.164 node1" >> /etc/hosts
echo "10.10.35.165 node2" >> /etc/hosts
echo "10.10.35.166 node3" >> /etc/hosts
```

### Cài đặt MariaDB (10.2)
> ### Thực hiện trên cả 3 node

Khai báo repo
```
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
```

Update và cài đặt MariaDB
```
yum -y update
yum install -y mariadb mariadb-server
```

Cài đặt galera và gói hỗ trợ
```
yum install -y galera rsync
```

Tắt Mariadb
```
systemctl stop mariadb
```
**Lưu ý:** Không khởi động dịch vụ mariadb sau khi cài (Liên quan tới cấu hình Galera Mariadb)

### Cấu hình Galera Cluster
#### **Tại node1**
Backup và chỉnh sửa cấu hình:
```
cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf.bak

echo '[server]
[mysqld]
bind-address=10.10.35.164

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
bind-address=10.10.35.164
# this server ip, change for each server
wsrep_node_address="10.10.34.164"
# this server name, change for each server
wsrep_node_name="node1"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
' > /etc/my.cnf.d/server.cnf
```

**Lưu ý:**
- `wsrep_cluster_address`: Danh sách các node thuộc Cluster, sử dụng địa chỉ IP (Trong bài lab, tôi sẽ sử dụng dải IP Replicate 10.10.34.164,10.10.34.165,10.10.34.166)
- `wsrep_cluster_name`: Tên của cluster
- `wsrep_node_address`: Địa chỉ IP của node đang thực hiện
- `wsrep_node_name`: Tên node (Giống với hostname)
- Không được bật mariadb (Quan trọng, nếu không sẽ dẫn tới lỗi khi khởi tạo Cluster)

#### **Tại node2**
Backup và chỉnh sửa cấu hình:
```
cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/server.cnf.bak

echo '[server]
[mysqld]
bind-address=10.10.35.165

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
bind-address=10.10.35.165
# this server ip, change for each server
wsrep_node_address="10.10.34.165"
# this server name, change for each server
wsrep_node_name="node2"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
' > /etc/my.cnf.d/server.cnf
```

#### **Tại node3**
Backup và chỉnh sửa cấu hình:
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
wsrep_node_name="node3"
wsrep_sst_method=rsync
[embedded]
[mariadb]
[mariadb-10.2]
' > /etc/my.cnf.d/server.cnf
```

### Khởi động dịch vụ
> ### Tại `node1`, khởi tạo cluster
```
galera_new_cluster
systemctl start mariadb
systemctl enable mariadb
```

> ### Tại `node2`, `node3`, chạy dịch vụ mariadb
```
systemctl start mariadb
systemctl enable mariadb
```

### Kiểm tra tại `node1`:
```
[root@node1 ~]# mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
```

# Phần 2: Cài đặt HAProxy bản 1.8
> ### Thực hiện trên tất cả các node
Cài đặt
```
yum install wget socat -y

wget http://cbs.centos.org/kojifiles/packages/haproxy/1.8.1/5.el7/x86_64/haproxy18-1.8.1-5.el7.x86_64.rpm 

yum install haproxy18-1.8.1-5.el7.x86_64.rpm -y
```

Tạo bản backup cho cấu hình mặc định và chỉnh sửa cấu hình HAproxy
```
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

Cấu hình HAProxy
```
echo 'global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen stats
    bind :8080
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics

listen galera
    bind 10.10.35.170:3306
    balance source
    mode tcp
    option tcpka
    option tcplog
    option clitcpka
    option srvtcpka
    timeout client 28801s
    timeout server 28801s
    option mysql-check user haproxy
    server node1 10.10.35.164:3306 check inter 5s fastinter 2s rise 3 fall 3
    server node2 10.10.35.165:3306 check inter 5s fastinter 2s rise 3 fall 3 backup
    server node3 10.10.35.166:3306 check inter 5s fastinter 2s rise 3 fall 3 backup' > /etc/haproxy/haproxy.cfg
```
**Trong đó:**
- `bind 10.10.35.170:3306` : Virtual IP

Cấu hình Log cho HAProxy
```
sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/g" /etc/rsyslog.conf
sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/g" /etc/rsyslog.conf
echo '$UDPServerAddress 127.0.0.1' >> /etc/rsyslog.conf

echo 'local2.*    /var/log/haproxy.log' > /etc/rsyslog.d/haproxy.conf

systemctl restart rsyslog
```

Bổ sung cấu hình cho phép kernel có thể binding tới IP VIP
```
echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf
```

Kiểm tra
```
sysctl -p

# Output
net.ipv4.ip_nonlocal_bind = 1
```

Tắt dịch vụ HAProxy
```
systemctl stop haproxy
systemctl disable haproxy
```

Tạo user `haproxy`, phục vụ plugin health check của HAProxy (`option mysql-check user haproxy`). -> Chỉ cẩn thực hiện trên 1 node. Vì Galera sẽ đồng bộ sang các node khác.
```
CREATE USER 'haproxy'@'node1';
CREATE USER 'haproxy'@'node2';
CREATE USER 'haproxy'@'node3';
CREATE USER 'haproxy'@'%';
```

# Phần 3: Triển khai Cluster Pacemaker
## Bước 1: Cài đặt Pacemaker corosyn
> ### Thực hiện trên cả 3 node
Cài đặt gói pacemaker pcs
```
yum -y install pacemaker pcs

systemctl start pcsd 
systemctl enable pcsd
```

Thiết lập mật khẩu user `hacluster`. Tại đây, ta đặt là `nhanhoa2020`
```
passwd hacluster
```

**Lưu ý:** Nhập chính xác và nhớ mật khẩu user `hacluster`, đồng bộ mật khẩu trên tất cả các node

## Bước 2: Tạo Cluster
> ### Thực hiện trên `node1`
Chứng thực cluster (Chỉ thực thiện trên cấu hình trên một node duy nhất, trong bài sẽ thực hiện trên `node1`), nhập chính xác tài khoản user `hacluster`
```
pcs cluster auth node1 node2 node3

Username: hacluster
Password: nhanhoa2020
```

OUTPUT
```
[root@node1 ~]# pcs cluster auth node1 node2 node3
Username: hacluster
Password:
node1: Authorized
node3: Authorized
node2: Authorized
```

Khởi tạo cấu hình cluster ban đầu
```
pcs cluster setup --name ha_cluster node1 node2 node3
```
OUTPUT
```
[root@node1 ~]# pcs cluster setup --name ha_cluster node1 node2 node3
Destroying cluster on nodes: node1, node2, node3...
node1: Stopping Cluster (pacemaker)...
node3: Stopping Cluster (pacemaker)...
node2: Stopping Cluster (pacemaker)...
node1: Successfully destroyed cluster
node3: Successfully destroyed cluster
node2: Successfully destroyed cluster

Sending 'pacemaker_remote authkey' to 'node1', 'node2', 'node3'
node1: successful distribution of the file 'pacemaker_remote authkey'
node3: successful distribution of the file 'pacemaker_remote authkey'
node2: successful distribution of the file 'pacemaker_remote authkey'
Sending cluster config files to the nodes...
node1: Succeeded
node2: Succeeded
node3: Succeeded

Synchronizing pcsd certificates on nodes node1, node2, node3...
node1: Success
node3: Success
node2: Success
Restarting pcsd on the nodes in order to reload the certificates...
node1: Success
node3: Success
node2: Success
```

**Lưu ý:**
- `ha_cluster`: Tên của cluster khởi tạo
- `node1`, `node2`, `node3`: Hostname các node thuộc cluster, yêu cầu khai báo trong `/etc/hosts`

Khởi động Cluster
```
pcs cluster start --all
```
OUTPUT
```
[root@node1 ~]# pcs cluster start --all
node1: Starting Cluster (corosync)...
node2: Starting Cluster (corosync)...
node3: Starting Cluster (corosync)...
node3: Starting Cluster (pacemaker)...
node1: Starting Cluster (pacemaker)...
node2: Starting Cluster (pacemaker)...
```

Cho phép cluster khởi động cùng OS
```
pcs cluster enable --all 
```
OUTPUT
```
[root@node1 ~]# pcs cluster enable --all
node1: Cluster Enabled
node2: Cluster Enabled
node3: Cluster Enabled
```

## Bước 3: Thiết lập Cluster
> ### Thực hiện trên `node1`
Bỏ qua cơ chế STONITH
```
pcs property set stonith-enabled=false
```

Cho phép Cluster chạy kể cả khi mất quorum
```
pcs property set no-quorum-policy=ignore
```

Hạn chế Resource trong cluster chuyển node sau khi Cluster khởi động lại
```
pcs property set default-resource-stickiness="INFINITY"
```

Kiểm tra thiết lập cluster
```
[root@node1 ~]# pcs property list 

Cluster Properties:
 cluster-infrastructure: corosync
 cluster-name: ha_cluster
 dc-version: 1.1.21-4.el7-f14e36fd43
 default-resource-stickiness: INFINITY
 have-watchdog: false
 no-quorum-policy: ignore
 stonith-enabled: false
```

Tạo Resource IP VIP Cluster
```
pcs resource create Virtual_IP ocf:heartbeat:IPaddr2 ip=10.10.35.170 cidr_netmask=24 op monitor interval=30s
```

Tạo Resource quản trị dịch vụ HAProxy
```
pcs resource create Loadbalancer_HaProxy systemd:haproxy op monitor timeout="5s" interval="5s"
```

Ràng buộc thứ tự khởi động dịch vụ, khởi động dịch vụ Virtual_IP sau đó khởi động dịch vụ Loadbalancer_HaProxy
```
pcs constraint order start Virtual_IP then Loadbalancer_HaProxy kind=Optional
```

Ràng buộc resource Virtual_IP phải khởi động cùng node với resource Loadbalancer_HaProxy
```
pcs constraint colocation add Virtual_IP Loadbalancer_HaProxy INFINITY
```

Kiểm tra trạng thái Cluster
```
[root@node1 ~]# pcs status

Cluster name: ha_cluster
Stack: corosync
Current DC: node3 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Tue Nov 10 11:43:15 2020
Last change: Tue Nov 10 11:43:02 2020 by root via cibadmin on node1

3 nodes configured
2 resources configured

Online: [ node1 node2 node3 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node2
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node2

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Kiểm tra cấu hình Resource
```
[root@node1 ~]# pcs resource show --full

 Resource: Virtual_IP (class=ocf provider=heartbeat type=IPaddr2)
  Attributes: cidr_netmask=24 ip=10.10.35.170
  Operations: monitor interval=30s (Virtual_IP-monitor-interval-30s)
              start interval=0s timeout=20s (Virtual_IP-start-interval-0s)
              stop interval=0s timeout=20s (Virtual_IP-stop-interval-0s)
 Resource: Loadbalancer_HaProxy (class=systemd type=haproxy)
  Operations: monitor interval=5s timeout=5s (Loadbalancer_HaProxy-monitor-interval-5s)
              start interval=0s timeout=100 (Loadbalancer_HaProxy-start-interval-0s)
              stop interval=0s timeout=100 (Loadbalancer_HaProxy-stop-interval-0s)
```

Kiểm tra ràng buộc trên resource
```
[root@node1 ~]# pcs constraint

Location Constraints:
Ordering Constraints:
  start Virtual_IP then start Loadbalancer_HaProxy (kind:Optional)
Colocation Constraints:
  Virtual_IP with Loadbalancer_HaProxy (score:INFINITY)
Ticket Constraints:
```

# Phần 4: Kiểm tra
## Kiểm tra trạng thái dịch vụ
Truy cập:
```
http://10.10.35.170:8080/stats
```

<img src="..\images\cluster\Screenshot_18.png">

Kết nối DB MariaDB thông qua IP VIP:
```
[root@node1 ~]# mysql -h 10.10.35.170 -u haproxy

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 118
Server version: 10.2.35-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

## Thử tắt `node1`
Truy cập `node1`, thực hiện tắt `node1`
```
init 0
```

Kiểm tra trạng thái Cluster, dễ thấy `node1` đã bị tắt. Dịch vụ Virtual_IP và Loadbalancer_HaProxy được chuyển sang `node2` tự động
```

```