import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to launch external navigation apps (Google Maps, Waze, or web directions).
class MapNavigationLauncher {
  /// Opens Google Maps / External Navigation to the given destination coordinates.
  ///
  /// Strategy:
  /// 1. Tries `google.navigation:q=lat,lng&mode=d` (opens Google Maps turn-by-turn navigation directly).
  /// 2. Tries `geo:lat,lng?q=lat,lng` (opens any installed map application).
  /// 3. Falls back to web URL `https://www.google.com/maps/dir/?api=1&destination=lat,lng`.
  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    BuildContext? context,
  }) async {
    if (latitude == 0.0 || longitude == 0.0) {
      if (context != null && context.mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'الإحداثيات غير متوفرة' : 'Location coordinates not available',
            ),
          ),
        );
      }
      return false;
    }

    // 1. Google Maps turn-by-turn navigation intent
    final navUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
    try {
      if (await canLaunchUrl(navUri)) {
        final ok = await launchUrl(navUri, mode: LaunchMode.externalNonBrowserApplication);
        if (ok) return true;
      }
    } catch (_) {}

    // 2. Standard geo: coordinate intent
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    try {
      if (await canLaunchUrl(geoUri)) {
        final ok = await launchUrl(geoUri, mode: LaunchMode.externalNonBrowserApplication);
        if (ok) return true;
      }
    } catch (_) {}

    // 3. Fallback to universal web Google Maps URL
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
