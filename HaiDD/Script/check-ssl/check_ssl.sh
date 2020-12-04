#!/bin/bash

# So ngay con lai cua SSL thi se canh bao
DAYS=10

# Check thoi han SSL cac domain
input="/root/check_ssl/list_domain"
timestamp_now=`date +%s`
while IFS= read -r line
do  
    # In ra ten domain
    echo "$line"

    # Lay ngay het han cua chung chi SSL
    expired=`(echo | openssl s_client -servername $line -connect $line:443 2> /dev/null | openssl x509 -noout -enddate | cut -d "=" -f2)`

    # Tinh so ngay con lai cua chung chi SSL
    timestamp_expired=`(``date -d"$expired" +%s` - `date +%s`)`
    days_expired=timestamp_expired/60/60/24
    
    # Kiem tra thoi han
    if [$timestamp_expired <= 864000] > /dev/null 2>&1; then {
        echo "$line\t$days_expired" >> /root/check_ssl/log_report/`date -d"$timestamp_now" +%Y%m%d_%T`\.report
        return 1
    } else {
        return 0
    } fi
    
    

    expired=`date -d"$expired" +'%d-%m-%Y %T'`
    echo "$expired"
    echo "$timestamp_expired"
    echo  -e "\n"
done < "$input"



#--------#
expired=`(echo | openssl s_client -servername cloud365.vn -connect cloud365.vn:443 2> /dev/null | openssl x509 -noout -enddate)`
echo "$expired"

date -d $expired +'%d-%m-%Y

864000

#------#
