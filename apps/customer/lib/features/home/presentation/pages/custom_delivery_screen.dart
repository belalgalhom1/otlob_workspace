import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart'
    show ApiErrorMapper, RoadRoutePoint, VehicleTypeHelper;
import 'package:data/data.dart' show ResolvedRoadRoute;
import 'package:data/providers.dart' show sharedRoutingRepositoryProvider;
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart'
    show AppMapStyle, AppMapTileLayer, NavigationRoutePolylines;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/location_picker_map.dart';
import '../../../orders/presentation/providers/custom_delivery_search_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/utils/wallet_payment_helper.dart';
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
  final MapController _previewMapController = MapController();

  static const LatLng _fallbackMapCenter = LatLng(30.0444, 31.2357);

  bool _mapReady = false;
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

  // Real street-following driving route (matching OrderTrackingScreen)
  List<LatLng> _roadRoutePoints = const [];
  int? _roadRouteDurationSeconds;
  bool _isRoadRoute = false;
  String? _lastRoadRouteKey;
  CancelToken? _roadRouteCancelToken;
  int _roadRouteRequestSeq = 0;

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
        paymentMethod: _paymentMethod.startsWith('MOBILE_WALLET')
            ? 'MOBILE_WALLET'
            : _paymentMethod,
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

  void _resetRoadRoute() {
    _roadRouteCancelToken?.cancel('route_reset');
    _roadRouteCancelToken = null;
    _roadRouteRequestSeq++;
    _lastRoadRouteKey = null;
    _roadRoutePoints = const [];
    _roadRouteDurationSeconds = null;
    _isRoadRoute = false;
  }

  Future<void> _fetchRoadRoute({bool force = false}) async {
    final pickup = _pickupLocation;
    final dropoff = _dropoffLocation;
    if (pickup == null || dropoff == null) {
      if (_roadRoutePoints.isNotEmpty || _lastRoadRouteKey != null) {
        if (mounted) {
          setState(_resetRoadRoute);
        } else {
          _resetRoadRoute();
        }
      }
      return;
    }

    final routeKey =
        '${pickup.latitude.toStringAsFixed(5)},${pickup.longitude.toStringAsFixed(5)}->'
        '${dropoff.latitude.toStringAsFixed(5)},${dropoff.longitude.toStringAsFixed(5)}';
    if (!force && routeKey == _lastRoadRouteKey) return;

    _roadRouteCancelToken?.cancel('route_inputs_changed');
    final token = CancelToken();
    _roadRouteCancelToken = token;
    _lastRoadRouteKey = routeKey;
    final requestSeq = ++_roadRouteRequestSeq;

    try {
      final repo = ref.read(sharedRoutingRepositoryProvider);
      final ResolvedRoadRoute resolved = await repo.computeWaypointsRoute(
        <RoadRoutePoint>[
          RoadRoutePoint(pickup.latitude, pickup.longitude),
          RoadRoutePoint(dropoff.latitude, dropoff.longitude),
        ],
        cancelToken: token,
      );
      if (!mounted ||
          token.isCancelled ||
          requestSeq != _roadRouteRequestSeq) {
        return;
      }

      if (resolved.hasRenderablePath) {
        final mappedPoints = resolved.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
        setState(() {
          _roadRoutePoints = mappedPoints;
          _isRoadRoute = resolved.isRoadRoute;
          _roadRouteDurationSeconds =
              resolved.isRoadRoute && resolved.durationSeconds > 0
              ? resolved.durationSeconds
              : null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapCamera());
      }
    } catch (_) {
      // Keep graceful straight-chord fallback when offline or in isolated tests.
    }
  }

  @override
  void dispose() {
    _roadRouteCancelToken?.cancel('disposed');
    _previewMapController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _detailsController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  void _syncMapCamera() {
    if (!_mapReady || !mounted) return;
    try {
      if (_pickupLocation != null && _dropoffLocation != null) {
        if (_pickupLocation == _dropoffLocation) {
          _previewMapController.move(_pickupLocation!, 15.5);
        } else {
          final boundPoints = _roadRoutePoints.length >= 2
              ? <LatLng>[
                  ..._roadRoutePoints,
                  _pickupLocation!,
                  _dropoffLocation!,
                ]
              : <LatLng>[_pickupLocation!, _dropoffLocation!];
          _previewMapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(boundPoints),
              padding: const EdgeInsets.fromLTRB(34, 64, 34, 56),
              maxZoom: 16.6,
            ),
          );
        }
      } else if (_pickupLocation != null) {
        _previewMapController.move(_pickupLocation!, 15.5);
      } else if (_dropoffLocation != null) {
        _previewMapController.move(_dropoffLocation!, 15.5);
      }
    } catch (_) {
      // Map not yet attached to render tree; camera will sync onMapReady.
    }
  }

  void _swapLocations() {
    if (_pickupLocation == null &&
        _dropoffLocation == null &&
        _pickupController.text.isEmpty &&
        _dropoffController.text.isEmpty) {
      return;
    }
    setState(() {
      _invalidateOrderIntent();
      final tmpLoc = _pickupLocation;
      _pickupLocation = _dropoffLocation;
      _dropoffLocation = tmpLoc;

      final tmpText = _pickupController.text;
      _pickupController.text = _dropoffController.text;
      _dropoffController.text = tmpText;

      _estimate = null;
      _estimateFailed = false;
      _estimateErrorKey = null;
      _lastEstimateKey = null;
      _resetRoadRoute();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapCamera());
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
      _resetRoadRoute();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapCamera());
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
      _resetRoadRoute();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapCamera());
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
            paymentMethod: _paymentMethod.startsWith('MOBILE_WALLET')
            ? 'MOBILE_WALLET'
            : _paymentMethod,
            vehicleType: _selectedVehicle,
            coinsToUse: coinsToUse,
            idempotencyKey: _clientOrderKeyForCheckout(),
          );

      if (!mounted) return;

      if (outcome.isSuccess && outcome.orderId != 'SUCCESS') {
        final selectedChannel = CustomerPaymentChannel.fromStorage(
          _paymentMethod,
        );
        if (selectedChannel != null && outcome.orderId != null) {
          await CustomerPaymentPreferenceStore.save(
            outcome.orderId!,
            selectedChannel,
          );
          if (!mounted) return;
        }
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
        if (mounted) {
          _fetchEstimate();
          _fetchRoadRoute();
        }
      });
    }

    final isAr = s.isArabic;
    final coinState = ref.watch(coinHistoryProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);
    final settings = settingsAsync.value;
    final isSettingsLoading = settingsAsync.isLoading && settings == null;

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
    final isWalletPayment = _paymentMethod.startsWith('MOBILE_WALLET');
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: palette.bgMain,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  final totalH = viewportConstraints.maxHeight;
                  final isCompact = totalH < 700;
                  final isUltraCompact = totalH < 630;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone 1: Compact Top Header (50px, shrink-0)
                        _buildHeader(s, isAr, palette),

                        // Zone 2: Flexible Live Map Preview (flex: 1, absorbs all extra vertical space)
                        Expanded(
                          child: _buildLiveMapZone(
                            s: s,
                            isAr: isAr,
                            isRide: isRide,
                            hasBothLocations: hasBothLocations,
                            distanceKm: estDistanceKm,
                            palette: palette,
                            isUltraCompact: isUltraCompact,
                          ),
                        ),

                        // Zone 3: Docked Compact Bottom Sheet (shrink-0, rounded-t-24, overlaps map edge cleanly)
                        _buildDockedBottomSheet(
                          s: s,
                          isAr: isAr,
                          isRide: isRide,
                          hasBothLocations: hasBothLocations,
                          hasEstimate: hasEstimate,
                          estDistanceKm: estDistanceKm,
                          estDeliveryFee: estDeliveryFee,
                          estServiceFee: estServiceFee,
                          estTax: estTax,
                          estDriverBonusFee: estDriverBonusFee,
                          estDriverBonusPaidByCustomer:
                              estDriverBonusPaidByCustomer,
                          estDiscount: estDiscount,
                          estUpfrontAmount: estUpfrontAmount,
                          estGrandTotal: estGrandTotal,
                          isWalletPayment: isWalletPayment,
                          canUseCoins: canUseCoins,
                          coinState: coinState,
                          settings: settings,
                          isSettingsLoading: isSettingsLoading,
                          enabledVehicles: enabledVehicles,
                          isSubmitEnabled: isSubmitEnabled,
                          palette: palette,
                          isCompact: isCompact,
                          isUltraCompact: isUltraCompact,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zone 1: Compact Top Header (height: 50px)
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
  // Zone 2: Flexible Live Map Preview (flex: 1, min-height: 120px)
  // ---------------------------------------------------------------------------
  Widget _buildLiveMapZone({
    required AppStrings s,
    required bool isAr,
    required bool isRide,
    required bool hasBothLocations,
    required double? distanceKm,
    required SpecialDeliveryPalette palette,
    required bool isUltraCompact,
  }) {
    final initialCenter =
        _pickupLocation ?? _dropoffLocation ?? _fallbackMapCenter;

    final int? realEtaMinutes =
        (_isRoadRoute &&
            _roadRouteDurationSeconds != null &&
            _roadRouteDurationSeconds! > 0)
        ? (_roadRouteDurationSeconds! / 60).ceil().clamp(1, 999)
        : null;

    String statusPillText;
    if (!hasBothLocations) {
      statusPillText = isAr
          ? 'اضغط لتحديد المواقع على الخريطة'
          : (isRide
                ? 'Select pickup and destination to see your final fare'
                : 'Select pickup and dropoff locations to see your final fare');
    } else if (_isEstimating) {
      statusPillText = isAr
          ? 'جاري حساب المسار والأجرة...'
          : 'Calculating route & fare...';
    } else if (distanceKm != null && distanceKm > 0) {
      if (realEtaMinutes != null) {
        statusPillText = isAr
            ? '${distanceKm.toStringAsFixed(1)} كم • ~$realEtaMinutes د'
            : '${distanceKm.toStringAsFixed(1)} km • ~$realEtaMinutes min';
      } else {
        statusPillText = isAr
            ? '${distanceKm.toStringAsFixed(1)} كم • المسار جاهز'
            : '${distanceKm.toStringAsFixed(1)} km • Route ready';
      }
    } else if (_estimateFailed) {
      final translated = _estimateErrorKey != null
          ? ApiErrorMapper.translate(_estimateErrorKey!, context: context)
          : null;
      statusPillText = (translated != null && translated.trim().isNotEmpty)
          ? translated
          : (isAr ? 'تعذر حساب المسار' : 'Route estimate unavailable');
    } else {
      statusPillText = isAr ? 'تم تحديد نقطتي المسار' : 'Route points selected';
    }

    final List<LatLng> polylinePoints =
        (_pickupLocation != null && _dropoffLocation != null)
        ? (_roadRoutePoints.length >= 2
              ? _roadRoutePoints
              : <LatLng>[_pickupLocation!, _dropoffLocation!])
        : const <LatLng>[];

    return Stack(
      key: const ValueKey('special_delivery_live_map_zone'),
      clipBehavior: Clip.none,
      children: [
        // Extend live map 20px downward behind the rounded-t-[24px] Bottom Sheet for seamless -mt-3 overlap
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -20,
          child: ColoredBox(
            color: palette.isDark
                ? const Color(0xFF171612)
                : const Color(0xFFEAE7DF),
            child: FlutterMap(
              mapController: _previewMapController,
              options: MapOptions(
                backgroundColor: palette.isDark
                    ? const Color(0xFF171612)
                    : const Color(0xFFEAE7DF),
                initialCenter: initialCenter,
                initialZoom: 14.0,
                minZoom: 4,
                maxZoom: 18.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _mapReady = true;
                  _syncMapCamera();
                },
                onTap: (_, _) =>
                    _openLocationPicker(isPickup: _pickupLocation == null),
              ),
              children: [
                const AppMapTileLayer(
                  style: AppMapStyle.auto,
                  userAgentPackageName: 'com.otlob.customer',
                ),
                if (polylinePoints.length >= 2)
                  RepaintBoundary(
                    child: PolylineLayer(
                      polylines: NavigationRoutePolylines.build(
                        points: polylinePoints,
                        foregroundColor: SpecialDeliveryTokens.gold,
                        casingColor: palette.isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                            : const Color(0xFF1E293B).withValues(alpha: 0.72),
                        strokeWidth: 4.8,
                        casingWidth: 8.2,
                      ),
                    ),
                  ),
                if (_pickupLocation != null || _dropoffLocation != null)
                  MarkerLayer(
                    markers: [
                      if (_pickupLocation != null)
                        Marker(
                          point: _pickupLocation!,
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: _buildMapPinMarker(
                            color: SpecialDeliveryTokens.gold,
                            icon: Icons.my_location_rounded,
                            iconColor: SpecialDeliveryTokens.darkOnGold,
                          ),
                        ),
                      if (_dropoffLocation != null)
                        Marker(
                          point: _dropoffLocation!,
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: _buildMapPinMarker(
                            color: SpecialDeliveryTokens.successGreen,
                            icon: Icons.location_on_rounded,
                            iconColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Subtle dark bottom gradient transitioning seamlessly behind the rounded Bottom Sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: -20,
          height: 68,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: palette.isDark ? 0.62 : 0.22),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Frosted Mode Switcher (top: 10px, horizontal: 14px)
        Positioned(
          top: isUltraCompact ? 6 : 10,
          left: 14,
          right: 14,
          child: _buildFloatingModeSwitcher(
            s,
            palette,
            isCompact: isUltraCompact,
          ),
        ),

        // Floating Bottom Map Controls: Status Pill (Start/Right in RTL) + 32x32 Expand Map Button (End/Left in RTL)
        Positioned(
          left: 14,
          right: 14,
          bottom: isUltraCompact ? 6 : 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () =>
                      _openLocationPicker(isPickup: _pickupLocation == null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color.fromRGBO(229, 169, 60, 0.40),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpecialDeliveryTokens.gold,
                            boxShadow: [
                              BoxShadow(
                                color: SpecialDeliveryTokens.gold.withValues(
                                  alpha: 0.75,
                                ),
                                blurRadius: 6,
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusPillText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SpecialDeliveryTokens.text(
                              size: 10,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TactileScaleTap(
                tapKey: const ValueKey('expand_map_picker_btn'),
                pressedScale: 0.94,
                onTap: () =>
                    _openLocationPicker(isPickup: _pickupLocation == null),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color.fromRGBO(229, 169, 60, 0.40),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    size: 15,
                    color: SpecialDeliveryTokens.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPinMarker({
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.50),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: iconColor),
    );
  }

  Widget _buildFloatingModeSwitcher(
    AppStrings s,
    SpecialDeliveryPalette palette, {
    bool isCompact = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: isCompact ? 36 : 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: palette.isDark ? 0.88 : 0.92),
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
        ),
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
          duration: const Duration(milliseconds: 220),
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
  // Zone 3: Docked Compact Bottom Sheet (shrink-0, rounded-t-24)
  // ---------------------------------------------------------------------------
  Widget _buildDockedBottomSheet({
    required AppStrings s,
    required bool isAr,
    required bool isRide,
    required bool hasBothLocations,
    required bool hasEstimate,
    required double? estDistanceKm,
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
    required PlatformSettingsData? settings,
    required bool isSettingsLoading,
    required List<String> enabledVehicles,
    required bool isSubmitEnabled,
    required SpecialDeliveryPalette palette,
    required bool isCompact,
    required bool isUltraCompact,
  }) {
    final gap = isUltraCompact ? 6.0 : (isCompact ? 8.0 : 10.0);

    return AnimatedContainer(
      key: const ValueKey('special_delivery_bottom_sheet'),
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(
        14,
        isUltraCompact ? 6 : 8,
        14,
        isUltraCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: palette.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: palette.sheetBorder, width: 1.5),
        ),
        boxShadow: [palette.sheetShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Drag Handle (36x4 pill)
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: isUltraCompact ? 5 : 7),

          // 2. Compact 1-Line Expandable Info Bar
          _buildCompactInfoBar(s, palette, isCompact: isCompact),
          SizedBox(height: gap),

          // 3. Locations (with Swap), Delivery Item Details & Payment Card
          _buildMainFormCard(
            s,
            isAr,
            isRide,
            palette,
            isCompact: isCompact,
            isUltraCompact: isUltraCompact,
          ),
          SizedBox(height: gap),

          // 4. Vehicle Type Selector — Full-Bleed Business-Type Style
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

          // 5. Optional Compact Fee Breakdown + Coins / Deposit Strip (only when real backend data exists)
          if (hasEstimate || canUseCoins) ...[
            SizedBox(height: isUltraCompact ? 6 : 9),
            _buildCompactFeesAndCoinsStrip(
              s: s,
              isAr: isAr,
              isRide: isRide,
              hasEstimate: hasEstimate,
              estDeliveryFee: estDeliveryFee,
              estServiceFee: estServiceFee,
              estTax: estTax,
              estDriverBonusFee: estDriverBonusFee,
              estDriverBonusPaidByCustomer: estDriverBonusPaidByCustomer,
              estDiscount: estDiscount,
              estUpfrontAmount: estUpfrontAmount,
              isWalletPayment: isWalletPayment,
              canUseCoins: canUseCoins,
              coinState: coinState,
              palette: palette,
            ),
          ],

          SizedBox(height: gap),

          // 6. Combined Total Fare + Primary Submit CTA Bar
          _buildCombinedFareAndCtaBar(
            s: s,
            isAr: isAr,
            isRide: isRide,
            hasBothLocations: hasBothLocations,
            hasEstimate: hasEstimate,
            estGrandTotal: estGrandTotal,
            isSubmitEnabled: isSubmitEnabled,
            palette: palette,
            isUltraCompact: isUltraCompact,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact 1-Line Expandable Info Bar (tlob-info-box)
  // ---------------------------------------------------------------------------
  Widget _buildCompactInfoBar(
    AppStrings s,
    SpecialDeliveryPalette palette, {
    bool isCompact = false,
  }) {
    final description = _serviceType == 'delivery'
        ? s.customCourierDesc
        : s.rideServiceDesc;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isCompact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: palette.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.infoBorder),
      ),
      child: _isExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  description,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: SpecialDeliveryTokens.text(
                    size: 10,
                    weight: FontWeight.w600,
                    color: palette.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isExpanded = false),
                    child: Text(
                      s.readLess,
                      style: SpecialDeliveryTokens.text(
                        size: 9.5,
                        weight: FontWeight.w800,
                        color: palette.goldText,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.goldText,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SpecialDeliveryTokens.text(
                      size: 10,
                      weight: FontWeight.w600,
                      color: palette.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isExpanded = true),
                  child: Text(
                    s.readMore,
                    style: SpecialDeliveryTokens.text(
                      size: 9.5,
                      weight: FontWeight.w800,
                      color: palette.goldText,
                      decoration: TextDecoration.underline,
                      decorationColor: palette.goldText,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Locations (with Centered Swap), Item Details & Payment Card (tlob-surface)
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
      padding: EdgeInsets.all(isUltraCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.surfaceBorder),
        boxShadow: [palette.surfaceShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pickup & Dropoff Row with Centered Circular Swap Button (⇄)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
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
                  const SizedBox(width: 12),
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
              TactileScaleTap(
                tapKey: const ValueKey('swap_locations_btn'),
                pressedScale: 0.90,
                onTap: _swapLocations,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface,
                    border: Border.all(
                      color: SpecialDeliveryTokens.gold,
                      width: 1.2,
                    ),
                    boxShadow: [palette.surfaceShadow],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: palette.goldText,
                  ),
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
            padding: isPickup
                ? const EdgeInsetsDirectional.fromSTEB(10, 0, 14, 0)
                : const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
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
                            size: 8.0,
                            weight: FontWeight.w800,
                            color: isPickup
                                ? palette.goldText
                                : SpecialDeliveryTokens.successGreen,
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
                  color: isPickup
                      ? palette.goldText
                      : (hasLocation
                            ? SpecialDeliveryTokens.successGreen
                            : palette.goldText),
                ),
              ],
            ),
          ),
        ),
        if (hasLocation)
          PositionedDirectional(
            top: -6,
            start: isPickup ? -5 : null,
            end: isPickup ? null : -5,
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
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                  size: 14,
                  color: selected ? palette.goldText : palette.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: SpecialDeliveryTokens.text(
                        size: 11,
                        weight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: selected ? palette.textPrimary : palette.textMuted,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: Row(
        children: [
          chip(
            value: 'CASH_ON_DELIVERY',
            label: isRide
                ? (isAr ? 'نقدي' : 'Cash')
                : (isAr ? 'عند الاستلام' : 'Cash'),
            icon: Icons.payments_outlined,
          ),
          const SizedBox(width: 6),
          chip(
            value: 'MOBILE_WALLET',
            label: isAr ? 'محفظة' : 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 6),
          chip(
            value: 'MOBILE_WALLET_INSTAPAY',
            label: isAr ? 'إنستا باي' : 'InstaPay',
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Vehicle Type Selector — Full-Bleed Business-Type Style (4-Column Grid)
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
    final boxSize = isUltraCompact ? 50.0 : (isCompact ? 56.0 : 64.0);

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
        SizedBox(height: isUltraCompact ? 4 : 6),

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
                              border: Border.all(
                                color: palette.surfaceBorder,
                                width: 1.5,
                              ),
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
                      const SizedBox(height: 4),
                      Container(
                        width: 38,
                        height: 9,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        rows.add(const SizedBox(height: 6));
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
    double boxSize = 64,
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
                      key: ValueKey('vehicle_image_box_${_serviceType}_$code'),
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? SpecialDeliveryTokens.gold
                              : palette.surfaceBorder,
                          width: isSelected ? 2.0 : 1.5,
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
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.formatImageUrl(
                                  customIconUrl,
                                ),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                memCacheWidth: 240,
                                placeholder: (_, _) => Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: isCompact ? 20 : 24,
                                    color: isSelected
                                        ? SpecialDeliveryTokens.goldDark
                                        : SpecialDeliveryTokens.darkOnGold,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: isCompact ? 20 : 24,
                                    color: isSelected
                                        ? SpecialDeliveryTokens.goldDark
                                        : SpecialDeliveryTokens.darkOnGold,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  fallbackIcon,
                                  size: isCompact ? 20 : 24,
                                  color: isSelected
                                      ? SpecialDeliveryTokens.goldDark
                                      : SpecialDeliveryTokens.darkOnGold,
                                ),
                              ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpecialDeliveryTokens.gold,
                            border: Border.all(
                              color: palette.sheetBg,
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
          SizedBox(height: isCompact ? 4 : 5),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.08,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SpecialDeliveryTokens.text(
                size: 10,
                weight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? palette.goldText : palette.textPrimary,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Optional Compact Fee Breakdown + Coins + Upfront Deposit Strip
  // ---------------------------------------------------------------------------
  Widget _buildCompactFeesAndCoinsStrip({
    required AppStrings s,
    required bool isAr,
    required bool isRide,
    required bool hasEstimate,
    required double estDeliveryFee,
    required double estServiceFee,
    required double estTax,
    required double estDriverBonusFee,
    required bool estDriverBonusPaidByCustomer,
    required double estDiscount,
    required double estUpfrontAmount,
    required bool isWalletPayment,
    required bool canUseCoins,
    required CoinHistoryState coinState,
    required SpecialDeliveryPalette palette,
  }) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.08,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasEstimate)
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
          if (canUseCoins) ...[
            if (hasEstimate) const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 13,
                      color: SpecialDeliveryTokens.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAr
                          ? 'استخدام ${coinState.currentBalance} عملة'
                          : 'Use ${coinState.currentBalance} Coins',
                      style: SpecialDeliveryTokens.text(
                        size: 10,
                        weight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 22,
                  child: Transform.scale(
                    scale: 0.74,
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
          if (hasEstimate && !isWalletPayment && estUpfrontAmount > 0) ...[
            const SizedBox(height: 3),
            Text(
              isAr
                  ? 'مطلوب تحويل مقدم ${_formatMoney(estUpfrontAmount, s.egp)} لمحفظة الكابتن بعد القبول.'
                  : 'Upfront deposit of ${_formatMoney(estUpfrontAmount, s.egp)} required after acceptance.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SpecialDeliveryTokens.text(
                size: 9,
                weight: FontWeight.w700,
                color: palette.goldText,
              ),
            ),
          ],
        ],
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
  // Combined Total Fare + Submit CTA Bar (tlob-surface, rounded-2xl, p-1.5 pr-3)
  // ---------------------------------------------------------------------------
  Widget _buildCombinedFareAndCtaBar({
    required AppStrings s,
    required bool isAr,
    required bool isRide,
    required bool hasBothLocations,
    required bool hasEstimate,
    required double? estGrandTotal,
    required bool isSubmitEnabled,
    required SpecialDeliveryPalette palette,
    required bool isUltraCompact,
  }) {
    final String fareSubtitle;
    if (_estimateFailed) {
      fareSubtitle = isAr ? 'اضغط لإعادة المحاولة' : 'Tap to retry';
    } else if (isAr) {
      fareSubtitle = hasEstimate ? 'الإجمالي شامل الخدمة' : 'الإجمالي المقدر';
    } else {
      fareSubtitle = isRide ? 'Final Ride Fare' : 'Final Delivery Fare';
    }

    final String ctaLabel;
    if (!hasBothLocations) {
      ctaLabel = isRide
          ? (isAr ? 'حدد المواقع للرحلة' : 'Select Locations')
          : (isAr ? 'حدد المواقع للطلب' : 'Select Locations');
    } else {
      ctaLabel = isRide
          ? (isAr ? 'اطلب الرحلة الآن' : 'Request Ride Now')
          : (isAr ? 'طلب مندوب الآن' : 'Request Courier Now');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEstimate
              ? SpecialDeliveryTokens.gold.withValues(alpha: 0.50)
              : palette.surfaceBorder,
        ),
        boxShadow: [palette.surfaceShadow],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.08,
        child: Row(
          children: [
            // Start Side (Right in RTL): Total Fare
            Expanded(
              flex: 38,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _estimateFailed
                    ? () => _fetchEstimate(force: true)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fareSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SpecialDeliveryTokens.text(
                        size: 9,
                        weight: _estimateFailed
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: _estimateFailed
                            ? SpecialDeliveryTokens.errorRed
                            : palette.textMuted,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    if (_isEstimating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SpecialDeliveryTokens.gold,
                          ),
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          estGrandTotal != null
                              ? _formatMoney(estGrandTotal, s.egp)
                              : '—',
                          maxLines: 1,
                          style: SpecialDeliveryTokens.numeric(
                            size: 17,
                            weight: FontWeight.w900,
                            color: estGrandTotal != null
                                ? palette.goldText
                                : palette.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // End Side (Left in RTL): Primary CTA (flex: 62%, height: 44px)
            Expanded(
              flex: 62,
              child: TactileScaleTap(
                tapKey: const ValueKey('special_delivery_submit_cta'),
                pressedScale: 0.98,
                onTap: isSubmitEnabled ? _submitOrder : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: isUltraCompact ? 40 : 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSubmitEnabled
                        ? SpecialDeliveryTokens.gold
                        : palette.disabledBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSubmitEnabled
                        ? [
                            BoxShadow(
                              color: SpecialDeliveryTokens.gold.withValues(
                                alpha: 0.30,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: SpecialDeliveryTokens.darkOnGold,
                          ),
                        )
                      : Text(
                          ctaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SpecialDeliveryTokens.text(
                            size: 13,
                            weight: FontWeight.w900,
                            color: isSubmitEnabled
                                ? SpecialDeliveryTokens.darkOnGold
                                : palette.disabledText,
                            height: 1.1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
