# Vận hành, giải quyết sự cố Rabbit Cluster

## Chuẩn bị môi trường
- [Cài đặt RabbitMQ Cluster 3 node](../Cluster/08-lab-cluster-3node-rabbitMQ.md)

# Case 1: Node xảy ra vấn đề
## Mô tả
Xảy ra trong trường hợp 1 node hoặc 2 node bị crash tiến trình, crash os hoặc phần cứng đòi hỏi khởi động lại OS, dịch vụ

## Chuẩn bị môi trường lab
Ta sẽ stop service rabbitMQ trên `node1`
```
[root@node1 ~]# systemctl stop rabbitmq-server
```

## Kiểm tra
Kiểm tra trên `node2` và `node3`:
```
# Node2
[root@node2 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node2
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node3,rabbit@node2]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node3,[]},{rabbit@node2,[]}]}]


# Node3
[root@node3 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node3
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node2,rabbit@node3]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node2,[]},{rabbit@node3,[]}]}]
```

Nhận thấy `node1` không hoạt động 
```
{running_nodes,[rabbit@node2,rabbit@node3]}
```

Hoặc trên giao diện web với IP là IP của 2 node còn hoạt động. ta sẽ thấy `node1` không hoạt động:

<img src="..\images\van_hanh\Screenshot_2.png">

## Cách giải quyết
Truy cập `node1`, khởi động lại dịch vụ:
```
systemctl restart rabbitmq-server
```

Khi khởi động lại service thành công, ta kiểm tra lại sẽ thấy `node1` trong cluster
```
# node2
[root@node2 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node2
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node1,rabbit@node3,rabbit@node2]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]},{rabbit@node3,[]},{rabbit@node2,[]}]}]

# node3
[root@node3 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node3
[{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
 {running_nodes,[rabbit@node1,rabbit@node2,rabbit@node3]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]},{rabbit@node2,[]},{rabbit@node3,[]}]}]
```

Trên giao diện web:

<img src="..\images\van_hanh\Screenshot_3.png">

## Lưu ý:
- Trong trường hợp cả 3 node đều down, ta phải bật node down cuối cùng lên trước. Các node sau thì không cần thứ tự.
    
    Ví dụ: Thứ tự down các node là: `node3` > `node1` > `node2`. Ta cần phải bật `node2` lên đầu tiên

- Trong trường hợp cả 3 node đều down nhưng không xác định được node nào tắt cuối cùng. Ta cần bật 1 node bất kỳ theo cách không an toàn để Cluster có thể hoạt động trở lại, giải quyết theo cách này có thể gây mất mát dữ liệu Queue, các node còn lại bật không cần thứ tự:
    ```
    # Câu lệnh
    rabbitmqctl force_boot
    systemctl start rabbitmq-server

    Ví dụ: Chọn node2 để thực hiện
    [root@node2 ~]# rabbitmqctl force_boot
    Forcing boot for Mnesia dir /var/lib/rabbitmq/mnesia/rabbit@node2

    [root@node2 ~]# systemctl start rabbitmq-server
    ```

# Case 2: Loại bỏ node khỏi Cluster
## Mô tả
Có 2 cách thực hiện:
- Cách 1: Tại node mong muốn được loại bỏ
- Cách 2: Tại 1 node bất kỳ trong cụm, loại bỏ node mong muốn

## Cách 1: Tại node mong muốn loại bỏ
- Tại node cần loại bỏ
    ```
    rabbitmqctl stop_app
    rabbitmqctl reset
    rabbitmqctl start_app
    rabbitmqctl cluster_status

    # Ví dụ: Ta loại bỏ node2
    [root@node2 ~]# rabbitmqctl stop_app
    Stopping rabbit application on node rabbit@node2
    [root@node2 ~]# rabbitmqctl reset
    Resetting node rabbit@node2
    [root@node2 ~]# rabbitmqctl start_app
    Starting node rabbit@node2
    [root@node2 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node2
    [{nodes,[{disc,[rabbit@node2]}]},
    {running_nodes,[rabbit@node2]},
    {cluster_name,<<"rabbit@node2">>},
    {partitions,[]},
    {alarms,[{rabbit@node2,[]}]}]
    ```

- Tại các node còn lại, kiểm tra sẽ thấy không còn node2 nữa
    ```
    # node1
    [root@node1 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node1
    [{nodes,[{disc,[rabbit@node1,rabbit@node3]}]},
    {running_nodes,[rabbit@node3,rabbit@node1]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node3,[]},{rabbit@node1,[]}]}]


    # node3
    [root@node3 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node3
    [{nodes,[{disc,[rabbit@node1,rabbit@node3]}]},
    {running_nodes,[rabbit@node1,rabbit@node3]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node1,[]},{rabbit@node3,[]}]}]
    ```

- Kiểm tra trên giao diện web

    <img src="..\images\van_hanh\Screenshot_4.png">

## Cách 2: 
- Truy cập node mong muốn loại bỏ, tắt dịch vụ. Không thể loại bỏ node với dịch vụ đang chạy
    ```
    rabbitmqctl stop_app

    # Ví dụ:
    [root@node2 ~]# rabbitmqctl stop_app
    Stopping rabbit application on node rabbit@node2
    ```

- Tại 1 node bất kỳ trong cụm, loại bỏ node mong muốn
    ```
    rabbitmqctl forget_cluster_node rabbit@node2

    # Ví dụ
    [root@node1 ~]# rabbitmqctl forget_cluster_node rabbit@node2
    Removing node rabbit@node2 from cluster
    ```

- Kiểm tra
    ```
    [root@node1 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node1
    [{nodes,[{disc,[rabbit@node1,rabbit@node3]}]},
    {running_nodes,[rabbit@node3,rabbit@node1]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node3,[]},{rabbit@node1,[]}]}]
    ```

- Quay lại node mong muốn loại bỏ, hiện tại đã không thể chạy lại dịch vụ, cần reset lại trạng thái cluster
    ```
    rabbitmqctl reset
    rabbitmqctl start_app
    rabbitmqctl cluster_status

    # Ví dụ
    [root@node2 ~]# rabbitmqctl reset
    Resetting node rabbit@node2
    [root@node2 ~]# rabbitmqctl start_app
    Starting node rabbit@node2
    [root@node2 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node2
    [{nodes,[{disc,[rabbit@node2]}]},
    {running_nodes,[rabbit@node2]},
    {cluster_name,<<"rabbit@node2">>},
    {partitions,[]},
    {alarms,[{rabbit@node2,[]}]}]
    ```

**Lưu ý:** Trong trường hợp quên tắt dịch vụ sẽ nhận thông báo
```
[root@node1 ~]# rabbitmqctl forget_cluster_node rabbit@node2
Removing node rabbit@node2 from cluster
Error: {failed_to_remove_node,rabbit@node2,
                            {active,"Mnesia is running",rabbit@node2}}
```

# Case 3: Bổ sung node vào Cluster
## Mô tả
- Thêm node vào cụm cluster RabbitMQ

## Cách thực hiện
- Truy cập node cần thêm vào cluster
    ```
    rabbitmqctl stop_app
    rabbitmqctl join_cluster rabbit@node1
    rabbitmqctl start_app
    rabbitmqctl cluster_status

    # Ví dụ: thêm node2 vào cụm cluster RabbitMQ

    [root@node2 ~]# rabbitmqctl stop_app
    Stopping rabbit application on node rabbit@node2
    [root@node2 ~]# rabbitmqctl join_cluster rabbit@node1
    Clustering node rabbit@node2 with rabbit@node1
    [root@node2 ~]# rabbitmqctl start_app
    Starting node rabbit@node2
    [root@node2 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node2
    [{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
    {running_nodes,[rabbit@node1,rabbit@node3,rabbit@node2]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node1,[]},{rabbit@node3,[]},{rabbit@node2,[]}]}]
    ```

- Kiểm tra trên các node khác
    ```
    # node1
    [root@node1 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node1
    [{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
    {running_nodes,[rabbit@node2,rabbit@node3,rabbit@node1]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node2,[]},{rabbit@node3,[]},{rabbit@node1,[]}]}]


    # node3
    [root@node3 ~]# rabbitmqctl cluster_status
    Cluster status of node rabbit@node3
    [{nodes,[{disc,[rabbit@node1,rabbit@node2,rabbit@node3]}]},
    {running_nodes,[rabbit@node2,rabbit@node1,rabbit@node3]},
    {cluster_name,<<"rabbit@node1">>},
    {partitions,[]},
    {alarms,[{rabbit@node2,[]},{rabbit@node1,[]},{rabbit@node3,[]}]}]
    ```

- Kiểm tra trên giao diện web

    <img src="..\images\van_hanh\Screenshot_5.png">

## Lưu ý:
- Khi join cluster, node join không được chạy dịch vụ, nếu chạy sẽ dẫn tới lỗi
- Có thể chọn 1 node bất kỳ trong cluster để join, không phụ thuộc vào node khởi tạo cluster

# Case 4: Khởi tạo lại Cluster
## Mô tả
- Trong trường hợp không thể khôi phục dịch vụ, chạy lại cluster
- Yêu cầu khởi tạo lại Cluster nhanh chóng

## Cách giải quyết
> ### Thực hiện trên tất cả các node trong Cluster
- Xóa bỏ dữ liệu cũ của cluster
    ```
    cd /var/lib/rabbitmq/mnesia/
    rm -rf *
    ```

- Loại bỏ tiến trình RabbitMQ
    ```
    # Kiểm tra tiến trình
    ps -ef | grep rabbitmq 

    # Loại bỏ
    pkill -KILL -u rabbitmq
    ```

- Khởi tạo lại tiến trình
    ```
    systemctl restart rabbitmq-server
    ```

- Kiểm tra lại dịch vụ
    ```
    systemctl status rabbitmq-server
    ```

- Kiểm tra danh sách user hiện có
    ```
    rabbitmqctl list_users
    ```

- Kiểm tra trạng thái Cluster
    ```
    rabbitmqctl cluster_status
    ```

- Làm mới Cluster hiện có
    ```
    rabbitmqctl reset
    ```

- Thực hiện join cluster theo [tài liệu](../Cluster/08-lab-cluster-3node-rabbitMQ.md)

**Lưu ý:**
- `Mnesia` là cơ sở dữ liệu phân tán, hỗ trợ sẵn multi-master thông qua phương thức Xác nhận hai pha. Hỗ trợ Erlang