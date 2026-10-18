import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'settings_schema.dart';
import 'widgets/settings_field_tile.dart';
import 'widgets/settings_explain_sheet.dart';

/// Detail view for a single settings section: a header with a "شرح" (explain)
/// action, the grouped editable fields, and a sticky save bar.
class SettingsSectionScreen extends StatelessWidget {
  final SettingsSection section;
  final Map<String, dynamic> settings;
  final bool isAr;
  final bool isSaving;
  final int unsavedCount;
  final VoidCallback onBack;
  final Future<void> Function() onSave;
  final void Function(String key, dynamic value) onChanged;
  final Future<void> Function(BuildContext context, String type) onPickImage;

  const SettingsSectionScreen({
    super.key,
    required this.section,
    required this.settings,
    required this.isAr,
    required this.isSaving,
    required this.unsavedCount,
    required this.onBack,
    required this.onSave,
    required this.onChanged,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, l10n),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildGroupedCards(context, theme),
            ),
          ),
        ),
        if (unsavedCount > 0) _buildSaveBar(context, l10n, theme),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: l10n.settings,
              style: IconButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              icon: Icon(
                isAr ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                size: 20,
              ),
            ),
            AppSpacing.hsm,
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
                    style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.desc(isAr),
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hsm,
            OutlinedButton.icon(
              onPressed: () => showSettingsExplanation(
                context,
                section: section,
                isAr: isAr,
              ),
              icon: const Icon(LucideIcons.info, size: 16),
              label: Text(l10n.settingsExplain),
              style: OutlinedButton.styleFrom(
                foregroundColor: section.color,
                side: BorderSide(color: section.color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildGroupedCards(BuildContext context, ThemeData theme) {
    final groups = <String?, List<SettingsField>>{};
    for (final field in section.fields) {
      groups.putIfAbsent(field.group(isAr), () => []).add(field);
    }

    final widgets = <Widget>[];
    groups.forEach((group, fields) {
      if (group != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
              left: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: section.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppSpacing.hsm,
                Text(
                  group,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final children = <Widget>[];
      for (var i = 0; i < fields.length; i++) {
        if (i > 0) {
          children.add(
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          );
        }
        final field = fields[i];
        children.add(
          SettingsFieldTile(
            field: field,
            isAr: isAr,
            value: settings[field.key],
            onChanged: (v) => onChanged(field.key, v),
            onPickImage: onPickImage,
          ),
        );
      }

      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    });

    return widgets;
  }

  Widget _buildSaveBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 18, color: AppColors.warning),
          AppSpacing.hsm,
          Expanded(
            child: Text(
              l10n.settingsUnsavedChanges,
              style: AppTypography.bodyMedium,
            ),
          ),
          AppSpacing.hmd,
          ElevatedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.save, size: 18),
            label: Text(isSaving ? l10n.saving : l10n.save),
          ),
        ],
      ),
    );
  }
}
