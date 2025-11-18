/// Centralized configuration for Pickoo Flutter app.
/// All environment variables and compile-time constants are defined here.
/// 
/// Usage:
///   - Set values at compile-time using --dart-define flags
///   - Example: flutter run -d chrome --dart-define=BACKEND_URL=https://api.example.com
///
/// Environment Variables:
///   - BACKEND_URL: Backend API base URL (default: http://localhost:8000)
///   - ENABLED_TOOLS: Comma-separated list of enabled tool IDs (default: auto_enhance)
///                    Use 'all' to enable all tools
///   - APP_VERSION: Application version string (default: 1.0.0+1)
///   - APP_NAME: Application display name (default: Pickoo AI)

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  /// Backend API Configuration
  /// The base URL for the FastAPI backend server.
  /// Can be overridden at compile-time with --dart-define=BACKEND_URL=...
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  /// Feature Flags - Enabled Tools
  /// Comma-separated list of tool IDs to enable in the UI.
  /// Available tools: auto_enhance, background_removal, face_retouch, 
  ///                  object_eraser, sky_replacement, super_resolution, style_transfer
  /// Use 'all' to enable all tools.
  /// Can be overridden with --dart-define=ENABLED_TOOLS=...
  static const String enabledTools = String.fromEnvironment(
    'ENABLED_TOOLS',
    defaultValue: 'auto_enhance',
  );
  
  /// Individual Tool Flags (can be overridden at compile-time)
  /// Auto Enhance - Automatic image enhancement
  static const bool enableAutoEnhance = bool.fromEnvironment(
    'ENABLE_AUTO_ENHANCE',
    defaultValue: true,
  );
  
  /// Background Removal - Remove background from images
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
  
  /// Application Information
  /// Application version and build number
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );
  
  /// Application display name
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Pickoo AI',
  );
  
  /// API Timeouts (in seconds)
  /// Request timeout for API calls
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 60,
  );
  
  /// Maximum image file size in MB
  static const int maxImageSizeMB = int.fromEnvironment(
    'MAX_IMAGE_SIZE_MB',
    defaultValue: 20,
  );
  
  /// Gallery Configuration
  /// Maximum number of items to store in local gallery
  static const int maxGalleryItems = int.fromEnvironment(
    'MAX_GALLERY_ITEMS',
    defaultValue: 50,
  );
  
  /// Development/Debug flags
  /// Enable debug logging
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );
  
  /// Enable verbose API logging
  static const bool verboseLogging = bool.fromEnvironment(
    'VERBOSE_LOGGING',
    defaultValue: false,
  );
  
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
}
