#!/bin/bash

# ID chat Telegram
USERID=""

# API Token bot
TOKEN=""

# List disk
INPUT="/root/nhanhoa-scripts/scripts/check_bad_disk/list_disk"

# HOSTNAME
HOSTNAME=`hostname`

# Message report
TEXT=`echo -e "$HOSTNAME"`

while IFS= read -r line
do
    echo "$line"
    RE_SEC_VALUE=`smartctl -a /dev/$line | grep 'Reallocated_Sector_Ct' | awk '{print $10}'`
    if [$RE_SEC_VALUE > 0] > /dev/null 2>&1; then {
        POH=`smartctl -a /dev/$line | grep 'Power_On_Hours' | awk '{print $10}'`
        # Nội dung report
        TEXT=$(echo -e "$TEXT\n$line\tReallocated_Sector_Ct: $RE_SEC_VALUE\tPower_On_Hours: $POH")
    } else {
        POH=0
    } fi
    echo "$RE_SEC_VALUE"
done < "$INPUT"
