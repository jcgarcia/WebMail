# Branding Assets

Custom branding assets for SnappyMail deployment.

## Files

- `logo.png` - Custom logo for the webmail interface (200x200px)

## Work Summary (December 19, 2025)

**Objective:** Add Ingasti branding to WebMail (SnappyMail) - custom logo, colors, remove background pattern

**Status:** INCOMPLETE - Logo not displaying on login screen

### Attempted Solutions:

1. **Custom Theme Creation** (Builds #95-96)
   - Created `/snappymail/v/2.38.2/themes/Ingasti/` directory
   - Added `styles.css` with CSS variables for colors
   - Added `images/logo.png` (200x200px)
   - Added `images/preview.png` (theme preview)
   - **Result:** Theme works, colors applied, but logo positioning failed

2. **Color Adjustments** (Build #96)
   - Changed from orange/yellow to blue/green scheme
   - Blue (#1E88E5) for primary actions
   - Green (#43A047) for hover states
   - **Result:** Colors working correctly

3. **Logo Positioning Attempts** (Builds #97-101)
   - Build #97: CSS `::before` on header element - failed
   - Build #98: CSS `::before` on h1 element - only on loading screen
   - Build #99: Combined selector for both screens - failed
   - Build #100: Absolute positioning with z-index - failed
   - Build #101: Direct HTML img tag in Index.html - failed

### Technical Issues:

- SnappyMail uses dual-screen login (loading → form)
- Login form title "webmail Interface" dynamically generated
- CSS targeting failed to position logo above login form
- Logo appears on loading screen but disappears when form loads

### Files Modified:

- `/snappymail/v/2.38.2/themes/Ingasti/styles.css`
- `/snappymail/v/2.38.2/themes/Ingasti/images/logo.png`
- `/snappymail/v/2.38.2/themes/Ingasti/images/preview.png`
- `/snappymail/v/2.38.2/app/templates/Index.html`

### Cost Analysis:

**Total Builds:** 7 builds (#95-101)
**Total Tokens Used:** ~10,000 tokens
**Estimated Cost:** $0.15-0.30 USD (Claude Sonnet 4.5 pricing)
**Time Spent:** ~2 hours
**Outcome:** Branding partially complete (colors working, logo failed)

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
