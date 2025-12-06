# Firebase Hosting Deployment Guide

## Prerequisites

Before deploying, ensure you have:
- ✅ Node.js installed (check with `node --version`)
- ✅ Firebase CLI installed (check with `firebase --version`)
- ✅ A Firebase project created (you should already have this)
- ✅ Flutter web build working locally

## Step-by-Step Deployment Process

### Step 1: Install Firebase CLI (if not already installed)

```powershell
npm install -g firebase-tools
```

Verify installation:
```powershell
firebase --version
```

### Step 2: Login to Firebase

```powershell
firebase login
```

This will open a browser window for you to authenticate with your Google account.

### Step 3: Initialize Firebase Hosting

Navigate to your project directory and run:
```powershell
cd c:\Users\User\Desktop\silsila_dawrah
firebase init hosting
```

**Configuration Options:**
1. **Use an existing project**: Select your Firebase project (the one you're using for Firestore)
2. **What do you want to use as your public directory?**: Enter `build/web`
3. **Configure as a single-page app?**: Enter `y` (Yes)
4. **Set up automatic builds with GitHub?**: Enter `n` (No)
5. **File build/web/index.html already exists. Overwrite?**: Enter `n` (No)

### Step 4: Build Your Flutter Web App

Build the production version:
```powershell
flutter build web --release
```

**Optional**: Build with web renderer (if you have rendering issues):
```powershell
flutter build web --release --web-renderer html
```

Or for better performance with CanvasKit:
```powershell
flutter build web --release --web-renderer canvaskit
```

### Step 5: Deploy to Firebase Hosting

```powershell
firebase deploy --only hosting
```

Wait for the deployment to complete. You'll see output like:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/YOUR-PROJECT/overview
Hosting URL: https://YOUR-PROJECT.web.app
```

### Step 6: Access Your Deployed App

Your app will be available at:
- `https://YOUR-PROJECT.web.app`
- `https://YOUR-PROJECT.firebaseapp.com`

---

## Quick Deployment Commands

After initial setup, use these commands for future deployments:

```powershell
# Build and deploy in one go
flutter build web --release && firebase deploy --only hosting

# Deploy with a custom message
firebase deploy --only hosting -m "Updated attendance export feature"

# Preview before deploying
firebase hosting:channel:deploy preview
```

---

## Troubleshooting

### Issue: "Firebase command not found"
**Solution**: Install Firebase CLI
```powershell
npm install -g firebase-tools
```

### Issue: Build fails
**Solution**: Clean and rebuild
```powershell
flutter clean
flutter pub get
flutter build web --release
```

### Issue: White screen after deployment
**Solution**: Check browser console for errors. May need to:
1. Clear browser cache
2. Check Firebase configuration
3. Verify base href in `web/index.html`

### Issue: Assets not loading
**Solution**: Ensure `firebase.json` has correct rewrites:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## Configuration Files

### firebase.json (will be created automatically)
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### .firebaserc (will be created automatically)
```json
{
  "projects": {
    "default": "your-project-id"
  }
}
```

---

## Performance Optimization

### 1. Enable Compression
Firebase Hosting automatically compresses files, but ensure your build is optimized:
```powershell
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### 2. Cache Headers
Add to `firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

### 3. Use CanvasKit for Better Performance
```powershell
flutter build web --release --web-renderer canvaskit
```

---

## Custom Domain (Optional)

To use a custom domain:

1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow the DNS configuration steps
4. Wait for SSL certificate provisioning (can take up to 24 hours)

---

## Continuous Deployment (Optional)

### Using GitHub Actions

Create `.github/workflows/firebase-hosting.yml`:
```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

---

## Security Considerations

1. **Firestore Rules**: Ensure your Firestore security rules are properly configured
2. **API Keys**: Your Firebase config in `web/index.html` is public (this is normal)
3. **Authentication**: Ensure proper authentication is enforced
4. **CORS**: Configure CORS if accessing external APIs

---

## Monitoring

After deployment, monitor your app:
- **Firebase Console**: Check hosting metrics
- **Analytics**: Enable Google Analytics for user tracking
- **Performance**: Use Firebase Performance Monitoring
- **Crashlytics**: Monitor errors and crashes

---

## Rollback

If you need to rollback to a previous version:
```powershell
firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL_ID TARGET_SITE_ID:live
```

Or from Firebase Console:
1. Go to Hosting → Release history
2. Click on a previous deployment
3. Click "Rollback"

---

## Cost Considerations

Firebase Hosting Free Tier:
- ✅ 10 GB storage
- ✅ 360 MB/day transfer
- ✅ Custom domain
- ✅ SSL certificate

For most small to medium apps, the free tier is sufficient!
