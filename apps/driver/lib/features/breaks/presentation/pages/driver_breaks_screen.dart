import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/l10n/app_localizations.dart';

class DriverBreaksScreen extends ConsumerStatefulWidget {
  const DriverBreaksScreen({super.key});

  @override
  ConsumerState<DriverBreaksScreen> createState() => _DriverBreaksScreenState();
}

class _DriverBreaksScreenState extends ConsumerState<DriverBreaksScreen> {
  String _selectedReason = 'REST';
  int? _selectedPresetMinutes = 30;
  final TextEditingController _customMinutesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customMinutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _breakReasonLabel(AppLocalizations l10n, String? reason) {
    switch (reason) {
      case 'PRAYER':
        return l10n.breakReasonPrayer;
      case 'MEAL':
        return l10n.breakReasonMeal;
      case 'REST':
        return l10n.breakReasonRest;
      case 'PERSONAL':
        return l10n.breakReasonPersonal;
      case 'OTHER':
        return l10n.breakReasonOther;
      default:
        return reason ?? l10n.breakReasonRest;
    }
  }

  String _breakStatusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'PENDING':
        return l10n.breakStatusPending;
      case 'APPROVED':
        return l10n.breakStatusApproved;
      case 'REJECTED':
        return l10n.breakStatusRejected;
      case 'CANCELLED':
        return l10n.breakStatusCancelled;
      case 'ENDED':
        return l10n.breakStatusEnded;
      default:
        return status ?? '';
    }
  }

  Color _breakStatusColor(String? status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'PENDING':
        return Colors.amber.shade700;
      case 'REJECTED':
        return AppColors.error;
      case 'CANCELLED':
        return Colors.orange.shade700;
      case 'ENDED':
      default:
        return Colors.grey;
    }
  }

  String _formatBreakTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  Future<void> _submitBreakRequest() async {
    if (_isSubmitting) return;

    final customMin = int.tryParse(_customMinutesController.text.trim());
    final minutes = customMin ?? _selectedPresetMinutes;
    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(breakActionsProvider.notifier).start(
            reason: _selectedReason,
            note: note,
            requestedMinutes: minutes,
          );
      if (mounted) {
        _noteController.clear();
        _customMinutesController.clear();
        ref.invalidate(driverProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إرسال طلب الاستراحة بنجاح'
                  : 'Break request submitted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _endBreak() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(breakActionsProvider.notifier).end();
      if (mounted) {
        ref.invalidate(driverProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إنهاء فترة الاستراحة بنجاح. أنت متصل الآن.'
                  : 'Break ended successfully. You are now online.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelBreak() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(breakActionsProvider.notifier).cancel();
      if (mounted) {
        ref.invalidate(driverProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إلغاء طلب الاستراحة'
                  : 'Break request cancelled',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';
    final breaksAsync = ref.watch(breaksOverviewProvider);
    final profileAsync = ref.watch(driverProfileProvider);

    final profile = profileAsync.value;
    final status = profile is Map
        ? (profile['data'] is Map ? profile['data']['status'] : profile['status'])?.toString()
        : null;
    final bool isDriverOnBreak = status == 'ON_BREAK';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الاستراحات' : 'Driver Breaks'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: l10n.retry,
            onPressed: () {
              ref.invalidate(breaksOverviewProvider);
              ref.invalidate(driverProfileProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(breaksOverviewProvider);
          await ref.read(driverProfileProvider.notifier).fetchProfile();
        },
        child: breaksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    ErrorUtils.translate(context, e),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: l10n.retry,
                    onPressed: () => ref.invalidate(breaksOverviewProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (overview) {
            final active = overview.active;
            final pending = overview.pending;
            final bool hasActiveBreak = active != null || isDriverOnBreak;

            return ListView(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0 + bottomInset),
              children: [
                // 1. Current State Hero Card
                if (hasActiveBreak)
                  _buildActiveBreakHero(active, l10n, isAr, isDark)
                else if (pending != null)
                  _buildPendingBreakHero(pending, l10n, isAr, isDark)
                else
                  _buildNewBreakRequestCard(l10n, isAr),

                const SizedBox(height: 28),

                // 2. Breaks History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.history, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.breakHistory,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (overview.recent.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${overview.recent.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. History List
                if (overview.recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: EmptyStateWidget(
                      icon: LucideIcons.coffee,
                      title: l10n.noBreaksYet,
                      subtitle: isAr
                          ? 'لم تسجل أي استراحات بعد. يمكنك طلب استراحة في أي وقت.'
                          : 'No break records found yet. You can request a break whenever needed.',
                    ),
                  )
                else
                  ...overview.recent.map((item) => _buildHistoryItem(item, l10n, isAr)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveBreakHero(
    Map<String, dynamic>? active,
    AppLocalizations l10n,
    bool isAr,
    bool isDark,
  ) {
    final Color borderCol = isDark ? Colors.amber.shade600 : Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.shade900.withValues(alpha: 0.18)
            : Colors.amber.shade700.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.coffee, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activeBreak,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.onBreakSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _breakReasonLabel(l10n, active?['reason']?.toString()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if ((active?['startedAt']?.toString().isNotEmpty ?? false)) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(LucideIcons.clock, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${isAr ? "بدأت:" : "Started:"} ${_formatBreakTime(active?['startedAt']?.toString())}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if ((active?['note']?.toString().isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            Text(
              '${isAr ? "ملاحظة:" : "Note:"} ${active!['note']}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: PrimaryButton(
              text: l10n.endBreak,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _endBreak,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBreakHero(
    Map<String, dynamic> pending,
    AppLocalizations l10n,
    bool isAr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.amber.shade600 : Colors.amber.shade700,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.hourglass,
                  color: isDark ? Colors.amber.shade400 : Colors.amber.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.breakRequestPending,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.breakRequestPendingSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${isAr ? "السبب:" : "Reason:"} ${_breakReasonLabel(l10n, pending['reason']?.toString())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (pending['requestedMinutes'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${pending['requestedMinutes']} ${isAr ? "دقيقة" : "min"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber.shade400 : Colors.amber.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _isSubmitting ? null : _cancelBreak,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.cancelBreakRequest,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBreakRequestCard(AppLocalizations l10n, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.coffee, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.takeBreak,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'اختر سبب الاستراحة والمدة المطلوبة'
                          : 'Select break reason and desired duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Reason Dropdown
          Text(
            l10n.breakReason,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedReason,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const ['PRAYER', 'MEAL', 'REST', 'PERSONAL', 'OTHER']
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(_breakReasonLabel(l10n, r)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedReason = v);
            },
          ),
          const SizedBox(height: 18),

          // Duration Presets
          Text(
            isAr ? 'المدة المطلوبة (بالدقائق):' : 'Desired Duration (minutes):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60].map((mins) {
              final isSelected = _selectedPresetMinutes == mins && _customMinutesController.text.isEmpty;
              return ChoiceChip(
                label: Text('$mins ${isAr ? "دقيقة" : "min"}'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPresetMinutes = mins;
                      _customMinutesController.clear();
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Custom minutes input (optional override)
          TextField(
            controller: _customMinutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.breakMinutes,
              hintText: isAr ? 'أو أدخل مدة أخرى مخصصة (دقائق)' : 'Or enter custom minutes',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) {
              if (v.trim().isNotEmpty) {
                setState(() => _selectedPresetMinutes = null);
              }
            },
          ),
          const SizedBox(height: 16),

          // Optional Note input
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l10n.breakNote,
              hintText: isAr ? 'أي توضيحات إضافية (اختياري)' : 'Any additional details (optional)',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            child: PrimaryButton(
              text: l10n.requestBreak,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitBreakRequest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    Map<String, dynamic> item,
    AppLocalizations l10n,
    bool isAr,
  ) {
    final status = (item['status']?.toString() ?? '').toUpperCase();
    final statusColor = _breakStatusColor(status);
    final statusLabel = _breakStatusLabel(l10n, status);
    final reason = _breakReasonLabel(l10n, item['reason']?.toString());
    final startedAt = item['startedAt']?.toString() ?? item['createdAt']?.toString();
    final requestedMinutes = item['requestedMinutes'];
    final actualMinutes = item['actualMinutes'];
    final note = item['note']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.coffee, size: 16, color: statusColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (startedAt != null && startedAt.isNotEmpty)
                Expanded(
                  child: Text(
                    _formatBreakTime(startedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (actualMinutes != null || requestedMinutes != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${actualMinutes ?? requestedMinutes} ${isAr ? "دقيقة" : "min"}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
