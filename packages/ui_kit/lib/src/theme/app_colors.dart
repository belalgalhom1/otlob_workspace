import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFBBB2B);
  static const Color primaryVariant = Color(0xFFE0A626);
  static const Color onPrimary = Color(0xFF111827); // Rich charcoal for WCAG AAA contrast on yellow

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Financial Semantics
  static const Color income = Color(0xFF10B981);
  static const Color debt = Color(0xFFEF4444);
  static const Color platformCut = Color(0xFF8B5CF6);
  static const Color supervisorCut = Color(0xFF0284C7);
  static const Color earnings = Color(0xFFF59E0B);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color bottomNavDark = Color(0xFF0F172A);
  static const Color fieldDark = Color(0xFF334155);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  static const Color textHint = Color(0xFF94A3B8);
  static const Color transparent = Colors.transparent;

  // Semantic Aliases
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color surface = surfaceLight;
  static const Color background = backgroundLight;
  static const Color accent = primaryVariant;
  static const Color textPrimary = textPrimaryLight;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
