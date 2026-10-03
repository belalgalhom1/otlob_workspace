import 'package:flutter/material.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:core/core.dart';

class ErrorUtils {
  /// Translates a backend error key or Exception to a localized Arabic or English string.
  static String translate(BuildContext context, dynamic error) {
    if (error == null) return '';

    final l10n = AppLocalizations.of(context);
    final locale = l10n?.localeName ?? 'ar';

    final message = error is String ? error : ApiErrorMapper.fromError(error);
    final lowerMessage = message.trim().toLowerCase();

    if (lowerMessage == 'forbidden resource' ||
        lowerMessage == 'forbidden' ||
        lowerMessage == 'access denied') {
      return locale.startsWith('ar')
          ? 'تم رفض الوصول: ليس لديك صلاحية.'
          : 'Access Denied: You do not have permission.';
    }

    return ApiErrorMapper.translate(error, locale: locale, context: context);
  }

  /// Errors keyed to a dead/revoked session or an auth guard rejection.
  ///
  /// A 401/403 of this class means the token (or the account) can no longer
  /// authenticate. Surfacing it to the UI is never useful — the app must
  /// bounce back to the login screen instead of stranding the dashboard on an
  /// "Unauthorized" error card.
  static bool isAuthSessionError(dynamic error) {
    if (error == null) return false;
    switch (ApiErrorMapper.fromError(error)) {
      case 'common_error_unauthorized':
      case 'common_error_forbidden':
      case 'auth_error_session_expired':
      case 'auth_error_session_compromised':
      case 'auth_error_user_not_found':
      case 'auth_error_missing_header':
      case 'auth_error_banned':
        return true;
    }
    return false;
  }
}
