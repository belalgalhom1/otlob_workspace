import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Unified external action launcher for phone calls, email intents, and URLs
/// with iOS-compatible launch modes and user-friendly localized fallbacks.
class ExternalActionLauncher {
  ExternalActionLauncher._();

  /// Normalizes a phone string and opens the system dialer.
  static Future<bool> callPhone(
    String? rawPhone, {
    BuildContext? context,
  }) async {
    final cleaned = (rawPhone ?? '').trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      _showFailure(
        context,
        ar: 'رقم الهاتف غير صالح',
        en: 'Invalid phone number',
      );
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    final launched = await _launchUri(uri, mode: LaunchMode.externalApplication);
    if (!launched && context != null && context.mounted) {
      _showFailure(
        context,
        ar: 'تعذر فتح تطبيق الاتصال',
        en: 'Could not open phone dialer',
      );
    }
    return launched;
  }

  /// Opens the default mail client targeting [email].
  static Future<bool> sendEmail(
    String? email, {
    String? subject,
    String? body,
    BuildContext? context,
  }) async {
    final trimmedEmail = (email ?? '').trim();
    if (trimmedEmail.isEmpty) {
      _showFailure(
        context,
        ar: 'البريد الإلكتروني غير صالح',
        en: 'Invalid email address',
      );
      return false;
    }
    final queryParameters = <String, String>{
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (body != null && body.isNotEmpty) 'body': body,
    };
    final uri = Uri(
      scheme: 'mailto',
      path: trimmedEmail,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final launched = await _launchUri(uri, mode: LaunchMode.externalApplication);
    if (!launched && context != null && context.mounted) {
      _showFailure(
        context,
        ar: 'لا يوجد تطبيق بريد إلكتروني متاح',
        en: 'No email app available on this device',
      );
    }
    return launched;
  }

  /// Launches a web/file/deep-link [url] externally, falling back gracefully.
  static Future<bool> openWebUrl(
    String? url, {
    BuildContext? context,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = Uri.tryParse((url ?? '').trim());
    if (uri == null || uri.scheme.isEmpty) {
      _showFailure(
        context,
        ar: 'الرابط غير صالح',
        en: 'Invalid link',
      );
      return false;
    }

    var launched = await _launchUri(uri, mode: mode);
    if (!launched && mode != LaunchMode.platformDefault) {
      launched = await _launchUri(uri, mode: LaunchMode.platformDefault);
    }
    if (!launched && context != null && context.mounted) {
      _showFailure(
        context,
        ar: 'تعذر فتح الرابط',
        en: 'Could not open link',
      );
    }
    return launched;
  }

  static Future<bool> _launchUri(
    Uri uri, {
    required LaunchMode mode,
  }) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }
      // On iOS/Android, some universal links succeed even when canLaunchUrl
      // returns false due to scheme query constraints; try direct launch once.
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return await launchUrl(uri, mode: mode);
      }
    } catch (_) {}
    return false;
  }

  static void _showFailure(
    BuildContext? context, {
    required String ar,
    required String en,
  }) {
    if (context == null || !context.mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isAr ? ar : en)),
    );
  }
}
