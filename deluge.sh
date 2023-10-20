#!/bin/bash

# Install required packages
sudo yum install -y deluge-web

# Create Deluge config directory and copy the web.conf file
sudo mkdir -p /var/lib/deluge/.config/deluge/
sudo cp /usr/share/doc/deluge/web.conf /var/lib/deluge/.config/deluge/web.conf

# Set the desired username and password
username="admin"
password="KalixDeluge\$2@1"

# Generate the password hash for Deluge WebUI
password_hash=$(python3 -c "import hashlib; print(hashlib.sha1('${password}'.encode()).hexdigest())")

# Set the username and password in the Deluge WebUI config file
sudo sed -i "s|\"passwd\": \".*\"|\"passwd\": \"$password_hash\"|" /var/lib/deluge/.config/deluge/web.conf
sudo sed -i "s|\"enabled\": false|\"enabled\": true|" /var/lib/deluge/.config/deluge/web.conf
sudo sed -i "s|\"port\": 8112|\"port\": 8112|" /var/lib/deluge/.config/deluge/web.conf

# Start the Deluge WebUI service
sudo systemctl enable deluge-web
sudo systemctl start deluge-web

# Open the necessary firewall port
sudo firewall-cmd --permanent --add-port=8112/tcp
sudo firewall-cmd --reload

# Inform the user about the setup
echo "Deluge WebUI has been installed and configured."
echo "Username: $username"
echo "Password: $password"
echo "Access Deluge WebUI at http://your_server_ip:8112"

