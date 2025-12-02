# GitHub Actions Setup for Pickoo AI Flutter

This document describes how to set up GitHub Actions for automated building and deployment of the Pickoo AI Flutter application to Google Play Store.

## 📋 Required GitHub Secrets

Navigate to your GitHub repository: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### 🔐 Android Signing Secrets

1. **JAVA_KEYSTORE_BASE64**
   - Base64-encoded upload keystore file
   - Generate: `base64 -w 0 upload-keystore.jks > keystore.base64`
   - Copy the content and paste as secret

2. **KEYSTORE_PASSWORD**
   - Password for the keystore file
   - Example: `your-keystore-password`

3. **KEY_ALIAS_PASSWORD**
   - Password for the key alias
   - Example: `your-key-alias-password`

4. **KEY_ALIAS**
   - Alias name for the key
   - Example: `upload`

### 🏪 Google Play Store Secrets

5. **PLAY_SERVICE_ACCOUNT_JSON**
   - Google Play Console service account JSON
   - Steps to create:
     1. Go to Google Play Console
     2. Setup → API access
     3. Create a service account
     4. Download JSON key
     5. Copy entire JSON content as secret

6. **PACKAGE_NAME**
   - Your app's package name
   - Example: `com.pickoo.ai.photo.editor`

### 🌐 Backend Configuration Secrets

7. **BACKEND_URL**
   - Production backend URL
   - Example: `https://api.pickoo.com` or `https://your-backend.elasticbeanstalk.com`

8. **GEMINI_API_KEY** (Optional)
   - Google Gemini API key for AI processing
   - Get from: https://makersuite.google.com/app/apikey

9. **MONGO_URI** (Optional)
   - MongoDB connection string
   - Example: `mongodb+srv://user:pass@cluster.mongodb.net/pickoo`

10. **JWT_SECRET** (Optional)
    - Secret key for JWT token signing
    - Generate: `openssl rand -base64 32`

11. **STRIPE_SECRET_KEY** (Optional)
    - Stripe secret key for payments
    - Example: `sk_live_...`

12. **STRIPE_WEBHOOK_SECRET** (Optional)
    - Stripe webhook signing secret
    - Example: `whsec_...`

## 📦 Optional GitHub Variables

Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Variables` tab

1. **PROCESSOR_MODE**
   - Value: `existing` or `new`
   - Default: `existing`

2. **GEMINI_BASE_URL**
   - Value: `https://generativelanguage.googleapis.com/`
   - Default: same as value

3. **GEMINI_MODEL**
   - Value: `gemini-2.0-flash-exp`
   - Default: same as value

## 🔧 Generating Android Keystore

If you don't have a keystore yet:

```bash
# Generate a new keystore
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Convert to base64
base64 -w 0 upload-keystore.jks > keystore.base64

# On Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File keystore.base64
```

## 📝 Setting up Google Play Console

### 1. Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable "Google Play Android Developer API"
4. Create service account:
   - IAM & Admin → Service Accounts → Create Service Account
   - Name: `pickoo-ci-cd`
   - Grant role: `Service Account User`
5. Create key (JSON format)
6. Download the JSON file

### 2. Link Service Account to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Setup → API access
3. Link the service account
4. Grant permissions:
   - View app information and download bulk reports
   - Manage production releases
   - Manage testing track releases

## 🚀 Workflow Triggers

The workflow runs on:
- **Push to `main` branch**: Full build + deploy to Play Store
- **Push to `develop` branch**: Build only (no deploy)
- **Pull requests to `main`**: Build and test only

## 📱 Deployment Tracks

The workflow deploys to **Internal Testing** track by default. To change:

Edit `.github/workflows/android-release.yml`:
```yaml
--track internal  # Change to: alpha, beta, production
```

## 🔄 Build Numbers

Build numbers are automatically incremented using `${{ github.run_number }}`.

## 📊 Artifacts

Each successful build uploads:
- `app-release.aab` - Android App Bundle (for Play Store)
- `app-release.apk` - APK file (for testing)
- `web-release` - Flutter web build

Artifacts are retained for:
- AAB/APK: 30 days
- Web: 15 days

## 🧪 Testing the Workflow

### Option 1: Test on develop branch
```bash
git checkout develop
git add .
git commit -m "test: CI/CD workflow"
git push origin develop
```

### Option 2: Test locally with act
```bash
# Install act (GitHub Actions locally)
# brew install act  # macOS
# choco install act-cli  # Windows

# Run the workflow
act push -s BACKEND_URL=http://localhost:8000
```

## 📖 Workflow Steps Explained

1. **Checkout** - Clone repository
2. **Setup Flutter** - Install Flutter SDK
3. **Dependencies** - Run `flutter pub get`
4. **Tests** - Run `flutter test`
5. **Build Web** - Build Flutter web version
6. **Backend Setup** - Optional backend for integration tests
7. **Decode Keystore** - Decode base64 keystore (main branch only)
8. **Build AAB** - Build Android App Bundle
9. **Build APK** - Build APK for artifacts
10. **Upload Artifacts** - Save build outputs
11. **Setup Fastlane** - Install Ruby and Fastlane
12. **Deploy** - Upload to Play Store (main branch only)
13. **Cleanup** - Remove sensitive files

## 🔍 Monitoring Deployments

Check deployment status:
1. Go to your GitHub repository
2. Click "Actions" tab
3. Select the workflow run
4. View logs and artifacts

Check Play Store status:
1. Go to Google Play Console
2. Release → Testing → Internal testing
3. View the latest release

## 🛠️ Troubleshooting

### Build fails with "Keystore not found"
- Verify `JAVA_KEYSTORE_BASE64` secret is set correctly
- Check base64 encoding has no line breaks

### Fastlane upload fails
- Verify `PLAY_SERVICE_ACCOUNT_JSON` is valid JSON
- Check service account has proper permissions in Play Console
- Ensure app exists in Play Console with at least one manual upload

### Backend connection fails
- Verify `BACKEND_URL` is accessible from GitHub Actions
- Check if backend requires authentication

### Flutter version mismatch
- Update `flutter-version` in workflow to match your local version
- Run `flutter --version` locally to check

## 📚 Additional Resources

- [Flutter CI/CD Documentation](https://docs.flutter.dev/deployment/cd)
- [Fastlane for Android](https://docs.fastlane.tools/getting-started/android/setup/)
- [Google Play Console API](https://developers.google.com/android-publisher)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🔄 Updating the Workflow

To modify deployment behavior:

```yaml
# Deploy to different track
--track production  # or alpha, beta

# Skip upload for specific conditions
if: github.event_name == 'push' && github.ref == 'refs/heads/main'

# Add version tags
--version-code ${{ github.run_number }}
--version-name "1.0.${{ github.run_number }}"
```

## 📞 Support

For issues with:
- **Workflow**: Check GitHub Actions logs
- **Play Store**: Contact Google Play Console support
- **Fastlane**: Visit [Fastlane Docs](https://docs.fastlane.tools)

---

**Last Updated**: November 18, 2025  
**Maintained By**: Mahesh U S
