#!/bin/bash

# Sử dụng:
# Lưu script theo đường dẫn /opt/sshLoginMonitor_v2.sh
# Thêm dòng sau "/opt/sshLogin.sh" (bỏ dấu ngoặc kép) & vào file: /etc/ssh/sshrc (nếu chưa có thì tạo)
# Cấp quyền thực thi cho script: chmod +x /opt/sshLogin.sh


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# TODO:                                                                          #
# - Cảnh báo qua Slack                                                           #
# - Check IP login để chỉnh lại tin nhắn cảnh báo khi lấy thông tin từ ipinfo.io #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Điều kiện, thực thi lần lượt các lệnh
set -e;

# ID chat Telegram
USERID="-456008539"

# API Token bot
TOKEN="936053035:AAGbl5y7463f0BCCx4RjzpB3_eRhUUNfKKw"

TIMEOUT="20"

# URL gửi tin nhắn của bot
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

# Thời gian hệ thống
DATE_EXEC="$(date "+%d %b %Y %H:%M")"

# File temp
TMPFILE='/tmp/ipinfo.txt'
echo "" > $TMPFILE

if [ -n "$SSH_CLIENT" ]; then
    IP=$(echo $SSH_CLIENT | awk '{print $1}')
    PORT=$(echo $SSH_CLIENT | awk '{print $3}')
    HOSTNAME=$(hostname -f)
    IPADDR=$(echo $SSH_CONNECTION | awk '{print $3}')

    # Lấy các thông tin từ IP người truy cập theo trang ipinfo.io
    curl http://ipinfo.io/$IP -s -o $TMPFILE > /dev/null
    CITY=$(cat $TMPFILE | jq '.city' | sed 's/"//g') > /dev/null
    REGION=$(cat $TMPFILE | jq '.region' | sed 's/"//g') > /dev/null
    COUNTRY=$(cat $TMPFILE | jq '.country' | sed 's/"//g') > /dev/null
    ORG=$(cat $TMPFILE | jq '.org' | sed 's/"//g') > /dev/null

    # Nội dung cảnh báo
    TEXT=$(echo -e "Thời gian: $DATE_EXEC\nUser: ${USER} logged in to $HOSTNAME($IPADDR) \nFrom $IP - $ORG - $CITY, $REGION, $COUNTRY on port $PORT")

    # Gửi cảnh báo
    curl -s -X POST --max-time $TIMEOUT $URL -d "chat_id=$USERID" -d text="$TEXT" > /dev/null

    # Xóa file temp khi script thực hiện xong
    rm $TMPFILE
fi