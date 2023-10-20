#!/bin/bash

# Enable the EPEL repository (if not already enabled)
sudo yum install -y epel-release

# Install Deluge
sudo yum install -y deluge-web deluge-common

# Start Deluge daemon
sudo systemctl start deluged
sudo systemctl enable deluged

# Set the desired username and password
username="admin"
password="KalixDeluge\$2@1"

# Generate the password hash for Deluge WebUI
password_hash=$(python3 -c "import hashlib; print(hashlib.sha1('${password}'.encode()).hexdigest())")

# Configure the Deluge WebUI
sudo mkdir -p /var/lib/deluge/.config/deluge
sudo touch /var/lib/deluge/.config/deluge/web.conf
sudo chown -R deluge:deluge /var/lib/deluge

cat <<EOL | sudo tee /var/lib/deluge/.config/deluge/web.conf
{
    "file": 1,
    "format": 1
}
EOL

sudo -u deluge deluge-web --conf /var/lib/deluge/.config/deluge/web.conf

# Set the username and password in the Deluge WebUI config file
sudo -u deluge echo "{\"file\": 1, \"format\": 1, \"passwd\": \"$password_hash\", \"enabled\": true, \"port\": 8112}" > /var/lib/deluge/.config/deluge/web.conf

# Restart the Deluge WebUI service
sudo systemctl restart deluge-web

# Open the necessary firewall port
sudo firewall-cmd --permanent --add-port=8112/tcp
sudo firewall-cmd --reload

# Inform the user about the setup
echo "Deluge WebUI has been installed and configured."
echo "Username: $username"
echo "Password: $password"
echo "Access Deluge WebUI at http://your_server_ip:8112"
