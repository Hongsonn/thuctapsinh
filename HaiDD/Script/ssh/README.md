# Hướng dẫn sử dụng script

## Yêu cầu
- OS: CentOS hoặc Ubuntu
- Thực hiện với `sudo` hoặc `root`
- Đã cài wget
    CentOS
    ```
    yum -y install wget
    ```
    Ubuntu
    ```
    apt-get -y install wget
    ```

## Thực hiện
1. Tải script
    ```
    cd
    
    wget https://raw.githubusercontent.com/danghai1996/thuctapsinh/master/HaiDD/Script/ssh/denyIPssh.sh
    ```

2. Cấp quyền
    ```
    chmod +x denyIPssh.sh
    ```

3. Chạy scritp
    ```
    ./denyIPssh.sh
    ```