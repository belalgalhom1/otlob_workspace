import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      fontFamily: AppTypography.fontFamily,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryVariant,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      ),

      textTheme: _buildTextTheme(
        AppColors.textPrimaryLight,
        AppColors.textSecondaryLight,
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),

      elevatedButtonTheme: _buildElevatedButtonTheme(),

      inputDecorationTheme: _buildInputDecorationTheme(
        fillColor: AppColors.surfaceLight,
        borderColor: AppColors.borderLight,
        textColor: AppColors.textPrimaryLight,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      dividerTheme: const DividerThemeData(thickness: 1, space: 1),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textPrimaryLight,
        labelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
      ),

      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimaryLight,
        iconColor: AppColors.textPrimaryLight,
      ),

      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimaryLight,
        ),
        backgroundColor: AppColors.surfaceLight,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
        ),
      ),

      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimaryLight,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textPrimaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      fontFamily: AppTypography.fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryVariant,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),

      textTheme: _buildTextTheme(
        AppColors.textPrimaryDark,
        AppColors.textSecondaryDark,
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),

      elevatedButtonTheme: _buildElevatedButtonTheme(),

      inputDecorationTheme: _buildInputDecorationTheme(
        fillColor: AppColors.fieldDark,
        borderColor: AppColors.borderDark,
        textColor: AppColors.textPrimaryDark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      dividerTheme: const DividerThemeData(thickness: 1, space: 1),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textPrimaryDark,
        labelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
      ),

      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimaryDark,
        iconColor: AppColors.textPrimaryDark,
      ),

      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimaryDark,
        ),
        backgroundColor: AppColors.surfaceDark,
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
        ),
      ),

      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimaryDark,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textPrimaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // Display
      displayLarge: AppTypography.headlineLarge.copyWith(color: primaryColor),
      displayMedium: AppTypography.headlineLarge.copyWith(color: primaryColor),
      displaySmall: AppTypography.headlineMedium.copyWith(color: primaryColor),
      // Headline
      headlineLarge: AppTypography.headlineLarge.copyWith(color: primaryColor),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: primaryColor),
      headlineSmall: AppTypography.headlineMedium.copyWith(color: primaryColor),
      // Title
      titleLarge: AppTypography.titleMedium.copyWith(color: primaryColor),
      titleMedium: AppTypography.titleMedium.copyWith(color: primaryColor),
      titleSmall: AppTypography.titleMedium.copyWith(color: primaryColor),
      // Body — bodyMedium is Flutter's DEFAULT for all Text() widgets
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primaryColor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: primaryColor),
      bodySmall: AppTypography.bodyMedium.copyWith(color: primaryColor),
      // Label
      labelLarge: AppTypography.labelLarge.copyWith(color: primaryColor),
      labelMedium: AppTypography.labelLarge.copyWith(color: primaryColor),
      labelSmall: AppTypography.labelLarge.copyWith(color: primaryColor),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        minimumSize: const Size(88, 54),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        textStyle: AppTypography.labelLarge,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),

      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),

      labelStyle: TextStyle(color: textColor),

      border: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: borderColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
