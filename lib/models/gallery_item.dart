import 'dart:convert';
import 'dart:typed_data';

class GalleryItem {
  final String id; // uuid
  final String tool; // tool id
  final DateTime createdAt;
  final Uint8List bytes; // processed image bytes

  const GalleryItem({
    required this.id,
    required this.tool,
    required this.createdAt,
    required this.bytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool,
        'createdAt': createdAt.toIso8601String(),
        'data': base64Encode(bytes),
      };

  static GalleryItem fromJson(Map<String, dynamic> json) => GalleryItem(
        id: json['id'] as String,
        tool: json['tool'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bytes: Uint8List.fromList(base64Decode(json['data'] as String)),
      );
}
