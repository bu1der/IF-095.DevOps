#!/bin/bash
sudo yum -y update
#PHP
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum-config-manager --enable remi-php70
sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-xml php-intl php-mbstring php-xmlrpc php-soap
sudo systemctl restart httpd.service

# Apach
sudo yum -y install httpd
sudo systemctl enable httpd
sudo systemctl start httpd
sudo sed -i 's%DocumentRoot "/var/www/html/"%DocumentRoot "/var/www/html/moodle"%g' "/etc/httpd/conf/httpd.conf"
sudo systemctl restart httpd


# Mariadb
sudo yum -y install mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
echo "[client]">>/etc/my.cnf.d/server.cnf
echo "default-character-set = utf8mb4">>/etc/my.cnf.d/server.cnf
echo "">>/etc/my.cnf.d/server.cnf
echo "[mysqld]">>/etc/my.cnf.d/server.cnf
echo "innodb_file_format = Barracuda">>/etc/my.cnf.d/server.cnf
echo "innodb_file_per_table = 1">>/etc/my.cnf.d/server.cnf
echo "innodb_large_prefix">>/etc/my.cnf.d/server.cnf
echo "">>/etc/my.cnf.d/server.cnf
echo "character-set-server = utf8mb4">>/etc/my.cnf.d/server.cnf
echo "collation-server = utf8mb4_unicode_ci">>/etc/my.cnf.d/server.cnf
echo "skip-character-set-client-handshake">>/etc/my.cnf.d/server.cnf
echo "">>/etc/my.cnf.d/server.cnf
echo "[mysql]">>/etc/my.cnf.d/server.cnf
echo "default-character-set = utf8mb4">>/etc/my.cnf.d/server.cnf
systemctl restart mariadb

#Create base Moodle
mysql -u root -p
create database moodle;
grant all privileges on moodle.* to 'admin'@'localhost' identified by 'password';
quit

#Moodle
sudo yum -y install wget
wget https://download.moodle.org/stable36/moodle-latest-36.tgz
sudo mkdir /var/moodledata
sudo chcon -R -t httpd_sys_rw_content_t /var/moodledata
sudo chown -R apache:apache /var/moodledata
tar xvzf moodle-latest-36.tgz -C /var/www/html/
chown -R apache:apache /var/www/
systemctl restart httpd.service


