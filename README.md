# ALMALINUX-LAMP-AUTOINSTALL

LAMP AUTO INSTALL SCRIPT FOR ALMALINUX

This Auto Install Script Works For XFS (XFILESHARE) Install
https://sibsoft.net/xfilesharing.html

Package Contents

Apache

MYSQL (MARIADB)

PHP 7.4

PHPMYADMIN

FFMPEG

CERTBOTS LETSENCRYPT

OPENVPN

How to use
Login as root and enter to start install
Do the Following Command:
wget https://raw.githubusercontent.com/KALIXHOSTING/ALMALINUX-LAMP-AUTOINSTALL/main/install.sh
# chmod 777 ./install.sh 
then run 

# ./install.sh


Enable Mod Rewrite

# sudo nano /etc/httpd/conf.modules.d/00-base.conf


Add this Line to file

# LoadModule rewrite_module modules/mod_rewrite.so

Then open This File
# sudo nano /etc/httpd/conf/httpd.conf

And Change 

# <Directory /var/www/html>
    AllowOverride From None
 </Directory>
 
 to
 # <Directory /var/www/html>
    AllowOverride All
 </Directory>

Now Restart Apache
# sudo systemctl restart httpd


Enable Let’s Encrypt on Host
***Make Sure You Name it as your domainname 
go to
# cd /etc/httpd/conf.d
Then 
# sudo nano yourDomainName.conf 

# 
# <VirtualHost *:80>
    ServerName yourDomainName.com
    DocumentRoot /var/www/html
    ServerAlias www.yourDomainName.com
    ErrorLog /var/www/error.log
    CustomLog /var/www/requests.log combined
# </VirtualHost>

Now Restart Apache
# sudo service httpd restart  

Now Run Let’s Encrypt Command
# sudo certbot --apache -d example.com

Now your host will have SSL with Let’s Encrypt Enabled
