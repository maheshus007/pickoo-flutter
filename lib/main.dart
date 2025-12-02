import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_nav.dart';
import 'utils/theme.dart';

/// Entry point of Pickoo AI Photo Editor.
void main() {
  runApp(const ProviderScope(child: PickooApp()));
}

class PickooApp extends ConsumerStatefulWidget {
  const PickooApp({super.key});
  @override
  ConsumerState<PickooApp> createState() => _PickooAppState();
}

class _PickooAppState extends ConsumerState<PickooApp> {
  int _index = 0;
  final _screens = const [
    HomeScreen(),
    GalleryScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'Pickoo AI',
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: auth.isAuthenticated
          ? Scaffold(
              body: _screens[_index],
              bottomNavigationBar: BottomNav(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
              ),
            )
          : const LoginScreen(),
    );
  }
}
