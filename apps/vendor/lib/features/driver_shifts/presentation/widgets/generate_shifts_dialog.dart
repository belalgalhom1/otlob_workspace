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
  final _maxDriversController = TextEditingController(text: '20');
  String? _selectedZoneId;
  bool _isLoading = false;

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
    _maxDriversController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: MediaQuery(
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

  Future<void> _submit(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx)!;
    if (_formKey.currentState?.validate() != true) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l10n.required), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
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
            ),
          );
      if (ctx.mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(l10n.shiftGeneratedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final zonesState = ref.watch(zoneProvider);
    return DialogScaffold(child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.calendarPlus, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        l10n.generateShifts,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(LucideIcons.x, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date range row
                  Row(
                    children: [
                      Expanded(child: _buildDateField(l10n.startDate, _startDate, () => _pickDate(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDateField(l10n.endDate, _endDate, () => _pickDate(false))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(true),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: l10n.startTime,
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(LucideIcons.sunrise, size: 16),
                            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            isDense: true,
                          ),
                          validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(false),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: l10n.endTime,
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(LucideIcons.sunset, size: 16),
                            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            isDense: true,
                          ),
                          validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Max drivers
                  TextFormField(
                    controller: _maxDriversController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.maxDrivers,
                      prefixIcon: const Icon(LucideIcons.users, size: 16),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      if (int.tryParse(v) == null || int.parse(v) < 1) return l10n.required;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Zone dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedZoneId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Zone',
                      prefixIcon: Icon(LucideIcons.map, size: 16),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Global (No Zone)'),
                      ),
                      ...?zonesState.value?.zones.map((zone) {
                        return DropdownMenuItem(
                          value: zone['id'].toString(),
                          child: Text(zone['name'] ?? 'Unknown'),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedZoneId = v),
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (btnCtx) => FilledButton.icon(
                      onPressed: _isLoading ? null : () => _submit(btnCtx),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.calendarPlus, size: 16),
                      label: Text(_isLoading ? '...' : l10n.generateShifts),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? AppColors.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(10),
          color: value != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 14,
              color: value != null
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? '${value.day}/${value.month}/${value.year}' : label,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
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
