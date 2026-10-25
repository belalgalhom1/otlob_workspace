import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'bloc/settings_provider.dart';
import 'settings_schema.dart';
import 'widgets/settings_field_tile.dart';
import 'widgets/settings_explain_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, dynamic> _editedSettings = {};
  Map<String, dynamic>? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).fetchSettings();
    });
  }

  bool _isSameValue(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is num || b is num) {
      final na = num.tryParse(a.toString());
      final nb = num.tryParse(b.toString());
      if (na != null && nb != null) return na == nb;
    }
    return a.toString() == b.toString();
  }

  void _onSettingChanged(String key, dynamic value) {
    final original = _settings?[key];
    setState(() {
      if (_isSameValue(original, value)) {
        _editedSettings.remove(key);
      } else {
        _editedSettings[key] = value;
      }
    });
  }

  Future<void> _saveSettings() async {
    if (_editedSettings.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(settingsProvider.notifier).updateSettings(_editedSettings);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSavedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
      _editedSettings.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context, String type) async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked == null || !mounted) return;
      final path = picked.path;
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      await ref
          .read(settingsProvider.notifier)
          .uploadSettingImage(type, bytes, picked.name);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  SettingsSection? _findSection(String id) {
    for (final s in platformSettingsSections) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    ref.listen<AsyncValue<Map<String, dynamic>>>(settingsProvider, (
      previous,
      state,
    ) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, state.error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final state = ref.watch(settingsProvider);

    if (state.isLoading && !state.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.hasValue) {
      return const SizedBox();
    }

    final settings = state.value!;
    _settings = settings;
    final displaySettings = Map<String, dynamic>.from(settings)
      ..addAll(_editedSettings);

    return DefaultTabController(
      length: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: AppSpacing.md),
          TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: l10n.tabAssets, icon: const Icon(LucideIcons.image)),
              Tab(text: l10n.tabFinancials, icon: const Icon(LucideIcons.dollarSign)),
              Tab(text: l10n.tabDelivery, icon: const Icon(LucideIcons.truck)),
              Tab(text: l10n.tabLoyalty, icon: const Icon(LucideIcons.award)),
              Tab(text: l10n.tabDrivers, icon: const Icon(LucideIcons.users)),
              Tab(text: l10n.tabAppLegal, icon: const Icon(LucideIcons.smartphone)),
              Tab(text: l10n.tabDataRetention, icon: const Icon(LucideIcons.database)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              children: [
                _buildAssetsTab(context, l10n, displaySettings, isAr),
                _buildSectionsTab([
                  _findSection('money'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
                _buildSectionsTab([
                  _findSection('delivery'),
                  _findSection('vehicles'),
                  _findSection('dispatch'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
                _buildSectionsTab([
                  _findSection('loyalty'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
                _buildSectionsTab([
                  _findSection('drivers'),
                  _findSection('breaks'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
                _buildSectionsTab([
                  _findSection('app'),
                  _findSection('customer'),
                  _findSection('support'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
                _buildSectionsTab([
                  _findSection('retention'),
                ].whereType<SettingsSection>().toList(), displaySettings, isAr, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(LucideIcons.settings, size: 28, color: AppColors.primary),
        AppSpacing.hmd,
        Text(
          l10n.settings,
          style: AppTypography.headlineMedium,
        ),
        const Spacer(),
        if (_editedSettings.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.save, size: 18),
            label: Text(
              _isSaving
                  ? l10n.saving
                  : '${l10n.save} (${_editedSettings.length})',
            ),
          ),
      ],
    );
  }

  Widget _buildSectionsTab(
    List<SettingsSection> sections,
    Map<String, dynamic> displaySettings,
    bool isAr,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const Divider(height: 36),
            _buildSectionBlock(sections[i], displaySettings, isAr, l10n, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionBlock(
    SettingsSection section,
    Map<String, dynamic> displaySettings,
    bool isAr,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final groups = <String?, List<SettingsField>>{};
    for (final field in section.fields) {
      groups.putIfAbsent(field.group(isAr), () => []).add(field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, section, isAr, l10n),
        ...groups.entries.map((entry) {
          final groupTitle = entry.key;
          final fields = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupTitle != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.xs,
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
                        groupTitle,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ...fields.map(
                (f) => SettingsFieldTile(
                  field: f,
                  isAr: isAr,
                  value: displaySettings[f.key],
                  onChanged: (v) => _onSettingChanged(f.key, v),
                  onPickImage: _pickAndUploadImage,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    SettingsSection section,
    bool isAr,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: section.color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: section.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.18),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(section.icon, color: section.color, size: 20),
          ),
          AppSpacing.hmd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title(isAr),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  section.desc(isAr),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
                vertical: AppSpacing.xs,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsTab(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> displaySettings,
    bool isAr,
  ) {
    final section = _findSection('assets');
    final fieldsByKey = <String, SettingsField>{};
    if (section != null) {
      for (final f in section.fields) {
        fieldsByKey[f.key] = f;
      }
    }

    Widget buildTile(String key) {
      final field = fieldsByKey[key];
      if (field == null) return const SizedBox();
      return SettingsFieldTile(
        field: field,
        isAr: isAr,
        value: displaySettings[key],
        onChanged: (v) => _onSettingChanged(key, v),
        onPickImage: _pickAndUploadImage,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section != null) _buildSectionHeader(context, section, isAr, l10n),
          buildTile('homeCoverUrl'),
          const Divider(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildTile('bicycleIconUrl')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: buildTile('motorcycleIconUrl')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildTile('motorTricycleIconUrl')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: buildTile('carIconUrl')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildTile('vanIconUrl')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: buildTile('truckIconUrl')),
            ],
          ),
          const Divider(height: 36),
          buildTile('deliveryBannerIconUrl'),
          if (section != null)
            ...section.fields
                .where((f) => ![
                      'homeCoverUrl',
                      'bicycleIconUrl',
                      'motorcycleIconUrl',
                      'motorTricycleIconUrl',
                      'carIconUrl',
                      'vanIconUrl',
                      'truckIconUrl',
                      'deliveryBannerIconUrl',
                    ].contains(f.key))
                .map((f) => SettingsFieldTile(
                      field: f,
                      isAr: isAr,
                      value: displaySettings[f.key],
                      onChanged: (v) => _onSettingChanged(f.key, v),
                      onPickImage: _pickAndUploadImage,
                    )),
        ],
      ),
    );
  }
}
