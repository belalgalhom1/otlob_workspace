//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_platform_settings_dto.g.dart';

/// UpdatePlatformSettingsDto
///
/// Properties:
/// * [currency] 
/// * [defaultCommissionRate] 
/// * [deliveryCommissionRate] 
/// * [driverManagerCommissionRate] 
/// * [customOrderPlatformFee] 
/// * [defaultTaxRate] 
/// * [minOrderAmount] 
/// * [baseDeliveryFee] 
/// * [extraVendorDeliveryFee] - Fixed extra delivery fee for each extra vendor in a multi-vendor delivery group (EGP). Default 10.
/// * [pricePerKm] 
/// * [pricePerKmBicycle] 
/// * [pricePerKmMotorcycle] 
/// * [pricePerKmCar] 
/// * [pricePerKmVan] 
/// * [pricePerKmTruck] 
/// * [pricePerKmMotorTricycle] 
/// * [maxDeliveryFee] - Max limit on delivery fee
/// * [minDeliveryFee] - Absolute minimum customer delivery fee in EGP. Applied after the per-vehicle min/max matrix, so a vehicle override still wins. 0 disables the global floor.
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
/// * [minOrderKm] - Distance below which fixed price is applied
/// * [minDistanceFixedPrice] - Fixed price applied if distance is below minOrderKm
/// * [maxDeliveryRadiusKm] 
/// * [driverSearchRadiusKm] 
/// * [driverSearchRadiusStepKm] 
/// * [driverSearchRadiusMaxKm] 
/// * [driverSearchMaxAttempts] 
/// * [driverSearchGeoCandidateLimit] - Max candidates to fetch from Redis geo-radius before SQL filtering (headroom for filters).
/// * [driverLocationFreshnessTtlSecs] - Driver location freshness TTL in seconds (how long a position is considered live).
/// * [driverLocationPrecisionMeters] - Location precision reduction in meters for customer-facing tracking (0 = exact).
/// * [groupingMaxBranchDistanceKm] - Smart grouping (km): max straight-line distance between any two vendor branches that may share one delivery group.
/// * [groupingMaxVendorCustomerDistanceKm] - Smart grouping (km): max straight-line distance from a vendor branch to the customer drop-off for that vendor to be groupable at all.
/// * [autoCancelPendingMins] 
/// * [mobileWalletTimeoutMins] 
/// * [driverAcceptTimeoutSecs] 
/// * [assistDecisionTimeoutSecs] 
/// * [maxNegativeDriverBalance] 
/// * [maxDispatchBatchSize] 
/// * [maxActiveOrdersPerDriver] - Maximum active orders a driver can carry at the same time (1-10). Default 1.
/// * [isMaintenanceMode] 
/// * [androidMinVersion] 
/// * [androidLatestVersion] 
/// * [androidForceUpdate] 
/// * [androidStoreUrl] 
/// * [iosMinVersion] 
/// * [iosLatestVersion] 
/// * [maxActiveOrdersPerCustomer] - Max active orders a customer can have
/// * [requirePriorDeliveryForMultipleOrders] - Requires prior delivery to place multiple orders
/// * [maxOtpAttempts] - Max OTP attempts before block
/// * [otpExpirySeconds] - OTP expiry in seconds
/// * [iosForceUpdate] 
/// * [iosStoreUrl] 
/// * [supportEmail] 
/// * [supportPhone] 
/// * [supportWhatsapp] 
/// * [termsUrl] 
/// * [privacyUrl] 
/// * [retentionOrdersDays] - Days before all old orders are hard-deleted
/// * [retentionArchivedChatsDays] - Days before archived conversations are hard-deleted
/// * [retentionNotificationsDays] - Days before old notifications are hard-deleted
/// * [retentionExpiredSessionsDays] - Days after expiry before sessions are hard-deleted
/// * [retentionAuditLogsDays] - Days before audit logs are hard-deleted
/// * [retentionAbandonedCartsDays] - Days before abandoned carts are hard-deleted
/// * [retentionPaymentReceiptsDays] - Days after an order settles before its mobile-wallet payment receipt screenshot is deleted from disk and cleared from the order (order row itself is kept)
/// * [retentionShiftStartPhotosDays] - Days after a shift ends before its driver start-photo (selfie) is deleted from disk and cleared from the shift (shift row itself is kept)
/// * [retentionPickupPhotosDays] - Days after an order settles before its pickup proof photo is deleted from disk and cleared from the order (order row itself is kept)
/// * [retentionDeliveryPhotosDays] - Days after an order settles before its delivery proof photo is deleted from disk and cleared from the order (order row itself is kept)
/// * [retentionWalletTransactionsDays] - Days before wallet transactions are hard-deleted
/// * [retentionStatisticsDays] - Days before statistics records are hard-deleted
/// * [maxKmForBicycle] - Max distance for bicycle dispatch
/// * [coinValue] - Value of 1 coin (e.g. 1 = 1 EGP)
/// * [amountSpentPerCoin] - Amount spent to earn 1 coin (e.g. 10 = 10 EGP)
/// * [minCoinsToUse] - Minimum coins required to use for partial payment
/// * [driverBonusActive] - Master switch for driver bonus
/// * [driverBonusAmount] - Bonus amount (e.g. 5 = 5 EGP)
/// * [driverBonusStartDate] - Start date of the bonus period
/// * [driverBonusEndDate] - End date of the bonus period
/// * [driverBonusPaidByCustomer] - If true, customer pays the bonus as a fee. If false, platform pays.
/// * [highValueOrderThreshold] - Threshold for high value orders (e.g. 2000 = 2000 EGP). 0 to disable.
/// * [highValueUpfrontRate] - Upfront percentage rate for high value cash orders (e.g. 20 = 20%)
/// * [driverShiftsEnabled] - Master switch for driver shifts feature
/// * [breaksEnabled] - Master switch for the driver break system. When off, drivers cannot request breaks and pending requests cannot be approved (admin grant still works as an override). Active breaks can always be ended.
/// * [bronzeTierBonusPerKm] - Per-km bonus for Bronze tier drivers
/// * [silverTierBonusPerKm] - Per-km bonus for Silver tier drivers
/// * [goldTierBonusPerKm] - Per-km bonus for Gold tier drivers (Used at checkout)
/// * [driverSettlementOrderThreshold] - Number of delivered orders after which a driver with a negative wallet balance must settle (transfer what they owe to the platform wallet) before receiving new orders. 0 disables.
/// * [maxBreakMinutesPerShift] - Max total break minutes allowed per shift
/// * [maxBreaksPerShift] - Max number of breaks allowed per shift
/// * [maxSingleBreakMinutes] - Max minutes for a single break before it is auto-ended by the system
/// * [pendingBreakExpiryMins] - Minutes a break request stays PENDING before the system auto-rejects it
@BuiltValue()
abstract class UpdatePlatformSettingsDto implements Built<UpdatePlatformSettingsDto, UpdatePlatformSettingsDtoBuilder> {
  @BuiltValueField(wireName: r'currency')
  String? get currency;

  @BuiltValueField(wireName: r'defaultCommissionRate')
  num? get defaultCommissionRate;

  @BuiltValueField(wireName: r'deliveryCommissionRate')
  num? get deliveryCommissionRate;

  @BuiltValueField(wireName: r'driverManagerCommissionRate')
  num? get driverManagerCommissionRate;

  @BuiltValueField(wireName: r'customOrderPlatformFee')
  num? get customOrderPlatformFee;

  @BuiltValueField(wireName: r'defaultTaxRate')
  num? get defaultTaxRate;

  @BuiltValueField(wireName: r'minOrderAmount')
  num? get minOrderAmount;

  @BuiltValueField(wireName: r'baseDeliveryFee')
  num? get baseDeliveryFee;

  /// Fixed extra delivery fee for each extra vendor in a multi-vendor delivery group (EGP). Default 10.
  @BuiltValueField(wireName: r'extraVendorDeliveryFee')
  num? get extraVendorDeliveryFee;

  @BuiltValueField(wireName: r'pricePerKm')
  num? get pricePerKm;

  @BuiltValueField(wireName: r'pricePerKmBicycle')
  num? get pricePerKmBicycle;

  @BuiltValueField(wireName: r'pricePerKmMotorcycle')
  num? get pricePerKmMotorcycle;

  @BuiltValueField(wireName: r'pricePerKmCar')
  num? get pricePerKmCar;

  @BuiltValueField(wireName: r'pricePerKmVan')
  num? get pricePerKmVan;

  @BuiltValueField(wireName: r'pricePerKmTruck')
  num? get pricePerKmTruck;

  @BuiltValueField(wireName: r'pricePerKmMotorTricycle')
  num? get pricePerKmMotorTricycle;

  /// Max limit on delivery fee
  @BuiltValueField(wireName: r'maxDeliveryFee')
  num? get maxDeliveryFee;

  /// Absolute minimum customer delivery fee in EGP. Applied after the per-vehicle min/max matrix, so a vehicle override still wins. 0 disables the global floor.
  @BuiltValueField(wireName: r'minDeliveryFee')
  num? get minDeliveryFee;

  @BuiltValueField(wireName: r'minDeliveryFeeBicycle')
  num? get minDeliveryFeeBicycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeBicycle')
  num? get maxDeliveryFeeBicycle;

  @BuiltValueField(wireName: r'minDeliveryFeeMotorcycle')
  num? get minDeliveryFeeMotorcycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeMotorcycle')
  num? get maxDeliveryFeeMotorcycle;

  @BuiltValueField(wireName: r'minDeliveryFeeCar')
  num? get minDeliveryFeeCar;

  @BuiltValueField(wireName: r'maxDeliveryFeeCar')
  num? get maxDeliveryFeeCar;

  @BuiltValueField(wireName: r'minDeliveryFeeVan')
  num? get minDeliveryFeeVan;

  @BuiltValueField(wireName: r'maxDeliveryFeeVan')
  num? get maxDeliveryFeeVan;

  @BuiltValueField(wireName: r'minDeliveryFeeTruck')
  num? get minDeliveryFeeTruck;

  @BuiltValueField(wireName: r'maxDeliveryFeeTruck')
  num? get maxDeliveryFeeTruck;

  @BuiltValueField(wireName: r'minDeliveryFeeMotorTricycle')
  num? get minDeliveryFeeMotorTricycle;

  @BuiltValueField(wireName: r'maxDeliveryFeeMotorTricycle')
  num? get maxDeliveryFeeMotorTricycle;

  @BuiltValueField(wireName: r'allowBicycle')
  bool? get allowBicycle;

  @BuiltValueField(wireName: r'allowMotorcycle')
  bool? get allowMotorcycle;

  @BuiltValueField(wireName: r'allowCar')
  bool? get allowCar;

  @BuiltValueField(wireName: r'allowVan')
  bool? get allowVan;

  @BuiltValueField(wireName: r'allowTruck')
  bool? get allowTruck;

  @BuiltValueField(wireName: r'allowMotorTricycle')
  bool? get allowMotorTricycle;

  /// Distance below which fixed price is applied
  @BuiltValueField(wireName: r'minOrderKm')
  num? get minOrderKm;

  /// Fixed price applied if distance is below minOrderKm
  @BuiltValueField(wireName: r'minDistanceFixedPrice')
  num? get minDistanceFixedPrice;

  @BuiltValueField(wireName: r'maxDeliveryRadiusKm')
  num? get maxDeliveryRadiusKm;

  @BuiltValueField(wireName: r'driverSearchRadiusKm')
  num? get driverSearchRadiusKm;

  @BuiltValueField(wireName: r'driverSearchRadiusStepKm')
  num? get driverSearchRadiusStepKm;

  @BuiltValueField(wireName: r'driverSearchRadiusMaxKm')
  num? get driverSearchRadiusMaxKm;

  @BuiltValueField(wireName: r'driverSearchMaxAttempts')
  num? get driverSearchMaxAttempts;

  /// Max candidates to fetch from Redis geo-radius before SQL filtering (headroom for filters).
  @BuiltValueField(wireName: r'driverSearchGeoCandidateLimit')
  num? get driverSearchGeoCandidateLimit;

  /// Driver location freshness TTL in seconds (how long a position is considered live).
  @BuiltValueField(wireName: r'driverLocationFreshnessTtlSecs')
  num? get driverLocationFreshnessTtlSecs;

  /// Location precision reduction in meters for customer-facing tracking (0 = exact).
  @BuiltValueField(wireName: r'driverLocationPrecisionMeters')
  num? get driverLocationPrecisionMeters;

  /// Smart grouping (km): max straight-line distance between any two vendor branches that may share one delivery group.
  @BuiltValueField(wireName: r'groupingMaxBranchDistanceKm')
  num? get groupingMaxBranchDistanceKm;

  /// Smart grouping (km): max straight-line distance from a vendor branch to the customer drop-off for that vendor to be groupable at all.
  @BuiltValueField(wireName: r'groupingMaxVendorCustomerDistanceKm')
  num? get groupingMaxVendorCustomerDistanceKm;

  @BuiltValueField(wireName: r'autoCancelPendingMins')
  num? get autoCancelPendingMins;

  @BuiltValueField(wireName: r'mobileWalletTimeoutMins')
  num? get mobileWalletTimeoutMins;

  @BuiltValueField(wireName: r'driverAcceptTimeoutSecs')
  num? get driverAcceptTimeoutSecs;

  @BuiltValueField(wireName: r'assistDecisionTimeoutSecs')
  num? get assistDecisionTimeoutSecs;

  @BuiltValueField(wireName: r'maxNegativeDriverBalance')
  num? get maxNegativeDriverBalance;

  @BuiltValueField(wireName: r'maxDispatchBatchSize')
  num? get maxDispatchBatchSize;

  /// Maximum active orders a driver can carry at the same time (1-10). Default 1.
  @BuiltValueField(wireName: r'maxActiveOrdersPerDriver')
  num? get maxActiveOrdersPerDriver;

  @BuiltValueField(wireName: r'isMaintenanceMode')
  bool? get isMaintenanceMode;

  @BuiltValueField(wireName: r'androidMinVersion')
  String? get androidMinVersion;

  @BuiltValueField(wireName: r'androidLatestVersion')
  String? get androidLatestVersion;

  @BuiltValueField(wireName: r'androidForceUpdate')
  bool? get androidForceUpdate;

  @BuiltValueField(wireName: r'androidStoreUrl')
  String? get androidStoreUrl;

  @BuiltValueField(wireName: r'iosMinVersion')
  String? get iosMinVersion;

  @BuiltValueField(wireName: r'iosLatestVersion')
  String? get iosLatestVersion;

  /// Max active orders a customer can have
  @BuiltValueField(wireName: r'maxActiveOrdersPerCustomer')
  num? get maxActiveOrdersPerCustomer;

  /// Requires prior delivery to place multiple orders
  @BuiltValueField(wireName: r'requirePriorDeliveryForMultipleOrders')
  bool? get requirePriorDeliveryForMultipleOrders;

  /// Max OTP attempts before block
  @BuiltValueField(wireName: r'maxOtpAttempts')
  num? get maxOtpAttempts;

  /// OTP expiry in seconds
  @BuiltValueField(wireName: r'otpExpirySeconds')
  num? get otpExpirySeconds;

  @BuiltValueField(wireName: r'iosForceUpdate')
  bool? get iosForceUpdate;

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

  /// Days before all old orders are hard-deleted
  @BuiltValueField(wireName: r'retentionOrdersDays')
  num? get retentionOrdersDays;

  /// Days before archived conversations are hard-deleted
  @BuiltValueField(wireName: r'retentionArchivedChatsDays')
  num? get retentionArchivedChatsDays;

  /// Days before old notifications are hard-deleted
  @BuiltValueField(wireName: r'retentionNotificationsDays')
  num? get retentionNotificationsDays;

  /// Days after expiry before sessions are hard-deleted
  @BuiltValueField(wireName: r'retentionExpiredSessionsDays')
  num? get retentionExpiredSessionsDays;

  /// Days before audit logs are hard-deleted
  @BuiltValueField(wireName: r'retentionAuditLogsDays')
  num? get retentionAuditLogsDays;

  /// Days before abandoned carts are hard-deleted
  @BuiltValueField(wireName: r'retentionAbandonedCartsDays')
  num? get retentionAbandonedCartsDays;

  /// Days after an order settles before its mobile-wallet payment receipt screenshot is deleted from disk and cleared from the order (order row itself is kept)
  @BuiltValueField(wireName: r'retentionPaymentReceiptsDays')
  num? get retentionPaymentReceiptsDays;

  /// Days after a shift ends before its driver start-photo (selfie) is deleted from disk and cleared from the shift (shift row itself is kept)
  @BuiltValueField(wireName: r'retentionShiftStartPhotosDays')
  num? get retentionShiftStartPhotosDays;

  /// Days after an order settles before its pickup proof photo is deleted from disk and cleared from the order (order row itself is kept)
  @BuiltValueField(wireName: r'retentionPickupPhotosDays')
  num? get retentionPickupPhotosDays;

  /// Days after an order settles before its delivery proof photo is deleted from disk and cleared from the order (order row itself is kept)
  @BuiltValueField(wireName: r'retentionDeliveryPhotosDays')
  num? get retentionDeliveryPhotosDays;

  /// Days before wallet transactions are hard-deleted
  @BuiltValueField(wireName: r'retentionWalletTransactionsDays')
  num? get retentionWalletTransactionsDays;

  /// Days before statistics records are hard-deleted
  @BuiltValueField(wireName: r'retentionStatisticsDays')
  num? get retentionStatisticsDays;

  /// Max distance for bicycle dispatch
  @BuiltValueField(wireName: r'maxKmForBicycle')
  num? get maxKmForBicycle;

  /// Value of 1 coin (e.g. 1 = 1 EGP)
  @BuiltValueField(wireName: r'coinValue')
  num? get coinValue;

  /// Amount spent to earn 1 coin (e.g. 10 = 10 EGP)
  @BuiltValueField(wireName: r'amountSpentPerCoin')
  num? get amountSpentPerCoin;

  /// Minimum coins required to use for partial payment
  @BuiltValueField(wireName: r'minCoinsToUse')
  num? get minCoinsToUse;

  /// Master switch for driver bonus
  @BuiltValueField(wireName: r'driverBonusActive')
  bool? get driverBonusActive;

  /// Bonus amount (e.g. 5 = 5 EGP)
  @BuiltValueField(wireName: r'driverBonusAmount')
  num? get driverBonusAmount;

  /// Start date of the bonus period
  @BuiltValueField(wireName: r'driverBonusStartDate')
  DateTime? get driverBonusStartDate;

  /// End date of the bonus period
  @BuiltValueField(wireName: r'driverBonusEndDate')
  DateTime? get driverBonusEndDate;

  /// If true, customer pays the bonus as a fee. If false, platform pays.
  @BuiltValueField(wireName: r'driverBonusPaidByCustomer')
  bool? get driverBonusPaidByCustomer;

  /// Threshold for high value orders (e.g. 2000 = 2000 EGP). 0 to disable.
  @BuiltValueField(wireName: r'highValueOrderThreshold')
  num? get highValueOrderThreshold;

  /// Upfront percentage rate for high value cash orders (e.g. 20 = 20%)
  @BuiltValueField(wireName: r'highValueUpfrontRate')
  num? get highValueUpfrontRate;

  /// Master switch for driver shifts feature
  @BuiltValueField(wireName: r'driverShiftsEnabled')
  bool? get driverShiftsEnabled;

  /// Master switch for the driver break system. When off, drivers cannot request breaks and pending requests cannot be approved (admin grant still works as an override). Active breaks can always be ended.
  @BuiltValueField(wireName: r'breaksEnabled')
  bool? get breaksEnabled;

  /// Per-km bonus for Bronze tier drivers
  @BuiltValueField(wireName: r'bronzeTierBonusPerKm')
  num? get bronzeTierBonusPerKm;

  /// Per-km bonus for Silver tier drivers
  @BuiltValueField(wireName: r'silverTierBonusPerKm')
  num? get silverTierBonusPerKm;

  /// Per-km bonus for Gold tier drivers (Used at checkout)
  @BuiltValueField(wireName: r'goldTierBonusPerKm')
  num? get goldTierBonusPerKm;

  /// Number of delivered orders after which a driver with a negative wallet balance must settle (transfer what they owe to the platform wallet) before receiving new orders. 0 disables.
  @BuiltValueField(wireName: r'driverSettlementOrderThreshold')
  num? get driverSettlementOrderThreshold;

  /// Max total break minutes allowed per shift
  @BuiltValueField(wireName: r'maxBreakMinutesPerShift')
  num? get maxBreakMinutesPerShift;

  /// Max number of breaks allowed per shift
  @BuiltValueField(wireName: r'maxBreaksPerShift')
  num? get maxBreaksPerShift;

  /// Max minutes for a single break before it is auto-ended by the system
  @BuiltValueField(wireName: r'maxSingleBreakMinutes')
  num? get maxSingleBreakMinutes;

  /// Minutes a break request stays PENDING before the system auto-rejects it
  @BuiltValueField(wireName: r'pendingBreakExpiryMins')
  num? get pendingBreakExpiryMins;

  UpdatePlatformSettingsDto._();

  factory UpdatePlatformSettingsDto([void updates(UpdatePlatformSettingsDtoBuilder b)]) = _$UpdatePlatformSettingsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePlatformSettingsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePlatformSettingsDto> get serializer => _$UpdatePlatformSettingsDtoSerializer();
}

class _$UpdatePlatformSettingsDtoSerializer implements PrimitiveSerializer<UpdatePlatformSettingsDto> {
  @override
  final Iterable<Type> types = const [UpdatePlatformSettingsDto, _$UpdatePlatformSettingsDto];

  @override
  final String wireName = r'UpdatePlatformSettingsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePlatformSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.currency != null) {
      yield r'currency';
      yield serializers.serialize(
        object.currency,
        specifiedType: const FullType(String),
      );
    }
    if (object.defaultCommissionRate != null) {
      yield r'defaultCommissionRate';
      yield serializers.serialize(
        object.defaultCommissionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.deliveryCommissionRate != null) {
      yield r'deliveryCommissionRate';
      yield serializers.serialize(
        object.deliveryCommissionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverManagerCommissionRate != null) {
      yield r'driverManagerCommissionRate';
      yield serializers.serialize(
        object.driverManagerCommissionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.customOrderPlatformFee != null) {
      yield r'customOrderPlatformFee';
      yield serializers.serialize(
        object.customOrderPlatformFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.defaultTaxRate != null) {
      yield r'defaultTaxRate';
      yield serializers.serialize(
        object.defaultTaxRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.minOrderAmount != null) {
      yield r'minOrderAmount';
      yield serializers.serialize(
        object.minOrderAmount,
        specifiedType: const FullType(num),
      );
    }
    if (object.baseDeliveryFee != null) {
      yield r'baseDeliveryFee';
      yield serializers.serialize(
        object.baseDeliveryFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.extraVendorDeliveryFee != null) {
      yield r'extraVendorDeliveryFee';
      yield serializers.serialize(
        object.extraVendorDeliveryFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKm != null) {
      yield r'pricePerKm';
      yield serializers.serialize(
        object.pricePerKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmBicycle != null) {
      yield r'pricePerKmBicycle';
      yield serializers.serialize(
        object.pricePerKmBicycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmMotorcycle != null) {
      yield r'pricePerKmMotorcycle';
      yield serializers.serialize(
        object.pricePerKmMotorcycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmCar != null) {
      yield r'pricePerKmCar';
      yield serializers.serialize(
        object.pricePerKmCar,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmVan != null) {
      yield r'pricePerKmVan';
      yield serializers.serialize(
        object.pricePerKmVan,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmTruck != null) {
      yield r'pricePerKmTruck';
      yield serializers.serialize(
        object.pricePerKmTruck,
        specifiedType: const FullType(num),
      );
    }
    if (object.pricePerKmMotorTricycle != null) {
      yield r'pricePerKmMotorTricycle';
      yield serializers.serialize(
        object.pricePerKmMotorTricycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFee != null) {
      yield r'maxDeliveryFee';
      yield serializers.serialize(
        object.maxDeliveryFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFee != null) {
      yield r'minDeliveryFee';
      yield serializers.serialize(
        object.minDeliveryFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeBicycle != null) {
      yield r'minDeliveryFeeBicycle';
      yield serializers.serialize(
        object.minDeliveryFeeBicycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeBicycle != null) {
      yield r'maxDeliveryFeeBicycle';
      yield serializers.serialize(
        object.maxDeliveryFeeBicycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeMotorcycle != null) {
      yield r'minDeliveryFeeMotorcycle';
      yield serializers.serialize(
        object.minDeliveryFeeMotorcycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeMotorcycle != null) {
      yield r'maxDeliveryFeeMotorcycle';
      yield serializers.serialize(
        object.maxDeliveryFeeMotorcycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeCar != null) {
      yield r'minDeliveryFeeCar';
      yield serializers.serialize(
        object.minDeliveryFeeCar,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeCar != null) {
      yield r'maxDeliveryFeeCar';
      yield serializers.serialize(
        object.maxDeliveryFeeCar,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeVan != null) {
      yield r'minDeliveryFeeVan';
      yield serializers.serialize(
        object.minDeliveryFeeVan,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeVan != null) {
      yield r'maxDeliveryFeeVan';
      yield serializers.serialize(
        object.maxDeliveryFeeVan,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeTruck != null) {
      yield r'minDeliveryFeeTruck';
      yield serializers.serialize(
        object.minDeliveryFeeTruck,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeTruck != null) {
      yield r'maxDeliveryFeeTruck';
      yield serializers.serialize(
        object.maxDeliveryFeeTruck,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDeliveryFeeMotorTricycle != null) {
      yield r'minDeliveryFeeMotorTricycle';
      yield serializers.serialize(
        object.minDeliveryFeeMotorTricycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryFeeMotorTricycle != null) {
      yield r'maxDeliveryFeeMotorTricycle';
      yield serializers.serialize(
        object.maxDeliveryFeeMotorTricycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.allowBicycle != null) {
      yield r'allowBicycle';
      yield serializers.serialize(
        object.allowBicycle,
        specifiedType: const FullType(bool),
      );
    }
    if (object.allowMotorcycle != null) {
      yield r'allowMotorcycle';
      yield serializers.serialize(
        object.allowMotorcycle,
        specifiedType: const FullType(bool),
      );
    }
    if (object.allowCar != null) {
      yield r'allowCar';
      yield serializers.serialize(
        object.allowCar,
        specifiedType: const FullType(bool),
      );
    }
    if (object.allowVan != null) {
      yield r'allowVan';
      yield serializers.serialize(
        object.allowVan,
        specifiedType: const FullType(bool),
      );
    }
    if (object.allowTruck != null) {
      yield r'allowTruck';
      yield serializers.serialize(
        object.allowTruck,
        specifiedType: const FullType(bool),
      );
    }
    if (object.allowMotorTricycle != null) {
      yield r'allowMotorTricycle';
      yield serializers.serialize(
        object.allowMotorTricycle,
        specifiedType: const FullType(bool),
      );
    }
    if (object.minOrderKm != null) {
      yield r'minOrderKm';
      yield serializers.serialize(
        object.minOrderKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.minDistanceFixedPrice != null) {
      yield r'minDistanceFixedPrice';
      yield serializers.serialize(
        object.minDistanceFixedPrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDeliveryRadiusKm != null) {
      yield r'maxDeliveryRadiusKm';
      yield serializers.serialize(
        object.maxDeliveryRadiusKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSearchRadiusKm != null) {
      yield r'driverSearchRadiusKm';
      yield serializers.serialize(
        object.driverSearchRadiusKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSearchRadiusStepKm != null) {
      yield r'driverSearchRadiusStepKm';
      yield serializers.serialize(
        object.driverSearchRadiusStepKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSearchRadiusMaxKm != null) {
      yield r'driverSearchRadiusMaxKm';
      yield serializers.serialize(
        object.driverSearchRadiusMaxKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSearchMaxAttempts != null) {
      yield r'driverSearchMaxAttempts';
      yield serializers.serialize(
        object.driverSearchMaxAttempts,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSearchGeoCandidateLimit != null) {
      yield r'driverSearchGeoCandidateLimit';
      yield serializers.serialize(
        object.driverSearchGeoCandidateLimit,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverLocationFreshnessTtlSecs != null) {
      yield r'driverLocationFreshnessTtlSecs';
      yield serializers.serialize(
        object.driverLocationFreshnessTtlSecs,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverLocationPrecisionMeters != null) {
      yield r'driverLocationPrecisionMeters';
      yield serializers.serialize(
        object.driverLocationPrecisionMeters,
        specifiedType: const FullType(num),
      );
    }
    if (object.groupingMaxBranchDistanceKm != null) {
      yield r'groupingMaxBranchDistanceKm';
      yield serializers.serialize(
        object.groupingMaxBranchDistanceKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.groupingMaxVendorCustomerDistanceKm != null) {
      yield r'groupingMaxVendorCustomerDistanceKm';
      yield serializers.serialize(
        object.groupingMaxVendorCustomerDistanceKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.autoCancelPendingMins != null) {
      yield r'autoCancelPendingMins';
      yield serializers.serialize(
        object.autoCancelPendingMins,
        specifiedType: const FullType(num),
      );
    }
    if (object.mobileWalletTimeoutMins != null) {
      yield r'mobileWalletTimeoutMins';
      yield serializers.serialize(
        object.mobileWalletTimeoutMins,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverAcceptTimeoutSecs != null) {
      yield r'driverAcceptTimeoutSecs';
      yield serializers.serialize(
        object.driverAcceptTimeoutSecs,
        specifiedType: const FullType(num),
      );
    }
    if (object.assistDecisionTimeoutSecs != null) {
      yield r'assistDecisionTimeoutSecs';
      yield serializers.serialize(
        object.assistDecisionTimeoutSecs,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxNegativeDriverBalance != null) {
      yield r'maxNegativeDriverBalance';
      yield serializers.serialize(
        object.maxNegativeDriverBalance,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxDispatchBatchSize != null) {
      yield r'maxDispatchBatchSize';
      yield serializers.serialize(
        object.maxDispatchBatchSize,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxActiveOrdersPerDriver != null) {
      yield r'maxActiveOrdersPerDriver';
      yield serializers.serialize(
        object.maxActiveOrdersPerDriver,
        specifiedType: const FullType(num),
      );
    }
    if (object.isMaintenanceMode != null) {
      yield r'isMaintenanceMode';
      yield serializers.serialize(
        object.isMaintenanceMode,
        specifiedType: const FullType(bool),
      );
    }
    if (object.androidMinVersion != null) {
      yield r'androidMinVersion';
      yield serializers.serialize(
        object.androidMinVersion,
        specifiedType: const FullType(String),
      );
    }
    if (object.androidLatestVersion != null) {
      yield r'androidLatestVersion';
      yield serializers.serialize(
        object.androidLatestVersion,
        specifiedType: const FullType(String),
      );
    }
    if (object.androidForceUpdate != null) {
      yield r'androidForceUpdate';
      yield serializers.serialize(
        object.androidForceUpdate,
        specifiedType: const FullType(bool),
      );
    }
    if (object.androidStoreUrl != null) {
      yield r'androidStoreUrl';
      yield serializers.serialize(
        object.androidStoreUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.iosMinVersion != null) {
      yield r'iosMinVersion';
      yield serializers.serialize(
        object.iosMinVersion,
        specifiedType: const FullType(String),
      );
    }
    if (object.iosLatestVersion != null) {
      yield r'iosLatestVersion';
      yield serializers.serialize(
        object.iosLatestVersion,
        specifiedType: const FullType(String),
      );
    }
    if (object.maxActiveOrdersPerCustomer != null) {
      yield r'maxActiveOrdersPerCustomer';
      yield serializers.serialize(
        object.maxActiveOrdersPerCustomer,
        specifiedType: const FullType(num),
      );
    }
    if (object.requirePriorDeliveryForMultipleOrders != null) {
      yield r'requirePriorDeliveryForMultipleOrders';
      yield serializers.serialize(
        object.requirePriorDeliveryForMultipleOrders,
        specifiedType: const FullType(bool),
      );
    }
    if (object.maxOtpAttempts != null) {
      yield r'maxOtpAttempts';
      yield serializers.serialize(
        object.maxOtpAttempts,
        specifiedType: const FullType(num),
      );
    }
    if (object.otpExpirySeconds != null) {
      yield r'otpExpirySeconds';
      yield serializers.serialize(
        object.otpExpirySeconds,
        specifiedType: const FullType(num),
      );
    }
    if (object.iosForceUpdate != null) {
      yield r'iosForceUpdate';
      yield serializers.serialize(
        object.iosForceUpdate,
        specifiedType: const FullType(bool),
      );
    }
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
    if (object.retentionOrdersDays != null) {
      yield r'retentionOrdersDays';
      yield serializers.serialize(
        object.retentionOrdersDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionArchivedChatsDays != null) {
      yield r'retentionArchivedChatsDays';
      yield serializers.serialize(
        object.retentionArchivedChatsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionNotificationsDays != null) {
      yield r'retentionNotificationsDays';
      yield serializers.serialize(
        object.retentionNotificationsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionExpiredSessionsDays != null) {
      yield r'retentionExpiredSessionsDays';
      yield serializers.serialize(
        object.retentionExpiredSessionsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionAuditLogsDays != null) {
      yield r'retentionAuditLogsDays';
      yield serializers.serialize(
        object.retentionAuditLogsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionAbandonedCartsDays != null) {
      yield r'retentionAbandonedCartsDays';
      yield serializers.serialize(
        object.retentionAbandonedCartsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionPaymentReceiptsDays != null) {
      yield r'retentionPaymentReceiptsDays';
      yield serializers.serialize(
        object.retentionPaymentReceiptsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionShiftStartPhotosDays != null) {
      yield r'retentionShiftStartPhotosDays';
      yield serializers.serialize(
        object.retentionShiftStartPhotosDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionPickupPhotosDays != null) {
      yield r'retentionPickupPhotosDays';
      yield serializers.serialize(
        object.retentionPickupPhotosDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionDeliveryPhotosDays != null) {
      yield r'retentionDeliveryPhotosDays';
      yield serializers.serialize(
        object.retentionDeliveryPhotosDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionWalletTransactionsDays != null) {
      yield r'retentionWalletTransactionsDays';
      yield serializers.serialize(
        object.retentionWalletTransactionsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.retentionStatisticsDays != null) {
      yield r'retentionStatisticsDays';
      yield serializers.serialize(
        object.retentionStatisticsDays,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxKmForBicycle != null) {
      yield r'maxKmForBicycle';
      yield serializers.serialize(
        object.maxKmForBicycle,
        specifiedType: const FullType(num),
      );
    }
    if (object.coinValue != null) {
      yield r'coinValue';
      yield serializers.serialize(
        object.coinValue,
        specifiedType: const FullType(num),
      );
    }
    if (object.amountSpentPerCoin != null) {
      yield r'amountSpentPerCoin';
      yield serializers.serialize(
        object.amountSpentPerCoin,
        specifiedType: const FullType(num),
      );
    }
    if (object.minCoinsToUse != null) {
      yield r'minCoinsToUse';
      yield serializers.serialize(
        object.minCoinsToUse,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverBonusActive != null) {
      yield r'driverBonusActive';
      yield serializers.serialize(
        object.driverBonusActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.driverBonusAmount != null) {
      yield r'driverBonusAmount';
      yield serializers.serialize(
        object.driverBonusAmount,
        specifiedType: const FullType(num),
      );
    }
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
    if (object.driverBonusPaidByCustomer != null) {
      yield r'driverBonusPaidByCustomer';
      yield serializers.serialize(
        object.driverBonusPaidByCustomer,
        specifiedType: const FullType(bool),
      );
    }
    if (object.highValueOrderThreshold != null) {
      yield r'highValueOrderThreshold';
      yield serializers.serialize(
        object.highValueOrderThreshold,
        specifiedType: const FullType(num),
      );
    }
    if (object.highValueUpfrontRate != null) {
      yield r'highValueUpfrontRate';
      yield serializers.serialize(
        object.highValueUpfrontRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverShiftsEnabled != null) {
      yield r'driverShiftsEnabled';
      yield serializers.serialize(
        object.driverShiftsEnabled,
        specifiedType: const FullType(bool),
      );
    }
    if (object.breaksEnabled != null) {
      yield r'breaksEnabled';
      yield serializers.serialize(
        object.breaksEnabled,
        specifiedType: const FullType(bool),
      );
    }
    if (object.bronzeTierBonusPerKm != null) {
      yield r'bronzeTierBonusPerKm';
      yield serializers.serialize(
        object.bronzeTierBonusPerKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.silverTierBonusPerKm != null) {
      yield r'silverTierBonusPerKm';
      yield serializers.serialize(
        object.silverTierBonusPerKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.goldTierBonusPerKm != null) {
      yield r'goldTierBonusPerKm';
      yield serializers.serialize(
        object.goldTierBonusPerKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverSettlementOrderThreshold != null) {
      yield r'driverSettlementOrderThreshold';
      yield serializers.serialize(
        object.driverSettlementOrderThreshold,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxBreakMinutesPerShift != null) {
      yield r'maxBreakMinutesPerShift';
      yield serializers.serialize(
        object.maxBreakMinutesPerShift,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxBreaksPerShift != null) {
      yield r'maxBreaksPerShift';
      yield serializers.serialize(
        object.maxBreaksPerShift,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxSingleBreakMinutes != null) {
      yield r'maxSingleBreakMinutes';
      yield serializers.serialize(
        object.maxSingleBreakMinutes,
        specifiedType: const FullType(num),
      );
    }
    if (object.pendingBreakExpiryMins != null) {
      yield r'pendingBreakExpiryMins';
      yield serializers.serialize(
        object.pendingBreakExpiryMins,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePlatformSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePlatformSettingsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'driverManagerCommissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverManagerCommissionRate = valueDes;
          break;
        case r'customOrderPlatformFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.customOrderPlatformFee = valueDes;
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
        case r'extraVendorDeliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.extraVendorDeliveryFee = valueDes;
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
        case r'minDeliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minDeliveryFee = valueDes;
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
        case r'driverSearchMaxAttempts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchMaxAttempts = valueDes;
          break;
        case r'driverSearchGeoCandidateLimit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSearchGeoCandidateLimit = valueDes;
          break;
        case r'driverLocationFreshnessTtlSecs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverLocationFreshnessTtlSecs = valueDes;
          break;
        case r'driverLocationPrecisionMeters':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverLocationPrecisionMeters = valueDes;
          break;
        case r'groupingMaxBranchDistanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.groupingMaxBranchDistanceKm = valueDes;
          break;
        case r'groupingMaxVendorCustomerDistanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.groupingMaxVendorCustomerDistanceKm = valueDes;
          break;
        case r'autoCancelPendingMins':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.autoCancelPendingMins = valueDes;
          break;
        case r'mobileWalletTimeoutMins':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.mobileWalletTimeoutMins = valueDes;
          break;
        case r'driverAcceptTimeoutSecs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverAcceptTimeoutSecs = valueDes;
          break;
        case r'assistDecisionTimeoutSecs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.assistDecisionTimeoutSecs = valueDes;
          break;
        case r'maxNegativeDriverBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxNegativeDriverBalance = valueDes;
          break;
        case r'maxDispatchBatchSize':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDispatchBatchSize = valueDes;
          break;
        case r'maxActiveOrdersPerDriver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxActiveOrdersPerDriver = valueDes;
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
        case r'otpExpirySeconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.otpExpirySeconds = valueDes;
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
        case r'retentionPaymentReceiptsDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionPaymentReceiptsDays = valueDes;
          break;
        case r'retentionShiftStartPhotosDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionShiftStartPhotosDays = valueDes;
          break;
        case r'retentionPickupPhotosDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionPickupPhotosDays = valueDes;
          break;
        case r'retentionDeliveryPhotosDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.retentionDeliveryPhotosDays = valueDes;
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
        case r'driverShiftsEnabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.driverShiftsEnabled = valueDes;
          break;
        case r'breaksEnabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.breaksEnabled = valueDes;
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
        case r'driverSettlementOrderThreshold':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverSettlementOrderThreshold = valueDes;
          break;
        case r'maxBreakMinutesPerShift':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxBreakMinutesPerShift = valueDes;
          break;
        case r'maxBreaksPerShift':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxBreaksPerShift = valueDes;
          break;
        case r'maxSingleBreakMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxSingleBreakMinutes = valueDes;
          break;
        case r'pendingBreakExpiryMins':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pendingBreakExpiryMins = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdatePlatformSettingsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePlatformSettingsDtoBuilder();
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

