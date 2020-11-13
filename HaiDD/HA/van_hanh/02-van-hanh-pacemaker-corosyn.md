# Tài liệu vận hành Pacemaker corosync

# PCS command
Pacemaker cung cấp `pcs` command như một công cụ để quản trị pacemaker, corosync

`pcs` gồm các subcommand sau:
- `cluster`: Quản trị tham số cluster, node.
- `resource`: Quản trị tài nguyên thuộc cluster.
- `stonith`: Quản trị cấu hình liên quan tới cơ chế fencing các thiết bị.
- `constraint`: Quản trị ràng buộc trên các tài nguyên
- `property`: Quản trị tham số mặc định của pacemaker
- `status`: Trạng thái tổng quan trên cluster, các resource

# Vận hành cluster
## 1. Thao tác trạng thái Cluster
- Ngừng hoạt động trên 1 node
    ```
    pcs cluster stop <node ..>
    ```

- Ngừng hoạt động cả cluster
    ```
    pcs cluster stop --all
    ```

- Không cho phép node khởi động cùng OS
    ```
    pcs cluster disable <node ..>
    ```

- Không cho phép cluster khởi động cùng OS
    ```
    pcs cluster disable --all
    ```

## 2. Bổ sung node vào Cluster
Ví dụ:
```
node1   10.10.35.164
node2   10.10.35.165
node3   10.10.35.166

Cluster 3 node đang chạy HAProxy Pacemaker Cluster
- Cluster Galera MariaDB
- Web wordpress với LAMP
```
### Tại node mong muốn bổ sung vào Cluster
```
node4   10.10.35.167
```
- Cài đặt đầy đủ, đồng bộ các dịch vụ giống các node thuộc Cluster:
    - Galera Mariadb Cluster: Cài đặt, Add thêm node vào Galera cluster
    - Cài đặt LAMP stack
    - Copy source code Wordpress sang node mới: với LAMP stack
    - Cài đặt HAProxy. Cấu hình giống 3 node trước đó. Bổ sung thêm cấu hình node mới
    - Cài đặt Pacemaker

- Đặt mật khẩu cho user `hacluster` giống các node thuộc cluster:
    ```
    passwd hacluster
    ```

- Khởi động dịch vụ
    ```
    systemctl start pcsd.service
    systemctl enable pcsd.service
    ```

### Tại node thuộc cluster
- Xác thực node mới:
    ```
    [root@node1 ~]# pcs cluster auth node4
    Username: hacluster
    Password:
    node4: Authorized
    ```

- Bổ sung node vào cluster:
    ```
    [root@node1 ~]# pcs cluster node add node4
    Disabling SBD service...
    node4: sbd disabled
    Sending remote node configuration files to 'node4'
    node4: successful distribution of the file 'pacemaker_remote authkey'
    node1: Corosync updated
    node2: Corosync updated
    node3: Corosync updated
    Setting up corosync...
    node4: Succeeded
    Synchronizing pcsd certificates on nodes node4...
    node4: Success
    Restarting pcsd on the nodes in order to reload the certificates...
    node4: Success
    ```

- Khởi động node vừa join
    ```
    pcs cluster start node4
    pcs cluster enable node4
    ```

### Kiểm tra
Kiểm tra trên các node:
```
[root@node1 ~]# pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: node1 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Thu Nov 12 16:43:51 2020
Last change: Thu Nov 12 16:37:53 2020 by hacluster via crmd on node1

4 nodes configured
2 resources configured

Online: [ node1 node2 node3 node4 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node1
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Trên giao diện web: Ta thấy node 4 cũng đã được thêm vào

<img src="..\images\van_hanh\Screenshot_1.png">

## 3. Loại bỏ node khỏi Cluster
Tại node thuộc cluster (không phải node muốn loại bỏ)
```
pcs cluster node remove <node muốn loại bỏ>
```

## 4. Di chuyển resource khỏi node
Kiểm tra các resource hiện có trong Cluster:
```
[root@node1 ~]# pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: node1 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Thu Nov 12 17:00:37 2020
Last change: Thu Nov 12 16:55:32 2020 by hacluster via crmd on node1

4 nodes configured
2 resources configured

Online: [ node1 node2 node3 node4 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node1
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Ta sẽ thực hiện chuyển resource `Virtual_IP` từ `node1` sang `node4`

- Tạo ràng buộc di chuyển. Câu lệnh dưới đây không thực sự di chuyển resource mà tạo ràng buộc cho Resource phải tới node chỉ định khi khởi động lại hoặc xảy ra lỗi
    ```
    pcs resource move Virtual_IP node4
    ```

- Kiểm tra, tai thấy ràng buộc: `Resource: Virtual_IP Enabled on: node4`
    ```
    [root@node1 ~]# pcs constraint
    Location Constraints:
    Resource: Virtual_IP
        Enabled on: node4 (score:INFINITY) (role: Started)
    Ordering Constraints:
    start Virtual_IP then start Loadbalancer_HaProxy (kind:Optional)
    Colocation Constraints:
    Virtual_IP with Loadbalancer_HaProxy (score:INFINITY)
    Ticket Constraints:
    ```

- Khởi động lại resource
    ```
    pcs resource ban Virtual_IP
    ```

- Kiểm tra trạng thái mới và IP trên node 4:
    ```
    [root@node1 ~]# pcs status
    Cluster name: ha_cluster
    Stack: corosync
    Current DC: node1 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
    Last updated: Thu Nov 12 17:37:56 2020
    Last change: Thu Nov 12 17:37:52 2020 by root via crm_resource on node1

    4 nodes configured
    2 resources configured

    Online: [ node1 node2 node3 node4 ]

    Full list of resources:

    Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node4
    Loadbalancer_HaProxy   (systemd:haproxy):      Starting node4

    Daemon Status:
    corosync: active/enabled
    pacemaker: active/enabled
    pcsd: active/enabled
    ```
    IP trên node4:
    ```
    [root@node4 ~]# ip a
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
        valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host
        valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 52:54:00:e3:95:09 brd ff:ff:ff:ff:ff:ff
        inet 10.10.35.167/24 brd 10.10.35.255 scope global noprefixroute eth0
        valid_lft forever preferred_lft forever
        inet 10.10.35.170/24 brd 10.10.35.255 scope global secondary eth0
        valid_lft forever preferred_lft forever
        inet6 fe80::5054:ff:fee3:9509/64 scope link noprefixroute
        valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 52:54:00:35:29:02 brd ff:ff:ff:ff:ff:ff
        inet 10.10.34.167/24 brd 10.10.34.255 scope global noprefixroute eth1
        valid_lft forever preferred_lft forever
        inet6 fe80::9a3f:daf3:166:2ed6/64 scope link noprefixroute
        valid_lft forever preferred_lft forever
    ```

- Loại bỏ ràng buộc tạm thời để resource trở lại bình thường
    ```
    pcs resource clear Virtual_IP
    ```

## 5. Ngừng dịch vụ tại 1 node chỉ định
Trạng thái Cluster
```
[root@node1 ~]# pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: node1 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Thu Nov 12 17:43:34 2020
Last change: Thu Nov 12 17:42:19 2020 by root via crm_resource on node1

4 nodes configured
2 resources configured

Online: [ node1 node2 node3 node4 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node2
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node2

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Ta thấy, ở đây resource `Virtual_IP` đang started trên `node2`. Ta sẽ thực hiện ngừng dịch vụ `Virtual_IP` này trên `node2` để thực hiện bảo trì, nâng cấp:
```
pcs resource ban Virtual_IP node2
```

Kết quả sau khi thực hiện:
```
[root@node1 ~]# pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: node1 (version 1.1.21-4.el7-f14e36fd43) - partition with quorum
Last updated: Fri Nov 13 09:07:43 2020
Last change: Fri Nov 13 09:07:38 2020 by root via crm_resource on node1

4 nodes configured
2 resources configured

Online: [ node1 node2 node3 node4 ]

Full list of resources:

 Virtual_IP     (ocf::heartbeat:IPaddr2):       Started node1
 Loadbalancer_HaProxy   (systemd:haproxy):      Started node1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

Kiểm tra constraint, ta sẽ thấy `node2` đã disabled resource `Virtual_IP`
```
[root@node1 ~]# pcs constraint
Location Constraints:
  Resource: Virtual_IP
    Disabled on: node2 (score:-INFINITY) (role: Started)
Ordering Constraints:
  start Virtual_IP then start Loadbalancer_HaProxy (kind:Optional)
Colocation Constraints:
  Virtual_IP with Loadbalancer_HaProxy (score:INFINITY)
Ticket Constraints:
```

Cho phép dịch vụ hoạt động trở lại:
```
pcs resource clear Virtual_IP
```

Kiểm tra lại constraint:
```
[root@node1 ~]# pcs constraint
Location Constraints:
Ordering Constraints:
  start Virtual_IP then start Loadbalancer_HaProxy (kind:Optional)
Colocation Constraints:
  Virtual_IP with Loadbalancer_HaProxy (score:INFINITY)
Ticket Constraints:
```

## 6. Khởi động lại resource
```
pcs resource restart <Resource id>
```

## 7. Xóa resource
```
pcs resource delete <Resource id>
```

## 8. Lỗi resource
Hiện tượng
```
[root@node2 ~]# pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: node1 (version 1.1.19-8.el7_6.2-c3c624ea3d) - partition with quorum
Last updated: Wed Jan 23 23:17:26 2019
Last change: Wed Jan 23 23:14:28 2019 by root via cibadmin on node1

3 nodes configured
11 resources configured

Online: [ node1 node2 node3 ]

Full list of resources:

Clone Set: Virtual_IP-clone [Virtual_IP] (unique)
    Virtual_IP:0       (ocf::heartbeat:IPaddr2):       Started node2
    Virtual_IP:1       (ocf::heartbeat:IPaddr2):       Started node2
    Virtual_IP:2       (ocf::heartbeat:IPaddr2):       Started node2
Clone Set: Web_Cluster-clone [Web_Cluster] (unique)
    Web_Cluster:0      (ocf::heartbeat:apache):        Started node3
    Web_Cluster:1      (ocf::heartbeat:apache):        Stopped
    Web_Cluster:2      (ocf::heartbeat:apache):        Started node2
Load_Balancer  (ocf::heartbeat:nginx): Started node2
Clone Set: Supervisor_Service-clone [Supervisor_Service] (unique)
    Supervisor_Service:0       (systemd:supervisord):  Started node2
    Supervisor_Service:1       (systemd:supervisord):  Started node3
    Supervisor_Service:2       (systemd:supervisord):  FAILED node1 (blocked)
Celerybeat     (ocf::heartbeat:celerybeat):    Started node2 (Monitoring)
```

Thực hiện cleanup resource, trạng thái resource sẽ trở lại bình thường
```
pcs resource cleanup Supervisor_Service-clone
```

## 9. Di chuyển IP VIP
- IP VIP cấu hình dạng clone nên không thể di chuyển theo cách thông thường
- Ta sẽ di chuyển dịch vụ có ràng buộc với IP VIP, để pacemaker di chuyển IP VIP theo tài nguyên ràng buộc. Trong mô hình HA portal, ta sẽ di chuyển dịch vụ Load_Balancer (ràng buộc IP VIP (Virtual_IP) luôn hoat động trên cùng node với Nginx(Load_Balancer)).