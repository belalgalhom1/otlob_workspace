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

  /// Renders a zone-deletion failure with the branch details the backend
  /// attached to the error payload, e.g.:
  ///
  ///   This delivery zone has stores assigned to it. Move or remove them first.
  ///
  ///   Main Branch — Downtown
  static String translateZoneDeleteDetails(BuildContext context, dynamic error) {
    final base = translate(context, error);

    if (error is! DioException) return base;

    final data = error.response?.data;
    final errors = data is Map ? data['errors'] : null;
    final branches = errors is Map ? errors['branches'] : null;
    if (branches is! List || branches.isEmpty) return base;

    final l10n = AppLocalizations.of(context);
    final isArabic = (l10n?.localeName ?? 'ar').startsWith('ar');

    final lines = branches.map((b) {
      if (b is! Map) return b.toString();
      final branchName =
          (isArabic && (b['nameAr']?.toString().isNotEmpty ?? false))
              ? b['nameAr']!.toString()
              : (b['name']?.toString() ?? '');
      final storeName =
          (isArabic && (b['vendorNameAr']?.toString().isNotEmpty ?? false))
              ? b['vendorNameAr']!.toString()
              : (b['vendorName']?.toString() ?? '');

      final parts = <String>[
        if (branchName.isNotEmpty) branchName,
        if (storeName.isNotEmpty) storeName,
      ];

      return parts.isEmpty ? '?' : parts.join(' — ');
    }).join('\n');

    return '$base\n\n$lines';
  }
}