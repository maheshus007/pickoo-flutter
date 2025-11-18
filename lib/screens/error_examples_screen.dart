import 'package:flutter/material.dart';
import '../widgets/error_tile.dart';

/// Example screen showing all error tile variations
/// This demonstrates the beautiful error display system
class ErrorTileExamplesScreen extends StatelessWidget {
  const ErrorTileExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Tile Examples'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Beautiful Error Display System',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Examples of all error tile variations',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          
          // Quota Exceeded Error
          const Text(
            '1. Quota Exceeded Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorTile.quotaExceeded(
            tool: 'auto_enhance',
            onClearCache: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            onDismiss: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Network Error
          const Text(
            '2. Network Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorTile.networkError(
            tool: 'background_removal',
            details: 'SocketException: Failed to connect to server at 192.168.1.1:8000',
            onRetry: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Retrying...')),
              );
            },
            onDismiss: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Processing Error
          const Text(
            '3. Processing Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorTile.processingError(
            tool: 'face_beautify',
            error: 'Invalid image format: Expected JPEG or PNG',
            onRetry: () {},
            onDismiss: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Authentication Error
          const Text(
            '4. Authentication Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorTile.authError(
            message: 'Your session has expired. Please login again.',
            onLogin: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to login...')),
              );
            },
            onDismiss: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Custom Error (Info Severity)
          const Text(
            '5. Custom Info Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const ErrorTile(
            title: 'Feature Coming Soon',
            message: 'AI video enhancement will be available in the next update. Stay tuned!',
            severity: ErrorSeverity.info,
            technicalDetails: 'Feature: video_enhancement\nStatus: In Development\nETA: Q1 2026',
            showCopyButton: false,
          ),
          
          const SizedBox(height: 32),
          
          // Custom Error with long technical details
          const Text(
            '6. Complex Error with Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorTile(
            title: 'Processing Pipeline Failed',
            message: 'The image processing pipeline encountered an unexpected error. Our team has been notified.',
            severity: ErrorSeverity.error,
            technicalDetails: '''
Tool: style_transfer
Error: RuntimeError: CUDA out of memory
Stack Trace:
  at torch.nn.functional.conv2d (line 234)
  at StyleTransferModel.forward (line 89)
  at process_image (line 156)
  
Memory Usage: 15.2GB / 16GB
Batch Size: 4
Image Size: 4096x4096px
Model: VGG19-StyleNet-v2
''',
            onRetry: () {},
            onDismiss: () {},
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
