# Keepalived

Đối với những mô hình dịch vụ cần đảm bảo tính sẵn sàng cao (High Availability – HA), thì việc hệ thống bị down là không thể chấp nhận được. Hiện có rất nhiều phần mềm, giải pháp để đảm bảo tính HA cho các hệ thống nhưng mình sẽ giới thiệu phần mềm đơn giản nhất là Keepalived với tính năng tự động chuyển đổi Virtual IP (VIP) giữa các máy chủ theo mô hình Active/Passive.

# 1. Keepalived là gì ?
Keepalived là một chương trình dịch vụ trên Linux cung cấp khả năng tạo độ sẵn sàng cao (High Availability) cho hệ thống dịch vụ và khả năng cân bằng tải (Load Balancing) đơn giản. Với sự gọn nhẹ, tối ưu trong dịch vụ HA của Keepalived mang đến cho quản trị viên một giải pháp Active-Backup dịch vụ rất tốt. Thế nhưng tính năng Load Balancing của Keepalived thì khá là chán, không mạnh mẽ, tuỳ biến linh hoạt như các giải pháp khác là Nginx hay HAProxy được.

Chính vì vậy khi xài Keepalived người ta thường chỉ sử dụng tính năng HA IP Failover của nó, chứ ít đả động đến tính năng cân bằng tải. Thế nên trong bài viết này cũng sẽ chỉ tập trung vào năng lực chính HA của Keepalived.

- Keepalived cung cấp các bộ thư viện (framework) cho 2 chức năng chính là: cân bằng tải (load balancing) cùng cơ chế health checking và độ sẵn sàng cao cho hệ thống (high availability) với VRRP
- Tính năng cân bằng tải sử dụng Linux Virtual Server (IPVS) module kernel trên Linux.
- Tính năng kiểm tra tình trạng sức khoẻ của các máy chủ backend cũng khá linh động giúp duy trì được pool server dịch vụ nào còn sống để cân bằng tải tốt.
- Tính sẵn sàng cao (HA) sẽ được Keepalived sử dụng kĩ thuật giao thức khá nổi tiếng VRRP (Virtual Redundancy Routing Protocol). VRRP được ứng dụng nhiều trong mô hình router failover

<img src="..\images\keepalive\Screenshot_1.png">

Tóm tắt lại thì Keepalived cho bạn 2 chức năng:
- **Cân bằng tải**: với chức năng health checking (kiểm tra tình trạng sức khoẻ) của các máy chủ trong mô hình HA và các phương thức cân bằng tải xuống server backend.
- **Tạo độ sẵn sàng cao (High Avaiability)** : chức năng VRRP đảm nhận quản lý khả năng chịu lỗi của cụm server (Failover) với Virtual IP.

# 2. Keepalived Failover IP hoạt động như thế nào ?
Keepalived sẽ gom nhóm các máy chủ dịch vụ nào tham gia cụm HA, khởi tạo một Virtual Server đại diện cho một nhóm thiết bị đó với một Virtual IP (VIP) và một địa chỉ MAC vật lý của máy chủ dịch vụ đang giữ Virtual IP đó. Vào mỗi thời điểm nhất định, chỉ có một server dịch vụ dùng địa chỉ MAC này tương ứng Virtual IP. Khi có ARP request gửi tới virtual IP thì server dịch vụ đó sẽ trả về địa chỉ MAC này.

Các máy chủ dịch vụ sử dụng chung VIP phải liên lạc với nhau bằng địa chỉ multicast 224.0.0.18 của giao thức VRRP. Các máy chủ sẽ có độ ưu tiên (priority) trong khoảng từ 1 – 254, và máy chủ nào có độ ưu tiên cao nhất sẽ thành Master, các máy chủ còn lại sẽ thành các Slave/Backup, hoạt động ở chế độ chờ.

<img src="..\images\keepalive\Screenshot_2.png">

Như đã nói ở trên, các server dịch vụ dùng chung Virtual IP sẽ có 2 trạng thái là MASTER/ACTIVE và BACKUP/SLAVE. Cơ chế failover được xử lý bởi giao thức VRRP, khi khởi động dịch vụ, toàn bộ các server cấu hình dùng chung VIP sẽ gia nhập vào một nhóm multicast. Nhóm multicast này dùng để gởi/nhận các gói tin quảng bá VRRP. Các server sẽ quảng bá độ ưu tiên (priority) của mình, server với độ ưu tiên cao nhất sẽ được chọn làm MASTER. Một khi nhóm đã có 1 MASTER thì MASTER này sẽ chịu trách nhiệm gởi các gói tin quảng bá VRRP định kỳ cho nhóm multicast.

<img src="..\images\keepalive\Screenshot_3.png">

Nếu vì một sự cố gì đó mà các server BACKUP không nhận được các gói tin quảng bá từ MASTER trong một khoảng thời gian nhất định thì cả nhóm sẽ bầu ra một MASTER mới. MASTER mới này sẽ tiếp quản địa chỉ VIP của nhóm và gởi các gói tin ARP báo là nó đang giữ địa chỉ VIP này. Khi MASTER cũ hoạt động bình thường trở lại thì server này có thể lại trở thành MASTER hoặc trở thành BACKUP tùy theo cấu hình độ ưu tiên của các router.

**Khi Keepalived chạy trên Linux**

Keepalived được phát triển bởi ngôn ngữ C, tiến trình dịch vụ của Keepalived khi khởi chạy trên Linux sẽ tạo ra 3 tiến trình cơ bản gồm:

- Một tiến trình cha có tên gọi là `watchdog`, sản sinh ra 2 tiến trình con kế tiếp. Tiến trình cha sẽ quản lý theo dõi hoạt động của tiến trình con.
- Hai tiến trình con:
    - một chịu trách nhiệm cho VRRP framework
    - một chịu trách nhiệm cho health checking (kiểm tra tình trạng sức khoẻ).

```
Keepalived <-- Parent process monitoring children
\_ Keepalived <-- VRRP child
\_ Keepalived <-- Healthchecking child
```

# 3. Các thành phần Linux Kernel mà Keepalived sử dụng
Keepalived sử dụng 4 module kernel Linux chính sau :

- **LVS Framework**: dùng để giao tiếp sockets.
- **Netfilter Framework**: hỗ trợ hoạt động IP Virtual Server (IPVS) NAT và Masquerading.
- **Netlink Interface**: điều khiển thêm/xoá VRRP Virtual IP trên card mạng.
- **Multicast**: VRRP advertisement packet được gửi đến lớp địa chỉ mạng VRRP Multicast (224.0.0.18)

# 4. Kiến trúc chương trình Keepalived
<img src="..\images\keepalive\Screenshot_4.png">

Ta quan tâm các thành phần chính sau:

## 4.1. WatchDog
Thư viện framework Watchdog sẽ sản sinh ra các tiến trình con cho hoạt động giám sát tình trạng (VRRP và Healthchecking). Watchdog sẽ giao tiếp với các tiến trình con qua unix domain socket trên Linux để quản lý các tiến trình con.

## 4.2. Checkers
Đây là một trong những tính năng chính của Keepalived. Checkers sẽ đảm nhận nhiệm vụ kiểm tra tình trạng sức khoẻ của server backup khác trong mô hình mạng Load Balancing.

## 4.3. VRRP Stack
Đây là tính năng quan trọng nhất của dịch vụ Keepalived. VRRP (Virtual Router Redundancy Protocol) . Một số đặc điểm của VRRP, hiểu cho khái niệm server thay router:
- VRRP tạo ra một gateway dự phòng từ một nhóm các server. Node active được gọI là master server, tất cả các server còn lạI đều trong trạng thái backup. Server master là server có độ ưu tiên cao nhất trong nhóm VRRP.
- Chỉ số nhóm của VRRP thay đổI từ 0 đến 255; độ ưu tiên của router thay đổI từ 1 cho đến 254 (254 là cao nhất, mặc định là 100).
- Các gói tin quảng bá của VRRP được gửi mỗi chu kỳ một giây. Các server backup có thể học các chu kỳ quảng bá từ server master.
- Nếu có server nào có độ ưu tiên cao hơn độ ưu tiên của server master thì server đó sẽ chiếm quyền.
- VRRP dùng địa chỉ multicast 224.0.0.18, dùng giao thức IP.

## 4.4. SMTP
Dùng giao thức SMTP để thực hiện gửi email, hỗ trợ công việc quản trị.

## 4.5. System Call
Keepalived cho phép bạn khởi chạy các script kịch bản hệ thống. Thường dùng cho hoạt động kiểm tra dạng MISC. Đối với VRRP framework, thư viện này cho phép chạy script kịch bản ngoài trong quá trình chuyển đổi trạng thái của giao thức.

