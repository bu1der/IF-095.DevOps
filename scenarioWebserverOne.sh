#!/bin/bash
MAINDB="moodledatabase"
USERDB="moodleuser"
PASSWDDB="moodlepassword"
WWWHOST="192.168.56.11"
BASEHOST="192.168.56.20"

# sudo yum -y update

#PHP
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum --enablerepo=remi,remi-php72 install -y php php-fpm \
         php-common php-pear php-mcrypt php-cli php-gd php-curl \
         php-mysql php-ldap php-zip php-fileinfo php-xml php-intl \
         php-mbstring php-xmlrpc php-soap php-pdo php-pgsql

sudo sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sudo sed -i -e 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's+listen = 127.0.0.1:9000+listen = /run/php-fpm/php-fpm.sock+g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;security.limit_extensions = .php .php3 .php4 .php5 .php7/security.limit_extensions = .php/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;env/env/g' /etc/php-fpm.d/www.conf
#Install Nginx
sudo yum -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo mkdir -p /var/lib/php/session/
sudo chown -R nginx:nginx /var/lib/php/session/
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

#Install App
curl https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz -o moodle-latest-36.tgz -s
sudo tar -xzf moodle-latest-36.tgz -C /var/www/

 sudo mkdir -p /var/moodledata
 sudo chown -R nginx:nginx /var/moodledata
 sudo chmod 755 /var/moodledata
 sudo chown -R nginx:nginx /var/www/moodle
 sudo chmod 755 /var/www/moodle

# nginx config
 uri='$uri'
 OD='$1'
 TR='$3'
cat <<EOF | sudo tee -a /etc/nginx/conf.d/moodle.conf
# PHP Upstream Handler
upstream php-handler {
    server unix:/run/php-fpm/php-fpm.sock;
}
# Nginx
server {
    listen 80;
    server_name ${WWWHOST};
# Root Moodle Data DIrectory
    root /var/www/moodle;
    rewrite ^/(.*\.php)(/)(.*)$ /$OD?file=/$TR last;
    location ^~ / {
            try_files $uri $uri/ /index.php?q=$request_uri;
            index index.php index.html index.htm;
            location ~ \.php$ {
                   include fastcgi.conf;
                   fastcgi_pass php-handler;
            }
    }
}
EOF
sudo rm /etc/nginx/nginx.conf
REMOTE_ADDR='$remote_addr'
REMOTE_USER='$remote_user'
TIME='$time_local'
REQUEST='$request'
STATUS='$status'
BODY='$body'
REFERER='$http_referer'
AGENT='$http_user_agent'
FORWARDED='$http_x_forwarded_for'
cat <<EOF | sudo tee -a /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '$REMOTE_ADDR - $REMOTE_USER [$TIME] "$REQUEST" '
                      '$STATUS $BODY_bytes_sent "$REFERER" '
                      '"$AGENT" "$FORWARDED"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
    server {
        listen       80;
        server_name  _;
        root         /usr/share/nginx/html;
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
        location / {
        }
        error_page 404 /404.html;
            location = /40x.html {
        }
        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
                        }
    }
}
EOF
sudo nginx -t
sudo systemctl restart nginx
sudo chcon -R -t httpd_sys_rw_content_t /var/moodledata
sudo setsebool httpd_can_network_connect true

#Install App
sudo /usr/bin/php /var/www/moodle/admin/cli/install.php --chmod=2770 \
 --lang=uk \
 --dbtype=pgsql \
 --wwwroot=http://$WWWHOST/ \
 --dataroot=/var/moodledata \
 --dbhost=$BASEHOST \
 --dbname=$MAINDB \
 --dbuser=$USERDB \
 --dbpass=$PASSWDDB \
 --dbport=5432 \
 --fullname=Moodle \
 --shortname=moodle \
 --summary=Moodle \
 --adminpass=Admin1 \
 --non-interactive \
 --agree-license
sudo chmod o+r /var/www/moodle/config.php
sudo chcon -R -t httpd_sys_rw_content_t /var/moodledata
sudo chown -R nginx:nginx /var/moodledata
sudo chown -R nginx:nginx /var/www/moodle
sudo systemctl restart nginx

sudo systemctl start firewalld.service
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="192.168.56.20"
  port protocol="tcp" port="80" accept'
sudo firewall-cmd --reload

