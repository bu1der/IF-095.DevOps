#!/bin/bash

sudo yum -y update

#PHP
if command -v php 2>/dev/null; then
  echo "PHP is already installed."
else
  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
  sudo yum -y install yum-utils
  sudo yum-config-manager --enable remi-php70
  sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-xml php-intl php-mbstring php-xmlrpc php-soap
fi

#Apache
if command -v httpd 2>/dev/null; then
  echo "Apache is already installed."
else
  sudo yum -y install httpd
  sudo systemctl start httpd
  sudo systemctl enable httpd
fi

#Mariadb
if command -v mysql 2>/dev/null; then
  echo "Mariadb is already installed."
else
  sudo yum -y install mariadb-server
  sudo systemctl start mariadb
  sudo systemctl enable mariadb
fi

  #Create base Moodle
RESULT=`mysqlshow --user=moodleUser --password=moodlePassword moodle| grep -v Wildcard | grep -o moodle`
if [ "$RESULT" == "moodle" ]; then
    echo "User moodle database is already created."
else
  sudo mysql -e "SET GLOBAL character_set_server = 'utf8mb4';"
  sudo mysql -e "SET GLOBAL innodb_file_format = 'BARRACUDA';"
  sudo mysql -e "SET GLOBAL innodb_large_prefix = 'ON';"
  sudo mysql -e "SET GLOBAL innodb_file_per_table = 'ON';"
  sudo mysql -e "CREATE DATABASE moodle;"
  sudo mysql -e "CREATE USER 'moodleUser'@'localhost' IDENTIFIED BY 'moodlePassword';"
  sudo mysql -e "GRANT ALL PRIVILEGES ON moodle.* TO 'moodleUser'@'localhost';"
  sudo mysql -e "FLUSH PRIVILEGES;"
fi

#Moodle
curl https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz -o moodle-latest-36.tgz -s
sudo tar -xzf moodle-latest-36.tgz -C /var/www/html/

sudo /usr/bin/php /var/www/html/moodle/admin/cli/install.php --chmod=2770  --lang=uk  --dbtype=mariadb  --wwwroot=http://192.168.56.198/moodle  --dataroot=/var/moodledata  --dbname="moodle"  --dbuser="moodleUser"  --dbpass="moodlePassword"  --dbport=3306  --fullname=Moodle  --shortname=moodle  --summary=Moodle  --adminpass=Admin1  --non-interactive  --agree-license
sudo chmod o+r /var/www/html/moodle/config.php
sudo chcon -R -t httpd_sys_rw_content_t /var/moodledata
sudo chown -R apache:apache /var/moodledata
sudo chown -R apache:apache /var/www/
sudo systemctl restart httpd