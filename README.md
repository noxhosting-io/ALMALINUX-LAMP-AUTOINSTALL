
![Logo](https://kalixhosting.com/img/logo.png)


# ALMALINUX LAMP AUTO INSTALL

ALMALINUX LAMP AUTO INSTALLER SCRIPT


## Authors

- [@maven_htx](https://instagram.com/maven_htx)


## Features

- APACHE2
- PHP 7.4
- MARIADB
- PHPMYADMIN
- COMPOSER
- FFMPEG
- PHPMYADMIN
- LETS ENCRYPT
- OPENVPN
- TRANSMISSIONBT (TORRENT DOWNLOADER)
- ZIP
- RAR 
- FIREWALL RULES ADDED
- RUBY

## MADE TO WORK WITH (XFILESHARE) XFS 

[XFS](https://sibsoft.net/xfilesharing.html)




## Installation

Install Script

```bash
 wget -4 https://scripts.kalixhosting.com/centos/almalinux/lamp/ -O install.sh && bash install.sh
```
## ENABLE MOD REWRITE

```bash
sudo nano /etc/httpd/conf.modules.d/00-base.conf
```
## ADD THIS LINE

```bash
LoadModule rewrite_module modules/mod_rewrite.so
```

## Now open

```bash
sudo nano /etc/httpd/conf/httpd.conf
```

## Change 
```bash
<Directory /var/www/html>
    AllowOverride From None
 </Directory>
```

# To

```bash
<Directory /var/www/html>
    AllowOverride All
 </Directory>
```
## Restart Apache2 

```bash
sudo systemctl restart httpd
```








## WANT TO SET UP VIRUAL HOST RUN THESE COMMANDS 

Replace yourDomainName with your Desired Domain


```bash
cd /etc/httpd/conf.d

sudo nano yourDomainName.conf 

INSIDE OF NANO PASTE THESE BELOW 

 <VirtualHost *:80>
    ServerName yourDomainName.com
    DocumentRoot /var/www/html
    ServerAlias www.yourDomainName.com
    ErrorLog /var/www/error.log
    CustomLog /var/www/requests.log combined
</VirtualHost>

CONTROL X   Y SAVE 

NOW RUN 

sudo service httpd restart  

```

## ADD LETS ENCRYPT SSL TO VirtualHost

RUN THIS COMMAND

```bash
sudo certbot --apache -d example.com

```





## 🔗 Links
KALIXHOSTING https://kalixhosting.com/
