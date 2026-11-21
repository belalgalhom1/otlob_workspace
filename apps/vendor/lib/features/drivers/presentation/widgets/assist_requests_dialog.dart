import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';
import '../../data/driver_models.dart';
import '../../data/driver_providers.dart';

class AssistRequestsDialog extends ConsumerStatefulWidget {
  const AssistRequestsDialog({super.key});

  @override
  ConsumerState<AssistRequestsDialog> createState() => _AssistRequestsDialogState();
}

class _AssistRequestsDialogState extends ConsumerState<AssistRequestsDialog> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final list = await repo.listPendingAssistRequests();
      if (mounted) {
        setState(() {
          _requests = list is List ? list : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _offerToNearest(String requestId) async {
    setState(() => _processingId = requestId);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.offerAssistToNearest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assist offer broadcasted to nearest drivers successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadRequests();
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
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _autoAssign(String requestId) async {
    setState(() => _processingId = requestId);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.autoAssignAssistDriver(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assistant driver auto-assigned successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadRequests();
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
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    setState(() => _processingId = requestId);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.decideAssistRequest(
        requestId,
        status: 'APPROVED',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assist request approved. You can now dispatch an assistant driver.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadRequests();
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
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isAr ? 'رفض طلب المساعدة' : 'Reject Assist Request',
      message: isAr
          ? 'هل أنت متأكد من رفض طلب مساعدة الكابتن هذا؟'
          : 'Are you sure you want to reject this driver assist request?',
      confirmLabel: isAr ? 'رفض' : 'Reject',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      icon: LucideIcons.xCircle,
      confirmIcon: LucideIcons.x,
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _processingId = requestId);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.decideAssistRequest(
        requestId,
        status: 'REJECTED',
      );
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم رفض الطلب.' : 'Request rejected.'),
            backgroundColor: AppColors.info,
          ),
        );
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _pickAndAssignDriver(String requestId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final driversState = ref.read(driversProvider);
    final drivers = driversState.value?.drivers ?? [];

    if (drivers.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'لا يوجد سائقون محملون. يرجى التأكد من توفر السائقين.'
                : 'No drivers loaded. Please ensure drivers are available.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final chosenDriver = await showDialog<DriverProfile>(
      context: context,
      builder: (ctx) => AppDialog(
        maxWidth: 460,
        maxHeight: 520,
        scrollableBody: false,
        expandBody: true,
        bodyPadding: EdgeInsets.zero,
        header: AppDialogHeader(
          icon: LucideIcons.userCheck,
          title: isAr ? 'اختيار كابتن مساعد' : 'Select Assistant Driver',
          subtitle: isAr
              ? 'اختر كابتناً لتعيينه على هذا الطلب'
              : 'Choose an available driver to assign',
          onClose: () => Navigator.pop(ctx),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: drivers.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: AppDialogStyles.borderColor(ctx),
          ),
          itemBuilder: (ctx, i) {
            final d = drivers[i];
            final theme = Theme.of(ctx);
            final vehicleLabel = (d.vehicleType != null &&
                    d.vehicleType!.trim().isNotEmpty)
                ? VehicleTypeHelper.label(d.vehicleType, isArabic: isAr)
                : '';
            final subtitle = [
              d.status,
              if (vehicleLabel.isNotEmpty) vehicleLabel,
              if ((d.vehiclePlate ?? '').trim().isNotEmpty)
                d.vehiclePlate!.trim(),
            ].join(' • ');
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: AppNetworkAvatar(
                imageUrl: ImageUtils.formatImageUrl(d.avatar),
                size: 36,
                fallbackIcon: LucideIcons.user,
                fallbackIconSize: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                foregroundColor: AppColors.primary,
              ),
              title: Text(
                d.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 16),
              onTap: () => Navigator.pop(ctx, d),
            );
          },
        ),
        footer: AppDialogFooter(
          cancelLabel: isAr ? 'إلغاء' : 'Cancel',
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (chosenDriver == null) return;

    setState(() => _processingId = requestId);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.assignAssistDriver(
        requestId,
        driverId: chosenDriver.id,
      );
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم تعيين ${chosenDriver.name} ككابتن مساعد.'
                  : 'Assigned ${chosenDriver.name} as assistant driver.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  String _formatReason(String reason, bool isAr) {
    switch (reason) {
      case 'TOO_HEAVY':
        return isAr ? 'حمولة ثقيلة جداً' : 'Too Heavy';
      case 'TOO_LARGE':
        return isAr ? 'حجم كبير جداً' : 'Too Large / Bulky';
      case 'MULTI_STOP_COMPLEXITY':
        return isAr ? 'تعدد نقاط الاستلام والشحن' : 'Multi-stop Complexity';
      case 'ACCESS_RESTRICTED':
        return isAr ? 'صعوبة الوصول أو الأدوار العليا' : 'Access Restricted / High Floor';
      case 'LONG_DISTANCE':
        return isAr ? 'مسافة طويلة جداً' : 'Long Distance';
      case 'OTHER':
        return isAr ? 'سبب آخر' : 'Other';
      default:
        return reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';
    final theme = Theme.of(context);
    final isMobile = AppDialogStyles.isMobile(context);

    return AppDialog(
      maxWidth: 700,
      maxHeight: 700,
      scrollableBody: false,
      expandBody: true,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      header: AppDialogHeader(
        icon: LucideIcons.users,
        title: isAr
            ? 'طلبات مساعدة الكباتن المعلقة'
            : 'Pending Driver Assist Requests',
        subtitle: _requests.isNotEmpty
            ? (isAr
                ? (_requests.length == 1
                    ? 'طلب واحد بانتظار الإجراء'
                    : '${_requests.length} طلبات بانتظار الإجراء')
                : (_requests.length == 1
                    ? '1 request awaiting action'
                    : '${_requests.length} requests awaiting action'))
            : null,
        actions: [
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _isLoading ? null : _loadRequests,
          ),
        ],
        onClose: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr
                            ? 'لا توجد طلبات مساعدة معلقة حالياً'
                            : 'No pending driver assist requests',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _requests[i] as Map<String, dynamic>;
                    final id = item['id']?.toString() ?? '';
                    final order =
                        item['order'] is Map ? item['order'] as Map : {};
                    final primaryDriver = item['primaryDriver'] is Map
                        ? item['primaryDriver'] as Map
                        : (item['driver'] is Map
                            ? item['driver'] as Map
                            : (item['requestedByDriver'] is Map
                                ? item['requestedByDriver'] as Map
                                : {}));
                    final primaryUser = primaryDriver['user'] is Map
                        ? primaryDriver['user'] as Map
                        : {};
                    final orderNumber = order['orderNumber']?.toString() ?? '';
                    final deliveryGroup = item['deliveryGroup'] is Map
                        ? item['deliveryGroup'] as Map
                        : null;
                    final groupSeq = deliveryGroup?['sequence'];
                    final driverName = primaryUser['name']?.toString() ??
                        primaryDriver['name']?.toString() ??
                        'Driver';
                    final driverPhone = primaryUser['phone']?.toString() ??
                        primaryDriver['phone']?.toString() ??
                        '';
                    final driverAvatar =
                        (primaryDriver['avatar'] ?? primaryUser['avatar'])
                            ?.toString();
                    final reason = item['reason']?.toString() ?? '';
                    final note = item['note']?.toString() ?? '';
                    final fee = item['proposedAssistFee']?.toString() ??
                        item['assistFee']?.toString() ??
                        '0';
                    final reqStatus = item['status']?.toString() ?? 'PENDING';
                    final isBusy = _processingId == id;

                    final statusColor = reqStatus == 'APPROVED'
                        ? AppColors.success
                        : reqStatus == 'REJECTED'
                            ? AppColors.error
                            : AppColors.warning;
                    final statusLabel = reqStatus == 'APPROVED'
                        ? (isAr
                            ? 'تمت الموافقة (جاهز للتعيين)'
                            : 'Approved (Ready to Assign)')
                        : reqStatus == 'REJECTED'
                            ? (isAr ? 'مرفوض' : 'Rejected')
                            : (isAr ? 'بانتظار الموافقة' : 'Pending Review');

                    return AppDialogSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.package,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        groupSeq != null
                                            ? '${orderNumber.isNotEmpty ? '#$orderNumber' : 'Order'} • ${isAr ? 'الرحلة #$groupSeq' : 'Trip #$groupSeq'}'
                                            : (orderNumber.isNotEmpty
                                                ? '#$orderNumber'
                                                : 'Order'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppBadgePill(
                                text: statusLabel,
                                accentColor: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              AppNetworkAvatar(
                                imageUrl: ImageUtils.formatImageUrl(driverAvatar),
                                size: 24,
                                fallbackIcon: LucideIcons.user,
                                fallbackIconSize: 13,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${isAr ? "الكابتن الطالب" : "Primary Driver"}: $driverName ${driverPhone.isNotEmpty ? "($driverPhone)" : ""}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isAr ? "السبب" : "Reason"}: ${_formatReason(reason, isAr)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${isAr ? "ملاحظة" : "Note"}: $note',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${isAr ? "رسوم المساعدة المقترحة" : "Assist Fee"}: $fee ${isAr ? "ج.م" : "EGP"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isBusy)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (reqStatus == 'PENDING')
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: theme.textTheme.labelMedium?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => _approveRequest(id),
                                    icon: const Icon(LucideIcons.check, size: 14),
                                    label: Text(isAr ? 'موافقة' : 'Approve'),
                                  ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () => _offerToNearest(id),
                                  icon: const Icon(LucideIcons.radio, size: 14),
                                  label: Text(
                                    isAr ? 'بث للأقرب' : 'Offer Nearest',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () => _autoAssign(id),
                                  icon: const Icon(LucideIcons.wand2, size: 14),
                                  label: Text(
                                    isAr ? 'تعيين تلقائي' : 'Auto Assign',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () => _pickAndAssignDriver(id),
                                  icon: const Icon(
                                    LucideIcons.userCheck,
                                    size: 14,
                                  ),
                                  label: Text(
                                    isAr ? 'اختيار كابتن' : 'Pick Driver',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: BorderSide(
                                      color:
                                          AppColors.error.withValues(alpha: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: theme.textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () => _rejectRequest(id),
                                  icon: const Icon(LucideIcons.x, size: 14),
                                  label: Text(isAr ? 'رفض' : 'Reject'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إغلاق' : 'Close',
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
