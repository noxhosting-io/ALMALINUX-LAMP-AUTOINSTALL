#!/bin/bash
set -euo pipefail

# AlmaLinux LAMP/tools installer with whiptail menu
# - Menu first, then execution
# - phpMyAdmin config URL fixed
# - FFmpeg from RPM Fusion (EL8/EL9)
# - Ensure tar/gzip/unzip exist
# - Python 3.9 before yt-dlp; pip warning suppressed; symlink only if needed

ELVER="$(rpm -E %rhel || echo 8)"

# Prereqs to render menu and handle archives
sudo dnf -y install dnf-plugins-core || true
# Whiptail is provided by newt on RHEL-like systems
sudo dnf -y install newt || true  # provides 'whiptail' [TUI]
sudo dnf -y install wget curl nano zip unzip tar gzip bzip2 xz zstd || true

show_menu() {
  whiptail --title "AlmaLinux Installer" --checklist "Select components (Space toggles, Enter confirms)" 22 78 14 \
    updates        "System update/upgrade"                           ON \
    firewall       "Firewalld HTTP/HTTPS"                            ON \
    apache         "Apache (httpd)"                                  ON \
    php74          "PHP 7.4 (Remi)"                                  ON \
    mariadb        "MariaDB server"                                  ON \
    securemdb      "Secure MariaDB (mysql_secure_installation)"      ON \
    phpmyadmin     "phpMyAdmin (latest tarball + conf)"              ON \
    certbot        "Certbot for Apache (mod_ssl)"                    ON \
    transmission   "Transmission daemon"                             OFF \
    openvpn        "OpenVPN (community script)"                      OFF \
    btop           "btop"                                            OFF \
    perlcgi        "Perl CGI-related libraries"                      OFF \
    ffmpeg         "FFmpeg (RPM Fusion)"                             ON \
    ytdlp          "Python 3.9 + yt-dlp"                             ON \
    3>&1 1>&2 2>&3
}

parse_choice() { [[ "$selected" == *" $1 "* ]] && echo 1 || echo 0; }

selected_raw="$(show_menu)" || { echo "Aborted."; exit 1; }
selected=" $(echo "$selected_raw" | sed 's/"//g') "

INSTALL_UPDATES=$(parse_choice updates)
INSTALL_FIREWALL=$(parse_choice firewall)
INSTALL_APACHE=$(parse_choice apache)
INSTALL_PHP=$(parse_choice php74)
INSTALL_MARIADB=$(parse_choice mariadb)
SECURE_MARIADB=$(parse_choice securemdb)
INSTALL_PHPMYADMIN=$(parse_choice phpmyadmin)
INSTALL_CERTBOT=$(parse_choice certbot)
INSTALL_TRANSMISSION=$(parse_choice transmission)
INSTALL_OPENVPN=$(parse_choice openvpn)
INSTALL_BTOP=$(parse_choice btop)
INSTALL_PERL_CGI_LIBS=$(parse_choice perlcgi)
INSTALL_FFMPEG=$(parse_choice ffmpeg)
INSTALL_YTDLP=$(parse_choice ytdlp)

summary=$(cat <<EOF
Updates:           $INSTALL_UPDATES
Firewall:          $INSTALL_FIREWALL
Apache:            $INSTALL_APACHE
PHP 7.4 (Remi):    $INSTALL_PHP
MariaDB:           $INSTALL_MARIADB
Secure MariaDB:    $SECURE_MARIADB
phpMyAdmin:        $INSTALL_PHPMYADMIN
Certbot:           $INSTALL_CERTBOT
Transmission:      $INSTALL_TRANSMISSION
OpenVPN:           $INSTALL_OPENVPN
btop:              $INSTALL_BTOP
Perl CGI libs:     $INSTALL_PERL_CGI_LIBS
FFmpeg:            $INSTALL_FFMPEG
Python3.9 + yt-dlp:$INSTALL_YTDLP
EOF
)
whiptail --title "Confirm selection" --yesno "$summary" 20 70 || { echo "Aborted."; exit 1; }

# EPEL and CRB/PowerTools
sudo dnf -y install epel-release
if [[ "$ELVER" -eq 8 ]]; then
  sudo dnf config-manager --set-enabled powertools || true
else
  sudo dnf config-manager --set-enabled crb || true
fi

# System update/upgrade
if [[ "$INSTALL_UPDATES" -eq 1 ]]; then
  sudo dnf -y update
  sudo dnf -y upgrade
fi

# Firewall
if [[ "$INSTALL_FIREWALL" -eq 1 ]]; then
  sudo dnf -y install firewalld
  sudo systemctl enable --now firewalld
  sudo firewall-cmd --permanent --zone=public --add-service=http
  sudo firewall-cmd --permanent --zone=public --add-service=https
  sudo firewall-cmd --reload
fi

# Apache
if [[ "$INSTALL_APACHE" -eq 1 ]]; then
  sudo dnf -y install httpd
  sudo systemctl enable --now httpd
fi

# PHP 7.4 via Remi
if [[ "$INSTALL_PHP" -eq 1 ]]; then
  if [[ "$ELVER" -eq 8 ]]; then
    sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
  else
    sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
  fi
  sudo dnf -y module reset php
  sudo dnf -y module enable php:remi-7.4
  sudo dnf -y install php php-cli php-common php-fpm php-curl php-gd php-mbstring php-process php-snmp php-xml php-zip php-mysqlnd php-pdo
  echo "<?php phpinfo();" | sudo tee /var/www/html/info.php >/dev/null || true
  sudo systemctl restart httpd || true
fi

# MariaDB
if [[ "$INSTALL_MARIADB" -eq 1 ]]; then
  sudo dnf -y install mariadb-server
  sudo systemctl enable --now mariadb
  if [[ "$SECURE_MARIADB" -eq 1 ]]; then
    sudo mysql_secure_installation
  fi
  sudo systemctl restart httpd || true
fi

# phpMyAdmin (latest tarball) + requested Apache conf
if [[ "$INSTALL_PHPMYADMIN" -eq 1 ]]; then
  TMPD="$(mktemp -d)"
  pushd "$TMPD" >/dev/null
  curl -L -o phpMyAdmin-latest-all-languages.tar.gz https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
  tar -xzf phpMyAdmin-latest-all-languages.tar.gz
  sudo rm -rf /usr/share/phpmyadmin
  sudo mv phpMyAdmin-*-all-languages /usr/share/phpmyadmin
  sudo mkdir -p /usr/share/phpmyadmin/tmp
  sudo chown -R apache:apache /usr/share/phpmyadmin
  sudo chmod 750 /usr/share/phpmyadmin/tmp
  popd >/dev/null
  rm -rf "$TMPD"

  sudo mv -f /etc/httpd/conf.d/phpmyadmin.conf /etc/httpd/conf.d/phpmyadmin.conf.bak 2>/dev/null || true
  curl -L -o /tmp/phpmyadmin.conf https://raw.githubusercontent.com/noxhosting-io/ALMALINUX-LAMP-AUTOINSTALL/refs/heads/main/phpmyadmin.conf
  sudo cp /tmp/phpmyadmin.conf /etc/httpd/conf.d/phpmyadmin.conf
  sudo restorecon -RF /usr/share/phpmyadmin 2>/dev/null || true
  sudo systemctl reload httpd || sudo systemctl restart httpd
fi

# Certbot
if [[ "$INSTALL_CERTBOT" -eq 1 ]]; then
  sudo dnf -y install certbot python3-certbot-apache mod_ssl
fi

# Transmission
if [[ "$INSTALL_TRANSMISSION" -eq 1 ]]; then
  sudo dnf -y install transmission-cli transmission-common transmission-daemon
  sudo systemctl enable --now transmission-daemon
fi

# btop
if [[ "$INSTALL_BTOP" -eq 1 ]]; then
  sudo dnf -y install btop
fi

# Perl CGI libs
if [[ "$INSTALL_PERL_CGI_LIBS" -eq 1 ]]; then
  sudo dnf -y install perl-CGI perl-libwww-perl perl-DBI perl-DBD-MySQL perl-GD perl-Cache-Memcached perl-Digest-SHA perl-LWP-Protocol-https
fi

# FFmpeg via RPM Fusion
if [[ "$INSTALL_FFMPEG" -eq 1 ]]; then
  if [[ "$ELVER" -eq 8 ]]; then
    sudo dnf -y install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
    sudo dnf -y install https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
  else
    sudo dnf -y install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm
    sudo dnf -y install https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm
  fi
  sudo dnf -y install ffmpeg ffmpeg-devel
fi

# Python 3.9 + yt-dlp
if [[ "$INSTALL_YTDLP" -eq 1 ]]; then
  sudo dnf -y install python39
  if ! command -v python3.9 >/dev/null 2>&1; then
    echo "python3.9 not found after installation"; exit 1
  fi

  # Preferred: standalone binary
  sudo curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
  sudo chmod a+rx /usr/local/bin/yt-dlp

  if ! /usr/local/bin/yt-dlp --version >/dev/null 2>&1; then
    # Fallback to pip for python3.9, suppress root warning
    python3.9 -m ensurepip --upgrade || true
    python3.9 -m pip install --upgrade pip || true
    python3.9 -m pip install --root-user-action=ignore --no-cache-dir --upgrade yt-dlp
    pip_bin="$(python3.9 -c 'import shutil;print(shutil.which("yt-dlp") or "")')"
    if [[ -n "$pip_bin" && -x "$pip_bin" ]]; then
      # Only link if different to avoid "same file" message
      if [[ ! -e /usr/local/bin/yt-dlp ]] || [[ "$(readlink -f /usr/local/bin/yt-dlp)" != "$(readlink -f "$pip_bin")" ]]; then
        sudo ln -sf "$pip_bin" /usr/local/bin/yt-dlp
      fi
    else
      # Final wrapper to force python3.9
      echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/yt-dlp >/dev/null
      echo 'exec /usr/bin/python3.9 -m yt_dlp "$@"' | sudo tee -a /usr/local/bin/yt-dlp >/dev/null
      sudo chmod a+rx /usr/local/bin/yt-dlp
    fi
  fi
fi

whiptail --title "Done" --msgbox "All selected components processed." 8 50
