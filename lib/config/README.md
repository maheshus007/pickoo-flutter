# Pickoo Flutter Configuration

This folder contains centralized configuration for the Pickoo Flutter application.

## Configuration File

**`app_config.dart`** - Central configuration hub for all compile-time constants and environment variables.

## Available Configuration Options

### Backend Configuration
- **`BACKEND_URL`** - Backend API base URL
  - Default: `http://localhost:8000`
  - Example: `https://api.pickoo.com`

### Feature Flags
- **`ENABLED_TOOLS`** - Comma-separated list of enabled AI tools
  - Default: `auto_enhance`
  - Available tools:
    - `auto_enhance` - Auto Enhance tool
    - `background_removal` - Background Removal tool
    - `face_retouch` - Face Retouch tool
    - `object_eraser` - Object Eraser tool
    - `sky_replacement` - Sky Replacement tool
    - `super_resolution` - Super Resolution tool
    - `style_transfer` - Artistic Style Transfer tool
    - `all` - Enable all tools
  - Example: `auto_enhance,background_removal,face_retouch`

### Individual Tool Flags (Fine-grained Control)
You can also enable/disable individual tools using specific flags:

- **`ENABLE_AUTO_ENHANCE`** - Auto Enhance tool
  - Default: `true`
  - Description: Automatic image enhancement

- **`ENABLE_BACKGROUND_REMOVAL`** - Background Removal tool
  - Default: `false`
  - Description: Remove background from images

- **`ENABLE_FACE_RETOUCH`** - Face Retouch tool
  - Default: `false`
  - Description: Enhance and retouch facial features

- **`ENABLE_OBJECT_ERASER`** - Object Eraser tool
  - Default: `false`
  - Description: Remove unwanted objects from images

- **`ENABLE_SKY_REPLACEMENT`** - Sky Replacement tool
  - Default: `false`
  - Description: Replace sky in landscape images

- **`ENABLE_SUPER_RESOLUTION`** - Super Resolution tool
  - Default: `false`
  - Description: Enhance image resolution

- **`ENABLE_STYLE_TRANSFER`** - Style Transfer tool
  - Default: `false`
  - Description: Apply artistic styles to images

> **Note:** Individual tool flags take precedence over `ENABLED_TOOLS` string.
> Use `ENABLED_TOOLS=all` to override all individual flags and enable everything.

### Application Information
- **`APP_VERSION`** - Application version string
  - Default: `1.0.0+1`
  - Format: `major.minor.patch+build`

- **`APP_NAME`** - Application display name
  - Default: `Pickoo AI`

### Performance Settings
- **`API_TIMEOUT_SECONDS`** - Request timeout for API calls
  - Default: `60`
  - Unit: seconds

- **`MAX_IMAGE_SIZE_MB`** - Maximum allowed image file size
  - Default: `20`
  - Unit: megabytes

### Storage Settings
- **`MAX_GALLERY_ITEMS`** - Maximum gallery items to store locally
  - Default: `50`

### Debug Settings
- **`DEBUG_MODE`** - Enable debug logging
  - Default: `false`
  - Values: `true` or `false`

- **`VERBOSE_LOGGING`** - Enable verbose API logging
  - Default: `false`
  - Values: `true` or `false`

## Usage Examples

### Development (Local Backend)
```bash
flutter run -d chrome
```

### Production (Remote Backend, All Tools)
```bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=https://api.pickoo.com \
  --dart-define=ENABLED_TOOLS=all \
  --dart-define=APP_VERSION=1.0.0+1
```

### Staging (Only Specific Tools)
```bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=https://staging-api.pickoo.com \
  --dart-define=ENABLED_TOOLS=auto_enhance,background_removal \
  --dart-define=DEBUG_MODE=true
```

### Custom Build for Client Demo
```bash
flutter build web \
  --dart-define=BACKEND_URL=https://demo.pickoo.com \
  --dart-define=ENABLED_TOOLS=auto_enhance,face_retouch \
  --dart-define=APP_NAME="Pickoo Demo" \
  --dart-define=MAX_IMAGE_SIZE_MB=10
```

### Using Individual Tool Flags (Fine-grained Control)
```bash
# Enable specific tools individually
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://localhost:8000 \
  --dart-define=ENABLE_AUTO_ENHANCE=true \
  --dart-define=ENABLE_BACKGROUND_REMOVAL=true \
  --dart-define=ENABLE_FACE_RETOUCH=false \
  --dart-define=ENABLE_OBJECT_ERASER=false \
  --dart-define=ENABLE_SKY_REPLACEMENT=false \
  --dart-define=ENABLE_SUPER_RESOLUTION=false \
  --dart-define=ENABLE_STYLE_TRANSFER=false
```

### Beta Testing Build (Subset of Features)
```bash
flutter build web \
  --dart-define=BACKEND_URL=https://beta.pickoo.com \
  --dart-define=ENABLE_AUTO_ENHANCE=true \
  --dart-define=ENABLE_BACKGROUND_REMOVAL=true \
  --dart-define=ENABLE_FACE_RETOUCH=true \
  --dart-define=APP_NAME="Pickoo Beta" \
  --dart-define=DEBUG_MODE=true
```

## Accessing Configuration in Code

```dart
import 'package:pickoo/config/app_config.dart';

// Access configuration values
final backendUrl = AppConfig.backendUrl;
final appName = AppConfig.appName;
final isDebugMode = AppConfig.debugMode;

// Individual tool flags
final autoEnhanceEnabled = AppConfig.enableAutoEnhance;
final bgRemovalEnabled = AppConfig.enableBackgroundRemoval;

// Check if a specific tool is enabled (recommended method)
if (AppConfig.isToolEnabled('auto_enhance')) {
  // Tool is enabled
}

// Use computed properties
final enabledIds = AppConfig.enabledToolIds; // Set<String>
final allEnabled = AppConfig.allToolsEnabled; // bool
final timeout = AppConfig.apiTimeout; // Duration
final maxSize = AppConfig.maxImageSizeBytes; // int (bytes)
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build Flutter Web
  run: |
    flutter build web \
      --dart-define=BACKEND_URL=${{ secrets.BACKEND_URL }} \
      --dart-define=ENABLED_TOOLS=all \
      --dart-define=APP_VERSION=${{ github.ref_name }}
```

### Environment-Specific Configurations

Create shell scripts for different environments:

**`build-dev.sh`**
```bash
#!/bin/bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://localhost:8000 \
  --dart-define=ENABLED_TOOLS=auto_enhance \
  --dart-define=DEBUG_MODE=true \
  --dart-define=VERBOSE_LOGGING=true
```

**`build-prod.sh`**
```bash
#!/bin/bash
flutter build web --release \
  --dart-define=BACKEND_URL=https://api.pickoo.com \
  --dart-define=ENABLED_TOOLS=all \
  --dart-define=APP_VERSION=1.0.0+1 \
  --dart-define=DEBUG_MODE=false
```

## Best Practices

1. **Never hardcode sensitive values** - Use environment variables or --dart-define
2. **Keep defaults sensible** - Defaults should work for local development
3. **Document all changes** - Update this README when adding new config options
4. **Type safety** - AppConfig provides typed access to all configuration
5. **Centralized management** - All config in one place makes updates easier

## Migration from Old Configuration

Old scattered configuration constants have been migrated to `AppConfig`:
- `kBackendUrl` (tool_provider.dart) → `AppConfig.backendUrl`
- `kEnabledTools` (tool.dart) → `AppConfig.enabledTools`
- `appVersion` (app_info.dart) → `AppConfig.appVersion`
- Hardcoded strings → `AppConfig.appName`

All imports updated to use the centralized config.
