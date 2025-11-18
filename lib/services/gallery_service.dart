import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gallery_item.dart';
import '../utils/error_display_helper.dart';
import 'package:uuid/uuid.dart';

/// Service for managing gallery storage with automatic cleanup and quota handling
/// Implements storage limits to prevent QuotaExceededError on web platforms
class GalleryService {
  static const _key = 'gallery_items_v1';
  static const int _maxGalleryItems = 20; // Maximum items to store
  static const int _emergencyLimit = 10; // Emergency cleanup limit
  static const int _maxStorageBytes = 4 * 1024 * 1024; // 4MB safety limit for web
  
  final _uuid = const Uuid();

  /// Load all gallery items from storage
  Future<List<GalleryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      final items = raw.map((e) => GalleryItem.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
      // Sort by most recent first for better UX (new edits appear at top)
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      if (kDebugMode) {
        print('[GalleryService] Load error: $e');
      }
      return [];
    }
  }

  /// Save all gallery items with automatic size management
  Future<void> saveAll(List<GalleryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Apply size limit before encoding
      var itemsToSave = items;
      if (itemsToSave.length > _maxGalleryItems) {
        itemsToSave = itemsToSave.sublist(0, _maxGalleryItems);
        if (kDebugMode) {
          print('[GalleryService] Trimmed gallery to $_maxGalleryItems items');
        }
      }
      
      // Encode to JSON
      final encoded = itemsToSave.map((e) => jsonEncode(e.toJson())).toList();
      
      // Check size before saving (web safety check)
      final totalSize = encoded.fold<int>(0, (sum, item) => sum + item.length);
      
      if (totalSize > _maxStorageBytes) {
        // Too large - reduce to emergency limit
        if (kDebugMode) {
          print('[GalleryService] Storage size ${(totalSize / 1024).toStringAsFixed(1)}KB exceeds limit, reducing to $_emergencyLimit items');
        }
        itemsToSave = itemsToSave.sublist(0, min(_emergencyLimit, itemsToSave.length));
        final reducedEncoded = itemsToSave.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList(_key, reducedEncoded);
      } else {
        await prefs.setStringList(_key, encoded);
      }
    } catch (e) {
      if (e.toString().contains('QuotaExceededError') || 
          e.toString().contains('exceeded the quota')) {
        // Emergency cleanup
        if (kDebugMode) {
          print('[GalleryService] QuotaExceededError - performing emergency cleanup');
        }
        await _emergencyCleanup(items);
        rethrow; // Re-throw for upper layer to handle with user-friendly message
      }
      rethrow;
    }
  }

  /// Emergency cleanup when quota is exceeded
  Future<void> _emergencyCleanup(List<GalleryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only the most recent N items
      final reducedItems = items.sublist(0, min(_emergencyLimit, items.length));
      final encoded = reducedItems.map((e) => jsonEncode(e.toJson())).toList();
      
      await prefs.setStringList(_key, encoded);
      
      if (kDebugMode) {
        print('[GalleryService] Emergency cleanup complete - kept $_emergencyLimit items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GalleryService] Emergency cleanup failed: $e');
      }
      // Last resort - clear everything
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (_) {}
    }
  }

  /// Create a new gallery item
  Future<GalleryItem> create(String tool, List<int> bytes) async {
    return GalleryItem(
      id: _uuid.v4(), 
      tool: tool, 
      createdAt: DateTime.now(), 
      bytes: bytes as dynamic
    );
  }

  /// Clear all gallery items
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      if (kDebugMode) {
        print('[GalleryService] Gallery cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GalleryService] Clear error: $e');
      }
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      final totalSize = raw.fold<int>(0, (sum, item) => sum + item.length);
      
      return {
        'item_count': raw.length,
        'total_bytes': totalSize,
        'total_kb': (totalSize / 1024).toStringAsFixed(1),
        'max_items': _maxGalleryItems,
        'utilization': (totalSize / _maxStorageBytes * 100).toStringAsFixed(1),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
