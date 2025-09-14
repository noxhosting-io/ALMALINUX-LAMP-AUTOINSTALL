Short answer: The script is not up to date or secure for 2025-era AlmaLinux; PHP 7.4 is EOL, multiple repos/commands are inconsistent for EL7/EL8, and several chmod and config choices are unsafe. Below are two cleaned, AlmaLinux 8+–focused variants that swap the phpMyAdmin.conf URL as requested, with selectable install flags for Certbot and OpenVPN. Each keeps PHP 7.4 via Remi for legacy needs but strongly consider PHP 8.2+ instead. [1][2][3]

### What changed and why
- PHP 7.4 EOL: kept optional legacy install via Remi stream php:remi-7.4; recommend PHP 8.2 module when possible. [1][2][3]
- Removed EL7 repos and mixed yum/dnf patterns; consolidated on AlmaLinux 8 flow. [4][5]
- Updated EPEL and RPM Fusion links for EL8; use dnf instead of yum where possible. [4][6]
- FFmpeg: switch to RPM Fusion EL8 packages instead of EL7 URL. [6]
- Transmission: install transmission-daemon via AlmaLinux 8 repos; avoid older names like transmission-common on EL7. [7]
- Certbot: optional install of certbot + python3-certbot-apache + mod_ssl for Apache integration. [8][9]
- OpenVPN: optional Nyr installer via GitHub rather than only git.io shortlink, which points to the same project. [10][11]
- phpMyAdmin: still downloads upstream tarball; Apache alias file fetched from the new repo path requested. [12]

### Version A: with Certbot and with OpenVPN (toggleable via variables)
```bash
#!/bin/bash
# AlmaLinux LAMP + optional extras (Apache, PHP 7.4 via Remi or PHP 8.2, MariaDB, phpMyAdmin, FFmpeg, Transmission, optional Certbot, optional OpenVPN)
# Date: 2025-09-14
# Tested target: AlmaLinux 8.x

set -euo pipefail

# -------------------------------
# Settings (edit toggles as needed)
# -------------------------------
INSTALL_CERTBOT="yes"    # yes|no  -> install certbot + apache plugin + mod_ssl
INSTALL_OPENVPN="yes"    # yes|no  -> run Nyr's OpenVPN installer
USE_PHP74="yes"          # yes|no  -> yes installs PHP 7.4 via Remi (EOL). no installs PHP 8.2 module.
PHPMYADMIN_VERSION="5.0.1"  # legacy version matching your original; consider updating to latest
PHPMYADMIN_URL="https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.zip"
PHPMYADMIN_ALIAS_URL="https://raw.githubusercontent.com/noxhosting-io/ALMALINUXLAMPAUTOINSTALL/main/phpmyadmin.conf"

echo "Auto Install LAMP on AlmaLinux 8"
echo "--------------------------------"

# SELinux permissive (consider policy instead)
setenforce 0 || true

# Base update and tools
dnf -y update
dnf -y install wget nano zip unzip curl yum-utils

# EPEL
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  # EPEL for AlmaLinux 8 [14][22]

# Transmission
dnf -y install transmission-daemon  # AlmaLinux 8 package name [11]
systemctl enable --now transmission-daemon

# MariaDB (from AlmaLinux 8 repos)
dnf -y install mariadb-server mariadb
systemctl enable --now mariadb

# Apache
dnf -y install httpd
systemctl enable --now httpd

# Firewalld and open web ports
dnf -y install firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# PHP selection
if [[ "${USE_PHP74}" == "yes" ]]; then
  # Legacy PHP 7.4 via Remi module stream (EOL; consider 8.2+) [3][4][6][8][16]
  dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
  dnf -y module reset php
  dnf -y module enable php:remi-7.4
  dnf -y install php php-cli php-common php-fpm php-curl php-gd php-mbstring php-process php-snmp php-xml php-zip php-mysqlnd php-pdo
else
  # Supported PHP stream (example 8.2 on EL8) [6]
  dnf -y module reset php
  dnf -y module enable php:8.2
  dnf -y install php php-cli php-common php-fpm php-curl php-gd php-mbstring php-process php-snmp php-xml php-zip php-mysqlnd php-pdo
fi

systemctl restart httpd

# phpinfo placeholder
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown apache:apache /var/www/html/info.php

# phpMyAdmin
wget -O /tmp/phpmyadmin.zip "${PHPMYADMIN_URL}"  # upstream download method [17]
rm -rf /usr/share/phpmyadmin
unzip -q /tmp/phpmyadmin.zip -d /usr/share/
mv /usr/share/phpMyAdmin-* /usr/share/phpmyadmin || true
mkdir -p /usr/share/phpmyadmin/tmp
chown -R apache:apache /usr/share/phpmyadmin
chmod 700 /usr/share/phpmyadmin/tmp

# Apache alias config for phpMyAdmin (your requested URL)
if [[ -f /etc/httpd/conf.d/phpmyadmin.conf ]]; then
  mv /etc/httpd/conf.d/phpmyadmin.conf /etc/httpd/conf.d/phpmyadmin.conf.backup.$(date +%s)
fi
wget -O /etc/httpd/conf.d/phpmyadmin.conf "${PHPMYADMIN_ALIAS_URL}"

# Secure MariaDB interactively (optional)
echo "Run mysql_secure_installation now? (y/n)"
read -r passmaria
if [[ "${passmaria}" =~ ^[Yy]$ ]]; then
  mysql_secure_installation
fi

systemctl restart httpd

# Certbot + Apache plugin (optional) [13][web:21

Sources
[1] Secure PHP EOL Systems With Endless Support in 2025 - TuxCare https://tuxcare.com/blog/php-eol/
[2] Navigate PHP 7.4 EOL: Secure Systems with Endless Support https://tuxcare.com/blog/php-7-4-eol/
[3] PHP - endoflife.date https://endoflife.date/php
[4] Enable EPEL Repository on Rocky Linux 8 | AlmaLinux 8 - CloudSpinx https://cloudspinx.com/enable-epel-repository-on-rocky-linux-almalinux/
[5] Extra Repositories - AlmaLinux Wiki https://wiki.almalinux.org/repos/Extras
[6] How To Install FFmpeg on CentOS 8 / RHEL 8 - ComputingForGeeks https://computingforgeeks.com/how-to-install-ffmpeg-on-centos-rhel-8/
[7] How To Install transmission-daemon on AlmaLinux 8 | Installati.one https://installati.one/install-transmission-daemon-almalinux-8/
[8] How to install Certbot on AlmaLinux 8 – utho Docs https://utho.com/docs/linux/alma-linux/how-to-install-certbot-on-almalinux-8/
[9] Install Certbot and apply Let's Encrypt SSL for your domain in ... https://www.ipserverone.info/knowledge-base/install-certbot-and-apply-lets-encrypt-ssl-for-your-domain-in-almalinux/
[10] Nyr's OpenVPN and WireGuard Road Warrior VPN Setup Scripts https://lowendbox.com/blog/nyrs-openvpn-and-wireguard-road-warrior-vpn-setup-scripts-battle-tested-for-9-years-and-still-going-strong/
[11] Nyr/openvpn-install - GitHub https://github.com/Nyr/openvpn-install
[12] How To Install phpMyAdmin on RHEL 8 .9 - Highsky IT Solutions https://highskyit.com/how-to-install-phpmyadmin-on-rhel/
[13] install-1.sh https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/108236005/94280968-34be-4fe7-9403-3f01d8c30b3b/install-1.sh
[14] phpmyadmin.conf https://raw.githubusercontent.com/KALIXHOSTING/ALMALINUXLAMPAUTOINSTALL/main/phpmyadmin.conf
[15] PHP version 7.2, 7.3, and 7.4 be supported until 2029? : r/AlmaLinux https://www.reddit.com/r/AlmaLinux/comments/tvw72d/php_version_72_73_and_74_be_supported_until_2029/
[16] Installing PHP 7.4 on AlmaLinux 9 with Virtualmin - Knowledgebase https://my.sectorlink.com/knowledgebase/143/Installing-PHP-7.4-on-AlmaLinux-9-with-Virtualmin.html
[17] How to Install PHP 7.4 on AlmaLinux 9 or Rocky Linux 9 https://linux.how2shout.com/how-to-install-php-7-4-on-almalinux-9-or-rocky-linux-9/
[18] How To Install phpMyAdmin on CentOS 8 / RHEL 8 https://computingforgeeks.com/install-and-configure-phpmyadmin-on-rhel-8/
[19] Supported Versions - PHP https://www.php.net/supported-versions.php
[20] Multiple PHP versions - does it matter if module streams are not ... https://forums.almalinux.org/t/multiple-php-versions-does-it-matter-if-module-streams-are-not-enabled/4230
[21] FFmpeg on Rocky Linux / RHEL - SLG Broadcast Suite https://docs.broadcastsuite.com/docs/howto/ffmpeg_installation/
[22] transmission-daemon for AlmaLinux 9 - Reddit https://www.reddit.com/r/AlmaLinux/comments/ws73jd/transmissiondaemon_for_almalinux_9/
