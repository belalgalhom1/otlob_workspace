import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:core/core.dart';

class ErrorUtils {
  /// Translates a backend error key or Exception to a localized Arabic or
  /// English string, surfacing the message the backend actually sent instead
  /// of a generic fallback whenever possible.
  static String translate(BuildContext context, dynamic error) {
    if (error == null) return '';

    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    final message = error is String ? error : ApiErrorMapper.fromError(error);
    final lowerMessage = message.trim().toLowerCase();

    if (lowerMessage == 'forbidden resource' ||
        lowerMessage == 'forbidden' ||
        lowerMessage == 'access denied') {
      return 'common_error_forbidden'.tr(context: context);
    }

    return ApiErrorMapper.translate(error, locale: locale, context: context);
  }

  /// Errors keyed to a dead/revoked session or an auth guard rejection.
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
