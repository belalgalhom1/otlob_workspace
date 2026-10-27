import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/location_picker_map.dart';

enum RideState { form, findingDriver, driverAssigned }

class CustomDeliveryScreen extends ConsumerStatefulWidget {
  const CustomDeliveryScreen({super.key});

  @override
  ConsumerState<CustomDeliveryScreen> createState() => _CustomDeliveryScreenState();
}

class _CustomDeliveryScreenState extends ConsumerState<CustomDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _selectedVehicle = 'motorcycle';
  String _serviceType = 'delivery'; // 'delivery' or 'ride'
  RideState _rideState = RideState.form;
  bool _isExpanded = false;
  bool _useCoins = false;
  bool _isEstimating = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _estimate;
  String? _lastEstimateKey;
  String? _clientOrderKey;

  String _clientOrderKeyForCheckout() =>
      _clientOrderKey ??= generateClientOrderKey();
  
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  Future<void> _fetchEstimate() async {
    if (_isEstimating) return;
    if (_pickupLocation == null || _dropoffLocation == null) {
      _estimate = null;
      return;
    }

    final detailsText = _detailsController.text.trim();

    // Coins change the quoted grandTotal server-side, so the computed value
    // (not just the toggle) is part of the key — same capping math as submit.
    int? coinsToUse;
    if (_useCoins) {
      final coinState = ref.read(coinHistoryProvider);
      final settings = ref.read(platformSettingsProvider).value;
      if (settings != null &&
          coinState.currentBalance >= settings.minCoinsToUse) {
        // Coins cover the whole bill; the backend caps the discount at the
        // grand total and only consumes the coins actually needed.
        coinsToUse = coinState.currentBalance;
      }
    }

    final estimateKey = '$_serviceType|$_selectedVehicle|${_pickupLocation!.longitude},${_pickupLocation!.latitude}|${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}|${coinsToUse ?? 0}';
    if (estimateKey == _lastEstimateKey) return;
    _lastEstimateKey = estimateKey;

    setState(() => _isEstimating = true);
    final result = await ref.read(ordersProvider.notifier).estimateCustomOrder(
      type: _serviceType,
      pickup: _pickupController.text.trim().isEmpty ? 'Pickup' : _pickupController.text.trim(),
      pickupLocation: [_pickupLocation!.longitude, _pickupLocation!.latitude],
      dropoff: _dropoffController.text.trim().isEmpty ? 'Dropoff' : _dropoffController.text.trim(),
      deliveryLocation: [_dropoffLocation!.longitude, _dropoffLocation!.latitude],
      vehicleType: _selectedVehicle,
      details: detailsText.isEmpty ? null : detailsText,
      coinsToUse: coinsToUse,
    );
    if (mounted) {
      setState(() {
        _estimate = result;
        _isEstimating = false;
      });
    }
  }

  double _calculateDistance() {
    if (_pickupLocation == null || _dropoffLocation == null) return 0.0;
    const distance = Distance();
    final meters = distance.as(LengthUnit.Meter, _pickupLocation!, _dropoffLocation!);
    return meters / 1000.0;
  }

  double _calculateTotalFee() {
    final settings = ref.read(platformSettingsProvider).value;
    if (settings == null) return 0.0;
    
    if (_pickupLocation == null || _dropoffLocation == null) return 0.0;
    final distanceKm = _calculateDistance();

    final serviceFee = settings.customOrderPlatformFee;
    final tax = (serviceFee * (settings.defaultTaxRate / 100.0)).roundToDouble();

    if (settings.minOrderKm > 0 && distanceKm < settings.minOrderKm) {
      final base = settings.minDistanceFixedPrice;
      return base + serviceFee + tax;
    }
    
    double perKm = 0;
    double minFee = 0;
    double maxFee = 0;
    switch (_selectedVehicle) {
      case 'bicycle':
        perKm = settings.pricePerKmBicycle.toDouble();
        minFee = settings.minDeliveryFeeBicycle.toDouble();
        maxFee = settings.maxDeliveryFeeBicycle.toDouble();
        break;
      case 'motorcycle':
        perKm = settings.pricePerKmMotorcycle.toDouble();
        minFee = settings.minDeliveryFeeMotorcycle.toDouble();
        maxFee = settings.maxDeliveryFeeMotorcycle.toDouble();
        break;
      case 'car':
        perKm = settings.pricePerKmCar.toDouble();
        minFee = settings.minDeliveryFeeCar.toDouble();
        maxFee = settings.maxDeliveryFeeCar.toDouble();
        break;
      case 'van':
        perKm = settings.pricePerKmVan.toDouble();
        minFee = settings.minDeliveryFeeVan.toDouble();
        maxFee = settings.maxDeliveryFeeVan.toDouble();
        break;
      case 'truck':
        perKm = settings.pricePerKmTruck.toDouble();
        minFee = settings.minDeliveryFeeTruck.toDouble();
        maxFee = settings.maxDeliveryFeeTruck.toDouble();
        break;
      case 'motor_tricycle':
        perKm = settings.pricePerKmMotorTricycle.toDouble();
        minFee = settings.minDeliveryFeeMotorTricycle.toDouble();
        maxFee = settings.maxDeliveryFeeMotorTricycle.toDouble();
        break;
      default:
        perKm = settings.pricePerKmMotorcycle.toDouble();
        minFee = settings.minDeliveryFeeMotorcycle.toDouble();
        maxFee = settings.maxDeliveryFeeMotorcycle.toDouble();
    }

    double deliveryFee = (settings.minOrderKm > 0 && distanceKm < settings.minOrderKm)
        ? settings.minDistanceFixedPrice.toDouble()
        : settings.baseDeliveryFee.toDouble() + (distanceKm * perKm);

    if (minFee > 0 && deliveryFee < minFee) {
      deliveryFee = minFee;
    }
    final effectiveMaxFee = maxFee > 0 ? maxFee : settings.maxDeliveryFee.toDouble();
    if (effectiveMaxFee > 0 && deliveryFee > effectiveMaxFee) {
      deliveryFee = effectiveMaxFee;
    }

    double driverBonusFee = 0;
    final now = DateTime.now();
    if (settings.driverBonusActive &&
        settings.driverBonusAmount > 0 &&
        settings.driverBonusStartDate != null &&
        settings.driverBonusEndDate != null &&
        now.isAfter(settings.driverBonusStartDate!) &&
        now.isBefore(settings.driverBonusEndDate!)) {
      driverBonusFee = settings.driverBonusAmount.toDouble();
    }

    double total = deliveryFee + serviceFee + tax;
    if (settings.driverBonusPaidByCustomer && driverBonusFee > 0) {
      total += driverBonusFee;
    }
    return total;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _detailsController.dispose();
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

        if (_serviceType == 'ride') {
          setState(() => _rideState = RideState.findingDriver);
        }

      final coinState = ref.read(coinHistoryProvider);
      final settings = ref.read(platformSettingsProvider).value;

      final distanceKm = _calculateDistance();
      if (_selectedVehicle == 'bicycle' && settings != null) {
        final maxBicycle = settings.maxKmForBicycle;
        if (distanceKm > maxBicycle) {
          final s = AppStrings.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? 'المسافة (${distanceKm.toStringAsFixed(1)} كم) تتجاوز الحد الأقصى للدراجة (${maxBicycle.toStringAsFixed(1)} كم)'
                : 'Distance (${distanceKm.toStringAsFixed(1)} km) exceeds bicycle maximum (${maxBicycle.toStringAsFixed(1)} km)'),
          ));
          if (_serviceType == 'ride') {
            setState(() => _rideState = RideState.form);
          }
          return;
        }
      }
      
      int? coinsToUse;
      if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
        // Same rule as the estimate: offer the full balance and let the
        // backend cap it at the grand total (keeps placement == estimate).
        coinsToUse = coinState.currentBalance;
      }

      final resultId = await ref.read(ordersProvider.notifier).placeCustomOrder(
        type: _serviceType,
        pickup: pickup,
        pickupLocation: [_pickupLocation!.longitude, _pickupLocation!.latitude],
        dropoff: dropoff,
        deliveryLocation: [_dropoffLocation!.longitude, _dropoffLocation!.latitude],
        details: details,
        vehicleType: _selectedVehicle,
        coinsToUse: coinsToUse,
        idempotencyKey: _clientOrderKeyForCheckout(),
      );

      if (!mounted) return;

        if (resultId != null) {
          _clientOrderKey = null;
          if (_serviceType == 'ride' && resultId != 'SUCCESS') {
            context.push('/order-tracking/$resultId');
          } else {
            context.go('/home');
            context.push('/orders');
          }
        } else {
          final s = AppStrings.of(context);
          setState(() => _rideState = RideState.form);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'فشل إتمام الطلب' : 'Failed to place order')));
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  bool _handleBack() {
    if (_rideState != RideState.form) {
      setState(() => _rideState = RideState.form);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if ((_pickupLocation != null || _dropoffLocation != null) && !_isEstimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchEstimate();
      });
    }
    final est = _estimate;
    final hasEstimate = est != null && (_pickupLocation != null) && (_dropoffLocation != null);
    final totalFee = hasEstimate
        ? ((est['grandTotal'] as num?)?.toDouble() ?? _calculateTotalFee())
        : _calculateTotalFee();
    final isAr = s.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final coinState = ref.watch(coinHistoryProvider);
    final settings = ref.watch(platformSettingsProvider).value;
    double coinDiscount = 0;
    
    if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
      coinDiscount = coinState.currentBalance * settings.coinValue;
      if (coinDiscount > totalFee) {
        coinDiscount = totalFee;
      }
    }
    
    final finalTotal = totalFee - coinDiscount;

    return PopScope(
      canPop: _rideState == RideState.form,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () {
              if (_handleBack()) context.pop();
            },
          ),
          title: Text(
            s.customDeliveryTitle, 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5
            )
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildBodyContent(s, isAr, totalFee, coinState, settings, coinDiscount, finalTotal, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(AppStrings s, bool isAr, double totalFee, coinState, settings, double coinDiscount, double finalTotal, bool isDark) {
    switch (_rideState) {
      case RideState.form:
        return _buildForm(s, isAr, totalFee, coinState, settings, coinDiscount, finalTotal, isDark);
      case RideState.findingDriver:
        return _buildFindingDriver(s, isAr, isDark);
      case RideState.driverAssigned:
        return _buildDriverAssigned(s, isAr, isDark);
    }
  }

  Widget _buildForm(AppStrings s, bool isAr, double totalFee, coinState, settings, double coinDiscount, double finalTotal, bool isDark) {
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
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLabel(s.vehicleType, isDark),
            const SizedBox(height: 12),
            _buildVehicleSelector(s, isDark),
            
            const SizedBox(height: 32),
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
                children: [
                  _priceRow(isAr ? 'رسوم التوصيل المقدرة' : 'Estimated Delivery Fare', _isEstimating ? '...' : '${totalFee.toStringAsFixed(0)} ${s.egp}', isDark),
                  const SizedBox(height: 8),
                  Text(
                    isAr 
                        ? 'الرسوم النهائية تشمل رسوم الخدمة والضرائب، وتُحتسب من مسافة الاستلام إلى التوصيل وتثبت عند تأكيد الطلب'
                        : 'Final fare (including service fees and taxes) is calculated from the pickup-to-dropoff distance and confirmed at checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (coinState.currentBalance > 0 && settings != null && coinState.currentBalance >= settings.minCoinsToUse) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'استخدام ${coinState.currentBalance} عملة' : 'Use ${coinState.currentBalance} Coins',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                        Switch(
                          value: _useCoins,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _useCoins = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  if (_useCoins && coinDiscount > 0) ...[
                    const SizedBox(height: 8),
                    _priceRow(isAr ? 'خصم العملات' : 'Coin Discount', '-${coinDiscount.toStringAsFixed(0)} ${s.egp}', isDark),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.total, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                      Text('${finalTotal.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_isSubmitting ||
                      _isEstimating ||
                      _estimate == null ||
                      _pickupLocation == null ||
                      _dropoffLocation == null)
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
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _switcherButton(s.delivery, 'delivery', isDark),
          _switcherButton(s.ride, 'ride', isDark),
        ],
      ),
    );
  }

  Widget _switcherButton(String label, String value, bool isDark) {
    final isSelected = _serviceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _serviceType = value;
            if (value == 'ride') {
               _selectedVehicle = 'car';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
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

    if (_serviceType == 'ride') {
      return Center(
        child: _vehicleOption(s.car, Icons.directions_car_filled_rounded, 'car', isDark, platformSettings?.carIconUrl),
      );
    }

    final vehicleOptions = <Widget>[];

    void addOption(Widget option) {
      if (vehicleOptions.isNotEmpty) {
        vehicleOptions.add(const SizedBox(width: 12));
      }
      vehicleOptions.add(option);
    }

    if (platformSettings?.allowBicycle ?? true) {
      addOption(_vehicleOption(s.isArabic ? 'دراجة' : 'Bicycle', Icons.pedal_bike_rounded, 'bicycle', isDark, platformSettings?.bicycleIconUrl));
    }
    if (platformSettings?.allowMotorcycle ?? true) {
      addOption(_vehicleOption(s.motorcycle, Icons.moped_rounded, 'motorcycle', isDark, platformSettings?.motorcycleIconUrl));
    }
    if (platformSettings?.allowMotorTricycle ?? true) {
      addOption(_vehicleOption(s.isArabic ? 'تروسيكل' : 'Tricycle', Icons.electric_rickshaw_rounded, 'motor_tricycle', isDark, platformSettings?.motorTricycleIconUrl));
    }
    if (platformSettings?.allowCar ?? true) {
      addOption(_vehicleOption(s.car, Icons.directions_car_filled_rounded, 'car', isDark, platformSettings?.carIconUrl));
    }
    if (platformSettings?.allowVan ?? true) {
      addOption(_vehicleOption(s.isArabic ? 'فان' : 'Van', Icons.airport_shuttle_rounded, 'van', isDark, platformSettings?.vanIconUrl));
    }
    if (platformSettings?.allowTruck ?? true) {
      addOption(_vehicleOption(s.isArabic ? 'نقل' : 'Truck', Icons.local_shipping_rounded, 'truck', isDark, platformSettings?.truckIconUrl));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: vehicleOptions,
      ),
    );
  }

  Widget _vehicleOption(String label, IconData fallbackIcon, String type, bool isDark, String? customIconUrl) {
    final isSelected = _selectedVehicle == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = type),
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                shape: BoxShape.circle,
                boxShadow: isSelected 
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))] 
                    : [],
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200),
                  width: 2,
                ),
              ),
              child: Center(
                child: customIconUrl != null && customIconUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: ImageUtils.formatImageUrl(customIconUrl),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(fallbackIcon, size: 44, color: isSelected ? Colors.black : Colors.grey),
                          errorWidget: (context, url, error) => Icon(fallbackIcon, size: 44, color: isSelected ? Colors.black : Colors.grey),
                        ),
                      )
                    : Icon(fallbackIcon, size: 52, color: isSelected ? Colors.black : Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingDriver(AppStrings s, bool isAr, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_6sxyjyjj.json',
                errorBuilder: (c, e, s) => const CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              s.findingCaptain, 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
            ),
            const SizedBox(height: 12),
            Text(
              s.pleaseWaitConnectDriver, 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAssigned(AppStrings s, bool isAr, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            s.requestConfirmed, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const CircleAvatar(radius: 32, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver123')),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'كابتن أحمد محمد' : 'Capt. Ahmed Mohamed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _circularAction(Icons.phone, Colors.green),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(
                      _selectedVehicle == 'motorcycle' ? Icons.moped_rounded : Icons.directions_car_filled_rounded,
                      color: Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedVehicle == 'motorcycle' ? (isAr ? 'باجاج بولسار' : 'Bajaj Pulsar') : (isAr ? 'تويوتا كورولا' : 'Toyota Corolla'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_selectedVehicle == 'motorcycle' ? (isAr ? 'أسود' : 'Black') : (isAr ? 'أبيض' : 'White'), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    _vehicleDetail(Icons.pin_rounded, 'ABC - 123', s.plateNo),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18), 
              backgroundColor: AppColors.primary, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            child: Text(s.trackRequest, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(s.backToHome, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _circularAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _vehicleDetail(IconData icon, String title, String sub) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ],
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
    return _buildTextField(
      controller: controller,
      hint: hint,
      icon: icon,
      isDark: isDark,
      validator: validator,
      readOnly: true,
      onTap: () async {
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
          final s = AppStrings.of(context);
          setState(() {
            if (isPickup) {
              _pickupLocation = result;
              controller.text = s.isArabic ? 'تم تحديد الموقع' : 'Location selected';
            } else {
              _dropoffLocation = result;
              controller.text = s.isArabic ? 'تم تحديد الموقع' : 'Location selected';
            }
          });
        }
      },
    );
  }

  Widget _priceRow(String label, String amount, bool isDark) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15)), 
      Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87))
    ]
  );
}
