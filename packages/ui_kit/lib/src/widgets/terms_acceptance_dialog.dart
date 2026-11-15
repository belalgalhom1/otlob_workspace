import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'dialogs/app_dialog.dart';
import 'legal_document_view.dart';

/// Per-app visual style presets for [TermsAcceptanceDialog] and legal gates.
enum TermsDialogVariant {
  /// Automatically inherits styling from [Theme.of(context)] & [AppDialogTheme].
  adaptive,

  /// Neutral consumer card/CTA identity matching the Customer app.
  customer,

  /// High-contrast operational Slate & Amber identity matching the Driver app.
  driver,

  /// Structured management-console [AppDialog] identity matching Vendor Admin.
  vendor,
}

class TermsAcceptanceDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String version;
  final String content;
  final bool isArabic;
  final VoidCallback? onLanguageToggle;
  final String acceptCheckboxLabel;
  final String acceptButtonLabel;
  final String? declineButtonLabel;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onViewPrivacyPolicy;
  final String? privacyPolicyLabel;
  final TermsDialogVariant variant;

  const TermsAcceptanceDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.version,
    required this.content,
    this.isArabic = false,
    this.onLanguageToggle,
    required this.acceptCheckboxLabel,
    required this.acceptButtonLabel,
    this.declineButtonLabel,
    this.isLoading = false,
    required this.onAccept,
    this.onDecline,
    this.onViewPrivacyPolicy,
    this.privacyPolicyLabel,
    this.variant = TermsDialogVariant.adaptive,
  });

  @override
  State<TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  bool _accepted = false;

  _ResolvedTermsVisuals _resolveVisuals(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ext = AppDialogStyles.themeOf(context);
    final accent = ext?.accentColor ?? theme.colorScheme.primary;
    final onAccent = ext?.onAccentColor ??
        AppDialogStyles.foregroundFor(accent, context: context);
    final badgeFg = ext?.badgeForegroundColor ??
        (isDark ? accent : const Color(0xFFB45309));
    final badgeBg = ext?.badgeBackgroundColor ??
        accent.withValues(alpha: isDark ? 0.16 : 0.12);

    switch (widget.variant) {
      case TermsDialogVariant.customer:
        return _ResolvedTermsVisuals(
          dialogBg: ext?.backgroundColor ??
              (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderColor: ext?.borderColor ??
              (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE)),
          readerBg: ext?.subtleSurfaceColor ??
              (isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA)),
          checkboxBg: ext?.sectionCardColor ??
              (isDark ? const Color(0xFF242426) : const Color(0xFFF8F9FA)),
          accent: accent,
          onAccent: Colors.black,
          badgeBg: badgeBg,
          badgeFg: isDark ? accent : const Color(0xFFB45309),
          dialogRadius: ext?.dialogRadius ?? 22.0,
          cardRadius: ext?.cardRadius ?? 16.0,
          buttonRadius: ext?.buttonRadius ?? 16.0,
          iconRadius: 14.0,
          buttonMinHeight: ext?.buttonMinHeight ?? 50.0,
          elevation: 0,
          maxWidth: 620,
          showDividers: false,
          inlineEndDesktopFooter: false,
          headerIconBg: accent.withValues(alpha: isDark ? 0.18 : 0.14),
          headerIconFg: isDark ? accent : const Color(0xFFB45309),
          headerIconBorder: Colors.transparent,
          versionPillRadius: 999,
        );
      case TermsDialogVariant.driver:
        return _ResolvedTermsVisuals(
          dialogBg: isDark ? AppColors.surfaceDark : Colors.white,
          borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
          readerBg: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.65)
              : AppColors.surfaceLight,
          checkboxBg: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
          accent: AppColors.primary,
          onAccent: AppColors.onPrimary,
          badgeBg: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12),
          badgeFg: isDark ? AppColors.primary : const Color(0xFFB45309),
          dialogRadius: 16.0,
          cardRadius: 14.0,
          buttonRadius: 14.0,
          iconRadius: 12.0,
          buttonMinHeight: 50.0,
          elevation: 0,
          maxWidth: 640,
          showDividers: true,
          inlineEndDesktopFooter: false,
          headerIconBg: AppColors.primary.withValues(alpha: 0.12),
          headerIconFg: isDark ? AppColors.primary : const Color(0xFFB45309),
          headerIconBorder: AppColors.primary.withValues(alpha: 0.30),
          versionPillRadius: 8,
        );
      case TermsDialogVariant.vendor:
        return _ResolvedTermsVisuals(
          dialogBg: isDark ? AppColors.surfaceDark : Colors.white,
          borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
          readerBg: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.55)
              : AppColors.surfaceLight,
          checkboxBg: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.45)
              : AppColors.surfaceLight,
          accent: AppColors.primary,
          onAccent: AppColors.onPrimary,
          badgeBg: AppColors.primary.withValues(alpha: 0.12),
          badgeFg: isDark ? AppColors.primary : const Color(0xFFB45309),
          dialogRadius: 18.0,
          cardRadius: 14.0,
          buttonRadius: 12.0,
          iconRadius: 10.0,
          buttonMinHeight: isMobile ? 48.0 : 46.0,
          elevation: 0,
          maxWidth: 680,
          showDividers: true,
          inlineEndDesktopFooter: true,
          headerIconBg: AppColors.primary.withValues(alpha: 0.12),
          headerIconFg: AppColors.primary,
          headerIconBorder: AppColors.primary.withValues(alpha: 0.25),
          versionPillRadius: 8,
        );
      case TermsDialogVariant.adaptive:
        return _ResolvedTermsVisuals(
          dialogBg: AppDialogStyles.backgroundColor(context),
          borderColor: AppDialogStyles.borderColor(context),
          readerBg: AppDialogStyles.subtleSurfaceColor(context),
          checkboxBg: AppDialogStyles.sectionCardColor(context),
          accent: accent,
          onAccent: onAccent,
          badgeBg: badgeBg,
          badgeFg: badgeFg,
          dialogRadius: AppDialogStyles.dialogRadius(context),
          cardRadius: AppDialogStyles.cardRadius(context),
          buttonRadius: AppDialogStyles.buttonRadius(context),
          iconRadius: 12.0,
          buttonMinHeight: AppDialogStyles.buttonMinHeight(context),
          elevation: 0,
          maxWidth: 660,
          showDividers: ext?.showHeaderDivider ?? true,
          inlineEndDesktopFooter: false,
          headerIconBg: accent.withValues(alpha: 0.12),
          headerIconFg: badgeFg,
          headerIconBorder: accent.withValues(alpha: 0.25),
          versionPillRadius: AppRadius.sm,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppDialogStyles.isMobile(context);
    final v = _resolveVisuals(context, isMobile);
    final maxDialogHeight = AppDialogStyles.availableHeight(
      context,
      maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      minHeight: 240,
    );
    final horizontalPad = isMobile ? AppSpacing.md : AppSpacing.lg;

    return PopScope(
      canPop: false, // Force explicit choice
      child: Dialog(
        insetPadding: AppDialogStyles.dialogInsetPadding(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(v.dialogRadius),
          side: BorderSide(color: v.borderColor),
        ),
        backgroundColor: v.dialogBg,
        surfaceTintColor: Colors.transparent,
        elevation: v.elevation,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: v.maxWidth,
            maxHeight: maxDialogHeight,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaledFont = MediaQuery.textScalerOf(context).scale(14.0);
              final useCompactHeader = isMobile &&
                  (constraints.maxWidth < 330 || scaledFont > 16.0);
              final useScrollableShell =
                  constraints.maxHeight < 490 || scaledFont > 17.5;
              final useUltraCompactWholeScroll = constraints.maxHeight < 300;

              final header = _buildHeader(
                context,
                theme,
                v,
                isMobile: isMobile,
                horizontalPad: horizontalPad,
                compactLayout: useCompactHeader,
              );
              final reader = _buildReader(context, v, isMobile: isMobile);
              final consentBlock = _buildConsentBlock(context, theme, v);
              final actions = _buildActions(
                context,
                theme,
                v,
                isMobile: isMobile,
                horizontalPad: horizontalPad,
                scaledFont: scaledFont,
              );

              if (useUltraCompactWholeScroll) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (v.showDividers)
                        Divider(height: 1, thickness: 1, color: v.borderColor),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad,
                          v.showDividers ? 14 : 6,
                          horizontalPad,
                          12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 150, child: reader),
                            const SizedBox(height: 12),
                            consentBlock,
                          ],
                        ),
                      ),
                      if (v.showDividers)
                        Divider(height: 1, thickness: 1, color: v.borderColor),
                      actions,
                    ],
                  ),
                );
              }

              if (useScrollableShell) {
                final boundedReaderHeight = math.max(
                  140.0,
                  math.min(220.0, constraints.maxHeight * 0.34),
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            if (v.showDividers)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: v.borderColor,
                              ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                v.showDividers ? 14 : 6,
                                horizontalPad,
                                12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: boundedReaderHeight,
                                    child: reader,
                                  ),
                                  const SizedBox(height: 12),
                                  consentBlock,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (v.showDividers)
                      Divider(height: 1, thickness: 1, color: v.borderColor),
                    actions,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (v.showDividers)
                    Divider(height: 1, thickness: 1, color: v.borderColor),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        v.showDividers ? 14 : 4,
                        horizontalPad,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: reader),
                          const SizedBox(height: 12),
                          consentBlock,
                        ],
                      ),
                    ),
                  ),
                  if (v.showDividers)
                    Divider(height: 1, thickness: 1, color: v.borderColor),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    _ResolvedTermsVisuals v, {
    required bool isMobile,
    required double horizontalPad,
    required bool compactLayout,
  }) {
    final docDirection =
        widget.isArabic ? TextDirection.rtl : TextDirection.ltr;

    final iconBox = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: v.headerIconBg,
        borderRadius: BorderRadius.circular(v.iconRadius),
        border: v.headerIconBorder == Colors.transparent
            ? null
            : Border.all(color: v.headerIconBorder),
      ),
      child: Center(
        child: Icon(
          LucideIcons.shieldCheck,
          color: v.headerIconFg,
          size: 21,
        ),
      ),
    );

    final versionBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: v.badgeBg,
        borderRadius: BorderRadius.circular(v.versionPillRadius),
        border: Border.all(color: v.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.variant == TermsDialogVariant.vendor) ...[
            Icon(LucideIcons.gitBranch, size: 11, color: v.badgeFg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              'v${widget.version}',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: v.badgeFg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    final languageToggle = widget.onLanguageToggle != null
        ? InkWell(
            onTap: widget.onLanguageToggle,
            borderRadius: BorderRadius.circular(
              widget.variant == TermsDialogVariant.customer ? 999 : 10,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: v.checkboxBg,
                  borderRadius: BorderRadius.circular(
                    widget.variant == TermsDialogVariant.customer ? 999 : 10,
                  ),
                  border: Border.all(color: v.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.languages, size: 15, color: v.badgeFg),
                    const SizedBox(width: 5),
                    Text(
                      widget.isArabic ? 'EN' : 'عربي',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    final subtitleWidget = widget.subtitle.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              softWrap: true,
            ),
          )
        : null;

    if (compactLayout) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          isMobile ? 16 : 20,
          horizontalPad,
          v.showDividers ? 14 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                iconBox,
                const SizedBox(width: 10),
                Flexible(child: versionBadge),
                const Spacer(),
                ?languageToggle,
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              textDirection: docDirection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
                color: theme.colorScheme.onSurface,
              ),
              softWrap: true,
            ),
            ?subtitleWidget,
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        isMobile ? 16 : 20,
        horizontalPad,
        v.showDividers ? 14 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      textDirection: docDirection,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      softWrap: true,
                    ),
                    versionBadge,
                  ],
                ),
                ?subtitleWidget,
              ],
            ),
          ),
          if (languageToggle != null) ...[
            const SizedBox(width: 8),
            languageToggle,
          ],
        ],
      ),
    );
  }

  Widget _buildReader(
    BuildContext context,
    _ResolvedTermsVisuals v, {
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: v.readerBg,
        borderRadius: BorderRadius.circular(v.cardRadius),
        border: Border.all(color: v.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(v.cardRadius),
        child: Scrollbar(
          child: LegalDocumentView(
            title: widget.title,
            version: widget.version,
            content: widget.content,
            isArabic: widget.isArabic,
            showHeader: false,
            padding: EdgeInsets.all(isMobile ? 14 : 18),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentBlock(
    BuildContext context,
    ThemeData theme,
    _ResolvedTermsVisuals v,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _accepted
                ? v.accent.withValues(alpha: isDark ? 0.14 : 0.08)
                : v.checkboxBg,
            borderRadius: BorderRadius.circular(v.cardRadius),
            border: Border.all(
              color: _accepted
                  ? v.accent.withValues(alpha: 0.55)
                  : v.borderColor,
              width: _accepted ? 1.3 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: widget.isLoading
                ? null
                : () => setState(() => _accepted = !_accepted),
            borderRadius: BorderRadius.circular(v.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    checked: _accepted,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _accepted ? v.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _accepted
                              ? v.accent
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                          width: 1.8,
                        ),
                      ),
                      child: _accepted
                          ? Icon(
                              LucideIcons.check,
                              size: 14,
                              color: v.onAccent,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.acceptCheckboxLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.35,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.onViewPrivacyPolicy != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.onViewPrivacyPolicy,
            borderRadius: BorderRadius.circular(v.cardRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: v.badgeBg.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(v.cardRadius),
                border: Border.all(color: v.accent.withValues(alpha: 0.24)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.fileText, size: 16, color: v.badgeFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.privacyPolicyLabel ??
                          (widget.isArabic
                              ? 'عرض سياسة الخصوصية وحماية البيانات'
                              : 'View Privacy Policy & Data Protection'),
                      softWrap: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: v.badgeFg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.externalLink,
                    size: 14,
                    color: v.badgeFg,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    ThemeData theme,
    _ResolvedTermsVisuals v, {
    required bool isMobile,
    required double horizontalPad,
    required double scaledFont,
  }) {
    final hasDecline =
        widget.declineButtonLabel != null && widget.onDecline != null;

    final Widget? declineButton = hasDecline
        ? OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onDecline,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isMobile ? 0 : 120, v.buttonMinHeight),
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: v.borderColor, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(v.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              widget.declineButtonLabel!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          )
        : null;

    final Widget acceptButton = ElevatedButton(
      onPressed: widget.isLoading || !_accepted ? null : widget.onAccept,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(isMobile ? 0 : 160, v.buttonMinHeight),
        backgroundColor: v.accent,
        foregroundColor: v.onAccent,
        disabledBackgroundColor:
            v.accent.withValues(alpha: widget.isLoading ? 0.65 : 0.35),
        disabledForegroundColor:
            v.onAccent.withValues(alpha: widget.isLoading ? 0.9 : 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(v.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: widget.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(v.onAccent),
              ),
            )
          : Text(
              widget.acceptButtonLabel,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: v.onAccent,
              ),
            ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        v.showDividers ? 14 : 6,
        horizontalPad,
        isMobile ? 16 : 20,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackVertically = hasDecline &&
              (constraints.maxWidth < 300 || scaledFont > 17.5);
          if (stackVertically) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                acceptButton,
                const SizedBox(height: 10),
                declineButton!,
              ],
            );
          }

          if (!isMobile && v.inlineEndDesktopFooter) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (declineButton != null) ...[
                  Flexible(child: declineButton),
                  const SizedBox(width: 12),
                ],
                Flexible(child: acceptButton),
              ],
            );
          }

          if (declineButton == null) {
            return SizedBox(width: double.infinity, child: acceptButton);
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: declineButton),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: acceptButton),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResolvedTermsVisuals {
  final Color dialogBg;
  final Color borderColor;
  final Color readerBg;
  final Color checkboxBg;
  final Color accent;
  final Color onAccent;
  final Color badgeBg;
  final Color badgeFg;
  final double dialogRadius;
  final double cardRadius;
  final double buttonRadius;
  final double iconRadius;
  final double buttonMinHeight;
  final double elevation;
  final double maxWidth;
  final bool showDividers;
  final bool inlineEndDesktopFooter;
  final Color headerIconBg;
  final Color headerIconFg;
  final Color headerIconBorder;
  final double versionPillRadius;

  const _ResolvedTermsVisuals({
    required this.dialogBg,
    required this.borderColor,
    required this.readerBg,
    required this.checkboxBg,
    required this.accent,
    required this.onAccent,
    required this.badgeBg,
    required this.badgeFg,
    required this.dialogRadius,
    required this.cardRadius,
    required this.buttonRadius,
    required this.iconRadius,
    required this.buttonMinHeight,
    required this.elevation,
    required this.maxWidth,
    required this.showDividers,
    required this.inlineEndDesktopFooter,
    required this.headerIconBg,
    required this.headerIconFg,
    required this.headerIconBorder,
    required this.versionPillRadius,
  });
}
