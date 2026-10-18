import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart' as dio;
import 'package:core/core.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  AsyncValue<Map<String, dynamic>> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchSettings() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(adminPlatformSettingsRepositoryProvider);
      final data = await repository.platformSettingsGetAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(ApiErrorMapper.fromError(e), st);
    }
  }

  static const _breakKeys = {
    'breaksEnabled',
    'maxBreakMinutesPerShift',
    'maxBreaksPerShift',
    'maxSingleBreakMinutes',
    'pendingBreakExpiryMins',
  };

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final repository = ref.read(adminPlatformSettingsRepositoryProvider);

    // Break quota keys bypass the generated DTO (it predates them) via a
    // raw PATCH. Everything else flows through the typed client as before.
    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value.toString().toLowerCase() == 'true') return true;
      if (value.toString().toLowerCase() == 'false') return false;
      return null;
    }

    num? toNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      return num.tryParse(value.toString());
    }

    final breakData = <String, dynamic>{};
    for (final key in _breakKeys) {
      if (!settings.containsKey(key)) continue;
      final value = settings[key];
      if (key == 'breaksEnabled') {
        final parsed = toBool(value);
        if (parsed != null) breakData[key] = parsed;
      } else {
        final numValue = toNum(value);
        if (numValue != null) breakData[key] = numValue.toInt();
      }
    }
    final rest = Map<String, dynamic>.of(settings)
      ..removeWhere((key, _) => _breakKeys.contains(key));

    if (breakData.isNotEmpty) {
      await repository.platformSettingsUpdateBreaks(breakData);
    }
    if (rest.isEmpty) {
      await fetchSettings();
      return;
    }

    final updatedData = await repository.platformSettingsUpdate(updatePlatformSettingsDto: UpdatePlatformSettingsDto((b) {
      num? parseNum(dynamic value) {
        if (value == null) return null;
        if (value is num) return value;
        return num.tryParse(value.toString());
      }
      
      bool? parseBool(dynamic value) {
        if (value == null) return null;
        if (value is bool) return value;
        if (value.toString().toLowerCase() == 'true') return true;
        if (value.toString().toLowerCase() == 'false') return false;
        return null;
      }
      
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        return DateTime.tryParse(value.toString());
      }

      if (settings.containsKey('currency')) b.currency = settings['currency'];
      if (settings.containsKey('defaultCommissionRate')) b.defaultCommissionRate = parseNum(settings['defaultCommissionRate']);
      if (settings.containsKey('deliveryCommissionRate')) b.deliveryCommissionRate = parseNum(settings['deliveryCommissionRate']);
      if (settings.containsKey('customOrderPlatformFee')) b.customOrderPlatformFee = parseNum(settings['customOrderPlatformFee']);
      if (settings.containsKey('defaultTaxRate')) b.defaultTaxRate = parseNum(settings['defaultTaxRate']);
      if (settings.containsKey('minOrderAmount')) b.minOrderAmount = parseNum(settings['minOrderAmount']);
      if (settings.containsKey('baseDeliveryFee')) b.baseDeliveryFee = parseNum(settings['baseDeliveryFee']);
      if (settings.containsKey('pricePerKm')) b.pricePerKm = parseNum(settings['pricePerKm']);
      if (settings.containsKey('pricePerKmBicycle')) b.pricePerKmBicycle = parseNum(settings['pricePerKmBicycle']);
      if (settings.containsKey('pricePerKmMotorcycle')) b.pricePerKmMotorcycle = parseNum(settings['pricePerKmMotorcycle']);
      if (settings.containsKey('pricePerKmCar')) b.pricePerKmCar = parseNum(settings['pricePerKmCar']);
      if (settings.containsKey('pricePerKmVan')) b.pricePerKmVan = parseNum(settings['pricePerKmVan']);
      if (settings.containsKey('pricePerKmTruck')) b.pricePerKmTruck = parseNum(settings['pricePerKmTruck']);
      if (settings.containsKey('pricePerKmMotorTricycle')) b.pricePerKmMotorTricycle = parseNum(settings['pricePerKmMotorTricycle']);
      if (settings.containsKey('maxDeliveryFee')) b.maxDeliveryFee = parseNum(settings['maxDeliveryFee']);
      if (settings.containsKey('minDeliveryFeeBicycle')) b.minDeliveryFeeBicycle = parseNum(settings['minDeliveryFeeBicycle']);
      if (settings.containsKey('maxDeliveryFeeBicycle')) b.maxDeliveryFeeBicycle = parseNum(settings['maxDeliveryFeeBicycle']);
      if (settings.containsKey('minDeliveryFeeMotorcycle')) b.minDeliveryFeeMotorcycle = parseNum(settings['minDeliveryFeeMotorcycle']);
      if (settings.containsKey('maxDeliveryFeeMotorcycle')) b.maxDeliveryFeeMotorcycle = parseNum(settings['maxDeliveryFeeMotorcycle']);
      if (settings.containsKey('minDeliveryFeeCar')) b.minDeliveryFeeCar = parseNum(settings['minDeliveryFeeCar']);
      if (settings.containsKey('maxDeliveryFeeCar')) b.maxDeliveryFeeCar = parseNum(settings['maxDeliveryFeeCar']);
      if (settings.containsKey('minDeliveryFeeVan')) b.minDeliveryFeeVan = parseNum(settings['minDeliveryFeeVan']);
      if (settings.containsKey('maxDeliveryFeeVan')) b.maxDeliveryFeeVan = parseNum(settings['maxDeliveryFeeVan']);
      if (settings.containsKey('minDeliveryFeeTruck')) b.minDeliveryFeeTruck = parseNum(settings['minDeliveryFeeTruck']);
      if (settings.containsKey('maxDeliveryFeeTruck')) b.maxDeliveryFeeTruck = parseNum(settings['maxDeliveryFeeTruck']);
      if (settings.containsKey('minDeliveryFeeMotorTricycle')) b.minDeliveryFeeMotorTricycle = parseNum(settings['minDeliveryFeeMotorTricycle']);
      if (settings.containsKey('maxDeliveryFeeMotorTricycle')) b.maxDeliveryFeeMotorTricycle = parseNum(settings['maxDeliveryFeeMotorTricycle']);
      if (settings.containsKey('minOrderKm')) b.minOrderKm = parseNum(settings['minOrderKm']);
      if (settings.containsKey('minDistanceFixedPrice')) b.minDistanceFixedPrice = parseNum(settings['minDistanceFixedPrice']);
      if (settings.containsKey('maxDeliveryRadiusKm')) b.maxDeliveryRadiusKm = parseNum(settings['maxDeliveryRadiusKm']);
      if (settings.containsKey('driverSearchRadiusKm')) b.driverSearchRadiusKm = parseNum(settings['driverSearchRadiusKm']);
      if (settings.containsKey('driverSearchRadiusStepKm')) b.driverSearchRadiusStepKm = parseNum(settings['driverSearchRadiusStepKm']);
      if (settings.containsKey('driverSearchRadiusMaxKm')) b.driverSearchRadiusMaxKm = parseNum(settings['driverSearchRadiusMaxKm']);
      if (settings.containsKey('driverSearchMaxAttempts')) b.driverSearchMaxAttempts = parseNum(settings['driverSearchMaxAttempts']);
      if (settings.containsKey('driverAcceptTimeoutSecs')) b.driverAcceptTimeoutSecs = parseNum(settings['driverAcceptTimeoutSecs']);
      if (settings.containsKey('autoCancelPendingMins')) b.autoCancelPendingMins = parseNum(settings['autoCancelPendingMins']);
      if (settings.containsKey('maxDispatchBatchSize')) b.maxDispatchBatchSize = parseNum(settings['maxDispatchBatchSize']);
      if (settings.containsKey('mobileWalletTimeoutMins')) b.mobileWalletTimeoutMins = parseNum(settings['mobileWalletTimeoutMins']);
      if (settings.containsKey('isMaintenanceMode')) b.isMaintenanceMode = parseBool(settings['isMaintenanceMode']);
      if (settings.containsKey('androidMinVersion')) b.androidMinVersion = settings['androidMinVersion'];
      if (settings.containsKey('androidLatestVersion')) b.androidLatestVersion = settings['androidLatestVersion'];
      if (settings.containsKey('androidForceUpdate')) b.androidForceUpdate = parseBool(settings['androidForceUpdate']);
      if (settings.containsKey('androidStoreUrl')) b.androidStoreUrl = settings['androidStoreUrl'];
      if (settings.containsKey('iosMinVersion')) b.iosMinVersion = settings['iosMinVersion'];
      if (settings.containsKey('iosLatestVersion')) b.iosLatestVersion = settings['iosLatestVersion'];
      if (settings.containsKey('iosForceUpdate')) b.iosForceUpdate = parseBool(settings['iosForceUpdate']);
      if (settings.containsKey('iosStoreUrl')) b.iosStoreUrl = settings['iosStoreUrl'];
      if (settings.containsKey('supportEmail')) b.supportEmail = settings['supportEmail'];
      if (settings.containsKey('supportPhone')) b.supportPhone = settings['supportPhone'];
      if (settings.containsKey('supportWhatsapp')) b.supportWhatsapp = settings['supportWhatsapp'];
      if (settings.containsKey('termsUrl')) b.termsUrl = settings['termsUrl'];
      if (settings.containsKey('privacyUrl')) b.privacyUrl = settings['privacyUrl'];
      if (settings.containsKey('retentionOrdersDays')) b.retentionOrdersDays = parseNum(settings['retentionOrdersDays']);
      if (settings.containsKey('retentionArchivedChatsDays')) b.retentionArchivedChatsDays = parseNum(settings['retentionArchivedChatsDays']);
      if (settings.containsKey('retentionNotificationsDays')) b.retentionNotificationsDays = parseNum(settings['retentionNotificationsDays']);
      if (settings.containsKey('retentionExpiredSessionsDays')) b.retentionExpiredSessionsDays = parseNum(settings['retentionExpiredSessionsDays']);
      if (settings.containsKey('retentionAuditLogsDays')) b.retentionAuditLogsDays = parseNum(settings['retentionAuditLogsDays']);
      if (settings.containsKey('retentionAbandonedCartsDays')) b.retentionAbandonedCartsDays = parseNum(settings['retentionAbandonedCartsDays']);
      if (settings.containsKey('retentionWalletTransactionsDays')) b.retentionWalletTransactionsDays = parseNum(settings['retentionWalletTransactionsDays']);
      if (settings.containsKey('retentionStatisticsDays')) b.retentionStatisticsDays = parseNum(settings['retentionStatisticsDays']);
      if (settings.containsKey('maxKmForBicycle')) b.maxKmForBicycle = parseNum(settings['maxKmForBicycle']);
      if (settings.containsKey('coinValue')) b.coinValue = parseNum(settings['coinValue']);
      if (settings.containsKey('amountSpentPerCoin')) b.amountSpentPerCoin = parseNum(settings['amountSpentPerCoin']);
      if (settings.containsKey('minCoinsToUse')) b.minCoinsToUse = parseNum(settings['minCoinsToUse']);
      if (settings.containsKey('driverBonusActive')) b.driverBonusActive = parseBool(settings['driverBonusActive']);
      if (settings.containsKey('driverBonusAmount')) b.driverBonusAmount = parseNum(settings['driverBonusAmount']);
      if (settings.containsKey('driverBonusStartDate')) b.driverBonusStartDate = parseDate(settings['driverBonusStartDate']);
      if (settings.containsKey('driverBonusEndDate')) b.driverBonusEndDate = parseDate(settings['driverBonusEndDate']);
      if (settings.containsKey('driverBonusPaidByCustomer')) b.driverBonusPaidByCustomer = parseBool(settings['driverBonusPaidByCustomer']);
      if (settings.containsKey('highValueOrderThreshold')) b.highValueOrderThreshold = parseNum(settings['highValueOrderThreshold']);
      if (settings.containsKey('highValueUpfrontRate')) b.highValueUpfrontRate = parseNum(settings['highValueUpfrontRate']);
      if (settings.containsKey('driverShiftsEnabled')) b.driverShiftsEnabled = parseBool(settings['driverShiftsEnabled']);
      if (settings.containsKey('bronzeTierBonusPerKm')) b.bronzeTierBonusPerKm = parseNum(settings['bronzeTierBonusPerKm']);
      if (settings.containsKey('silverTierBonusPerKm')) b.silverTierBonusPerKm = parseNum(settings['silverTierBonusPerKm']);
      if (settings.containsKey('goldTierBonusPerKm')) b.goldTierBonusPerKm = parseNum(settings['goldTierBonusPerKm']);
      if (settings.containsKey('driverSettlementOrderThreshold')) b.driverSettlementOrderThreshold = parseNum(settings['driverSettlementOrderThreshold']);
      if (settings.containsKey('allowBicycle')) b.allowBicycle = parseBool(settings['allowBicycle']);
      if (settings.containsKey('allowMotorcycle')) b.allowMotorcycle = parseBool(settings['allowMotorcycle']);
      if (settings.containsKey('allowCar')) b.allowCar = parseBool(settings['allowCar']);
      if (settings.containsKey('allowVan')) b.allowVan = parseBool(settings['allowVan']);
      if (settings.containsKey('allowTruck')) b.allowTruck = parseBool(settings['allowTruck']);
      if (settings.containsKey('allowMotorTricycle')) b.allowMotorTricycle = parseBool(settings['allowMotorTricycle']);
      if (settings.containsKey('maxActiveOrdersPerCustomer')) b.maxActiveOrdersPerCustomer = parseNum(settings['maxActiveOrdersPerCustomer']);
      if (settings.containsKey('requirePriorDeliveryForMultipleOrders')) b.requirePriorDeliveryForMultipleOrders = parseBool(settings['requirePriorDeliveryForMultipleOrders']);
      if (settings.containsKey('maxOtpAttempts')) b.maxOtpAttempts = parseNum(settings['maxOtpAttempts']);
      if (settings.containsKey('otpExpirySeconds')) b.otpExpirySeconds = parseNum(settings['otpExpirySeconds']);
    }));
    state = AsyncValue.data(updatedData);
  }

  Future<void> uploadSettingImage(
    String type,
    List<int> bytes,
    String fileName,
  ) async {
    final repository = ref.read(adminPlatformSettingsRepositoryProvider);
    final file = dio.MultipartFile.fromBytes(bytes, filename: fileName);
    if (type == 'home-cover') {
      await repository.platformSettingsUploadHomeCover(file: file);
    } else if (type == 'motorcycle') {
      await repository.platformSettingsUploadMotorcycleIcon(file: file);
    } else if (type == 'car') {
      await repository.platformSettingsUploadCarIcon(file: file);
    } else if (type == 'delivery-banner') {
      await repository.platformSettingsUploadDeliveryBannerIcon(file: file);
    } else if (type == 'bicycle' ||
        type == 'motor_tricycle' ||
        type == 'van' ||
        type == 'truck') {
      await repository.platformSettingsUploadVehicleIcon(
        vehicleType: type,
        file: file,
      );
    }
    await fetchSettings();
  }
}

