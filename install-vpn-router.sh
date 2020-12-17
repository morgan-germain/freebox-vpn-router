#!/bin/sh

IP_ADDRESS='192.168.1.1'

NORDVPN_LOGIN='todo'
NORDVPN_PASSWORD='todo'

# Install dependencies
sudo apt install -y \
  ca-certificates \
  curl \
  iptables-persistent \
  isc-dhcp-server \
  jq \
  netfilter-persistent \
  openvpn \
  pv \
  unzip

# Faster boot times
echo 'Disabling GRUB prompt timeout...'
sudo sed -i '/GRUB_TIMEOUT/s/5$/0/g' /etc/default/grub
sudo update-grub

### NordVPN connection

# Set NordVPN credentials
echo 'Configuring NordVPN connection...'
sudo tee /etc/openvpn/auth.secret > /dev/null << EOF
${NORDVPN_LOGIN}
${NORDVPN_PASSWORD}
EOF

# Retrieve list of servers
TMP_FILE='/tmp/ovpn.zip'
curl --output "${TMP_FILE}" https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
sudo unzip -o "${TMP_FILE}" -d /etc/openvpn | pv -l -s 11789 > /dev/null
# Each configuration file should be linked to openvpn credential file
sudo find /etc/openvpn -name '*.ovpn' \
    -type f \
    -exec sed -i 's/^auth-user-pass$/auth-user-pass \/etc\/openvpn\/auth.secret/' {} \;

# Detect the best server
echo 'Choosing best NordVPN server...'
./choose-server.sh
sudo systemctl start openvpn

### Routage
echo 'Becoming an IPv4 router...'
# Enable routing
sudo sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf
sudo sysctl -p
# Enable masquerade
sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
sudo netfilter-persistent save

### Network configuration
echo "Setting IP address statically as ${IP_ADDRESS}..."
sudo sed -i '/eth0/s/^/#/g' /etc/network/interfaces
sudo sed -i '/eth0/s/^/#/g' /etc/network/interfaces.d/50-cloud-init

sudo tee /etc/network/interfaces.d/99-static-ip > /dev/null << EOF
# The normal eth0
allow-hotplug eth0
iface eth0 inet static
  address ${IP_ADDRESS}
  netmask 255.255.255.0
  gateway 192.168.1.254
  dns-nameservers 192.168.1.254
EOF

### DHCP Server
sudo sed -i '/INTERFACESv4/s/""/"eth0"/g' /etc/default/isc-dhcp-server

sudo tee /etc/dhcp/dhcpd.conf > /dev/null << EOF
option domain-name "morgan.netlib.re";
option domain-name-servers 8.8.8.8, 8.8.4.4;
#option domain-name-servers 192.168.1.254;

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.100 192.168.1.252;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.1.255;
  option routers 192.168.1.1; # VPN Router
}

group {
  option routers 192.168.1.254; # Freebox Router (bypass VPN for these devices)

  # Static leases
  host freebox-player {
    hardware ethernet 70:FC:8F:60:77:94;
    fixed-address 192.168.1.2;
  }
}
EOF

echo 'You should reboot now with:'
echo 'sudo systemctl reboot'
