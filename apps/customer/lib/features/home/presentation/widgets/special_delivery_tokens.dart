import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared brand colors, typography helpers, and tactile press feedback widget
/// for the Special Delivery (التوصيل الخاص) screen and its Map Location Picker.
class SpecialDeliveryTokens {
  SpecialDeliveryTokens._();

  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFF6C667);
  static const Color goldDark = Color(0xFFC88D26);
  static const Color darkOnGold = Color(0xFF14120E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

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
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: numericFont,
      fontFamilyFallback: numericFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Dual-theme palette (Dark Mode default & Crisp Light Mode) bound to
/// [Theme.of(context).brightness].
class SpecialDeliveryPalette {
  final bool isDark;
  final Color bgMain;
  final Color headerBg;
  final Color headerBorder;
  final BoxShadow headerShadow;

  final Color surface;
  final Color surfaceBorder;
  final BoxShadow surfaceShadow;
  final Color surface2;
  final Color inputBg;

  final Color textPrimary;
  final Color textMuted;
  final Color goldText;

  final Color infoBg;
  final Color infoBorder;

  final Color disabledBg;
  final Color disabledText;

  final Color selectedTint;
  final Color pinHaloColor;
  final SystemUiOverlayStyle systemOverlayStyle;

  const SpecialDeliveryPalette._({
    required this.isDark,
    required this.bgMain,
    required this.headerBg,
    required this.headerBorder,
    required this.headerShadow,
    required this.surface,
    required this.surfaceBorder,
    required this.surfaceShadow,
    required this.surface2,
    required this.inputBg,
    required this.textPrimary,
    required this.textMuted,
    required this.goldText,
    required this.infoBg,
    required this.infoBorder,
    required this.disabledBg,
    required this.disabledText,
    required this.selectedTint,
    required this.pinHaloColor,
    required this.systemOverlayStyle,
  });

  static const SpecialDeliveryPalette dark = SpecialDeliveryPalette._(
    isDark: true,
    bgMain: Color(0xFF0F0E0C),
    headerBg: Color(0xFF151310),
    headerBorder: Color.fromRGBO(229, 169, 60, 0.20),
    headerShadow: BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.40),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    surface: Color(0xFF1A1815),
    surfaceBorder: Color.fromRGBO(229, 169, 60, 0.28),
    surfaceShadow: BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.42),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
    surface2: Color(0xFF24211C),
    inputBg: Color(0xFF1E1C18),
    textPrimary: Color(0xFFF7F4EE),
    textMuted: Color(0xFF9E9689),
    goldText: SpecialDeliveryTokens.gold,
    infoBg: Color.fromRGBO(229, 169, 60, 0.10),
    infoBorder: Color.fromRGBO(229, 169, 60, 0.30),
    disabledBg: Color.fromRGBO(158, 150, 137, 0.20),
    disabledText: Color(0xFF8D8579),
    selectedTint: Color.fromRGBO(229, 169, 60, 0.15),
    pinHaloColor: Color.fromRGBO(229, 169, 60, 0.35),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static const SpecialDeliveryPalette light = SpecialDeliveryPalette._(
    isDark: false,
    bgMain: Color(0xFFF7F6F2),
    headerBg: Color(0xFFFFFFFF),
    headerBorder: Color.fromRGBO(0, 0, 0, 0.07),
    headerShadow: BoxShadow(
      color: Color.fromRGBO(15, 14, 12, 0.05),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color.fromRGBO(200, 141, 38, 0.30),
    surfaceShadow: BoxShadow(
      color: Color.fromRGBO(24, 22, 19, 0.06),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    surface2: Color(0xFFF1EFEA),
    inputBg: Color(0xFFF3F2EE),
    textPrimary: Color(0xFF181613),
    textMuted: Color(0xFF6E6A63),
    goldText: SpecialDeliveryTokens.goldDark,
    infoBg: Color(0xFFFFF9EC),
    infoBorder: Color.fromRGBO(200, 141, 38, 0.42),
    disabledBg: Color(0xFFE5E2DA),
    disabledText: Color(0xFF8A847A),
    selectedTint: Color.fromRGBO(229, 169, 60, 0.15),
    pinHaloColor: Color.fromRGBO(229, 169, 60, 0.30),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static SpecialDeliveryPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// Subtle tactile scale feedback wrapper for cards & action buttons.
class TactileScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Key? tapKey;

  const TactileScaleTap({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.tapKey,
  });

  @override
  State<TactileScaleTap> createState() => _TactileScaleTapState();
}

class _TactileScaleTapState extends State<TactileScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      key: widget.tapKey,
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
