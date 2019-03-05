#!/bin/bash
MAINDB="moodledatabase"
USERDB="moodleuser"
PASSWDDB="moodlepassword"
WWWHOST11="192.168.56.11"
WWWHOST12="192.168.56.12"

# sudo yum -y update

#install DB
sudo yum -y install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-redhat11-11-2.noarch.rpm
sudo yum -y install postgresql11-server
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
sudo systemctl start postgresql-11
sudo systemctl enable postgresql-11

# Database
sudo -u postgres psql -c "CREATE USER ${USERDB} WITH ENCRYPTED PASSWORD '${PASSWDDB}';"
sudo -u postgres psql -c "CREATE DATABASE ${MAINDB} WITH OWNER ${USERDB};"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${MAINDB} to ${USERDB};"

sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/11/data/postgresql.conf
sudo sed -i -e "s/#port = 5432/port = 5432/g" /var/lib/pgsql/11/data/postgresql.conf
sudo cat <<EOF | sudo tee -a /var/lib/pgsql/11/data/pg_hba.conf
host    all             all              ${WWWHOST11}/32        password
host    all             all              ${WWWHOST12}/32        password
EOF

sudo systemctl restart postgresql-11

sudo systemctl start firewalld.service
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
   rule family="ipv4"
   source address="192.168.56.11/32"
   port protocol="tcp" port="5432" accept'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
   rule family="ipv4"
   source address="192.168.56.12/32"
   port protocol="tcp" port="5432" accept'
sudo firewall-cmd --reload


