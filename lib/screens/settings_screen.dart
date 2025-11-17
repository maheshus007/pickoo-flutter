import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/tool_provider.dart';
import '../utils/app_info.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Theme', style: TextStyle(color: Colors.white)),
            value: mode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          ListTile(
            title: const Text('Clear Gallery Cache', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Remove all processed images', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This will permanently delete all processed images from your local gallery cache. Continue?',
                    style: TextStyle(color: Colors.white70),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery cleared')));
                }
              }
            },
          ),
          const Divider(),
            ListTile(
              title: const Text('App Version', style: TextStyle(color: Colors.white)),
              subtitle: Text(appVersion, style: const TextStyle(color: Colors.white54)),
            ),
        ],
      ),
    );
  }
}
