#!/bin/sh

NEXTCLOUD_IP='192.168.1.8'
YUNOHOST_IP='192.168.1.4'
NEXTCLOUD_CERTS='/etc/letsencrypt/live/home.morgan.netlib.re'
YUNOHOST_CERTS='/etc/letsencrypt/live/yuno.morgan.netlib.re'

# Install dependencies
sudo apt install -y nginx-light

# Copy NextcloudPi certificates
echo 'Copying NextcloudPi certificates on reverse proxy'
sudo mkdir -p "${NEXTCLOUD_CERTS}"
sudo mkdir -p "${YUNOHOST_CERTS}"

ssh "pi@${NEXTCLOUD_IP}" sudo cat "${NEXTCLOUD_CERTS}/fullchain.pem" | \
    sudo tee "${NEXTCLOUD_CERTS}/fullchain.pem" > /dev/null

ssh "pi@${NEXTCLOUD_IP}" sudo cat "${NEXTCLOUD_CERTS}/privkey.pem" | \
    sudo tee "${NEXTCLOUD_CERTS}/privkey.pem" > /dev/null


# Set Reverse Proxy configuration
# https://tools.keycdn.com/http2-test
echo 'Configuring Nextcloud reverse proxy configuration...'
sudo cp ./nginx/default /etc/nginx/sites-available/default
sudo cp ./nginx/nextcloud /etc/nginx/sites-available/nextcloud
sudo cp ./nginx/yuno /etc/nginx/sites-available/yuno

sudo rm -f /etc/nginx/sites-enabled/*
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud
sudo ln -sf /etc/nginx/sites-available/yuno /etc/nginx/sites-enabled/yuno
sudo systemctl reload nginx

echo 'You should enable HTTP ports redirection now...'
