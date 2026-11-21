import 'package:core/core.dart' show VehicleTypeHelper;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/network_providers.dart';

part 'platform_settings_provider.g.dart';

class PlatformSettingsData {
  final String? homeCoverUrl;
  final String? motorcycleIconUrl;
  final String? carIconUrl;
  final String? minibusIconUrl;
  final String? tukTukIconUrl;
  final String? bicycleIconUrl;
  final String? motorTricycleIconUrl;
  final String? quarterTruckIconUrl;
  final String? halfTruckIconUrl;
  final bool isMaintenanceMode;
  final String? supportEmail;
  final String? supportPhone;
  final String? supportWhatsapp;
  final String? termsUrl;
  final String? privacyUrl;
  final String? deliveryBannerIconUrl;
  final String currency;
  final double minOrderAmount;
  final double baseDeliveryFee;
  final double customOrderPlatformFee;
  final double defaultTaxRate;
  final double pricePerKm;
  final double pricePerKmBicycle;
  final double pricePerKmMotorcycle;
  final double pricePerKmCar;
  final double pricePerKmMinibus;
  final double pricePerKmTukTuk;
  final double pricePerKmMotorTricycle;
  final double pricePerKmQuarterTruck;
  final double pricePerKmHalfTruck;
  final bool allowBicycle;
  final bool allowMotorcycle;
  final bool allowCar;
  final bool allowMinibus;
  final bool allowTukTuk;
  final bool allowMotorTricycle;
  final bool allowQuarterTruck;
  final bool allowHalfTruck;
  final Map<String, List<String>> serviceEligibleVehicles;
  final double maxKmForBicycle;
  final double maxDeliveryRadiusKm;
  final double minOrderKm;
  final double minDistanceFixedPrice;
  final double maxDeliveryFee;
  final double minDeliveryFeeBicycle;
  final double maxDeliveryFeeBicycle;
  final double minDeliveryFeeMotorcycle;
  final double maxDeliveryFeeMotorcycle;
  final double minDeliveryFeeCar;
  final double maxDeliveryFeeCar;
  final double minDeliveryFeeMinibus;
  final double maxDeliveryFeeMinibus;
  final double minDeliveryFeeTukTuk;
  final double maxDeliveryFeeTukTuk;
  final double minDeliveryFeeMotorTricycle;
  final double maxDeliveryFeeMotorTricycle;
  final double minDeliveryFeeQuarterTruck;
  final double maxDeliveryFeeQuarterTruck;
  final double minDeliveryFeeHalfTruck;
  final double maxDeliveryFeeHalfTruck;
  final bool driverBonusActive;
  final double driverBonusAmount;
  final DateTime? driverBonusStartDate;
  final DateTime? driverBonusEndDate;
  final bool driverBonusPaidByCustomer;
  final double coinValue;
  final double amountSpentPerCoin;
  final int minCoinsToUse;
  final int maxMultiVendorVendors;
  final double driverSearchRadiusKm;
  final double driverSearchRadiusStepKm;
  final double driverSearchRadiusMaxKm;
  final int driverSearchMaxAttempts;
  final int driverAcceptTimeoutSecs;

  PlatformSettingsData({
    this.homeCoverUrl,
    this.motorcycleIconUrl,
    this.carIconUrl,
    this.minibusIconUrl,
    this.tukTukIconUrl,
    this.bicycleIconUrl,
    this.motorTricycleIconUrl,
    this.quarterTruckIconUrl,
    this.halfTruckIconUrl,
    this.isMaintenanceMode = false,
    this.supportEmail,
    this.supportPhone,
    this.supportWhatsapp,
    this.termsUrl,
    this.privacyUrl,
    this.deliveryBannerIconUrl,
    this.currency = 'EGP',
    this.minOrderAmount = 0,
    this.baseDeliveryFee = 15,
    this.customOrderPlatformFee = 10,
    this.defaultTaxRate = 14,
    this.pricePerKm = 3,
    this.pricePerKmBicycle = 2,
    this.pricePerKmMotorcycle = 3,
    this.pricePerKmCar = 5,
    this.pricePerKmMinibus = 8,
    this.pricePerKmTukTuk = 4,
    this.pricePerKmMotorTricycle = 4,
    this.pricePerKmQuarterTruck = 8,
    this.pricePerKmHalfTruck = 12,
    this.allowBicycle = true,
    this.allowMotorcycle = true,
    this.allowCar = true,
    this.allowMinibus = true,
    this.allowTukTuk = true,
    this.allowMotorTricycle = true,
    this.allowQuarterTruck = true,
    this.allowHalfTruck = true,
    this.serviceEligibleVehicles = const {},
    this.maxKmForBicycle = 5.0,
    this.maxDeliveryRadiusKm = 1500,
    this.minOrderKm = 0,
    this.minDistanceFixedPrice = 0,
    this.maxDeliveryFee = 0,
    this.minDeliveryFeeBicycle = 0,
    this.maxDeliveryFeeBicycle = 0,
    this.minDeliveryFeeMotorcycle = 0,
    this.maxDeliveryFeeMotorcycle = 0,
    this.minDeliveryFeeCar = 0,
    this.maxDeliveryFeeCar = 0,
    this.minDeliveryFeeMinibus = 0,
    this.maxDeliveryFeeMinibus = 0,
    this.minDeliveryFeeTukTuk = 0,
    this.maxDeliveryFeeTukTuk = 0,
    this.minDeliveryFeeMotorTricycle = 0,
    this.maxDeliveryFeeMotorTricycle = 0,
    this.minDeliveryFeeQuarterTruck = 0,
    this.maxDeliveryFeeQuarterTruck = 0,
    this.minDeliveryFeeHalfTruck = 0,
    this.maxDeliveryFeeHalfTruck = 0,
    this.driverBonusActive = false,
    this.driverBonusAmount = 0,
    this.driverBonusStartDate,
    this.driverBonusEndDate,
    this.driverBonusPaidByCustomer = false,
    this.coinValue = 1,
    this.amountSpentPerCoin = 10,
    this.minCoinsToUse = 1,
    this.maxMultiVendorVendors = 5,
    this.driverSearchRadiusKm = 3,
    this.driverSearchRadiusStepKm = 3,
    this.driverSearchRadiusMaxKm = 15,
    this.driverSearchMaxAttempts = 5,
    this.driverAcceptTimeoutSecs = 30,
  });

  bool isVehicleAllowed(String? rawVehicleType) {
    switch (VehicleTypeHelper.normalize(rawVehicleType)) {
      case VehicleTypeHelper.bicycle:
        return allowBicycle;
      case VehicleTypeHelper.motorcycle:
        return allowMotorcycle;
      case VehicleTypeHelper.car:
        return allowCar;
      case VehicleTypeHelper.minibus:
        return allowMinibus;
      case VehicleTypeHelper.tukTuk:
        return allowTukTuk;
      case VehicleTypeHelper.motorTricycle:
        return allowMotorTricycle;
      case VehicleTypeHelper.quarterTruck:
        return allowQuarterTruck;
      case VehicleTypeHelper.halfTruck:
        return allowHalfTruck;
      default:
        return false;
    }
  }

  String? iconUrlForVehicle(String? rawVehicleType) {
    switch (VehicleTypeHelper.normalize(rawVehicleType)) {
      case VehicleTypeHelper.bicycle:
        return bicycleIconUrl;
      case VehicleTypeHelper.motorcycle:
        return motorcycleIconUrl;
      case VehicleTypeHelper.car:
        return carIconUrl;
      case VehicleTypeHelper.minibus:
        return minibusIconUrl;
      case VehicleTypeHelper.tukTuk:
        return tukTukIconUrl;
      case VehicleTypeHelper.motorTricycle:
        return motorTricycleIconUrl;
      case VehicleTypeHelper.quarterTruck:
        return quarterTruckIconUrl;
      case VehicleTypeHelper.halfTruck:
        return halfTruckIconUrl;
      default:
        return null;
    }
  }

  ({double perKm, double minFee, double maxFee}) pricingForVehicle(
    String? rawVehicleType,
  ) {
    switch (VehicleTypeHelper.normalize(rawVehicleType)) {
      case VehicleTypeHelper.bicycle:
        return (
          perKm: pricePerKmBicycle,
          minFee: minDeliveryFeeBicycle,
          maxFee: maxDeliveryFeeBicycle,
        );
      case VehicleTypeHelper.motorcycle:
        return (
          perKm: pricePerKmMotorcycle,
          minFee: minDeliveryFeeMotorcycle,
          maxFee: maxDeliveryFeeMotorcycle,
        );
      case VehicleTypeHelper.car:
        return (
          perKm: pricePerKmCar,
          minFee: minDeliveryFeeCar,
          maxFee: maxDeliveryFeeCar,
        );
      case VehicleTypeHelper.minibus:
        return (
          perKm: pricePerKmMinibus,
          minFee: minDeliveryFeeMinibus,
          maxFee: maxDeliveryFeeMinibus,
        );
      case VehicleTypeHelper.tukTuk:
        return (
          perKm: pricePerKmTukTuk,
          minFee: minDeliveryFeeTukTuk,
          maxFee: maxDeliveryFeeTukTuk,
        );
      case VehicleTypeHelper.motorTricycle:
        return (
          perKm: pricePerKmMotorTricycle,
          minFee: minDeliveryFeeMotorTricycle,
          maxFee: maxDeliveryFeeMotorTricycle,
        );
      case VehicleTypeHelper.quarterTruck:
        return (
          perKm: pricePerKmQuarterTruck,
          minFee: minDeliveryFeeQuarterTruck,
          maxFee: maxDeliveryFeeQuarterTruck,
        );
      case VehicleTypeHelper.halfTruck:
        return (
          perKm: pricePerKmHalfTruck,
          minFee: minDeliveryFeeHalfTruck,
          maxFee: maxDeliveryFeeHalfTruck,
        );
      default:
        return (
          perKm: pricePerKmMotorcycle,
          minFee: minDeliveryFeeMotorcycle,
          maxFee: maxDeliveryFeeMotorcycle,
        );
    }
  }

  List<String> enabledVehiclesForService(String serviceType) {
    return VehicleTypeHelper.eligibleForOrderType(
      serviceType,
      backendMatrix: serviceEligibleVehicles,
    ).where(isVehicleAllowed).toList(growable: false);
  }

  factory PlatformSettingsData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final parsedMaxMultiVendor =
        int.tryParse(json['maxMultiVendorVendors']?.toString() ?? '') ?? 5;

    final rawMatrix = json['serviceEligibleVehicles'];
    final parsedMatrix = <String, List<String>>{};
    if (rawMatrix is Map) {
      for (final entry in rawMatrix.entries) {
        if (entry.value is List) {
          final items = (entry.value as List)
              .map((e) => VehicleTypeHelper.normalize(e?.toString()))
              .whereType<String>()
              .toList(growable: false);
          if (items.isNotEmpty) {
            parsedMatrix[entry.key.toString().toUpperCase()] = items;
          }
        }
      }
    }

    return PlatformSettingsData(
      homeCoverUrl: json['homeCoverUrl'],
      motorcycleIconUrl: json['motorcycleIconUrl'],
      carIconUrl: json['carIconUrl'],
      minibusIconUrl: json['minibusIconUrl'],
      tukTukIconUrl: json['tukTukIconUrl'],
      bicycleIconUrl: json['bicycleIconUrl'],
      motorTricycleIconUrl: json['motorTricycleIconUrl'],
      quarterTruckIconUrl: json['quarterTruckIconUrl'],
      halfTruckIconUrl: json['halfTruckIconUrl'],
      isMaintenanceMode: json['isMaintenanceMode'] ?? false,
      supportEmail: json['support']?['email'] ?? json['supportEmail'],
      supportPhone: json['support']?['phone'] ?? json['supportPhone'],
      supportWhatsapp: json['support']?['whatsapp'] ?? json['supportWhatsapp'],
      termsUrl: json['legal']?['termsUrl'] ?? json['termsUrl'],
      privacyUrl: json['legal']?['privacyUrl'] ?? json['privacyUrl'],
      deliveryBannerIconUrl: json['deliveryBannerIconUrl'],
      currency: json['currency'] ?? 'EGP',
      minOrderAmount: double.tryParse(json['minOrderAmount']?.toString() ?? '0') ?? 0,
      baseDeliveryFee: double.tryParse(json['baseDeliveryFee']?.toString() ?? '15') ?? 15,
      customOrderPlatformFee: double.tryParse(json['customOrderPlatformFee']?.toString() ?? '10') ?? 10,
      defaultTaxRate: double.tryParse(json['defaultTaxRate']?.toString() ?? '14') ?? 14,
      pricePerKm: double.tryParse(json['pricePerKm']?.toString() ?? '3') ?? 3,
      pricePerKmBicycle: double.tryParse(json['pricePerKmBicycle']?.toString() ?? '2') ?? 2,
      pricePerKmMotorcycle: double.tryParse(json['pricePerKmMotorcycle']?.toString() ?? '3') ?? 3,
      pricePerKmCar: double.tryParse(json['pricePerKmCar']?.toString() ?? '5') ?? 5,
      pricePerKmMinibus: double.tryParse(json['pricePerKmMinibus']?.toString() ?? '8') ?? 8,
      pricePerKmTukTuk: double.tryParse(json['pricePerKmTukTuk']?.toString() ?? '4') ?? 4,
      pricePerKmMotorTricycle: double.tryParse(json['pricePerKmMotorTricycle']?.toString() ?? '4') ?? 4,
      pricePerKmQuarterTruck: double.tryParse(json['pricePerKmQuarterTruck']?.toString() ?? '8') ?? 8,
      pricePerKmHalfTruck: double.tryParse(json['pricePerKmHalfTruck']?.toString() ?? '12') ?? 12,
      allowBicycle: json['allowBicycle'] ?? true,
      allowMotorcycle: json['allowMotorcycle'] ?? true,
      allowCar: json['allowCar'] ?? true,
      allowMinibus: json['allowMinibus'] ?? true,
      allowTukTuk: json['allowTukTuk'] ?? true,
      allowMotorTricycle: json['allowMotorTricycle'] ?? true,
      allowQuarterTruck: json['allowQuarterTruck'] ?? true,
      allowHalfTruck: json['allowHalfTruck'] ?? true,
      serviceEligibleVehicles: parsedMatrix,
      maxKmForBicycle: double.tryParse(json['maxKmForBicycle']?.toString() ?? '5.0') ?? 5.0,
      maxDeliveryRadiusKm: double.tryParse(json['maxDeliveryRadiusKm']?.toString() ?? '1500') ?? 1500,
      minOrderKm: double.tryParse(json['minOrderKm']?.toString() ?? '0') ?? 0,
      minDistanceFixedPrice: double.tryParse(json['minDistanceFixedPrice']?.toString() ?? '0') ?? 0,
      maxDeliveryFee: double.tryParse(json['maxDeliveryFee']?.toString() ?? '0') ?? 0,
      minDeliveryFeeBicycle: double.tryParse(json['minDeliveryFeeBicycle']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeBicycle: double.tryParse(json['maxDeliveryFeeBicycle']?.toString() ?? '0') ?? 0,
      minDeliveryFeeMotorcycle: double.tryParse(json['minDeliveryFeeMotorcycle']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeMotorcycle: double.tryParse(json['maxDeliveryFeeMotorcycle']?.toString() ?? '0') ?? 0,
      minDeliveryFeeCar: double.tryParse(json['minDeliveryFeeCar']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeCar: double.tryParse(json['maxDeliveryFeeCar']?.toString() ?? '0') ?? 0,
      minDeliveryFeeMinibus: double.tryParse(json['minDeliveryFeeMinibus']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeMinibus: double.tryParse(json['maxDeliveryFeeMinibus']?.toString() ?? '0') ?? 0,
      minDeliveryFeeTukTuk: double.tryParse(json['minDeliveryFeeTukTuk']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeTukTuk: double.tryParse(json['maxDeliveryFeeTukTuk']?.toString() ?? '0') ?? 0,
      minDeliveryFeeMotorTricycle: double.tryParse(json['minDeliveryFeeMotorTricycle']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeMotorTricycle: double.tryParse(json['maxDeliveryFeeMotorTricycle']?.toString() ?? '0') ?? 0,
      minDeliveryFeeQuarterTruck: double.tryParse(json['minDeliveryFeeQuarterTruck']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeQuarterTruck: double.tryParse(json['maxDeliveryFeeQuarterTruck']?.toString() ?? '0') ?? 0,
      minDeliveryFeeHalfTruck: double.tryParse(json['minDeliveryFeeHalfTruck']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeHalfTruck: double.tryParse(json['maxDeliveryFeeHalfTruck']?.toString() ?? '0') ?? 0,
      driverBonusActive: json['driverBonusActive'] ?? false,
      driverBonusAmount: double.tryParse(json['driverBonusAmount']?.toString() ?? '0') ?? 0,
      driverBonusStartDate: parseDate(json['driverBonusStartDate']),
      driverBonusEndDate: parseDate(json['driverBonusEndDate']),
      driverBonusPaidByCustomer: json['driverBonusPaidByCustomer'] ?? false,
      coinValue: double.tryParse(json['coinValue']?.toString() ?? '1') ?? 1,
      amountSpentPerCoin: double.tryParse(json['amountSpentPerCoin']?.toString() ?? '10') ?? 10,
      minCoinsToUse: int.tryParse(json['minCoinsToUse']?.toString() ?? '1') ?? 1,
      maxMultiVendorVendors: parsedMaxMultiVendor < 1 ? 5 : parsedMaxMultiVendor,
      driverSearchRadiusKm:
          double.tryParse(json['driverSearchRadiusKm']?.toString() ?? '3') ?? 3,
      driverSearchRadiusStepKm:
          double.tryParse(json['driverSearchRadiusStepKm']?.toString() ?? '3') ??
              3,
      driverSearchRadiusMaxKm:
          double.tryParse(json['driverSearchRadiusMaxKm']?.toString() ?? '15') ??
              15,
      driverSearchMaxAttempts:
          int.tryParse(json['driverSearchMaxAttempts']?.toString() ?? '5') ?? 5,
      driverAcceptTimeoutSecs:
          int.tryParse(json['driverAcceptTimeoutSecs']?.toString() ?? '30') ??
              30,
    );
  }
}

@riverpod
Future<PlatformSettingsData> platformSettings(Ref ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get(
      '/platform-settings/public',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data['data'] ?? response.data;
    return PlatformSettingsData.fromJson(data);
  } catch (e) {
    // Fallback to defaults on error
    return PlatformSettingsData();
  }
}
