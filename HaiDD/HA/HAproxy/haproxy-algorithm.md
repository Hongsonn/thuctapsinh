# Một số thuật toán trong HAProxy

# 1. Round Robin
Là thuật toán luân chuẩn theo vòng. Các server sẽ được sử dụng lần lượt theo vòng, phụ thuộc vào giá trị trọng số của nó. roundrobin là thuật toán được sử dụng mặc định load balancing khi không có thuật toán nào được chỉ định.

```
    backend web-backend
        option httplog
        option forwardfor
        server web1 192.168.1.110:8080 check
        server web2 192.168.1.111:8080 check
        server web3 192.168.1.112:8080 check
```

Dựa vào khả năng xử lý của từng server, chúng ta sẽ thay đổi giá trị trọng số của từng server để phân phối tải đến các server khác nhau. Sử dụng tham số `weight` để thay đổi trọng số. Tỷ lệ tải của các server sẽ tỷ lệ thuận trọng số của chúng so với tổng trọng số của tất cả server. Vì vậy mà server nào có trọng số càng cao, thì yêu cầu tải lên nó cũng sẽ cao. Ví dụ cân bằng tải khi thiết lập `weight`

```
    backend web-backend
        balance  roundrobin
        option httplog
        option forwardfor
        server web1 192.168.1.110:8080 check weight 2
        server web2 192.168.1.111:8080 check weight 2
        server web3 192.168.1.112:8080 check weight 1
```

Khi đó mỗi 05 request, 2 request đầu tiên sẽ được chuyển tiếp lần lượt đến server web1 và web2, 3 request sau sẽ thực hiện chuyển tiếp lần lượt đến server web1, web2 và web3.

Mặc định weight có giá trị là 1, giá trị tối đa của weight là 256. Nếu server giá trị weight là 0, khi đó nó sẽ không tham gia vào cụm server trong load balancing.

# 2. Leastconn
Đây là thuật toán dựa trên tính toán số lượng kết nối để thực hiện cân bằng tải cho server, nó sẽ tự động lựa chọn server với số lượng kết nối đang hoạt động là nhỏ nhất, để lượng connection giữa các server là tương đương nhau.

Thuật toán này khắc phục được tình trạng một số server có lượng connection rất lớn (do duy trì trạng thái connection), trong khi một số server khác thì lượng tải hay connection thấp.

```
    backend web-backend
        leastconn
        option httplog
        option forwardfor
        server web1 192.168.1.110:8080 check
        server web2 192.168.1.111:8080 check
        server web3 192.168.1.112:8080 check
```

Thuật toán này hoạt động tốt khi mà hiệu suất và khả năng tải của các server là tương đương nhau.

