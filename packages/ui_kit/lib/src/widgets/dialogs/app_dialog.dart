import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../dialog_scaffold.dart';

/// Shared visual tokens and helpers for dialogs across the Otlob suite.
class AppDialogStyles {
  AppDialogStyles._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static Color backgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;
  }

  static Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  static Color subtleSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.6)
        : AppColors.surfaceLight;
  }

  static Color sectionCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.45)
        : AppColors.surfaceLight;
  }

  static Color dropdownColor(BuildContext context) => backgroundColor(context);

  /// Returns an accessible foreground color for [background] so labels/icons on
  /// bright brand surfaces (such as [AppColors.primary]) never render white-on-yellow.
  static Color foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.light
        ? AppColors.onPrimary
        : Colors.white;
  }

  static EdgeInsets dialogInsetPadding(BuildContext context) {
    final mobile = isMobile(context);
    return EdgeInsets.symmetric(
      horizontal: mobile ? 12 : 24,
      vertical: mobile ? 14 : 24,
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
    final accent = accentColor ?? AppColors.primary;

    return Padding(
      padding: padding ??
          EdgeInsetsDirectional.fromSTEB(
            horizontalPad,
            16,
            isMobile ? 10 : 16,
            14,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                    color: titleColor ?? theme.colorScheme.onSurface,
                  ),
                  softWrap: true,
                ),
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
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
          if (showCloseButton)
            IconButton(
              tooltip: closeTooltip ?? (isAr ? 'إغلاق' : 'Close'),
              icon: const Icon(LucideIcons.x, size: 20),
              onPressed: isCloseDisabled
                  ? null
                  : (onClose ?? () => Navigator.of(context).maybePop()),
            ),
        ],
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

    final hasCancel = cancelLabel != null && cancelLabel!.isNotEmpty;
    final hasConfirm = confirmLabel != null && confirmLabel!.isNotEmpty;

    final Widget? cancelButton = hasCancel
        ? OutlinedButton(
            onPressed: isLoading
                ? null
                : (onCancel ?? () => Navigator.of(context).pop(false)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 46),
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: dialogBorder, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18),
            ),
            child: Text(
              cancelLabel!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        : null;

    Widget? confirmButton;
    if (hasConfirm) {
      final bg = confirmBackgroundColor ??
          (isDestructive ? AppColors.error : AppColors.primary);
      final fg = confirmForegroundColor ?? AppDialogStyles.foregroundFor(bg);
      final displayText =
          (isLoading && loadingLabel != null) ? loadingLabel! : confirmLabel!;

      final buttonStyle = ElevatedButton.styleFrom(
        minimumSize: Size(isMobile ? 0 : 140, 46),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: isLoading ? 0.65 : 0.45),
        disabledForegroundColor: fg.withValues(alpha: isLoading ? 0.9 : 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 8,
        ),
      );

      final labelWidget = Text(
        displayText,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
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
        actionRow = Row(
          children: [
            Expanded(flex: 2, child: cancelButton),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: confirmButton),
          ],
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
          if (cancelButton != null) cancelButton,
          if (cancelButton != null && confirmButton != null)
            const SizedBox(width: 12),
          if (confirmButton != null) confirmButton,
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

    final Widget bodySlot;
    if (scrollableBody) {
      bodySlot = Flexible(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: effectiveBodyPadding,
          child: body,
        ),
      );
    } else {
      final padded = effectiveBodyPadding == EdgeInsets.zero
          ? body
          : Padding(padding: effectiveBodyPadding, child: body);
      bodySlot = expandBody ? Expanded(child: padded) : Flexible(child: padded);
    }

    Widget dialog = Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: AppDialogStyles.dialogInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(18),
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
      dialog = PopScope(canPop: false, child: dialog);
    }

    return useDialogScaffold ? DialogScaffold(child: dialog) : dialog;
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
    final effectiveAccent =
        accentColor ?? (isDestructive ? AppColors.error : AppColors.primary);
    final effectiveIcon =
        icon ?? (isDestructive ? LucideIcons.alertTriangle : LucideIcons.helpCircle);

    return AppDialog(
      maxWidth: maxWidth,
      useDialogScaffold: useDialogScaffold,
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
