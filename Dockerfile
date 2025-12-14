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

# Create final image from official PHP base
FROM php:8.2-fpm-alpine

LABEL org.label-schema.description="SnappyMail WebMail (Ingasti Custom) using nginx, php-fpm on Alpine"

# Install runtime dependencies
RUN apk add --no-cache ca-certificates nginx supervisor bash

# Install essential PHP extensions for SnappyMail (minimal set to reduce build time)
RUN set -eux; \
    apk add --no-cache --virtual .build-dependencies $PHPIZE_DEPS; \
    pecl install apcu; \
    docker-php-ext-enable apcu; \
    docker-php-source delete; \
    apk del .build-dependencies;

# GD for image handling
RUN set -eux; \
    apk add --no-cache freetype libjpeg-turbo libpng; \
    apk add --no-cache --virtual .deps freetype-dev libjpeg-turbo-dev libpng-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install gd; \
    apk del .deps

# Core extensions
RUN docker-php-ext-install pdo_mysql opcache zip

# Optional: PostgreSQL support (comment out if not needed)
RUN set -eux; \
    apk add --no-cache postgresql-libs; \
    apk add --no-cache --virtual .deps postgresql-dev; \
    docker-php-ext-install pdo_pgsql; \
    apk del .deps

# Copy customized SnappyMail from customizer stage
COPY --chown=www-data:www-data --from=customizer /tmp/snappymail /snappymail
RUN mv -v /snappymail/data /var/lib/snappymail

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
