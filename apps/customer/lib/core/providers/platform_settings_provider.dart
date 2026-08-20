import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/network_providers.dart';

part 'platform_settings_provider.g.dart';

class PlatformSettingsData {
  final String? homeCoverUrl;
  final String? motorcycleIconUrl;
  final String? carIconUrl;
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
  final double coinValue;
  final double amountSpentPerCoin;
  final int minCoinsToUse;
  final bool requireCustomerApproval;
  final int customerApprovalTimeoutMins;

  PlatformSettingsData({
    this.homeCoverUrl,
    this.motorcycleIconUrl,
    this.carIconUrl,
    this.deliveryBannerIconUrl,
    this.currency = 'EGP',
    this.minOrderAmount = 0,
    this.baseDeliveryFee = 15,
    this.customOrderPlatformFee = 0,
    this.defaultTaxRate = 14,
    this.pricePerKm = 3,
    this.pricePerKmBicycle = 2,
    this.pricePerKmMotorcycle = 3,
    this.pricePerKmCar = 5,
    this.pricePerKmVan = 8,
    this.pricePerKmTruck = 12,
    this.pricePerKmMotorTricycle = 4,
    this.coinValue = 1,
    this.amountSpentPerCoin = 10,
    this.minCoinsToUse = 1,
    this.requireCustomerApproval = true,
    this.customerApprovalTimeoutMins = 10,
  });

  factory PlatformSettingsData.fromJson(Map<String, dynamic> json) {
    return PlatformSettingsData(
      homeCoverUrl: json['homeCoverUrl'],
      motorcycleIconUrl: json['motorcycleIconUrl'],
      carIconUrl: json['carIconUrl'],
      deliveryBannerIconUrl: json['deliveryBannerIconUrl'],
      currency: json['currency'] ?? 'EGP',
      minOrderAmount: double.tryParse(json['minOrderAmount']?.toString() ?? '0') ?? 0,
      baseDeliveryFee: double.tryParse(json['baseDeliveryFee']?.toString() ?? '15') ?? 15,
      customOrderPlatformFee: double.tryParse(json['customOrderPlatformFee']?.toString() ?? '0') ?? 0,
      defaultTaxRate: double.tryParse(json['defaultTaxRate']?.toString() ?? '14') ?? 14,
      pricePerKm: double.tryParse(json['pricePerKm']?.toString() ?? '3') ?? 3,
      pricePerKmBicycle: double.tryParse(json['pricePerKmBicycle']?.toString() ?? '2') ?? 2,
      pricePerKmMotorcycle: double.tryParse(json['pricePerKmMotorcycle']?.toString() ?? '3') ?? 3,
      pricePerKmCar: double.tryParse(json['pricePerKmCar']?.toString() ?? '5') ?? 5,
      pricePerKmVan: double.tryParse(json['pricePerKmVan']?.toString() ?? '8') ?? 8,
      pricePerKmTruck: double.tryParse(json['pricePerKmTruck']?.toString() ?? '12') ?? 12,
      pricePerKmMotorTricycle: double.tryParse(json['pricePerKmMotorTricycle']?.toString() ?? '4') ?? 4,
      coinValue: double.tryParse(json['coinValue']?.toString() ?? '1') ?? 1,
      amountSpentPerCoin: double.tryParse(json['amountSpentPerCoin']?.toString() ?? '10') ?? 10,
      minCoinsToUse: int.tryParse(json['minCoinsToUse']?.toString() ?? '1') ?? 1,
      requireCustomerApproval: json['requireCustomerApproval'] ?? true,
      customerApprovalTimeoutMins: int.tryParse(json['customerApprovalTimeoutMins']?.toString() ?? '10') ?? 10,
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
