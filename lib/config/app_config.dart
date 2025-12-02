/// Centralized configuration for Pickoo Flutter app.
/// Combines environment, backend, payment, and feature flags.
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Environment configuration
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // Backend API base URL (alias of BACKEND_URL)
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    // Default to deployed backend; override via --dart-define as needed
    defaultValue: 'http://pickoo-backend-new-env.eba-87fqh8rp.ap-south-1.elasticbeanstalk.com',
  );

  // API timeouts
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 60,
  );
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  // Payment configuration
  static const String googlePayMerchantId = String.fromEnvironment(
    'GOOGLE_PAY_MERCHANT_ID',
    defaultValue: '',
  );
  static const String googlePayMerchantName = String.fromEnvironment(
    'GOOGLE_PAY_MERCHANT_NAME',
    defaultValue: 'Pickoo AI',
  );
  static const String paymentEnvironment = String.fromEnvironment(
    'PAYMENT_ENVIRONMENT',
    defaultValue: 'TEST',
  );

  // Application info
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Pickoo AI',
  );
  static const int maxImageSizeMB = int.fromEnvironment(
    'MAX_IMAGE_SIZE_MB',
    defaultValue: 20,
  );

  // Feature flags (tools)
  static const String enabledTools = String.fromEnvironment(
    'ENABLED_TOOLS',
    defaultValue: 'auto_enhance',
  );
  static const bool enableAutoEnhance = bool.fromEnvironment(
    'ENABLE_AUTO_ENHANCE',
    defaultValue: true,
  );
  static const bool enableBackgroundRemoval = bool.fromEnvironment(
    'ENABLE_BACKGROUND_REMOVAL',
    defaultValue: false,
  );
  
  /// Face Retouch - Enhance and retouch facial features
  static const bool enableFaceRetouch = bool.fromEnvironment(
    'ENABLE_FACE_RETOUCH',
    defaultValue: false,
  );
  
  /// Object Eraser - Remove unwanted objects from images
  static const bool enableObjectEraser = bool.fromEnvironment(
    'ENABLE_OBJECT_ERASER',
    defaultValue: false,
  );
  
  /// Sky Replacement - Replace sky in landscape images
  static const bool enableSkyReplacement = bool.fromEnvironment(
    'ENABLE_SKY_REPLACEMENT',
    defaultValue: false,
  );
  
  /// Super Resolution - Enhance image resolution
  static const bool enableSuperResolution = bool.fromEnvironment(
    'ENABLE_SUPER_RESOLUTION',
    defaultValue: false,
  );
  
  /// Style Transfer - Apply artistic styles to images
  static const bool enableStyleTransfer = bool.fromEnvironment(
    'ENABLE_STYLE_TRANSFER',
    defaultValue: false,
  );
  
  /// Gallery Configuration
  /// Maximum number of items to store in local gallery
  static const int maxGalleryItems = int.fromEnvironment(
    'MAX_GALLERY_ITEMS',
    defaultValue: 50,
  );
  
  // Debug flags
  static const bool debugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);
  static const bool verboseLogging = bool.fromEnvironment('VERBOSE_LOGGING', defaultValue: false);
  static const bool enablePayments = bool.fromEnvironment('ENABLE_PAYMENTS', defaultValue: true);
  static const bool enableAIFeatures = bool.fromEnvironment('ENABLE_AI_FEATURES', defaultValue: true);
  
  // Computed properties
  
  /// Get list of enabled tool IDs from comma-separated string
  static Set<String> get enabledToolIds {
    return enabledTools.split(',').map((e) => e.trim()).toSet();
  }
  
  /// Check if all tools should be enabled
  static bool get allToolsEnabled {
    return enabledTools.toLowerCase() == 'all';
  }
  
  /// Check if a specific tool is enabled
  /// Uses both individual flags and the enabledTools string
  static bool isToolEnabled(String toolId) {
    // If 'all' is specified, enable all tools
    if (allToolsEnabled) return true;
    
    // Check individual tool flags first (takes precedence)
    switch (toolId) {
      case 'auto_enhance':
        return enableAutoEnhance;
      case 'background_removal':
        return enableBackgroundRemoval;
      case 'face_retouch':
        return enableFaceRetouch;
      case 'object_eraser':
        return enableObjectEraser;
      case 'sky_replacement':
        return enableSkyReplacement;
      case 'super_resolution':
        return enableSuperResolution;
      case 'style_transfer':
        return enableStyleTransfer;
      default:
        // Fall back to checking the comma-separated list
        return enabledToolIds.contains(toolId);
    }
  }
  
  /// Get API timeout as Duration
  static Duration get apiTimeout {
    return Duration(seconds: apiTimeoutSeconds);
  }
  
  /// Get max image size in bytes
  static int get maxImageSizeBytes {
    return maxImageSizeMB * 1024 * 1024;
  }
  
  // Helper booleans for environment
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
}
