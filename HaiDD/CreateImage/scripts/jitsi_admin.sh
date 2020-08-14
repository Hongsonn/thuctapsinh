#!/bin/bash
#ThaoNV
new_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/nginx/sites-available/10.10.30.188.conf
mv /etc/nginx/sites-available/10.10.30.188.conf /etc/nginx/sites-available/10.10.30.179.conf
ln -s /etc/nginx/sites-available/10.10.30.179.conf /etc/nginx/sites-enabled/10.10.30.179.conf
rm -f /etc/nginx/sites-enabled/10.10.30.188.conf

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/jitsi/meet/10.10.30.179.key -out /etc/jitsi/meet/10.10.30.179.crt << EOF





10.10.30.179

EOF

sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/turnserver.conf

sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/jitsi/jicofo/config
sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/jitsi/jicofo/sip-communicator.properties
sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/jitsi/meet/10.10.30.188-config.js
mv /etc/jitsi/meet/10.10.30.188-config.js /etc/jitsi/meet/10.10.30.179-config.js
sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/jitsi/videobridge/config
sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/jitsi/videobridge/sip-communicator.properties

sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/prosody/conf.avail/10.10.30.188.cfg.lua
mv /etc/prosody/conf.avail/10.10.30.188.cfg.lua /etc/prosody/conf.avail/10.10.30.179.cfg.lua
ln -s /etc/prosody/conf.avail/10.10.30.179.cfg.lua /etc/prosody/conf.d/10.10.30.179.cfg.lua
rm -f /etc/prosody/conf.d/10.10.30.188.cfg.lua

rm -rf /var/lib/prosody/*
rm -f /etc/prosody/certs/*.10.10.30.188.*
rm -f /etc/prosody/certs/10.10.30.188.*


prosodyctl cert generate 10.10.30.179 <<EOF







EOF

prosodyctl cert generate auth.10.10.30.179 <<EOF







EOF

prosodyctl register focus auth.10.10.30.179 eJ6h0GF1

ln -s /var/lib/prosody/10.10.30.179.crt /etc/prosody/certs/10.10.30.179.crt
ln -s /var/lib/prosody/10.10.30.179.key /etc/prosody/certs/10.10.30.179.key
ln -s /var/lib/prosody/auth.10.10.30.179.crt /etc/prosody/certs/auth.10.10.30.179.crt
ln -s /var/lib/prosody/auth.10.10.30.179.key /etc/prosody/certs/auth.10.10.30.179.key

ln -s /var/lib/prosody/auth.10.10.30.179.crt /usr/local/share/ca-certificates/auth.10.10.30.179.crt

rm -f /usr/local/share/ca-certificates/auth.10.10.30.188.crt
rm -f /etc/jitsi/meet/10.10.30.188.*

update-ca-certificates -f

echo "jitsi-videobridge jitsi-videobridge/jvb-hostname string 10.10.30.179" | debconf-set-selections
echo "jitsi-meet jitsi-meet/jvb-hostname string 10.10.30.179" | debconf-set-selections

prosodyctl register jvb auth.10.10.30.179 q@Iyc0G#

cd /opt/
source env/bin/activate
cd /opt/NH-Jitsi/
python manage.py update_domain --settings=project.settings.thanhnb02
sed -Ei "s|10.10.30.188|10.10.30.179|g" /etc/nginx/sites-available/nmeet-admin

systemctl stop nginx
systemctl stop jitsi-videobridge2
systemctl stop jicofo
prosodyctl stop
systemctl start nginx
prosodyctl start
systemctl start jitsi-videobridge2
systemctl start jicofo