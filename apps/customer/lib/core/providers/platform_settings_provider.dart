import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/network_providers.dart';

part 'platform_settings_provider.g.dart';

class PlatformSettingsData {
  final String? homeCoverUrl;
  final String? motorcycleIconUrl;
  final String? carIconUrl;
  final String? bicycleIconUrl;
  final String? motorTricycleIconUrl;
  final String? vanIconUrl;
  final String? truckIconUrl;
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
  final double pricePerKmVan;
  final double pricePerKmTruck;
  final double pricePerKmMotorTricycle;
  final bool allowBicycle;
  final bool allowMotorcycle;
  final bool allowCar;
  final bool allowVan;
  final bool allowTruck;
  final bool allowMotorTricycle;
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
  final double minDeliveryFeeVan;
  final double maxDeliveryFeeVan;
  final double minDeliveryFeeTruck;
  final double maxDeliveryFeeTruck;
  final double minDeliveryFeeMotorTricycle;
  final double maxDeliveryFeeMotorTricycle;
  final bool driverBonusActive;
  final double driverBonusAmount;
  final DateTime? driverBonusStartDate;
  final DateTime? driverBonusEndDate;
  final bool driverBonusPaidByCustomer;
  final double coinValue;
  final double amountSpentPerCoin;
  final int minCoinsToUse;

  PlatformSettingsData({
    this.homeCoverUrl,
    this.motorcycleIconUrl,
    this.carIconUrl,
    this.bicycleIconUrl,
    this.motorTricycleIconUrl,
    this.vanIconUrl,
    this.truckIconUrl,
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
    this.pricePerKmVan = 8,
    this.pricePerKmTruck = 12,
    this.pricePerKmMotorTricycle = 4,
    this.allowBicycle = true,
    this.allowMotorcycle = true,
    this.allowCar = true,
    this.allowVan = true,
    this.allowTruck = true,
    this.allowMotorTricycle = true,
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
    this.minDeliveryFeeVan = 0,
    this.maxDeliveryFeeVan = 0,
    this.minDeliveryFeeTruck = 0,
    this.maxDeliveryFeeTruck = 0,
    this.minDeliveryFeeMotorTricycle = 0,
    this.maxDeliveryFeeMotorTricycle = 0,
    this.driverBonusActive = false,
    this.driverBonusAmount = 0,
    this.driverBonusStartDate,
    this.driverBonusEndDate,
    this.driverBonusPaidByCustomer = false,
    this.coinValue = 1,
    this.amountSpentPerCoin = 10,
    this.minCoinsToUse = 1,
  });

  factory PlatformSettingsData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PlatformSettingsData(
      homeCoverUrl: json['homeCoverUrl'],
      motorcycleIconUrl: json['motorcycleIconUrl'],
      carIconUrl: json['carIconUrl'],
      bicycleIconUrl: json['bicycleIconUrl'],
      motorTricycleIconUrl: json['motorTricycleIconUrl'],
      vanIconUrl: json['vanIconUrl'],
      truckIconUrl: json['truckIconUrl'],
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
      pricePerKmVan: double.tryParse(json['pricePerKmVan']?.toString() ?? '8') ?? 8,
      pricePerKmTruck: double.tryParse(json['pricePerKmTruck']?.toString() ?? '12') ?? 12,
      pricePerKmMotorTricycle: double.tryParse(json['pricePerKmMotorTricycle']?.toString() ?? '4') ?? 4,
      allowBicycle: json['allowBicycle'] ?? true,
      allowMotorcycle: json['allowMotorcycle'] ?? true,
      allowCar: json['allowCar'] ?? true,
      allowVan: json['allowVan'] ?? true,
      allowTruck: json['allowTruck'] ?? true,
      allowMotorTricycle: json['allowMotorTricycle'] ?? true,
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
      minDeliveryFeeVan: double.tryParse(json['minDeliveryFeeVan']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeVan: double.tryParse(json['maxDeliveryFeeVan']?.toString() ?? '0') ?? 0,
      minDeliveryFeeTruck: double.tryParse(json['minDeliveryFeeTruck']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeTruck: double.tryParse(json['maxDeliveryFeeTruck']?.toString() ?? '0') ?? 0,
      minDeliveryFeeMotorTricycle: double.tryParse(json['minDeliveryFeeMotorTricycle']?.toString() ?? '0') ?? 0,
      maxDeliveryFeeMotorTricycle: double.tryParse(json['maxDeliveryFeeMotorTricycle']?.toString() ?? '0') ?? 0,
      driverBonusActive: json['driverBonusActive'] ?? false,
      driverBonusAmount: double.tryParse(json['driverBonusAmount']?.toString() ?? '0') ?? 0,
      driverBonusStartDate: parseDate(json['driverBonusStartDate']),
      driverBonusEndDate: parseDate(json['driverBonusEndDate']),
      driverBonusPaidByCustomer: json['driverBonusPaidByCustomer'] ?? false,
      coinValue: double.tryParse(json['coinValue']?.toString() ?? '1') ?? 1,
      amountSpentPerCoin: double.tryParse(json['amountSpentPerCoin']?.toString() ?? '10') ?? 10,
      minCoinsToUse: int.tryParse(json['minCoinsToUse']?.toString() ?? '1') ?? 1,
    );
  }
}

@riverpod
Future<PlatformSettingsData> platformSettings(Ref ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/platform-settings/public');
    final data = response.data['data'] ?? response.data;
    return PlatformSettingsData.fromJson(data);
  } catch (e) {
    // Fallback to defaults on error
    return PlatformSettingsData();
  }
}
