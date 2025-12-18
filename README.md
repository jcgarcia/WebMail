# WebMail

Web-based email client (SnappyMail) for accessing accounts on Central Mail Hub.

## Overview

- **URL**: https://mail.ingasti.com
- **Application**: SnappyMail
- **Authentication**: Caddy AuthCrunch SSO
- **Mail Server**: cmh.ingasti.com (IMAP/SMTP)

## Features

- Web access to email from any browser
- Multi-account support
- Modern responsive UI
- Works with any IMAP/SMTP server

## Deployment

### Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check status
kubectl -n webmail get pods
kubectl -n webmail get svc
```

### Post-Deployment Configuration

1. Access admin panel: `https://mail.ingasti.com/?admin`
2. Configure default domain with IMAP/SMTP settings:
   - Server: cmh.ingasti.com
   - IMAP: Port 993 (SSL/TLS)
   - SMTP: Port 587 (STARTTLS)

## Architecture

```
User → mail.ingasti.com → Caddy (SSO) → K8s Service → SnappyMail Pod
                                              ↓
                                         PersistentVolume (256Mi)
                                              ↓
                                         cmh.ingasti.com (IMAP/SMTP)
```

## Storage

PersistentVolume (256Mi) stores:
- Application configuration
- Domain settings
- User preferences

Emails remain on the IMAP server (CMH), not stored locally.

## Project Structure

- `k8s/` - Kubernetes deployment manifests
- `activity/` - Development tracking and planning
- `docs/` - Technical documentation

## Development

All development happens in this WIP repository:

```bash
pnpm install
pnpm dev
```

## Publishing

Use the publishing script to sync changes to the public repository:

```bash
./publish-WebMail -c   # Create distribution
./publish-WebMail -p   # Push to GitHub
./publish-WebMail      # Create and push
```

## Activity Tracking

This project uses structured activity tracking. See [`activity/README.md`](./activity/README.md) for details.

### Quick Start

1. Review current context: `activity/status/current-context.md`
2. Work on your tasks
3. Save session: `cp activity/templates/status-template.md activity/status/session-$(date +%Y-%m-%d-%H%M).md`

## Repositories

- **Private WIP**: git@github.com:Ingasti/webmail-wip.git
- **Public**: git@github.com:jcgarcia/WebMail.git

## Author

Julio Cesar Garcia

## Created

2025-12-11 with gitproject v       2.2
