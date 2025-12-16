#!/bin/sh
# Custom entrypoint that injects branding CSS before starting snappymail

# Inject custom CSS into the main template
cat > /tmp/inject-css.php << 'EOF'
<?php
// Inject custom branding CSS
$customCSS = '/var/lib/snappymail/custom-styles.css';
if (file_exists($customCSS)) {
    echo '<style>';
    readfile($customCSS);
    echo '</style>';
}
?>
EOF

# Create a wrapper for index.php that includes our custom CSS
mkdir -p /snappymail-custom
cp /snappymail/index.php /snappymail-custom/index.php

# Modify to include custom CSS injection
sed -i "/<\/head>/i $(cat /tmp/inject-css.php | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')" /snappymail-custom/index.php

# Start the original entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"
