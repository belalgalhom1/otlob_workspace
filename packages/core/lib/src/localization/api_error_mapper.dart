import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Enterprise API error mapper and translator.
///
/// Follows single-source-of-truth architecture by resolving localized messages
/// directly from the core translation catalogs (`packages/core/assets/translations/`).
/// Normalizes dot-separated backend error keys (`auth.error.banned`) to
/// snake_case (`auth_error_banned`) and delegates translation to [EasyLocalization].
class ApiErrorMapper {
  const ApiErrorMapper._();

  /// Extracts and normalizes the error message key from a [DioException],
  /// [Exception], or dynamic error.
  ///
  /// Converts dot-separated backend keys (e.g. `'auth.error.banned'`)
  /// to snake_case keys (e.g. `'auth_error_banned'`) used in translation catalogs.
  static String fromError(dynamic error) {
    if (error == null) {
      return 'common_error_unknown';
    }

    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          final message = data['message'];
          if (message is String && message.trim().isNotEmpty) {
            return _normalizeKey(message);
          } else if (message is List && message.isNotEmpty) {
            return _normalizeKey(message.first.toString());
          }
        }
      }
      return 'common_error_server_error';
    }

    final errorString = error.toString().replaceFirst('Exception: ', '').trim();
    if (errorString.isEmpty) {
      return 'common_error_unknown';
    }

    return _normalizeKey(errorString);
  }

  /// Translates a backend error key, [DioException], or [Exception] using [EasyLocalization].
  ///
  /// Resolves the translation directly from `packages/core/assets/translations/{locale}.json`.
  /// If [EasyLocalization] is not initialized or the key is untranslated,
  /// returns a localized generic fallback message.
  static String translate(
    dynamic error, {
    String? locale,
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
  }) {
    if (error == null) return '';

    final key = error is String && error.contains('_') ? error : fromError(error);

    try {
      final translated = key.tr(
        context: context,
        args: args,
        namedArgs: namedArgs,
      );
      if (translated != key && translated.trim().isNotEmpty) {
        return translated;
      }
    } catch (_) {
      // EasyLocalization not yet initialized or context is unavailable
    }

    final isArabic = locale?.toLowerCase().startsWith('ar') ?? true;
    return isArabic
        ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'
        : 'An unexpected error occurred. Please try again.';
  }

  /// Direct fallback lookup retained for backward compatibility.
  static String getFallbackMessage(String key, {bool isArabic = true}) {
    return translate(key, locale: isArabic ? 'ar' : 'en');
  }

  static String _normalizeKey(String raw) {
    return raw.trim().replaceAll('.', '_').replaceAll('-', '_');
  }
}
