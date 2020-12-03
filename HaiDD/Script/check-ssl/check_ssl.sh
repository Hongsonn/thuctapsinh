#!/bin/bash

# Check thoi han SSL cac domain
input="/root/check_ssl/list_domain"
timestamp_now=`date +%s`
while IFS= read -r line
do  
    echo "$line"
    expired=`(echo | openssl s_client -servername $line -connect $line:443 2> /dev/null | openssl x509 -noout -enddate | cut -d "=" -f2)`
    expired=`date -d"$expired" +'%d-%m-%Y %T'`
    
    # Tinh so ngay con lai cua chung chi SSL
    

    echo "$expired"
    echo  -e "\n"
done < "$input"




expired=`(echo | openssl s_client -servername cloud365.vn -connect cloud365.vn:443 2> /dev/null | openssl x509 -noout -enddate)`
echo "$expired"

date -d $expired +'%d-%m-%Y