import 'package:core/core.dart';
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
}
