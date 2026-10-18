import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import '../settings_schema.dart';

/// Opens the plain-language "شرح" sheet for a settings section.
///
/// Describes what the section controls, plus the meaning of every field in it,
/// so a non-technical operator understands the impact before editing.
Future<void> showSettingsExplanation(
  BuildContext context, {
  required SettingsSection section,
  required bool isAr,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SettingsExplanationSheet(section: section, isAr: isAr),
  );
}

class _SettingsExplanationSheet extends StatelessWidget {
  final SettingsSection section;
  final bool isAr;

  const _SettingsExplanationSheet({
    required this.section,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Padding(
      padding: EdgeInsets.only(top: media.padding.top + 32),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Icon(section.icon, color: section.color, size: 22),
                  ),
                  AppSpacing.hmd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title(isAr),
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        AppSpacing.vxs,
                        Text(
                          section.explain(isAr),
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < section.fields.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: borderColor),
                      _buildFieldRow(context, section.fields[i]),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(BuildContext context, SettingsField field) {
    final theme = Theme.of(context);
    final group = field.group(isAr);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsetsDirectional.only(start: 4, end: 4),
                decoration: BoxDecoration(
                  color: section.color,
                  shape: BoxShape.circle,
                ),
              ),
              AppSpacing.hsm,
              Expanded(
                child: Text(
                  field.label(isAr),
                  style: AppTypography.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 26),
            child: Text(
              group == null ? field.help(isAr) : '$group: ${field.help(isAr)}',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
