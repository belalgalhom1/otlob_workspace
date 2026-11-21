import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../dialog_scaffold.dart';

/// Per-application visual tokens for dialogs and legal surfaces so each app
/// (Customer, Driver, Vendor Admin) retains its authentic visual identity.
@immutable
class AppDialogTheme extends ThemeExtension<AppDialogTheme> {
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? subtleSurfaceColor;
  final Color? sectionCardColor;
  final Color? accentColor;
  final Color? onAccentColor;
  final Color? badgeBackgroundColor;
  final Color? badgeForegroundColor;
  final double? dialogRadius;
  final double? cardRadius;
  final double? buttonRadius;
  final double? buttonMinHeight;
  final bool? showHeaderDivider;

  const AppDialogTheme({
    this.backgroundColor,
    this.borderColor,
    this.subtleSurfaceColor,
    this.sectionCardColor,
    this.accentColor,
    this.onAccentColor,
    this.badgeBackgroundColor,
    this.badgeForegroundColor,
    this.dialogRadius,
    this.cardRadius,
    this.buttonRadius,
    this.buttonMinHeight,
    this.showHeaderDivider,
  });

  @override
  AppDialogTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? subtleSurfaceColor,
    Color? sectionCardColor,
    Color? accentColor,
    Color? onAccentColor,
    Color? badgeBackgroundColor,
    Color? badgeForegroundColor,
    double? dialogRadius,
    double? cardRadius,
    double? buttonRadius,
    double? buttonMinHeight,
    bool? showHeaderDivider,
  }) {
    return AppDialogTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      subtleSurfaceColor: subtleSurfaceColor ?? this.subtleSurfaceColor,
      sectionCardColor: sectionCardColor ?? this.sectionCardColor,
      accentColor: accentColor ?? this.accentColor,
      onAccentColor: onAccentColor ?? this.onAccentColor,
      badgeBackgroundColor: badgeBackgroundColor ?? this.badgeBackgroundColor,
      badgeForegroundColor: badgeForegroundColor ?? this.badgeForegroundColor,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      buttonMinHeight: buttonMinHeight ?? this.buttonMinHeight,
      showHeaderDivider: showHeaderDivider ?? this.showHeaderDivider,
    );
  }

  @override
  AppDialogTheme lerp(covariant AppDialogTheme? other, double t) {
    if (other is! AppDialogTheme) return this;
    return AppDialogTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      subtleSurfaceColor:
          Color.lerp(subtleSurfaceColor, other.subtleSurfaceColor, t),
      sectionCardColor: Color.lerp(sectionCardColor, other.sectionCardColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      onAccentColor: Color.lerp(onAccentColor, other.onAccentColor, t),
      badgeBackgroundColor:
          Color.lerp(badgeBackgroundColor, other.badgeBackgroundColor, t),
      badgeForegroundColor:
          Color.lerp(badgeForegroundColor, other.badgeForegroundColor, t),
      dialogRadius: lerpDouble(dialogRadius, other.dialogRadius, t),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t),
      buttonMinHeight: lerpDouble(buttonMinHeight, other.buttonMinHeight, t),
      showHeaderDivider: t < 0.5 ? showHeaderDivider : other.showHeaderDivider,
    );
  }
}

/// Shared visual tokens and helpers for dialogs across the Otlob suite.
class AppDialogStyles {
  AppDialogStyles._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static AppDialogTheme? themeOf(BuildContext context) =>
      Theme.of(context).extension<AppDialogTheme>();

  static Color backgroundColor(BuildContext context) {
    final ext = themeOf(context);
    if (ext?.backgroundColor != null) return ext!.backgroundColor!;
    final theme = Theme.of(context);
    if (theme.dialogTheme.backgroundColor != null) {
      return theme.dialogTheme.backgroundColor!;
    }
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;
  }

  static Color borderColor(BuildContext context) {
    final ext = themeOf(context);
    if (ext?.borderColor != null) return ext!.borderColor!;
    final theme = Theme.of(context);
    final shape = theme.dialogTheme.shape;
    if (shape is RoundedRectangleBorder &&
        shape.side != BorderSide.none &&
        shape.side.color.a > 0) {
      return shape.side.color;
    }
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  static Color subtleSurfaceColor(BuildContext context) {
    final ext = themeOf(context);
    if (ext?.subtleSurfaceColor != null) return ext!.subtleSurfaceColor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.6)
        : AppColors.surfaceLight;
  }

  static Color sectionCardColor(BuildContext context) {
    final ext = themeOf(context);
    if (ext?.sectionCardColor != null) return ext!.sectionCardColor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.45)
        : AppColors.surfaceLight;
  }

  static Color accentColor(BuildContext context) {
    final ext = themeOf(context);
    if (ext?.accentColor != null) return ext!.accentColor!;
    return Theme.of(context).colorScheme.primary;
  }

  static double dialogRadius(BuildContext context) =>
      themeOf(context)?.dialogRadius ?? 18.0;

  static double cardRadius(BuildContext context) =>
      themeOf(context)?.cardRadius ?? 14.0;

  static double buttonRadius(BuildContext context) =>
      themeOf(context)?.buttonRadius ?? 12.0;

  static double buttonMinHeight(BuildContext context) =>
      themeOf(context)?.buttonMinHeight ?? 48.0;

  static Color dropdownColor(BuildContext context) => backgroundColor(context);

  /// Returns an accessible foreground color for [background] so labels/icons on
  /// bright brand surfaces (such as [AppColors.primary]) never render white-on-yellow.
  static Color foregroundFor(Color background, {BuildContext? context}) {
    if (ThemeData.estimateBrightnessForColor(background) == Brightness.light) {
      if (context != null) {
        final onAccent = themeOf(context)?.onAccentColor;
        if (onAccent != null) return onAccent;
      }
      return AppColors.onPrimary;
    }
    return Colors.white;
  }

  static EdgeInsets dialogInsetPadding(BuildContext context) {
    final mobile = isMobile(context);
    final pad = MediaQuery.paddingOf(context);
    final minH = mobile ? 12.0 : 24.0;
    final minV = mobile ? 14.0 : 24.0;
    return EdgeInsets.fromLTRB(
      math.max(minH, pad.left + 8.0),
      math.max(minV, pad.top + 8.0),
      math.max(minH, pad.right + 8.0),
      math.max(minV, pad.bottom + 8.0),
    );
  }

  static double availableHeight(
    BuildContext context, {
    double maxHeight = 760,
    double minHeight = 260,
  }) {
    final mediaSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final mobile = mediaSize.width < 600;
    final rawAvailable = mediaSize.height -
        mediaPadding.vertical -
        viewInsets.bottom -
        (mobile ? 28.0 : 48.0);
    final safeMax = math.max(160.0, maxHeight);
    final clampedAvailable = rawAvailable.clamp(160.0, safeMax);
    final effectiveMin = math.min(minHeight, clampedAvailable);
    return clampedAvailable.clamp(effectiveMin, safeMax);
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hintText,
    String? labelText,
    String? helperText,
    String? errorText,
    IconData? icon,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
    String? suffixText,
    bool isMultiline = false,
    bool isDense = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = subtleSurfaceColor(context);
    final enabledColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.16)
        : AppColors.borderLight;
    final disabledBorderColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : AppColors.borderLight.withValues(alpha: 0.7);
    final radius = BorderRadius.circular(12);

    return InputDecoration(
      labelText: labelText,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 13.5,
      ),
      hintText: hintText,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        fontSize: 13.5,
      ),
      helperText: helperText,
      helperMaxLines: 2,
      errorText: errorText,
      errorMaxLines: 2,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon ??
          (icon != null
              ? Icon(
                  icon,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      isDense: isDense,
      contentPadding: contentPadding ??
          (isMultiline
              ? const EdgeInsets.all(14)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: enabledColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: enabledColor, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }

  /// Brightness-aware wrapper for Flutter's [showDatePicker] / [showTimePicker].
  static Widget adaptivePickerTheme(BuildContext context, Widget? child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: theme.colorScheme.surface,
            onSurface: theme.colorScheme.onSurface,
          )
        : ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: Colors.white,
            onSurface: theme.colorScheme.onSurface,
          );

    return Theme(
      data: theme.copyWith(
        colorScheme: colorScheme,
        dialogTheme: DialogThemeData(
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor(context)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.primary : AppColors.textPrimaryLight,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// Compact pill badge used next to headers or field labels (e.g., EN, عربي, Markdown).
class AppBadgePill extends StatelessWidget {
  final String text;
  final Color? accentColor;
  final IconData? icon;

  const AppBadgePill({
    super.key,
    required this.text,
    this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor;
    final Color? foregroundColor;
    if (color == null) {
      foregroundColor = theme.colorScheme.onSurfaceVariant;
    } else if (!isDark &&
        (color == AppColors.primary ||
            color == AppColors.warning ||
            ThemeData.estimateBrightnessForColor(color) == Brightness.light)) {
      foregroundColor = const Color(0xFFB45309);
    } else {
      foregroundColor = color;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.12)
            : (isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color != null
              ? color.withValues(alpha: 0.28)
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: foregroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// External bold label placed above dialog inputs with optional required star and tags.
class AppFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? languageTag;
  final String? formatTag;
  final Color? languageTagColor;
  final EdgeInsetsGeometry? padding;

  const AppFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.languageTag,
    this.formatTag,
    this.languageTagColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 7),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (isRequired)
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          if (languageTag != null)
            AppBadgePill(
              text: languageTag!,
              accentColor: languageTagColor ?? AppColors.primary,
            ),
          if (formatTag != null) AppBadgePill(text: formatTag!),
        ],
      ),
    );
  }
}

/// Inline high-contrast error callout displayed inside dialogs.
class AppDialogErrorBanner extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? margin;

  const AppDialogErrorBanner({
    super.key,
    required this.message,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.alertCircle,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle bordered card container for grouped info or form sections inside dialogs.
class AppDialogSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const AppDialogSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppDialogStyles.sectionCardColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? AppDialogStyles.borderColor(context),
        ),
      ),
      child: child,
    );
  }
}

/// Standardized pinned dialog header matching the legal & terms dialog.
class AppDialogHeader extends StatelessWidget {
  final IconData icon;
  final Color? accentColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? badge;
  final Color? iconBackgroundColor;
  final Color? iconForegroundColor;
  final Color? iconBorderColor;
  final double? iconRadius;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool isCloseDisabled;
  final String? closeTooltip;
  final EdgeInsetsGeometry? padding;

  const AppDialogHeader({
    super.key,
    required this.icon,
    this.accentColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleWidget,
    this.badge,
    this.iconBackgroundColor,
    this.iconForegroundColor,
    this.iconBorderColor,
    this.iconRadius,
    this.actions = const [],
    this.onClose,
    this.showCloseButton = true,
    this.isCloseDisabled = false,
    this.closeTooltip,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppDialogStyles.isMobile(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final horizontalPad = isMobile ? 16.0 : 24.0;
    final accent = accentColor ?? AppDialogStyles.accentColor(context);
    final effectiveIconBg =
        iconBackgroundColor ?? accent.withValues(alpha: 0.12);
    final effectiveIconFg = iconForegroundColor ?? accent;
    final effectiveIconBorder =
        iconBorderColor ?? accent.withValues(alpha: 0.25);

    return Padding(
      padding: padding ??
          EdgeInsetsDirectional.fromSTEB(
            horizontalPad,
            16,
            isMobile ? 10 : 16,
            14,
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontScale = MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
          // Stack header actions onto a dedicated row below the title whenever
          // horizontal space is constrained (mobile dialogs or enlarged fonts)
          // so the title can never be squeezed into a narrow vertical strip.
          final placeActionsBelow = actions.isNotEmpty &&
              (isMobile ||
                  constraints.maxWidth < 560 ||
                  fontScale > 1.25);

          final closeBtn = showCloseButton
              ? IconButton(
                  tooltip: closeTooltip ?? (isAr ? 'إغلاق' : 'Close'),
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: isCloseDisabled
                      ? null
                      : (onClose ?? () => Navigator.of(context).maybePop()),
                )
              : null;

          final titleWidget = Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
              color: titleColor ?? theme.colorScheme.onSurface,
            ),
            softWrap: true,
          );

          final topRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(iconRadius ?? 10),
                  border: effectiveIconBorder == Colors.transparent
                      ? null
                      : Border.all(color: effectiveIconBorder),
                ),
                child: Icon(icon, color: effectiveIconFg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          titleWidget,
                          badge!,
                        ],
                      )
                    else
                      titleWidget,
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 3),
                      subtitleWidget!,
                    ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty && !placeActionsBelow) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
                ),
              ],
              if (closeBtn != null) closeBtn,
            ],
          );

          if (!placeActionsBelow) {
            return topRow;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              topRow,
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Standardized responsive pinned footer for dialog actions.
class AppDialogFooter extends StatelessWidget {
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final IconData? confirmIcon;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final bool isLoading;
  final String? loadingLabel;
  final bool isDestructive;
  final Widget? leading;
  final EdgeInsetsGeometry? padding;

  const AppDialogFooter({
    super.key,
    this.cancelLabel,
    this.onCancel,
    this.confirmLabel,
    this.onConfirm,
    this.confirmIcon,
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    this.isLoading = false,
    this.loadingLabel,
    this.isDestructive = false,
    this.leading,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppDialogStyles.isMobile(context);
    final dialogBorder = AppDialogStyles.borderColor(context);
    final horizontalPad = isMobile ? 16.0 : 24.0;
    final btnRadius = AppDialogStyles.buttonRadius(context);
    final btnMinHeight = AppDialogStyles.buttonMinHeight(context);

    final hasCancel = cancelLabel != null && cancelLabel!.isNotEmpty;
    final hasConfirm = confirmLabel != null && confirmLabel!.isNotEmpty;

    final Widget? cancelButton = hasCancel
        ? OutlinedButton(
            onPressed: isLoading
                ? null
                : (onCancel ?? () => Navigator.of(context).pop(false)),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isMobile ? 0 : 100, btnMinHeight),
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: dialogBorder, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(btnRadius),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 18,
                vertical: 10,
              ),
            ),
            child: Text(
              cancelLabel!,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        : null;

    Widget? confirmButton;
    if (hasConfirm) {
      final bg = confirmBackgroundColor ??
          (isDestructive
              ? AppColors.error
              : AppDialogStyles.accentColor(context));
      final fg = confirmForegroundColor ??
          AppDialogStyles.foregroundFor(bg, context: context);
      final displayText =
          (isLoading && loadingLabel != null) ? loadingLabel! : confirmLabel!;

      final buttonStyle = ElevatedButton.styleFrom(
        minimumSize: Size(isMobile ? 0 : 140, btnMinHeight),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: isLoading ? 0.65 : 0.45),
        disabledForegroundColor: fg.withValues(alpha: isLoading ? 0.9 : 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(btnRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 10,
        ),
      );

      final labelWidget = Text(
        displayText,
        textAlign: TextAlign.center,
        softWrap: true,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

      final Widget? leadingIcon = isLoading
          ? SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          : (confirmIcon != null ? Icon(confirmIcon, size: 17) : null);

      confirmButton = ElevatedButton(
        onPressed: isLoading ? null : onConfirm,
        style: buttonStyle,
        child: leadingIcon == null
            ? labelWidget
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leadingIcon,
                  const SizedBox(width: 8),
                  Flexible(child: labelWidget),
                ],
              ),
      );
    }

    Widget actionRow;
    if (isMobile) {
      if (cancelButton != null && confirmButton != null) {
        actionRow = LayoutBuilder(
          builder: (context, constraints) {
            final scaledFont = MediaQuery.textScalerOf(context).scale(14.0);
            final stackVertically =
                constraints.maxWidth < 290 || scaledFont > 17.5;
            if (stackVertically) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  confirmButton!,
                  const SizedBox(height: 10),
                  cancelButton,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: cancelButton),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: confirmButton!),
                ],
              ),
            );
          },
        );
      } else if (confirmButton != null) {
        actionRow = SizedBox(width: double.infinity, child: confirmButton);
      } else if (cancelButton != null) {
        actionRow = SizedBox(width: double.infinity, child: cancelButton);
      } else {
        actionRow = const SizedBox.shrink();
      }
    } else if (leading != null) {
      actionRow = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(child: leading!),
          const SizedBox(width: 12),
          ?cancelButton,
          if (cancelButton != null && confirmButton != null)
            const SizedBox(width: 12),
          ?confirmButton,
        ],
      );
    } else {
      actionRow = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (cancelButton != null) Flexible(child: cancelButton),
          if (cancelButton != null && confirmButton != null)
            const SizedBox(width: 12),
          if (confirmButton != null) Flexible(child: confirmButton),
        ],
      );
    }

    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(horizontalPad, 14, horizontalPad, 16),
      child: (isMobile && leading != null)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leading!,
                const SizedBox(height: 12),
                actionRow,
              ],
            )
          : actionRow,
    );
  }
}

/// Standardized dialog shell with pinned header, scrollable or expanded body,
/// and pinned footer wrapped in [DialogScaffold].
class AppDialog extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? footer;
  final double maxWidth;
  final double maxHeight;
  final bool scrollableBody;
  final bool expandBody;
  final EdgeInsetsGeometry? bodyPadding;
  final bool useDialogScaffold;
  final bool canPop;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool showDividers;

  const AppDialog({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.maxWidth = 600,
    this.maxHeight = 760,
    this.scrollableBody = true,
    this.expandBody = false,
    this.bodyPadding,
    this.useDialogScaffold = true,
    this.canPop = true,
    this.borderRadius,
    this.backgroundColor,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppDialogStyles.isMobile(context);
    final dialogBg = backgroundColor ?? AppDialogStyles.backgroundColor(context);
    final dialogBorder = AppDialogStyles.borderColor(context);
    final insets = AppDialogStyles.dialogInsetPadding(context);
    final horizontalPad = isMobile ? 16.0 : 24.0;
    final availableHeight = AppDialogStyles.availableHeight(
      context,
      maxHeight: maxHeight,
    );

    final effectiveBodyPadding = bodyPadding ??
        (scrollableBody
            ? EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: isMobile ? 16 : 20,
              )
            : EdgeInsets.zero);

    // If caller explicitly requested non-scrollable body (e.g. tab views with internal TabBarView),
    // preserve the bounded height slot.
    if (!scrollableBody) {
      final padded = effectiveBodyPadding == EdgeInsets.zero
          ? body
          : Padding(padding: effectiveBodyPadding, child: body);
      final bodySlot = expandBody ? Expanded(child: padded) : Flexible(child: padded);

      Widget boundedDialog = Dialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        insetPadding: insets,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ??
              BorderRadius.circular(AppDialogStyles.dialogRadius(context)),
          side: BorderSide(color: dialogBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: availableHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                header!,
                if (showDividers)
                  Divider(height: 1, thickness: 1, color: dialogBorder),
              ],
              bodySlot,
              if (footer != null) ...[
                if (showDividers)
                  Divider(height: 1, thickness: 1, color: dialogBorder),
                footer!,
              ],
            ],
          ),
        ),
      );

      if (!canPop) {
        boundedDialog = PopScope(canPop: false, child: boundedDialog);
      }

      return useDialogScaffold ? DialogScaffold(child: boundedDialog) : boundedDialog;
    }

    // Default & Forms: The bordered container is purely a visual layout element.
    // The entire screen is vertically scrollable so users can swipe anywhere
    // (inside the form, over headers, footers, borders, or the outer backdrop).
    final shapeBorder = RoundedRectangleBorder(
      borderRadius: borderRadius ??
          BorderRadius.circular(AppDialogStyles.dialogRadius(context)),
      side: BorderSide(color: dialogBorder),
    );

    final Widget dialog = Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      insetPadding: EdgeInsets.zero,
      shape: shapeBorder,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              if (showDividers)
                Divider(height: 1, thickness: 1, color: dialogBorder),
            ],
            effectiveBodyPadding == EdgeInsets.zero
                ? body
                : Padding(padding: effectiveBodyPadding, child: body),
            if (footer != null) ...[
              if (showDividers)
                Divider(height: 1, thickness: 1, color: dialogBorder),
              footer!,
            ],
          ],
        ),
      ),
    );

    Widget scrollableWrapper = LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = math.max(0.0, constraints.maxHeight - insets.vertical);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: insets,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Absorb taps on dialog card so backdrop tap doesn't dismiss accidentally
                },
                child: dialog,
              ),
            ),
          ),
        );
      },
    );

    Widget fullView = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (canPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: scrollableWrapper,
    );

    if (!canPop) {
      fullView = PopScope(canPop: false, child: fullView);
    }

    return useDialogScaffold ? DialogScaffold(child: fullView) : fullView;
  }
}

/// Standardized confirmation / destructive prompt dialog replacing bare [AlertDialog]s.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? message;
  final Widget? extraContent;
  final String confirmLabel;
  final String? cancelLabel;
  final IconData? icon;
  final Color? accentColor;
  final IconData? confirmIcon;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final bool isDestructive;
  final bool isLoading;
  final bool isConfirmEnabled;
  final String? loadingLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final double maxWidth;
  final bool useDialogScaffold;

  const AppConfirmDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.message,
    this.extraContent,
    required this.confirmLabel,
    this.cancelLabel,
    this.icon,
    this.accentColor,
    this.confirmIcon,
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    this.isDestructive = false,
    this.isLoading = false,
    this.isConfirmEnabled = true,
    this.loadingLabel,
    this.onConfirm,
    this.onCancel,
    this.maxWidth = 460,
    this.useDialogScaffold = true,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? message,
    Widget? extraContent,
    required String confirmLabel,
    String? cancelLabel,
    IconData? icon,
    Color? accentColor,
    IconData? confirmIcon,
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    bool isDestructive = false,
    double maxWidth = 460,
    bool barrierDismissible = true,
    bool useDialogScaffold = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        subtitle: subtitle,
        message: message,
        extraContent: extraContent,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        accentColor: accentColor,
        confirmIcon: confirmIcon,
        confirmBackgroundColor: confirmBackgroundColor,
        confirmForegroundColor: confirmForegroundColor,
        isDestructive: isDestructive,
        maxWidth: maxWidth,
        useDialogScaffold: useDialogScaffold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final effectiveAccent = accentColor ??
        (isDestructive
            ? AppColors.error
            : AppDialogStyles.accentColor(context));
    final effectiveIcon =
        icon ?? (isDestructive ? LucideIcons.alertTriangle : LucideIcons.helpCircle);

    return AppDialog(
      maxWidth: maxWidth,
      useDialogScaffold: useDialogScaffold,
      showDividers: AppDialogStyles.themeOf(context)?.showHeaderDivider ?? true,
      canPop: !isLoading,
      header: AppDialogHeader(
        icon: effectiveIcon,
        accentColor: effectiveAccent,
        title: title,
        titleColor: isDestructive ? AppColors.error : null,
        subtitle: subtitle,
        isCloseDisabled: isLoading,
        onClose: onCancel ?? () => Navigator.of(context).pop(false),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null && message!.isNotEmpty)
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          if (extraContent != null) ...[
            if (message != null && message!.isNotEmpty)
              const SizedBox(height: 14),
            extraContent!,
          ],
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: cancelLabel ?? (isAr ? 'إلغاء' : 'Cancel'),
        onCancel: onCancel ?? () => Navigator.of(context).pop(false),
        confirmLabel: confirmLabel,
        onConfirm: (!isConfirmEnabled || isLoading)
            ? null
            : (onConfirm ?? () => Navigator.of(context).pop(true)),
        confirmIcon: confirmIcon,
        confirmBackgroundColor: confirmBackgroundColor,
        confirmForegroundColor: confirmForegroundColor,
        isDestructive: isDestructive,
        isLoading: isLoading,
        loadingLabel: loadingLabel,
      ),
    );
  }
}
