// Conditional import usage: avoid using File operations on web.
import 'dart:io' show File; // Only used when not kIsWeb
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../models/tool.dart';

/// Centralized API client using Dio.
/// Handles: base config, error translation, multipart uploads.
class ApiService {
  final Dio _dio;

  ApiService(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
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
              options.headers['Authorization'] = 'Bearer ' + token;
            }
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
    bool rawMode = false,
  }) async {
    // Determine endpoint for fallback if generic /process fails (e.g., 422 validation)
    final fallbackEndpoint = ToolRegistry.tools.firstWhere(
      (t) => t.id == toolId,
      orElse: () => Tool(id: toolId, name: toolId, endpoint: '/$toolId'),
    ).endpoint;
    try {
      MultipartFile part;
      String? mime = image.mimeType; // available for XFile.fromData
      mime ??= image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final mediaType = MediaType.parse(mime);
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        part = MultipartFile.fromBytes(bytes, filename: image.name, contentType: mediaType);
      } else {
        if (image.path.isNotEmpty) {
          final file = File(image.path);
          part = await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last, contentType: mediaType);
        } else {
          // Fallback for in-memory XFile (rare on mobile) - send bytes
          final bytes = await image.readAsBytes();
          part = MultipartFile.fromBytes(bytes, filename: image.name, contentType: mediaType);
        }
      }
      final formData = FormData.fromMap({'file': part});
      Response response;
      try {
        // Include a redundant 'request' param (legacy) plus raw flag when requested
        final qp = {
          'tool_id': toolId,
          'request': toolId,
          if (rawMode) 'raw': 1,
        };
        response = await _dio.post('/process', queryParameters: qp, data: formData,
            options: rawMode
                ? Options(responseType: ResponseType.bytes)
                : Options());
      } on DioException catch (e) {
        // Fallback on 422 (validation error) or 404 if generic endpoint not usable.
        if (e.response?.statusCode == 422 || e.response?.statusCode == 404) {
          // Retry with fallback endpoint (legacy dedicated tool endpoint)
          final qp = {
            'request': toolId,
            if (rawMode) 'raw': 1,
          };
          response = await _dio.post(fallbackEndpoint, data: formData, queryParameters: qp,
              options: rawMode
                  ? Options(responseType: ResponseType.bytes)
                  : Options());
        } else {
          rethrow;
        }
      }
      if (rawMode) {
        // Expect raw bytes in response.data (already bytes type for ResponseType.bytes)
        if (response.data is Uint8List) {
          return response.data as Uint8List;
        }
        if (response.data is List<int>) {
          return Uint8List.fromList(response.data as List<int>);
        }
        throw Exception('Unexpected raw response type: ${response.data.runtimeType}');
      } else {
        if (response.data is Map && response.data['image_base64'] != null) {
          return base64Decode(response.data['image_base64'] as String);
        }
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    } catch (e) {
      throw Exception('Processing failed: $e');
    }
  }

  String _extractMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response?.data['detail'] as String;
    }
    return e.message ?? 'Unknown network error';
  }
}
