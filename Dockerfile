# syntax=docker/dockerfile:1
# SnappyMail WebMail with Ingasti Customizations
# Use pre-built SnappyMail release and apply customizations

FROM alpine:3.18.5 AS customizer
RUN apk add --no-cache bash imagemagick wget

# Download and extract SnappyMail release
WORKDIR /tmp
RUN wget -q https://github.com/the-djmaze/snappymail/releases/download/v2.38.2/snappymail-2.38.2.tar.gz && \
    tar -xzf snappymail-2.38.2.tar.gz && \
    rm snappymail-2.38.2.tar.gz

# Apply Ingasti customizations
COPY branding/logo.png /tmp/snappymail/assets/logo.png
RUN find /tmp/snappymail -name "*.css" -type f -exec sed -i 's/#ffffff/#fefefe/g' {} \;

# Create final image from official PHP base (Alpine 3.21 for postgresql-libs support)
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
COPY --chown=www-data:www-data --from=customizer /tmp/snappymail /snappymail
RUN set -eux; \
    mkdir -p /var/lib/snappymail; \
    if [ -d /snappymail/data ]; then mv /snappymail/data/* /var/lib/snappymail/ || true; fi; \
    chown -R www-data:www-data /var/lib/snappymail

# Copy configuration files from SnappyMail release
COPY .docker/release/files/ /

# Setup permissions
RUN set -eux; \
    chown www-data:www-data /snappymail/include.php; \
    chmod 440 /snappymail/include.php; \
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
