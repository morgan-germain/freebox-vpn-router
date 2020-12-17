#!/bin/sh

NEXTCLOUD_IP='192.168.1.4'
CERTS_PATH='/etc/letsencrypt/live/home.morgan.netlib.re'

# Install dependencies
sudo apt install -y nginx-light

# Copy NextcloudPi certificates
echo 'Copying NextcloudPi certificates on reverse proxy'
sudo mkdir -p "${CERTS_PATH}"

ssh "pi@${NEXTCLOUD_IP}" sudo cat "${CERTS_PATH}/fullchain.pem" | \
    sudo tee "${CERTS_PATH}/fullchain.pem" > /dev/null

ssh "pi@${NEXTCLOUD_IP}" sudo cat "${CERTS_PATH}/privkey.pem" | \
    sudo tee "${CERTS_PATH}/privkey.pem" > /dev/null


# Set Reverse Proxy configuration
# https://tools.keycdn.com/http2-test
echo 'Configuring Nextcloud reverse proxy configuration...'
sudo tee /etc/nginx/sites-available/nextcloud > /dev/null << EOF
server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	server_name home.morgan.netlib.re;

	ssl_certificate           ${CERTS_PATH}/fullchain.pem;
	ssl_certificate_key       ${CERTS_PATH}/privkey.pem;

	access_log /var/log/nginx/home-access.log;
	error_log /var/log/nginx/home-error.log;

	location / {
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_pass http://${NEXTCLOUD_IP};
	}
}
EOF

sudo ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
sudo systemctl reload nginx

echo 'You should enable HTTP ports redirection now...'
