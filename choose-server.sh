#!/bin/sh

NORDVPN_RECOMMENDATION='https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations'
BEST_SERVER="$(curl --silent "${NORDVPN_RECOMMENDATION}" --stderr - | jq --raw-output '.[0].hostname')"

SERVER="${BEST_SERVER:-fr399.nordvpn.com}"

echo "Selecting server ${SERVER}"
sudo ln -sf /etc/openvpn/ovpn_tcp/${SERVER}.tcp.ovpn /etc/openvpn/nordvpn.conf
if systemctl --quiet is-active openvpn.service; then
    sudo systemctl reload openvpn.service
else
    sudo systemctl start openvpn.service
fi
