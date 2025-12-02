import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/tool_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/gallery_item.dart';
import '../widgets/neon_card.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(galleryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: items.isEmpty
          ? const Center(child: Text('No processed images yet', style: TextStyle(color: Colors.white60)))
          : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _GalleryThumb(item: item);
              },
            ),
    );
  }
}

class _GalleryThumb extends ConsumerWidget {
  final GalleryItem item;
  const _GalleryThumb({required this.item});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonCard(
      padding: EdgeInsets.zero,
      onTap: () => _openDialog(context, ref),
      child: Hero(
        tag: item.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(item.bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.tool, style: const TextStyle(color: Colors.white70)),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Hero(tag: item.id, child: Image.memory(item.bytes, fit: BoxFit.contain)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Wrap(
                  spacing: 12,
                  children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(galleryProvider.notifier).remove(item.id);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final sub = ref.read(subscriptionProvider);
                      // Ad gating: if free plan show ad placeholder first.
                      if (sub.plan.adSupported) {
                        await showDialog(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Text('Ad', style: TextStyle(color: Colors.white)),
                            content: const Text('Ad Placeholder - Your sponsored content here.', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(_), child: const Text('Close')),
                            ],
                          ),
                        );
                      }
                      final xfile = XFile.fromData(item.bytes, name: 'pickoo_${item.tool}.png', mimeType: 'image/png');
                      await Share.shareXFiles([xfile], text: 'Download from Pickoo (${item.tool})');
                    },
                    icon: const Icon(Icons.download, color: Colors.white70),
                    label: const Text('Download'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final xfile = XFile.fromData(item.bytes, name: 'pickoo_${item.tool}.png', mimeType: 'image/png');
                      await Share.shareXFiles([xfile], text: 'Edited with Pickoo (${item.tool})');
                    },
                    icon: const Icon(Icons.share, color: Colors.white70),
                    label: const Text('Share'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
