import 'package:flutter/material.dart';

/// Scoped Dark & Gold design tokens for the Customer Home Screen redesign.
/// Kept local to the Home feature so other screens remain unaffected.
class HomeDesignTokens {
  HomeDesignTokens._();

  // Core Surfaces
  static const Color bgMain = Color(0xFF0F0E0C);
  static const Color logoBg = Color(0xFF12110E);
  static const Color cardSurface1 = Color(0xFF1A1815);
  static const Color cardSurface2 = Color(0xFF24211C);
  static const Color inputBg = Color(0xFF1E1C18);
  static const Color navBg = Color.fromRGBO(22, 20, 17, 0.96);

  // Brand Gold Palette
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFF6C667);
  static const Color goldDark = Color(0xFFC88D26);
  static const Color darkOnGold = Color(0xFF14120E);
  static const Color selectedCategoryIconBg = Color(0xFF181511);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF7F4EE);
  static const Color textMuted = Color(0xFF9E9689);

  // Semantic Accents
  static const Color offerBadgeRed = Color(0xFFDC2626);
  static const Color discountTextRed = Color(0xFFF87171);
  static const Color discountBgRed = Color.fromRGBO(239, 68, 68, 0.20);
  static const Color discountBorderRed = Color.fromRGBO(239, 68, 68, 0.40);
  static const Color ratingAmber = Color(0xFFFBBF24);

  // Gold Borders
  static const Color borderHeader = Color.fromRGBO(229, 169, 60, 0.16);
  static const Color borderNav = Color.fromRGBO(229, 169, 60, 0.20);
  static const Color borderSubtle = Color.fromRGBO(229, 169, 60, 0.28);
  static const Color borderCourierImage = Color.fromRGBO(229, 169, 60, 0.30);
  static const Color borderHotDeal = Color.fromRGBO(229, 169, 60, 0.40);
  static const Color borderBanner = Color.fromRGBO(229, 169, 60, 0.45);
  static const Color borderCourier = Color.fromRGBO(229, 169, 60, 0.50);
  static const Color borderHighlight = Color.fromRGBO(229, 169, 60, 0.55);

  // Banner & Card Gradients
  static const Color bannerFallbackStart = Color(0xFF091322);
  static const Color bannerFallbackMid = Color(0xFF132A4A);
  static const Color bannerFallbackEnd = Color(0xFF1D3E69);

  static const Color bannerOverlayStart = Color.fromRGBO(7, 14, 26, 0.95);
  static const Color bannerOverlayMid = Color.fromRGBO(9, 19, 34, 0.75);

  static const Color courierBgDark = Color(0xFF0D111A);
  static const Color courierBgMid = Color.fromRGBO(16, 22, 34, 0.96);
  static const Color courierGoldGlow = Color.fromRGBO(229, 169, 60, 0.20);

  static const Color hotDealGradientStart = Color(0xFF1E1B16);
  static const Color hotDealGradientEnd = Color(0xFF161411);

  // Typography Helpers
  static const String primaryFont = 'Cairo';
  static const List<String> primaryFallback = ['Cairo', 'Tajawal', 'Roboto', 'Arial'];

  static const String numericFont = 'Inter';
  static const List<String> numericFallback = ['Inter', 'Roboto', 'Arial'];

  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = textPrimary,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    List<Shadow>? shadows,
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
      shadows: shadows,
    );
  }

  static TextStyle numeric({
    required double size,
    FontWeight weight = FontWeight.w800,
    Color color = gold,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
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
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
