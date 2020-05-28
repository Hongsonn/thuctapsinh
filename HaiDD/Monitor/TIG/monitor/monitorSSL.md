Sử dụng plugin `inputs.x509_cert`

Import Dashboard: 11707
```conf
[[inputs.x509_cert]]
#   ## List certificate sources
   sources = ["/etc/ssl/certs/ssl-cert-snakeoil.pem",
                "https://thongke.dangdohai.xyz:443",
                "https://blog.cloud365.vn:443",
                "https://hocchudong.com:443",
                "https://kb.nhanhoa.com:443",
                "https://netbox1.dungdb.xyz:443"]
    insecure_skip_verify = true
```
