import 'package:core/core.dart' show ApiErrorMapper, VehicleTypeHelper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../orders/presentation/providers/custom_delivery_search_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/location_picker_map.dart';

class CustomDeliveryScreen extends ConsumerStatefulWidget {
  const CustomDeliveryScreen({super.key, this.initialDraft});

  final CustomDeliveryDraft? initialDraft;

  @override
  ConsumerState<CustomDeliveryScreen> createState() => _CustomDeliveryScreenState();
}

class _CustomDeliveryScreenState extends ConsumerState<CustomDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _detailsController = TextEditingController();
  final _specialRequestController = TextEditingController();

  String _selectedVehicle = 'motorcycle';
  String _serviceType = 'delivery'; // 'delivery' or 'ride'
  String _paymentMethod = 'CASH_ON_DELIVERY';
  bool _isExpanded = false;
  bool _useCoins = false;
  bool _isEstimating = false;
  bool _estimateFailed = false;
  String? _estimateErrorKey;
  bool _isSubmitting = false;
  Map<String, dynamic>? _estimate;
  String? _lastEstimateKey;
  int _estimateRequestSeq = 0;
  String? _clientOrderKey;

  String _clientOrderKeyForCheckout() =>
      _clientOrderKey ??= generateClientOrderKey();

  void _invalidateOrderIntent() {
    _clientOrderKey = null;
  }

  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      _serviceType = draft.serviceType;
      _selectedVehicle = draft.vehicleType;
      _pickupController.text = draft.pickupAddress;
      _dropoffController.text = draft.dropoffAddress;
      _detailsController.text = draft.itemDetails ?? '';
      _specialRequestController.text = draft.specialRequest ?? '';
      _pickupLocation = draft.pickupLocation;
      _dropoffLocation = draft.dropoffLocation;
      _paymentMethod = draft.paymentMethod;
      _useCoins = draft.useCoins;
    }
  }

  List<String> _enabledVehicles(
    String serviceType,
    PlatformSettingsData? settings,
  ) {
    final codes = settings != null
        ? settings.enabledVehiclesForService(serviceType)
        : VehicleTypeHelper.eligibleForOrderType(serviceType);
    return codes.map((c) => c.toLowerCase()).toList(growable: false);
  }

  String? _reconciledVehicle(
    String serviceType,
    PlatformSettingsData? settings,
  ) {
    final enabled = _enabledVehicles(serviceType, settings);
    if (enabled.isEmpty) return null;
    final current = _selectedVehicle.trim().toLowerCase();
    if (enabled.contains(current)) return current;
    return enabled.first;
  }

  Future<void> _fetchEstimate({bool force = false}) async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      if (_estimate != null || _estimateFailed || _isEstimating) {
        _estimateRequestSeq++;
        _lastEstimateKey = null;
        if (mounted) {
          setState(() {
            _estimate = null;
            _estimateFailed = false;
            _isEstimating = false;
          });
        }
      }
      return;
    }

    final settings = ref.read(platformSettingsProvider).value;
    final activeVehicle = _reconciledVehicle(_serviceType, settings);
    if (activeVehicle == null) {
      if (_estimate != null && mounted) {
        setState(() {
          _estimate = null;
          _estimateFailed = false;
          _lastEstimateKey = null;
        });
      }
      return;
    }
    if (activeVehicle != _selectedVehicle) {
      _selectedVehicle = activeVehicle;
    }

    final detailsText = _detailsController.text.trim();

    // Coins change the quoted grandTotal server-side, so the computed value
    // (not just the toggle) is part of the key — same capping math as submit.
    int? coinsToUse;
    if (_useCoins) {
      final coinState = ref.read(coinHistoryProvider);
      if (settings != null &&
          coinState.currentBalance >= settings.minCoinsToUse) {
        coinsToUse = coinState.currentBalance;
      }
    }

    final estimateKey =
        '$_serviceType|$_selectedVehicle|$_paymentMethod|${_pickupLocation!.longitude},${_pickupLocation!.latitude}|${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}|${coinsToUse ?? 0}';
    if (!force && estimateKey == _lastEstimateKey) return;
    _lastEstimateKey = estimateKey;

    final requestSeq = ++_estimateRequestSeq;
    if (mounted) {
      setState(() {
        _isEstimating = true;
        _estimateFailed = false;
        _estimateErrorKey = null;
      });
    }

    Map<String, dynamic>? result;
    final ordersNotifier = ref.read(ordersProvider.notifier);
    try {
      result = await ordersNotifier.estimateCustomOrder(
        type: _serviceType,
        pickup: _pickupController.text.trim().isEmpty
            ? 'Pickup'
            : _pickupController.text.trim(),
        pickupLocation: [_pickupLocation!.longitude, _pickupLocation!.latitude],
        dropoff: _dropoffController.text.trim().isEmpty
            ? 'Dropoff'
            : _dropoffController.text.trim(),
        deliveryLocation: [
          _dropoffLocation!.longitude,
          _dropoffLocation!.latitude,
        ],
        vehicleType: _selectedVehicle,
        details: detailsText.isEmpty ? null : detailsText,
        paymentMethod: _paymentMethod,
        coinsToUse: coinsToUse,
      );
    } finally {
      if (mounted && requestSeq == _estimateRequestSeq) {
        setState(() {
          _estimate = result;
          _estimateFailed = result == null;
          _estimateErrorKey =
              result == null ? ordersNotifier.lastCustomEstimateErrorKey : null;
          if (result == null) {
            _lastEstimateKey = null;
          }
          _isEstimating = false;
        });
      }
    }
  }

  String _formatMoney(double amount, String currency) {
    final rounded = amount.roundToDouble();
    final formatted = (amount - rounded).abs() < 0.005
        ? rounded.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$formatted $currency';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _detailsController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      if (_pickupLocation == null || _dropoffLocation == null) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'يرجى تحديد موقع الاستلام والتسليم' : 'Please select pickup and dropoff locations')));
        return;
      }
      if (_estimate == null || _isEstimating) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'يرجى الانتظار حتى يتم حساب الأجرة' : 'Please wait until the fare is calculated')));
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final pickup = _pickupController.text.trim();
        final dropoff = _dropoffController.text.trim();
        final details = _detailsController.text.trim();
        final specialRequest = _specialRequestController.text.trim();

        final coinState = ref.read(coinHistoryProvider);
        final settings = ref.read(platformSettingsProvider).value;
        final activeVehicle = _reconciledVehicle(_serviceType, settings);
        if (activeVehicle == null) {
          final s = AppStrings.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.isArabic
                    ? 'لا توجد مركبات متاحة لهذه الخدمة حالياً'
                    : 'No vehicles are currently available for this service',
              ),
            ),
          );
          return;
        }
        _selectedVehicle = activeVehicle;

        int? coinsToUse;
        if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
          // Same rule as the estimate: offer the full balance and let the
          // backend cap it at the grand total (keeps placement == estimate).
          coinsToUse = coinState.currentBalance;
        }

        final outcome = await ref.read(ordersProvider.notifier).placeCustomOrderDetailed(
          type: _serviceType,
          pickup: pickup,
          pickupLocation: [_pickupLocation!.longitude, _pickupLocation!.latitude],
          dropoff: dropoff,
          deliveryLocation: [_dropoffLocation!.longitude, _dropoffLocation!.latitude],
          details: details.isEmpty ? null : details,
          specialRequest: specialRequest.isEmpty ? null : specialRequest,
          paymentMethod: _paymentMethod,
          vehicleType: _selectedVehicle,
          coinsToUse: coinsToUse,
          idempotencyKey: _clientOrderKeyForCheckout(),
        );

        if (!mounted) return;

        if (outcome.isSuccess && outcome.orderId != 'SUCCESS') {
          _clientOrderKey = null;
          context.go('/home');
          context.push(
            '/order-search/${outcome.orderId}',
            extra: outcome.order,
          );
        } else if (outcome.isSuccess) {
          _clientOrderKey = null;
          context.go('/home');
          context.push('/orders');
        } else {
          final errorMsg = outcome.errorKey != null
              ? ApiErrorMapper.translate(outcome.errorKey!, context: context)
              : (AppStrings.of(context).isArabic
                  ? 'فشل إتمام الطلب'
                  : 'Failed to place order');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hasBothLocations = _pickupLocation != null && _dropoffLocation != null;
    if (hasBothLocations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchEstimate();
      });
    }

    final isAr = s.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinState = ref.watch(coinHistoryProvider);
    final settings = ref.watch(platformSettingsProvider).value;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _serviceType == 'ride'
              ? (isAr ? 'طلب رحلة' : 'Request Ride')
              : s.customDeliveryTitle,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: isAr ? 0 : -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildForm(s, isAr, coinState, settings, isDark),
      ),
    );
  }

  Widget _buildForm(
    AppStrings s,
    bool isAr,
    CoinHistoryState coinState,
    PlatformSettingsData? settings,
    bool isDark,
  ) {
    final hasBothLocations = _pickupLocation != null && _dropoffLocation != null;
    final est = _estimate;
    final hasEstimate = est != null && hasBothLocations;
    final estDistanceKm = hasEstimate
        ? (est['distanceKm'] as num?)?.toDouble()
        : null;
    final estDeliveryFee = hasEstimate
        ? ((est['deliveryFee'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estServiceFee = hasEstimate
        ? ((est['serviceFee'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estTax = hasEstimate
        ? ((est['tax'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estDriverBonusFee = hasEstimate
        ? ((est['driverBonusFee'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estDriverBonusPaidByCustomer =
        hasEstimate && est['driverBonusPaidByCustomer'] == true;
    final estDiscount = hasEstimate
        ? ((est['discount'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estUpfrontAmount = hasEstimate
        ? ((est['upfrontAmount'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final estGrandTotal = hasEstimate
        ? (est['grandTotal'] as num?)?.toDouble()
        : null;
    final isWalletPayment = _paymentMethod == 'MOBILE_WALLET';
    final isRide = _serviceType == 'ride';
    final canUseCoins =
        coinState.currentBalance > 0 &&
        settings != null &&
        coinState.currentBalance >= settings.minCoinsToUse;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSwitcher(s, isDark),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Text(
                      _serviceType == 'delivery' ? s.customCourierDesc : s.rideServiceDesc,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      maxLines: _isExpanded ? 10 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? s.readLess : s.readMore,
                      textAlign: isAr ? TextAlign.left : TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(_serviceType == 'ride' ? s.yourLocation : s.pickupLocation, isDark),
                  _buildLocationField(
                    controller: _pickupController,
                    hint: _serviceType == 'ride' ? s.whereAreYou : s.wherePickUp,
                    icon: _serviceType == 'ride' ? Icons.person_pin_circle_rounded : Icons.my_location_rounded,
                    isDark: isDark,
                    isPickup: true,
                    validator: (v) => v == null || v.isEmpty ? s.required : null,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(_serviceType == 'ride' ? s.destination : s.dropoffLocation, isDark),
                  _buildLocationField(
                    controller: _dropoffController,
                    hint: _serviceType == 'ride' ? s.whereToGo : s.wherePackageGoing,
                    icon: _serviceType == 'ride' ? Icons.flag_rounded : Icons.location_on_rounded,
                    isDark: isDark,
                    isPickup: false,
                    validator: (v) => v == null || v.isEmpty ? s.required : null,
                  ),
                  if (_serviceType == 'delivery') ...[
                    const SizedBox(height: 24),
                    _buildLabel(s.itemDetails, isDark),
                    _buildTextField(
                      controller: _detailsController,
                      hint: s.enterItemDetails,
                      icon: Icons.inventory_2_outlined,
                      maxLines: 3,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? s.required : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildLabel(isAr ? 'ملاحظات إضافية (اختياري)' : 'Additional Notes (Optional)', isDark),
                  _buildTextField(
                    controller: _specialRequestController,
                    hint: isAr ? 'مثال: قابل للكسر، اتصل عند الوصول' : 'e.g. Fragile item, call on arrival',
                    icon: Icons.note_alt_outlined,
                    maxLines: 2,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(isAr ? 'طريقة الدفع' : 'Payment Method', isDark),
                  const SizedBox(height: 6),
                  _buildPaymentMethodSelector(isAr, isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLabel(s.vehicleType, isDark),
            const SizedBox(height: 12),
            _buildVehicleSelector(s, isDark),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasEstimate
                      ? AppColors.primary.withValues(alpha: 0.30)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isRide
                              ? (isAr ? 'الأجرة النهائية للرحلة' : 'Final Ride Fare')
                              : (isAr ? 'الأجرة النهائية للتوصيل' : 'Final Delivery Fare'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (hasEstimate &&
                          estDistanceKm != null &&
                          estDistanceKm > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.route_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${estDistanceKm.toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!hasBothLocations)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isRide
                                  ? (isAr
                                      ? 'حدد نقطة الركوب والوجهة لعرض الأجرة النهائية مباشرة'
                                      : 'Select pickup and destination to see your final fare')
                                  : (isAr
                                      ? 'حدد موقع الاستلام والتسليم لعرض الأجرة النهائية مباشرة'
                                      : 'Select pickup and dropoff locations to see your final fare'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isEstimating)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              isAr
                                  ? 'جاري حساب الأجرة النهائية...'
                                  : 'Calculating final fare...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_estimateFailed || !hasEstimate)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _fetchEstimate(force: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _estimateErrorKey != null
                                    ? '${ApiErrorMapper.translate(_estimateErrorKey!, context: context)} • ${isAr ? 'اضغط لإعادة المحاولة' : 'Tap to retry'}'
                                    : (isAr
                                        ? 'تعذر حساب الأجرة. اضغط لإعادة المحاولة'
                                        : 'Could not calculate fare. Tap to retry'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _priceRow(
                      isRide
                          ? (isAr ? 'أجرة الرحلة' : 'Ride Fare')
                          : (isAr ? 'رسوم التوصيل' : 'Delivery Fare'),
                      _formatMoney(estDeliveryFee, s.egp),
                      isDark,
                    ),
                    if (estServiceFee > 0) ...[
                      const SizedBox(height: 8),
                      _priceRow(
                        isAr ? 'رسوم الخدمة' : 'Service Fee',
                        _formatMoney(estServiceFee, s.egp),
                        isDark,
                      ),
                    ],
                    if (estDriverBonusPaidByCustomer &&
                        estDriverBonusFee > 0) ...[
                      const SizedBox(height: 8),
                      _priceRow(
                        isAr ? 'مكافأة إضافية للكابتن' : 'Driver Bonus',
                        _formatMoney(estDriverBonusFee, s.egp),
                        isDark,
                      ),
                    ],
                    if (estTax > 0) ...[
                      const SizedBox(height: 8),
                      _priceRow(
                        isAr ? 'الضرائب والرسوم' : 'Taxes & Fees',
                        _formatMoney(estTax, s.egp),
                        isDark,
                      ),
                    ],
                  ],
                  if (canUseCoins) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFB300),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'استخدام ${coinState.currentBalance} عملة'
                                      : 'Use ${coinState.currentBalance} Coins',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _useCoins,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _useCoins = val;
                              _invalidateOrderIntent();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  if (_useCoins && estDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _priceRow(
                      isAr ? 'خصم العملات' : 'Coin Discount',
                      '-${_formatMoney(estDiscount, s.egp)}',
                      isDark,
                      valueColor: AppColors.success,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.total,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _isEstimating
                              ? '...'
                              : (estGrandTotal != null
                                  ? _formatMoney(estGrandTotal, s.egp)
                                  : '—'),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: AppColors.primary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasEstimate) ...[
                    if (!isWalletPayment && estUpfrontAmount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(
                            alpha: isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 17,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'مطلوب تحويل مقدم بقيمة ${_formatMoney(estUpfrontAmount, s.egp)} إلى محفظة الكابتن بعد قبول الطلب، والباقي نقداً.'
                                    : 'An upfront deposit of ${_formatMoney(estUpfrontAmount, s.egp)} is transferred to your driver\'s wallet after acceptance; pay the rest in cash.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.amber.shade200
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      isWalletPayment
                          ? (isAr
                              ? 'الأجرة النهائية شاملة جميع الرسوم والضرائب. ستحوّل المبلغ إلى محفظة الكابتن مباشرة بعد قبول الطلب.'
                              : 'Final fare includes all fees and taxes. You will transfer to your driver\'s wallet once accepted.')
                          : (estUpfrontAmount > 0
                              ? (isAr
                                  ? 'الأجرة النهائية شاملة جميع الرسوم والضرائب.'
                                  : 'Final fare includes all fees and taxes.')
                              : (isAr
                                  ? 'الأجرة النهائية شاملة جميع الرسوم والضرائب ومؤكدة مباشرة دون خطوة دفع إضافية.'
                                  : 'Final fare includes all fees and taxes — confirmed directly with no extra checkout step.')),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_isSubmitting ||
                      _isEstimating ||
                      _estimate == null ||
                      _pickupLocation == null ||
                      _dropoffLocation == null ||
                      _enabledVehicles(
                        _serviceType,
                        settings,
                      ).isEmpty)
                  ? null
                  : _submitOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade400,
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _serviceType == 'ride' ? (isAr ? 'اطلب الآن' : 'Request Now') : s.requestCourier,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher(AppStrings s, bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _switcherButton(s.delivery, 'delivery', isDark),
              _switcherButton(s.ride, 'ride', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switcherButton(String label, String value, bool isDark) {
    final isSelected = _serviceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_serviceType == value) return;
          final settings = ref.read(platformSettingsProvider).value;
          final nextVehicle = _reconciledVehicle(value, settings);
          setState(() {
            _serviceType = value;
            if (nextVehicle != null) {
              _selectedVehicle = nextVehicle;
            }
            _estimate = null;
            _lastEstimateKey = null;
            _invalidateOrderIntent();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isSelected ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(AppStrings s, bool isDark) {
    final platformSettings = ref.watch(platformSettingsProvider).value;
    final enabledVehicles = _enabledVehicles(_serviceType, platformSettings);

    if (enabledVehicles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.isArabic
                    ? 'لا توجد مركبات متاحة لهذه الخدمة حالياً'
                    : 'No vehicles are currently available for this service',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!enabledVehicles.contains(_selectedVehicle)) {
      final fallback = enabledVehicles.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedVehicle == fallback) return;
        setState(() {
          _selectedVehicle = fallback;
          _estimate = null;
          _lastEstimateKey = null;
          _invalidateOrderIntent();
        });
      });
    }

    final activeSelection = enabledVehicles.contains(_selectedVehicle)
        ? _selectedVehicle
        : enabledVehicles.first;

    final rows = <Widget>[];
    for (var i = 0; i < enabledVehicles.length; i += 2) {
      final firstCode = enabledVehicles[i];
      final secondCode =
          (i + 1 < enabledVehicles.length) ? enabledVehicles[i + 1] : null;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _vehicleOption(
                  label: VehicleTypeHelper.label(
                    firstCode,
                    isArabic: s.isArabic,
                  ),
                  fallbackIcon: VehicleTypeHelper.icon(firstCode),
                  type: firstCode,
                  isSelected: activeSelection == firstCode,
                  isDark: isDark,
                  customIconUrl: platformSettings?.iconUrlForVehicle(firstCode),
                ),
              ),
              const SizedBox(width: 12),
              if (secondCode != null)
                Expanded(
                  child: _vehicleOption(
                    label: VehicleTypeHelper.label(
                      secondCode,
                      isArabic: s.isArabic,
                    ),
                    fallbackIcon: VehicleTypeHelper.icon(secondCode),
                    type: secondCode,
                    isSelected: activeSelection == secondCode,
                    isDark: isDark,
                    customIconUrl:
                        platformSettings?.iconUrlForVehicle(secondCode),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _vehicleOption({
    required String label,
    required IconData fallbackIcon,
    required String type,
    required bool isSelected,
    required bool isDark,
    required String? customIconUrl,
  }) {
    final surfaceColor = isSelected
        ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50);
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? Colors.white12 : Colors.grey.shade200);
    final iconCircleBg = isSelected
        ? AppColors.primary
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white);
    final iconColor =
        isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.grey.shade700);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('vehicle_option_${_serviceType}_$type'),
        onTap: () {
          if (_selectedVehicle == type) return;
          setState(() {
            _selectedVehicle = type;
            _estimate = null;
            _lastEstimateKey = null;
            _invalidateOrderIntent();
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            children: [
              if (isSelected)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: iconCircleBg,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                              ),
                      ),
                      child: Center(
                        child: customIconUrl != null && customIconUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl:
                                      ImageUtils.formatImageUrl(customIconUrl),
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Icon(
                                    fallbackIcon,
                                    size: 28,
                                    color: iconColor,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    fallbackIcon,
                                    size: 28,
                                    color: iconColor,
                                  ),
                                ),
                              )
                            : Icon(fallbackIcon, size: 28, color: iconColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? AppColors.primary : Colors.black)
                            : (isDark ? Colors.white : Colors.black87),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(bool isAr, bool isDark) {
    Widget chip({
      required String value,
      required String label,
      required IconData icon,
    }) {
      final selected = _paymentMethod == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _paymentMethod = value;
            _invalidateOrderIntent();
          }),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chip(
            value: 'CASH_ON_DELIVERY',
            label: _serviceType == 'ride'
                ? (isAr ? 'نقدي' : 'Cash')
                : (isAr ? 'الدفع عند الاستلام' : 'Cash on Delivery'),
            icon: Icons.money_rounded,
          ),
          const SizedBox(width: 10),
          chip(
            value: 'MOBILE_WALLET',
            label: isAr ? 'محفظة إلكترونية' : 'Mobile Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4), 
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87))
  );

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    required bool isDark,
    int maxLines = 1, 
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.7), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: const BorderSide(color: AppColors.primary, width: 2)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: const BorderSide(color: Colors.red, width: 1)
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required bool isPickup,
    String? Function(String?)? validator,
  }) {
    final s = AppStrings.of(context);
    final hasCoord = isPickup ? _pickupLocation != null : _dropoffLocation != null;

    Future<void> openMapPicker() async {
      final result = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerMap(
            initialLocation: isPickup ? _pickupLocation : _dropoffLocation,
          ),
        ),
      );
      if (!mounted) return;
      if (result != null) {
        final strings = AppStrings.of(context);
        final defaultLabel =
            strings.isArabic ? 'تم تحديد الموقع' : 'Location selected';
        setState(() {
          _invalidateOrderIntent();
          if (isPickup) {
            _pickupLocation = result;
          } else {
            _dropoffLocation = result;
          }
          if (controller.text.trim().isEmpty) {
            controller.text = defaultLabel;
          }
        });
      }
    }

    return _buildTextField(
      controller: controller,
      hint: hint,
      icon: icon,
      isDark: isDark,
      validator: validator,
      readOnly: !hasCoord,
      onTap: hasCoord ? null : openMapPicker,
      suffixIcon: IconButton(
        tooltip: s.isArabic ? 'تحديد على الخريطة' : 'Pick on map',
        onPressed: openMapPicker,
        icon: Icon(
          hasCoord ? Icons.edit_location_alt_rounded : Icons.map_outlined,
          color: hasCoord ? AppColors.success : AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    String amount,
    bool isDark, {
    Color? valueColor,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          amount,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}
