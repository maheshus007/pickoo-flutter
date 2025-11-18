# 🔐 Complete Guide: Setting Up GitHub Secrets for Play Store Deployment

This guide provides **exact commands and steps** to generate and configure all required secrets.

---

## 📋 Prerequisites

- Android Studio installed
- Git Bash or PowerShell
- Access to Google Play Console
- Google Cloud Platform account

---

## 🔑 Step-by-Step Setup

### 1️⃣ Generate Android Signing Keystore

**Open PowerShell and run:**

```powershell
# Navigate to your project
cd "d:\CodeSurge\Python\Photo Editor\pickoo-flutter\android\app"

# Generate keystore (will prompt for passwords)
keytool -genkey -v -keystore upload-keystore.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload

# You'll be prompted for:
# - Keystore password (remember this - you'll need it!)
# - Key password (can be same as keystore password)
# - Your name, organization, city, state, country
```

**Important**: Save these passwords! You'll need them for GitHub secrets.

---

### 2️⃣ Convert Keystore to Base64

```powershell
# Still in android/app directory
# Convert keystore to base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File -Encoding ASCII keystore-base64.txt

# View the content (this is your JAVA_KEYSTORE_BASE64 value)
Get-Content keystore-base64.txt
```

**Copy the entire output** - this is your `JAVA_KEYSTORE_BASE64` secret.

---

### 3️⃣ Get Package Name

```powershell
# Navigate to project root
cd "d:\CodeSurge\Python\Photo Editor\pickoo-flutter"

# Find package name in build.gradle
Select-String -Path "android\app\build.gradle" -Pattern "applicationId"
```

**Output will show something like:**
```
applicationId "com.pickoo.ai.photo.editor"
```

Copy the package name (without quotes) - this is your `PACKAGE_NAME` secret.

---

### 4️⃣ Create Google Play Service Account

#### A. Create Service Account in Google Cloud Console

1. **Go to Google Cloud Console**: https://console.cloud.google.com
2. **Create/Select Project**:
   - Click project dropdown at top
   - Click "New Project"
   - Name: `Pickoo AI`
   - Click "Create"

3. **Enable Google Play Android Developer API**:
   - Search for "Google Play Android Developer API"
   - Click "Enable"

4. **Create Service Account**:
   - Go to: IAM & Admin → Service Accounts
   - Click "Create Service Account"
   - Name: `pickoo-ci-cd`
   - Description: `GitHub Actions CI/CD for Pickoo`
   - Click "Create and Continue"
   - Role: `Service Account User`
   - Click "Continue" → "Done"

5. **Create JSON Key**:
   - Click on the service account you just created
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Select "JSON"
   - Click "Create"
   - **File will auto-download** (save this securely!)

#### B. Link Service Account to Play Console

1. **Go to Google Play Console**: https://play.google.com/console
2. **Setup → API Access**
3. Click "Link" next to your service account
4. Grant permissions:
   - ☑️ View app information and download bulk reports
   - ☑️ Manage production releases
   - ☑️ Manage testing track releases
5. Click "Invite user" → "Send invitation"

#### C. Get JSON Content for GitHub Secret

```powershell
# If your service account JSON is in Downloads
cd $env:USERPROFILE\Downloads

# Display the JSON (this is your PLAY_SERVICE_ACCOUNT_JSON value)
Get-Content "pickoo-ai-*.json" | Out-String
```

**Copy the entire JSON output** - this is your `PLAY_SERVICE_ACCOUNT_JSON` secret.

---

### 5️⃣ Get Backend URL

Your backend URL depends on where it's deployed:

**Options:**

**A. Local Development** (not recommended for production):
```
http://localhost:8000
```

**B. If using AWS Elastic Beanstalk** (from your backend setup):
```
https://your-backend.elasticbeanstalk.com
```

**C. If using other hosting**:
- Heroku: `https://your-app.herokuapp.com`
- Railway: `https://your-app.railway.app`
- Google Cloud Run: `https://your-service-xxxxx.run.app`

**Check your current backend setup:**
```powershell
cd "d:\CodeSurge\Python\Photo Editor\pickoo-backend"
# Check if there's a deployment config
Get-ChildItem -Filter "*.eb*" -Recurse
```

---

## 🔧 Setting Secrets in GitHub

### Method 1: Via GitHub Web Interface (Recommended)

1. **Go to your repository secrets page**:
   ```
   https://github.com/maheshus007/pickoo-flutter/settings/secrets/actions
   ```

2. **Click "New repository secret"** for each secret:

   | Secret Name | Value Source | Example |
   |------------|--------------|---------|
   | `JAVA_KEYSTORE_BASE64` | From step 2 (base64 file content) | `MIIKGQIBAz...` (very long string) |
   | `KEYSTORE_PASSWORD` | Password you entered in step 1 | `MySecurePassword123!` |
   | `KEY_ALIAS_PASSWORD` | Key password from step 1 | `MySecurePassword123!` |
   | `KEY_ALIAS` | Alias name from step 1 | `upload` |
   | `PLAY_SERVICE_ACCOUNT_JSON` | From step 4C (JSON file content) | `{"type":"service_account",...}` |
   | `PACKAGE_NAME` | From step 3 | `com.pickoo.ai.photo.editor` |
   | `BACKEND_URL` | From step 5 | `https://your-backend.com` |

3. **For each secret**:
   - Click "New repository secret"
   - Enter the name (e.g., `KEYSTORE_PASSWORD`)
   - Paste the value
   - Click "Add secret"

### Method 2: Via GitHub CLI (Advanced)

```powershell
# Install GitHub CLI if not installed
winget install GitHub.cli

# Login to GitHub
gh auth login

# Set secrets (replace with your actual values)
cd "d:\CodeSurge\Python\Photo Editor\pickoo-flutter"

# Set keystore (from base64 file)
gh secret set JAVA_KEYSTORE_BASE64 < android\app\keystore-base64.txt

# Set passwords (you'll be prompted to enter)
gh secret set KEYSTORE_PASSWORD
gh secret set KEY_ALIAS_PASSWORD
gh secret set KEY_ALIAS

# Set package name
gh secret set PACKAGE_NAME -b "com.pickoo.ai.photo.editor"

# Set Play Store JSON (from downloaded file)
gh secret set PLAY_SERVICE_ACCOUNT_JSON < "$env:USERPROFILE\Downloads\pickoo-ai-*.json"

# Set backend URL
gh secret set BACKEND_URL -b "https://your-backend.com"
```

---

## ✅ Verify Secrets are Set

### Via Web:
1. Go to: https://github.com/maheshus007/pickoo-flutter/settings/secrets/actions
2. You should see all 7 secrets listed (values are hidden)

### Via CLI:
```powershell
gh secret list
```

---

## 🚀 Test the Deployment

Once all secrets are set:

```powershell
# Make a small change and push to main
cd "d:\CodeSurge\Python\Photo Editor\pickoo-flutter"

# Switch to main branch
git checkout -b main
git merge develop

# Push to trigger deployment
git push origin main

# Watch the workflow
# Go to: https://github.com/maheshus007/pickoo-flutter/actions
```

---

## 🔍 Troubleshooting

### "Keystore not found" error
```powershell
# Verify base64 encoding worked
cd "d:\CodeSurge\Python\Photo Editor\pickoo-flutter\android\app"
Get-Content keystore-base64.txt | Measure-Object -Character
# Should show thousands of characters
```

### "Service account not authorized" error
- Double-check you invited the service account in Play Console
- Wait 10 minutes after invitation (propagation delay)
- Verify JSON is complete and valid

### "Package name mismatch" error
```powershell
# Verify package name matches
Select-String -Path "android\app\build.gradle" -Pattern "applicationId"
Select-String -Path "android\app\src\main\AndroidManifest.xml" -Pattern "package"
# Both should match
```

---

## 📝 Summary Checklist

- [ ] ✅ Keystore generated (`upload-keystore.jks`)
- [ ] ✅ Keystore converted to base64
- [ ] ✅ Passwords saved securely
- [ ] ✅ Package name identified
- [ ] ✅ Service account created in Google Cloud
- [ ] ✅ Service account JSON downloaded
- [ ] ✅ Service account linked to Play Console
- [ ] ✅ Backend URL determined
- [ ] ✅ All 7 secrets added to GitHub
- [ ] ✅ Secrets verified in GitHub settings

---

## 🎯 Quick Reference Card

Save this for future reference:

```
Repository: https://github.com/maheshus007/pickoo-flutter
Secrets Page: https://github.com/maheshus007/pickoo-flutter/settings/secrets/actions
Actions Page: https://github.com/maheshus007/pickoo-flutter/actions
Play Console: https://play.google.com/console

Keystore Location: android/app/upload-keystore.jks
Alias: upload
Package: com.pickoo.ai.photo.editor (update if different)
```

---

**Created**: November 18, 2025  
**Last Updated**: November 18, 2025  
**Maintained By**: Mahesh U S
