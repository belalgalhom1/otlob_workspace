import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'dialogs/app_dialog.dart';

class LegalDocumentView extends StatelessWidget {
  final String title;
  final String version;
  final String? lastUpdated;
  final String content;
  final bool isArabic;
  final bool showHeader;
  final VoidCallback? onLanguageToggle;
  final VoidCallback? onShare;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final EdgeInsetsGeometry? padding;

  const LegalDocumentView({
    super.key,
    required this.title,
    required this.version,
    this.lastUpdated,
    required this.content,
    this.isArabic = false,
    this.showHeader = true,
    this.onLanguageToggle,
    this.onShare,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.retryLabel,
    this.padding,
  });

  Color _readableAccent(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return accent;
    final badgeFg = AppDialogStyles.themeOf(context)?.badgeForegroundColor;
    if (badgeFg != null) return badgeFg;
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.light
        ? const Color(0xFFB45309)
        : accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppDialogStyles.accentColor(context);
    final readableAccent = _readableAccent(context, accent);
    final dialogBg = AppDialogStyles.backgroundColor(context);
    final border = AppDialogStyles.borderColor(context);
    final btnRadius = AppDialogStyles.buttonRadius(context);
    final btnMinHeight = AppDialogStyles.buttonMinHeight(context);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              isArabic ? 'جاري تحميل الوثيقة...' : 'Loading document...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      final btnFg = AppDialogStyles.foregroundFor(accent, context: context);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDialogStyles.cardRadius(context)),
                ),
                child: Icon(
                  LucideIcons.fileWarning,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(LucideIcons.refreshCw, size: 17),
                  label: Text(
                    retryLabel ?? (isArabic ? 'إعادة المحاولة' : 'Retry'),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: btnFg,
                    minimumSize: Size(140, btnMinHeight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(btnRadius),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (showHeader) ...[
            // Header card with metadata and language toggle
            Builder(
              builder: (context) {
                final versionChip = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppDialogStyles.themeOf(context)
                            ?.badgeBackgroundColor ??
                        accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.gitBranch,
                        size: 13,
                        color: readableAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'v$version',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: readableAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );

                final langButton = onLanguageToggle == null
                    ? null
                    : InkWell(
                        onTap: onLanguageToggle,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.languages,
                                size: 14,
                                color: readableAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'English' : 'عربي',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: readableAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                final shareButton = onShare == null
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.share2, size: 18),
                        onPressed: onShare,
                        visualDensity: VisualDensity.compact,
                        tooltip: isArabic ? 'مشاركة' : 'Share',
                      );

                final hasUpdated =
                    lastUpdated != null && lastUpdated!.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: dialogBg,
                    borderRadius: BorderRadius.circular(
                      AppDialogStyles.cardRadius(context),
                    ),
                    border: Border.all(color: border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 330;
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                versionChip,
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ?langButton,
                                    ?shareButton,
                                  ],
                                ),
                              ],
                            ),
                            if (hasUpdated) ...[
                              const SizedBox(height: 8),
                              Text(
                                lastUpdated!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                versionChip,
                                if (hasUpdated)
                                  Text(
                                    lastUpdated!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    softWrap: true,
                                  ),
                              ],
                            ),
                          ),
                          if (langButton != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            langButton,
                          ],
                          if (shareButton != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            shareButton,
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Main Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
              softWrap: true,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: border),
            const SizedBox(height: AppSpacing.md),
          ],

          // Content body
          Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: _buildFormattedContent(
              context,
              content,
              accent: accent,
              readableAccent: readableAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(
    BuildContext context,
    String rawText, {
    required Color accent,
    required Color readableAccent,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boldSpanColor =
        isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    final lines = rawText.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
            child: Text.rich(
              _buildInlineSpans(
                line.substring(4),
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: readableAccent,
                ),
                boldSpanColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xs),
            child: Text.rich(
              _buildInlineSpans(
                line.substring(3),
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                boldSpanColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
            child: Text.rich(
              _buildInlineSpans(
                line.substring(2),
                theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                boldSpanColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        // Blockquote / Important callout
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(
                left: isArabic
                    ? BorderSide.none
                    : BorderSide(color: accent, width: 3.5),
                right: isArabic
                    ? BorderSide(color: accent, width: 3.5)
                    : BorderSide.none,
              ),
            ),
            child: Text.rich(
              _buildInlineSpans(
                line.substring(2),
                theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                ),
                boldSpanColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: readableAccent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text.rich(
                    _buildInlineSpans(
                      line.substring(2),
                      theme.textTheme.bodyMedium?.copyWith(
                        height: 1.65,
                        color: theme.colorScheme.onSurface,
                      ),
                      boldSpanColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Check for numbered list like "1. ", "2. ", etc.
        final numMatch = RegExp(r'^(\d+[\.\)])\s+(.*)$').firstMatch(line);
        if (numMatch != null) {
          final prefix = numMatch.group(1)!;
          final rest = numMatch.group(2)!;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefix,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: readableAccent,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text.rich(
                      _buildInlineSpans(
                        rest,
                        theme.textTheme.bodyMedium?.copyWith(
                          height: 1.65,
                          color: theme.colorScheme.onSurface,
                        ),
                        boldSpanColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Text.rich(
                _buildInlineSpans(
                  line,
                  theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    color: theme.colorScheme.onSurface,
                  ),
                  boldSpanColor,
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  static TextSpan _buildInlineSpans(
    String text,
    TextStyle? baseStyle,
    Color? boldColor,
  ) {
    if (!text.contains('**')) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      if (i % 2 == 1) {
        // Bold section inside ** ... **
        spans.add(
          TextSpan(
            text: part,
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.bold,
              color: boldColor ?? baseStyle.color,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: baseStyle,
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}
