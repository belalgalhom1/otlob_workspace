import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared brand constants and typography helpers for the Customer Home Screen.
class HomeDesignTokens {
  HomeDesignTokens._();

  // Brand Gold Palette (shared across Dark & Light modes)
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFF6C667);
  static const Color goldDark = Color(0xFFC88D26);
  static const Color goldTextLightMode = Color(0xFFB87B14);
  static const Color darkOnGold = Color(0xFF14120E);
  static const Color logoBg = Color(0xFF12110E);

  // Semantic Accents
  static const Color offerBadgeRed = Color(0xFFDC2626);
  static const Color ratingAmber = Color(0xFFFBBF24);

  // Hero Banner Fallbacks & Scrim (dark in both modes for crisp white headline readability)
  static const Color bannerFallbackStart = Color(0xFF091322);
  static const Color bannerFallbackMid = Color(0xFF132A4A);
  static const Color bannerFallbackEnd = Color(0xFF1D3E69);
  static const Color bannerOverlayStart = Color.fromRGBO(7, 14, 26, 0.95);
  static const Color bannerOverlayMid = Color.fromRGBO(9, 19, 34, 0.75);

  // Typography Helpers
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
    required Color color,
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

/// Theme-aware color palette for the Customer Home Screen supporting both
/// Dark Mode and Light (White) Mode seamlessly via [Theme.of(context)].
class HomePalette {
  final bool isDark;
  final Color bgMain;
  final Color headerBg;
  final Color cardSurface1;
  final Color cardSurface2;
  final Color inputSurface;
  final Color navBg;

  final Color textPrimary;
  final Color textMuted;
  final Color goldText;

  final Color borderSubtle;
  final Color borderHeader;
  final Color borderNav;
  final Color borderHighlight;
  final Color borderBanner;
  final Color borderCourier;
  final Color borderCourierImage;
  final Color borderHotDeal;

  final Color cardShadowColor;
  final List<Color> hotDealGradientColors;

  final Color discountBgRed;
  final Color discountBorderRed;
  final Color discountTextRed;

  final Gradient courierGradient;
  final Color courierTitleColor;
  final Color courierSubtitleColor;
  final Color courierBadgeBg;
  final Color courierBadgeText;
  final List<Color> courierImageFallbackColors;
  final Color courierShadowColor;

  final SystemUiOverlayStyle systemOverlayStyle;

  const HomePalette._({
    required this.isDark,
    required this.bgMain,
    required this.headerBg,
    required this.cardSurface1,
    required this.cardSurface2,
    required this.inputSurface,
    required this.navBg,
    required this.textPrimary,
    required this.textMuted,
    required this.goldText,
    required this.borderSubtle,
    required this.borderHeader,
    required this.borderNav,
    required this.borderHighlight,
    required this.borderBanner,
    required this.borderCourier,
    required this.borderCourierImage,
    required this.borderHotDeal,
    required this.cardShadowColor,
    required this.hotDealGradientColors,
    required this.discountBgRed,
    required this.discountBorderRed,
    required this.discountTextRed,
    required this.courierGradient,
    required this.courierTitleColor,
    required this.courierSubtitleColor,
    required this.courierBadgeBg,
    required this.courierBadgeText,
    required this.courierImageFallbackColors,
    required this.courierShadowColor,
    required this.systemOverlayStyle,
  });

  static const HomePalette dark = HomePalette._(
    isDark: true,
    bgMain: Color(0xFF0F0E0C),
    headerBg: Color.fromRGBO(15, 14, 12, 0.95),
    cardSurface1: Color(0xFF1A1815),
    cardSurface2: Color(0xFF24211C),
    inputSurface: Color(0xFF1E1C18),
    navBg: Color.fromRGBO(22, 20, 17, 0.96),
    textPrimary: Color(0xFFF7F4EE),
    textMuted: Color(0xFF9E9689),
    goldText: HomeDesignTokens.gold,
    borderSubtle: Color.fromRGBO(229, 169, 60, 0.28),
    borderHeader: Color.fromRGBO(229, 169, 60, 0.16),
    borderNav: Color.fromRGBO(229, 169, 60, 0.20),
    borderHighlight: Color.fromRGBO(229, 169, 60, 0.55),
    borderBanner: Color.fromRGBO(229, 169, 60, 0.45),
    borderCourier: Color.fromRGBO(229, 169, 60, 0.50),
    borderCourierImage: Color.fromRGBO(229, 169, 60, 0.30),
    borderHotDeal: Color.fromRGBO(229, 169, 60, 0.40),
    cardShadowColor: Color.fromRGBO(0, 0, 0, 0.40),
    hotDealGradientColors: [Color(0xFF1E1B16), Color(0xFF161411)],
    discountBgRed: Color.fromRGBO(239, 68, 68, 0.20),
    discountBorderRed: Color.fromRGBO(239, 68, 68, 0.40),
    discountTextRed: Color(0xFFF87171),
    courierGradient: RadialGradient(
      center: Alignment(-0.6, -0.6),
      radius: 1.35,
      colors: [
        Color.fromRGBO(229, 169, 60, 0.20),
        Color.fromRGBO(16, 22, 34, 0.96),
        Color(0xFF0D111A),
      ],
      stops: [0.0, 0.55, 1.0],
    ),
    courierTitleColor: HomeDesignTokens.gold,
    courierSubtitleColor: Color.fromRGBO(255, 255, 255, 0.95),
    courierBadgeBg: Color.fromRGBO(229, 169, 60, 0.20),
    courierBadgeText: HomeDesignTokens.goldLight,
    courierImageFallbackColors: [Color(0xFF132945), Color(0xFF0A1424)],
    courierShadowColor: Color.fromRGBO(229, 169, 60, 0.14),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const HomePalette light = HomePalette._(
    isDark: false,
    bgMain: Color(0xFFF8F7F4),
    headerBg: Color.fromRGBO(255, 255, 255, 0.96),
    cardSurface1: Color(0xFFFFFFFF),
    cardSurface2: Color(0xFFF1EFEA),
    inputSurface: Color(0xFFFFFFFF),
    navBg: Color.fromRGBO(255, 255, 255, 0.97),
    textPrimary: Color(0xFF181613),
    textMuted: Color(0xFF6E6A63),
    goldText: HomeDesignTokens.goldTextLightMode,
    borderSubtle: Color.fromRGBO(200, 141, 38, 0.35),
    borderHeader: Color.fromRGBO(200, 141, 38, 0.22),
    borderNav: Color.fromRGBO(200, 141, 38, 0.26),
    borderHighlight: HomeDesignTokens.gold,
    borderBanner: Color.fromRGBO(200, 141, 38, 0.45),
    borderCourier: Color.fromRGBO(200, 141, 38, 0.45),
    borderCourierImage: Color.fromRGBO(200, 141, 38, 0.38),
    borderHotDeal: Color.fromRGBO(200, 141, 38, 0.35),
    cardShadowColor: Color.fromRGBO(24, 22, 19, 0.08),
    hotDealGradientColors: [Color(0xFFFFFFFF), Color(0xFFF8F5EE)],
    discountBgRed: Color.fromRGBO(220, 38, 38, 0.10),
    discountBorderRed: Color.fromRGBO(220, 38, 38, 0.30),
    discountTextRed: Color(0xFFDC2626),
    courierGradient: LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [
        Color(0xFFFFFDF8),
        Color(0xFFFFF5DC),
        Color(0xFFFCE7B5),
      ],
      stops: [0.0, 0.52, 1.0],
    ),
    courierTitleColor: HomeDesignTokens.goldTextLightMode,
    courierSubtitleColor: Color(0xFF3B362E),
    courierBadgeBg: Color.fromRGBO(229, 169, 60, 0.22),
    courierBadgeText: HomeDesignTokens.goldTextLightMode,
    courierImageFallbackColors: [Color(0xFFFFF5DC), Color(0xFFF6DC9E)],
    courierShadowColor: Color.fromRGBO(200, 141, 38, 0.16),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static HomePalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static HomePalette fromBrightness(bool isDark) {
    return isDark ? dark : light;
  }
}
