import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import '../orders_provider.dart';
import 'package:vendor/core/utils/error_utils.dart';

class AssignDriverSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String orderCode;

  const AssignDriverSheet({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  ConsumerState<AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _AssignDriverSheetState extends ConsumerState<AssignDriverSheet> {
  bool _isFetching = true;
  bool _isAssigning = false;
  List<dynamic> _drivers = [];

  @override
  void initState() {
    super.initState();
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
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.ordersAdminForceAssignDriver(
        orderId: widget.orderId,
        adminAssignDriverDto: AdminAssignDriverDto((b) => b..driverId = driverId),
      );

      if (mounted) {
        // Refresh orders list
        ref.read(ordersProvider.notifier).fetchOrders();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.driverAssignedSuccess)),
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
                      'Assign Driver to Order #${widget.orderCode}',
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
                      'No online drivers found',
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
                      final name = (driver['name'] ?? (driver['user'] is Map ? driver['user']['name'] : null) ?? 'Unknown').toString();
                      final phone = (driver['phone'] ?? driver['phoneNumber'] ?? (driver['user'] is Map ? driver['user']['phone'] : null) ?? '').toString();
                      
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Text(phone),
                        trailing: ElevatedButton(
                          onPressed: _isAssigning ? null : () => _assignDriver(driver['id']),
                          child: const Text('Assign'),
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
