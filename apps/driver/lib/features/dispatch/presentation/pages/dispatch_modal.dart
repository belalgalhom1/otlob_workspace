import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class DispatchModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> dispatchData;

  const DispatchModal({super.key, required this.dispatchData});

  @override
  ConsumerState<DispatchModal> createState() => _DispatchModalState();

  static Future<void> show(BuildContext context, Map<String, dynamic> data) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: 'dispatch_modal_route'),
      builder: (context) => DispatchModal(dispatchData: data),
    );
  }
}

class _DispatchModalState extends ConsumerState<DispatchModal> {
  int _secondsLeft = 30; // From driverAcceptTimeoutSecs
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.dispatchData['expiresAt'] != null) {
      try {
        final expiresAt = DateTime.parse(widget.dispatchData['expiresAt'].toString());
        final diff = expiresAt.difference(DateTime.now()).inSeconds;
        _secondsLeft = diff > 0 ? diff : 0;
      } catch (_) {}
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _onDecline(); // Auto-decline when timer expires
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onAccept() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(driverDispatchRepositoryProvider);
      final dispatchId = widget.dispatchData['dispatchId'] ?? widget.dispatchData['id'];
      await repo.respondToDispatch(dispatchId, 'ACCEPTED');
      
      // Invalidate the provider so it fetches the new order instead of using the cached null state
      ref.invalidate(orderExecutionProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/order-execution');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptDispatch(e.toString()))),
        );
      }
    }
  }

  Future<void> _onDecline() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(driverDispatchRepositoryProvider);
      final dispatchId = widget.dispatchData['dispatchId'] ?? widget.dispatchData['id'];
      await repo.respondToDispatch(dispatchId, 'REJECTED');
    } catch (_) {
      // Ignore errors on decline
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(configurationProvider.notifier).currency;
    final earningsVal = widget.dispatchData['estimatedEarnings'] ?? 0.0;
    final earnings = '${earningsVal.toString()} $currency';
    
    final distVal = widget.dispatchData['distanceKm'] ?? widget.dispatchData['estimatedDistanceKm'] ?? 0.0;
    final distance = '${distVal.toStringAsFixed(1)} km';
    
    final pickupName = widget.dispatchData['pickupLocationName']?.toString() ?? AppLocalizations.of(context)!.vendorFallback;
    final dropoffName = widget.dispatchData['dropoffLocationName']?.toString() ?? AppLocalizations.of(context)!.customerFallback;

    return DialogScaffold(child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.zap, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.newDeliveryRequest,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(LucideIcons.banknote, earnings, AppLocalizations.of(context)!.earningsLabel, AppColors.success),
                _buildInfoItem(LucideIcons.navigation, distance, AppLocalizations.of(context)!.distanceLabel, AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            _buildLocationRow(LucideIcons.store, pickupName, AppLocalizations.of(context)!.pickupLabel, context),
            const SizedBox(height: 12),
            _buildLocationRow(LucideIcons.mapPin, dropoffName, AppLocalizations.of(context)!.dropoffLabel, context),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.expiresInSeconds(_secondsLeft),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondsLeft < 10 ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: AppLocalizations.of(context)!.acceptDelivery,
              isLoading: _isLoading,
              onPressed: _onAccept,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _onDecline,
              child: Text(AppLocalizations.of(context)!.decline),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, String name, String type, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}
