import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  bool _isAllowed(PermissionStatus status, {bool allowProvisional = false}) {
    return status.isGranted ||
        status.isLimited ||
        (allowProvisional && status.isProvisional);
  }

  Future<bool> _request(
    Permission permission,
    String label, {
    bool allowProvisional = false,
  }) async {
    if (kIsWeb) return true;

    final status = await permission.status;
    if (_isAllowed(status, allowProvisional: allowProvisional)) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      debugPrint(
        'PermissionService: $label permission denied ($status).',
      );
      return false;
    }

    final result = await permission.request();
    return _isAllowed(result, allowProvisional: allowProvisional);
  }

  /// Request notification permissions globally
  Future<bool> requestNotificationPermission() {
    // Web handles push natively or via browser prompt.
    return _request(
      Permission.notification,
      'Notification',
      allowProvisional: true,
    );
  }

  /// Request location permissions globally (Both When In Use and Always if needed)
  Future<bool> requestLocationPermission() {
    return _request(Permission.locationWhenInUse, 'Location');
  }

  /// Request Camera permissions globally
  Future<bool> requestCameraPermission() {
    return _request(Permission.camera, 'Camera');
  }

  /// Request Photo Library permissions globally (supports iOS Limited Photos access).
  Future<bool> requestPhotosPermission() {
    return _request(Permission.photos, 'Photos');
  }

  /// Request Microphone permissions globally
  Future<bool> requestMicrophonePermission() {
    return _request(Permission.microphone, 'Microphone');
  }

  /// Open device app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
