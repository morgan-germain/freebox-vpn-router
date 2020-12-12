#!/bin/sh

NORDVPN_LOGIN='pouet'
NORDVPN_PASSWORD='pouetpouet'

# Install dependencies
sudo apt install -y ca-certificates curl jq openvpn unzip

# Set NordVPN credentials
sudo tee /etc/openvpn/auth.secret << EOF
${NORDVPN_LOGIN}
${NORDVPN_PASSWORD}
EOF

# Retrieve list of servers
curl --output=/tmp/ovpn.zip https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip /tmp/ovpn.zip -d /etc/openvpn
# Each configuration file should be linked to openvpn credential file
sudo find /etc/openvpn -name '*.ovpn' \
    -type f \
    -exec sed -i 's/^auth-user-pass$/auth-user-pass \/etc\/openvpn\/auth.secret/' {} \;

# Detect the best server
./chose-server.sh
