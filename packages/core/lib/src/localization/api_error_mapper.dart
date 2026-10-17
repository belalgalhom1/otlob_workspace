import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Parsed view of a backend error payload.
class _BackendError {
  const _BackendError({this.message, this.errors});

  /// Raw `message` the backend sent (usually a dot-separated translation key).
  final String? message;

  /// Validation details (`field -> [messages]`) when the failure is a 400 from
  /// the `ValidationPipe`.
  final Map<String, List<String>>? errors;
}

/// Enterprise API error mapper and translator.
///
/// Follows single-source-of-truth architecture by resolving localized messages
/// directly from the core translation catalogs (`packages/core/assets/translations/`).
/// Normalizes dot-separated backend error keys (`auth.error.banned`) to
/// snake_case (`auth_error_banned`) and delegates translation to [EasyLocalization].
///
/// Crucially, a backend message is *never* silently dropped: if a key has no
/// catalog entry it is surfaced verbatim (when human-readable) instead of being
/// replaced by the generic "unexpected error" text.
class ApiErrorMapper {
  const ApiErrorMapper._();

  static final RegExp _keyPattern =
      RegExp(r'^[a-zA-Z0-9_]+([.\-][a-zA-Z0-9_]+)*$');

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
      final data = error.response?.data;
      if (data is Map && data.containsKey('message')) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return _normalizeKey(message);
        }
        if (message is List && message.isNotEmpty) {
          return _normalizeKey(message.first.toString());
        }
        if (message is Map && message.isNotEmpty) {
          return 'common_error_validation';
        }
      }
      // A handful of endpoints return a bare string body on failure.
      if (data is String && data.trim().isNotEmpty && _looksLikeKey(data)) {
        return _normalizeKey(data);
      }
      return 'common_error_server_error';
    }

    final errorString = error.toString().replaceFirst('Exception: ', '').trim();
    if (errorString.isEmpty) {
      return 'common_error_unknown';
    }

    return _looksLikeKey(errorString)
        ? _normalizeKey(errorString)
        : 'common_error_unknown';
  }

  /// Translates a backend error key, [DioException], or [Exception] using
  /// [EasyLocalization].
  ///
  /// Resolution order:
  /// 1. Translate the backend `message` key (string or first list entry).
  /// 2. Append translated `errors` validation details, when present.
  /// 3. If the key has no catalog entry but the backend sent human-readable
  ///    text, return that text verbatim.
  /// 4. Otherwise fall back to a localized generic message.
  static String translate(
    dynamic error, {
    String? locale,
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
  }) {
    if (error == null) return '';

    final isArabic = locale?.toLowerCase().startsWith('ar') ?? true;

    // A plain string is either a translation key or a human-readable message.
    if (error is String) {
      final raw = error.trim();
      if (raw.isEmpty) return '';
      final key = _looksLikeKey(raw) ? _normalizeKey(raw) : raw;
      final translated = _translateKey(key, context, args, namedArgs);
      if (translated != null) return translated;
      if (!_looksLikeKey(raw)) return raw;
      return _generic(isArabic);
    }

    final extracted = _extract(error);

    String? message;
    final rawMessage = extracted.message?.trim();
    if (rawMessage != null && rawMessage.isNotEmpty) {
      message = _translateKey(
        _normalizeKey(rawMessage),
        context,
        args,
        namedArgs,
      );
      // Untranslated but human-readable -> show exactly what the backend said.
      if (message == null && !_looksLikeKey(rawMessage)) {
        message = rawMessage;
      }
    }

    // No usable backend message: resolve from the exception itself
    // (e.g. network failures -> `common_error_server_error`).
    message ??= _translateKey(
      _normalizeKey(fromError(error)),
      context,
      args,
      namedArgs,
    );

    final details = _formatDetails(extracted.errors, context);
    if (details.isNotEmpty) {
      return (message != null && message.isNotEmpty)
          ? '$message\n$details'
          : details;
    }

    return message ?? _generic(isArabic);
  }

  /// Direct fallback lookup retained for backward compatibility.
  static String getFallbackMessage(String key, {bool isArabic = true}) {
    return translate(key, locale: isArabic ? 'ar' : 'en');
  }

  static String? _translateKey(
    String key,
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
  ) {
    if (key.trim().isEmpty) return null;
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
      // EasyLocalization not yet initialized or context is unavailable.
    }
    return null;
  }

  static _BackendError _extract(dynamic error) {
    if (error is! DioException) {
      return _BackendError(message: error?.toString());
    }

    final data = error.response?.data;
    String? message;
    Map<String, List<String>>? errors;

    if (data is Map) {
      final raw = data['message'];
      if (raw is String && raw.trim().isNotEmpty) {
        message = raw;
      } else if (raw is List && raw.isNotEmpty) {
        message = raw.first.toString();
        errors = {'': raw.map((e) => e.toString()).toList()};
      } else if (raw is Map && raw.isNotEmpty) {
        message = 'common.error.validation';
        errors = _parseErrors(raw);
      }

      errors ??= _parseErrors(data['errors']);
      if (message == null && errors != null && errors.isNotEmpty) {
        message = 'common.error.validation';
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }

    return _BackendError(message: message, errors: errors);
  }

  static Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        out[key.toString()] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        out[key.toString()] = [value.toString()];
      }
    });
    return out.isEmpty ? null : out;
  }

  static String _formatDetails(
    Map<String, List<String>>? errors,
    BuildContext? context,
  ) {
    if (errors == null || errors.isEmpty) return '';
    final lines = <String>[];
    errors.forEach((field, messages) {
      final rendered = messages
          .map((m) => _translateKey(_normalizeKey(m), context, null, null) ?? m)
          .join(', ');
      lines.add(field.isEmpty ? rendered : '$field: $rendered');
    });
    return lines.join('\n');
  }

  static bool _looksLikeKey(String value) =>
      _keyPattern.hasMatch(value.trim());

  static String _normalizeKey(String raw) {
    return raw.trim().replaceAll('.', '_').replaceAll('-', '_');
  }

  static String _generic(bool isArabic) {
    return isArabic
        ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'
        : 'An unexpected error occurred. Please try again.';
  }
}
