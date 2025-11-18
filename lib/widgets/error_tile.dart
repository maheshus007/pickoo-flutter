import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Beautiful error tile widget for displaying errors in a user-friendly format
/// Shows error category, message, and action buttons
class ErrorTile extends StatelessWidget {
  final String title;
  final String message;
  final ErrorSeverity severity;
  final String? technicalDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showCopyButton;

  const ErrorTile({
    super.key,
    required this.title,
    required this.message,
    this.severity = ErrorSeverity.error,
    this.technicalDetails,
    this.onRetry,
    this.onDismiss,
    this.showCopyButton = true,
  });

  /// Factory constructor for quota exceeded errors
  factory ErrorTile.quotaExceeded({
    String? tool,
    VoidCallback? onClearCache,
    VoidCallback? onDismiss,
  }) {
    return ErrorTile(
      title: 'Storage Quota Exceeded',
      message: tool != null 
          ? 'Processing failed for $tool. Your device storage is full. Clear some space or app cache to continue.'
          : 'Your device storage is full. Clear some space or app cache to continue.',
      severity: ErrorSeverity.warning,
      technicalDetails: tool != null ? 'Tool: $tool\nError: QuotaExceededError on setItem()' : null,
      onRetry: onClearCache,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for network errors
  factory ErrorTile.networkError({
    String? tool,
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ErrorTile(
      title: 'Connection Failed',
      message: tool != null
          ? 'Failed to process $tool. Check your internet connection and try again.'
          : 'Network connection failed. Check your internet and try again.',
      severity: ErrorSeverity.error,
      technicalDetails: details,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for processing errors
  factory ErrorTile.processingError({
    required String tool,
    required String error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ErrorTile(
      title: 'Processing Failed',
      message: 'Failed to apply $tool effect. Please try again.',
      severity: ErrorSeverity.error,
      technicalDetails: 'Tool: $tool\nError: $error',
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for authentication errors
  factory ErrorTile.authError({
    String? message,
    VoidCallback? onLogin,
    VoidCallback? onDismiss,
  }) {
    return ErrorTile(
      title: 'Authentication Required',
      message: message ?? 'Please login to continue using this feature.',
      severity: ErrorSeverity.warning,
      onRetry: onLogin,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  colors.icon,
                  color: colors.iconColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colors.titleColor.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          
          // Message body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: colors.messageColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                // Technical details (collapsible)
                if (technicalDetails != null) ...[
                  const SizedBox(height: 12),
                  _TechnicalDetailsSection(
                    details: technicalDetails!,
                    colors: colors,
                  ),
                ],
                
                // Action buttons
                if (onRetry != null || showCopyButton) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (onRetry != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: Icon(
                              severity == ErrorSeverity.warning 
                                  ? Icons.cleaning_services 
                                  : Icons.refresh,
                              size: 18,
                            ),
                            label: Text(
                              severity == ErrorSeverity.warning 
                                  ? 'Clear Cache' 
                                  : 'Retry',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (onRetry != null && showCopyButton && technicalDetails != null)
                        const SizedBox(width: 12),
                      if (showCopyButton && technicalDetails != null)
                        OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(context),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.buttonColor,
                            side: BorderSide(color: colors.buttonColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final text = '''
$title
$message

Technical Details:
$technicalDetails
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _ErrorColors _getColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (severity) {
      case ErrorSeverity.error:
        return _ErrorColors(
          backgroundColor: isDark ? const Color(0xFF2D1517) : const Color(0xFFFFF5F5),
          borderColor: isDark ? const Color(0xFFE53E3E) : const Color(0xFFFEB2B2),
          headerColor: isDark ? const Color(0xFF3D1A1D) : const Color(0xFFFEE2E2),
          shadowColor: Colors.red.withOpacity(0.1),
          icon: Icons.error_outline,
          iconColor: isDark ? const Color(0xFFFC8181) : const Color(0xFFE53E3E),
          titleColor: isDark ? const Color(0xFFFC8181) : const Color(0xFFC53030),
          messageColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
          buttonColor: isDark ? const Color(0xFFE53E3E) : const Color(0xFFDC2626),
        );
      
      case ErrorSeverity.warning:
        return _ErrorColors(
          backgroundColor: isDark ? const Color(0xFF2D2519) : const Color(0xFFFFFBEB),
          borderColor: isDark ? const Color(0xFFD69E2E) : const Color(0xFFFCD34D),
          headerColor: isDark ? const Color(0xFF3D311D) : const Color(0xFFFEF3C7),
          shadowColor: Colors.orange.withOpacity(0.1),
          icon: Icons.warning_amber_outlined,
          iconColor: isDark ? const Color(0xFFF6AD55) : const Color(0xFFD69E2E),
          titleColor: isDark ? const Color(0xFFF6AD55) : const Color(0xFFB7791F),
          messageColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
          buttonColor: isDark ? const Color(0xFFD69E2E) : const Color(0xFFF59E0B),
        );
      
      case ErrorSeverity.info:
        return _ErrorColors(
          backgroundColor: isDark ? const Color(0xFF1A2632) : const Color(0xFFEFF6FF),
          borderColor: isDark ? const Color(0xFF3182CE) : const Color(0xFF93C5FD),
          headerColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
          shadowColor: Colors.blue.withOpacity(0.1),
          icon: Icons.info_outline,
          iconColor: isDark ? const Color(0xFF63B3ED) : const Color(0xFF3182CE),
          titleColor: isDark ? const Color(0xFF63B3ED) : const Color(0xFF2C5282),
          messageColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
          buttonColor: isDark ? const Color(0xFF3182CE) : const Color(0xFF3B82F6),
        );
    }
  }
}

/// Technical details expandable section
class _TechnicalDetailsSection extends StatefulWidget {
  final String details;
  final _ErrorColors colors;

  const _TechnicalDetailsSection({
    required this.details,
    required this.colors,
  });

  @override
  State<_TechnicalDetailsSection> createState() => _TechnicalDetailsSectionState();
}

class _TechnicalDetailsSectionState extends State<_TechnicalDetailsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: widget.colors.messageColor.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Technical Details',
                style: TextStyle(
                  color: widget.colors.messageColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.colors.messageColor.withOpacity(0.1),
              ),
            ),
            child: SelectableText(
              widget.details,
              style: TextStyle(
                color: widget.colors.messageColor.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Error severity levels
enum ErrorSeverity {
  error,
  warning,
  info,
}

/// Color scheme for error tiles
class _ErrorColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color headerColor;
  final Color shadowColor;
  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
  final Color buttonColor;

  _ErrorColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.headerColor,
    required this.shadowColor,
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
    required this.buttonColor,
  });
}
