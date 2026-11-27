import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_design_tokens.dart';

/// Theme-aware color tokens and helpers strictly matching the Store Details &
/// Menu specification for both Dark and Light themes.
class StoreDetailPalette {
  final bool isDark;
  final Color bgMain;
  final Color bgCard;
  final Color bgCard2;
  final Color inputBg;
  final Color textPrimary;
  final Color textMuted;
  final Color gold;
  final Color goldHover;
  final Color darkOnGold;
  final Color goldText;
  final Color borderGold;
  final BoxShadow cardShadow;
  final SystemUiOverlayStyle systemOverlayStyle;

  const StoreDetailPalette._({
    required this.isDark,
    required this.bgMain,
    required this.bgCard,
    required this.bgCard2,
    required this.inputBg,
    required this.textPrimary,
    required this.textMuted,
    required this.gold,
    required this.goldHover,
    required this.darkOnGold,
    required this.goldText,
    required this.borderGold,
    required this.cardShadow,
    required this.systemOverlayStyle,
  });

  static const Color bannerFallbackStart = Color(0xFF083B66);
  static const Color bannerFallbackMid = Color(0xFF0E6BA8);
  static const Color bannerFallbackEnd = Color(0xFF38BDF8);

  static const StoreDetailPalette dark = StoreDetailPalette._(
    isDark: true,
    bgMain: Color(0xFF0F0E0C),
    bgCard: Color(0xFF1A1815),
    bgCard2: Color(0xFF24211C),
    inputBg: Color(0xFF1E1C18),
    textPrimary: Color(0xFFFFFFFF),
    textMuted: Color(0xFFE5E2DC),
    gold: Color(0xFFE5A93C),
    goldHover: Color(0xFFF6C667),
    darkOnGold: Color(0xFF14120E),
    goldText: Color(0xFFE5A93C),
    borderGold: Color.fromRGBO(229, 169, 60, 0.28),
    cardShadow: BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.42),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const StoreDetailPalette light = StoreDetailPalette._(
    isDark: false,
    bgMain: Color(0xFFF7F6F2),
    bgCard: Color(0xFFFFFFFF),
    bgCard2: Color(0xFFF1EFEA),
    inputBg: Color(0xFFF3F2EE),
    textPrimary: Color(0xFF11100E),
    textMuted: Color(0xFF33302B),
    gold: Color(0xFFE5A93C),
    goldHover: Color(0xFFF6C667),
    darkOnGold: Color(0xFF14120E),
    goldText: Color(0xFFB87B14),
    borderGold: Color.fromRGBO(200, 141, 38, 0.30),
    cardShadow: BoxShadow(
      color: Color.fromRGBO(24, 22, 19, 0.06),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static StoreDetailPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static StoreDetailPalette fromBrightness(bool isDark) {
    return isDark ? dark : light;
  }

  /// Arabic/UI text style using Cairo.
  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return HomeDesignTokens.text(
      size: size,
      weight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  /// Numeric/price/rating text style using Inter with tabular figures.
  static TextStyle numeric({
    required double size,
    FontWeight weight = FontWeight.w800,
    required Color color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return HomeDesignTokens.numeric(
      size: size,
      weight: weight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}

/// Normalizes Arabic & Latin text for strict product-name-only menu search:
/// - strips Arabic diacritics (tashkeel) and tatweel
/// - normalizes أ / إ / آ / ٱ -> ا, ة -> ه, ى -> ي
/// - trims and lowercases
String normalizeMenuSearchText(String input) {
  final stripped = input
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim()
      .toLowerCase();
  return stripped.replaceAll(RegExp(r'\s+'), ' ');
}
