import 'package:flutter/material.dart';
import '../widgets/error_tile.dart';

/// Helper class to parse and display beautiful error tiles
class ErrorDisplayHelper {
  /// Parse error message and return appropriate ErrorTile widget
  static Widget buildErrorTile({
    required String error,
    String? tool,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    VoidCallback? onClearCache,
  }) {
    // Parse the error message
    final errorLower = error.toLowerCase();
    
    // QuotaExceededError
    if (errorLower.contains('quotaexceedederror') || 
        errorLower.contains('exceeded the quota') ||
        errorLower.contains('storage quota')) {
      return ErrorTile.quotaExceeded(
        tool: tool,
        onClearCache: onClearCache ?? onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('failed to connect') ||
        errorLower.contains('socketexception')) {
      return ErrorTile.networkError(
        tool: tool,
        details: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Authentication errors
    if (errorLower.contains('unauthorized') ||
        errorLower.contains('authentication') ||
        errorLower.contains('login required') ||
        errorLower.contains('401')) {
      return ErrorTile.authError(
        message: 'Please login to continue using this feature.',
        onLogin: onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Quota/subscription errors
    if (errorLower.contains('quota exceeded') ||
        errorLower.contains('limit reached') ||
        errorLower.contains('subscription') ||
        errorLower.contains('upgrade required')) {
      return ErrorTile(
        title: 'Upgrade Required',
        message: 'You\'ve reached your plan limit. Upgrade to continue.',
        severity: ErrorSeverity.warning,
        technicalDetails: tool != null ? 'Tool: $tool\n$error' : error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Server errors (5xx)
    if (errorLower.contains('500') ||
        errorLower.contains('502') ||
        errorLower.contains('503') ||
        errorLower.contains('server error')) {
      return ErrorTile(
        title: 'Server Error',
        message: 'Our servers are experiencing issues. Please try again later.',
        severity: ErrorSeverity.error,
        technicalDetails: tool != null ? 'Tool: $tool\n$error' : error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Generic processing error
    if (tool != null) {
      return ErrorTile.processingError(
        tool: tool,
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    }
    
    // Generic error fallback
    return ErrorTile(
      title: 'Error',
      message: _getCleanErrorMessage(error),
      severity: ErrorSeverity.error,
      technicalDetails: error,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Show error tile as a bottom sheet
  static void showErrorBottomSheet(
    BuildContext context, {
    required String error,
    String? tool,
    VoidCallback? onRetry,
    VoidCallback? onClearCache,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => buildErrorTile(
        error: error,
        tool: tool,
        onRetry: onRetry,
        onDismiss: () => Navigator.pop(context),
        onClearCache: onClearCache,
      ),
    );
  }

  /// Show error tile as a dialog
  static void showErrorDialog(
    BuildContext context, {
    required String error,
    String? tool,
    VoidCallback? onRetry,
    VoidCallback? onClearCache,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: buildErrorTile(
          error: error,
          tool: tool,
          onRetry: onRetry,
          onDismiss: () => Navigator.pop(context),
          onClearCache: onClearCache,
        ),
      ),
    );
  }

  /// Extract clean user-friendly message from error
  static String _getCleanErrorMessage(String error) {
    // Remove stack traces and technical jargon
    final lines = error.split('\n');
    final firstLine = lines.first.trim();
    
    // Remove common prefixes
    final prefixesToRemove = [
      'Exception: ',
      'Error: ',
      'Failed: ',
      'DioError: ',
      'DioException: ',
    ];
    
    String cleaned = firstLine;
    for (final prefix in prefixesToRemove) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
      }
    }
    
    // If still too long, truncate
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 197)}...';
    }
    
    return cleaned;
  }

  /// Format error for logging with context
  static String formatErrorLog({
    required String error,
    String? tool,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[ErrorLog]');
    if (operation != null) buffer.writeln('Operation: $operation');
    if (tool != null) buffer.writeln('Tool: $tool');
    buffer.writeln('Error: $error');
    
    if (context != null && context.isNotEmpty) {
      buffer.writeln('Context:');
      context.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }
}
