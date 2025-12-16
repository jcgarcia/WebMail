# WebMail (SnappyMail) Troubleshooting Guide

## Issue: Endless Authentication Loop

### Problem Description
When accessing `https://mail.ingasti.com`, users get stuck in an endless loop between the auth portal (auth.ingasti.com) and the mail portal. Instead of reaching SnappyMail's login page, the browser keeps redirecting to the authentication portal even after successful GitHub authentication.

**Symptoms:**
1. User authenticates at auth.ingasti.com via GitHub
2. Browser redirects to mail.ingasti.com
3. Instead of showing SnappyMail login page, redirects back to auth.ingasti.com
4. Cycle repeats endlessly

### Root Cause
The issue occurs when the WebMail Kubernetes namespace is recreated (e.g., after deletion or namespace refresh). When this happens:

1. **New Service IP is assigned** - The k8s service gets a new ClusterIP (e.g., old: `10.43.61.100`, new: `10.43.127.9`)
2. **Caddyfile becomes outdated** - The reverse proxy configuration on oracledev still points to the old service IP
3. **Caddy can't reach the backend** - Requests to the old IP fail silently or timeout
4. **Authorization fails** - Caddy's `authorize with mypolicy` directive fails because it can't verify the backend is reachable
5. **Redirect loop** - Caddy re-authorizes the user, which creates a redirect loop

### Solution

#### Step 1: Identify the New Service IP

```bash
# On oracledev
ssh oracledev 'kubectl -n webmail get svc snappymail -o jsonpath="{.spec.clusterIP}"'
```

Example output: `10.43.127.9`

#### Step 2: Check Current Caddyfile Configuration

```bash
ssh oracledev 'sudo grep -A 10 "# WebMail" /etc/caddy/Caddyfile'
```

Look for the `reverse_proxy` line. It should show the current service IP.

#### Step 3: Update Caddyfile with New IP (if needed)

If the IP in Caddyfile is outdated, restore from the working backup and update:

```bash
# Backup current Caddyfile
ssh oracledev 'sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup-$(date +%s)'

# Restore from Dec 11 working version
ssh oracledev 'sudo cp /etc/caddy/Caddyfile.old /etc/caddy/Caddyfile'

# Replace old IP with new IP (get the IP from Step 1)
ssh oracledev 'sudo sed -i "s/10.43.61.100/10.43.127.9/g" /etc/caddy/Caddyfile'
```

#### Step 4: Validate and Reload Caddy

```bash
# Validate configuration
ssh oracledev 'sudo caddy validate --config /etc/caddy/Caddyfile'

# Reload Caddy
ssh oracledev 'sudo caddy reload --config /etc/caddy/Caddyfile'
```

#### Step 5: Verify the Fix

```bash
# Check that WebMail is now redirecting properly
curl -sI https://mail.ingasti.com/ | head -10

# Should show:
# HTTP/2 302
# location: https://auth.ingasti.com?redirect_url=https%3A%2F%2Fmail.ingasti.com%2F
```

After authenticating at auth.ingasti.com, you should now reach SnappyMail's login page.

### Checking Caddy Logs

To verify authorization is working:

```bash
# View recent logs
ssh oracledev 'sudo journalctl -u caddy -n 100 --no-pager | grep -A 2 "acl rule hit"'

# Should show entries like:
# "action":"allow",...,"user":{"name":"Your Name","roles":["authp/user"]}
```

This confirms Caddy is recognizing authenticated users and allowing them through.

### Key Configuration (Reference)

The correct WebMail block in `/etc/caddy/Caddyfile` should look like:

```caddyfile
# WebMail - SnappyMail (PROTECTED - SSO)
mail.ingasti.com {
    authorize with mypolicy

    reverse_proxy 10.43.127.9:80 {
        header_up X-Auth-User {http.auth.user.email}
        header_up X-Auth-Name {http.auth.user.name}
    }

    log {
        output file /var/log/caddy/webmail.log
    }
}
```

**Important:**
- `authorize with mypolicy` - Protects the endpoint via SSO
- `reverse_proxy <IP>:80` - Must point to the current k8s service ClusterIP
- `header_up X-Auth-*` - Passes authenticated user info to SnappyMail

### Prevention

To avoid this issue in the future:

1. **Keep `/etc/caddy/Caddyfile.old` updated** - After each successful Caddyfile change, backup a working version
2. **Document service IPs** - Track k8s service IPs in the WebMail README
3. **Automate IP updates** - Consider using k8s DNS name (`snappymail.webmail.svc.cluster.local`) instead of IP in reverse_proxy (requires DNS resolution in Caddy)

### Related Files

- `/etc/caddy/Caddyfile` - Caddy configuration on oracledev
- `/etc/caddy/Caddyfile.old` - Backup of working configuration
- `k8s/deployment.yaml` - WebMail k8s deployment (defines service)
- `/var/log/caddy/webmail.log` - WebMail access logs on oracledev

### Quick Reference Commands

```bash
# Get WebMail service IP
ssh oracledev 'kubectl -n webmail get svc snappymail -o jsonpath="{.spec.clusterIP}"'

# Check pod status
ssh oracledev 'kubectl -n webmail get pods'

# Check pod logs
ssh oracledev 'kubectl -n webmail logs $(kubectl -n webmail get pods -o name | head -1)'

# Test SnappyMail is responding
ssh oracledev 'curl -s http://10.43.127.9:80/ | head -5'

# View Caddy WebMail configuration
ssh oracledev 'sudo grep -A 15 "# WebMail" /etc/caddy/Caddyfile'

# View Caddy webmail logs
ssh oracledev 'sudo tail -50 /var/log/caddy/webmail.log'
```

---

**Last Updated:** 2025-12-16  
**Fixed By:** GitHub Copilot  
**Issue:** Endless auth loop after k8s namespace recreation
