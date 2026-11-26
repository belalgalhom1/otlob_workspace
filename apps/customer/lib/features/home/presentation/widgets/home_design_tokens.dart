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
  static const Color logoBlack = Color(0xFF11100E);
  static const Color logoWhite = Color(0xFFFFFFFF);

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
}

/// Theme-aware color palette for the Customer Home Screen supporting both
/// Dark Mode and airy, crisp Light (White) Mode via [Theme.of(context)].
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

  // Mandatory Logo Inversion Tokens (Header Circular Logo + "All / الكل" Tile)
  final Color logoBg;
  final Color logoPrimaryText;
  final Color logoArabicText;
  final List<BoxShadow> logoShadows;

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
  final List<Color> storeFallbackCoverColors;

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
    required this.logoBg,
    required this.logoPrimaryText,
    required this.logoArabicText,
    required this.logoShadows,
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
    required this.storeFallbackCoverColors,
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
    textPrimary: Color(0xFFFFFFFF),
    textMuted: Color(0xFFE5E2DC),
    goldText: HomeDesignTokens.gold,
    // Dark Mode Logo Inversion: Pure WHITE bg, dark/black TLOB, warm gold أطلب, soft white glow
    logoBg: HomeDesignTokens.logoWhite,
    logoPrimaryText: HomeDesignTokens.logoBlack,
    logoArabicText: HomeDesignTokens.goldTextLightMode,
    logoShadows: [
      BoxShadow(
        color: Color.fromRGBO(255, 255, 255, 0.14),
        blurRadius: 14,
        offset: Offset(0, 4),
      ),
    ],
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
    storeFallbackCoverColors: [Color(0xFF24211C), Color(0xFF1A1815)],
    discountBgRed: Color(0xFF991B1B),
    discountBorderRed: Color(0xFFF87171),
    discountTextRed: Color(0xFFFFFFFF),
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
    courierTitleColor: Color(0xFFFFFFFF),
    courierSubtitleColor: Color(0xFFF3F4F6),
    courierBadgeBg: Color.fromRGBO(229, 169, 60, 0.22),
    courierBadgeText: Color(0xFFFFFFFF),
    courierImageFallbackColors: [Color(0xFF132945), Color(0xFF0A1424)],
    courierShadowColor: Color.fromRGBO(229, 169, 60, 0.14),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const HomePalette light = HomePalette._(
    isDark: false,
    // Airy warm off-white scaffold + crisp #FFFFFF elevated cards + soft ambient shadow
    bgMain: Color(0xFFF7F6F2),
    headerBg: Color.fromRGBO(255, 255, 255, 0.97),
    cardSurface1: Color(0xFFFFFFFF),
    cardSurface2: Color(0xFFFAF9F6),
    inputSurface: Color(0xFFFFFFFF),
    navBg: Color.fromRGBO(255, 255, 255, 0.98),
    textPrimary: Color(0xFF11100E),
    textMuted: Color(0xFF33302B),
    goldText: HomeDesignTokens.goldTextLightMode,
    // Light Mode Logo Inversion: Pure BLACK bg, white TLOB, light gold أطلب, subtle dark shadow
    logoBg: HomeDesignTokens.logoBlack,
    logoPrimaryText: HomeDesignTokens.logoWhite,
    logoArabicText: HomeDesignTokens.goldLight,
    logoShadows: [
      BoxShadow(
        color: Color.fromRGBO(17, 16, 14, 0.22),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    borderSubtle: Color.fromRGBO(229, 169, 60, 0.28),
    borderHeader: Color.fromRGBO(15, 14, 12, 0.06),
    borderNav: Color.fromRGBO(15, 14, 12, 0.07),
    borderHighlight: HomeDesignTokens.gold,
    borderBanner: Color.fromRGBO(229, 169, 60, 0.42),
    borderCourier: Color.fromRGBO(229, 169, 60, 0.42),
    borderCourierImage: Color.fromRGBO(229, 169, 60, 0.34),
    borderHotDeal: Color.fromRGBO(229, 169, 60, 0.32),
    cardShadowColor: Color.fromRGBO(15, 14, 12, 0.06),
    hotDealGradientColors: [Color(0xFFFFFFFF), Color(0xFFFEFEFC)],
    storeFallbackCoverColors: [Color(0xFFFCFBF7), Color(0xFFF6F1E4)],
    discountBgRed: Color(0xFFFEE2E2),
    discountBorderRed: Color(0xFFFCA5A5),
    discountTextRed: Color(0xFF991B1B),
    courierGradient: LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFFBF0),
        Color(0xFFFFF2D1),
      ],
      stops: [0.0, 0.55, 1.0],
    ),
    courierTitleColor: Color(0xFF11100E),
    courierSubtitleColor: Color(0xFF1F1D19),
    courierBadgeBg: Color.fromRGBO(229, 169, 60, 0.16),
    courierBadgeText: Color(0xFF11100E),
    courierImageFallbackColors: [Color(0xFFFFFDF7), Color(0xFFFFF5DC)],
    courierShadowColor: Color.fromRGBO(15, 14, 12, 0.06),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static HomePalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static HomePalette fromBrightness(bool isDark) {
    return isDark ? dark : light;
  }
}
