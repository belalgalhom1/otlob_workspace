import 'package:api/api.dart' show DeliveryIncidentResponsibility;
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import '../orders_provider.dart';
import 'package:vendor/core/utils/error_utils.dart';

class AssignDriverSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String orderCode;
  final List<dynamic>? deliveryGroups;
  final String? initialDeliveryGroupId;

  const AssignDriverSheet({
    super.key,
    required this.orderId,
    required this.orderCode,
    this.deliveryGroups,
    this.initialDeliveryGroupId,
  });

  @override
  ConsumerState<AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _AssignDriverSheetState extends ConsumerState<AssignDriverSheet> {
  bool _isFetching = true;
  bool _isAssigning = false;
  List<dynamic> _drivers = [];
  String? _selectedGroupId;
  DeliveryIncidentResponsibility? _previousDriverResponsibility;
  final TextEditingController _reassignmentReasonController =
      TextEditingController();

  @override
  void dispose() {
    _reassignmentReasonController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _assignableGroups {
    final raw = widget.deliveryGroups;
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .where((g) {
          final st = g['status']?.toString() ?? '';
          return st != 'CANCELLED' && st != 'DELIVERED';
        })
        .map((g) => Map<String, dynamic>.from(g))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final groups = _assignableGroups;
    _selectedGroupId = widget.initialDeliveryGroupId ??
        (groups.isNotEmpty ? groups.first['id']?.toString() : null);
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      // Fetch online drivers
      final result = await repo.getDrivers(status: 'ONLINE', limit: 100);

      if (mounted) {
        setState(() {
          _drivers = result['drivers'] ?? result['items'] ?? [];
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _assignDriver(String driverId) async {
    setState(() => _isAssigning = true);
    try {
      final repo = ref.read(adminOrdersRepositoryProvider);
      await repo.assignDriver(
        orderId: widget.orderId,
        driverId: driverId,
        deliveryGroupId: _selectedGroupId,
        previousDriverResponsibility: _previousDriverResponsibility,
        reassignmentReason: _reassignmentReasonController.text,
      );

      if (mounted) {
        // Refresh orders list
        ref.read(ordersProvider.notifier).fetchOrders();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.driverAssignedSuccess),
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
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final groups = _assignableGroups;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isAr
                          ? 'تعيين سائق للطلب #${widget.orderCode}'
                          : 'Assign Driver to Order #${widget.orderCode}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (groups.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                  decoration: InputDecoration(
                    labelText: isAr ? 'مجموعة التوصيل / الشحنة' : 'Delivery Group / Trip',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: groups.map((g) {
                    final gid = g['id']?.toString() ?? '';
                    final seq = g['sequence'] ?? 1;
                    final drv = g['primaryDriver'] ?? g['driver'];
                    final drvName = drv is Map ? drv['name']?.toString() : null;
                    final label = (drvName != null && drvName.isNotEmpty)
                        ? (isAr
                            ? 'شحنة #$seq (الحالي: $drvName)'
                            : 'Trip #$seq (Current: $drvName)')
                        : (isAr ? 'شحنة #$seq' : 'Trip #$seq');
                    return DropdownMenuItem<String>(
                      value: gid,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _isAssigning
                      ? null
                      : (val) => setState(() => _selectedGroupId = val),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<DeliveryIncidentResponsibility?>(
                initialValue: _previousDriverResponsibility,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'مسؤولية السائق السابق (في حال الاستبدال)'
                      : 'Previous Driver Responsibility (if replacing)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<DeliveryIncidentResponsibility?>(
                    value: null,
                    child: Text(
                      isAr
                          ? 'تلقائي (قيد المراجعة)'
                          : 'Default (Under Review)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
                    child: Text(
                      isAr ? 'خطأ السائق السابق' : 'Previous Driver At Fault',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: DeliveryIncidentResponsibility.CUSTOMER,
                    child: Text(
                      isAr ? 'بسبب العميل' : 'Customer',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: DeliveryIncidentResponsibility.VENDOR,
                    child: Text(
                      isAr ? 'بسبب المتجر' : 'Vendor',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM,
                    child: Text(
                      isAr ? 'ظرف خارجي / نظام' : 'External / System',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: _isAssigning
                    ? null
                    : (val) =>
                          setState(() => _previousDriverResponsibility = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reassignmentReasonController,
                enabled: !_isAssigning,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'سبب إعادة تعيين السائق (اختياري)'
                      : 'Reassignment Reason (Optional)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_isFetching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_drivers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      isAr ? 'لا يوجد سائقون متصلون حالياً' : 'No online drivers found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];
                      final name = (driver['name'] ??
                              (driver['user'] is Map
                                  ? driver['user']['name']
                                  : null) ??
                              'Unknown')
                          .toString();
                      final phone = (driver['phone'] ??
                              driver['phoneNumber'] ??
                              (driver['user'] is Map
                                  ? driver['user']['phone']
                                  : null) ??
                              '')
                          .toString();

                      final rawAvatar = (driver['avatar'] ??
                              (driver['user'] is Map
                                  ? driver['user']['avatar']
                                  : null))
                          ?.toString();

                      return ListTile(
                        leading: AppNetworkAvatar(
                          imageUrl: ImageUtils.formatImageUrl(rawAvatar),
                          size: 40,
                          fallbackIcon: Icons.person,
                        ),
                        title: Text(name),
                        subtitle: Text(phone),
                        trailing: ElevatedButton(
                          onPressed: _isAssigning
                              ? null
                              : () => _assignDriver(driver['id'].toString()),
                          child: Text(isAr ? 'تعيين' : 'Assign'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
