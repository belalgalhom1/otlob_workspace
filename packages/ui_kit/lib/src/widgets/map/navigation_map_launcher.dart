import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to launch external navigation and map apps cleanly across iOS and Android.
class MapNavigationLauncher {
  /// Opens Google Maps, Apple Maps (on iOS), or web directions to the given destination coordinates.
  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) {
      _showInvalidCoords(context);
      return false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // 1. iOS Google Maps turn-by-turn navigation
      final iosGoogleNav = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
      );
      if (await _tryLaunch(iosGoogleNav, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }

      // 2. Native Apple Maps turn-by-turn directions
      final appleMaps = Uri.parse(
        'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
      );
      if (await _tryLaunch(appleMaps, LaunchMode.externalApplication)) {
        return true;
      }
    } else {
      // 1. Android Google Maps turn-by-turn navigation intent
      final navUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
      if (await _tryLaunch(navUri, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }

      // 2. Standard geo: coordinate intent
      final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
      if (await _tryLaunch(geoUri, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
    }

    // 3. Universal Google Maps web fallback
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    return _launchWithErrorFeedback(
      webUri,
      context != null && context.mounted ? context : null,
    );
  }

  /// Opens an external map app pinned at [latitude], [longitude] (non-navigation view).
  static Future<bool> launchLocation({
    required double latitude,
    required double longitude,
    String? label,
    BuildContext? context,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) {
      _showInvalidCoords(context);
      return false;
    }

    final encodedLabel = (label != null && label.trim().isNotEmpty)
        ? Uri.encodeComponent(label.trim())
        : null;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final iosGoogle = Uri.parse(
        'comgooglemaps://?q=$latitude,$longitude',
      );
      if (await _tryLaunch(iosGoogle, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }

      final appleUrl = encodedLabel != null
          ? 'https://maps.apple.com/?ll=$latitude,$longitude&q=$encodedLabel'
          : 'https://maps.apple.com/?ll=$latitude,$longitude';
      if (await _tryLaunch(Uri.parse(appleUrl), LaunchMode.externalApplication)) {
        return true;
      }
    } else {
      final geoQuery = encodedLabel != null
          ? '$latitude,$longitude($encodedLabel)'
          : '$latitude,$longitude';
      final geoUri = Uri.parse('geo:$latitude,$longitude?q=$geoQuery');
      if (await _tryLaunch(geoUri, LaunchMode.externalNonBrowserApplication)) {
        return true;
      }
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    return _launchWithErrorFeedback(
      webUri,
      context != null && context.mounted ? context : null,
    );
  }

  static bool _hasValidCoordinates(double latitude, double longitude) {
    return latitude != 0.0 && longitude != 0.0;
  }

  static void _showInvalidCoords(BuildContext? context) {
    if (context == null || !context.mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'الإحداثيات غير متوفرة' : 'Location coordinates not available',
        ),
      ),
    );
  }

  static Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> _launchWithErrorFeedback(
    Uri webUri,
    BuildContext? context,
  ) async {
    try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
      return await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
      return false;
    }
  }
}
