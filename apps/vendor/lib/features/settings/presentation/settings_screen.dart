import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'bloc/settings_provider.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'settings_schema.dart';
import 'settings_section_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, dynamic> _editedSettings = {};
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _settings;
  SettingsSection? _activeSection;
  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).fetchSettings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  bool _sectionMatches(SettingsSection section) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    bool hit(String? text) => text != null && text.toLowerCase().contains(q);

    if (hit(section.titleAr) ||
        hit(section.titleEn) ||
        hit(section.descAr) ||
        hit(section.descEn)) {
      return true;
    }
    for (final field in section.fields) {
      if (hit(field.labelAr) ||
          hit(field.labelEn) ||
          hit(field.helpAr) ||
          hit(field.helpEn) ||
          hit(field.key)) {
        return true;
      }
    }
    return false;
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

    if (_activeSection != null) {
      return SettingsSectionScreen(
        section: _activeSection!,
        settings: displaySettings,
        isAr: isAr,
        isSaving: _isSaving,
        unsavedCount: _editedSettings.length,
        onBack: () => setState(() => _activeSection = null),
        onSave: _saveSettings,
        onChanged: _onSettingChanged,
        onPickImage: _pickAndUploadImage,
      );
    }

    return _buildHome(context, l10n, isAr);
  }

  Widget _buildHome(
    BuildContext context,
    AppLocalizations l10n,
    bool isAr,
  ) {
    final theme = Theme.of(context);
    final sections =
        platformSettingsSections.where(_sectionMatches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.settings, size: 28, color: AppColors.primary),
            AppSpacing.hmd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settings,
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsChooseSection,
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (_editedSettings.isNotEmpty) ...[
              AppSpacing.hmd,
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
                label: Text(_isSaving ? l10n.saving : l10n.save),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.settingsSearchHint,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: sections.isEmpty
              ? _buildNoResults(l10n)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 150,
                      ),
                      itemCount: sections.length,
                      itemBuilder: (context, index) =>
                          _buildSectionCard(context, sections[index], isAr),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoResults(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.search,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          AppSpacing.vmd,
          Text(
            l10n.settingsNoResults,
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    SettingsSection section,
    bool isAr,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        borderRadius: AppRadius.mdRadius,
        onTap: () => setState(() => _activeSection = section),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Icon(section.icon, color: section.color, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    isAr ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                section.title(isAr),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                section.desc(isAr),
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
