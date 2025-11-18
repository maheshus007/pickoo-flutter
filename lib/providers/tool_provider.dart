import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tool.dart';
import '../services/api_service.dart';
import '../services/gallery_service.dart';
import '../models/gallery_item.dart';
import '../config/app_config.dart';
import '../utils/error_display_helper.dart';
import 'subscription_provider.dart';

/// Holds state for current editing session.
class ToolState {
  final Tool? selectedTool;
  final XFile? original;
  final Uint8List? originalBytes; // cached bytes for UI (avoid async in build)
  final Uint8List? result;
  final Uint8List? previousResult; // single-level history
  final Tool? previousTool;
  final bool processing;
  final String? error;

  const ToolState({
    this.selectedTool,
    this.original,
    this.originalBytes,
    this.result,
    this.previousResult,
    this.previousTool,
    this.processing = false,
    this.error,
  });

  ToolState copyWith({
    Tool? selectedTool,
    XFile? original,
    Uint8List? originalBytes,
    Uint8List? result,
    Uint8List? previousResult,
    Tool? previousTool,
    bool? processing,
    String? error,
  }) => ToolState(
        selectedTool: selectedTool ?? this.selectedTool,
        original: original ?? this.original,
        originalBytes: originalBytes ?? this.originalBytes,
        result: result ?? this.result,
        previousResult: previousResult ?? this.previousResult,
        previousTool: previousTool ?? this.previousTool,
        processing: processing ?? this.processing,
        error: error,
      );

  bool get hasResult => result != null;
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(AppConfig.backendUrl);
});

final toolStateProvider = NotifierProvider<ToolStateNotifier, ToolState>(() {
  return ToolStateNotifier();
});

// Gallery provider to be referenced after processing for persistence.
final galleryProvider = NotifierProvider<GalleryNotifier, List<GalleryItem>>(() {
  return GalleryNotifier();
});

class GalleryNotifier extends Notifier<List<GalleryItem>> {
  final _service = GalleryService();
  @override
  List<GalleryItem> build() {
    // Fire and forget async load
    _load();
    return const [];
  }

  Future<void> _load() async {
    final items = await _service.load();
    state = items;
  }

  /// Add new item to gallery with automatic quota management
  Future<void> add(String tool, Uint8List bytes) async {
    try {
      final item = await _service.create(tool, bytes);
      // Prepend the new item so latest appears first in gallery
      final newState = [item, ...state];
      
      // Save to storage (will auto-cleanup if needed)
      await _service.saveAll(newState);
      
      // Update state only after successful save
      state = newState;
      
    } catch (e) {
      // Handle QuotaExceededError gracefully
      if (e.toString().contains('QuotaExceededError') || 
          e.toString().contains('exceeded the quota')) {
        
        // Log the error
        final errorLog = ErrorDisplayHelper.formatErrorLog(
          error: e.toString(),
          tool: tool,
          operation: 'save_to_gallery',
          context: {
            'current_items': state.length,
            'max_items': 20,
          },
        );
        // ignore: avoid_print
        print(errorLog);
        
        // Reload gallery (emergency cleanup already happened in service)
        await _load();
        
        // Re-throw with user-friendly message
        throw Exception('Storage quota exceeded. Gallery has been reduced to 10 most recent images. Please clear cache in settings to free up space.');
      }
      
      // For other errors, just rethrow
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _service.saveAll(state);
  }

  Future<void> clear() async {
    state = [];
    await _service.clearAll();
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _service.getStorageStats();
  }
}

class ToolStateNotifier extends Notifier<ToolState> {
  @override
  ToolState build() => const ToolState();

  void selectTool(Tool tool) {
    // If currently processing ignore rapid re-selection.
    if (state.processing) return;
    // Store previous result before switching tool (for revert capability)
    state = state.copyWith(
      previousResult: state.result,
      previousTool: state.selectedTool,
      selectedTool: tool,
      error: null,
      // Clear current result so UI shows loading or original.
      result: null,
    );
    // Auto process if original available.
    if (state.original != null) {
      // Schedule microtask to avoid setState overlap.
      Future.microtask(() => process());
    }
  }

  Future<void> setOriginal(XFile file) async {
    // OPTIMIZED: Skip slow client-side compression - let backend handle it
    // Just read the bytes for display, upload the original file
    
    Uint8List displayBytes;
    try {
      displayBytes = await file.readAsBytes();
    } catch (e) {
      rethrow;
    }
    
    state = state.copyWith(
      original: file, // Store original file reference
      originalBytes: displayBytes, // Just for display
      result: null,
      previousResult: null,
      previousTool: null,
      processing: false,
      error: null,
    );
    
    // If a tool is already selected, auto-process the newly uploaded image
    if (state.selectedTool != null) {
      Future.microtask(() => process());
    }
  }

  Future<void> process() async {
    final tool = state.selectedTool;
    final original = state.original;
    if (tool == null || original == null) return;
    // Subscription gating
    final sub = ref.read(subscriptionProvider);
    if (sub.isExpired) {
      state = state.copyWith(error: 'Subscription expired. Please purchase a new plan.');
      return;
    }
    if (sub.quotaExceeded) {
      state = state.copyWith(error: 'Image quota reached for current plan. Upgrade to continue.');
      return;
    }
    // Debug logging for investigation
    // ignore: avoid_print
    print('[ToolState] Starting process for tool=${tool.id}');
    state = state.copyWith(processing: true, error: null);
  final api = ref.read(apiServiceProvider);
    try {
      // All tools now processed via unified /process endpoint.
      Uint8List bytes = await api.processTool(toolId: tool.id, image: original);
      
      // REMOVED: Slow dimension normalization (was causing hang on large images)
      // Backend already returns properly sized images, no need for client-side resizing
      
      state = state.copyWith(result: bytes, processing: false);
      // ignore: avoid_print
      print('[ToolState] Process succeeded tool=${tool.id} bytes=${bytes.length}');
      
      // Persist to gallery (with quota error handling)
      try {
        await ref.read(galleryProvider.notifier).add(tool.id, bytes);
      } catch (galleryError) {
        // Log gallery save error but don't fail the entire process
        final galleryErrorLog = ErrorDisplayHelper.formatErrorLog(
          error: galleryError.toString(),
          tool: tool.id,
          operation: 'save_to_gallery',
          context: {
            'result_bytes': bytes.length,
          },
        );
        // ignore: avoid_print
        print(galleryErrorLog);
        
        // Show user-friendly error message but keep the result
        // User can still download/share even if gallery save failed
        state = state.copyWith(
          error: 'Image processed successfully, but gallery save failed: ${galleryError.toString()}',
        );
      }
      
      // Record usage
  ref.read(subscriptionProvider.notifier).recordUsage();
    } catch (e) {
      // Format error with context for better debugging
      final errorLog = ErrorDisplayHelper.formatErrorLog(
        error: e.toString(),
        tool: tool.id,
        operation: 'process_image',
        context: {
          'has_original': state.original != null,
          'original_bytes': state.originalBytes?.length ?? 0,
        },
      );
      // ignore: avoid_print
      print(errorLog);
      
      state = state.copyWith(error: e.toString(), processing: false);
    }
  }

  void revert() {
    if (state.previousResult != null) {
      state = state.copyWith(
        result: state.previousResult,
        selectedTool: state.previousTool,
        // Clear previous to prevent multi-level chain for now.
        previousResult: null,
        previousTool: null,
        error: null,
      );
    } else {
      // Revert to original (no result)
      state = state.copyWith(result: null, error: null);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const ToolState();
  }

  /// Optionally hydrate dynamic tools from backend (not stored in state yet; caller can use result)
  Future<List<Tool>> fetchAvailableTools() async {
    final api = ref.read(apiServiceProvider);
    return api.fetchTools();
  }
}
