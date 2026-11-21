import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';

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
    // The expiry is enforced by the server; the client clock may lag or lead
    // the server, so never start at 0 (that would auto-pop the dialog before
    // the driver can react). If the absolute expiresAt already passed on this
    // device, fall back to the configured accept window.
    int? computedSeconds;
    if (widget.dispatchData['expiresAt'] != null) {
      try {
        final expiresAt = DateTime.parse(widget.dispatchData['expiresAt'].toString());
        final diff = expiresAt.difference(DateTime.now()).inSeconds;
        if (diff > 0) computedSeconds = diff;
      } catch (_) {}
    }
    final config = ref.read(configurationProvider).value;
    final timeout = config?['driverAcceptTimeoutSecs'] ?? config?['driverDispatchTimeout'];
    final fallback = timeout is num && timeout > 0 ? timeout.toInt() : 30;
    _secondsLeft = computedSeconds ?? fallback;
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
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onAccept() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(driverDispatchRepositoryProvider);
      final dispatchId = widget.dispatchData['dispatchId'] ?? widget.dispatchData['id'];
      await repo.respondToDispatch(dispatchId, 'ACCEPTED');
      
      // Refresh active order state without wiping _selectedOrderId if driver is already executing an order
      await ref.read(orderExecutionProvider.notifier).refresh();
      
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/order-execution');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errMsg = ErrorUtils.translate(context, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptDispatch(errMsg))),
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
    final rawCurrency = ref.watch(configurationProvider.notifier).currency;
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';
    final currency = (isAr && rawCurrency == 'EGP') ? 'ج.م' : rawCurrency;
    final rawEarnings = widget.dispatchData['estimatedEarnings'];
    final double earningsNum = rawEarnings is num
        ? rawEarnings.toDouble()
        : (double.tryParse(rawEarnings?.toString() ?? '0') ?? 0.0);
    final earnings = '${earningsNum.toStringAsFixed(0)} $currency';

    final rawDeliveryFee = widget.dispatchData['deliveryFee'];
    final double deliveryFeeNum = rawDeliveryFee is num
        ? rawDeliveryFee.toDouble()
        : (double.tryParse(rawDeliveryFee?.toString() ?? '0') ?? 0.0);
    final String? feeSubLabel = (deliveryFeeNum > 0 && (deliveryFeeNum - earningsNum).abs() > 0.01)
        ? '${isAr ? 'رسوم التوصيل' : 'Delivery fee'}: ${deliveryFeeNum.toStringAsFixed(0)} $currency'
        : null;

    final distVal = widget.dispatchData['distanceKm'] ?? widget.dispatchData['estimatedDistanceKm'] ?? 0.0;
    final distance = '${distVal.toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}';

    final orderType = OrderTypeHelper.resolve(widget.dispatchData);
    final pickupFallback = orderType.isRide
        ? l10n.customerFallback
        : (orderType.isCustomDelivery ? l10n.pickupLabel : l10n.vendorFallback);
    final pickupName =
        widget.dispatchData['pickupLocationName']?.toString() ?? pickupFallback;
    final pickupLogo = widget.dispatchData['pickupLocationLogo']?.toString();
    final dropoffName =
        widget.dispatchData['dropoffLocationName']?.toString() ??
            l10n.customerFallback;
    final dropoffAvatar =
        widget.dispatchData['dropoffCustomerAvatar']?.toString();
    final isStacked = widget.dispatchData['isStacked'] == true ||
        widget.dispatchData['isStacked'] == 'true';
    final requestedVehicleType = VehicleTypeHelper.normalize(
      widget.dispatchData['requestedVehicleType']?.toString(),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = AppDialogStyles.isMobile(context);
    final accentTextColor =
        isDark ? AppColors.primary : const Color(0xFFB45309);
    final earningsColor =
        isDark ? AppColors.success : const Color(0xFF047857);
    final isUrgent = _secondsLeft < 10;

    return AppDialog(
      maxWidth: 460,
      canPop: false,
      header: AppDialogHeader(
        icon: orderType.isRide
            ? (requestedVehicleType != null &&
                    requestedVehicleType != VehicleTypeHelper.car
                ? VehicleTypeHelper.icon(requestedVehicleType)
                : LucideIcons.car)
            : (orderType.isCustomDelivery && requestedVehicleType != null
                ? VehicleTypeHelper.icon(requestedVehicleType)
                : LucideIcons.zap),
        title: OrderTypeHelper.dispatchModalTitle(orderType, isArabic: isAr),
        showCloseButton: false,
        subtitleWidget: (isStacked || requestedVehicleType != null)
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (requestedVehicleType != null)
                      AppBadgePill(
                        text: VehicleTypeHelper.label(
                          requestedVehicleType,
                          isArabic: isAr,
                        ),
                        icon: VehicleTypeHelper.icon(requestedVehicleType),
                        accentColor: accentTextColor,
                      ),
                    if (isStacked)
                      AppBadgePill(
                        text: isAr
                            ? 'طلب مجمع إضافي في خط سيرك'
                            : 'Batch Corridor Order',
                        icon: LucideIcons.route,
                        accentColor: accentTextColor,
                      ),
                  ],
                ),
              )
            : null,
        actions: [
          AppBadgePill(
            text: '${_secondsLeft}s',
            icon: LucideIcons.timer,
            accentColor: isUrgent ? AppColors.error : accentTextColor,
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDialogSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    LucideIcons.banknote,
                    earnings,
                    l10n.earningsLabel,
                    earningsColor,
                    subLabel: feeSubLabel,
                  ),
                ),
                Container(
                  width: 1,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppDialogStyles.borderColor(context),
                ),
                Expanded(
                  child: _buildInfoItem(
                    LucideIcons.navigation,
                    distance,
                    l10n.distanceLabel,
                    accentTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppDialogSectionCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLocationRow(
                  orderType.isRide
                      ? LucideIcons.user
                      : (orderType.isCustomDelivery
                          ? LucideIcons.package
                          : LucideIcons.store),
                  pickupName,
                  orderType.isRide
                      ? '${l10n.pickupLabel} (${l10n.customerFallback})'
                      : l10n.pickupLabel,
                  context,
                  avatarUrl: orderType.isRide ? dropoffAvatar : pickupLogo,
                  isStore: orderType.isStandard,
                ),
                Divider(
                  height: 22,
                  thickness: 1,
                  color: AppDialogStyles.borderColor(context),
                ),
                _buildLocationRow(
                  LucideIcons.mapPin,
                  dropoffName,
                  l10n.dropoffLabel,
                  context,
                  avatarUrl: dropoffAvatar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.expiresInSeconds(_secondsLeft),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUrgent ? AppColors.error : accentTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
      footer: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          14,
          isMobile ? 16 : 24,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              text: OrderTypeHelper.dispatchAcceptButtonLabel(
                orderType,
                isArabic: isAr,
              ),
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _onAccept,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _isLoading ? null : _onDecline,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(
                  color: AppDialogStyles.borderColor(context),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.decline,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label,
    Color color, {
    String? subLabel,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 3),
          Text(
            subLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String name,
    String type,
    BuildContext context, {
    String? avatarUrl,
    bool isStore = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primary : const Color(0xFFB45309);
    return Row(
      children: [
        AppNetworkAvatar(
          imageUrl: ImageUtils.formatImageUrl(avatarUrl),
          size: 38,
          borderRadius: isStore ? 10 : null,
          fallbackIcon: icon,
          fallbackIconSize: 19,
          backgroundColor: AppColors.primary.withValues(alpha: 0.14),
          foregroundColor: iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
