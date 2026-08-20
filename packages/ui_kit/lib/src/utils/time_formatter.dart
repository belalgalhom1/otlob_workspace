import 'package:flutter/widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

class TimeFormatter {
  static bool _initialized = false;

  /// Initializes timeago locales. Call this once in the app initialization.
  static void initialize() {
    if (!_initialized) {
      timeago.setLocaleMessages('ar', timeago.ArMessages());
      timeago.setLocaleMessages('ar_short', timeago.ArShortMessages());
      timeago.setLocaleMessages('en', timeago.EnMessages());
      timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
      _initialized = true;
    }
  }

  /// Formats a DateTime into a relative "time ago" string based on the current context's locale.
  static String formatTimeAgo(BuildContext context, DateTime date, {bool short = false}) {
    if (!_initialized) {
      initialize();
    }
    
    final locale = Localizations.localeOf(context).languageCode;
    final String localeFormat = short ? '${locale}_short' : locale;
    
    return timeago.format(date, locale: localeFormat);
  }
}
