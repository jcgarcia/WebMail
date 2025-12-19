# WebMail Troubleshooting - December 18, 2025

## Current Status: HTTP 502 Error

### Issue Summary
WebMail application returns HTTP ERROR 502 when accessing https://mail.ingasti.com/

### What's Working ✅
1. **Build Pipeline**: Dockerfile builds successfully, image pushes to `ghcr.io/ingasti/snappymail:branding`
2. **Registry Authentication**: Added `imagePullSecrets: ghcr-credentials` - pods now pull images successfully
3. **Pod Status**: Pod is Running (1/1 Ready)
4. **Nginx & PHP-FPM**: Both services running inside container
5. **File Structure**: Correct nested path `/snappymail/snappymail/v/2.38.2/`
6. **Data Path**: Fixed include.php to use `/var/lib/snappymail/` (no more data folder errors)
7. **Volume Mount**: Corrected to `/var/lib/snappymail`

### Current Problem ❌
**Port Mismatch**: 
- Nginx is listening on port **8888** inside container
- Kubernetes service expects port **80**
- Result: Connection refused → HTTP 502

### Investigation Details

#### Pod Logs (Good - No Errors)
```
[INFO] Snappymail version: 2.38.2
[INFO] Setting permissions on /var/lib/snappymail
nginx_00 entered RUNNING state
php-fpm_00 entered RUNNING state
[18-Dec-2025 17:09:02] NOTICE: fpm is running, pid 29
[18-Dec-2025 17:09:02] NOTICE: ready to handle connections
[INFO] Services ready, initializing application
[INFO] Application initialized
```

#### Network Check (Port Mismatch Found)
```bash
$ kubectl exec snappymail-6d797ccc7c-752pf -- netstat -tlnp
Proto Local Address           State       PID/Program name
tcp   0.0.0.0:8888            LISTEN      28/nginx
tcp   :::8888                 LISTEN      28/nginx
tcp   :::9000                 LISTEN      29/php-fpm
```

#### Current k8s Configuration
```yaml
# Deployment - containerPort
ports:
- containerPort: 80  # WRONG - should be 8888

# Service - targetPort
ports:
- port: 80
  targetPort: 80     # WRONG - should be 8888
```

## Files Fixed Today

### 1. Dockerfile
- ✅ Fixed path structure to create `/snappymail/snappymail/v/2.38.2/`
- ✅ Added copy of custom `include.php` with correct data path
- Commits: 7310136

### 2. k8s/deployment.yaml
- ✅ Added `imagePullSecrets: ghcr-credentials` for registry auth
- ✅ Fixed volume mount from `/var/snappymail/data` to `/var/lib/snappymail`
- ✅ Fixed image reference to `ghcr.io/ingasti/snappymail:branding`
- ❌ **TODO**: Fix containerPort from 80 to 8888
- Commits: 45f1c92, ff2b154

### 3. publish-WebMail script
- ✅ Fixed `WIP_DIR` to point to repo root instead of tools/scripts/

## Tomorrow's Fix Plan

### Step 1: Fix Port Configuration
```bash
cd ~/GitProjects/WebMail/webmail-wip
```

Edit `k8s/deployment.yaml`:
```yaml
# Change containerPort from 80 to 8888
ports:
- containerPort: 8888  # Match nginx config

# Change service targetPort
ports:
- port: 80
  targetPort: 8888     # Route external 80 to internal 8888
```

### Step 2: Deploy
```bash
git add k8s/deployment.yaml
git commit -m "Fix port configuration: nginx listens on 8888"
tools/scripts/publish-WebMail -a
jenkins-factory build webmail -f
```

### Step 3: Verify
```bash
# Wait for deployment
ssh oracledev "kubectl -n webmail get pods"

# Test from inside pod
ssh oracledev "kubectl -n webmail exec <pod-name> -- curl -I http://localhost:8888"

# Test from external
curl -I https://mail.ingasti.com/
```

Expected result: HTTP 200 with SnappyMail login page

## Key Learning

The Dockerfile exposes ports 8888 and 9000:
```dockerfile
EXPOSE 8888
EXPOSE 9000
```

But k8s deployment.yaml was configured for port 80. This mismatch caused the 502 error because the service was routing traffic to a port where nothing was listening.

## Repository Locations
- Private dev: `~/GitProjects/WebMail/webmail-wip/`
- Public repo: `~/wip/pub/WebMail/`
- GitHub: `git@github.com:jcgarcia/WebMail.git`
- Registry: `ghcr.io/ingasti/snappymail:branding`
- Jenkins job: `webmail`
- k8s namespace: `webmail`
- URL: https://mail.ingasti.com/

## Related Projects for Reference
- Blog project: `~/GitProjects/Blog/Blog/` (working ghcr.io deployment with imagePullSecrets)
