import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared brand constants, typography helpers, and strict Arabic search
/// normalization utilities for the Store Details & Menu screen.
class StoreDetailsTokens {
  StoreDetailsTokens._();

  // Brand Gold Palette
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFF6C667);
  static const Color goldDark = Color(0xFFC88D26);
  static const Color goldTextLightMode = Color(0xFFB87B14);
  static const Color darkOnGold = Color(0xFF14120E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  // Banner Fallback Gradient (exact prototype gradient when cover image is missing)
  static const LinearGradient bannerFallbackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF083B66),
      Color(0xFF0E6BA8),
      Color(0xFF38BDF8),
    ],
  );

  // Typography
  static const String primaryFont = 'Cairo';
  static const List<String> primaryFallback = [
    'Cairo',
    'Tajawal',
    'Roboto',
    'Arial',
  ];

  static const String numericFont = 'Inter';
  static const List<String> numericFallback = ['Inter', 'Roboto', 'Arial'];

  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontFamilyFallback: primaryFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextStyle numeric({
    required double size,
    FontWeight weight = FontWeight.w800,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: numericFont,
      fontFamilyFallback: numericFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Normalizes Arabic and Latin text for strict product-name matching:
  /// - Lowercases & trims whitespace
  /// - Unifies Alef variants (أ / إ / آ -> ا)
  /// - Unifies Teh Marbuta (ة -> ه)
  /// - Unifies Alef Maksura (ى -> ي)
  /// - Strips Arabic harakat/diacritics (U+064B..U+065F)
  static String normalizeArabic(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '');
  }

  /// Formats a numeric price cleanly (omits `.00` for whole numbers, keeps up
  /// to 2 decimals otherwise).
  static String formatPrice(num value) {
    final d = value.toDouble();
    if (d % 1 == 0) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(2);
  }

  /// Filters menu products by active category and strict product-name-only
  /// search (never matching descriptions).
  ///
  /// When a normalized exact product-name match exists, returns ONLY the exact
  /// match(es) so searching for a specific product isolates it cleanly.
  static List<Map<String, dynamic>> filterMenuProducts({
    required List<dynamic> allMenu,
    required String activeCategoryId,
    required String rawQuery,
  }) {
    final items = allMenu
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) {
      if (activeCategoryId == 'all') return true;
      final catId = (item['category'] ?? item['categoryId'])?.toString() ?? '';
      return catId == activeCategoryId;
    }).toList();

    final q = normalizeArabic(rawQuery);
    if (q.isEmpty) return items;

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return items;

    final nameMatches = items.where((item) {
      final normAr = normalizeArabic(item['nameAr']?.toString());
      final normEn = normalizeArabic(item['name']?.toString());
      final arMatches =
          normAr.isNotEmpty && tokens.every((token) => normAr.contains(token));
      final enMatches =
          normEn.isNotEmpty && tokens.every((token) => normEn.contains(token));
      return arMatches || enMatches;
    }).toList();

    final exactMatches = nameMatches.where((item) {
      final normAr = normalizeArabic(item['nameAr']?.toString());
      final normEn = normalizeArabic(item['name']?.toString());
      return (normAr.isNotEmpty && normAr == q) ||
          (normEn.isNotEmpty && normEn == q);
    }).toList();

    return exactMatches.isNotEmpty ? exactMatches : nameMatches;
  }
}

/// Dual-theme palette for the Store Details & Menu screen bound to
/// [Theme.of(context).brightness].
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
    goldText: StoreDetailsTokens.goldTextLightMode,
    borderGold: Color.fromRGBO(200, 141, 38, 0.30),
    sheetTopBorder: Color.fromRGBO(200, 141, 38, 0.40),
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
