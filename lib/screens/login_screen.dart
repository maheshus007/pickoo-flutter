import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showSignup = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF121212), Color(0xFF1E1E1E)]
        : [Colors.grey.shade100, Colors.white];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: isDark ? const Color(0xFF222428) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _showSignup ? 'Create your account' : 'Welcome back',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showSignup ? 'Sign up to start editing photos.' : 'Login to continue editing.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: (isDark ? Colors.white70 : Colors.black54),
                              ),
                        ),
                        const SizedBox(height: 24),
                        if (auth.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(.7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (auth.error != null) const SizedBox(height: 18),
                        _InputBlock(
                          controller: _emailCtrl,
                          label: 'Email (optional)',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _InputBlock(
                          controller: _mobileCtrl,
                          label: 'Mobile (optional)',
                          keyboardType: TextInputType.phone,
                        ),
                        _InputBlock(
                          controller: _passwordCtrl,
                          label: 'Password',
                          obscure: !_showPassword,
                          trailing: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: isDark ? Colors.white70 : Colors.black54),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: auth.loading
                                ? null
                                : () {
                                    final email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
                                    final mobile = _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim();
                                    final password = _passwordCtrl.text;
                                    if (_showSignup) {
                                      ref.read(authProvider.notifier).signup(email: email, mobile: mobile, password: password);
                                    } else {
                                      ref.read(authProvider.notifier).login(email: email, mobile: mobile, password: password);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: Text(
                              auth.loading ? 'Please wait…' : _showSignup ? 'Create Account' : 'Login',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: auth.loading ? null : () => setState(() => _showSignup = !_showSignup),
                          child: Text(
                            _showSignup ? 'Already have an account? Login' : 'Need an account? Sign Up',
                            style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)), const SizedBox(width: 12), Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)), const SizedBox(width: 12), Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12))]),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: auth.loading ? null : () => ref.read(authProvider.notifier).googleLogin(),
                            icon: const Icon(Icons.login),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: auth.loading ? null : () => ref.read(authProvider.notifier).facebookLogin('FAKE_FACEBOOK_TOKEN_PLACEHOLDER'),
                            icon: const Icon(Icons.facebook),
                            label: const Text('Continue with Facebook'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBlock extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  const _InputBlock({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Improve contrast: dynamically choose a high-contrast foreground color.
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white70 : Colors.black45;
    final fill = isDark ? Colors.white12 : Colors.black.withOpacity(0.04);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(color: baseColor, fontWeight: FontWeight.w500),
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: baseColor.withOpacity(.85), fontSize: 14),
          filled: true,
          fillColor: fill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor.withOpacity(.55)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
          ),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}
