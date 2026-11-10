import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request notification permissions globally
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true; // Web handles push natively or via browser prompt
    
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: Notification permission permanently denied.');
      return false;
    }
    
    return false;
  }

  /// Request location permissions globally (Both When In Use and Always if needed)
  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: Location permission permanently denied.');
      return false;
    }
    
    return false;
  }

  /// Request Camera permissions globally
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: Camera permission permanently denied.');
      return false;
    }
    
    return false;
  }

  /// Request Microphone permissions globally (for chat voice notes / audio recording)
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true;

    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: Microphone permission permanently denied.');
      return false;
    }

    return false;
  }

  /// Request Photos permissions globally (supporting iOS 14+ limited photo library)
  Future<bool> requestPhotosPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('PermissionService: Photos permission permanently denied.');
      return false;
    }

    return false;
  }
  
  /// Open device app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
