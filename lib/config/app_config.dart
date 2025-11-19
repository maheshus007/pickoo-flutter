/// Application-wide configuration
/// Centralized management of API URLs, keys, and environment settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================
  
  /// Current environment: development, staging, production
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // ============================================================================
  // API CONFIGURATION
  // ============================================================================
  
  /// Backend API base URL
  /// Override at compile time: flutter run --dart-define=API_BASE_URL=http://localhost:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://pickoo-backend-new-env.eba-87fqh8rp.ap-south-1.elasticbeanstalk.com',
  );

  /// API timeout duration in seconds
  static const int apiTimeoutSeconds = 30;

  /// API connection timeout in milliseconds
  static const int connectTimeoutMs = 30000;

  /// API receive timeout in milliseconds
  static const int receiveTimeoutMs = 30000;

  // ============================================================================
  // PAYMENT CONFIGURATION
  // ============================================================================
  
  /// Google Pay Merchant ID
  static const String googlePayMerchantId = String.fromEnvironment(
    'GOOGLE_PAY_MERCHANT_ID',
    defaultValue: '',
  );

  /// Google Pay Merchant Name
  static const String googlePayMerchantName = String.fromEnvironment(
    'GOOGLE_PAY_MERCHANT_NAME',
    defaultValue: 'Pickoo AI Photo Editor',
  );

  /// Payment gateway environment: TEST or PRODUCTION
  static const String paymentEnvironment = String.fromEnvironment(
    'PAYMENT_ENVIRONMENT',
    defaultValue: 'TEST',
  );

  // ============================================================================
  // APP CONFIGURATION
  // ============================================================================
  
  /// Application name
  static const String appName = 'Pickoo AI Photo Editor';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Maximum image size in MB
  static const int maxImageSizeMB = 10;

  /// Supported image formats
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  
  /// Enable payment features
  static const bool enablePayments = bool.fromEnvironment(
    'ENABLE_PAYMENTS',
    defaultValue: true,
  );

  /// Enable AI features
  static const bool enableAIFeatures = bool.fromEnvironment(
    'ENABLE_AI_FEATURES',
    defaultValue: true,
  );

  /// Enable debug logging
  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: false,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging mode
  static bool get isStaging => environment == 'staging';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';

  /// Get formatted API URL with endpoint
  static String getApiUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    // Ensure base URL doesn't end with slash
    String baseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    
    return '$baseUrl/$endpoint';
  }

  /// Print configuration (for debugging)
  static void printConfig() {
    if (enableDebugLogging) {
      print('=== App Configuration ===');
      print('Environment: $environment');
      print('API Base URL: $apiBaseUrl');
      print('Google Pay Merchant ID: ${googlePayMerchantId.isEmpty ? "Not Set" : "***"}');
      print('Payment Environment: $paymentEnvironment');
      print('Enable Payments: $enablePayments');
      print('Enable AI Features: $enableAIFeatures');
      print('========================');
    }
  }
}
