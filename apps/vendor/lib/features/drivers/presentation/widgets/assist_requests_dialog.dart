import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Assist Request'),
        content: const Text('Are you sure you want to reject this driver assist request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected.'),
            backgroundColor: AppColors.info,
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

  Future<void> _pickAndAssignDriver(String requestId) async {
    final driversState = ref.read(driversProvider);
    final drivers = driversState.value?.drivers ?? [];

    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No drivers loaded. Please ensure drivers are available.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final chosenDriver = await showDialog<DriverProfile>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Assistant Driver'),
        content: SizedBox(
          width: 400,
          height: 350,
          child: ListView.separated(
            itemCount: drivers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = drivers[i];
              return ListTile(
                title: Text(d.name),
                subtitle: Text('${d.status} • ${d.vehicleType ?? ""} ${d.vehiclePlate ?? ""}'.trim()),
                onTap: () => Navigator.pop(ctx, d),
              );
            },
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned ${chosenDriver.name} as assistant driver.'),
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

    return DialogScaffold(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.users, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr ? 'طلبات مساعدة الكباتن المعلقة' : 'Pending Driver Assist Requests',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: _loadRequests,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _requests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.checkCircle, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr ? 'لا توجد طلبات مساعدة معلقة حالياً' : 'No pending driver assist requests',
                                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
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
                                final order = item['order'] is Map ? item['order'] as Map : {};
                                final primaryDriver = item['primaryDriver'] is Map
                                    ? item['primaryDriver'] as Map
                                    : (item['driver'] is Map ? item['driver'] as Map : {});
                                final primaryUser = primaryDriver['user'] is Map ? primaryDriver['user'] as Map : {};
                                final orderNumber = order['orderNumber']?.toString() ?? '';
                                final driverName = primaryUser['name']?.toString() ?? primaryDriver['name']?.toString() ?? 'Driver';
                                final driverPhone = primaryUser['phone']?.toString() ?? primaryDriver['phone']?.toString() ?? '';
                                final reason = item['reason']?.toString() ?? '';
                                final note = item['note']?.toString() ?? '';
                                final fee = item['proposedAssistFee']?.toString() ?? item['assistFee']?.toString() ?? '0';
                                final reqStatus = item['status']?.toString() ?? 'PENDING';
                                final isBusy = _processingId == id;

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(LucideIcons.package, size: 16, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      orderNumber.isNotEmpty ? '#$orderNumber' : 'Order',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: reqStatus == 'APPROVED'
                                                    ? AppColors.success.withValues(alpha: 0.15)
                                                    : reqStatus == 'REJECTED'
                                                        ? AppColors.error.withValues(alpha: 0.15)
                                                        : AppColors.warning.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                reqStatus == 'APPROVED'
                                                    ? (isAr ? 'تمت الموافقة (جاهز للتعيين)' : 'Approved (Ready to Assign)')
                                                    : reqStatus == 'REJECTED'
                                                        ? (isAr ? 'مرفوض' : 'Rejected')
                                                        : (isAr ? 'بانتظار الموافقة' : 'Pending Review'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: reqStatus == 'APPROVED'
                                                      ? AppColors.success
                                                      : reqStatus == 'REJECTED'
                                                          ? AppColors.error
                                                          : AppColors.warning,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${isAr ? "الكابتن الطالب" : "Primary Driver"}: $driverName ${driverPhone.isNotEmpty ? "($driverPhone)" : ""}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isAr ? "السبب" : "Reason"}: ${_formatReason(reason, isAr)}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                        ),
                                        if (note.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${isAr ? "ملاحظة" : "Note"}: $note',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isAr ? "رسوم المساعدة المقترحة" : "Assist Fee"}: $fee EGP',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                                                      backgroundColor: AppColors.success,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      textStyle: const TextStyle(fontSize: 12),
                                                    ),
                                                    onPressed: () => _approveRequest(id),
                                                    icon: const Icon(LucideIcons.check, size: 14),
                                                    label: Text(isAr ? 'موافقة' : 'Approve'),
                                                  ),
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  textStyle: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () => _offerToNearest(id),
                                                icon: const Icon(LucideIcons.radio, size: 14),
                                                label: Text(isAr ? 'بث للأقرب' : 'Offer Nearest'),
                                              ),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  textStyle: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () => _autoAssign(id),
                                                icon: const Icon(LucideIcons.wand2, size: 14),
                                                label: Text(isAr ? 'تعيين تلقائي' : 'Auto Assign'),
                                              ),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  textStyle: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () => _pickAndAssignDriver(id),
                                                icon: const Icon(LucideIcons.userCheck, size: 14),
                                                label: Text(isAr ? 'اختيار كابتن' : 'Pick Driver'),
                                              ),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.error,
                                                  side: const BorderSide(color: AppColors.error),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  textStyle: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () => _rejectRequest(id),
                                                icon: const Icon(LucideIcons.x, size: 14),
                                                label: Text(isAr ? 'رفض' : 'Reject'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
