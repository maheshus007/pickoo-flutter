import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/tool_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_plan.dart';
import '../widgets/neon_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final auth = ref.watch(authProvider);
    final sub = ref.watch(subscriptionProvider);
    final galleryCount = ref.watch(galleryProvider).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (auth.loading) const CircularProgressIndicator(),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                if (auth.isAuthenticated && !auth.loading) ...[
                  Text('Signed in (user id: ${auth.userId ?? 'unknown'})', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Gallery items: $galleryCount', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => ref.read(authProvider.notifier).logout(), child: const Text('Logout')),
                ] else if (!auth.loading) ...[
                  const Text('Not signed in', style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => ref.read(authProvider.notifier).googleLogin(), child: const Text('Login with Google')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Subscription', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PlansRegistry.all.map((plan) {
              final selected = plan.id == sub.plan.id;
              return NeonCard(
                selected: selected,
                onTap: () => ref.read(subscriptionProvider.notifier).purchase(plan),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(plan.name, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(plan.priceLabel, style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Colors.white70)),
                    if (plan.imageQuota != null)
                      Text('${plan.imageQuota} imgs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    if (plan.durationDays != null)
                      Text('${plan.durationDays} day(s)', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Current Plan: ${sub.plan.name}', style: const TextStyle(color: Colors.white)),
          if (sub.plan.imageQuota != null)
            Text('Remaining: ${sub.remainingImages}', style: const TextStyle(color: Colors.white70)),
          if (sub.isExpired)
            const Text('Plan expired. Purchase a new plan.', style: TextStyle(color: Colors.redAccent)),
          if (sub.error != null)
            Text(sub.error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}
