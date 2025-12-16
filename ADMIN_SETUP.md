# SnappyMail Admin Setup Guide

## Quick Access to Admin Panel

### Admin Credentials
- **Login**: `admin`
- **Password**: `jLApGpGDq8Pe`
- **TOTP Code**: (leave empty)

### Accessing the Admin Panel

The admin panel is accessible at: **`https://mail.ingasti.com/?admin`**

**Flow:**
1. Navigate to `https://mail.ingasti.com/?admin`
2. You will be redirected to GitHub OAuth at `https://auth.ingasti.com`
3. Authenticate with your GitHub account
4. You will be redirected back to SnappyMail Admin Panel login
5. Enter credentials above and click "LOG INTO THE ADMIN PANEL"

## Admin Panel Setup Tasks

### 1. Configure Email Domains

After logging into the admin panel, you need to configure which email domains users can authenticate against.

**Default Configuration:**
- By default, SnappyMail comes with a `default.json` domain configuration
- You can view/edit domains in the admin panel under **Domains** section

**Steps to Add a Domain:**
1. Go to **Domains** in the admin panel
2. Click **Add Domain** (or edit existing)
3. Configure:
   - **IMAP Server**: Your mail server address (e.g., `imap.example.com`)
   - **IMAP Port**: Usually `993` (SSL) or `143` (PLAIN)
   - **IMAP SSL/TLS**: Enable for secure connection
   - **SMTP Server**: Your SMTP server (e.g., `smtp.example.com`)
   - **SMTP Port**: Usually `465` (SSL) or `587` (TLS)
   - **SMTP SSL/TLS**: Enable as appropriate

### 2. Test Domain Configuration

Once configured:
1. Go back to the SnappyMail login page: `https://mail.ingasti.com`
2. Enter an email address from your configured domain
3. Enter the corresponding IMAP password
4. Click "SIGN IN"

If successful, you'll see your mailbox interface.

### 3. Admin Tasks Available

In the Admin Panel you can:

- **Domains**: Add, edit, disable email domains
- **Security**: Configure admin password, TOTP, security policies
- **Interface**: Customize UI theme, language, login screen
- **Mail Settings**: Configure message per page, refresh intervals, attachment limits
- **Logs**: View system logs and authentication attempts
- **Contacts**: Enable/disable contact sync, configure database
- **Plugins**: Enable/disable plugins (if any installed)
- **Updates**: Check for SnappyMail updates (if enabled)

## Current Configuration Status

### Deployment Info
- **URL**: `https://mail.ingasti.com`
- **SSO Protection**: Enabled via Caddy (GitHub OAuth)
- **Container Image**: `djmaze/snappymail:latest` (v2.38.2)
- **Kubernetes Namespace**: `webmail`
- **Storage**: Persistent Volume at `/var/lib/snappymail`

### System Configuration
```ini
[security]
allow_admin_panel = On
admin_login = "admin"
custom_server_signature = "SnappyMail"
force_https = Off
```

```ini
[defaults]
autologout = 30
messages_per_page = 20
allow_additional_accounts = On
allow_additional_identities = On
```

```ini
[admin_panel]
host = ""
key = "admin"
allow_update = Off
```

## Data Location

All SnappyMail configuration and data is stored in the Kubernetes PVC at:
```
/var/lib/snappymail/
├── _data_/
│   └── _default_/
│       ├── configs/
│       │   └── application.ini      # Main configuration file
│       ├── domains/                 # Domain configurations
│       │   ├── default.json
│       │   └── [other-domains].json
│       ├── admin_password.txt       # Plain text admin password
│       └── cache/                   # Cache files
├── INSTALLED                        # Marker file (app initialized)
└── SALT.php                         # Encryption salt
```

## Troubleshooting Admin Access

### Issue: "404 Not Found" when accessing admin

**Cause**: Caddy reverse proxy routing issue or service IP mismatch

**Solution**: 
1. Verify service IP is correct in Caddyfile:
```bash
ssh oracledev 'kubectl -n webmail get svc'
```
2. Check current Caddyfile configuration:
```bash
ssh oracledev 'grep -A 10 "mail.ingasti.com" /etc/caddy/Caddyfile'
```
3. If IP is wrong, update it and reload Caddy:
```bash
ssh oracledev 'sudo sed -i "s/10.43.X.X/10.43.127.9/g" /etc/caddy/Caddyfile && sudo caddy reload -c /etc/caddy/Caddyfile'
```

### Issue: Endless redirect loop between auth and login

**Cause**: Service IP changed when namespace was recreated

**Solution**: See `TROUBLESHOOTING.md` - Caddyfile IP Configuration section

### Issue: Admin password not working

**Cause**: Password was changed or pod was restarted without persistent storage

**Steps to reset**:
1. Connect to pod:
```bash
ssh oracledev 'kubectl -n webmail exec -it snappymail-* -- sh'
```
2. Find and delete the admin password file:
```bash
rm /var/lib/snappymail/_data_/_default_/admin_password.txt
```
3. Restart the pod:
```bash
ssh oracledev 'kubectl -n webmail rollout restart deployment snappymail'
```
4. Check for new auto-generated password:
```bash
ssh oracledev 'kubectl -n webmail exec snappymail-* -- cat /var/lib/snappymail/_data_/_default_/admin_password.txt'
```

## Important Notes

### Security Considerations

1. **Default Password**: The password `jLApGpGDq8Pe` is a generated default. **Change it immediately after first login**:
   - Admin Panel → Security → Change Admin Password

2. **TOTP (Two-Factor Authentication)**: Can be enabled for extra security:
   - Admin Panel → Security → Set TOTP Code

3. **SSO Integration**: Currently, SnappyMail uses GitHub OAuth via Caddy for:
   - **Access Protection**: Only authenticated GitHub users can reach mail.ingasti.com
   - **User Identification**: SnappyMail logs show authenticated user info
   - **NOT for Mail Login**: Mail credentials (IMAP) are still required at SnappyMail login

### Data Persistence

- All configurations, domains, and cached data are stored in the Kubernetes PVC
- **DO NOT DELETE** the namespace without backing up the PVC
- If PVC is deleted, all configuration is lost and must be set up again

### Admin Panel URL Format

SnappyMail admin panel uses this URL scheme:
- **Full path**: `/?admin` (the `?admin` parameter toggles admin mode)
- **Proxy consideration**: When accessed through Caddy reverse proxy at `mail.ingasti.com`, the URL becomes `https://mail.ingasti.com/?admin`

## Initial Setup Checklist

- [ ] Access admin panel at `https://mail.ingasti.com/?admin`
- [ ] Log in with credentials above
- [ ] Change admin password to something secure
- [ ] Add your email domain(s) in Domains section
- [ ] Configure IMAP/SMTP settings for each domain
- [ ] Test login with a real email account
- [ ] Configure auto-logout time (default: 30 minutes)
- [ ] Enable plugins if needed
- [ ] Set up TOTP for admin account (recommended)
- [ ] Verify logs are being written correctly

## Next Steps

1. **Add Email Domains**: Go to Admin Panel → Domains → Add Domain
2. **Configure IMAP/SMTP**: Set up connection details for your mail servers
3. **Test Access**: Log in with a user account to verify everything works
4. **Set Security Options**: Change default password, enable TOTP, configure security policies
5. **Monitor Logs**: Check logs regularly for authentication issues or errors

For detailed troubleshooting, see `TROUBLESHOOTING.md`.
