# Typescript (Text Session Recording)

Trên máy cài đặt Guacamole

Đường dẫn lưu record sẽ được quy định và thống nhất.

1. Tạo thư mục để lưu các record
    ```
    mkdir /opt/recording
    ```

2. Khai báo trong cài đặt Connection

    Tương tự như sau:

    <img src="https://i.imgur.com/TAFtyuX.png">

3. Khi sử dụng ta sẽ có các file lưu session tương tự như sau

    <img src="https://i.imgur.com/JkMq8fs.png">

4. Xem session: Lưu ý: cần đúng đuôi `.1`, `.2`, ...
    
    Ví dụ:
    ```
    scriptreplay 34.164.1.timing 34.164.1
    ```

Ta sẽ thấy lần lượt thao tác mà người sử dụng thực hiện trong session đó.