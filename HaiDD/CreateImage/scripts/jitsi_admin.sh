#!/bin/bash

# Script change domain Jitsi

NEW_DOMAIN=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Get old, new domain
OLD_DOMAIN=$(debconf-show jitsi-meet-web-config | grep jitsi-meet/jvb-hostname | awk -F" " '{print $NF}')


#Stop all processes
systemctl stop nginx
systemctl stop jitsi-*
systemctl stop jicofo
prosodyctl stop

# Nginx
nginx_enabled=/etc/nginx/sites-enabled/$OLD_DOMAIN.conf
nginx_avail=/etc/nginx/sites-available/$OLD_DOMAIN.conf

if [ -f "$nginx_enabled" ]; then
    rm -rf $nginx_enabled
else
        echo "Nginx config is not existed"
        exit 1
fi

if [ -f "$nginx_avail" ]; then
    sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" $nginx_avail
        mv $nginx_avail /etc/nginx/sites-available/$NEW_DOMAIN.conf
        ln -s /etc/nginx/sites-available/$NEW_DOMAIN.conf /etc/nginx/sites-enabled/$NEW_DOMAIN.conf
else
        echo "Nginx config is not existed"
        exit 1
fi


# Jitsi
sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/jitsi/jicofo/config
sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/jitsi/jicofo/sip-communicator.properties

sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/jitsi/meet/$OLD_DOMAIN-config.js
mv /etc/jitsi/meet/$OLD_DOMAIN-config.js /etc/jitsi/meet/$NEW_DOMAIN-config.js

mv /etc/jitsi/meet/$OLD_DOMAIN.crt /etc/jitsi/meet/$NEW_DOMAIN.crt
mv /etc/jitsi/meet/$OLD_DOMAIN.key /etc/jitsi/meet/$NEW_DOMAIN.key

sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/jitsi/videobridge/config
sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/jitsi/videobridge/sip-communicator.properties


# Prosody
rm -rf /etc/prosody/certs/$OLD_DOMAIN.crt
rm -rf /etc/prosody/certs/$OLD_DOMAIN.key
rm -rf /etc/prosody/certs/auth.$OLD_DOMAIN.crt
rm -rf /etc/prosody/certs/auth.$OLD_DOMAIN.key
rm -rf /etc/prosody/conf.d/$OLD_DOMAIN.cfg.lua

sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/prosody/conf.avail/$OLD_DOMAIN.cfg.lua

mv /etc/prosody/conf.avail/$OLD_DOMAIN.cfg.lua /etc/prosody/conf.avail/$NEW_DOMAIN.cfg.lua
ln -s /etc/prosody/conf.avail/$NEW_DOMAIN.cfg.lua /etc/prosody/conf.d/$NEW_DOMAIN.cfg.lua

prosodyctl cert generate $NEW_DOMAIN <<EOF







EOF

prosodyctl cert generate auth.$NEW_DOMAIN <<EOF







EOF


rm -rf /var/lib/prosody/$OLD_DOMAIN.cnf
rm -rf /var/lib/prosody/$OLD_DOMAIN.crt
rm -rf /var/lib/prosody/$OLD_DOMAIN.key
rm -rf /var/lib/prosody/auth.$OLD_DOMAIN.cnf
rm -rf /var/lib/prosody/auth.$OLD_DOMAIN.crt
rm -rf /var/lib/prosody/auth.$OLD_DOMAIN.key

ln -s /var/lib/prosody/$NEW_DOMAIN.crt /etc/prosody/certs/$NEW_DOMAIN.crt
ln -s /var/lib/prosody/$NEW_DOMAIN.key /etc/prosody/certs/$NEW_DOMAIN.key
ln -s /var/lib/prosody/auth.$NEW_DOMAIN.crt /etc/prosody/certs/auth.$NEW_DOMAIN.crt
ln -s /var/lib/prosody/auth.$NEW_DOMAIN.key /etc/prosody/certs/auth.$NEW_DOMAIN.key

ln -s /var/lib/prosody/auth.$NEW_DOMAIN.crt /usr/local/share/ca-certificates/auth.$NEW_DOMAIN.crt

rm -rf /usr/local/share/ca-certificates/auth.$OLD_DOMAIN.crt

F_OLD_DOMAIN=$(echo $OLD_DOMAIN | sed 's|\.|\%2e|g')
F_NEW_DOMAIN=$(echo $NEW_DOMAIN | sed 's|\.|\%2e|g')

mv /var/lib/prosody/$F_OLD_DOMAIN /var/lib/prosody/$F_NEW_DOMAIN
mv /var/lib/prosody/auth%2e$F_OLD_DOMAIN /var/lib/prosody/auth%2e$F_NEW_DOMAIN
mv /var/lib/prosody/recorder%2e$F_OLD_DOMAIN /var/lib/prosody/recorder%2e$F_NEW_DOMAIN

update-ca-certificates -f
echo "jitsi-videobridge jitsi-videobridge/jvb-hostname string $NEW_DOMAIN" | debconf-set-selections
echo "jitsi-meet jitsi-meet/jvb-hostname string $NEW_DOMAIN" | debconf-set-selections

#nMeet-admin
sed -Ei "s|$OLD_DOMAIN|$NEW_DOMAIN|g" /etc/nginx/sites-available/nmeet-admin

# Start service
systemctl start nginx
prosodyctl start
systemctl start jitsi-*
systemctl start jicofo
systemctl restart jitsi-videobridge2


source /opt/env/bin/activate
/opt/env/bin/python /opt/NH-Jitsi/manage.py update_domain --settings=project.settings.thanhnb02
echo "from users.models import User; User.objects.create_superuser('admin', 'admin@$NEW_DOMAIN', '123456789')" | /opt/env/bin/python /opt/NH-Jitsi/manage.py shell
