#!/bin/sh
set -eu

DEBUG=${DEBUG:-}
if [ "$DEBUG" = 'true' ]; then
    set -x
fi
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-25M}
MEMORY_LIMIT=${MEMORY_LIMIT:-128M}
SECURE_COOKIES=${SECURE_COOKIES:-true}

# Set attachment size limit
sed -i "s/<UPLOAD_MAX_SIZE>/$UPLOAD_MAX_SIZE/g" /usr/local/etc/php-fpm.d/php-fpm.conf /etc/nginx/nginx.conf
sed -i "s/<MEMORY_LIMIT>/$MEMORY_LIMIT/g" /usr/local/etc/php-fpm.d/php-fpm.conf

# Secure cookies
if [ "${SECURE_COOKIES}" = 'true' ]; then
    echo "[INFO] Secure cookies activated"
        {
        	echo 'session.cookie_httponly = On';
        	echo 'session.cookie_secure = On';
        	echo 'session.use_only_cookies = On';
        } > /usr/local/etc/php/conf.d/cookies.ini;
fi

echo "[INFO] Snappymail version: 2.38.2"

# Set permissions on snappymail data
echo "[INFO] Setting permissions on /var/lib/snappymail"
chown -R www-data:www-data /var/lib/snappymail/
chmod 750 /var/lib/snappymail/
find /var/lib/snappymail/ -type d -exec chmod 750 {} \;
find /var/lib/snappymail/ -type f -exec chmod 644 {} \;

# Ensure data directory structure exists
mkdir -p /var/lib/snappymail/_data_/_default_/{cache,configs,domains,plugins,storage}
chown -R www-data:www-data /var/lib/snappymail/_data_/
chmod -R 755 /var/lib/snappymail/_data_/

echo "[INFO] Snappymail version: 2.38.2"

# Set permissions on snappymail data
echo "[INFO] Setting permissions on /var/lib/snappymail"
chown -R www-data:www-data /var/lib/snappymail/
chmod -R 700 /var/lib/snappymail/

# Background initialization after services start
(
    while ! nc -vz -w 1 127.0.0.1 8888 > /dev/null 2>&1; do echo "[INFO] Waiting for nginx"; sleep 1; done
    while ! nc -vz -w 1 127.0.0.1 9000 > /dev/null 2>&1; do echo "[INFO] Waiting for php-fpm"; sleep 1; done
    
    echo "[INFO] Services ready, initializing application"
    for i in {1..10}; do
        wget -T 2 -qO- http://127.0.0.1:8888/ > /dev/null 2>&1 && break
        sleep 1
    done
    echo "[INFO] Application initialized"
) &

# RUN !
exec /usr/bin/supervisord -c /supervisor.conf --pidfile /run/supervisord.pid
