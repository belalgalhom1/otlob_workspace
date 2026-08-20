import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:api/api.dart';
import '../network/dio_client.dart';
import '../permissions/permission_service.dart';
import '../location/location_service.dart';
import '../network/push_notification_service.dart';
import '../config/media_config_service.dart';

import '../auth/token_service.dart';
import '../socket/socket_service.dart';
import '../config/env_config.dart';

// Provides the secure storage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provides the base URL, can be overridden based on flavor or env
final baseUrlProvider = Provider<String>((ref) {
  return EnvConfig.apiUrl;
});

// Provides the fully configured Dio client
final dioClientProvider = Provider<DioClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(baseUrl, secureStorage);
});

// Exposes the underlying Dio instance directly for ease of use
final dioProvider = Provider((ref) {
  return ref.watch(dioClientProvider).dio;
});

// Provides the generated Api client
final apiClientProvider = Provider<Api>((ref) {
  final dio = ref.watch(dioProvider);
  return Api(dio: dio, serializers: standardSerializers);
});

// Provides the unified TokenService
final tokenServiceProvider = Provider<TokenService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return TokenService(apiClient, storage);
});

// Provides the core socket service
final coreSocketServiceProvider = Provider<CoreSocketService>((ref) {
  final tokenService = ref.watch(tokenServiceProvider);
  return CoreSocketService(
    isTokenExpired: tokenService.isTokenExpired,
    refreshToken: tokenService.refreshToken,
  );
});

// Provides the permission service
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

// Provides the generic core location service
final coreLocationServiceProvider = Provider<CoreLocationService>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  return CoreLocationService(permissionService);
});

// Provides the PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final api = ref.watch(apiClientProvider);
  return PushNotificationService(api.getDevicesPushNotificationsApi());
});

final mediaConfigServiceProvider = Provider<MediaConfigService>((ref) {
  return MediaConfigService();
});
