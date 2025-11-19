import 'dart:typed_data';
import 'dart:io' show File, Directory; // For temp file writing on non-web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/tool.dart';
import '../services/api_service.dart';
import '../services/gallery_service.dart';
import '../models/gallery_item.dart';
import '../config/app_config.dart';
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
  final bool rawMode; // whether current processing requests raw bytes (no base64)

  const ToolState({
    this.selectedTool,
    this.original,
    this.originalBytes,
    this.result,
    this.previousResult,
    this.previousTool,
    this.processing = false,
    this.error,
    this.rawMode = false,
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
    bool? rawMode,
  }) => ToolState(
        selectedTool: selectedTool ?? this.selectedTool,
        original: original ?? this.original,
        originalBytes: originalBytes ?? this.originalBytes,
        result: result ?? this.result,
        previousResult: previousResult ?? this.previousResult,
        previousTool: previousTool ?? this.previousTool,
        processing: processing ?? this.processing,
        error: error,
        rawMode: rawMode ?? this.rawMode,
      );

  bool get hasResult => result != null;
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(AppConfig.apiBaseUrl);
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

  Future<void> add(String tool, Uint8List bytes) async {
    final item = await _service.create(tool, bytes);
    // Prepend the new item so latest appears first in gallery
    state = [item, ...state];
    await _service.saveAll(state);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _service.saveAll(state);
  }

  Future<void> clear() async {
    state = [];
    await _service.saveAll(state);
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
    // Clean up previous temp compressed file if present
    if (!kIsWeb) {
      final prevPath = state.original?.path ?? '';
      if (prevPath.contains('neuralens_compressed_')) {
        try { await File(prevPath).delete(); } catch (_) {}
      }
    }
    Uint8List originalBytes = await file.readAsBytes();
    Uint8List processedBytes = originalBytes;
    const int maxDim = 1600; // performance ceiling
    const int jpegQuality = 85;
    bool wantsPng = false;
    try {
      final decoded = img.decodeImage(originalBytes);
      if (decoded != null) {
        int w = decoded.width;
        int h = decoded.height;
        wantsPng = decoded.hasAlpha; // preserve transparency if present
        if (w > maxDim || h > maxDim) {
          final scale = w >= h ? maxDim / w : maxDim / h;
          final newW = (w * scale).round();
          final newH = (h * scale).round();
          final resized = img.copyResize(decoded, width: newW, height: newH, interpolation: img.Interpolation.linear);
          if (wantsPng) {
            processedBytes = Uint8List.fromList(img.encodePng(resized));
          } else {
            processedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
          }
        } else {
          // Even if not resized, convert to JPEG to reduce payload (unless already tiny)
          processedBytes = Uint8List.fromList(
            wantsPng ? img.encodePng(decoded) : img.encodeJpg(decoded, quality: jpegQuality),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ToolState] Image compression skipped due to error: $e');
      processedBytes = originalBytes; // fallback
    }
    // Create a new XFile wrapping processed bytes. For non-web ensure a temp path for File fallback.
    XFile effectiveFile;
    if (!kIsWeb) {
      try {
        final tmpDir = Directory.systemTemp;
        final ext = wantsPng ? 'png' : 'jpg';
        final tmpPath = '${tmpDir.path}/neuralens_compressed_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(tmpPath).writeAsBytes(processedBytes, flush: true);
        effectiveFile = XFile(tmpPath, name: 'compressed.$ext');
      } catch (_) {
        effectiveFile = XFile.fromData(
          processedBytes,
          name: wantsPng ? 'compressed.png' : 'compressed.jpg',
          mimeType: wantsPng ? 'image/png' : 'image/jpeg',
        );
      }
    } else {
      effectiveFile = XFile.fromData(
        processedBytes,
        name: wantsPng ? 'compressed.png' : 'compressed.jpg',
        mimeType: wantsPng ? 'image/png' : 'image/jpeg',
      );
    }
    state = state.copyWith(
      original: effectiveFile,
      originalBytes: processedBytes,
      // Replace old image entirely: clear previous result/tool and any error; stop any ongoing processing
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
  Uint8List bytes = await api.processTool(toolId: tool.id, image: original, rawMode: state.rawMode);
      // Normalize result dimensions to match original to avoid visual duplicate layering artifacts in CompareSlider.
      try {
        if (state.originalBytes != null) {
          final origImg = img.decodeImage(state.originalBytes!);
          final resImg = img.decodeImage(bytes);
          if (origImg != null && resImg != null && (origImg.width != resImg.width || origImg.height != resImg.height)) {
            // Resize result to match original dimensions using linear interpolation.
            final resized = img.copyResize(resImg, width: origImg.width, height: origImg.height, interpolation: img.Interpolation.linear);
            // Preserve PNG if original had alpha; otherwise JPEG for size.
            final wantsPng = origImg.hasAlpha || resImg.hasAlpha;
            bytes = Uint8List.fromList(wantsPng ? img.encodePng(resized) : img.encodeJpg(resized, quality: 90));
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('[ToolState] Dimension normalization skipped: $e');
      }
      state = state.copyWith(result: bytes, processing: false);
      // ignore: avoid_print
      print('[ToolState] Process succeeded tool=${tool.id} bytes=${bytes.length}');
      // Persist to gallery
  await ref.read(galleryProvider.notifier).add(tool.id, bytes);
      // Record usage
  ref.read(subscriptionProvider.notifier).recordUsage();
    } catch (e) {
      // ignore: avoid_print
      print('[ToolState] Process failed tool=${tool.id} error=$e');
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

  void reset() {
    state = const ToolState();
  }

  /// Optionally hydrate dynamic tools from backend (not stored in state yet; caller can use result)
  Future<List<Tool>> fetchAvailableTools() async {
    final api = ref.read(apiServiceProvider);
    return api.fetchTools();
  }

  void toggleRawMode() {
    if (state.processing) return; // avoid switching mid-flight
    state = state.copyWith(rawMode: !state.rawMode);
  }
}
