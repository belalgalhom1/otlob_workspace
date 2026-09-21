//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_setting.g.dart';

/// PlatformSetting
///
/// Properties:
/// * [id] 
/// * [currency] 
/// * [defaultCommissionRate] 
/// * [deliveryCommissionRate] 
/// * [defaultTaxRate] 
/// * [minOrderAmount] 
/// * [baseDeliveryFee] 
/// * [pricePerKm] 
/// * [pricePerKmBicycle] 
/// * [pricePerKmMotorcycle] 
/// * [pricePerKmCar] 
/// * [pricePerKmVan] 
/// * [pricePerKmTruck] 
/// * [pricePerKmMotorTricycle] 
/// * [maxDeliveryFee] 
/// * [minDeliveryFeeBicycle] 
/// * [maxDeliveryFeeBicycle] 
/// * [minDeliveryFeeMotorcycle] 
/// * [maxDeliveryFeeMotorcycle] 
/// * [minDeliveryFeeCar] 
/// * [maxDeliveryFeeCar] 
/// * [minDeliveryFeeVan] 
/// * [maxDeliveryFeeVan] 
/// * [minDeliveryFeeTruck] 
/// * [maxDeliveryFeeTruck] 
/// * [minDeliveryFeeMotorTricycle] 
/// * [maxDeliveryFeeMotorTricycle] 
/// * [allowBicycle] 
/// * [allowMotorcycle] 
/// * [allowCar] 
/// * [allowVan] 
/// * [allowTruck] 
/// * [allowMotorTricycle] 
/// * [minOrderKm] 
/// * [minDistanceFixedPrice] 
/// * [maxDeliveryRadiusKm] 
/// * [driverSearchRadiusKm] 
/// * [driverSearchRadiusStepKm] 
/// * [driverSearchRadiusMaxKm] 
/// * [autoCancelPendingMins] 
/// * [driverAcceptTimeoutSecs] 
/// * [isMaintenanceMode] 
/// * [androidMinVersion] 
/// * [androidLatestVersion] 
/// * [androidForceUpdate] 
/// * [androidStoreUrl] 
/// * [iosMinVersion] 
/// * [iosLatestVersion] 
/// * [iosForceUpdate] 
/// * [iosStoreUrl] 
/// * [supportEmail] 
/// * [supportPhone] 
/// * [supportWhatsapp] 
/// * [termsUrl] 
/// * [privacyUrl] 
/// * [homeCoverUrl] 
/// * [motorcycleIconUrl] 
/// * [carIconUrl] 
/// * [deliveryBannerIconUrl] 
/// * [retentionOrdersDays] 
/// * [retentionArchivedChatsDays] 
/// * [retentionNotificationsDays] 
/// * [retentionExpiredSessionsDays] 
/// * [retentionAuditLogsDays] 
/// * [retentionAbandonedCartsDays] 
/// * [retentionWalletTransactionsDays] 
/// * [retentionStatisticsDays] 
/// * [maxKmForBicycle] 
/// * [driverSearchMaxAttempts] 
/// * [fallbackOrderDistanceKm] 
/// * [customOrderPlatformFee] 
/// * [maxDispatchBatchSize] 
/// * [coinValue] 
/// * [amountSpentPerCoin] 
/// * [minCoinsToUse] 
/// * [driverBonusActive] 
/// * [driverBonusAmount] 
/// * [driverBonusStartDate] 
/// * [driverBonusEndDate] 
/// * [driverBonusPaidByCustomer] 
/// * [driverShiftsEnabled] 
/// * [maxActiveOrdersPerCustomer] 
/// * [requirePriorDeliveryForMultipleOrders] 
/// * [maxOtpAttempts] 
/// * [maxNegativeDriverBalance] 
/// * [otpExpirySeconds] 
/// * [bronzeTierBonusPerKm] 
/// * [silverTierBonusPerKm] 
/// * [goldTierBonusPerKm] 
/// * [highValueOrderThreshold] 
/// * [highValueUpfrontRate] 
/// * [updatedAt] 
@BuiltValue()
abstract class PlatformSetting implements Built<PlatformSetting, PlatformSettingBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'defaultCommissionRate')
  num get defaultCommissionRate;

  @BuiltValueField(wireName: r'deliveryCommissionRate')
  num get deliveryCommissionRate;

  @BuiltValueField(wireName: r'defaultTaxRate')
  num get defaultTaxRate;

  @BuiltValueField(wireName: r'minOrderAmount')
  num get minOrderAmount;

  @BuiltValueField(wireName: r'baseDeliveryFee')
  num get baseDeliveryFee;

  @BuiltValueField(wireName: r'pricePerKm')
  num get pricePerKm;

  @BuiltValueField(wireName: r'pricePerKmBicycle')
  num get pricePerKmBicycle;

  @BuiltValueField(wireName: r'pricePerKmMotorcycle')
  num get pricePerKmMotorcycle;

  @BuiltValueField(wireName: r'pricePerKmCar')
  num get pricePerKmCar;

  @BuiltValueField(wireName: r'pricePerKmVan')
  num get pricePerKmVan;

  @BuiltValueField(wireName: r'pricePerKmTruck')
  num get pricePerKmTruck;

  @BuiltValueField(wireName: r'pricePerKmMotorTricycle')
  num get pricePerKmMotorTricycle;

  @BuiltValueField(wireName: r'maxDeliveryFee')
  num get maxDeliveryFee;

  @BuiltValueField(wireName: r'minDeliveryFeeBicycle')
  num get minDeliveryFeeBicycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeBicycle')
  num get maxDeliveryFeeBicycle;

  @BuiltValueField(wireName: r'minDeliveryFeeMotorcycle')
  num get minDeliveryFeeMotorcycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeMotorcycle')
  num get maxDeliveryFeeMotorcycle;

  @BuiltValueField(wireName: r'minDeliveryFeeCar')
  num get minDeliveryFeeCar;

  @BuiltValueField(wireName: r'maxDeliveryFeeCar')
  num get maxDeliveryFeeCar;

  @BuiltValueField(wireName: r'minDeliveryFeeVan')
  num get minDeliveryFeeVan;

  @BuiltValueField(wireName: r'maxDeliveryFeeVan')
  num get maxDeliveryFeeVan;

  @BuiltValueField(wireName: r'minDeliveryFeeTruck')
  num get minDeliveryFeeTruck;

  @BuiltValueField(wireName: r'maxDeliveryFeeTruck')
  num get maxDeliveryFeeTruck;

  @BuiltValueField(wireName: r'minDeliveryFeeMotorTricycle')
  num get minDeliveryFeeMotorTricycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeMotorTricycle')
  num get maxDeliveryFeeMotorTricycle;

  @BuiltValueField(wireName: r'allowBicycle')
  bool get allowBicycle;

  @BuiltValueField(wireName: r'allowMotorcycle')
  bool get allowMotorcycle;

  @BuiltValueField(wireName: r'allowCar')
  bool get allowCar;

  @BuiltValueField(wireName: r'allowVan')
  bool get allowVan;

  @BuiltValueField(wireName: r'allowTruck')
  bool get allowTruck;

  @BuiltValueField(wireName: r'allowMotorTricycle')
  bool get allowMotorTricycle;

  @BuiltValueField(wireName: r'minOrderKm')
  num get minOrderKm;

  @BuiltValueField(wireName: r'minDistanceFixedPrice')
  num get minDistanceFixedPrice;

  @BuiltValueField(wireName: r'maxDeliveryRadiusKm')
  num get maxDeliveryRadiusKm;

  @BuiltValueField(wireName: r'driverSearchRadiusKm')
  num get driverSearchRadiusKm;

  @BuiltValueField(wireName: r'driverSearchRadiusStepKm')
  num get driverSearchRadiusStepKm;

  @BuiltValueField(wireName: r'driverSearchRadiusMaxKm')
  num get driverSearchRadiusMaxKm;

  @BuiltValueField(wireName: r'autoCancelPendingMins')
  num get autoCancelPendingMins;

  @BuiltValueField(wireName: r'driverAcceptTimeoutSecs')
  num get driverAcceptTimeoutSecs;

  @BuiltValueField(wireName: r'isMaintenanceMode')
  bool get isMaintenanceMode;

  @BuiltValueField(wireName: r'androidMinVersion')
  String get androidMinVersion;

  @BuiltValueField(wireName: r'androidLatestVersion')
  String get androidLatestVersion;

  @BuiltValueField(wireName: r'androidForceUpdate')
  bool get androidForceUpdate;

  @BuiltValueField(wireName: r'androidStoreUrl')
  String? get androidStoreUrl;

  @BuiltValueField(wireName: r'iosMinVersion')
  String get iosMinVersion;

  @BuiltValueField(wireName: r'iosLatestVersion')
  String get iosLatestVersion;

  @BuiltValueField(wireName: r'iosForceUpdate')
  bool get iosForceUpdate;

  @BuiltValueField(wireName: r'iosStoreUrl')
  String? get iosStoreUrl;

  @BuiltValueField(wireName: r'supportEmail')
  String? get supportEmail;

  @BuiltValueField(wireName: r'supportPhone')
  String? get supportPhone;

  @BuiltValueField(wireName: r'supportWhatsapp')
  String? get supportWhatsapp;

  @BuiltValueField(wireName: r'termsUrl')
  String? get termsUrl;

  @BuiltValueField(wireName: r'privacyUrl')
  String? get privacyUrl;

  @BuiltValueField(wireName: r'homeCoverUrl')
  String? get homeCoverUrl;

  @BuiltValueField(wireName: r'motorcycleIconUrl')
  String? get motorcycleIconUrl;

  @BuiltValueField(wireName: r'carIconUrl')
  String? get carIconUrl;

  @BuiltValueField(wireName: r'deliveryBannerIconUrl')
  String? get deliveryBannerIconUrl;

  @BuiltValueField(wireName: r'retentionOrdersDays')
  num get retentionOrdersDays;

  @BuiltValueField(wireName: r'retentionArchivedChatsDays')
  num get retentionArchivedChatsDays;

  @BuiltValueField(wireName: r'retentionNotificationsDays')
  num get retentionNotificationsDays;

  @BuiltValueField(wireName: r'retentionExpiredSessionsDays')
  num get retentionExpiredSessionsDays;

  @BuiltValueField(wireName: r'retentionAuditLogsDays')
  num get retentionAuditLogsDays;

  @BuiltValueField(wireName: r'retentionAbandonedCartsDays')
  num get retentionAbandonedCartsDays;

  @BuiltValueField(wireName: r'retentionWalletTransactionsDays')
  num get retentionWalletTransactionsDays;

  @BuiltValueField(wireName: r'retentionStatisticsDays')
  num get retentionStatisticsDays;

  @BuiltValueField(wireName: r'maxKmForBicycle')
  num get maxKmForBicycle;

  @BuiltValueField(wireName: r'driverSearchMaxAttempts')
  num get driverSearchMaxAttempts;

  @BuiltValueField(wireName: r'fallbackOrderDistanceKm')
  num get fallbackOrderDistanceKm;

  @BuiltValueField(wireName: r'customOrderPlatformFee')
  num get customOrderPlatformFee;

  @BuiltValueField(wireName: r'maxDispatchBatchSize')
  num get maxDispatchBatchSize;

  @BuiltValueField(wireName: r'coinValue')
  num get coinValue;

  @BuiltValueField(wireName: r'amountSpentPerCoin')
  num get amountSpentPerCoin;

  @BuiltValueField(wireName: r'minCoinsToUse')
  num get minCoinsToUse;

  @BuiltValueField(wireName: r'driverBonusActive')
  bool get driverBonusActive;

  @BuiltValueField(wireName: r'driverBonusAmount')
  num get driverBonusAmount;

  @BuiltValueField(wireName: r'driverBonusStartDate')
  DateTime? get driverBonusStartDate;

  @BuiltValueField(wireName: r'driverBonusEndDate')
  DateTime? get driverBonusEndDate;

  @BuiltValueField(wireName: r'driverBonusPaidByCustomer')
  bool get driverBonusPaidByCustomer;

  @BuiltValueField(wireName: r'driverShiftsEnabled')
  bool get driverShiftsEnabled;

  @BuiltValueField(wireName: r'maxActiveOrdersPerCustomer')
  num get maxActiveOrdersPerCustomer;

  @BuiltValueField(wireName: r'requirePriorDeliveryForMultipleOrders')
  bool get requirePriorDeliveryForMultipleOrders;

  @BuiltValueField(wireName: r'maxOtpAttempts')
  num get maxOtpAttempts;

  @BuiltValueField(wireName: r'maxNegativeDriverBalance')
  num get maxNegativeDriverBalance;

  @BuiltValueField(wireName: r'otpExpirySeconds')
  num get otpExpirySeconds;

  @BuiltValueField(wireName: r'bronzeTierBonusPerKm')
  num get bronzeTierBonusPerKm;

  @BuiltValueField(wireName: r'silverTierBonusPerKm')
  num get silverTierBonusPerKm;

  @BuiltValueField(wireName: r'goldTierBonusPerKm')
  num get goldTierBonusPerKm;

  @BuiltValueField(wireName: r'highValueOrderThreshold')
  num get highValueOrderThreshold;

  @BuiltValueField(wireName: r'highValueUpfrontRate')
  num get highValueUpfrontRate;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  PlatformSetting._();

  factory PlatformSetting([void updates(PlatformSettingBuilder b)]) = _$PlatformSetting;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformSettingBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformSetting> get serializer => _$PlatformSettingSerializer();
}

class _$PlatformSettingSerializer implements PrimitiveSerializer<PlatformSetting> {
  @override
  final Iterable<Type> types = const [PlatformSetting, _$PlatformSetting];

  @override
  final String wireName = r'PlatformSetting';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformSetting object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    yield r'defaultCommissionRate';
    yield serializers.serialize(
      object.defaultCommissionRate,
      specifiedType: const FullType(num),
    );
    yield r'deliveryCommissionRate';
    yield serializers.serialize(
      object.deliveryCommissionRate,
      specifiedType: const FullType(num),
    );
    yield r'defaultTaxRate';
    yield serializers.serialize(
      object.defaultTaxRate,
      specifiedType: const FullType(num),
    );
    yield r'minOrderAmount';
    yield serializers.serialize(
      object.minOrderAmount,
      specifiedType: const FullType(num),
    );
    yield r'baseDeliveryFee';
    yield serializers.serialize(
      object.baseDeliveryFee,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKm';
    yield serializers.serialize(
      object.pricePerKm,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmBicycle';
    yield serializers.serialize(
      object.pricePerKmBicycle,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmMotorcycle';
    yield serializers.serialize(
      object.pricePerKmMotorcycle,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmCar';
    yield serializers.serialize(
      object.pricePerKmCar,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmVan';
    yield serializers.serialize(
      object.pricePerKmVan,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmTruck';
    yield serializers.serialize(
      object.pricePerKmTruck,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmMotorTricycle';
    yield serializers.serialize(
      object.pricePerKmMotorTricycle,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFee';
    yield serializers.serialize(
      object.maxDeliveryFee,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeBicycle';
    yield serializers.serialize(
      object.minDeliveryFeeBicycle,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeBicycle';
    yield serializers.serialize(
      object.maxDeliveryFeeBicycle,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeMotorcycle';
    yield serializers.serialize(
      object.minDeliveryFeeMotorcycle,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeMotorcycle';
    yield serializers.serialize(
      object.maxDeliveryFeeMotorcycle,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeCar';
    yield serializers.serialize(
      object.minDeliveryFeeCar,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeCar';
    yield serializers.serialize(
      object.maxDeliveryFeeCar,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeVan';
    yield serializers.serialize(
      object.minDeliveryFeeVan,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeVan';
    yield serializers.serialize(
      object.maxDeliveryFeeVan,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeTruck';
    yield serializers.serialize(
      object.minDeliveryFeeTruck,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeTruck';
    yield serializers.serialize(
      object.maxDeliveryFeeTruck,
      specifiedType: const FullType(num),
    );
    yield r'minDeliveryFeeMotorTricycle';
    yield serializers.serialize(
      object.minDeliveryFeeMotorTricycle,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryFeeMotorTricycle';
    yield serializers.serialize(
      object.maxDeliveryFeeMotorTricycle,
      specifiedType: const FullType(num),
    );
    yield r'allowBicycle';
    yield serializers.serialize(
      object.allowBicycle,
      specifiedType: const FullType(bool),
    );
    yield r'allowMotorcycle';
    yield serializers.serialize(
      object.allowMotorcycle,
      specifiedType: const FullType(bool),
    );
    yield r'allowCar';
    yield serializers.serialize(
      object.allowCar,
      specifiedType: const FullType(bool),
    );
    yield r'allowVan';
    yield serializers.serialize(
      object.allowVan,
      specifiedType: const FullType(bool),
    );
    yield r'allowTruck';
    yield serializers.serialize(
      object.allowTruck,
      specifiedType: const FullType(bool),
    );
    yield r'allowMotorTricycle';
    yield serializers.serialize(
      object.allowMotorTricycle,
      specifiedType: const FullType(bool),
    );
    yield r'minOrderKm';
    yield serializers.serialize(
      object.minOrderKm,
      specifiedType: const FullType(num),
    );
    yield r'minDistanceFixedPrice';
    yield serializers.serialize(
      object.minDistanceFixedPrice,
      specifiedType: const FullType(num),
    );
    yield r'maxDeliveryRadiusKm';
    yield serializers.serialize(
      object.maxDeliveryRadiusKm,
      specifiedType: const FullType(num),
    );
    yield r'driverSearchRadiusKm';
    yield serializers.serialize(
      object.driverSearchRadiusKm,
      specifiedType: const FullType(num),
    );
    yield r'driverSearchRadiusStepKm';
    yield serializers.serialize(
      object.driverSearchRadiusStepKm,
      specifiedType: const FullType(num),
    );
    yield r'driverSearchRadiusMaxKm';
    yield serializers.serialize(
      object.driverSearchRadiusMaxKm,
      specifiedType: const FullType(num),
    );
    yield r'autoCancelPendingMins';
    yield serializers.serialize(
      object.autoCancelPendingMins,
      specifiedType: const FullType(num),
    );
    yield r'driverAcceptTimeoutSecs';
    yield serializers.serialize(
      object.driverAcceptTimeoutSecs,
      specifiedType: const FullType(num),
    );
    yield r'isMaintenanceMode';
    yield serializers.serialize(
      object.isMaintenanceMode,
      specifiedType: const FullType(bool),
    );
    yield r'androidMinVersion';
    yield serializers.serialize(
      object.androidMinVersion,
      specifiedType: const FullType(String),
    );
    yield r'androidLatestVersion';
    yield serializers.serialize(
      object.androidLatestVersion,
      specifiedType: const FullType(String),
    );
    yield r'androidForceUpdate';
    yield serializers.serialize(
      object.androidForceUpdate,
      specifiedType: const FullType(bool),
    );
    if (object.androidStoreUrl != null) {
      yield r'androidStoreUrl';
      yield serializers.serialize(
        object.androidStoreUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'iosMinVersion';
    yield serializers.serialize(
      object.iosMinVersion,
      specifiedType: const FullType(String),
    );
    yield r'iosLatestVersion';
    yield serializers.serialize(
      object.iosLatestVersion,
      specifiedType: const FullType(String),
    );
    yield r'iosForceUpdate';
    yield serializers.serialize(
      object.iosForceUpdate,
      specifiedType: const FullType(bool),
    );
    if (object.iosStoreUrl != null) {
      yield r'iosStoreUrl';
      yield serializers.serialize(
        object.iosStoreUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.supportEmail != null) {
      yield r'supportEmail';
      yield serializers.serialize(
        object.supportEmail,
        specifiedType: const FullType(String),
      );
    }
    if (object.supportPhone != null) {
      yield r'supportPhone';
      yield serializers.serialize(
        object.supportPhone,
        specifiedType: const FullType(String),
      );
    }
    if (object.supportWhatsapp != null) {
      yield r'supportWhatsapp';
      yield serializers.serialize(
        object.supportWhatsapp,
        specifiedType: const FullType(String),
      );
    }
    if (object.termsUrl != null) {
      yield r'termsUrl';
      yield serializers.serialize(
        object.termsUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.privacyUrl != null) {
      yield r'privacyUrl';
      yield serializers.serialize(
        object.privacyUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.homeCoverUrl != null) {
      yield r'homeCoverUrl';
      yield serializers.serialize(
        object.homeCoverUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.motorcycleIconUrl != null) {
      yield r'motorcycleIconUrl';
      yield serializers.serialize(
        object.motorcycleIconUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.carIconUrl != null) {
      yield r'carIconUrl';
      yield serializers.serialize(
        object.carIconUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryBannerIconUrl != null) {
      yield r'deliveryBannerIconUrl';
      yield serializers.serialize(
        object.deliveryBannerIconUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'retentionOrdersDays';
    yield serializers.serialize(
      object.retentionOrdersDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionArchivedChatsDays';
    yield serializers.serialize(
      object.retentionArchivedChatsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionNotificationsDays';
    yield serializers.serialize(
      object.retentionNotificationsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionExpiredSessionsDays';
    yield serializers.serialize(
      object.retentionExpiredSessionsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionAuditLogsDays';
    yield serializers.serialize(
      object.retentionAuditLogsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionAbandonedCartsDays';
    yield serializers.serialize(
      object.retentionAbandonedCartsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionWalletTransactionsDays';
    yield serializers.serialize(
      object.retentionWalletTransactionsDays,
      specifiedType: const FullType(num),
    );
    yield r'retentionStatisticsDays';
    yield serializers.serialize(
      object.retentionStatisticsDays,
      specifiedType: const FullType(num),
    );
    yield r'maxKmForBicycle';
    yield serializers.serialize(
      object.maxKmForBicycle,
      specifiedType: const FullType(num),
    );
    yield r'driverSearchMaxAttempts';
    yield serializers.serialize(
      object.driverSearchMaxAttempts,
      specifiedType: const FullType(num),
    );
    yield r'fallbackOrderDistanceKm';
    yield serializers.serialize(
      object.fallbackOrderDistanceKm,
      specifiedType: const FullType(num),
    );
    yield r'customOrderPlatformFee';
    yield serializers.serialize(
      object.customOrderPlatformFee,
      specifiedType: const FullType(num),
    );
    yield r'maxDispatchBatchSize';
    yield serializers.serialize(
      object.maxDispatchBatchSize,
      specifiedType: const FullType(num),
    );
    yield r'coinValue';
    yield serializers.serialize(
      object.coinValue,
      specifiedType: const FullType(num),
    );
    yield r'amountSpentPerCoin';
    yield serializers.serialize(
      object.amountSpentPerCoin,
      specifiedType: const FullType(num),
    );
    yield r'minCoinsToUse';
    yield serializers.serialize(
      object.minCoinsToUse,
      specifiedType: const FullType(num),
    );
    yield r'driverBonusActive';
    yield serializers.serialize(
      object.driverBonusActive,
      specifiedType: const FullType(bool),
    );
    yield r'driverBonusAmount';
    yield serializers.serialize(
      object.driverBonusAmount,
      specifiedType: const FullType(num),
    );
    if (object.driverBonusStartDate != null) {
      yield r'driverBonusStartDate';
      yield serializers.serialize(
        object.driverBonusStartDate,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.driverBonusEndDate != null) {
      yield r'driverBonusEndDate';
      yield serializers.serialize(
        object.driverBonusEndDate,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'driverBonusPaidByCustomer';
    yield serializers.serialize(
      object.driverBonusPaidByCustomer,
      specifiedType: const FullType(bool),
    );
    yield r'driverShiftsEnabled';
    yield serializers.serialize(
      object.driverShiftsEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'maxActiveOrdersPerCustomer';
    yield serializers.serialize(
      object.maxActiveOrdersPerCustomer,
      specifiedType: const FullType(num),
    );
    yield r'requirePriorDeliveryForMultipleOrders';
    yield serializers.serialize(
      object.requirePriorDeliveryForMultipleOrders,
      specifiedType: const FullType(bool),
    );
    yield r'maxOtpAttempts';
    yield serializers.serialize(
      object.maxOtpAttempts,
      specifiedType: const FullType(num),
    );
    yield r'maxNegativeDriverBalance';
    yield serializers.serialize(
      object.maxNegativeDriverBalance,
      specifiedType: const FullType(num),
    );
    yield r'otpExpirySeconds';
    yield serializers.serialize(
      object.otpExpirySeconds,
      specifiedType: const FullType(num),
    );
    yield r'bronzeTierBonusPerKm';
    yield serializers.serialize(
      object.bronzeTierBonusPerKm,
      specifiedType: const FullType(num),
    );
    yield r'silverTierBonusPerKm';
    yield serializers.serialize(
      object.silverTierBonusPerKm,
      specifiedType: const FullType(num),
    );
    yield r'goldTierBonusPerKm';
    yield serializers.serialize(
      object.goldTierBonusPerKm,
      specifiedType: const FullType(num),
    );
    yield r'highValueOrderThreshold';
    yield serializers.serialize(
      object.highValueOrderThreshold,
      specifiedType: const FullType(num),
    );
    yield r'highValueUpfrontRate';
    yield serializers.serialize(
      object.highValueUpfrontRate,
      specifiedType: const FullType(num),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformSetting object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformSettingBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        case r'defaultCommissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.defaultCommissionRate = valueDes;
          break;
        case r'deliveryCommissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.deliveryCommissionRate = valueDes;
          break;
        case r'defaultTaxRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.defaultTaxRate = valueDes;
          break;
        case r'minOrderAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minOrderAmount = valueDes;
          break;
        case r'baseDeliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.baseDeliveryFee = valueDes;
          break;
        case r'pricePerKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKm = valueDes;
          break;
        case r'pricePerKmBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmBicycle = valueDes;
          break;
        case r'pricePerKmMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmMotorcycle = valueDes;
          break;
        case r'pricePerKmCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmCar = valueDes;
          break;
        case r'pricePerKmVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmVan = valueDes;
          break;
        case r'pricePerKmTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmTruck = valueDes;
          break;
        case r'pricePerKmMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmMotorTricycle = valueDes;
          break;
        case r'maxDeliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFee = valueDes;
          break;
        case r'minDeliveryFeeBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeBicycle = valueDes;
          break;
        case r'maxDeliveryFeeBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeBicycle = valueDes;
          break;
        case r'minDeliveryFeeMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeMotorcycle = valueDes;
          break;
        case r'maxDeliveryFeeMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeMotorcycle = valueDes;
          break;
        case r'minDeliveryFeeCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeCar = valueDes;
          break;
        case r'maxDeliveryFeeCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeCar = valueDes;
          break;
        case r'minDeliveryFeeVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeVan = valueDes;
          break;
        case r'maxDeliveryFeeVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeVan = valueDes;
          break;
        case r'minDeliveryFeeTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeTruck = valueDes;
          break;
        case r'maxDeliveryFeeTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeTruck = valueDes;
          break;
        case r'minDeliveryFeeMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFeeMotorTricycle = valueDes;
          break;
        case r'maxDeliveryFeeMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryFeeMotorTricycle = valueDes;
          break;
        case r'allowBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowBicycle = valueDes;
          break;
        case r'allowMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowMotorcycle = valueDes;
          break;
        case r'allowCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowCar = valueDes;
          break;
        case r'allowVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowVan = valueDes;
          break;
        case r'allowTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowTruck = valueDes;
          break;
        case r'allowMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowMotorTricycle = valueDes;
          break;
        case r'minOrderKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minOrderKm = valueDes;
          break;
        case r'minDistanceFixedPrice':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDistanceFixedPrice = valueDes;
          break;
        case r'maxDeliveryRadiusKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDeliveryRadiusKm = valueDes;
          break;
        case r'driverSearchRadiusKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchRadiusKm = valueDes;
          break;
        case r'driverSearchRadiusStepKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchRadiusStepKm = valueDes;
          break;
        case r'driverSearchRadiusMaxKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchRadiusMaxKm = valueDes;
          break;
        case r'autoCancelPendingMins':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.autoCancelPendingMins = valueDes;
          break;
        case r'driverAcceptTimeoutSecs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverAcceptTimeoutSecs = valueDes;
          break;
        case r'isMaintenanceMode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isMaintenanceMode = valueDes;
          break;
        case r'androidMinVersion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.androidMinVersion = valueDes;
          break;
        case r'androidLatestVersion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.androidLatestVersion = valueDes;
          break;
        case r'androidForceUpdate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.androidForceUpdate = valueDes;
          break;
        case r'androidStoreUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.androidStoreUrl = valueDes;
          break;
        case r'iosMinVersion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.iosMinVersion = valueDes;
          break;
        case r'iosLatestVersion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.iosLatestVersion = valueDes;
          break;
        case r'iosForceUpdate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.iosForceUpdate = valueDes;
          break;
        case r'iosStoreUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.iosStoreUrl = valueDes;
          break;
        case r'supportEmail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.supportEmail = valueDes;
          break;
        case r'supportPhone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.supportPhone = valueDes;
          break;
        case r'supportWhatsapp':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.supportWhatsapp = valueDes;
          break;
        case r'termsUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.termsUrl = valueDes;
          break;
        case r'privacyUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.privacyUrl = valueDes;
          break;
        case r'homeCoverUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.homeCoverUrl = valueDes;
          break;
        case r'motorcycleIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motorcycleIconUrl = valueDes;
          break;
        case r'carIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.carIconUrl = valueDes;
          break;
        case r'deliveryBannerIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryBannerIconUrl = valueDes;
          break;
        case r'retentionOrdersDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionOrdersDays = valueDes;
          break;
        case r'retentionArchivedChatsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionArchivedChatsDays = valueDes;
          break;
        case r'retentionNotificationsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionNotificationsDays = valueDes;
          break;
        case r'retentionExpiredSessionsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionExpiredSessionsDays = valueDes;
          break;
        case r'retentionAuditLogsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionAuditLogsDays = valueDes;
          break;
        case r'retentionAbandonedCartsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionAbandonedCartsDays = valueDes;
          break;
        case r'retentionWalletTransactionsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionWalletTransactionsDays = valueDes;
          break;
        case r'retentionStatisticsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionStatisticsDays = valueDes;
          break;
        case r'maxKmForBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxKmForBicycle = valueDes;
          break;
        case r'driverSearchMaxAttempts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchMaxAttempts = valueDes;
          break;
        case r'fallbackOrderDistanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.fallbackOrderDistanceKm = valueDes;
          break;
        case r'customOrderPlatformFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.customOrderPlatformFee = valueDes;
          break;
        case r'maxDispatchBatchSize':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDispatchBatchSize = valueDes;
          break;
        case r'coinValue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinValue = valueDes;
          break;
        case r'amountSpentPerCoin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amountSpentPerCoin = valueDes;
          break;
        case r'minCoinsToUse':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minCoinsToUse = valueDes;
          break;
        case r'driverBonusActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.driverBonusActive = valueDes;
          break;
        case r'driverBonusAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverBonusAmount = valueDes;
          break;
        case r'driverBonusStartDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.driverBonusStartDate = valueDes;
          break;
        case r'driverBonusEndDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.driverBonusEndDate = valueDes;
          break;
        case r'driverBonusPaidByCustomer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.driverBonusPaidByCustomer = valueDes;
          break;
        case r'driverShiftsEnabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.driverShiftsEnabled = valueDes;
          break;
        case r'maxActiveOrdersPerCustomer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxActiveOrdersPerCustomer = valueDes;
          break;
        case r'requirePriorDeliveryForMultipleOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.requirePriorDeliveryForMultipleOrders = valueDes;
          break;
        case r'maxOtpAttempts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxOtpAttempts = valueDes;
          break;
        case r'maxNegativeDriverBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxNegativeDriverBalance = valueDes;
          break;
        case r'otpExpirySeconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.otpExpirySeconds = valueDes;
          break;
        case r'bronzeTierBonusPerKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.bronzeTierBonusPerKm = valueDes;
          break;
        case r'silverTierBonusPerKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.silverTierBonusPerKm = valueDes;
          break;
        case r'goldTierBonusPerKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.goldTierBonusPerKm = valueDes;
          break;
        case r'highValueOrderThreshold':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.highValueOrderThreshold = valueDes;
          break;
        case r'highValueUpfrontRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.highValueUpfrontRate = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformSetting deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformSettingBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

