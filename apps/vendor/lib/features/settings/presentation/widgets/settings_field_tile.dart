import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import '../settings_schema.dart';

/// Renders a single platform setting with its label and inline help text.
class SettingsFieldTile extends StatelessWidget {
  final SettingsField field;
  final bool isAr;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final Future<void> Function(BuildContext context, String type) onPickImage;

  const SettingsFieldTile({
    super.key,
    required this.field,
    required this.isAr,
    required this.value,
    required this.onChanged,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.kind) {
      case SettingsFieldKind.toggle:
        return _buildToggle(context);
      case SettingsFieldKind.image:
        return _buildImage(context);
      case SettingsFieldKind.text:
      case SettingsFieldKind.number:
        return _SettingsTextInput(
          key: ValueKey(field.key),
          field: field,
          isAr: isAr,
          value: value,
          onChanged: onChanged,
        );
    }
  }

  Widget _buildToggle(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label(isAr), style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  field.help(isAr),
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hmd,
          Switch(
            value: value == true,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);
    final url = value?.toString();
    final hasImage = url != null && url.isNotEmpty;
    final type = field.imageType!;
    final width = field.wide ? double.infinity : 140.0;
    final height = field.wide ? 180.0 : 140.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label(isAr), style: AppTypography.titleMedium),
          const SizedBox(height: 2),
          Text(
            field.help(isAr),
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              Container(
                width: field.wide ? double.infinity : width,
                height: height,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.mdRadius,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: ImageUtils.formatImageUrl(url),
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => Icon(
                            LucideIcons.imageOff,
                            size: 40,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        )
                      : Icon(
                          LucideIcons.imagePlus,
                          size: 40,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                ),
              ),
              PositionedDirectional(
                end: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: FloatingActionButton.small(
                  heroTag: 'setting-image-$type',
                  onPressed: () => onPickImage(context, type),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(LucideIcons.camera, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTextInput extends StatefulWidget {
  final SettingsField field;
  final bool isAr;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _SettingsTextInput({
    super.key,
    required this.field,
    required this.isAr,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SettingsTextInput> createState() => _SettingsTextInputState();
}

class _SettingsTextInputState extends State<_SettingsTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue());
  }

  String _displayValue() {
    final raw = widget.value;
    if (raw == null) return '';
    if (widget.field.key.endsWith('Date')) {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) {
        final d = parsed.toLocal();
        return '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
      }
    }
    return raw.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = widget.field;
    final isNumber = field.kind == SettingsFieldKind.number;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label(widget.isAr), style: AppTypography.titleMedium),
          const SizedBox(height: 2),
          Text(
            field.help(widget.isAr),
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              isDense: true,
              suffixText: field.suffix,
            ),
          ),
        ],
      ),
    );
  }
}
