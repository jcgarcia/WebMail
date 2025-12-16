# syntax=docker/dockerfile:1
# SnappyMail WebMail with Ingasti Customizations
# Download official release, apply CSS fix, and customize

FROM alpine:3.18.5 AS customizer
RUN apk add --no-cache bash imagemagick curl gzip

WORKDIR /tmp

# Download and extract SnappyMail release
RUN curl -sL -o snappymail-2.38.2.tar.gz https://github.com/the-djmaze/snappymail/releases/download/v2.38.2/snappymail-2.38.2.tar.gz && \
    tar -xzf snappymail-2.38.2.tar.gz && \
    rm snappymail-2.38.2.tar.gz

# Apply CSS fix: Remove LoginView button background override to show blue color
RUN sed -i 's/.LoginView .btn,.LoginView input{background:0 0;/.LoginView input{background:0 0;/g' \
    /tmp/snappymail/v/2.38.2/static/css/app.css && \
    sed -i 's/.LoginView .btn,.LoginView input{background:0 0;/.LoginView input{background:0 0;/g' \
    /tmp/snappymail/v/2.38.2/static/css/app.min.css

# Regenerate gzipped CSS versions with the fix
RUN cd /tmp/snappymail/v/2.38.2/static/css/ && \
    gzip -f -c app.css > app.css.gz && \
    gzip -f -c app.min.css > app.min.css.gz

# Apply Ingasti customizations
COPY branding/logo.png /tmp/snappymail/v/2.38.2/assets/logo.png

# Change theme CSS colors
RUN find /tmp/snappymail/v/2.38.2/themes -name "*.css" -type f -exec sed -i \
    -e 's/#ffffff/#fefefe/g' \
    -e 's/FF6B35/#0066FF/g' \
    -e 's/ff6b35/#0066FF/g' \
    -e 's/F77F00/#0052CC/g' \
    -e 's/f77f00/#0052CC/g' \
    {} \;

# Create final image from official PHP base
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

# Copy customized SnappyMail from customizer stage
# The tar extracts to snappymail/v/2.38.2/..., so copy it to /snappymail/ to get /snappymail/snappymail/v/2.38.2/...
RUN mkdir -p /snappymail
COPY --chown=www-data:www-data --from=customizer /tmp/snappymail /snappymail/snappymail

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
    chmod 444 /snappymail/snappymail/v/2.38.2/static/css/*.css*

# Copy configuration files
COPY .docker/release/files/etc/ /etc/
COPY .docker/release/files/usr/ /usr/
COPY .docker/release/files/supervisor.conf /supervisor.conf
COPY .docker/release/files/entrypoint.sh /entrypoint.sh

# Setup final permissions
RUN set -eux; \
    chown www-data:www-data /snappymail/snappymail/v/2.38.2/include.php; \
    chmod 440 /snappymail/snappymail/v/2.38.2/include.php; \
    chmod +x /entrypoint.sh; \
    mv -v /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf.disabled || true; \
    mv -v /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf.disabled || true; \
    mv -v /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.disabled || true

USER root
WORKDIR /snappymail/snappymail/v/2.38.2
VOLUME /var/lib/snappymail
EXPOSE 8888
EXPOSE 9000
ENTRYPOINT []
CMD ["/entrypoint.sh"]
