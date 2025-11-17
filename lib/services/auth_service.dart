import 'package:google_sign_in/google_sign_in.dart';

/// Placeholder auth service. Real Firebase integration would add:
/// - firebase_core initialization in main
/// - firebase_auth usage for persistent sessions
/// For now, we provide a thin wrapper around GoogleSignIn to simulate flow.
class AuthService {
  // Explicit web clientId ensures proper audience in ID tokens; replace with your real Web OAuth Client ID.
  static const String _webClientId = '37994016666-kl3i8dtdn2ehji5m8ivojcp53aramd0t.apps.googleusercontent.com';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _webClientId,
    scopes: ["email", "profile"],
  );

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> currentIdToken() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken; // may be null on some platforms
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<GoogleSignInAccount?> currentUser() async {
    return _googleSignIn.currentUser;
  }
}
