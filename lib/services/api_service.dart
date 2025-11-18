import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/tool.dart';

/// Centralized API client using Dio.
/// Handles: base config, error translation, multipart uploads.
class ApiService {
  final Dio _dio;

  ApiService(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        )) {
    // Interceptors for logging & error mapping.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inject Authorization header from persisted auth_token if not already set.
        try {
          if (!options.headers.containsKey('Authorization')) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          // Remove null values from query parameters to prevent "Cannot send Null" error
          if (options.queryParameters.isNotEmpty) {
            options.queryParameters.removeWhere((key, value) => value == null);
          }
        } catch (e) {
          // Silent failure; proceed without auth header.
          debugPrint('[API AUTH INJECT WARN] $e');
        }
        handler.next(options);
      },
      onError: (e, handler) {
        debugPrint('[API ERROR] ${e.type} ${e.message}');
        handler.next(e);
      },
    ));
  }

  /// Fast native image compression using flutter_image_compress
  /// MUCH faster than Dart's image package (uses native libraries)
  Future<Uint8List> _compressImageFast(XFile image) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // For web, read bytes directly (compression happens on backend)
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        debugPrint('[COMPRESS] Web - skipping client compression, ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        return bytes;
      }
      
      // For native platforms, use fast native compression
      final result = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 1080,        // Max 1080px width
        minHeight: 1080,       // Max 1080px height  
        quality: 65,           // Good balance between quality and size
        format: CompressFormat.jpeg, // Always JPEG for speed
        keepExif: false,       // Remove EXIF metadata
      );
      
      if (result == null) {
        debugPrint('[COMPRESS] Failed, using original');
        return await image.readAsBytes();
      }
      
      stopwatch.stop();
      final originalSize = await image.length();
      final compressedSize = result.length;
      final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      
      debugPrint('[COMPRESS] ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB → ${(compressedSize / 1024).toStringAsFixed(0)} KB ($reduction% reduction) in ${stopwatch.elapsedMilliseconds}ms');
      
      return result;
    } catch (e) {
      debugPrint('[COMPRESS ERROR] $e - using original');
      return await image.readAsBytes();
    }
  }

  /// Fetch available tools from backend. Falls back to static registry if unreachable.
  Future<List<Tool>> fetchTools() async {
    try {
      final resp = await _dio.get('/tools');
      if (resp.data is Map && resp.data['tools'] is List) {
        final list = (resp.data['tools'] as List);
        return list.map((e) => Tool(
          id: e['id'] as String,
          name: (e['name'] ?? e['id']) as String,
          endpoint: e['endpoint'] as String,
          description: e['description'] as String?,
        )).toList();
      }
      return ToolRegistry.tools; // unexpected shape
    } catch (_) {
      return ToolRegistry.tools; // network / parsing failure
    }
  }

  /// Generic processing using unified /process endpoint with query fallback for tool_id.
  Future<Uint8List> processTool({
    required String toolId,
    required XFile image,
  }) async {
    // For web, use http package to avoid Dio's FormData null issues
    if (kIsWeb) {
      return _processToolWeb(toolId: toolId, image: image);
    }
    
    // Native platforms continue using Dio
    return _processToolNative(toolId: toolId, image: image);
  }

  /// Web-specific implementation using http package
  Future<Uint8List> _processToolWeb({
    required String toolId,
    required XFile image,
  }) async {
    try {
      // Fast compression (on web, backend handles it)
      final bytes = await _compressImageFast(image);
      
      String filename = image.name.isNotEmpty ? image.name : 'upload.jpg';
      String? mime = 'image/jpeg'; // Always JPEG after compression
      
      final uri = Uri.parse('${_dio.options.baseUrl}/process?tool_id=$toolId&request=$toolId');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add auth token if available
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('[WEB AUTH WARN] $e');
      }
      
      debugPrint('[UPLOAD] Starting upload ${(bytes.length / 1024).toStringAsFixed(0)} KB');
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mime),
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
      
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['image_base64'] != null) {
        return base64Decode(json['image_base64'] as String);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Processing failed: $e');
    }
  }

  /// Native platform implementation using Dio with progress tracking
  Future<Uint8List> _processToolNative({
    required String toolId,
    required XFile image,
  }) async {
    // Determine endpoint for fallback if generic /process fails (e.g., 422 validation)
    final fallbackEndpoint = ToolRegistry.tools.firstWhere(
      (t) => t.id == toolId,
      orElse: () => Tool(id: toolId, name: toolId, endpoint: '/$toolId'),
    ).endpoint;
    try {
      // Fast native compression
      final bytes = await _compressImageFast(image);
      
      String filename = 'upload.jpg'; // Always JPEG after compression
      final mediaType = MediaType.parse('image/jpeg');
      
      // Create multipart from compressed bytes
      final part = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      );
      
      final formData = FormData.fromMap({'file': part});
      Response response;
      try {
        final qp = {
          'tool_id': toolId,
          'request': toolId,
        };
        
        // Upload with progress tracking
        response = await _dio.post(
          '/process', 
          queryParameters: qp, 
          data: formData,
          options: Options(
            responseType: ResponseType.json,
            headers: {},
          ),
          onSendProgress: (sent, total) {
            final progress = (sent / total * 100).toStringAsFixed(0);
            debugPrint('[UPLOAD] Progress: $progress%');
          },
        );
      } on DioException catch (e) {
        // Fallback on 422 (validation error) or 404 if generic endpoint not usable.
        if (e.response?.statusCode == 422 || e.response?.statusCode == 404) {
          final qp = {
            'request': toolId,
          };
          response = await _dio.post(fallbackEndpoint, data: formData, queryParameters: qp,
              options: Options(
                responseType: ResponseType.json,
                headers: {},
              ));
        } else {
          rethrow;
        }
      }
      
      if (response.data is Map && response.data['image_base64'] != null) {
        return base64Decode(response.data['image_base64'] as String);
      }
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    } catch (e) {
      throw Exception('Processing failed: $e');
    }
  }

  /// Verify Google Play purchase with backend
  Future<Map<String, dynamic>> verifyGooglePlayPurchase({
    required String userId,
    required String purchaseToken,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        '/subscription/verify-google-play',
        data: {
          'user_id': userId,
          'purchase_token': purchaseToken,
          'product_id': productId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _extractMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Record image processing usage in backend
  Future<void> recordUsage(String userId) async {
    try {
      await _dio.post(
        '/subscription/record_usage',
        data: {'user_id': userId},
      );
      debugPrint('[API] Usage recorded for user: $userId');
    } on DioException catch (e) {
      debugPrint('[API ERROR] Failed to record usage: ${_extractMessage(e)}');
      // Don't throw - usage tracking shouldn't block the user
    } catch (e) {
      debugPrint('[API ERROR] Failed to record usage: $e');
    }
  }

  /// Get subscription status from backend
  Future<Map<String, dynamic>?> getSubscriptionStatus(String userId) async {
    try {
      final response = await _dio.get(
        '/subscription/status',
        queryParameters: {'user_id': userId},
      );
      debugPrint('[API] Subscription status fetched for user: $userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[API ERROR] Failed to get subscription status: ${_extractMessage(e)}');
      return null;
    } catch (e) {
      debugPrint('[API ERROR] Failed to get subscription status: $e');
      return null;
    }
  }

  String _extractMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response?.data['detail'] as String;
    }
    return e.message ?? 'Unknown network error';
  }
}
