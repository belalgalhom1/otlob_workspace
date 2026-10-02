import 'package:flutter/material.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';

class ErrorUtils {
  /// Translates a backend error/success key, [DioException], or [Exception] to
  /// a localized Arabic or English string using the shared core catalogs, so
  /// both apps show identical messages for the same backend error.
  static String translate(BuildContext context, dynamic error) {
    if (error == null) return '';

    final l10n = AppLocalizations.of(context);
    final locale = l10n?.localeName ?? 'ar';

    final message = error is String ? error : ApiErrorMapper.fromError(error);
    final lowerMessage = message.trim().toLowerCase();

    if (lowerMessage == 'forbidden resource' ||
        lowerMessage == 'forbidden' ||
        lowerMessage == 'access denied') {
      return l10n?.common_error_forbidden ?? '';
    }

    return ApiErrorMapper.translate(message, locale: locale, context: context);
  }
}