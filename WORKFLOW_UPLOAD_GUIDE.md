# 🚀 Quick Guide: Add Workflows via GitHub Web Interface

Since the Personal Access Token lacks the `workflow` scope, here's how to add the workflows manually through GitHub's web interface:

## 📝 Step-by-Step Instructions

### 1. Go to Your Repository
Visit: https://github.com/maheshus007/pickoo-flutter

### 2. Create Workflows Directory

1. Click on "Add file" → "Create new file"
2. In the filename field, type: `.github/workflows/android-release.yml`
3. This will automatically create the directories

### 3. Copy Workflow Content

Open the local file at:
```
d:\CodeSurge\Python\Photo Editor\pickoo-flutter\.github\workflows\android-release.yml
```

Copy the entire content and paste it into the GitHub web editor.

### 4. Commit the File

- Add commit message: `ci: Add Android CI/CD workflow`
- Select "Commit directly to the `develop` branch"
- Click "Commit new file"

### 5. Repeat for Other Workflow Files

**File 2: manual-deploy.yml**
- Click "Add file" → "Create new file"
- Filename: `.github/workflows/manual-deploy.yml`
- Copy content from local file
- Commit message: `ci: Add manual deployment workflow`
- Commit to `develop`

**File 3: README.md**
- Click "Add file" → "Create new file"
- Filename: `.github/workflows/README.md`
- Copy content from local file
- Commit message: `docs: Add CI/CD workflow documentation`
- Commit to `develop`

### 6. Verify Workflows

1. Go to "Actions" tab in your repository
2. You should see the new workflows listed
3. They will be triggered on the next push to `develop` or `main`

## 🎯 Alternative: Update Your Token (Better for Future)

To avoid this issue in the future:

1. Go to: https://github.com/settings/tokens
2. Click on your current token or "Generate new token"
3. **Check the `workflow` box** under permissions
4. Click "Update token" or "Generate token"
5. Copy the new token
6. Update your git credentials:
   ```bash
   git config --global credential.helper manager
   # Then try pushing again - it will prompt for new token
   ```

## 📊 After Adding Workflows

Once workflows are added, they will automatically run when:
- ✅ You push to `develop` branch (build only)
- ✅ You push to `main` branch (build + deploy to Play Store)
- ✅ You manually trigger from Actions tab

## 🔐 Configure Secrets

After workflows are added, configure secrets at:
https://github.com/maheshus007/pickoo-flutter/settings/secrets/actions

### Required Secrets:
```
JAVA_KEYSTORE_BASE64
KEYSTORE_PASSWORD
KEY_ALIAS_PASSWORD
KEY_ALIAS
PLAY_SERVICE_ACCOUNT_JSON
PACKAGE_NAME
BACKEND_URL
GEMINI_API_KEY (optional)
```

See the full list in: `.github/workflows/README.md`

## ✅ Quick Test After Setup

Make a small change and push:
```bash
# Make any small change
echo "# Test" >> test.txt

# Commit and push
git add test.txt
git commit -m "test: Trigger workflow"
git push origin develop

# Check Actions tab to see workflow running
```

---

**Note**: The workflow files are already created in your local repository. You just need to add them to GitHub via the web interface or update your token to push them.

**Local files location**:
- `d:\CodeSurge\Python\Photo Editor\pickoo-flutter\.github\workflows\android-release.yml`
- `d:\CodeSurge\Python\Photo Editor\pickoo-flutter\.github\workflows\manual-deploy.yml`
- `d:\CodeSurge\Python\Photo Editor\pickoo-flutter\.github\workflows\README.md`
