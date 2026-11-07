import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'primary_button.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileWarning,
                size: 54,
                color: theme.colorScheme.error,
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
                PrimaryButton(
                  text: retryLabel ?? (isArabic ? 'إعادة المحاولة' : 'Retry'),
                  onPressed: onRetry!,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            // Header card with metadata and language toggle
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Version Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.gitBranch,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'v$version',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (lastUpdated != null && lastUpdated!.isNotEmpty)
                    Expanded(
                      child: Text(
                        lastUpdated!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        softWrap: true,
                      ),
                    )
                  else
                    const Spacer(),
                  if (onLanguageToggle != null) ...[
                    InkWell(
                      onTap: onLanguageToggle,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.languages,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'English' : 'عربي',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (onShare != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(LucideIcons.share2, size: 18),
                      onPressed: onShare,
                      visualDensity: VisualDensity.compact,
                      tooltip: isArabic ? 'مشاركة' : 'Share',
                    ),
                  ],
                ],
              ),
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
            Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
            const SizedBox(height: AppSpacing.md),
          ],

          // Content body
          Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: _buildFormattedContent(context, content),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, String rawText) {
    final theme = Theme.of(context);
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
                  color: AppColors.primaryVariant,
                ),
                AppColors.primary,
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
                AppColors.primary,
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
                AppColors.primary,
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
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border(
                left: isArabic
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.primary, width: 3.5),
                right: isArabic
                    ? const BorderSide(color: AppColors.primary, width: 3.5)
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
                AppColors.primary,
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
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
                      AppColors.primary,
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
                      color: AppColors.primary,
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
                        AppColors.primary,
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
                  AppColors.primary,
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              color: boldColor ?? baseStyle?.color,
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
