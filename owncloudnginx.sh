#/bin/bash

set -e -u 
echo '------------------------------------------------------------------------'
echo '-- This script installs ownCloud on Rasian.                           --'
echo '-- You should further optimize speed and memory unless already done.  --'
echo '-- Feel free to use and adjust this script!                           --'
echo '------------------------------------------------------------------------'
echo

# configuration
INSTALL_DIR=/var/www
INSTALL_FROM=http://owncloud.org/releases/
INSTALL_FILE=owncloud-latest.tar.bz2
DB_PACKAGES="php5-sqlite sqlite"

# TODO: this variables must also be set in owncloudnginx.conf
PRIVATE_KEY=/etc/nginx/server.key
PUBLIC_KEY=/etc/nginx/server.crt

echo "ownCloud will be installed"
echo "  from $INSTALL_FROM$INSTALL_FILE"
echo "  to   $INSTALL_DIR/owncload"


## install required packages for nginx and PHP
apt-get install -y nginx php5-fpm php5-cli php5-curl php5-gd php-pear $DB_PACKAGES openssl


if [ ! -f $PRIVATE_KEY ]; then
    ## generate self-signed certificate that is valid for five years
    openssl req $@ -new -x509 -days 1826 -nodes -out $PUBLIC_KEY -keyout $PRIVATE_KEY
    chmod 600 $PRIVATE_KEY
    echo "self-signed certificate has been created"
    echo "  at   $PUBLIC_KEY with private key at $PRIVATE_KEY"
fi

# TODO: if already installed...

## download latest release of ownCloud
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR
wget $INSTALL_FROM$INSTALL_FILE
tar -xjf $INSTALL_FILE
rm $INSTALL_FILE
cd owncloud
chown -R www-data:www-data $INSTALL_DIR/owncloud

# TODO: cp remote.php

## configure nginx
if [ ! -f /etc/nginx/sites-available/owncloud ]; then
    cp owncloudnginx.conf /etc/nginx/sites-available/owncloud
fi
rm /etc/nginx/sites-enabled/default
ln -s -f /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/default

# restart nginx
/etc/init.d/nginx restart

IPADDRESS=$(hostname -I | tr -d ' ')
echo "Owncloud should now be available a https://$IPADDRESS/owncloud"

