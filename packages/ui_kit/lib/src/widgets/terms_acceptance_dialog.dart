import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'primary_button.dart';
import 'legal_document_view.dart';

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
  });

  @override
  State<TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // Force explicit choice
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: size.height * 0.88,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.shieldCheck,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'v${widget.version}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onLanguageToggle != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        icon: const Icon(LucideIcons.languages, size: 20),
                        tooltip: widget.isArabic ? 'English' : 'عربي',
                        onPressed: widget.onLanguageToggle,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Terms Scrollable Content Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: LegalDocumentView(
                        title: widget.title,
                        version: widget.version,
                        content: widget.content,
                        isArabic: widget.isArabic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Agreement Checkbox
                InkWell(
                  onTap: () {
                    setState(() => _accepted = !_accepted);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _accepted,
                          activeColor: AppColors.primary,
                          onChanged: (v) {
                            setState(() => _accepted = v ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            widget.acceptCheckboxLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Actions: Accept / Decline
                Row(
                  children: [
                    if (widget.declineButtonLabel != null &&
                        widget.onDecline != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.isLoading ? null : widget.onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(widget.declineButtonLabel!),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: widget.acceptButtonLabel,
                        isLoading: widget.isLoading,
                        onPressed: _accepted ? widget.onAccept : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
