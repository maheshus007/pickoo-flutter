import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config/app_config.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/compare_slider.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_title.dart';
import '../providers/subscription_provider.dart';
import '../providers/ad_provider.dart';
import '../utils/error_display_helper.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription_plan.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'payment_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(toolStateProvider);
    final notifier = ref.read(toolStateProvider.notifier);
    final sub = ref.watch(subscriptionProvider);
    final bannerAdState = ref.watch(bannerAdProvider);
    return Stack(children: [
            Scaffold(
        appBar: AppBar(title: Text(AppConfig.appName)),
        body: Stack(
          children: [
            // Futuristic subtle radial gradient backdrop
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.8),
                    radius: 1.2,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      Colors.black,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100, // Add extra bottom padding to prevent overlap with bottom nav bar
              ),
              children: [
            _HeaderSection(onPick: () async {
              // Show interstitial ad before image upload for free tier users
              final adService = ref.read(adServiceProvider);
              if (adService.shouldShowAds(sub.plan)) {
                await adService.showInterstitialAd();
                // Small delay to let ad close properly
                await Future.delayed(const Duration(milliseconds: 500));
              }
              
              final picker = ImagePicker();
              final file = await picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                await notifier.setOriginal(file);
                
                // Load banner ad after upload for free tier users
                if (adService.shouldShowAds(sub.plan)) {
                  ref.read(bannerAdProvider.notifier).loadBannerAd();
                }
              }
            }, onSample: () async {
              // Load bundled base64 sample image and create a temporary XFile.
              final base64Data = await rootBundle.loadString('assets/images/sample.base64');
              final bytes = base64Decode(base64Data);
              final tempDir = Directory.systemTemp;
              final filePath = '${tempDir.path}/pickoo_sample.png';
              final file = await File(filePath).writeAsBytes(bytes, flush: true);
              await notifier.setOriginal(XFile(file.path));
            }),
            // Stable image area: keeps layout position fixed using AnimatedSwitcher + AspectRatio.
            if (toolState.originalBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: (toolState.hasResult && toolState.result != null)
                      ? Stack(
                          children: [
                            CompareSlider(
                              key: const ValueKey('compare-slider'),
                              before: toolState.originalBytes!,
                              after: toolState.result!,
                            ),
                            // Download edited (after) image button overlay
                            Positioned(
                              right: 8,
                              top: 8,
                              child: _DownloadButton(
                                bytes: toolState.result!,
                                filename: 'pickoo_edited.png',
                                tooltip: 'Download edited',
                                adSupported: sub.plan.adSupported,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          key: const ValueKey('original-image'),
                          children: toolState.error != null && !toolState.processing
                              ? [
                                  // Base image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      toolState.originalBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Download button
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: _DownloadButton(
                                      bytes: toolState.originalBytes!,
                                      filename: 'pickoo_original.png',
                                      tooltip: 'Download original',
                                      adSupported: sub.plan.adSupported,
                                    ),
                                  ),
                                  // Error overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                              child: Text(
                                                toolState.error!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            OutlinedButton.icon(
                                              onPressed: () => notifier.process(),
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      toolState.originalBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: _DownloadButton(
                                      bytes: toolState.originalBytes!,
                                      filename: 'pickoo_original.png',
                                      tooltip: 'Download original',
                                      adSupported: sub.plan.adSupported,
                                    ),
                                  ),
                                ],
                        ),
                ),
              ),
            const SizedBox(height: 24),
                const SectionTitle('AI Tools'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ToolRegistry.enabledTools.map((t) {
                final selected = toolState.selectedTool?.id == t.id;
                return NeonCard(
                  key: ValueKey('tool-${t.id}'),
                  selected: selected,
                  onTap: () => notifier.selectTool(t),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high, color: selected ? Theme.of(context).colorScheme.primary : Colors.white),
                      const SizedBox(height: 8),
                      Text(t.name, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (toolState.original != null && toolState.selectedTool != null && !toolState.processing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (sub.plan.imageQuota != null)
                      Text('Remaining: ${sub.remainingImages}', style: const TextStyle(color: Colors.white54)),
                    const SizedBox(width: 12),
                    if (sub.isExpired)
                      const Text('Expired', style: TextStyle(color: Colors.redAccent)),
                    if (toolState.previousResult != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: OutlinedButton.icon(
                          onPressed: notifier.revert,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Revert'),
                        ),
                      ),
                  ],
                ),
              ),
                if (toolState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ErrorDisplayHelper.buildErrorTile(
                      error: toolState.error!,
                      tool: toolState.selectedTool?.name,
                      onRetry: () => notifier.process(),
                      onDismiss: () => notifier.clearError(),
                    ),
                  ),
            // Action buttons now appear below stable image container only when a result exists.
            if (toolState.hasResult && toolState.result != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async => _downloadBytes(
                        context: context,
                        bytes: toolState.result!,
                        filename: 'pickoo_edited.png',
                        adSupported: sub.plan.adSupported,
                      ),
                      icon: const Icon(Icons.download, color: Colors.white70),
                      label: const Text('Download'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final xfile = XFile.fromData(toolState.result!, name: 'pickoo_result.png', mimeType: 'image/png');
                        await Share.shareXFiles([xfile], text: 'Edited with Pickoo');
                      },
                      icon: const Icon(Icons.share, color: Colors.white70),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ),
              
              // Show banner ad after processing for free tier users
              if (sub.plan.adSupported && bannerAdState.isLoaded && bannerAdState.ad != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AdWidget(ad: bannerAdState.ad!),
                  ),
                ),
            ],
              ],
            ),
          ],
        ),
      ),
      if (sub.plan.adSupported)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.85)),
<<<<<<< HEAD
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await PaymentService.startGPayUpi(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(plan: PlansRegistry.week100),
                        ),
                      ),
                      child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                      builder: (context) => PaymentScreen(plan: PlansRegistry.week100),
                    ),
                  ),
                  child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
                ),
              ],
>>>>>>> origin/main
            ),
          ),
        ),
      LoadingOverlay(visible: toolState.processing),
    ]);
  }
}

class _DownloadButton extends StatelessWidget {
  final Uint8List bytes;
  final String filename;
  final String tooltip;
  final bool adSupported;
  const _DownloadButton({
    required this.bytes,
    required this.filename,
    required this.tooltip,
    required this.adSupported,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () async {
          await _downloadBytes(
            context: context,
            bytes: bytes,
            filename: filename,
            adSupported: adSupported,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.download, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

Future<void> _downloadBytes({
  required BuildContext context,
  required Uint8List bytes,
  required String filename,
  required bool adSupported,
}) async {
  // Optional ad dialog for free plan
  if (adSupported) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Ad', style: TextStyle(color: Colors.white)),
        content: const Text('Ad Placeholder - Your sponsored content here.', style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('Close'))],
      ),
    );
  }
  if (kIsWeb) {
    // Use browser download mechanism (web only)
    // Note: This code won't compile on non-web platforms, but kIsWeb prevents execution
    throw UnimplementedError('Web download not available in this build');
  } else {
    // Fallback: share file (mobile/desktop)
    final xfile = XFile.fromData(bytes, name: filename, mimeType: 'image/png');
    await Share.shareXFiles([xfile], text: 'Edited with Pickoo');
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onPick;
  final VoidCallback onSample;
  const _HeaderSection({required this.onPick, required this.onSample});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Upload a photo, choose an AI tool and let Pickoo enhance it.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload),
              label: const Text('Select Photo'),
            ),
          ],
        ),
      ],
    );
  }
}
