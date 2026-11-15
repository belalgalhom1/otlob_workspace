import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/driver_shifts/presentation/providers/driver_shifts_provider.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/core/utils/error_utils.dart';

class GenerateShiftsDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const GenerateShiftsDialog({super.key, required this.onSuccess});

  @override
  ConsumerState<GenerateShiftsDialog> createState() => _GenerateShiftsDialogState();
}

class _GenerateShiftsDialogState extends ConsumerState<GenerateShiftsDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  final _titleController = TextEditingController();
  final _titleArController = TextEditingController();
  final _maxDriversController = TextEditingController(text: '20');
  String? _selectedZoneId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTimeController.text = _startTime.format(context);
        _endTimeController.text = _endTime.format(context);
      }
      ref.read(zoneProvider.notifier).fetchZones();
    });
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _titleController.dispose();
    _titleArController.dispose();
    _maxDriversController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          AppDialogStyles.adaptivePickerTheme(context, child),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final controller = isStart ? _startTimeController : _endTimeController;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return AppDialogStyles.adaptivePickerTheme(
          context,
          MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
        controller.text = selectedTime.format(context);
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() != true) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _errorMessage = l10n.required);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final startHh = _startTime.hour.toString().padLeft(2, '0');
      final startMm = _startTime.minute.toString().padLeft(2, '0');
      final endHh = _endTime.hour.toString().padLeft(2, '0');
      final endMm = _endTime.minute.toString().padLeft(2, '0');

      await ref.read(shiftPoolsProvider.notifier).generateShiftPools(
            GenerateShiftPoolsRequest(
              startDate: _startDate!.toIso8601String().substring(0, 10),
              endDate: _endDate!.toIso8601String().substring(0, 10),
              startTime: '$startHh:$startMm',
              endTime: '$endHh:$endMm',
              maxDrivers: int.parse(_maxDriversController.text.trim()),
              zoneId: _selectedZoneId,
              title: _titleController.text.trim().isEmpty
                  ? null
                  : _titleController.text.trim(),
              titleAr: _titleArController.text.trim().isEmpty
                  ? null
                  : _titleArController.text.trim(),
            ),
          );
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final msg = l10n.shiftGeneratedSuccessfully;
        Navigator.pop(context);
        widget.onSuccess();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorUtils.translate(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final zonesState = ref.watch(zoneProvider);

    return AppDialog(
      maxWidth: 520,
      canPop: !_isLoading,
      header: AppDialogHeader(
        icon: LucideIcons.calendarPlus,
        title: l10n.generateShifts,
        subtitle: isAr
            ? 'تحديد نطاق التواريخ والأوقات والحد الأقصى للسائقين'
            : 'Configure shift date range, schedule window, and capacity',
        isCloseDisabled: _isLoading,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
              AppDialogErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AppFieldLabel(label: l10n.shiftTitle, languageTag: 'EN'),
            TextFormField(
              controller: _titleController,
              enabled: !_isLoading,
              maxLength: 100,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: l10n.shiftTitleHint,
                icon: LucideIcons.tag,
              ).copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.shiftTitleAr, languageTag: 'عربي'),
            TextFormField(
              controller: _titleArController,
              enabled: !_isLoading,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.rtl,
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: l10n.shiftTitleArHint,
                icon: LucideIcons.tag,
              ).copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isAr ? 'نطاق التاريخ' : 'Date Range',
              isRequired: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    l10n.startDate,
                    _startDate,
                    () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    l10n.endDate,
                    _endDate,
                    () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFieldLabel(label: l10n.startTime, isRequired: true),
                      TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        onTap: _isLoading ? null : () => _pickTime(true),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: AppDialogStyles.inputDecoration(
                          context,
                          icon: LucideIcons.sunrise,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? l10n.required : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFieldLabel(label: l10n.endTime, isRequired: true),
                      TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        onTap: _isLoading ? null : () => _pickTime(false),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: AppDialogStyles.inputDecoration(
                          context,
                          icon: LucideIcons.sunset,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? l10n.required : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.maxDrivers, isRequired: true),
            TextFormField(
              controller: _maxDriversController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: '20',
                icon: LucideIcons.users,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.required;
                if (int.tryParse(v) == null || int.parse(v) < 1) {
                  return l10n.required;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: isAr ? 'المنطقة المخصصة' : 'Assigned Zone'),
            DropdownButtonFormField<String>(
              initialValue: _selectedZoneId,
              isExpanded: true,
              dropdownColor: AppDialogStyles.dropdownColor(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: AppDialogStyles.inputDecoration(
                context,
                icon: LucideIcons.map,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    isAr ? 'عام (بدون منطقة)' : 'Global (No Zone)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...?zonesState.value?.zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone['id'].toString(),
                    child: Text(
                      zone['name'] ?? l10n.unknown,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _selectedZoneId = v),
            ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: l10n.generateShifts,
        confirmIcon: LucideIcons.calendarPlus,
        isLoading: _isLoading,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? AppColors.primary.withValues(alpha: 0.65)
                : AppDialogStyles.borderColor(context),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: value != null
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppDialogStyles.subtleSurfaceColor(context),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 16,
              color: value != null
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? '${value.day}/${value.month}/${value.year}'
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      value != null ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
