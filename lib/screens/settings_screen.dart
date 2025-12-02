import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tool_provider.dart';
import '../utils/app_info.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic>? _storageStats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await ref.read(galleryProvider.notifier).getStorageStats();
      if (mounted) {
        setState(() {
          _storageStats = stats;
          _loadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryItems = ref.watch(galleryProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Storage Statistics Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gallery Storage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                          onPressed: _loadingStats ? null : _loadStorageStats,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingStats)
                      const Center(child: CircularProgressIndicator())
                    else if (_storageStats != null) ...[
                      _buildStatRow('Items', '${_storageStats!['item_count'] ?? 0}'),
                      _buildStatRow('Total Size', '${(_storageStats!['total_kb'] ?? 0).toStringAsFixed(1)} KB'),
                      _buildStatRow('Storage Used', '${(_storageStats!['utilization'] ?? 0).toStringAsFixed(1)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_storageStats!['utilization'] ?? 0) / 100.0,
                        backgroundColor: Colors.grey[800],
                        color: (_storageStats!['utilization'] ?? 0) > 80 
                          ? Colors.redAccent 
                          : Colors.blueAccent,
                      ),
                      if ((_storageStats!['utilization'] ?? 0) > 80)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            '⚠️ Storage is almost full. Consider clearing cache.',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Clear Gallery Cache', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Remove all ${galleryItems.length} processed images',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: galleryItems.isEmpty ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
                  content: Text(
                    'This will permanently delete all ${galleryItems.length} processed images from your local gallery cache. Continue?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(galleryProvider.notifier).clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gallery cleared')),
                  );
                  // Reload stats after clearing
                  _loadStorageStats();
                }
              }
            },
          ),
          const Divider(),
            const ListTile(
              title: Text('App Version', style: TextStyle(color: Colors.white)),
              subtitle: Text(appVersion, style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
