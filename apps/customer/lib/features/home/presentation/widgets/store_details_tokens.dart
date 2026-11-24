import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens, dual-theme palette, typography helpers, and strict Arabic
/// product-name search utilities for the Store Details & Menu screen.
class StoreDetailsTokens {
  StoreDetailsTokens._();

  // Brand Gold Accents
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldHover = Color(0xFFF6C667);
  static const Color goldTextLight = Color(0xFFB87B14);
  static const Color darkOnGold = Color(0xFF14120E);

  // Semantic Accents
  static const Color errorRed = Color(0xFFEF4444);
  static const Color openGreen = Color(0xFF10B981);

  // Banner Fallback Gradient: linear-gradient(135deg, #083B66, #0E6BA8, #38BDF8)
  static const LinearGradient bannerFallbackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF083B66), Color(0xFF0E6BA8), Color(0xFF38BDF8)],
  );

  // Typography
  static const String arabicFont = 'Cairo';
  static const List<String> arabicFontFallback = [
    'Cairo',
    'Tajawal',
    'Roboto',
    'Arial',
  ];

  static const String numericFont = 'Inter';
  static const List<String> numericFontFallback = [
    'Inter',
    'Cairo',
    'Roboto',
    'Arial',
  ];

  /// Cairo text style (never applies arbitrary letterSpacing so Arabic shaping
  /// remains connected and crisp).
  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: arabicFont,
      fontFamilyFallback: arabicFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  /// Inter tabular numeric style for prices, ratings, and item counts.
  static TextStyle numeric({
    required double size,
    FontWeight weight = FontWeight.w800,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: numericFont,
      fontFamilyFallback: numericFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Formats prices cleanly without trailing `.00` for whole numbers.
  static String formatPrice(num value) {
    final d = value.toDouble();
    if ((d - d.roundToDouble()).abs() < 0.005) {
      return d.round().toString();
    }
    return d.toStringAsFixed(2);
  }

  static final RegExp _arabicDiacritics = RegExp(
    r'[\u064B-\u065F\u0670\u0640]',
  );
  static final RegExp _alefVariants = RegExp(r'[أإآٱ]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Normalizes Arabic & Latin text for strict product-name matching:
  /// - أ / إ / آ / ٱ → ا
  /// - ة → ه
  /// - ى → ي
  /// - strips harakat/diacritics & tatweel
  /// - lowercases & collapses whitespace
  static String normalizeProductName(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw
        .toLowerCase()
        .replaceAll(_arabicDiacritics, '')
        .replaceAll(_alefVariants, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  /// Filters [items] strictly by product name (`name` / `nameAr`) — never
  /// matching descriptions — with exact-match priority when any item's
  /// normalized name equals the normalized query.
  static List<Map<String, dynamic>> filterProductsByStrictName(
    Iterable<Map<String, dynamic>> items,
    String rawQuery,
  ) {
    final list = items.toList(growable: false);
    final query = normalizeProductName(rawQuery);
    if (query.isEmpty) return list;

    final exactMatches = <Map<String, dynamic>>[];
    final partialMatches = <Map<String, dynamic>>[];

    for (final item in list) {
      final normAr = normalizeProductName(item['nameAr']?.toString());
      final normEn = normalizeProductName(item['name']?.toString());

      final isExact =
          (normAr.isNotEmpty && normAr == query) ||
          (normEn.isNotEmpty && normEn == query);
      if (isExact) {
        exactMatches.add(item);
        continue;
      }

      final isPartial =
          (normAr.isNotEmpty && normAr.contains(query)) ||
          (normEn.isNotEmpty && normEn.contains(query));
      if (isPartial) {
        partialMatches.add(item);
      }
    }

    return exactMatches.isNotEmpty ? exactMatches : partialMatches;
  }

  /// Returns a clean image URL from backend data, rejecting empty strings and
  /// hardcoded stock fallback URLs.
  static String? cleanBackendImageUrl(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (value.contains('images.unsplash.com') ||
        value.contains('loremflickr.com')) {
      return null;
    }
    return value;
  }
}

/// Exact Dark & Light color tokens for Store Details & Menu.
class StoreDetailsPalette {
  final bool isDark;
  final Color bgMain;
  final Color bgCard;
  final Color bgCard2;
  final Color inputBg;
  final Color textPrimary;
  final Color textMuted;
  final Color goldText;
  final Color borderGold;
  final Color sheetTopBorder;
  final BoxShadow cardShadow;
  final SystemUiOverlayStyle systemOverlayStyle;

  const StoreDetailsPalette._({
    required this.isDark,
    required this.bgMain,
    required this.bgCard,
    required this.bgCard2,
    required this.inputBg,
    required this.textPrimary,
    required this.textMuted,
    required this.goldText,
    required this.borderGold,
    required this.sheetTopBorder,
    required this.cardShadow,
    required this.systemOverlayStyle,
  });

  static const StoreDetailsPalette dark = StoreDetailsPalette._(
    isDark: true,
    bgMain: Color(0xFF0F0E0C),
    bgCard: Color(0xFF1A1815),
    bgCard2: Color(0xFF24211C),
    inputBg: Color(0xFF1E1C18),
    textPrimary: Color(0xFFF7F4EE),
    textMuted: Color(0xFF9E9689),
    goldText: StoreDetailsTokens.gold,
    borderGold: Color.fromRGBO(229, 169, 60, 0.28),
    sheetTopBorder: Color.fromRGBO(229, 169, 60, 0.40),
    cardShadow: BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.42),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const StoreDetailsPalette light = StoreDetailsPalette._(
    isDark: false,
    bgMain: Color(0xFFF7F6F2),
    bgCard: Color(0xFFFFFFFF),
    bgCard2: Color(0xFFF1EFEA),
    inputBg: Color(0xFFF3F2EE),
    textPrimary: Color(0xFF181613),
    textMuted: Color(0xFF6E6A63),
    goldText: StoreDetailsTokens.goldTextLight,
    borderGold: Color.fromRGBO(200, 141, 38, 0.30),
    sheetTopBorder: Color.fromRGBO(229, 169, 60, 0.40),
    cardShadow: BoxShadow(
      color: Color.fromRGBO(24, 22, 19, 0.06),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static StoreDetailsPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static StoreDetailsPalette fromBrightness(bool isDark) {
    return isDark ? dark : light;
  }
}
