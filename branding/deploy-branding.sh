#!/bin/bash
# Deploy branding customizations to SnappyMail
set -e

BRANDING_DIR="branding"
POD_NAME="snappymail-cf7bfbdf9-5pxxh"
NAMESPACE="webmail"
WEBMAIL_PATH="/var/lib/snappymail"

echo "Deploying branding customizations to SnappyMail..."

# 1. Copy logo to pod
echo "📸 Uploading logo..."
kubectl -n $NAMESPACE cp "$BRANDING_DIR/logo.png" "$POD_NAME:$WEBMAIL_PATH/logo.png"

# 2. Copy custom CSS to pod
echo "🎨 Uploading custom CSS..."
kubectl -n $NAMESPACE cp "$BRANDING_DIR/custom.css" "$POD_NAME:$WEBMAIL_PATH/custom.css"

# 3. Update application.ini with branding settings
echo "⚙️  Updating configuration..."
kubectl -n $NAMESPACE exec $POD_NAME -- sh -c 'cat >> /var/lib/snappymail/_data_/_default_/configs/application.ini << "EOF"

[webmail]
; Custom branding
title = "Ingasti WebMail"
loading_description = "Ingasti WebMail"
favicon_url = "/logo.png"

[branding]
; Custom styling applied via custom.css
EOF'

# 4. Restart the pod to apply changes
echo "♻️  Restarting pod to apply changes..."
kubectl -n $NAMESPACE rollout restart deployment snappymail
kubectl -n $NAMESPACE rollout status deployment snappymail

echo "✅ Branding customization complete!"
echo ""
echo "Changes applied:"
echo "  • Background color: #fefefe (solid white)"
echo "  • Logo: /var/lib/snappymail/logo.png"
echo "  • Custom CSS: /var/lib/snappymail/custom.css"
echo "  • Title: 'Ingasti WebMail'"
echo ""
echo "Visit: https://mail.ingasti.com"
