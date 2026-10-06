import 'package:api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'shared_platform_settings_repository.dart';

class AppStatusResult {
  final bool maintenance;
  final bool mustUpdate;
  final bool shouldUpdate;
  final String? storeUrl;

  const AppStatusResult({
    this.maintenance = false,
    this.mustUpdate = false,
    this.shouldUpdate = false,
    this.storeUrl,
  });
}

/// Calls the public app-version-check endpoint and maps the response.
/// Returns null when the check itself fails (offline/backend down) so callers
/// can fail open and let the app's normal error states handle it.
Future<AppStatusResult?> checkAppStatus(
  SharedPlatformSettingsRepository repo,
) async {
  try {
    final pkg = await PackageInfo.fromPlatform();
    final raw = await repo.checkAppVersion(
      AppVersionCheckDto(
        (b) => b
          ..platform = defaultTargetPlatform == TargetPlatform.iOS
              ? AppVersionCheckDtoPlatformEnum.ios
              : AppVersionCheckDtoPlatformEnum.android
          ..version = pkg.version,
      ),
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return AppStatusResult(
      maintenance: map['isMaintenanceMode'] == true,
      mustUpdate: map['mustUpdate'] == true,
      shouldUpdate: map['shouldUpdate'] == true,
      storeUrl: map['storeUrl']?.toString(),
    );
  } catch (_) {
    return null;
  }
}
