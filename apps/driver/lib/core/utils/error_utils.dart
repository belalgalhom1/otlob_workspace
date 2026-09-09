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
}
