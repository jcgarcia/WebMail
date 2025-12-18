# Branding Assets

Custom branding assets for SnappyMail deployment.

## Files

- `logo.png` - Custom logo for the webmail interface

## Applying Customization

SnappyMail supports customization through the admin panel:

1. Access admin panel: `https://mail.ingasti.com/?admin`
2. Go to **Branding** section
3. Set **Title**: "Ingasti Mail"
4. Set **Logo URL**: Upload or link to custom logo
5. Choose **Theme**: Select preferred theme

### Logo Options

**Option 1: External URL**
- Host logo on a public URL
- Set in admin panel: Logo URL = `https://your-url/logo.png`

**Option 2: Upload via Admin**
- Some themes support logo upload directly

**Option 3: Custom Theme**
- Create custom theme with embedded logo
- Place in `/var/lib/snappymail/themes/`

### Configuration File

Advanced settings can be set in `/var/lib/snappymail/_data_/_default_/configs/application.ini`:

```ini
[webmail]
title = "Ingasti Mail"
loading_description = "Ingasti Mail"

[branding]
; Custom branding options
```

## Post-Deployment Steps

After deploying SnappyMail:

1. Access `https://mail.ingasti.com/?admin`
2. Login with admin credentials (set on first access)
3. Configure branding settings
4. Configure default mail domain (cmh.ingasti.com)
