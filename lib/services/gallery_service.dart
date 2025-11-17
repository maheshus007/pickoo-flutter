import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gallery_item.dart';
import 'package:uuid/uuid.dart';

class GalleryService {
  static const _key = 'gallery_items_v1';
  final _uuid = const Uuid();

  Future<List<GalleryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = raw.map((e) => GalleryItem.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    // Sort by most recent first for better UX (new edits appear at top)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveAll(List<GalleryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<GalleryItem> create(String tool, List<int> bytes) async {
    return GalleryItem(id: _uuid.v4(), tool: tool, createdAt: DateTime.now(), bytes: bytes as dynamic);
  }
}
