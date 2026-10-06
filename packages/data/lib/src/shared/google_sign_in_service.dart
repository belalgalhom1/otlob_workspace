import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static const String serverClientId =
      '818727905926-bbsknrt1aqvpcs11u2qngf4onegrtsu0.apps.googleusercontent.com';

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  /// Runs the interactive Google flow and returns a Google ID token suitable
  /// for POST /auth/social. Throws when the user cancels or no token arrives.
  static Future<String> getIdToken() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('google.sign_in.no_token');
    }
    return idToken;
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
