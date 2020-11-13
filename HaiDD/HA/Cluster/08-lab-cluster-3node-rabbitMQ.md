# Cấu hình Rabbit Cluster trên CentOS-7

## Phân hoạch

<img src="..\images\cluster\Screenshot_16.png">

# Chuẩn bị
### Tại node1
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
File `/etc/hosts` sau khi cấu hình:
```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.10.35.164 node1
10.10.35.165 node2
10.10.35.166 node3
```

Cài đặt Erlang, các gói phụ trợ
```
yum -y install epel-release
yum update -y
yum -y install erlang socat wget
```

### Tại node2
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

Cài đặt Erlang, các gói phụ trợ
```
yum -y install epel-release
yum update -y
yum -y install erlang socat wget
```

### Tại node3
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

Cài đặt Erlang, các gói phụ trợ
```
yum -y install epel-release
yum update -y
yum -y install erlang socat wget
```

# Cài đặt, Cấu hình RabbitMQ
## Thực hiện trên tất cả các node
Cài đặt RabbitMQ
```
wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.10/rabbitmq-server-3.6.10-1.el7.noarch.rpm

rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc

rpm -Uvh rabbitmq-server-3.6.10-1.el7.noarch.rpm
```

Chạy dịch vụ
```
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl status rabbitmq-server
```

## Tại `node1`
Kiểm tra trạng thái node
```
[root@node1 ~]# rabbitmqctl status|grep rabbit

Status of node rabbit@node1
     [{rabbit,"RabbitMQ","3.6.10"},
      {rabbit_common,
          "Modules shared by rabbitmq-server and rabbitmq-erlang-client",
```

Tạo User cho App (Portal), phân quyền: `user/pass: admin/portal123`
```
rabbitmqctl add_user admin portal123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl add_vhost admin_vhost
rabbitmqctl set_permissions -p admin_vhost admin ".*" ".*" ".*"
```

Copy file `/var/lib/rabbitmq/.erlang.cookie` từ `node1` sang các node còn lại. (Có nhập password)
```
scp /var/lib/rabbitmq/.erlang.cookie root@node2:/var/lib/rabbitmq/.erlang.cookie

scp /var/lib/rabbitmq/.erlang.cookie root@node3:/var/lib/rabbitmq/.erlang.cookie
```

Cấu hình policy HA Rabbit Cluster
```
rabbitmqctl -p admin_vhost set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}'
```

Kiểm tra trạng thái cluster
```
[root@node1 ~]# rabbitmqctl cluster_status

Cluster status of node rabbit@node1
[{nodes,[{disc,[rabbit@node1]}]},
 {running_nodes,[rabbit@node1]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]}]}]
```

Khởi chạy App
```
[root@node1 ~]# rabbitmqctl start_app

Starting node rabbit@node1
```

Kiểm tra trạng thái cluster
```
[root@node1 ~]# rabbitmqctl cluster_status

Cluster status of node rabbit@node1
[{nodes,[{disc,[rabbit@node1]}]},
 {running_nodes,[rabbit@node1]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]}]}]
```

## Tại `node2`
Phân quyền file `/var/lib/rabbitmq/.erlang.cookie`
```
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
```

Khởi động lại dịch vụ
```
systemctl restart rabbitmq-server.service
```

Join cluster `node1`
```
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
```

## Tại `node3`
Phân quyền file `/var/lib/rabbitmq/.erlang.cookie`
```
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
```

Khởi động lại dịch vụ
```
systemctl restart rabbitmq-server.service
```

Join cluster `node1`
```
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
```

## Kiểm tra trên tất cả các node
```
# Node1
[root@node1 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node1
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node3,rabbit@node2,rabbit@node1]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node3,[]},{rabbit@node2,[]},{rabbit@node1,[]}]}]

# Node2
[root@node2 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node2
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node3,rabbit@node1,rabbit@node2]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node3,[]},{rabbit@node1,[]},{rabbit@node2,[]}]}]

# Node3
[root@node3 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node3
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node1,rabbit@node2,rabbit@node3]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]},{rabbit@node2,[]},{rabbit@node3,[]}]}]
```

# Kích hoạt plugin rabbit management
> ## Thực hiện trên tất cả các node
```
rabbitmq-plugins enable rabbitmq_management

chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
```

# Giao diện web của RabbitMQ
```
http://<địa_chỉ_IP_node>:15672/
```

Thông tin đăng nhập đã tạo ở trên
- user: `admin`
- password: `portal123`

<img src="..\images\cluster\Screenshot_24.png">

