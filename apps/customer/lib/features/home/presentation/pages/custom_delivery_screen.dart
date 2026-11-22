import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart' show ApiErrorMapper, VehicleTypeHelper;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/location_picker_map.dart';
import '../../../orders/presentation/providers/custom_delivery_search_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import '../widgets/special_delivery_tokens.dart';

class CustomDeliveryScreen extends ConsumerStatefulWidget {
  const CustomDeliveryScreen({super.key, this.initialDraft});

  final CustomDeliveryDraft? initialDraft;

  @override
  ConsumerState<CustomDeliveryScreen> createState() =>
      _CustomDeliveryScreenState();
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

  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  String _clientOrderKeyForCheckout() =>
      _clientOrderKey ??= generateClientOrderKey();

  void _invalidateOrderIntent() {
    _clientOrderKey = null;
  }

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

  void _showGoldToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final palette = SpecialDeliveryPalette.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: isError
                  ? SpecialDeliveryTokens.errorRed
                  : SpecialDeliveryTokens.gold,
              width: 1,
            ),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: isError
                    ? SpecialDeliveryTokens.errorRed
                    : SpecialDeliveryTokens.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: SpecialDeliveryTokens.text(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
        // PlaceCustomOrderDto validates itemDetails as @IsNotEmpty() for
        // CUSTOM_DELIVERY even on /orders/custom/estimate, although pricing
        // only depends on locations/vehicle/coins. _submitOrder still requires
        // the customer to enter real itemDetails before placing an order.
        details: _serviceType == 'delivery'
            ? (detailsText.isEmpty ? 'Custom delivery item' : detailsText)
            : (detailsText.isEmpty ? null : detailsText),
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
    return '$formatted ${currency.trim()}';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _detailsController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker({required bool isPickup}) async {
    final s = AppStrings.of(context);
    final isRide = _serviceType == 'ride';
    final title = isPickup
        ? (isRide ? s.yourLocation : s.pickupLocation)
        : (isRide ? s.destination : s.dropoffLocation);

    String? resolvedAddress;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: isPickup ? _pickupLocation : _dropoffLocation,
          title: title,
          onAddressResolved: (addr) => resolvedAddress = addr,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final strings = AppStrings.of(context);
    final fallbackLabel =
        strings.isArabic ? 'تم تحديد الموقع' : 'Location selected';
    final addressText =
        (resolvedAddress != null && resolvedAddress!.trim().isNotEmpty)
        ? resolvedAddress!.trim()
        : fallbackLabel;

    setState(() {
      _invalidateOrderIntent();
      if (isPickup) {
        _pickupLocation = result;
        _pickupController.text = addressText;
      } else {
        _dropoffLocation = result;
        _dropoffController.text = addressText;
      }
    });
  }

  void _clearLocation({required bool isPickup}) {
    setState(() {
      _invalidateOrderIntent();
      if (isPickup) {
        _pickupLocation = null;
        _pickupController.clear();
      } else {
        _dropoffLocation = null;
        _dropoffController.clear();
      }
      _estimate = null;
      _estimateFailed = false;
      _estimateErrorKey = null;
      _lastEstimateKey = null;
    });
  }

  void _submitOrder() async {
    if (_isSubmitting) return;
    final s = AppStrings.of(context);

    if (_pickupLocation == null || _dropoffLocation == null) {
      _showGoldToast(
        s.isArabic
            ? 'يرجى تحديد موقع الاستلام والتسليم'
            : 'Please select pickup and dropoff locations',
        isError: true,
      );
      return;
    }

    if (_serviceType == 'delivery' && _detailsController.text.trim().isEmpty) {
      _showGoldToast(
        s.isArabic
            ? 'يرجى إدخال تفاصيل الغرض المراد توصيله'
            : 'Please enter item details',
        isError: true,
      );
      return;
    }

    if (_estimate == null || _isEstimating) {
      _showGoldToast(
        s.isArabic
            ? 'يرجى الانتظار حتى يتم حساب الأجرة'
            : 'Please wait until the fare is calculated',
      );
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
        _showGoldToast(
          s.isArabic
              ? 'لا توجد مركبات متاحة لهذه الخدمة حالياً'
              : 'No vehicles are currently available for this service',
          isError: true,
        );
        return;
      }
      _selectedVehicle = activeVehicle;

      int? coinsToUse;
      if (_useCoins &&
          settings != null &&
          coinState.currentBalance >= settings.minCoinsToUse) {
        coinsToUse = coinState.currentBalance;
      }

      final outcome = await ref
          .read(ordersProvider.notifier)
          .placeCustomOrderDetailed(
            type: _serviceType,
            pickup: pickup,
            pickupLocation: [
              _pickupLocation!.longitude,
              _pickupLocation!.latitude,
            ],
            dropoff: dropoff,
            deliveryLocation: [
              _dropoffLocation!.longitude,
              _dropoffLocation!.latitude,
            ],
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
        _showGoldToast(errorMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = SpecialDeliveryPalette.of(context);
    final hasBothLocations =
        _pickupLocation != null && _dropoffLocation != null;

    if (hasBothLocations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchEstimate();
      });
    }

    final isAr = s.isArabic;
    final coinState = ref.watch(coinHistoryProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);
    final settings = settingsAsync.value;
    final isSettingsLoading = settingsAsync.isLoading && settings == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: palette.bgMain,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  // A. Top Header (50px fixed)
                  _buildHeader(s, isAr, palette),

                  // Zero-Scroll Body Container (flex-col justify-between overflow-hidden)
                  Expanded(
                    child: ClipRect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Form(
                          key: _formKey,
                          child: _buildZeroScrollBody(
                            s: s,
                            isAr: isAr,
                            coinState: coinState,
                            settings: settings,
                            isSettingsLoading: isSettingsLoading,
                            palette: palette,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A. Top Header (50px)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(AppStrings s, bool isAr, SpecialDeliveryPalette palette) {
    final title = _serviceType == 'ride'
        ? (isAr ? 'طلب رحلة' : 'Request Ride')
        : (isAr ? 'توصيل خاص' : s.customDeliveryTitle);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.headerBg,
        border: Border(
          bottom: BorderSide(color: palette.headerBorder, width: 1),
        ),
        boxShadow: [palette.headerShadow],
      ),
      child: Row(
        children: [
          TactileScaleTap(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.surfaceBorder),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SpecialDeliveryTokens.text(
                size: 15,
                weight: FontWeight.w900,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zero-Scroll Body Column (Sections B, C, D, E, F)
  // ---------------------------------------------------------------------------
  Widget _buildZeroScrollBody({
    required AppStrings s,
    required bool isAr,
    required CoinHistoryState coinState,
    required PlatformSettingsData? settings,
    required bool isSettingsLoading,
    required SpecialDeliveryPalette palette,
  }) {
    final hasBothLocations =
        _pickupLocation != null && _dropoffLocation != null;
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
    final estTax = hasEstimate ? ((est['tax'] as num?)?.toDouble() ?? 0.0) : 0.0;
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

    final enabledVehicles = _enabledVehicles(_serviceType, settings);
    final isSubmitEnabled =
        !_isSubmitting &&
        !_isEstimating &&
        _estimate != null &&
        hasBothLocations &&
        enabledVehicles.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        final isCompact = availH < 610;
        final isUltraCompact = availH < 560;
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final adaptiveGap = (viewportHeight * 0.0125).clamp(6.0, 12.0);
        final sectionGap = isUltraCompact
            ? 5.0
            : (isCompact ? 6.0 : adaptiveGap);

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // B. Mode Switcher (Segmented Control)
            _buildTypeSwitcher(s, palette, isCompact: isCompact),

            // C. Expandable Info Banner
            _buildInfoBanner(s, isAr, palette, isCompact: isCompact),

            // D. Locations, Item Details & Payment Card
            _buildMainFormCard(
              s,
              isAr,
              isRide,
              palette,
              isCompact: isCompact,
              isUltraCompact: isUltraCompact,
            ),

            // E. Vehicle Selection Grid (Backend-Driven, 4-Column Grid)
            _buildVehicleSection(
              s: s,
              isAr: isAr,
              settings: settings,
              isSettingsLoading: isSettingsLoading,
              enabledVehicles: enabledVehicles,
              distanceKm: estDistanceKm,
              palette: palette,
              isCompact: isCompact,
              isUltraCompact: isUltraCompact,
            ),

            // F. Final Fare Card + Primary CTA Button (Always visible without scroll)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFinalFareCard(
                  s: s,
                  isAr: isAr,
                  isRide: isRide,
                  hasBothLocations: hasBothLocations,
                  hasEstimate: hasEstimate,
                  estDeliveryFee: estDeliveryFee,
                  estServiceFee: estServiceFee,
                  estTax: estTax,
                  estDriverBonusFee: estDriverBonusFee,
                  estDriverBonusPaidByCustomer: estDriverBonusPaidByCustomer,
                  estDiscount: estDiscount,
                  estUpfrontAmount: estUpfrontAmount,
                  estGrandTotal: estGrandTotal,
                  isWalletPayment: isWalletPayment,
                  canUseCoins: canUseCoins,
                  coinState: coinState,
                  palette: palette,
                  isCompact: isCompact,
                ),
                SizedBox(height: sectionGap),
                _buildSubmitButton(
                  s: s,
                  isAr: isAr,
                  isEnabled: isSubmitEnabled,
                  palette: palette,
                  isCompact: isCompact,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // B. Mode Switcher (Segmented Control)
  // ---------------------------------------------------------------------------
  Widget _buildTypeSwitcher(
    AppStrings s,
    SpecialDeliveryPalette palette, {
    bool isCompact = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isCompact ? 36 : 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.surfaceBorder),
        boxShadow: [palette.surfaceShadow],
      ),
      child: Row(
        children: [
          _switcherButton(s.delivery, 'delivery', palette),
          _switcherButton(s.ride, 'ride', palette),
        ],
      ),
    );
  }

  Widget _switcherButton(
    String label,
    String value,
    SpecialDeliveryPalette palette,
  ) {
    final isSelected = _serviceType == value;
    return Expanded(
      child: TactileScaleTap(
        pressedScale: 0.97,
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
            _estimateFailed = false;
            _estimateErrorKey = null;
            _lastEstimateKey = null;
            _invalidateOrderIntent();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? SpecialDeliveryTokens.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SpecialDeliveryTokens.gold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: SpecialDeliveryTokens.text(
              size: 12,
              weight: isSelected ? FontWeight.w900 : FontWeight.w800,
              color: isSelected
                  ? SpecialDeliveryTokens.darkOnGold
                  : palette.textMuted,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. Expandable Info Banner (tlob-info-box)
  // ---------------------------------------------------------------------------
  Widget _buildInfoBanner(
    AppStrings s,
    bool isAr,
    SpecialDeliveryPalette palette, {
    bool isCompact = false,
  }) {
    final description = _serviceType == 'delivery'
        ? s.customCourierDesc
        : s.rideServiceDesc;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isCompact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            description,
            maxLines: _isExpanded ? (isCompact ? 3 : 4) : 2,
            overflow: TextOverflow.ellipsis,
            style: SpecialDeliveryTokens.text(
              size: 10.5,
              weight: FontWeight.w600,
              color: palette.textPrimary,
              height: isCompact ? 1.25 : 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? s.readLess : s.readMore,
                style: SpecialDeliveryTokens.text(
                  size: 10,
                  weight: FontWeight.w800,
                  color: palette.goldText,
                  decoration: TextDecoration.underline,
                  decorationColor: palette.goldText,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Locations, Item Details & Payment Card (tlob-surface)
  // ---------------------------------------------------------------------------
  Widget _buildMainFormCard(
    AppStrings s,
    bool isAr,
    bool isRide,
    SpecialDeliveryPalette palette, {
    bool isCompact = false,
    bool isUltraCompact = false,
  }) {
    final rowGap = isUltraCompact ? 5.0 : (isCompact ? 6.0 : 8.0);
    final locHeight = isUltraCompact ? 36.0 : (isCompact ? 38.0 : 40.0);
    final fieldHeight = isUltraCompact ? 32.0 : (isCompact ? 34.0 : 36.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.surfaceBorder),
        boxShadow: [palette.surfaceShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pickup & Dropoff Row (2-col grid, gap: 8px)
          Row(
            children: [
              Expanded(
                child: _buildLocationPickerButton(
                  isPickup: true,
                  placeholder: isRide ? s.yourLocation : s.pickupLocation,
                  addressText: _pickupController.text.trim(),
                  hasLocation: _pickupLocation != null,
                  icon: isRide
                      ? Icons.my_location_rounded
                      : Icons.gps_fixed_rounded,
                  isAr: isAr,
                  palette: palette,
                  height: locHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLocationPickerButton(
                  isPickup: false,
                  placeholder: isRide ? s.destination : s.dropoffLocation,
                  addressText: _dropoffController.text.trim(),
                  hasLocation: _dropoffLocation != null,
                  icon: Icons.location_on_rounded,
                  isAr: isAr,
                  palette: palette,
                  height: locHeight,
                ),
              ),
            ],
          ),

          // Item Details Row (2-col grid — Delivery Mode ONLY)
          if (!isRide) ...[
            SizedBox(height: rowGap),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInput(
                    controller: _detailsController,
                    hint: isAr ? 'تفاصيل الغرض (أوراق...)' : s.enterItemDetails,
                    palette: palette,
                    height: fieldHeight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInput(
                    controller: _specialRequestController,
                    hint: isAr ? 'ملاحظات (اختياري)' : 'Notes (Optional)',
                    palette: palette,
                    height: fieldHeight,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: rowGap),

          // Payment Method Row (2-col grid)
          _buildPaymentMethodSelector(
            isAr,
            isRide,
            palette,
            height: fieldHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPickerButton({
    required bool isPickup,
    required String placeholder,
    required String addressText,
    required bool hasLocation,
    required IconData icon,
    required bool isAr,
    required SpecialDeliveryPalette palette,
    double height = 40,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TactileScaleTap(
          pressedScale: 0.97,
          onTap: () => _openLocationPicker(isPickup: isPickup),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: hasLocation ? palette.selectedTint : palette.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasLocation
                    ? SpecialDeliveryTokens.gold
                    : palette.surfaceBorder,
                width: hasLocation ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasLocation)
                        Text(
                          isAr ? 'تم التحديد ✓' : 'Selected ✓',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SpecialDeliveryTokens.text(
                            size: 8.5,
                            weight: FontWeight.w800,
                            color: palette.goldText,
                            height: 1.05,
                          ),
                        ),
                      Text(
                        hasLocation && addressText.isNotEmpty
                            ? addressText
                            : placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SpecialDeliveryTokens.text(
                          size: 10.5,
                          weight: hasLocation
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: hasLocation
                              ? palette.textPrimary
                              : palette.textMuted,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 15,
                  color: palette.goldText,
                ),
              ],
            ),
          ),
        ),
        if (hasLocation)
          PositionedDirectional(
            top: -5,
            end: -5,
            child: GestureDetector(
              onTap: () => _clearLocation(isPickup: isPickup),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(
                    color: SpecialDeliveryTokens.gold,
                    width: 1,
                  ),
                  boxShadow: [palette.surfaceShadow],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactInput({
    required TextEditingController controller,
    required String hint,
    required SpecialDeliveryPalette palette,
    double height = 36,
  }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: SpecialDeliveryTokens.gold,
        style: SpecialDeliveryTokens.text(
          size: 11,
          weight: FontWeight.w600,
          color: palette.textPrimary,
          height: 1.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: SpecialDeliveryTokens.text(
            size: 10.5,
            weight: FontWeight.w500,
            color: palette.textMuted,
            height: 1.2,
          ),
          filled: true,
          fillColor: palette.inputBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: height < 35 ? 6 : 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: palette.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: palette.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: SpecialDeliveryTokens.gold,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
    bool isAr,
    bool isRide,
    SpecialDeliveryPalette palette, {
    double height = 36,
  }) {
    Widget chip({
      required String value,
      required String label,
      required IconData icon,
    }) {
      final selected = _paymentMethod == value;
      return Expanded(
        child: TactileScaleTap(
          pressedScale: 0.97,
          onTap: () => setState(() {
            _paymentMethod = value;
            _invalidateOrderIntent();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? palette.selectedTint : palette.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? SpecialDeliveryTokens.gold
                    : palette.surfaceBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? palette.goldText : palette.textMuted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SpecialDeliveryTokens.text(
                      size: 11,
                      weight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? palette.textPrimary : palette.textMuted,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          value: 'CASH_ON_DELIVERY',
          label: isRide
              ? (isAr ? 'نقدي' : 'Cash')
              : (isAr ? 'عند الاستلام' : 'Cash on Delivery'),
          icon: Icons.payments_outlined,
        ),
        const SizedBox(width: 8),
        chip(
          value: 'MOBILE_WALLET',
          label: isAr ? 'محفظة إلكترونية' : 'Mobile Wallet',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // E. Vehicle Selection Grid (Backend-Driven, 4-Column Grid)
  // ---------------------------------------------------------------------------
  Widget _buildVehicleSection({
    required AppStrings s,
    required bool isAr,
    required PlatformSettingsData? settings,
    required bool isSettingsLoading,
    required List<String> enabledVehicles,
    required double? distanceKm,
    required SpecialDeliveryPalette palette,
    bool isCompact = false,
    bool isUltraCompact = false,
  }) {
    if (!isSettingsLoading &&
        enabledVehicles.isNotEmpty &&
        !enabledVehicles.contains(_selectedVehicle)) {
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
        : (enabledVehicles.isNotEmpty ? enabledVehicles.first : '');
    final boxSize = isUltraCompact ? 54.0 : (isCompact ? 60.0 : 68.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header: Title + Optional Distance Pill from Backend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              s.vehicleType,
              style: SpecialDeliveryTokens.text(
                size: 11.5,
                weight: FontWeight.w900,
                color: palette.textPrimary,
                height: 1.15,
              ),
            ),
            if (distanceKm != null && distanceKm > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.selectedTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.infoBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 11,
                      color: palette.goldText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}',
                      style: SpecialDeliveryTokens.numeric(
                        size: 9.5,
                        weight: FontWeight.w800,
                        color: palette.goldText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: isCompact ? 6 : 8),

        // Loading Skeleton / Empty / 4-Column Grid
        if (isSettingsLoading)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (idx) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: idx < 3 ? 8 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: boxSize,
                          maxHeight: boxSize,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.surfaceBorder),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.goldText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 5 : 6),
                      Container(
                        width: 40,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          )
        else if (enabledVehicles.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'لا توجد مركبات متاحة لهذه الخدمة حالياً'
                        : 'No vehicles are currently available for this service',
                    style: SpecialDeliveryTokens.text(
                      size: 11,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildFourColumnVehicleRows(
            isAr: isAr,
            enabledVehicles: enabledVehicles,
            activeSelection: activeSelection,
            settings: settings,
            palette: palette,
            boxSize: boxSize,
            isCompact: isCompact,
          ),
      ],
    );
  }

  Widget _buildFourColumnVehicleRows({
    required bool isAr,
    required List<String> enabledVehicles,
    required String activeSelection,
    required PlatformSettingsData? settings,
    required SpecialDeliveryPalette palette,
    required double boxSize,
    bool isCompact = false,
  }) {
    final rows = <Widget>[];
    for (var start = 0; start < enabledVehicles.length; start += 4) {
      final chunk = enabledVehicles.skip(start).take(4).toList(growable: false);
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 8));
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (col) {
            final code = col < chunk.length ? chunk[col] : null;
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: col < 3 ? 8 : 0),
                child: code == null
                    ? const SizedBox.shrink()
                    : _buildVehicleCard(
                        code: code,
                        label: VehicleTypeHelper.label(code, isArabic: isAr),
                        fallbackIcon: VehicleTypeHelper.icon(code),
                        customIconUrl: settings?.iconUrlForVehicle(code),
                        isSelected: activeSelection == code,
                        palette: palette,
                        boxSize: boxSize,
                        isCompact: isCompact,
                      ),
              ),
            );
          }),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildVehicleCard({
    required String code,
    required String label,
    required IconData fallbackIcon,
    required String? customIconUrl,
    required bool isSelected,
    required SpecialDeliveryPalette palette,
    double boxSize = 68,
    bool isCompact = false,
  }) {
    final hasImage = customIconUrl != null && customIconUrl.isNotEmpty;

    return TactileScaleTap(
      tapKey: ValueKey('vehicle_option_${_serviceType}_$code'),
      pressedScale: 0.95,
      onTap: () {
        if (_selectedVehicle == code) return;
        setState(() {
          _selectedVehicle = code;
          _estimate = null;
          _estimateFailed = false;
          _estimateErrorKey = null;
          _lastEstimateKey = null;
          _invalidateOrderIntent();
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1:1 Rounded Square Icon Box (Full-bleed edge-to-edge image, zero inner padding)
          AnimatedScale(
            scale: isSelected ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: boxSize,
                maxHeight: boxSize,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? SpecialDeliveryTokens.gold
                              : palette.surfaceBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color.fromRGBO(229, 169, 60, 0.42),
                                  blurRadius: 14,
                                  spreadRadius: 0,
                                ),
                              ]
                            : [palette.surfaceShadow],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isSelected ? 14 : 15,
                        ),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.formatImageUrl(
                                  customIconUrl,
                                ),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                memCacheWidth: 240,
                                placeholder: (_, _) => Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: isCompact ? 22 : 26,
                                    color: isSelected
                                        ? palette.goldText
                                        : palette.textMuted,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: isCompact ? 22 : 26,
                                    color: isSelected
                                        ? palette.goldText
                                        : palette.textMuted,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  fallbackIcon,
                                  size: isCompact ? 22 : 26,
                                  color: isSelected
                                      ? palette.goldText
                                      : palette.textPrimary,
                                ),
                              ),
                      ),
                    ),
                    if (isSelected)
                      PositionedDirectional(
                        top: -4,
                        start: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpecialDeliveryTokens.gold,
                            border: Border.all(
                              color: palette.bgMain,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.25),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: SpecialDeliveryTokens.darkOnGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 5 : 6),
          // Vehicle Name Label below the icon box (matches Home Business Types)
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.10,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SpecialDeliveryTokens.text(
                size: isSelected ? 10.5 : 10.0,
                weight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? palette.goldText
                    : (palette.isDark
                          ? const Color(0xFFC9C1B4)
                          : palette.textMuted),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F1. Final Fare Card (tlob-surface)
  // ---------------------------------------------------------------------------
  Widget _buildFinalFareCard({
    required AppStrings s,
    required bool isAr,
    required bool isRide,
    required bool hasBothLocations,
    required bool hasEstimate,
    required double estDeliveryFee,
    required double estServiceFee,
    required double estTax,
    required double estDriverBonusFee,
    required bool estDriverBonusPaidByCustomer,
    required double estDiscount,
    required double estUpfrontAmount,
    required double? estGrandTotal,
    required bool isWalletPayment,
    required bool canUseCoins,
    required CoinHistoryState coinState,
    required SpecialDeliveryPalette palette,
    bool isCompact = false,
  }) {
    final fareTitle = isAr
        ? 'الإجمالي النهائي'
        : (isRide ? 'Final Ride Fare' : 'Final Delivery Fare');

    String subtitle;
    if (!hasBothLocations) {
      subtitle = isRide
          ? (isAr
                ? 'حدد نقطة الركوب والوجهة لعرض الأجرة النهائية'
                : 'Select pickup and destination to see your final fare')
          : (isAr
                ? 'حدد موقع الاستلام والتسليم لعرض الأجرة النهائية'
                : 'Select pickup and dropoff locations to see your final fare');
    } else if (_isEstimating) {
      subtitle = isAr ? 'جاري حساب الأجرة...' : 'Calculating final fare...';
    } else if (_estimateFailed) {
      subtitle = _estimateErrorKey != null
          ? '${ApiErrorMapper.translate(_estimateErrorKey!, context: context)} • ${isAr ? 'اضغط لإعادة المحاولة' : 'Tap to retry'}'
          : (isAr
                ? 'تعذر حساب الأجرة • اضغط لإعادة المحاولة'
                : 'Could not calculate fare • Tap to retry');
    } else {
      subtitle = isAr
          ? 'الرسوم المقدرة تشمل الخدمة'
          : 'Estimated fare includes service & fees';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isCompact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEstimate
              ? SpecialDeliveryTokens.gold.withValues(alpha: 0.55)
              : palette.surfaceBorder,
        ),
        boxShadow: [palette.surfaceShadow],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _estimateFailed ? () => _fetchEstimate(force: true) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SpecialDeliveryTokens.text(
                            size: 10,
                            weight: _estimateFailed
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _estimateFailed
                                ? SpecialDeliveryTokens.errorRed
                                : palette.textMuted,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          fareTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SpecialDeliveryTokens.text(
                            size: 12,
                            weight: FontWeight.w900,
                            color: palette.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isEstimating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SpecialDeliveryTokens.gold,
                      ),
                    )
                  else
                    Text(
                      estGrandTotal != null
                          ? _formatMoney(estGrandTotal, s.egp)
                          : '—',
                      style: SpecialDeliveryTokens.numeric(
                        size: 17,
                        weight: FontWeight.w900,
                        color: estGrandTotal != null
                            ? palette.goldText
                            : palette.textMuted,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),

            // Compact Backend Itemized Breakdown Strip (only when server estimate exists)
            if (hasEstimate) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  _miniFeeChip(
                    isRide
                        ? (isAr ? 'الرحلة' : 'Ride Fare')
                        : (isAr ? 'التوصيل' : 'Delivery Fare'),
                    _formatMoney(estDeliveryFee, s.egp),
                    palette,
                  ),
                  if (estServiceFee > 0)
                    _miniFeeChip(
                      isAr ? 'الخدمة' : 'Service Fee',
                      _formatMoney(estServiceFee, s.egp),
                      palette,
                    ),
                  if (estDriverBonusPaidByCustomer && estDriverBonusFee > 0)
                    _miniFeeChip(
                      isAr ? 'مكافأة' : 'Driver Bonus',
                      _formatMoney(estDriverBonusFee, s.egp),
                      palette,
                    ),
                  if (estTax > 0)
                    _miniFeeChip(
                      isAr ? 'ضريبة' : 'Taxes & Fees',
                      _formatMoney(estTax, s.egp),
                      palette,
                    ),
                  if (_useCoins && estDiscount > 0)
                    _miniFeeChip(
                      isAr ? 'خصم عملات' : 'Coin Discount',
                      '-${_formatMoney(estDiscount, s.egp)}',
                      palette,
                      valueColor: SpecialDeliveryTokens.successGreen,
                    ),
                ],
              ),
            ],

            // Compact Coins Toggle (only if user has eligible balance)
            if (canUseCoins) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: SpecialDeliveryTokens.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr
                            ? 'استخدام ${coinState.currentBalance} عملة'
                            : 'Use ${coinState.currentBalance} Coins',
                        style: SpecialDeliveryTokens.text(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 24,
                    child: Transform.scale(
                      scale: 0.78,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Switch(
                        value: _useCoins,
                        activeThumbColor: SpecialDeliveryTokens.darkOnGold,
                        activeTrackColor: SpecialDeliveryTokens.gold,
                        inactiveThumbColor: palette.textMuted,
                        inactiveTrackColor: palette.surface2,
                        trackOutlineColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? SpecialDeliveryTokens.gold
                              : palette.surfaceBorder,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _useCoins = val;
                            _invalidateOrderIntent();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Compact Upfront Deposit Notice (only when required by backend)
            if (hasEstimate && !isWalletPayment && estUpfrontAmount > 0) ...[
              const SizedBox(height: 5),
              Text(
                isAr
                    ? 'مطلوب تحويل مقدم ${_formatMoney(estUpfrontAmount, s.egp)} لمحفظة الكابتن بعد القبول.'
                    : 'Upfront deposit of ${_formatMoney(estUpfrontAmount, s.egp)} required after acceptance.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SpecialDeliveryTokens.text(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: palette.goldText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniFeeChip(
    String label,
    String value,
    SpecialDeliveryPalette palette, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: SpecialDeliveryTokens.text(
            size: 9.5,
            weight: FontWeight.w600,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: SpecialDeliveryTokens.numeric(
            size: 9.5,
            weight: FontWeight.w800,
            color: valueColor ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // F2. Primary CTA Button (w-full py-3.5 rounded-2xl)
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton({
    required AppStrings s,
    required bool isAr,
    required bool isEnabled,
    required SpecialDeliveryPalette palette,
    bool isCompact = false,
  }) {
    final ctaLabel = _serviceType == 'ride'
        ? (isAr ? 'اطلب الآن' : 'Request Now')
        : s.requestCourier;

    return TactileScaleTap(
      pressedScale: 0.98,
      onTap: isEnabled ? _submitOrder : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isCompact ? 11 : 14),
        decoration: BoxDecoration(
          color: isEnabled ? SpecialDeliveryTokens.gold : palette.disabledBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: SpecialDeliveryTokens.gold.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: SpecialDeliveryTokens.darkOnGold,
                ),
              )
            : Text(
                ctaLabel,
                style: SpecialDeliveryTokens.text(
                  size: 14,
                  weight: FontWeight.w900,
                  color: isEnabled
                      ? SpecialDeliveryTokens.darkOnGold
                      : palette.disabledText,
                  height: 1.1,
                ),
              ),
      ),
    );
  }
}
