import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service.g.dart';

class PermissionPermanentlyDeniedException implements Exception {}

@Riverpod(keepAlive: true)
PermissionService permissionService(Ref ref) => PermissionService();

class PermissionService {
  bool _isAllowed(PermissionStatus status, {bool allowProvisional = false}) {
    return status.isGranted ||
        status.isLimited ||
        (allowProvisional && status.isProvisional);
  }

  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;
    if (_isAllowed(status, allowProvisional: permission == Permission.notification)) {
      return true;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw PermissionPermanentlyDeniedException();
    }

    final result = await permission.request();
    if (_isAllowed(result, allowProvisional: permission == Permission.notification)) {
      return true;
    }
    if (result.isPermanentlyDenied || result.isRestricted) {
      throw PermissionPermanentlyDeniedException();
    }
    return false;
  }

  Future<bool> requestGalleryPermission() async {
    if (Platform.isIOS) return requestPermission(Permission.photos);

    final photoStatus = await Permission.photos.request();
    if (_isAllowed(photoStatus)) return true;

    final storageStatus = await Permission.storage.request();
    if (_isAllowed(storageStatus)) return true;

    if (photoStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException();
    }

    return false;
  }

  Future<bool> openSettings() => openAppSettings();
}
