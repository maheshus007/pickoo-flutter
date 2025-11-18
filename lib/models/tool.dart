import '../config/app_config.dart';

/// Represents an AI editing tool available in the app.
/// Each tool has an id, display name, endpoint path for the FastAPI backend,
/// and an optional description for future expansion.
class Tool {
  final String id; // machine-readable id
  final String name; // user-visible name
  final String endpoint; // FastAPI endpoint (e.g. /enhance)
  final String? description;
  final bool enabled; // whether the tool is currently enabled

  const Tool({
    required this.id,
    required this.name,
    required this.endpoint,
    this.description,
    this.enabled = true, // default to enabled
  });
}

/// Central registry of all tools. This enables dynamic UI lists
/// and future feature toggling/remote config.
class ToolRegistry {
  static final List<Tool> tools = _buildTools();
  
  static List<Tool> _buildTools() {
    return <Tool>[
      Tool(
        id: 'auto_enhance',
        name: 'Auto Enhance',
        endpoint: '/enhance',
        enabled: AppConfig.isToolEnabled('auto_enhance'),
      ),
      Tool(
        id: 'background_removal',
        name: 'Background Removal',
        endpoint: '/remove_bg',
        enabled: AppConfig.isToolEnabled('background_removal'),
      ),
      Tool(
        id: 'face_retouch',
        name: 'Face Retouch',
        endpoint: '/face_retouch',
        enabled: AppConfig.isToolEnabled('face_retouch'),
      ),
      Tool(
        id: 'object_eraser',
        name: 'Object Eraser',
        endpoint: '/erase_object',
        enabled: AppConfig.isToolEnabled('object_eraser'),
      ),
      Tool(
        id: 'sky_replacement',
        name: 'Sky Replacement',
        endpoint: '/sky_replace',
        enabled: AppConfig.isToolEnabled('sky_replacement'),
      ),
      Tool(
        id: 'super_resolution',
        name: 'Super Resolution',
        endpoint: '/super_res',
        enabled: AppConfig.isToolEnabled('super_resolution'),
      ),
      Tool(
        id: 'style_transfer',
        name: 'Artistic Style Transfer',
        endpoint: '/style_transfer',
        enabled: AppConfig.isToolEnabled('style_transfer'),
      ),
    ];
  }
  
  /// Get only enabled tools for display in UI
  static List<Tool> get enabledTools => tools.where((t) => t.enabled).toList();
}
