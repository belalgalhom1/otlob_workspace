import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show PlatformException;
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

  static String _mapFailureKey({String? code, String? message}) {
    final text = '${code ?? ''} ${message ?? ''}'.toLowerCase();
    if (text.contains('clientconfigurationerror') ||
        text.contains('providerconfigurationerror') ||
        text.contains('gidclientid') ||
        text.contains('client_id') ||
        text.contains('clientid') ||
        text.contains('url scheme') ||
        text.contains('active configuration') ||
        text.contains('configuration')) {
      return 'auth.error.google_not_configured';
    }
    return 'auth.error.google_sign_in_failed';
  }

  /// Runs the interactive Google flow and returns a Google ID token suitable
  /// for POST /auth/social. Throws a canonical translation key when the user
  /// cancels or Google Sign-In cannot complete.
  static Future<String> getIdToken() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('google.sign_in.no_token');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw Exception('google.sign_in.no_token');
      }
      debugPrint(
        'GoogleSignInException: code=${e.code}, description=${e.description}, details=${e.details}',
      );
      throw Exception(
        _mapFailureKey(
          code: e.code.name,
          message: '${e.description ?? ''} ${e.details ?? ''}',
        ),
      );
    } on PlatformException catch (e) {
      final str = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (str.contains('canceled') || str.contains('cancelled')) {
        throw Exception('google.sign_in.no_token');
      }
      debugPrint(
        'GoogleSignIn PlatformException: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      throw Exception(_mapFailureKey(code: e.code, message: e.message));
    } catch (e) {
      final str = e.toString();
      if (str.contains('google.sign_in.no_token')) rethrow;
      final lower = str.toLowerCase();
      if (lower.contains('canceled') || lower.contains('cancelled')) {
        throw Exception('google.sign_in.no_token');
      }
      debugPrint('GoogleSignIn unexpected error (${e.runtimeType}): $e');
      throw Exception(_mapFailureKey(message: str));
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
