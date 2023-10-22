#!/bin/bash
###########################################################
#Script Auto Install Apache, PHP 7.4, MariaDB, phpmyadmin,FFMPEG,TRANSMISSION,OPENVPN,LETSENCRYPT
#Author		:  MAVEN
#Instagram	:  https://www.kalixhosting.com
#Version	:  1.0.0
#Date		:  03/12/2023
#OS		:  ALMALINUX
###########################################################

echo "Auto Install LAMP ALMALINUX"
echo "###########################"

#Update ALMALINUX
sudo setenforce 0
yum -y update
yum -y install wget
yum -y upgrade
yum install wget nano zip unzip -y
chmod +rw /root
chmod 777 /root
yum -y install epel-release

yum -y update


yum -y install transmission-cli transmission-common transmission-daemon

systemctl start transmission-daemon.service


#EPEL Repo
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-7.noarch.rpm
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
yum -y install yum-utils
dnf module enable php:7.4 -y


#Install MariaDB
yum -y install mariadb-server mariadb
systemctl start mariadb.service
systemctl enable mariadb.service

#Install Apache
yum -y install httpd
systemctl start httpd.service
systemctl enable httpd.service

#FIREWALL PORTS HTTP AND HTTPS
sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

#Install PHP 7.4
sudo dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf module -y reset php
sudo dnf module install php:remi-7.4 -y
sudo dnf -y install php php-{cli,common,fpm,curl,gd,mbstring,process,snmp,xml,zip,memcached,mysqlnd,json,mbstring,pdo,pdo-dblib,xml}


systemctl restart httpd.service


echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

#MariaDB Support PHP
sudo yum install mariadb-server -y
sudo systemctl start mysql.service
sudo systemctl enable mariadb
sudo systemctl start mariadb
systemctl restart httpd.service

#Install PHPMYADMIN
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.zip
unzip phpMyAdmin-5.0.1-all-languages.zip
mv phpMyAdmin-5.0.1-all-languages /usr/share/phpmyadmin
mkdir /usr/share/phpmyadmin/tmp
chown -R apache:apache /usr/share/phpmyadmin
chmod 777 /usr/share/phpmyadmin/tmp

#CONFIG phpmyadmin
mv /etc/httpd/conf.d/phpmyadmin.conf /etc/httpd/conf.d/phpMyadmin.conf.backup
wget https://raw.githubusercontent.com/KALIXHOSTING/ALMALINUXLAMPAUTOINSTALL/main/phpmyadmin.conf
cp phpmyadmin.conf /etc/httpd/conf.d/

echo "Password Root MariaDB ? | Change MariaDB Root Password ? (y|n)"
read passmaria

case $passmaria in
	y | Y)
	mysql_secure_installation
	;;

	n | N)
	;;

	*)
	echo "Wrong Syntax :p"
	;;
esac
#RESTART APACHE
systemctl restart httpd.service


#CONFIG CERTBOT
sudo dnf install certbot python3-certbot-apache mod_ssl -y

#btop
sudo dnf install epel-release
sudo dnf install btop -y

yum -y install perl-CGI perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD perl-Cache-Memcached perl-Digest-SHA perl-LWP-Protocol-https
#RESTART APACHE
systemctl restart httpd.service

#CHMOD VAR/WWW/HTML
chmod +rw /var
chmod +rw /var/www/html
chmod 777 /var
chmod 777 /var/www/html

#install FFMPEG
sudo yum install epel-release -y
sudo yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y 
sudo yum install ffmpeg ffmpeg-devel -y



#install OPENVPN
wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh



echo "######## KALIXHOSTING AUTOINSTALL FOR ALMALINUX | FINISH #########"
