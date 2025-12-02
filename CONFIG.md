# Flutter Application Configuration

## Overview

All application configuration is centralized in `lib/config/app_config.dart` for easy management and environment-specific overrides.

## Configuration Categories

### 1. **API Configuration**
- `apiBaseUrl` - Backend API base URL
- `apiTimeoutSeconds` - API timeout duration
- `connectTimeoutMs` - Connection timeout
- `receiveTimeoutMs` - Receive timeout

### 2. **Payment Configuration**
- `googlePayMerchantId` - Google Pay merchant ID
- `googlePayMerchantName` - Business name for Google Pay
- `paymentEnvironment` - TEST or PRODUCTION

### 3. **Feature Flags**
- `enablePayments` - Enable/disable payment features
- `enableAIFeatures` - Enable/disable AI features
- `enableDebugLogging` - Enable/disable debug logging

## Environment-Specific Configuration

### Development
```bash
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=ENABLE_DEBUG_LOGGING=true
```

### Staging
```bash
flutter run \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=API_BASE_URL=http://pickoo-backend-new-env.ap-south-1.elasticbeanstalk.com \
  --dart-define=PAYMENT_ENVIRONMENT=TEST
```

### Production
```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.pickoo.app \
  --dart-define=GOOGLE_PAY_MERCHANT_ID=your_merchant_id \
  --dart-define=GOOGLE_PAY_MERCHANT_NAME="Pickoo AI Photo Editor" \
  --dart-define=PAYMENT_ENVIRONMENT=PRODUCTION \
  --dart-define=ENABLE_PAYMENTS=true \
  --dart-define=ENABLE_AI_FEATURES=true
```

## Usage in Code

### Import the config
```dart
import 'package:your_app/config/app_config.dart';
```

### Access configuration values
```dart
// Get API base URL
String apiUrl = AppConfig.apiBaseUrl;

// Get full API endpoint URL
String endpoint = AppConfig.getApiUrl('process');
// Returns: http://your-api.com/process

// Check environment
if (AppConfig.isDevelopment) {
  print('Running in development mode');
}

// Check feature flags
if (AppConfig.enablePayments) {
  // Show payment UI
}

// Print configuration (for debugging)
AppConfig.printConfig();
```

### Using in Dio/HTTP clients
```dart
final dio = Dio(BaseOptions(
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
  receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
));
```

## GitHub Actions Integration

Add these secrets to your GitHub repository:

### Required Secrets
- `API_BASE_URL` - Backend API URL
- `GOOGLE_PAY_MERCHANT_ID` - Google Pay merchant ID
- `GOOGLE_PAY_MERCHANT_NAME` - Business name

### Example Workflow
```yaml
- name: Build Flutter App
  run: |
    flutter build apk --release \
      --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \
      --dart-define=GOOGLE_PAY_MERCHANT_ID=${{ secrets.GOOGLE_PAY_MERCHANT_ID }} \
      --dart-define=GOOGLE_PAY_MERCHANT_NAME="${{ secrets.GOOGLE_PAY_MERCHANT_NAME }}" \
      --dart-define=ENVIRONMENT=production \
      --dart-define=PAYMENT_ENVIRONMENT=PRODUCTION
```

## Default Values

The configuration includes sensible defaults for quick development:

| Variable | Default Value |
|----------|--------------|
| `ENVIRONMENT` | `production` |
| `API_BASE_URL` | `http://pickoo-backend-new-env.ap-south-1.elasticbeanstalk.com` |
| `GOOGLE_PAY_MERCHANT_NAME` | `Pickoo AI Photo Editor` |
| `PAYMENT_ENVIRONMENT` | `TEST` |
| `ENABLE_PAYMENTS` | `true` |
| `ENABLE_AI_FEATURES` | `true` |
| `ENABLE_DEBUG_LOGGING` | `false` |

## Benefits

✅ **Centralized Management** - All config in one place  
✅ **Environment Flexibility** - Easy switching between dev/staging/prod  
✅ **Type Safety** - Compile-time constants  
✅ **No Hardcoding** - No URLs scattered across codebase  
✅ **CI/CD Ready** - Easy integration with GitHub Actions  
✅ **Feature Flags** - Toggle features without code changes  

## Best Practices

1. **Never hardcode URLs** - Always use `AppConfig.apiBaseUrl`
2. **Use feature flags** - Check `AppConfig.enablePayments` before showing payment UI
3. **Environment checks** - Use `AppConfig.isDevelopment` for debug features
4. **Override in CI/CD** - Pass `--dart-define` flags in deployment pipelines
5. **Secure secrets** - Never commit merchant IDs or API keys to git

## Migration Guide

### Before (❌ Hardcoded)
```dart
final dio = Dio(BaseOptions(baseUrl: 'http://52.66.135.108'));
```

### After (✅ Centralized)
```dart
final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
```

---

For more information, see `lib/config/app_config.dart`
