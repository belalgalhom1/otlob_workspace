import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shared helper to surface actionable iOS/Android permission recovery UI
/// when `image_picker` or media APIs fail due to denied camera/photo access.
class MediaPermissionHelper {
  MediaPermissionHelper._();

  /// Returns `true` when [error] represents a camera or photo-library access
  /// denial thrown by `image_picker` on iOS/Android.
  static bool isAccessDeniedError(Object error) {
    if (error is! PlatformException) return false;
    final code = error.code.toLowerCase();
    return code == 'camera_access_denied' ||
        code == 'photo_access_denied' ||
        code == 'camera_access_restricted' ||
        code == 'photo_access_restricted';
  }

  /// Displays a localized SnackBar prompting the user to enable permissions in
  /// Settings when [error] is an access denial, or [fallbackMessage] otherwise.
  static void handlePickerError(
    Object error, {
    BuildContext? context,
    String? fallbackMessage,
  }) {
    if (context == null || !context.mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (isAccessDeniedError(error)) {
      final isCamera =
          error is PlatformException && error.code.toLowerCase().contains('camera');
      final message = isCamera
          ? (isAr
              ? 'يرجى السماح بالوصول إلى الكاميرا من الإعدادات'
              : 'Please allow camera access in Settings')
          : (isAr
              ? 'يرجى السماح بالوصول إلى الصور من الإعدادات'
              : 'Please allow photo library access in Settings');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: isAr ? 'الإعدادات' : 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallbackMessage)),
      );
    }
  }
}
