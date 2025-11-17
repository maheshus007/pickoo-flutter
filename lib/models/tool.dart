/// Represents an AI editing tool available in the app.
/// Each tool has an id, display name, endpoint path for the FastAPI backend,
/// and an optional description for future expansion.
class Tool {
  final String id; // machine-readable id
  final String name; // user-visible name
  final String endpoint; // FastAPI endpoint (e.g. /enhance)
  final String? description;

  const Tool({
    required this.id,
    required this.name,
    required this.endpoint,
    this.description,
  });
}

/// Central registry of all tools. This enables dynamic UI lists
/// and future feature toggling/remote config.
class ToolRegistry {
  static const tools = <Tool>[
    Tool(id: 'auto_enhance', name: 'Auto Enhance', endpoint: '/enhance'),
    Tool(id: 'background_removal', name: 'Background Removal', endpoint: '/remove_bg'),
    Tool(id: 'face_retouch', name: 'Face Retouch', endpoint: '/face_retouch'),
    Tool(id: 'object_eraser', name: 'Object Eraser', endpoint: '/erase_object'),
    Tool(id: 'sky_replacement', name: 'Sky Replacement', endpoint: '/sky_replace'),
    Tool(id: 'super_resolution', name: 'Super Resolution', endpoint: '/super_res'),
    Tool(id: 'style_transfer', name: 'Artistic Style Transfer', endpoint: '/style_transfer'),
  ];
}
