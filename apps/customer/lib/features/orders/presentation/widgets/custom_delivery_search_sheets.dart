import 'dart:async';
import 'dart:io';
import 'package:api/api.dart';
import 'package:core/core.dart'
    show OrderActivityHelper, OrderTypeHelper, VehicleTypeHelper;
import 'package:data/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_kit/ui_kit.dart'
    show
        AppNetworkAvatar,
        ExternalActionLauncher,
        MediaPermissionHelper,
        RouteEndpointsCard;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../providers/custom_delivery_search_controller.dart';
import '../providers/orders_provider.dart';
import '../widgets/rate_order_bottom_sheet.dart';

/// Main draggable bottom sheet content for [CustomDeliverySearchScreen].
/// Adapts smoothly across Searching, Driver Found, and Terminal states without
/// jarring screen transitions, and scales gracefully for all [TextScaler] sizes.
class CustomDeliverySearchSheetBody extends ConsumerWidget {
  const CustomDeliverySearchSheetBody({
    super.key,
    required this.state,
    required this.driverLocationListenable,
    this.nearbyVehiclesListenable,
    required this.onCancelConfirmed,
    required this.onRetrySearch,
    required this.onEditRequest,
    this.onPaymentSubmitted,
    this.currency = 'EGP',
  });

  final CustomDeliverySearchState state;
  final ValueListenable<DriverLiveMarkerState?> driverLocationListenable;
  final ValueListenable<List<NearbyVehicleMarkerState>>?
  nearbyVehiclesListenable;
  final VoidCallback onCancelConfirmed;
  final VoidCallback onRetrySearch;
  final VoidCallback onEditRequest;
  final VoidCallback? onPaymentSubmitted;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetChild = switch (state) {
      _ when state.isDriverMatched => _DriverFoundSheetView(
        key: const ValueKey('driver_found_sheet'),
        state: state,
        driverLocationListenable: driverLocationListenable,
        onPaymentSubmitted: onPaymentSubmitted,
        currency: currency,
      ),
      _ when state.isTerminal => _TerminalSearchSheetView(
        key: ValueKey('terminal_sheet_${state.phase.name}'),
        state: state,
        onRetrySearch: onRetrySearch,
        onEditRequest: onEditRequest,
        currency: currency,
      ),
      _ => _SearchingSheetView(
        key: const ValueKey('searching_sheet'),
        state: state,
        nearbyVehiclesListenable: nearbyVehiclesListenable,
        onRequestCancel: () => _showCancelConfirmation(context),
        currency: currency,
        isDark: isDark,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: sheetChild,
    );
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return SafeArea(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'app.confirmCancelSearchTitle'.tr(context: dialogCtx),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                'app.confirmCancelSearchMessage'.tr(context: dialogCtx),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            actions: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(88, 48),
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: Text(
                      'app.keepSearching'.tr(context: dialogCtx),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: Text(
                      'app.confirmCancelAction'.tr(context: dialogCtx),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      onCancelConfirmed();
    }
  }
}

class _SearchingSheetView extends StatelessWidget {
  const _SearchingSheetView({
    super.key,
    required this.state,
    required this.nearbyVehiclesListenable,
    required this.onRequestCancel,
    required this.currency,
    required this.isDark,
  });

  final CustomDeliverySearchState state;
  final ValueListenable<List<NearbyVehicleMarkerState>>?
  nearbyVehiclesListenable;
  final VoidCallback onRequestCancel;
  final String currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.locale.languageCode == 'ar';
    final statusInfo = _resolvePhaseDisplay(context, state.phase);
    final sStatus = state.searchStatus;
    final attempt = (sStatus?.attempt ?? 1).toInt();
    final maxAttempts = (sStatus?.maxAttempts ?? 5).toInt();
    final radius = sStatus?.radiusKm ?? 3;
    final fallbackNearbyCount = (sStatus?.nearbyAvailableCount ?? 0).toInt();
    final totalContacted = (sStatus?.totalContactedCount ?? 0).toInt();
    final rejectedCount = (sStatus?.rejectedCount ?? 0).toInt();
    final requestedVehicle = state.requestedVehicleType;

    Widget buildMetricsWrap(int nearbyCount) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetricPill(
            icon: Icons.radar_rounded,
            label: 'app.waveProgressLabel'.tr(
              context: context,
              namedArgs: {
                'attempt': '$attempt',
                'maxAttempts': '$maxAttempts',
              },
            ),
            color: AppColors.primary,
            isDark: isDark,
          ),
          _MetricPill(
            icon: Icons.track_changes_rounded,
            label: 'app.searchRadiusLabel'.tr(
              context: context,
              namedArgs: {'radius': radius.toString()},
            ),
            color: Colors.blueAccent,
            isDark: isDark,
          ),
          if (nearbyCount > 0)
            _MetricPill(
              icon: _vehicleIcon(requestedVehicle),
              label: 'app.nearbyDriversOnlineCount'.tr(
                context: context,
                namedArgs: {'count': '$nearbyCount'},
              ),
              color: AppColors.success,
              isDark: isDark,
            ),
          if (totalContacted > 0)
            _MetricPill(
              icon: Icons.notifications_active_rounded,
              label: 'app.contactedDriversCount'.tr(
                context: context,
                namedArgs: {'count': '$totalContacted'},
              ),
              color: Colors.deepOrange,
              isDark: isDark,
            ),
          if (rejectedCount > 0)
            _MetricPill(
              icon: Icons.close_rounded,
              label: 'app.rejectedDriversCount'.tr(
                context: context,
                namedArgs: {'count': '$rejectedCount'},
              ),
              color: theme.colorScheme.onSurfaceVariant,
              isDark: isDark,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: statusInfo.accent.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusInfo.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                _vehicleIcon(requestedVehicle),
                color: statusInfo.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app.findingDriverTitle'.tr(context: context),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      key: ValueKey('${state.phase.name}_$attempt'),
                      child: Text(
                        statusInfo.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusInfo.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          statusInfo.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (sStatus != null)
          _WaveCountdownBar(
            waveExpiresAtIso: sStatus.waveExpiresAt,
            totalSecs: sStatus.searchTimeoutSecs.toInt(),
            accentColor: AppColors.primary,
          ),
        const SizedBox(height: 12),
        if (nearbyVehiclesListenable != null)
          ValueListenableBuilder<List<NearbyVehicleMarkerState>>(
            valueListenable: nearbyVehiclesListenable!,
            builder: (context, liveVehicles, _) {
              final effectiveCount = liveVehicles.isNotEmpty
                  ? liveVehicles.length
                  : fallbackNearbyCount;
              return buildMetricsWrap(effectiveCount);
            },
          )
        else
          buildMetricsWrap(fallbackNearbyCount),
        const SizedBox(height: 16),
        if (state.order != null) ...[
          _buildOrderRouteAndFareSummary(
            context,
            state.order!,
            currency: currency,
            isAr: isAr,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: OutlinedButton(
            onPressed: state.isCancelling ? null : onRequestCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: state.isCancelling
                    ? theme.colorScheme.outlineVariant
                    : AppColors.error,
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: state.isCancelling
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'app.cancellingSearch'.tr(context: context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close_rounded, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'app.cancelSearch'.tr(context: context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _DriverFoundSheetView extends ConsumerStatefulWidget {
  const _DriverFoundSheetView({
    super.key,
    required this.state,
    required this.driverLocationListenable,
    this.onPaymentSubmitted,
    required this.currency,
  });

  final CustomDeliverySearchState state;
  final ValueListenable<DriverLiveMarkerState?> driverLocationListenable;
  final VoidCallback? onPaymentSubmitted;
  final String currency;

  @override
  ConsumerState<_DriverFoundSheetView> createState() =>
      _DriverFoundSheetViewState();
}

class _DriverFoundSheetViewState extends ConsumerState<_DriverFoundSheetView> {
  bool _openingChat = false;
  XFile? _receiptFile;
  bool _submittingPayment = false;

  Future<void> _openOrderChat() async {
    if (_openingChat) return;
    final orderId = widget.state.orderId;
    setState(() => _openingChat = true);
    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final convo = await chatRepo.createOrderConversation(orderId);
      if (!mounted) return;
      final convoData = (convo is Map && convo.containsKey('data'))
          ? convo['data']
          : convo;
      final convoId =
          (convoData is Map ? convoData['id'] : null)?.toString() ?? orderId;
      final orderNum =
          widget.state.order?['orderNumber']?.toString() ??
          (orderId.length >= 8 ? orderId.substring(0, 8) : orderId);
      final isAr = context.locale.languageCode == 'ar';
      final orderType = OrderTypeHelper.resolve(
        widget.state.order ??
            {'type': widget.state.isRide ? 'RIDE' : 'CUSTOM_DELIVERY'},
      );
      await context.push(
        '/chat/order/$convoId',
        extra: {
          'title': OrderTypeHelper.chatTitle(
            orderType,
            orderNumber: orderNum,
            isArabic: isAr,
          ),
          'orderId': orderId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  List<Map<String, dynamic>> _visibleDriverWallets(
    Map<String, dynamic> driver,
  ) {
    final raw = driver['mobileWallets'];
    if (raw is! List || raw.isEmpty) return const [];
    final wallets = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((w) => w['isActive'] != false)
        .toList();
    bool isInstaPay(Map<String, dynamic> w) =>
        (w['type'] ?? w['provider'] ?? '')
            .toString()
            .toUpperCase()
            .contains('INSTAPAY');
    final mobile = wallets.where((w) => !isInstaPay(w)).toList();
    return mobile.isNotEmpty ? mobile : wallets;
  }

  Future<void> _pickPaymentReceipt() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _receiptFile = file);
      }
    } catch (e) {
      if (mounted) {
        MediaPermissionHelper.handlePickerError(e, context: context);
      }
    }
  }

  Future<void> _submitPaymentProof({required bool isAr}) async {
    if (_submittingPayment) return;
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى إرفاق لقطة شاشة للتحويل أولاً'
                : 'Please attach the transfer screenshot first',
          ),
        ),
      );
      return;
    }
    setState(() => _submittingPayment = true);
    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .markPaymentPaid(
            widget.state.orderId,
            receiptPath: _receiptFile!.path,
          );
      if (!mounted) return;
      if (success) {
        setState(() => _receiptFile = null);
        widget.onPaymentSubmitted?.call();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isAr
                      ? 'تم إرسال تأكيد التحويل بنجاح!'
                      : 'Transfer confirmation sent!')
                : (isAr
                      ? 'فشل إرسال التأكيد. حاول مرة أخرى.'
                      : 'Confirmation failed. Please try again.'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingPayment = false);
    }
  }

  Widget _buildInlinePendingPaymentCard(
    BuildContext context, {
    required Map<String, dynamic> order,
    required Map<String, dynamic> driver,
    required String currency,
    required bool isAr,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final upfront =
        double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0;
    final total =
        double.tryParse(
          (order['grandTotal'] ?? order['total'])?.toString() ?? '0',
        ) ??
        0.0;
    final isUpfront =
        (order['paymentMethod']?.toString() ?? '') == 'CASH_ON_DELIVERY' &&
        upfront > 0;
    final amountDue = isUpfront ? upfront : total;
    final paidClaimed =
        (order['paymentStatus']?.toString().toUpperCase() ?? '') == 'PAID';
    final wallets = _visibleDriverWallets(driver);

    const accent = Color(0xFFD97706);

    return Container(
      key: const ValueKey('inline_pending_payment_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUpfront
                          ? (isAr
                                ? 'المبلغ المقدم المطلوب أولاً'
                                : 'Upfront deposit required')
                          : (isAr
                                ? 'المبلغ المطلوب تحويله'
                                : 'Wallet transfer required'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${amountDue.toStringAsFixed(0)} $currency',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'حوّل المبلغ إلى محفظة الكابتن ثم أرفق لقطة شاشة للإيصال لبدء الرحلة.'
                : "Transfer the amount to your driver's mobile wallet and upload the receipt screenshot to proceed.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...wallets.map((w) {
              final number =
                  (w['number'] ?? w['walletNumber'] ?? '').toString().trim();
              final isInsta = (w['type'] ?? w['provider'] ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('INSTAPAY');
              final providerLabel = isInsta
                  ? (isAr ? 'إنستا باي' : 'InstaPay')
                  : (isAr ? 'محفظة إلكترونية' : 'Mobile Wallet');
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            number,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (number.isNotEmpty)
                      IconButton(
                        tooltip: isAr ? 'نسخ الرقم' : 'Copy number',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: number));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr ? 'تم نسخ رقم المحفظة' : 'Wallet copied',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          if (paidClaimed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'تم إرسال تأكيدك. بانتظار تأكيد الكابتن استلام المبلغ.'
                          : 'Confirmation sent. Waiting for your driver to verify receipt.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: _submittingPayment ? null : _pickPaymentReceipt,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 19),
              label: Text(
                _receiptFile != null
                    ? (_receiptFile!.name.isNotEmpty
                          ? _receiptFile!.name
                          : (isAr ? 'تم إرفاق الإيصال' : 'Receipt attached'))
                    : (isAr
                          ? 'إرفاق لقطة شاشة التحويل (مطلوب)'
                          : 'Attach transfer screenshot (required)'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_receiptFile != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_receiptFile!.path),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ElevatedButton.icon(
                onPressed: _submittingPayment
                    ? null
                    : () => _submitPaymentProof(isAr: isAr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _submittingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  isUpfront
                      ? (isAr
                            ? 'لقد دفعت المبلغ المقدم'
                            : 'I have paid the upfront amount')
                      : (isAr
                            ? 'لقد حوّلت المبلغ'
                            : 'I have transferred the amount'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({
    String key,
    IconData icon,
    Color accent,
    String title,
    String subtitle,
    bool emphasize,
  })
  _resolveJourneyBanner(BuildContext context, CustomDeliverySearchState state) {
    if (state.isAwaitingPayment) {
      return (
        key: 'awaiting_payment',
        icon: Icons.account_balance_wallet_rounded,
        accent: Colors.deepPurple,
        title: 'app.driverFoundTitle'.tr(context: context),
        subtitle: 'app.driverAwaitingPaymentStatus'.tr(context: context),
        emphasize: false,
      );
    }
    if (state.isDriverArrived) {
      return (
        key: 'driver_arrived',
        icon: Icons.where_to_vote_rounded,
        accent: AppColors.success,
        title: 'app.driverArrivedTitle'.tr(context: context),
        subtitle: (state.isRide
                ? 'app.driverArrivedRideSubtitle'
                : 'app.driverArrivedDeliverySubtitle')
            .tr(context: context),
        emphasize: true,
      );
    }
    if (state.isTripInProgress) {
      return (
        key: 'trip_in_progress_${state.isRide}',
        icon: _vehicleIcon(
          (state.driver?['vehicleType'] ?? state.requestedVehicleType)
              .toString(),
        ),
        accent: AppColors.success,
        title: (state.isRide
                ? 'app.rideStartedTitle'
                : 'app.deliveryOnItsWayTitle')
            .tr(context: context),
        subtitle: (state.isRide
                ? 'app.rideStartedSubtitle'
                : 'app.deliveryOnItsWaySubtitle')
            .tr(context: context),
        emphasize: true,
      );
    }
    if (state.isTripCompleted) {
      return (
        key: 'trip_completed_${state.isRide}',
        icon: Icons.check_circle_rounded,
        accent: AppColors.success,
        title: (state.isRide
                ? 'app.rideCompletedTitle'
                : 'app.deliveryCompletedTitle')
            .tr(context: context),
        subtitle: (state.isRide
                ? 'app.rideCompletedSubtitle'
                : 'app.deliveryCompletedSubtitle')
            .tr(context: context),
        emphasize: true,
      );
    }
    return (
      key: 'driver_assigned',
      icon: Icons.verified_rounded,
      accent: AppColors.success,
      title: 'app.driverFoundTitle'.tr(context: context),
      subtitle: 'app.driverAcceptedStatus'.tr(context: context),
      emphasize: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';
    final state = widget.state;
    final order = state.order ?? const <String, dynamic>{};
    final orderType = OrderTypeHelper.resolve(
      state.order ?? {'type': state.isRide ? 'RIDE' : 'CUSTOM_DELIVERY'},
    );
    final driver = state.driver ?? const <String, dynamic>{};
    final user = driver['user'] is Map
        ? Map<String, dynamic>.from(driver['user'] as Map)
        : const <String, dynamic>{};

    final driverName =
        (driver['name'] ??
                driver['fullName'] ??
                user['name'] ??
                user['fullName'] ??
                '')
            .toString()
            .trim();
    final avatarUrl =
        (driver['avatar'] ??
                driver['avatarUrl'] ??
                user['avatar'] ??
                user['avatarUrl'])
            ?.toString();
    final driverPhone =
        (driver['phone'] ?? user['phone'])?.toString().trim() ?? '';
    final vehicleType =
        (driver['vehicleType'] ?? order['requestedVehicleType'] ?? '')
            .toString();
    final vehiclePlate = (driver['vehiclePlate'] ?? '').toString().trim();
    final ratingCount = (driver['ratingCount'] as num?)?.toInt() ?? 0;
    final rawRating = (driver['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingValue = rawRating > 5 ? rawRating / 100.0 : rawRating;
    final isPendingPayment = state.isAwaitingPayment;
    final banner = _resolveJourneyBanner(context, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.06),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(banner.key),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: banner.accent.withValues(
                alpha: banner.emphasize ? (isDark ? 0.22 : 0.14) : 0.12,
              ),
              borderRadius: BorderRadius.circular(16),
              border: banner.emphasize
                  ? Border.all(
                      color: banner.accent.withValues(alpha: 0.45),
                      width: 1.4,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: banner.accent.withValues(
                      alpha: banner.emphasize ? 0.20 : 0.14,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    banner.icon,
                    color: banner.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: banner.emphasize
                              ? (isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        banner.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppNetworkAvatar(
                    imageUrl: ImageUtils.formatImageUrl(avatarUrl),
                    size: 56,
                    borderRadius: 28,
                    fallbackIcon: Icons.person_rounded,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (driverName.isNotEmpty)
                          Text(
                            driverName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (ratingCount > 0)
                              _MetricPill(
                                icon: Icons.star_rounded,
                                label:
                                    '${ratingValue.toStringAsFixed(1)} ${'app.driverRatingsCount'.tr(context: context, namedArgs: {'count': '$ratingCount'})}',
                                color: Colors.amber.shade700,
                                isDark: isDark,
                              ),
                            if (vehicleType.isNotEmpty)
                              _MetricPill(
                                icon: _vehicleIcon(vehicleType),
                                label: _localizedVehicleLabel(
                                  vehicleType,
                                  isArabic: isAr,
                                ),
                                color: AppColors.primary,
                                isDark: isDark,
                              ),
                            if (vehiclePlate.isNotEmpty)
                              _MetricPill(
                                icon: Icons.confirmation_number_outlined,
                                label: vehiclePlate,
                                color: theme.colorScheme.secondary,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!state.isDriverArrived && !state.isTripCompleted) ...[
                const SizedBox(height: 12),
                ValueListenableBuilder<DriverLiveMarkerState?>(
                  valueListenable: widget.driverLocationListenable,
                  builder: (context, liveLoc, _) {
                    final distKm =
                        liveLoc?.distanceToPickupKm ??
                        state.searchStatus?.driverDistanceKm?.toDouble();
                    final liveEtaMinutes =
                        liveLoc?.etaMinutes ??
                        state.searchStatus?.driverEtaMinutes?.toInt();
                    if (distKm == null && liveEtaMinutes == null) {
                      return const SizedBox.shrink();
                    }
                    final distanceLabel = distKm != null
                        ? (state.isTripInProgress
                              ? 'app.distanceToDestinationKm'.tr(
                                  context: context,
                                  namedArgs: {
                                    'distance': distKm.toStringAsFixed(1),
                                  },
                                )
                              : 'app.driverDistanceAway'.tr(
                                  context: context,
                                  namedArgs: {
                                    'distance': distKm.toStringAsFixed(1),
                                  },
                                ))
                        : null;
                    final etaLabel = liveEtaMinutes != null
                        ? (state.isTripInProgress
                              ? 'app.etaToDestinationMin'.tr(
                                  context: context,
                                  namedArgs: {'minutes': '$liveEtaMinutes'},
                                )
                              : 'app.driverEtaApprox'.tr(
                                  context: context,
                                  namedArgs: {'minutes': '$liveEtaMinutes'},
                                ))
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (distanceLabel != null)
                            _MetricPill(
                              icon: state.isTripInProgress
                                  ? Icons.flag_rounded
                                  : Icons.near_me_rounded,
                              label: distanceLabel,
                              color: Colors.blueAccent,
                              isDark: isDark,
                            ),
                          if (etaLabel != null)
                            _MetricPill(
                              icon: Icons.schedule_rounded,
                              label: etaLabel,
                              color: AppColors.success,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ] else
                const SizedBox(height: 12),
              if (!state.isTripCompleted)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (driverPhone.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: OutlinedButton.icon(
                          onPressed: () => ExternalActionLauncher.callPhone(
                            driverPhone,
                            context: context,
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: Text('app.callDriver'.tr(context: context)),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: OutlinedButton.icon(
                        onPressed: _openingChat ? null : _openOrderChat,
                        icon: _openingChat
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                              ),
                        label: Text('app.chatWithDriver'.tr(context: context)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (isPendingPayment) ...[
          const SizedBox(height: 12),
          _buildInlinePendingPaymentCard(
            context,
            order: order,
            driver: driver,
            currency: widget.currency,
            isAr: isAr,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 14),
        if (state.order != null) ...[
          _buildOrderRouteAndFareSummary(
            context,
            state.order!,
            currency: widget.currency,
            isAr: isAr,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],
        if (state.isTripCompleted) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: ElevatedButton.icon(
              onPressed: state.order == null
                  ? null
                  : () {
                      RateOrderBottomSheet.show(
                        context,
                        state.orderId,
                        order: state.order,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.star_rounded),
              label: Text(
                OrderTypeHelper.rateActionLabel(orderType, isArabic: isAr),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: OutlinedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text('app.backToHome'.tr(context: context)),
            ),
          ),
        ],
      ],
    );
  }
}

class _TerminalSearchSheetView extends StatelessWidget {
  const _TerminalSearchSheetView({
    super.key,
    required this.state,
    required this.onRetrySearch,
    required this.onEditRequest,
    required this.currency,
  });

  final CustomDeliverySearchState state;
  final VoidCallback onRetrySearch;
  final VoidCallback onEditRequest;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';
    final phase = state.phase;

    final IconData icon;
    final Color color;
    final String title;
    final String description;

    if (phase == DriverSearchPhase.NO_DRIVERS_AVAILABLE) {
      icon = Icons.location_off_rounded;
      color = Colors.orange.shade700;
      title = 'app.noDriversFoundTitle'.tr(context: context);
      description = 'app.noDriversFoundDesc'.tr(context: context);
    } else if (phase == DriverSearchPhase.SEARCH_TIMEOUT) {
      icon = Icons.timer_off_rounded;
      color = Colors.deepOrange;
      title = 'app.searchTimedOutTitle'.tr(context: context);
      description = 'app.searchTimedOutDesc'.tr(context: context);
    } else {
      icon = Icons.cancel_outlined;
      color = AppColors.error;
      title = 'app.searchCancelledTitle'.tr(context: context);
      final actor = state.order != null
          ? OrderActivityHelper.resolveCancelledBy(state.order!)
          : null;
      if (actor != null && (actor.reason?.isNotEmpty ?? false)) {
        description = '${actor.displayName(isArabic: isAr)}: ${actor.reason!}';
      } else {
        description = 'app.searchCancelledDesc'.tr(context: context);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (state.order != null) ...[
          _buildOrderRouteAndFareSummary(
            context,
            state.order!,
            currency: currency,
            isAr: isAr,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
        if (state.canRetry)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: ElevatedButton(
              onPressed: state.isRetrying ? null : onRetrySearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: state.isRetrying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'app.retryingSearch'.tr(context: context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'app.retrySearch'.tr(context: context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: OutlinedButton.icon(
            onPressed: state.isRetrying ? null : onEditRequest,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
            label: Text(
              'app.editRequestDetails'.tr(context: context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Isolated timer bar for the active offer wave so per-second countdown ticks
/// never trigger rebuilds on parent search cards or the map.
class _WaveCountdownBar extends StatefulWidget {
  const _WaveCountdownBar({
    required this.waveExpiresAtIso,
    required this.totalSecs,
    required this.accentColor,
  });

  final String? waveExpiresAtIso;
  final int totalSecs;
  final Color accentColor;

  @override
  State<_WaveCountdownBar> createState() => _WaveCountdownBarState();
}

class _WaveCountdownBarState extends State<_WaveCountdownBar> {
  Timer? _timer;
  int _remainingSecs = 0;
  DateTime? _targetTime;

  @override
  void initState() {
    super.initState();
    _syncTarget();
  }

  @override
  void didUpdateWidget(covariant _WaveCountdownBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waveExpiresAtIso != widget.waveExpiresAtIso ||
        oldWidget.totalSecs != widget.totalSecs) {
      _syncTarget();
    }
  }

  void _syncTarget() {
    _timer?.cancel();
    _timer = null;
    final raw = widget.waveExpiresAtIso;
    _targetTime = raw != null && raw.isNotEmpty ? DateTime.tryParse(raw) : null;
    _updateRemaining();
    if (_targetTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _updateRemaining();
      });
    }
  }

  void _updateRemaining() {
    final target = _targetTime;
    final next = target == null
        ? 0
        : target.difference(DateTime.now()).inSeconds.clamp(0, 3600);
    if (next != _remainingSecs && mounted) {
      setState(() => _remainingSecs = next);
    } else {
      _remainingSecs = next;
    }
    if (next <= 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalSecs > 0 ? widget.totalSecs : 30;
    final hasActiveWindow = _targetTime != null && _remainingSecs > 0;
    final fraction = hasActiveWindow
        ? (_remainingSecs / total).clamp(0.0, 1.0)
        : null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: widget.accentColor.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
          if (hasActiveWindow) ...[
            const SizedBox(height: 6),
            Text(
              'app.searchWaveTimeRemaining'.tr(
                context: context,
                namedArgs: {'seconds': '$_remainingSecs'},
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildOrderRouteAndFareSummary(
  BuildContext context,
  Map<String, dynamic> order, {
  required String currency,
  required bool isAr,
  required bool isDark,
}) {
  final orderType = OrderTypeHelper.resolve(order);
  final pickupAddr = (order['pickupAddress'] ?? '').toString().trim();
  final dropoffAddr = (order['deliveryAddress'] ?? '').toString().trim();
  final itemDetails = (order['itemDetails'] ?? '').toString().trim();
  final specialRequest = (order['specialRequest'] ?? '').toString().trim();
  final grandTotal = (order['grandTotal'] as num?)?.toDouble();
  final distanceKm = (order['distanceKm'] as num?)?.toDouble();
  final paymentMethod = (order['paymentMethod'] ?? 'CASH_ON_DELIVERY')
      .toString();
  final vehicle = (order['requestedVehicleType'] ?? '').toString();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RouteEndpointsCard(
        pickupLabel: (orderType.isRide
                ? 'app.ridePickupPointLabel'
                : 'app.pickupPointLabel')
            .tr(context: context),
        pickupAddress: pickupAddr.isEmpty ? '-' : pickupAddr,
        dropoffLabel: (orderType.isRide
                ? 'app.rideDropoffPointLabel'
                : 'app.dropoffPointLabel')
            .tr(context: context),
        dropoffAddress: dropoffAddr.isEmpty ? '-' : dropoffAddr,
        pickupColor: AppColors.primary,
        dropoffColor: Colors.redAccent,
        itemDetailsLabel: isAr ? 'تفاصيل الشحنة' : 'Package Details',
        itemDetails: (!orderType.isRide && itemDetails.isNotEmpty)
            ? itemDetails
            : null,
        notesLabel: isAr ? 'ملاحظات إضافية' : 'Special Notes',
        notes: specialRequest.isNotEmpty ? specialRequest : null,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          if (grandTotal != null)
            _MetricPill(
              icon: Icons.payments_outlined,
              label: '${grandTotal.toStringAsFixed(0)} $currency',
              color: AppColors.success,
              isDark: isDark,
            ),
          if (distanceKm != null && distanceKm > 0)
            _MetricPill(
              icon: Icons.route_rounded,
              label: '${distanceKm.toStringAsFixed(1)} km',
              color: Colors.indigo,
              isDark: isDark,
            ),
          if (vehicle.isNotEmpty)
            _MetricPill(
              icon: _vehicleIcon(vehicle),
              label: _localizedVehicleLabel(vehicle, isArabic: isAr),
              color: AppColors.primary,
              isDark: isDark,
            ),
          _MetricPill(
            icon: paymentMethod == 'MOBILE_WALLET'
                ? Icons.account_balance_wallet_outlined
                : Icons.money_rounded,
            label: OrderTypeHelper.paymentMethodLabel(
              orderType,
              paymentMethod,
              isArabic: isAr,
            ),
            color: Colors.teal,
            isDark: isDark,
          ),
        ],
      ),
    ],
  );
}

({String label, String description, IconData icon, Color accent})
_resolvePhaseDisplay(BuildContext context, DriverSearchPhase phase) {
  if (phase == DriverSearchPhase.FINDING_DRIVERS) {
    return (
      label: 'app.findingDriversStatus'.tr(context: context),
      description: 'app.searchQueuedDesc'.tr(context: context),
      icon: Icons.manage_search_rounded,
      accent: AppColors.primary,
    );
  }
  if (phase == DriverSearchPhase.CONTACTING_DRIVERS) {
    return (
      label: 'app.contactingDriversStatus'.tr(context: context),
      description: 'app.searchActiveDesc'.tr(context: context),
      icon: Icons.podcasts_rounded,
      accent: Colors.deepOrange,
    );
  }
  if (phase == DriverSearchPhase.WAITING_DRIVER_RESPONSE) {
    return (
      label: 'app.waitingDriverResponseStatus'.tr(context: context),
      description: 'app.searchActiveDesc'.tr(context: context),
      icon: Icons.hourglass_top_rounded,
      accent: Colors.blueAccent,
    );
  }
  if (phase == DriverSearchPhase.NO_DRIVERS_IN_WAVE) {
    return (
      label: 'app.expandingSearchStatus'.tr(context: context),
      description: 'app.searchQueuedDesc'.tr(context: context),
      icon: Icons.radar_rounded,
      accent: Colors.amber.shade700,
    );
  }
  return (
    label: 'app.searchQueuedStatus'.tr(context: context),
    description: 'app.searchQueuedDesc'.tr(context: context),
    icon: Icons.sync_rounded,
    accent: AppColors.primary,
  );
}

IconData _vehicleIcon(String vehicle) => VehicleTypeHelper.icon(vehicle);

String _localizedVehicleLabel(String vehicle, {required bool isArabic}) =>
    VehicleTypeHelper.label(vehicle, isArabic: isArabic);
