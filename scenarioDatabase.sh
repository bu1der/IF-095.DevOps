#!/bin/bash

sudo yum -y update

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


