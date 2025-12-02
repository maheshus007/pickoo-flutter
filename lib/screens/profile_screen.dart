import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/tool_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_plan.dart';
import '../widgets/neon_card.dart';
import 'payment_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late PageController _pageController;
  int _currentPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    // Find initial plan index
    final currentPlan = ref.read(subscriptionProvider).plan;
    _currentPlanIndex = PlansRegistry.all.indexWhere((p) => p.id == currentPlan.id);
    if (_currentPlanIndex == -1) _currentPlanIndex = 0;
    
    _pageController = PageController(
      initialPage: _currentPlanIndex,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Subscription Plans', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          
          // Scrollable plan carousel
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPlanIndex = index;
                });
              },
              itemCount: PlansRegistry.all.length,
              itemBuilder: (context, index) {
                final plan = PlansRegistry.all[index];
                final selected = plan.id == sub.plan.id;
                final isActive = index == _currentPlanIndex;
                
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: NeonCard(
                      selected: selected,
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.priceLabel,
                            style: TextStyle(
                              color: selected ? Theme.of(context).colorScheme.primary : Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (plan.imageQuota != null)
                            Text(
                              '${plan.imageQuota} images',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          if (plan.durationDays != null)
                            Text(
                              '${plan.durationDays} day(s)',
                              style: const TextStyle(color: Colors.white38, fontSize: 14),
                            ),
                          if (selected)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              PlansRegistry.all.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPlanIndex ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPlanIndex
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Select/Upgrade button
          ElevatedButton(
            onPressed: () {
              final selectedPlan = PlansRegistry.all[_currentPlanIndex];
              if (selectedPlan.id == 'free') {
                ref.read(subscriptionProvider.notifier).purchase(selectedPlan);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(plan: selectedPlan),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              PlansRegistry.all[_currentPlanIndex].id == sub.plan.id
                  ? 'Current Plan'
                  : PlansRegistry.all[_currentPlanIndex].id == 'free'
                      ? 'Switch to Free Plan'
                      : 'Upgrade to This Plan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          Text('Current Plan: ${sub.plan.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          if (sub.plan.imageQuota != null)
            Text('Remaining: ${sub.remainingImages} / ${sub.plan.imageQuota}', style: const TextStyle(color: Colors.white70)),
          if (sub.isExpired)
            const Text('Plan expired. Purchase a new plan.', style: TextStyle(color: Colors.redAccent)),
          if (sub.error != null)
            Text(sub.error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}
