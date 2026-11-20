import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';

class AdminDriverTierVisuals {
  final DriverTier tier;
  final Color primary;
  final Color background;
  final Color border;
  final IconData icon;
  final String labelEn;
  final String labelAr;

  const AdminDriverTierVisuals({
    required this.tier,
    required this.primary,
    required this.background,
    required this.border,
    required this.icon,
    required this.labelEn,
    required this.labelAr,
  });

  String label(bool isAr) => isAr ? labelAr : labelEn;

  static DriverTier parseTier(String? raw) {
    final upper = (raw ?? 'BRONZE').trim().toUpperCase();
    if (upper == 'GOLD') return DriverTier.GOLD;
    if (upper == 'SILVER') return DriverTier.SILVER;
    return DriverTier.BRONZE;
  }

  static AdminDriverTierVisuals of(DriverTier tier, {bool isDark = false}) {
    if (tier == DriverTier.GOLD) {
      return AdminDriverTierVisuals(
        tier: tier,
        primary: const Color(0xFFD4920E),
        background: const Color(0xFFD4920E).withValues(alpha: isDark ? 0.18 : 0.12),
        border: const Color(0xFFD4920E).withValues(alpha: 0.45),
        icon: LucideIcons.trophy,
        labelEn: 'Gold',
        labelAr: 'ذهبية',
      );
    }
    if (tier == DriverTier.SILVER) {
      return AdminDriverTierVisuals(
        tier: tier,
        primary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        background: const Color(0xFF64748B).withValues(alpha: isDark ? 0.22 : 0.12),
        border: const Color(0xFF64748B).withValues(alpha: 0.45),
        icon: LucideIcons.award,
        labelEn: 'Silver',
        labelAr: 'فضية',
      );
    }
    return AdminDriverTierVisuals(
      tier: DriverTier.BRONZE,
      primary: const Color(0xFFB45309),
      background: const Color(0xFFB45309).withValues(alpha: isDark ? 0.20 : 0.12),
      border: const Color(0xFFB45309).withValues(alpha: 0.45),
      icon: LucideIcons.shield,
      labelEn: 'Bronze',
      labelAr: 'برونزية',
    );
  }

  static AdminDriverTierVisuals fromString(String? raw, {bool isDark = false}) {
    return of(parseTier(raw), isDark: isDark);
  }
}

class DriverTierBadgePill extends StatelessWidget {
  final DriverTier tier;
  final bool compact;

  const DriverTierBadgePill({
    super.key,
    required this.tier,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = AdminDriverTierVisuals.of(tier, isDark: isDark);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: v.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: compact ? 12 : 14, color: v.primary),
          const SizedBox(width: 5),
          Text(
            v.label(isAr),
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: v.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class OverrideDriverTierDialog extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;
  final DriverTier currentTier;

  const OverrideDriverTierDialog({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.currentTier,
  });

  @override
  ConsumerState<OverrideDriverTierDialog> createState() =>
      _OverrideDriverTierDialogState();
}

class _OverrideDriverTierDialogState
    extends ConsumerState<OverrideDriverTierDialog> {
  late DriverTier _selectedTier;
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.currentTier == DriverTier.GOLD
        ? DriverTier.SILVER
        : DriverTier.GOLD;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final reason = _reasonController.text.trim();
    if (_selectedTier == widget.currentTier) {
      setState(() {
        _errorMessage = isAr
            ? 'الشارة المختارة مطابقة للشارة الحالية للسائق.'
            : 'Selected badge tier is the same as the driver\'s current tier.';
      });
      return;
    }
    if (reason.isEmpty) {
      setState(() {
        _errorMessage = isAr
            ? 'يرجى إدخال سبب لتعديل شارة تصنيف السائق يدوياً.'
            : 'Please provide an audit reason for overriding the driver badge.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(adminDriverRankingRepositoryProvider)
          .overrideDriverTier(
            widget.driverId,
            newTier: _selectedTier,
            reason: reason,
          );
      ref.read(driversProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop(_selectedTier);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.translate(context, e);
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tiers = [DriverTier.GOLD, DriverTier.SILVER, DriverTier.BRONZE];

    return AppDialog(
      maxWidth: 480,
      canPop: !_isSaving,
      header: AppDialogHeader(
        icon: LucideIcons.award,
        title: isAr ? 'تعديل شارة السائق يدوياً' : 'Override Driver Badge',
        subtitle: widget.driverName,
        isCloseDisabled: _isSaving,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
            AppDialogErrorBanner(message: _errorMessage!),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Text(
                isAr ? 'الشارة الحالية:' : 'Current Badge:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              DriverTierBadgePill(tier: widget.currentTier),
            ],
          ),
          const SizedBox(height: 16),
          AppFieldLabel(
            label: isAr ? 'اختر الشارة الجديدة' : 'Select New Badge',
            isRequired: true,
          ),
          Row(
            children: [
              for (int i = 0; i < tiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final t = tiers[i];
                      final v = AdminDriverTierVisuals.of(t, isDark: isDark);
                      final selected = _selectedTier == t;
                      final isCurrent = widget.currentTier == t;
                      return InkWell(
                        onTap: (_isSaving || isCurrent)
                            ? null
                            : () => setState(() => _selectedTier = t),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? v.background
                                : AppDialogStyles.subtleSurfaceColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? v.primary
                                  : AppDialogStyles.borderColor(context),
                              width: selected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Opacity(
                            opacity: isCurrent ? 0.45 : 1.0,
                            child: Column(
                              children: [
                                Icon(v.icon, size: 20, color: v.primary),
                                const SizedBox(height: 6),
                                Text(
                                  v.label(isAr),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: v.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppFieldLabel(
            label: isAr ? 'سبب التعديل اليدوي (إلزامي)' : 'Override Reason (Mandatory)',
            isRequired: true,
          ),
          TextField(
            controller: _reasonController,
            enabled: !_isSaving,
            maxLines: 3,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: isAr
                  ? 'اكتب سبب تغيير الشارة ليظهر في سجل التقييم وإشعار السائق...'
                  : 'Enter audit reason for changing the driver badge...',
              icon: LucideIcons.fileText,
              isMultiline: true,
            ),
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إلغاء' : 'Cancel',
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: isAr ? 'حفظ الشارة' : 'Save Badge',
        confirmIcon: LucideIcons.check,
        isLoading: _isSaving,
        onConfirm: _submit,
      ),
    );
  }
}

class DriverRankHistoryDialog extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;
  final DriverTier initialTier;
  final bool canOverride;

  const DriverRankHistoryDialog({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.initialTier,
    this.canOverride = false,
  });

  @override
  ConsumerState<DriverRankHistoryDialog> createState() =>
      _DriverRankHistoryDialogState();
}

class _DriverRankHistoryDialogState
    extends ConsumerState<DriverRankHistoryDialog> {
  late DriverTier _currentTier;
  bool _isLoading = true;
  String? _error;
  List<DriverRankHistoryEntryDto> _entries = [];
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _currentTier = widget.initialTier;
    _fetchHistory();
  }

  Future<void> _fetchHistory({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .getDriverHistory(widget.driverId, page: page, limit: 15);
      if (mounted) {
        setState(() {
          _entries = res.data.toList();
          _page = res.meta.page.toInt();
          _totalPages = res.meta.totalPages.toInt();
          if (_entries.isNotEmpty && _page == 1) {
            _currentTier = _entries.first.newTier;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorUtils.translate(context, e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOverrideDialog() async {
    final newTier = await showDialog<DriverTier>(
      context: context,
      builder: (_) => OverrideDriverTierDialog(
        driverId: widget.driverId,
        driverName: widget.driverName,
        currentTier: _currentTier,
      ),
    );
    if (newTier != null && mounted) {
      setState(() => _currentTier = newTier);
      await _fetchHistory(page: 1);
    }
  }

  String _reasonLabel(DriverRankChangeReason reason, bool isAr) {
    if (reason == DriverRankChangeReason.ADMIN_OVERRIDE) {
      return isAr ? 'تعديل إداري يدوي' : 'Manual Admin Override';
    }
    if (reason == DriverRankChangeReason.INACTIVE_DRIVER) {
      return isAr ? 'عدم وجود نشاط أسبوعي' : 'Inactive Week';
    }
    return isAr ? 'تقييم أسبوعي' : 'Weekly Evaluation';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppDialog(
      maxWidth: 620,
      maxHeight: 740,
      scrollableBody: false,
      expandBody: true,
      bodyPadding: EdgeInsets.zero,
      header: AppDialogHeader(
        icon: LucideIcons.trophy,
        title: isAr ? 'سجل الشارة والتصنيف الأسبوعي' : 'Weekly Badge & Rank History',
        subtitle: widget.driverName,
        actions: [
          DriverTierBadgePill(tier: _currentTier),
          if (widget.canOverride) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _openOverrideDialog,
              icon: const Icon(LucideIcons.pencil, size: 14),
              label: Text(
                isAr ? 'تعديل الشارة' : 'Override Badge',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
        onClose: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.circleAlert,
                      color: AppColors.error,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _fetchHistory(page: _page),
                      icon: const Icon(LucideIcons.refreshCw, size: 15),
                      label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.history,
                      size: 44,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا توجد سجلات تقييم أو تعديل شارة لهذا السائق بعد'
                          : 'No ranking evaluations or badge overrides recorded yet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final periodKey = entry.periodKey.asStringOrNull;
                      final overrideReason =
                          entry.overrideReason.asStringOrNull;
                      final snap = entry.metricsSnapshot;
                      final dateStr = DateFormat(
                        'd MMM yyyy • h:mm a',
                        isAr ? 'ar' : 'en',
                      ).format(entry.evaluatedAt.toLocal());

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppDialogStyles.subtleSurfaceColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppDialogStyles.borderColor(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    periodKey != null
                                        ? '${_reasonLabel(entry.changeReason, isAr)} ($periodKey)'
                                        : _reasonLabel(entry.changeReason, isAr),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (entry.performancePercentage != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${entry.performancePercentage!.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                DriverTierBadgePill(
                                  tier: entry.previousTier,
                                  compact: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(LucideIcons.arrowRight, size: 14),
                                ),
                                DriverTierBadgePill(
                                  tier: entry.newTier,
                                  compact: true,
                                ),
                                const Spacer(),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            if (overrideReason != null &&
                                overrideReason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'سبب التعديل: $overrideReason'
                                    : 'Reason: $overrideReason',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (snap != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _MiniKpiPill(
                                    label: isAr ? 'القبول' : 'Acceptance',
                                    rate: snap.acceptanceRate?.toDouble(),
                                    detail:
                                        '${snap.acceptedDispatches.toInt()}/${snap.eligibleDispatches.toInt()}',
                                  ),
                                  _MiniKpiPill(
                                    label: isAr ? 'الإتمام' : 'Completion',
                                    rate: snap.completionRate?.toDouble(),
                                    detail:
                                        '${snap.completedOrders.toInt()}/${snap.driverResponsibleOrders.toInt()}',
                                  ),
                                  _MiniKpiPill(
                                    label: isAr ? 'الانضباط' : 'Punctuality',
                                    rate: snap.shiftPunctualityRate?.toDouble(),
                                    detail:
                                        '${snap.onTimeShifts.toInt()}/${snap.eligibleShifts.toInt()}',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 1
                              ? () => _fetchHistory(page: _page - 1)
                              : null,
                          icon: const Icon(LucideIcons.chevronLeft, size: 18),
                        ),
                        Text(
                          '$_page / $_totalPages',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        IconButton(
                          onPressed: _page < _totalPages
                              ? () => _fetchHistory(page: _page + 1)
                              : null,
                          icon: const Icon(LucideIcons.chevronRight, size: 18),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إغلاق' : 'Close',
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _MiniKpiPill extends StatelessWidget {
  final String label;
  final double? rate;
  final String detail;

  const _MiniKpiPill({
    required this.label,
    required this.rate,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final rateStr = rate != null ? '${rate!.toStringAsFixed(1)}%' : 'N/A';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '$label: $rateStr ($detail)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
