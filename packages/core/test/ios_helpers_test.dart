import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/test.dart';

void main() {
  group('iOS Secure Storage Configuration', () {
    test('uses KeychainAccessibility.first_unlock for background resilience', () {
      expect(
        appIosSecureStorageOptions.accessibility,
        KeychainAccessibility.first_unlock,
      );
      expect(
        appSecureStorage.iOptions.accessibility,
        KeychainAccessibility.first_unlock,
      );
    });
  });

  group('ApiErrorMapper iOS platform and auth mapping', () {
    test('maps Keychain PlatformException (-34018 / -25299) to canonical key', () {
      final entitlementError = PlatformException(
        code: 'Unexpected security result code',
        message: 'Code: -34018, Message: A required entitlement is not present.',
        details: -34018,
      );
      final duplicateError = PlatformException(
        code: 'Unexpected security result code',
        message: 'Code: -25299, Message: The specified item already exists in the keychain.',
        details: -25299,
      );

      expect(
        ApiErrorMapper.fromError(entitlementError),
        'auth_error_secure_storage_unavailable',
      );
      expect(
        ApiErrorMapper.fromError(duplicateError),
        'auth_error_secure_storage_unavailable',
      );
    });

    test('maps Google Sign-In PlatformException configuration errors distinctly', () {
      final configError = PlatformException(
        code: 'google_sign_in',
        message: 'No active configuration. Make sure GIDClientID is set in Info.plist.',
      );
      final genericGoogleError = PlatformException(
        code: 'google_sign_in',
        message: 'Token exchange aborted.',
      );

      expect(
        ApiErrorMapper.fromError(configError),
        'auth_error_google_not_configured',
      );
      expect(
        ApiErrorMapper.fromError(genericGoogleError),
        'auth_error_google_sign_in_failed',
      );
    });

    test('maps TimeoutException to common_error_server_error', () {
      expect(
        ApiErrorMapper.fromError(TimeoutException('timed out')),
        'common_error_server_error',
      );
    });

    test('strips Exception prefix when normalizing auth exception keys', () {
      final err = Exception('auth.error.google_not_configured');
      expect(ApiErrorMapper.fromError(err), 'auth_error_google_not_configured');
      // EasyLocalization isn't mounted in headless unit tests, so translate()
      // falls back to _generic without leaking the raw "Exception:" prefix.
      final translated = ApiErrorMapper.translate(err, locale: 'en');
      expect(translated.startsWith('Exception:'), isFalse);
    });

    test('new auth error translation keys exist in en.json and ar.json', () {
      const requiredKeys = [
        'auth_error_google_not_configured',
        'auth_error_google_sign_in_failed',
        'auth_error_secure_storage_unavailable',
      ];
      for (final locale in ['en', 'ar']) {
        final file = File('assets/translations/$locale.json');
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in requiredKeys) {
          expect(map[key], isA<String>());
          expect((map[key] as String).trim(), isNotEmpty);
        }
      }
    });
  });
}
