#!/bin/bash
set -e

# Build custom SnappyMail image on ARM with proper CSS modifications
# This script prepares the image by extracting, modifying, and recompressing CSS files

WORK_DIR="/tmp/snappymail-build"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Building Custom SnappyMail Image on ARM ==="
echo "Working directory: $WORK_DIR"
echo "Repository: $REPO_DIR"

# Create working directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/extract"
cd "$WORK_DIR"

# Download SnappyMail release
echo "Downloading SnappyMail v2.38.2..."
wget -q https://github.com/the-djmaze/snappymail/releases/download/v2.38.2/snappymail-2.38.2.tar.gz

# Extract
echo "Extracting..."
tar -xzf snappymail-2.38.2.tar.gz -C extract/
rm snappymail-2.38.2.tar.gz

SNAPPY_PATH="$WORK_DIR/extract/snappymail"

# Modify CSS files - CRITICAL FIX: Remove LoginView button background override
# The original CSS has: .LoginView .btn,.LoginView input{background:0 0;}
# This removes the button from that rule so it keeps the blue color
echo "Modifying CSS files..."

# Apply the critical CSS fix
if [ -f "$SNAPPY_PATH/v/2.38.2/static/css/app.css" ]; then
    echo "  - Fixing app.css (removing .LoginView .btn from background override)..."
    sed -i 's/.LoginView .btn,.LoginView input{background:0 0;/.LoginView input{background:0 0;/g' "$SNAPPY_PATH/v/2.38.2/static/css/app.css"
fi

if [ -f "$SNAPPY_PATH/v/2.38.2/static/css/app.min.css" ]; then
    echo "  - Fixing app.min.css..."
    sed -i 's/.LoginView .btn,.LoginView input{background:0 0;/.LoginView input{background:0 0;/g' "$SNAPPY_PATH/v/2.38.2/static/css/app.min.css"
fi

# 3. Recompress CSS files (if gzip tools available)
if command -v gzip &> /dev/null; then
    echo "  - Recompressing CSS files..."
    cd "$SNAPPY_PATH/v/2.38.2/static/css/"
    
    # Recompress minified files
    [ -f app.css ] && gzip -9 -f -k app.css
    [ -f app.min.css ] && gzip -9 -f -k app.min.css
    [ -f admin.css ] && gzip -9 -f -k admin.css || true
    [ -f admin.min.css ] && gzip -9 -f -k admin.min.css || true
    [ -f boot.min.css ] && gzip -9 -f -k boot.min.css || true
    
    cd "$WORK_DIR"
fi

# 4. Copy logo
echo "Copying logo..."
mkdir -p "$SNAPPY_PATH/v/2.38.2/themes/Default/images"
cp "$REPO_DIR/branding/logo.png" "$SNAPPY_PATH/v/2.38.2/themes/Default/images/ingasti-logo.png" 2>/dev/null || echo "  Logo not found, skipping"

# 5. Verify changes
echo "Verifying changes in app.min.css..."
if grep -q "#0066FF" "$SNAPPY_PATH/v/2.38.2/static/css/app.min.css"; then
    echo "  ✓ Blue color (#0066FF) found in app.min.css"
else
    echo "  ✗ WARNING: Blue color not found in app.min.css"
fi

# 6. Create new tar.gz with modified files
echo "Creating modified tar.gz..."
cd "$WORK_DIR/extract"
tar -czf "$WORK_DIR/snappymail-modified.tar.gz" snappymail/

echo "Modified archive: $WORK_DIR/snappymail-modified.tar.gz"

# 7. Build Docker image
echo ""
echo "Building Docker image..."
cd "$REPO_DIR"

# Create a temporary Dockerfile that uses the modified tar.gz
cat > "$WORK_DIR/Dockerfile.local" << 'DOCKERFILE'
FROM alpine:3.18.5 AS base
COPY snappymail-modified.tar.gz /tmp/
RUN tar -xzf /tmp/snappymail-modified.tar.gz -C /tmp/ && rm /tmp/snappymail-modified.tar.gz

FROM php:8.2-fpm-alpine3.21

LABEL org.label-schema.description="SnappyMail WebMail (Ingasti Custom) using nginx, php-fpm on Alpine"

RUN apk add --no-cache ca-certificates nginx supervisor bash

RUN set -eux; \
    apk add --no-cache freetype libjpeg-turbo libpng libzip postgresql-libs; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        freetype-dev libjpeg-turbo-dev libpng-dev \
        libzip-dev postgresql-dev; \
    pecl install apcu; \
    docker-php-ext-enable apcu; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install gd; \
    docker-php-ext-install pdo_mysql zip pdo_pgsql; \
    docker-php-source delete; \
    apk del .build-deps

COPY --chown=www-data:www-data --from=base /tmp/snappymail /snappymail
RUN set -eux; \
    mkdir -p /var/lib/snappymail; \
    if [ -d /snappymail/data ]; then mv /snappymail/data/* /var/lib/snappymail/ || true; fi; \
    chown -R www-data:www-data /var/lib/snappymail; \
    chmod -R 700 /var/lib/snappymail; \
    mkdir -p /var/lib/snappymail/_data_/_default_/{cache,configs,domains,plugins,storage}; \
    chown -R www-data:www-data /var/lib/snappymail/_data_; \
    chmod -R 700 /var/lib/snappymail/_data_

COPY docker-nginx.conf /etc/nginx/http.d/default.conf
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888
ENTRYPOINT ["/entrypoint.sh"]
DOCKERFILE

# Build with the modified files
docker build -f "$WORK_DIR/Dockerfile.local" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t ghcr.io/ingasti/snappymail:branding \
    "$WORK_DIR"

echo ""
echo "✓ Image built: ghcr.io/ingasti/snappymail:branding"
echo ""
echo "Pushing to GitHub Container Registry..."
docker push ghcr.io/ingasti/snappymail:branding

echo ""
echo "✓ Image pushed successfully!"
echo ""
echo "Now trigger the WebMail job in Jenkins to deploy:"
echo "  jenkins-factory build webmail"
