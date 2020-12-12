#!/bin/sh

NORDVPN_LOGIN='pouet'
NORDVPN_PASSWORD='pouetpouet'

# Install dependencies
sudo apt install -y ca-certificates curl jq openvpn unzip

### NordVPN connection

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


### Routage
# Enable routing
# TODO Morgan : décommenter une ligne avec sed
sed /etc/sysctl.conf
#net.ipv4.ip_forward = 1

sudo systcl -p
sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# Save iptable rule
sudo apt install netfilter-persistent iptables-persistent
sudo netfilter-persistent save

### Network configuration
# TODO Morgan : remplacer la conf DHCP par la conf statique avec sed
# TODO Morgan : attention, le fichier /etc/network/interfaces.d/50-cloud-init force le DHCP pour eth0
## The normal eth0
#allow-hotplug eth0
#iface eth0 inet dhcp
#par cette section
## The normal eth0
#allow-hotplug eth0
#iface eth0 inet static
#  address 192.168.1.1
#  netmask 255.255.255.0
#  gateway 192.168.1.254
#  dns-nameservers 192.168.1.254

# TODO Morgan : faut peut-être faire ça a la fin
sudo systemctl restart networking

### DHCP Server

sudo apt install isc-dhcp-server
# TODO MGE :
# Write in /etc/default/isc-dhcp-server
# INTERFACESv4="eth0"


sudo tee /etc/dhcp/dpcpd.conf << EOF
option domain-name "morgan.netlib.re";
option domain-name-servers 8.8.8.8, 8.8.4.4;
#option domain-name-servers 192.168.1.254;

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.100 192.168.1.252;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.1.255;
  option routers 192.168.1.253; # VPN Router
}

group {
  option routers 192.168.1.254; # Freebox Router (bypass VPN for these devices)

EOF
sudo systemctl restart isc-dhcp-server
