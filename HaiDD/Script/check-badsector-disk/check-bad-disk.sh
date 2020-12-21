#!/bin/bash

# RD Team - HaiDD 12/2020

# ID chat Telegram
USERID=""

# API Token bot
TOKEN=""

# URL gửi tin nhắn của bot
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

# List disk
INPUT="/root/nhanhoa-scripts/scripts/check_bad_disk/list_disk"

# HOSTNAME
HOSTNAME=`hostname`

# Message report
TEXT=`echo -e "$HOSTNAME\n-------"`

while IFS= read -r line
do
    echo "$line"
    # Reallocated_Sector_Ct
    RSC=`smartctl -a /dev/$line | grep 'Reallocated_' | awk '{print $10}'`
    echo "$RSC"

    # Uncorrectable_Error_Cnt
    UEC=`smartctl -a /dev/$line | grep "Uncorrectable_" | awk '{print $10}'`
    echo "$UEC"

    # Pending_Sector_Count
    PSC=`smartctl -a /dev/$line | grep "Pending_" | awk '{print $10}'`
    echo "$PSC"
    
    # Power_On_Hours
    POH=`smartctl -a /dev/$line | grep 'Power_On_Hours' | awk '{print $10}'`

    if [ "$RSC" != '' ] > /dev/null 2>&1; then {
        if [ "$RSC" != '0' ] || [ "$UEC" != '0' ] || [ "$PSC" != '0' ] > /dev/null 2>&1; then {
            # Nội dung report
            TEXT=$(echo -e "$TEXT\n$line\nReallocated_Sector_Ct: $RSC\nPower_On_Hours: $POH\nUncorrectable_Error_Cnt: $UEC\nPending_Sector_Count: $PSC\n-------\n")
        } else {
            TEXT=$(echo -e "$TEXT\n$line\n-------\n")
        } fi
    } else {
        TEXT=$(echo -e "$TEXT\n$line\nỔ cài OS\n-------\n")
    } fi
done < "$INPUT"

# Gửi cảnh báo
curl  -s -X "POST" "$URL" -d "text=<code>$TEXT</code>" -d "chat_id=$USERID" -d "parse_mode=html" > /dev/null
