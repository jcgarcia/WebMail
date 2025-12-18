# syntax=docker/dockerfile:1
# SnappyMail WebMail with Ingasti Customizations
# Using pre-extracted and fixed SnappyMail files from repo

FROM php:8.2-fpm-alpine3.21

LABEL org.label-schema.description="SnappyMail WebMail (Ingasti Custom) using nginx, php-fpm on Alpine"

# Install runtime dependencies
RUN apk add --no-cache ca-certificates nginx supervisor bash

# Install all PHP extensions in single compilation stage for efficiency
RUN set -eux; \
    \
    apk add --no-cache freetype libjpeg-turbo libpng libzip postgresql-libs; \
    \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        freetype-dev libjpeg-turbo-dev libpng-dev \
        libzip-dev postgresql-dev; \
    \
    pecl install apcu; \
    docker-php-ext-enable apcu; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install gd; \
    \
    docker-php-ext-install pdo_mysql zip pdo_pgsql; \
    \
    docker-php-source delete; \
    apk del .build-deps

# Copy SnappyMail from repo (pre-extracted and CSS fixed)
# The repo structure is: snappymail/v/2.38.2/...
# We need it at: /snappymail/snappymail/v/2.38.2/... (for index.php to find it)
RUN mkdir -p /snappymail/snappymail
COPY --chown=www-data:www-data snappymail/v /snappymail/snappymail/v

# Copy custom include.php with correct data path
COPY --chown=www-data:www-data .docker/release/files/snappymail/include.php /snappymail/snappymail/v/2.38.2/include.php

# Setup SnappyMail data directory and permissions
RUN set -eux; \
    mkdir -p /var/lib/snappymail; \
    if [ -d /snappymail/data ]; then mv /snappymail/data/* /var/lib/snappymail/ || true; fi; \
    chown -R www-data:www-data /var/lib/snappymail; \
    chmod -R 700 /var/lib/snappymail; \
    mkdir -p /var/lib/snappymail/_data_/_default_/{cache,configs,domains,plugins,storage}; \
    chown -R www-data:www-data /var/lib/snappymail/_data_; \
    chmod -R 700 /var/lib/snappymail/_data_; \
    # Make CSS files read-only
    chmod 444 /snappymail/snappymail/v/2.38.2/static/css/*.css* || true

# Copy configuration files and index.php
COPY .docker/release/files/etc/ /etc/
COPY .docker/release/files/usr/ /usr/
COPY .docker/release/files/supervisor.conf /supervisor.conf
COPY .docker/release/files/entrypoint.sh /entrypoint.sh
COPY --chown=www-data:www-data .docker/release/files/index.php /snappymail/index.php
COPY --chown=www-data:www-data .docker/release/files/listener.php /snappymail/listener.php

# Setup final permissions
RUN set -eux; \
    chown www-data:www-data /snappymail/snappymail/v/2.38.2/include.php; \
    chmod 440 /snappymail/snappymail/v/2.38.2/include.php; \
    chmod +x /entrypoint.sh; \
    mv -v /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf.disabled || true; \
    mv -v /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf.disabled || true; \
    mv -v /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.disabled || true

USER root
WORKDIR /snappymail
VOLUME /var/lib/snappymail
EXPOSE 8888
EXPOSE 9000
ENTRYPOINT []
CMD ["/entrypoint.sh"]
