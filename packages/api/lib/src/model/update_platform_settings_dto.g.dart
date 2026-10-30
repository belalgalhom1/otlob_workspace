// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_platform_settings_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePlatformSettingsDto extends UpdatePlatformSettingsDto {
  @override
  final String? currency;
  @override
  final num? defaultCommissionRate;
  @override
  final num? deliveryCommissionRate;
  @override
  final num? driverManagerCommissionRate;
  @override
  final num? customOrderPlatformFee;
  @override
  final num? defaultTaxRate;
  @override
  final num? minOrderAmount;
  @override
  final num? baseDeliveryFee;
  @override
  final num? extraVendorDeliveryFee;
  @override
  final num? pricePerKm;
  @override
  final num? pricePerKmBicycle;
  @override
  final num? pricePerKmMotorcycle;
  @override
  final num? pricePerKmCar;
  @override
  final num? pricePerKmVan;
  @override
  final num? pricePerKmTruck;
  @override
  final num? pricePerKmMotorTricycle;
  @override
  final num? maxDeliveryFee;
  @override
  final num? minDeliveryFee;
  @override
  final num? minDeliveryFeeBicycle;
  @override
  final num? maxDeliveryFeeBicycle;
  @override
  final num? minDeliveryFeeMotorcycle;
  @override
  final num? maxDeliveryFeeMotorcycle;
  @override
  final num? minDeliveryFeeCar;
  @override
  final num? maxDeliveryFeeCar;
  @override
  final num? minDeliveryFeeVan;
  @override
  final num? maxDeliveryFeeVan;
  @override
  final num? minDeliveryFeeTruck;
  @override
  final num? maxDeliveryFeeTruck;
  @override
  final num? minDeliveryFeeMotorTricycle;
  @override
  final num? maxDeliveryFeeMotorTricycle;
  @override
  final bool? allowBicycle;
  @override
  final bool? allowMotorcycle;
  @override
  final bool? allowCar;
  @override
  final bool? allowVan;
  @override
  final bool? allowTruck;
  @override
  final bool? allowMotorTricycle;
  @override
  final num? minOrderKm;
  @override
  final num? minDistanceFixedPrice;
  @override
  final num? maxDeliveryRadiusKm;
  @override
  final num? driverSearchRadiusKm;
  @override
  final num? driverSearchRadiusStepKm;
  @override
  final num? driverSearchRadiusMaxKm;
  @override
  final num? driverSearchMaxAttempts;
  @override
  final num? driverSearchGeoCandidateLimit;
  @override
  final num? driverLocationFreshnessTtlSecs;
  @override
  final num? driverLocationPrecisionMeters;
  @override
  final num? groupingMaxBranchDistanceKm;
  @override
  final num? groupingMaxVendorCustomerDistanceKm;
  @override
  final num? autoCancelPendingMins;
  @override
  final num? mobileWalletTimeoutMins;
  @override
  final num? driverAcceptTimeoutSecs;
  @override
  final num? assistDecisionTimeoutSecs;
  @override
  final num? maxNegativeDriverBalance;
  @override
  final num? maxDispatchBatchSize;
  @override
  final num? maxActiveOrdersPerDriver;
  @override
  final num? stackedOrderDriverPercentage;
  @override
  final num? batchMaxVendorDistanceKm;
  @override
  final num? batchMaxCustomerDistanceKm;
  @override
  final bool? isMaintenanceMode;
  @override
  final String? androidMinVersion;
  @override
  final String? androidLatestVersion;
  @override
  final bool? androidForceUpdate;
  @override
  final String? androidStoreUrl;
  @override
  final String? iosMinVersion;
  @override
  final String? iosLatestVersion;
  @override
  final num? maxActiveOrdersPerCustomer;
  @override
  final bool? requirePriorDeliveryForMultipleOrders;
  @override
  final num? maxOtpAttempts;
  @override
  final num? otpExpirySeconds;
  @override
  final bool? iosForceUpdate;
  @override
  final String? iosStoreUrl;
  @override
  final String? supportEmail;
  @override
  final String? supportPhone;
  @override
  final String? supportWhatsapp;
  @override
  final String? termsUrl;
  @override
  final String? privacyUrl;
  @override
  final num? retentionOrdersDays;
  @override
  final num? retentionArchivedChatsDays;
  @override
  final num? retentionNotificationsDays;
  @override
  final num? retentionExpiredSessionsDays;
  @override
  final num? retentionAuditLogsDays;
  @override
  final num? retentionAbandonedCartsDays;
  @override
  final num? retentionPaymentReceiptsDays;
  @override
  final num? retentionShiftStartPhotosDays;
  @override
  final num? retentionPickupPhotosDays;
  @override
  final num? retentionDeliveryPhotosDays;
  @override
  final num? retentionWalletTransactionsDays;
  @override
  final num? retentionStatisticsDays;
  @override
  final num? maxKmForBicycle;
  @override
  final num? coinValue;
  @override
  final num? amountSpentPerCoin;
  @override
  final num? minCoinsToUse;
  @override
  final bool? driverBonusActive;
  @override
  final num? driverBonusAmount;
  @override
  final DateTime? driverBonusStartDate;
  @override
  final DateTime? driverBonusEndDate;
  @override
  final bool? driverBonusPaidByCustomer;
  @override
  final num? highValueOrderThreshold;
  @override
  final num? highValueUpfrontRate;
  @override
  final bool? driverShiftsEnabled;
  @override
  final bool? breaksEnabled;
  @override
  final num? bronzeTierBonusPerKm;
  @override
  final num? silverTierBonusPerKm;
  @override
  final num? goldTierBonusPerKm;
  @override
  final num? driverSettlementOrderThreshold;
  @override
  final num? maxBreakMinutesPerShift;
  @override
  final num? maxBreaksPerShift;
  @override
  final num? maxSingleBreakMinutes;
  @override
  final num? pendingBreakExpiryMins;

  factory _$UpdatePlatformSettingsDto([
    void Function(UpdatePlatformSettingsDtoBuilder)? updates,
  ]) => (UpdatePlatformSettingsDtoBuilder()..update(updates))._build();

  _$UpdatePlatformSettingsDto._({
    this.currency,
    this.defaultCommissionRate,
    this.deliveryCommissionRate,
    this.driverManagerCommissionRate,
    this.customOrderPlatformFee,
    this.defaultTaxRate,
    this.minOrderAmount,
    this.baseDeliveryFee,
    this.extraVendorDeliveryFee,
    this.pricePerKm,
    this.pricePerKmBicycle,
    this.pricePerKmMotorcycle,
    this.pricePerKmCar,
    this.pricePerKmVan,
    this.pricePerKmTruck,
    this.pricePerKmMotorTricycle,
    this.maxDeliveryFee,
    this.minDeliveryFee,
    this.minDeliveryFeeBicycle,
    this.maxDeliveryFeeBicycle,
    this.minDeliveryFeeMotorcycle,
    this.maxDeliveryFeeMotorcycle,
    this.minDeliveryFeeCar,
    this.maxDeliveryFeeCar,
    this.minDeliveryFeeVan,
    this.maxDeliveryFeeVan,
    this.minDeliveryFeeTruck,
    this.maxDeliveryFeeTruck,
    this.minDeliveryFeeMotorTricycle,
    this.maxDeliveryFeeMotorTricycle,
    this.allowBicycle,
    this.allowMotorcycle,
    this.allowCar,
    this.allowVan,
    this.allowTruck,
    this.allowMotorTricycle,
    this.minOrderKm,
    this.minDistanceFixedPrice,
    this.maxDeliveryRadiusKm,
    this.driverSearchRadiusKm,
    this.driverSearchRadiusStepKm,
    this.driverSearchRadiusMaxKm,
    this.driverSearchMaxAttempts,
    this.driverSearchGeoCandidateLimit,
    this.driverLocationFreshnessTtlSecs,
    this.driverLocationPrecisionMeters,
    this.groupingMaxBranchDistanceKm,
    this.groupingMaxVendorCustomerDistanceKm,
    this.autoCancelPendingMins,
    this.mobileWalletTimeoutMins,
    this.driverAcceptTimeoutSecs,
    this.assistDecisionTimeoutSecs,
    this.maxNegativeDriverBalance,
    this.maxDispatchBatchSize,
    this.maxActiveOrdersPerDriver,
    this.stackedOrderDriverPercentage,
    this.batchMaxVendorDistanceKm,
    this.batchMaxCustomerDistanceKm,
    this.isMaintenanceMode,
    this.androidMinVersion,
    this.androidLatestVersion,
    this.androidForceUpdate,
    this.androidStoreUrl,
    this.iosMinVersion,
    this.iosLatestVersion,
    this.maxActiveOrdersPerCustomer,
    this.requirePriorDeliveryForMultipleOrders,
    this.maxOtpAttempts,
    this.otpExpirySeconds,
    this.iosForceUpdate,
    this.iosStoreUrl,
    this.supportEmail,
    this.supportPhone,
    this.supportWhatsapp,
    this.termsUrl,
    this.privacyUrl,
    this.retentionOrdersDays,
    this.retentionArchivedChatsDays,
    this.retentionNotificationsDays,
    this.retentionExpiredSessionsDays,
    this.retentionAuditLogsDays,
    this.retentionAbandonedCartsDays,
    this.retentionPaymentReceiptsDays,
    this.retentionShiftStartPhotosDays,
    this.retentionPickupPhotosDays,
    this.retentionDeliveryPhotosDays,
    this.retentionWalletTransactionsDays,
    this.retentionStatisticsDays,
    this.maxKmForBicycle,
    this.coinValue,
    this.amountSpentPerCoin,
    this.minCoinsToUse,
    this.driverBonusActive,
    this.driverBonusAmount,
    this.driverBonusStartDate,
    this.driverBonusEndDate,
    this.driverBonusPaidByCustomer,
    this.highValueOrderThreshold,
    this.highValueUpfrontRate,
    this.driverShiftsEnabled,
    this.breaksEnabled,
    this.bronzeTierBonusPerKm,
    this.silverTierBonusPerKm,
    this.goldTierBonusPerKm,
    this.driverSettlementOrderThreshold,
    this.maxBreakMinutesPerShift,
    this.maxBreaksPerShift,
    this.maxSingleBreakMinutes,
    this.pendingBreakExpiryMins,
  }) : super._();
  @override
  UpdatePlatformSettingsDto rebuild(
    void Function(UpdatePlatformSettingsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdatePlatformSettingsDtoBuilder toBuilder() =>
      UpdatePlatformSettingsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePlatformSettingsDto &&
        currency == other.currency &&
        defaultCommissionRate == other.defaultCommissionRate &&
        deliveryCommissionRate == other.deliveryCommissionRate &&
        driverManagerCommissionRate == other.driverManagerCommissionRate &&
        customOrderPlatformFee == other.customOrderPlatformFee &&
        defaultTaxRate == other.defaultTaxRate &&
        minOrderAmount == other.minOrderAmount &&
        baseDeliveryFee == other.baseDeliveryFee &&
        extraVendorDeliveryFee == other.extraVendorDeliveryFee &&
        pricePerKm == other.pricePerKm &&
        pricePerKmBicycle == other.pricePerKmBicycle &&
        pricePerKmMotorcycle == other.pricePerKmMotorcycle &&
        pricePerKmCar == other.pricePerKmCar &&
        pricePerKmVan == other.pricePerKmVan &&
        pricePerKmTruck == other.pricePerKmTruck &&
        pricePerKmMotorTricycle == other.pricePerKmMotorTricycle &&
        maxDeliveryFee == other.maxDeliveryFee &&
        minDeliveryFee == other.minDeliveryFee &&
        minDeliveryFeeBicycle == other.minDeliveryFeeBicycle &&
        maxDeliveryFeeBicycle == other.maxDeliveryFeeBicycle &&
        minDeliveryFeeMotorcycle == other.minDeliveryFeeMotorcycle &&
        maxDeliveryFeeMotorcycle == other.maxDeliveryFeeMotorcycle &&
        minDeliveryFeeCar == other.minDeliveryFeeCar &&
        maxDeliveryFeeCar == other.maxDeliveryFeeCar &&
        minDeliveryFeeVan == other.minDeliveryFeeVan &&
        maxDeliveryFeeVan == other.maxDeliveryFeeVan &&
        minDeliveryFeeTruck == other.minDeliveryFeeTruck &&
        maxDeliveryFeeTruck == other.maxDeliveryFeeTruck &&
        minDeliveryFeeMotorTricycle == other.minDeliveryFeeMotorTricycle &&
        maxDeliveryFeeMotorTricycle == other.maxDeliveryFeeMotorTricycle &&
        allowBicycle == other.allowBicycle &&
        allowMotorcycle == other.allowMotorcycle &&
        allowCar == other.allowCar &&
        allowVan == other.allowVan &&
        allowTruck == other.allowTruck &&
        allowMotorTricycle == other.allowMotorTricycle &&
        minOrderKm == other.minOrderKm &&
        minDistanceFixedPrice == other.minDistanceFixedPrice &&
        maxDeliveryRadiusKm == other.maxDeliveryRadiusKm &&
        driverSearchRadiusKm == other.driverSearchRadiusKm &&
        driverSearchRadiusStepKm == other.driverSearchRadiusStepKm &&
        driverSearchRadiusMaxKm == other.driverSearchRadiusMaxKm &&
        driverSearchMaxAttempts == other.driverSearchMaxAttempts &&
        driverSearchGeoCandidateLimit == other.driverSearchGeoCandidateLimit &&
        driverLocationFreshnessTtlSecs ==
            other.driverLocationFreshnessTtlSecs &&
        driverLocationPrecisionMeters == other.driverLocationPrecisionMeters &&
        groupingMaxBranchDistanceKm == other.groupingMaxBranchDistanceKm &&
        groupingMaxVendorCustomerDistanceKm ==
            other.groupingMaxVendorCustomerDistanceKm &&
        autoCancelPendingMins == other.autoCancelPendingMins &&
        mobileWalletTimeoutMins == other.mobileWalletTimeoutMins &&
        driverAcceptTimeoutSecs == other.driverAcceptTimeoutSecs &&
        assistDecisionTimeoutSecs == other.assistDecisionTimeoutSecs &&
        maxNegativeDriverBalance == other.maxNegativeDriverBalance &&
        maxDispatchBatchSize == other.maxDispatchBatchSize &&
        maxActiveOrdersPerDriver == other.maxActiveOrdersPerDriver &&
        stackedOrderDriverPercentage == other.stackedOrderDriverPercentage &&
        batchMaxVendorDistanceKm == other.batchMaxVendorDistanceKm &&
        batchMaxCustomerDistanceKm == other.batchMaxCustomerDistanceKm &&
        isMaintenanceMode == other.isMaintenanceMode &&
        androidMinVersion == other.androidMinVersion &&
        androidLatestVersion == other.androidLatestVersion &&
        androidForceUpdate == other.androidForceUpdate &&
        androidStoreUrl == other.androidStoreUrl &&
        iosMinVersion == other.iosMinVersion &&
        iosLatestVersion == other.iosLatestVersion &&
        maxActiveOrdersPerCustomer == other.maxActiveOrdersPerCustomer &&
        requirePriorDeliveryForMultipleOrders ==
            other.requirePriorDeliveryForMultipleOrders &&
        maxOtpAttempts == other.maxOtpAttempts &&
        otpExpirySeconds == other.otpExpirySeconds &&
        iosForceUpdate == other.iosForceUpdate &&
        iosStoreUrl == other.iosStoreUrl &&
        supportEmail == other.supportEmail &&
        supportPhone == other.supportPhone &&
        supportWhatsapp == other.supportWhatsapp &&
        termsUrl == other.termsUrl &&
        privacyUrl == other.privacyUrl &&
        retentionOrdersDays == other.retentionOrdersDays &&
        retentionArchivedChatsDays == other.retentionArchivedChatsDays &&
        retentionNotificationsDays == other.retentionNotificationsDays &&
        retentionExpiredSessionsDays == other.retentionExpiredSessionsDays &&
        retentionAuditLogsDays == other.retentionAuditLogsDays &&
        retentionAbandonedCartsDays == other.retentionAbandonedCartsDays &&
        retentionPaymentReceiptsDays == other.retentionPaymentReceiptsDays &&
        retentionShiftStartPhotosDays == other.retentionShiftStartPhotosDays &&
        retentionPickupPhotosDays == other.retentionPickupPhotosDays &&
        retentionDeliveryPhotosDays == other.retentionDeliveryPhotosDays &&
        retentionWalletTransactionsDays ==
            other.retentionWalletTransactionsDays &&
        retentionStatisticsDays == other.retentionStatisticsDays &&
        maxKmForBicycle == other.maxKmForBicycle &&
        coinValue == other.coinValue &&
        amountSpentPerCoin == other.amountSpentPerCoin &&
        minCoinsToUse == other.minCoinsToUse &&
        driverBonusActive == other.driverBonusActive &&
        driverBonusAmount == other.driverBonusAmount &&
        driverBonusStartDate == other.driverBonusStartDate &&
        driverBonusEndDate == other.driverBonusEndDate &&
        driverBonusPaidByCustomer == other.driverBonusPaidByCustomer &&
        highValueOrderThreshold == other.highValueOrderThreshold &&
        highValueUpfrontRate == other.highValueUpfrontRate &&
        driverShiftsEnabled == other.driverShiftsEnabled &&
        breaksEnabled == other.breaksEnabled &&
        bronzeTierBonusPerKm == other.bronzeTierBonusPerKm &&
        silverTierBonusPerKm == other.silverTierBonusPerKm &&
        goldTierBonusPerKm == other.goldTierBonusPerKm &&
        driverSettlementOrderThreshold ==
            other.driverSettlementOrderThreshold &&
        maxBreakMinutesPerShift == other.maxBreakMinutesPerShift &&
        maxBreaksPerShift == other.maxBreaksPerShift &&
        maxSingleBreakMinutes == other.maxSingleBreakMinutes &&
        pendingBreakExpiryMins == other.pendingBreakExpiryMins;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, defaultCommissionRate.hashCode);
    _$hash = $jc(_$hash, deliveryCommissionRate.hashCode);
    _$hash = $jc(_$hash, driverManagerCommissionRate.hashCode);
    _$hash = $jc(_$hash, customOrderPlatformFee.hashCode);
    _$hash = $jc(_$hash, defaultTaxRate.hashCode);
    _$hash = $jc(_$hash, minOrderAmount.hashCode);
    _$hash = $jc(_$hash, baseDeliveryFee.hashCode);
    _$hash = $jc(_$hash, extraVendorDeliveryFee.hashCode);
    _$hash = $jc(_$hash, pricePerKm.hashCode);
    _$hash = $jc(_$hash, pricePerKmBicycle.hashCode);
    _$hash = $jc(_$hash, pricePerKmMotorcycle.hashCode);
    _$hash = $jc(_$hash, pricePerKmCar.hashCode);
    _$hash = $jc(_$hash, pricePerKmVan.hashCode);
    _$hash = $jc(_$hash, pricePerKmTruck.hashCode);
    _$hash = $jc(_$hash, pricePerKmMotorTricycle.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFee.hashCode);
    _$hash = $jc(_$hash, minDeliveryFee.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeBicycle.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeBicycle.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeMotorcycle.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeMotorcycle.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeCar.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeCar.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeVan.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeVan.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeTruck.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeTruck.hashCode);
    _$hash = $jc(_$hash, minDeliveryFeeMotorTricycle.hashCode);
    _$hash = $jc(_$hash, maxDeliveryFeeMotorTricycle.hashCode);
    _$hash = $jc(_$hash, allowBicycle.hashCode);
    _$hash = $jc(_$hash, allowMotorcycle.hashCode);
    _$hash = $jc(_$hash, allowCar.hashCode);
    _$hash = $jc(_$hash, allowVan.hashCode);
    _$hash = $jc(_$hash, allowTruck.hashCode);
    _$hash = $jc(_$hash, allowMotorTricycle.hashCode);
    _$hash = $jc(_$hash, minOrderKm.hashCode);
    _$hash = $jc(_$hash, minDistanceFixedPrice.hashCode);
    _$hash = $jc(_$hash, maxDeliveryRadiusKm.hashCode);
    _$hash = $jc(_$hash, driverSearchRadiusKm.hashCode);
    _$hash = $jc(_$hash, driverSearchRadiusStepKm.hashCode);
    _$hash = $jc(_$hash, driverSearchRadiusMaxKm.hashCode);
    _$hash = $jc(_$hash, driverSearchMaxAttempts.hashCode);
    _$hash = $jc(_$hash, driverSearchGeoCandidateLimit.hashCode);
    _$hash = $jc(_$hash, driverLocationFreshnessTtlSecs.hashCode);
    _$hash = $jc(_$hash, driverLocationPrecisionMeters.hashCode);
    _$hash = $jc(_$hash, groupingMaxBranchDistanceKm.hashCode);
    _$hash = $jc(_$hash, groupingMaxVendorCustomerDistanceKm.hashCode);
    _$hash = $jc(_$hash, autoCancelPendingMins.hashCode);
    _$hash = $jc(_$hash, mobileWalletTimeoutMins.hashCode);
    _$hash = $jc(_$hash, driverAcceptTimeoutSecs.hashCode);
    _$hash = $jc(_$hash, assistDecisionTimeoutSecs.hashCode);
    _$hash = $jc(_$hash, maxNegativeDriverBalance.hashCode);
    _$hash = $jc(_$hash, maxDispatchBatchSize.hashCode);
    _$hash = $jc(_$hash, maxActiveOrdersPerDriver.hashCode);
    _$hash = $jc(_$hash, stackedOrderDriverPercentage.hashCode);
    _$hash = $jc(_$hash, batchMaxVendorDistanceKm.hashCode);
    _$hash = $jc(_$hash, batchMaxCustomerDistanceKm.hashCode);
    _$hash = $jc(_$hash, isMaintenanceMode.hashCode);
    _$hash = $jc(_$hash, androidMinVersion.hashCode);
    _$hash = $jc(_$hash, androidLatestVersion.hashCode);
    _$hash = $jc(_$hash, androidForceUpdate.hashCode);
    _$hash = $jc(_$hash, androidStoreUrl.hashCode);
    _$hash = $jc(_$hash, iosMinVersion.hashCode);
    _$hash = $jc(_$hash, iosLatestVersion.hashCode);
    _$hash = $jc(_$hash, maxActiveOrdersPerCustomer.hashCode);
    _$hash = $jc(_$hash, requirePriorDeliveryForMultipleOrders.hashCode);
    _$hash = $jc(_$hash, maxOtpAttempts.hashCode);
    _$hash = $jc(_$hash, otpExpirySeconds.hashCode);
    _$hash = $jc(_$hash, iosForceUpdate.hashCode);
    _$hash = $jc(_$hash, iosStoreUrl.hashCode);
    _$hash = $jc(_$hash, supportEmail.hashCode);
    _$hash = $jc(_$hash, supportPhone.hashCode);
    _$hash = $jc(_$hash, supportWhatsapp.hashCode);
    _$hash = $jc(_$hash, termsUrl.hashCode);
    _$hash = $jc(_$hash, privacyUrl.hashCode);
    _$hash = $jc(_$hash, retentionOrdersDays.hashCode);
    _$hash = $jc(_$hash, retentionArchivedChatsDays.hashCode);
    _$hash = $jc(_$hash, retentionNotificationsDays.hashCode);
    _$hash = $jc(_$hash, retentionExpiredSessionsDays.hashCode);
    _$hash = $jc(_$hash, retentionAuditLogsDays.hashCode);
    _$hash = $jc(_$hash, retentionAbandonedCartsDays.hashCode);
    _$hash = $jc(_$hash, retentionPaymentReceiptsDays.hashCode);
    _$hash = $jc(_$hash, retentionShiftStartPhotosDays.hashCode);
    _$hash = $jc(_$hash, retentionPickupPhotosDays.hashCode);
    _$hash = $jc(_$hash, retentionDeliveryPhotosDays.hashCode);
    _$hash = $jc(_$hash, retentionWalletTransactionsDays.hashCode);
    _$hash = $jc(_$hash, retentionStatisticsDays.hashCode);
    _$hash = $jc(_$hash, maxKmForBicycle.hashCode);
    _$hash = $jc(_$hash, coinValue.hashCode);
    _$hash = $jc(_$hash, amountSpentPerCoin.hashCode);
    _$hash = $jc(_$hash, minCoinsToUse.hashCode);
    _$hash = $jc(_$hash, driverBonusActive.hashCode);
    _$hash = $jc(_$hash, driverBonusAmount.hashCode);
    _$hash = $jc(_$hash, driverBonusStartDate.hashCode);
    _$hash = $jc(_$hash, driverBonusEndDate.hashCode);
    _$hash = $jc(_$hash, driverBonusPaidByCustomer.hashCode);
    _$hash = $jc(_$hash, highValueOrderThreshold.hashCode);
    _$hash = $jc(_$hash, highValueUpfrontRate.hashCode);
    _$hash = $jc(_$hash, driverShiftsEnabled.hashCode);
    _$hash = $jc(_$hash, breaksEnabled.hashCode);
    _$hash = $jc(_$hash, bronzeTierBonusPerKm.hashCode);
    _$hash = $jc(_$hash, silverTierBonusPerKm.hashCode);
    _$hash = $jc(_$hash, goldTierBonusPerKm.hashCode);
    _$hash = $jc(_$hash, driverSettlementOrderThreshold.hashCode);
    _$hash = $jc(_$hash, maxBreakMinutesPerShift.hashCode);
    _$hash = $jc(_$hash, maxBreaksPerShift.hashCode);
    _$hash = $jc(_$hash, maxSingleBreakMinutes.hashCode);
    _$hash = $jc(_$hash, pendingBreakExpiryMins.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePlatformSettingsDto')
          ..add('currency', currency)
          ..add('defaultCommissionRate', defaultCommissionRate)
          ..add('deliveryCommissionRate', deliveryCommissionRate)
          ..add('driverManagerCommissionRate', driverManagerCommissionRate)
          ..add('customOrderPlatformFee', customOrderPlatformFee)
          ..add('defaultTaxRate', defaultTaxRate)
          ..add('minOrderAmount', minOrderAmount)
          ..add('baseDeliveryFee', baseDeliveryFee)
          ..add('extraVendorDeliveryFee', extraVendorDeliveryFee)
          ..add('pricePerKm', pricePerKm)
          ..add('pricePerKmBicycle', pricePerKmBicycle)
          ..add('pricePerKmMotorcycle', pricePerKmMotorcycle)
          ..add('pricePerKmCar', pricePerKmCar)
          ..add('pricePerKmVan', pricePerKmVan)
          ..add('pricePerKmTruck', pricePerKmTruck)
          ..add('pricePerKmMotorTricycle', pricePerKmMotorTricycle)
          ..add('maxDeliveryFee', maxDeliveryFee)
          ..add('minDeliveryFee', minDeliveryFee)
          ..add('minDeliveryFeeBicycle', minDeliveryFeeBicycle)
          ..add('maxDeliveryFeeBicycle', maxDeliveryFeeBicycle)
          ..add('minDeliveryFeeMotorcycle', minDeliveryFeeMotorcycle)
          ..add('maxDeliveryFeeMotorcycle', maxDeliveryFeeMotorcycle)
          ..add('minDeliveryFeeCar', minDeliveryFeeCar)
          ..add('maxDeliveryFeeCar', maxDeliveryFeeCar)
          ..add('minDeliveryFeeVan', minDeliveryFeeVan)
          ..add('maxDeliveryFeeVan', maxDeliveryFeeVan)
          ..add('minDeliveryFeeTruck', minDeliveryFeeTruck)
          ..add('maxDeliveryFeeTruck', maxDeliveryFeeTruck)
          ..add('minDeliveryFeeMotorTricycle', minDeliveryFeeMotorTricycle)
          ..add('maxDeliveryFeeMotorTricycle', maxDeliveryFeeMotorTricycle)
          ..add('allowBicycle', allowBicycle)
          ..add('allowMotorcycle', allowMotorcycle)
          ..add('allowCar', allowCar)
          ..add('allowVan', allowVan)
          ..add('allowTruck', allowTruck)
          ..add('allowMotorTricycle', allowMotorTricycle)
          ..add('minOrderKm', minOrderKm)
          ..add('minDistanceFixedPrice', minDistanceFixedPrice)
          ..add('maxDeliveryRadiusKm', maxDeliveryRadiusKm)
          ..add('driverSearchRadiusKm', driverSearchRadiusKm)
          ..add('driverSearchRadiusStepKm', driverSearchRadiusStepKm)
          ..add('driverSearchRadiusMaxKm', driverSearchRadiusMaxKm)
          ..add('driverSearchMaxAttempts', driverSearchMaxAttempts)
          ..add('driverSearchGeoCandidateLimit', driverSearchGeoCandidateLimit)
          ..add(
            'driverLocationFreshnessTtlSecs',
            driverLocationFreshnessTtlSecs,
          )
          ..add('driverLocationPrecisionMeters', driverLocationPrecisionMeters)
          ..add('groupingMaxBranchDistanceKm', groupingMaxBranchDistanceKm)
          ..add(
            'groupingMaxVendorCustomerDistanceKm',
            groupingMaxVendorCustomerDistanceKm,
          )
          ..add('autoCancelPendingMins', autoCancelPendingMins)
          ..add('mobileWalletTimeoutMins', mobileWalletTimeoutMins)
          ..add('driverAcceptTimeoutSecs', driverAcceptTimeoutSecs)
          ..add('assistDecisionTimeoutSecs', assistDecisionTimeoutSecs)
          ..add('maxNegativeDriverBalance', maxNegativeDriverBalance)
          ..add('maxDispatchBatchSize', maxDispatchBatchSize)
          ..add('maxActiveOrdersPerDriver', maxActiveOrdersPerDriver)
          ..add('stackedOrderDriverPercentage', stackedOrderDriverPercentage)
          ..add('batchMaxVendorDistanceKm', batchMaxVendorDistanceKm)
          ..add('batchMaxCustomerDistanceKm', batchMaxCustomerDistanceKm)
          ..add('isMaintenanceMode', isMaintenanceMode)
          ..add('androidMinVersion', androidMinVersion)
          ..add('androidLatestVersion', androidLatestVersion)
          ..add('androidForceUpdate', androidForceUpdate)
          ..add('androidStoreUrl', androidStoreUrl)
          ..add('iosMinVersion', iosMinVersion)
          ..add('iosLatestVersion', iosLatestVersion)
          ..add('maxActiveOrdersPerCustomer', maxActiveOrdersPerCustomer)
          ..add(
            'requirePriorDeliveryForMultipleOrders',
            requirePriorDeliveryForMultipleOrders,
          )
          ..add('maxOtpAttempts', maxOtpAttempts)
          ..add('otpExpirySeconds', otpExpirySeconds)
          ..add('iosForceUpdate', iosForceUpdate)
          ..add('iosStoreUrl', iosStoreUrl)
          ..add('supportEmail', supportEmail)
          ..add('supportPhone', supportPhone)
          ..add('supportWhatsapp', supportWhatsapp)
          ..add('termsUrl', termsUrl)
          ..add('privacyUrl', privacyUrl)
          ..add('retentionOrdersDays', retentionOrdersDays)
          ..add('retentionArchivedChatsDays', retentionArchivedChatsDays)
          ..add('retentionNotificationsDays', retentionNotificationsDays)
          ..add('retentionExpiredSessionsDays', retentionExpiredSessionsDays)
          ..add('retentionAuditLogsDays', retentionAuditLogsDays)
          ..add('retentionAbandonedCartsDays', retentionAbandonedCartsDays)
          ..add('retentionPaymentReceiptsDays', retentionPaymentReceiptsDays)
          ..add('retentionShiftStartPhotosDays', retentionShiftStartPhotosDays)
          ..add('retentionPickupPhotosDays', retentionPickupPhotosDays)
          ..add('retentionDeliveryPhotosDays', retentionDeliveryPhotosDays)
          ..add(
            'retentionWalletTransactionsDays',
            retentionWalletTransactionsDays,
          )
          ..add('retentionStatisticsDays', retentionStatisticsDays)
          ..add('maxKmForBicycle', maxKmForBicycle)
          ..add('coinValue', coinValue)
          ..add('amountSpentPerCoin', amountSpentPerCoin)
          ..add('minCoinsToUse', minCoinsToUse)
          ..add('driverBonusActive', driverBonusActive)
          ..add('driverBonusAmount', driverBonusAmount)
          ..add('driverBonusStartDate', driverBonusStartDate)
          ..add('driverBonusEndDate', driverBonusEndDate)
          ..add('driverBonusPaidByCustomer', driverBonusPaidByCustomer)
          ..add('highValueOrderThreshold', highValueOrderThreshold)
          ..add('highValueUpfrontRate', highValueUpfrontRate)
          ..add('driverShiftsEnabled', driverShiftsEnabled)
          ..add('breaksEnabled', breaksEnabled)
          ..add('bronzeTierBonusPerKm', bronzeTierBonusPerKm)
          ..add('silverTierBonusPerKm', silverTierBonusPerKm)
          ..add('goldTierBonusPerKm', goldTierBonusPerKm)
          ..add(
            'driverSettlementOrderThreshold',
            driverSettlementOrderThreshold,
          )
          ..add('maxBreakMinutesPerShift', maxBreakMinutesPerShift)
          ..add('maxBreaksPerShift', maxBreaksPerShift)
          ..add('maxSingleBreakMinutes', maxSingleBreakMinutes)
          ..add('pendingBreakExpiryMins', pendingBreakExpiryMins))
        .toString();
  }
}

class UpdatePlatformSettingsDtoBuilder
    implements
        Builder<UpdatePlatformSettingsDto, UpdatePlatformSettingsDtoBuilder> {
  _$UpdatePlatformSettingsDto? _$v;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  num? _defaultCommissionRate;
  num? get defaultCommissionRate => _$this._defaultCommissionRate;
  set defaultCommissionRate(num? defaultCommissionRate) =>
      _$this._defaultCommissionRate = defaultCommissionRate;

  num? _deliveryCommissionRate;
  num? get deliveryCommissionRate => _$this._deliveryCommissionRate;
  set deliveryCommissionRate(num? deliveryCommissionRate) =>
      _$this._deliveryCommissionRate = deliveryCommissionRate;

  num? _driverManagerCommissionRate;
  num? get driverManagerCommissionRate => _$this._driverManagerCommissionRate;
  set driverManagerCommissionRate(num? driverManagerCommissionRate) =>
      _$this._driverManagerCommissionRate = driverManagerCommissionRate;

  num? _customOrderPlatformFee;
  num? get customOrderPlatformFee => _$this._customOrderPlatformFee;
  set customOrderPlatformFee(num? customOrderPlatformFee) =>
      _$this._customOrderPlatformFee = customOrderPlatformFee;

  num? _defaultTaxRate;
  num? get defaultTaxRate => _$this._defaultTaxRate;
  set defaultTaxRate(num? defaultTaxRate) =>
      _$this._defaultTaxRate = defaultTaxRate;

  num? _minOrderAmount;
  num? get minOrderAmount => _$this._minOrderAmount;
  set minOrderAmount(num? minOrderAmount) =>
      _$this._minOrderAmount = minOrderAmount;

  num? _baseDeliveryFee;
  num? get baseDeliveryFee => _$this._baseDeliveryFee;
  set baseDeliveryFee(num? baseDeliveryFee) =>
      _$this._baseDeliveryFee = baseDeliveryFee;

  num? _extraVendorDeliveryFee;
  num? get extraVendorDeliveryFee => _$this._extraVendorDeliveryFee;
  set extraVendorDeliveryFee(num? extraVendorDeliveryFee) =>
      _$this._extraVendorDeliveryFee = extraVendorDeliveryFee;

  num? _pricePerKm;
  num? get pricePerKm => _$this._pricePerKm;
  set pricePerKm(num? pricePerKm) => _$this._pricePerKm = pricePerKm;

  num? _pricePerKmBicycle;
  num? get pricePerKmBicycle => _$this._pricePerKmBicycle;
  set pricePerKmBicycle(num? pricePerKmBicycle) =>
      _$this._pricePerKmBicycle = pricePerKmBicycle;

  num? _pricePerKmMotorcycle;
  num? get pricePerKmMotorcycle => _$this._pricePerKmMotorcycle;
  set pricePerKmMotorcycle(num? pricePerKmMotorcycle) =>
      _$this._pricePerKmMotorcycle = pricePerKmMotorcycle;

  num? _pricePerKmCar;
  num? get pricePerKmCar => _$this._pricePerKmCar;
  set pricePerKmCar(num? pricePerKmCar) =>
      _$this._pricePerKmCar = pricePerKmCar;

  num? _pricePerKmVan;
  num? get pricePerKmVan => _$this._pricePerKmVan;
  set pricePerKmVan(num? pricePerKmVan) =>
      _$this._pricePerKmVan = pricePerKmVan;

  num? _pricePerKmTruck;
  num? get pricePerKmTruck => _$this._pricePerKmTruck;
  set pricePerKmTruck(num? pricePerKmTruck) =>
      _$this._pricePerKmTruck = pricePerKmTruck;

  num? _pricePerKmMotorTricycle;
  num? get pricePerKmMotorTricycle => _$this._pricePerKmMotorTricycle;
  set pricePerKmMotorTricycle(num? pricePerKmMotorTricycle) =>
      _$this._pricePerKmMotorTricycle = pricePerKmMotorTricycle;

  num? _maxDeliveryFee;
  num? get maxDeliveryFee => _$this._maxDeliveryFee;
  set maxDeliveryFee(num? maxDeliveryFee) =>
      _$this._maxDeliveryFee = maxDeliveryFee;

  num? _minDeliveryFee;
  num? get minDeliveryFee => _$this._minDeliveryFee;
  set minDeliveryFee(num? minDeliveryFee) =>
      _$this._minDeliveryFee = minDeliveryFee;

  num? _minDeliveryFeeBicycle;
  num? get minDeliveryFeeBicycle => _$this._minDeliveryFeeBicycle;
  set minDeliveryFeeBicycle(num? minDeliveryFeeBicycle) =>
      _$this._minDeliveryFeeBicycle = minDeliveryFeeBicycle;

  num? _maxDeliveryFeeBicycle;
  num? get maxDeliveryFeeBicycle => _$this._maxDeliveryFeeBicycle;
  set maxDeliveryFeeBicycle(num? maxDeliveryFeeBicycle) =>
      _$this._maxDeliveryFeeBicycle = maxDeliveryFeeBicycle;

  num? _minDeliveryFeeMotorcycle;
  num? get minDeliveryFeeMotorcycle => _$this._minDeliveryFeeMotorcycle;
  set minDeliveryFeeMotorcycle(num? minDeliveryFeeMotorcycle) =>
      _$this._minDeliveryFeeMotorcycle = minDeliveryFeeMotorcycle;

  num? _maxDeliveryFeeMotorcycle;
  num? get maxDeliveryFeeMotorcycle => _$this._maxDeliveryFeeMotorcycle;
  set maxDeliveryFeeMotorcycle(num? maxDeliveryFeeMotorcycle) =>
      _$this._maxDeliveryFeeMotorcycle = maxDeliveryFeeMotorcycle;

  num? _minDeliveryFeeCar;
  num? get minDeliveryFeeCar => _$this._minDeliveryFeeCar;
  set minDeliveryFeeCar(num? minDeliveryFeeCar) =>
      _$this._minDeliveryFeeCar = minDeliveryFeeCar;

  num? _maxDeliveryFeeCar;
  num? get maxDeliveryFeeCar => _$this._maxDeliveryFeeCar;
  set maxDeliveryFeeCar(num? maxDeliveryFeeCar) =>
      _$this._maxDeliveryFeeCar = maxDeliveryFeeCar;

  num? _minDeliveryFeeVan;
  num? get minDeliveryFeeVan => _$this._minDeliveryFeeVan;
  set minDeliveryFeeVan(num? minDeliveryFeeVan) =>
      _$this._minDeliveryFeeVan = minDeliveryFeeVan;

  num? _maxDeliveryFeeVan;
  num? get maxDeliveryFeeVan => _$this._maxDeliveryFeeVan;
  set maxDeliveryFeeVan(num? maxDeliveryFeeVan) =>
      _$this._maxDeliveryFeeVan = maxDeliveryFeeVan;

  num? _minDeliveryFeeTruck;
  num? get minDeliveryFeeTruck => _$this._minDeliveryFeeTruck;
  set minDeliveryFeeTruck(num? minDeliveryFeeTruck) =>
      _$this._minDeliveryFeeTruck = minDeliveryFeeTruck;

  num? _maxDeliveryFeeTruck;
  num? get maxDeliveryFeeTruck => _$this._maxDeliveryFeeTruck;
  set maxDeliveryFeeTruck(num? maxDeliveryFeeTruck) =>
      _$this._maxDeliveryFeeTruck = maxDeliveryFeeTruck;

  num? _minDeliveryFeeMotorTricycle;
  num? get minDeliveryFeeMotorTricycle => _$this._minDeliveryFeeMotorTricycle;
  set minDeliveryFeeMotorTricycle(num? minDeliveryFeeMotorTricycle) =>
      _$this._minDeliveryFeeMotorTricycle = minDeliveryFeeMotorTricycle;

  num? _maxDeliveryFeeMotorTricycle;
  num? get maxDeliveryFeeMotorTricycle => _$this._maxDeliveryFeeMotorTricycle;
  set maxDeliveryFeeMotorTricycle(num? maxDeliveryFeeMotorTricycle) =>
      _$this._maxDeliveryFeeMotorTricycle = maxDeliveryFeeMotorTricycle;

  bool? _allowBicycle;
  bool? get allowBicycle => _$this._allowBicycle;
  set allowBicycle(bool? allowBicycle) => _$this._allowBicycle = allowBicycle;

  bool? _allowMotorcycle;
  bool? get allowMotorcycle => _$this._allowMotorcycle;
  set allowMotorcycle(bool? allowMotorcycle) =>
      _$this._allowMotorcycle = allowMotorcycle;

  bool? _allowCar;
  bool? get allowCar => _$this._allowCar;
  set allowCar(bool? allowCar) => _$this._allowCar = allowCar;

  bool? _allowVan;
  bool? get allowVan => _$this._allowVan;
  set allowVan(bool? allowVan) => _$this._allowVan = allowVan;

  bool? _allowTruck;
  bool? get allowTruck => _$this._allowTruck;
  set allowTruck(bool? allowTruck) => _$this._allowTruck = allowTruck;

  bool? _allowMotorTricycle;
  bool? get allowMotorTricycle => _$this._allowMotorTricycle;
  set allowMotorTricycle(bool? allowMotorTricycle) =>
      _$this._allowMotorTricycle = allowMotorTricycle;

  num? _minOrderKm;
  num? get minOrderKm => _$this._minOrderKm;
  set minOrderKm(num? minOrderKm) => _$this._minOrderKm = minOrderKm;

  num? _minDistanceFixedPrice;
  num? get minDistanceFixedPrice => _$this._minDistanceFixedPrice;
  set minDistanceFixedPrice(num? minDistanceFixedPrice) =>
      _$this._minDistanceFixedPrice = minDistanceFixedPrice;

  num? _maxDeliveryRadiusKm;
  num? get maxDeliveryRadiusKm => _$this._maxDeliveryRadiusKm;
  set maxDeliveryRadiusKm(num? maxDeliveryRadiusKm) =>
      _$this._maxDeliveryRadiusKm = maxDeliveryRadiusKm;

  num? _driverSearchRadiusKm;
  num? get driverSearchRadiusKm => _$this._driverSearchRadiusKm;
  set driverSearchRadiusKm(num? driverSearchRadiusKm) =>
      _$this._driverSearchRadiusKm = driverSearchRadiusKm;

  num? _driverSearchRadiusStepKm;
  num? get driverSearchRadiusStepKm => _$this._driverSearchRadiusStepKm;
  set driverSearchRadiusStepKm(num? driverSearchRadiusStepKm) =>
      _$this._driverSearchRadiusStepKm = driverSearchRadiusStepKm;

  num? _driverSearchRadiusMaxKm;
  num? get driverSearchRadiusMaxKm => _$this._driverSearchRadiusMaxKm;
  set driverSearchRadiusMaxKm(num? driverSearchRadiusMaxKm) =>
      _$this._driverSearchRadiusMaxKm = driverSearchRadiusMaxKm;

  num? _driverSearchMaxAttempts;
  num? get driverSearchMaxAttempts => _$this._driverSearchMaxAttempts;
  set driverSearchMaxAttempts(num? driverSearchMaxAttempts) =>
      _$this._driverSearchMaxAttempts = driverSearchMaxAttempts;

  num? _driverSearchGeoCandidateLimit;
  num? get driverSearchGeoCandidateLimit =>
      _$this._driverSearchGeoCandidateLimit;
  set driverSearchGeoCandidateLimit(num? driverSearchGeoCandidateLimit) =>
      _$this._driverSearchGeoCandidateLimit = driverSearchGeoCandidateLimit;

  num? _driverLocationFreshnessTtlSecs;
  num? get driverLocationFreshnessTtlSecs =>
      _$this._driverLocationFreshnessTtlSecs;
  set driverLocationFreshnessTtlSecs(num? driverLocationFreshnessTtlSecs) =>
      _$this._driverLocationFreshnessTtlSecs = driverLocationFreshnessTtlSecs;

  num? _driverLocationPrecisionMeters;
  num? get driverLocationPrecisionMeters =>
      _$this._driverLocationPrecisionMeters;
  set driverLocationPrecisionMeters(num? driverLocationPrecisionMeters) =>
      _$this._driverLocationPrecisionMeters = driverLocationPrecisionMeters;

  num? _groupingMaxBranchDistanceKm;
  num? get groupingMaxBranchDistanceKm => _$this._groupingMaxBranchDistanceKm;
  set groupingMaxBranchDistanceKm(num? groupingMaxBranchDistanceKm) =>
      _$this._groupingMaxBranchDistanceKm = groupingMaxBranchDistanceKm;

  num? _groupingMaxVendorCustomerDistanceKm;
  num? get groupingMaxVendorCustomerDistanceKm =>
      _$this._groupingMaxVendorCustomerDistanceKm;
  set groupingMaxVendorCustomerDistanceKm(
    num? groupingMaxVendorCustomerDistanceKm,
  ) => _$this._groupingMaxVendorCustomerDistanceKm =
      groupingMaxVendorCustomerDistanceKm;

  num? _autoCancelPendingMins;
  num? get autoCancelPendingMins => _$this._autoCancelPendingMins;
  set autoCancelPendingMins(num? autoCancelPendingMins) =>
      _$this._autoCancelPendingMins = autoCancelPendingMins;

  num? _mobileWalletTimeoutMins;
  num? get mobileWalletTimeoutMins => _$this._mobileWalletTimeoutMins;
  set mobileWalletTimeoutMins(num? mobileWalletTimeoutMins) =>
      _$this._mobileWalletTimeoutMins = mobileWalletTimeoutMins;

  num? _driverAcceptTimeoutSecs;
  num? get driverAcceptTimeoutSecs => _$this._driverAcceptTimeoutSecs;
  set driverAcceptTimeoutSecs(num? driverAcceptTimeoutSecs) =>
      _$this._driverAcceptTimeoutSecs = driverAcceptTimeoutSecs;

  num? _assistDecisionTimeoutSecs;
  num? get assistDecisionTimeoutSecs => _$this._assistDecisionTimeoutSecs;
  set assistDecisionTimeoutSecs(num? assistDecisionTimeoutSecs) =>
      _$this._assistDecisionTimeoutSecs = assistDecisionTimeoutSecs;

  num? _maxNegativeDriverBalance;
  num? get maxNegativeDriverBalance => _$this._maxNegativeDriverBalance;
  set maxNegativeDriverBalance(num? maxNegativeDriverBalance) =>
      _$this._maxNegativeDriverBalance = maxNegativeDriverBalance;

  num? _maxDispatchBatchSize;
  num? get maxDispatchBatchSize => _$this._maxDispatchBatchSize;
  set maxDispatchBatchSize(num? maxDispatchBatchSize) =>
      _$this._maxDispatchBatchSize = maxDispatchBatchSize;

  num? _maxActiveOrdersPerDriver;
  num? get maxActiveOrdersPerDriver => _$this._maxActiveOrdersPerDriver;
  set maxActiveOrdersPerDriver(num? maxActiveOrdersPerDriver) =>
      _$this._maxActiveOrdersPerDriver = maxActiveOrdersPerDriver;

  num? _stackedOrderDriverPercentage;
  num? get stackedOrderDriverPercentage => _$this._stackedOrderDriverPercentage;
  set stackedOrderDriverPercentage(num? stackedOrderDriverPercentage) =>
      _$this._stackedOrderDriverPercentage = stackedOrderDriverPercentage;

  num? _batchMaxVendorDistanceKm;
  num? get batchMaxVendorDistanceKm => _$this._batchMaxVendorDistanceKm;
  set batchMaxVendorDistanceKm(num? batchMaxVendorDistanceKm) =>
      _$this._batchMaxVendorDistanceKm = batchMaxVendorDistanceKm;

  num? _batchMaxCustomerDistanceKm;
  num? get batchMaxCustomerDistanceKm => _$this._batchMaxCustomerDistanceKm;
  set batchMaxCustomerDistanceKm(num? batchMaxCustomerDistanceKm) =>
      _$this._batchMaxCustomerDistanceKm = batchMaxCustomerDistanceKm;

  bool? _isMaintenanceMode;
  bool? get isMaintenanceMode => _$this._isMaintenanceMode;
  set isMaintenanceMode(bool? isMaintenanceMode) =>
      _$this._isMaintenanceMode = isMaintenanceMode;

  String? _androidMinVersion;
  String? get androidMinVersion => _$this._androidMinVersion;
  set androidMinVersion(String? androidMinVersion) =>
      _$this._androidMinVersion = androidMinVersion;

  String? _androidLatestVersion;
  String? get androidLatestVersion => _$this._androidLatestVersion;
  set androidLatestVersion(String? androidLatestVersion) =>
      _$this._androidLatestVersion = androidLatestVersion;

  bool? _androidForceUpdate;
  bool? get androidForceUpdate => _$this._androidForceUpdate;
  set androidForceUpdate(bool? androidForceUpdate) =>
      _$this._androidForceUpdate = androidForceUpdate;

  String? _androidStoreUrl;
  String? get androidStoreUrl => _$this._androidStoreUrl;
  set androidStoreUrl(String? androidStoreUrl) =>
      _$this._androidStoreUrl = androidStoreUrl;

  String? _iosMinVersion;
  String? get iosMinVersion => _$this._iosMinVersion;
  set iosMinVersion(String? iosMinVersion) =>
      _$this._iosMinVersion = iosMinVersion;

  String? _iosLatestVersion;
  String? get iosLatestVersion => _$this._iosLatestVersion;
  set iosLatestVersion(String? iosLatestVersion) =>
      _$this._iosLatestVersion = iosLatestVersion;

  num? _maxActiveOrdersPerCustomer;
  num? get maxActiveOrdersPerCustomer => _$this._maxActiveOrdersPerCustomer;
  set maxActiveOrdersPerCustomer(num? maxActiveOrdersPerCustomer) =>
      _$this._maxActiveOrdersPerCustomer = maxActiveOrdersPerCustomer;

  bool? _requirePriorDeliveryForMultipleOrders;
  bool? get requirePriorDeliveryForMultipleOrders =>
      _$this._requirePriorDeliveryForMultipleOrders;
  set requirePriorDeliveryForMultipleOrders(
    bool? requirePriorDeliveryForMultipleOrders,
  ) => _$this._requirePriorDeliveryForMultipleOrders =
      requirePriorDeliveryForMultipleOrders;

  num? _maxOtpAttempts;
  num? get maxOtpAttempts => _$this._maxOtpAttempts;
  set maxOtpAttempts(num? maxOtpAttempts) =>
      _$this._maxOtpAttempts = maxOtpAttempts;

  num? _otpExpirySeconds;
  num? get otpExpirySeconds => _$this._otpExpirySeconds;
  set otpExpirySeconds(num? otpExpirySeconds) =>
      _$this._otpExpirySeconds = otpExpirySeconds;

  bool? _iosForceUpdate;
  bool? get iosForceUpdate => _$this._iosForceUpdate;
  set iosForceUpdate(bool? iosForceUpdate) =>
      _$this._iosForceUpdate = iosForceUpdate;

  String? _iosStoreUrl;
  String? get iosStoreUrl => _$this._iosStoreUrl;
  set iosStoreUrl(String? iosStoreUrl) => _$this._iosStoreUrl = iosStoreUrl;

  String? _supportEmail;
  String? get supportEmail => _$this._supportEmail;
  set supportEmail(String? supportEmail) => _$this._supportEmail = supportEmail;

  String? _supportPhone;
  String? get supportPhone => _$this._supportPhone;
  set supportPhone(String? supportPhone) => _$this._supportPhone = supportPhone;

  String? _supportWhatsapp;
  String? get supportWhatsapp => _$this._supportWhatsapp;
  set supportWhatsapp(String? supportWhatsapp) =>
      _$this._supportWhatsapp = supportWhatsapp;

  String? _termsUrl;
  String? get termsUrl => _$this._termsUrl;
  set termsUrl(String? termsUrl) => _$this._termsUrl = termsUrl;

  String? _privacyUrl;
  String? get privacyUrl => _$this._privacyUrl;
  set privacyUrl(String? privacyUrl) => _$this._privacyUrl = privacyUrl;

  num? _retentionOrdersDays;
  num? get retentionOrdersDays => _$this._retentionOrdersDays;
  set retentionOrdersDays(num? retentionOrdersDays) =>
      _$this._retentionOrdersDays = retentionOrdersDays;

  num? _retentionArchivedChatsDays;
  num? get retentionArchivedChatsDays => _$this._retentionArchivedChatsDays;
  set retentionArchivedChatsDays(num? retentionArchivedChatsDays) =>
      _$this._retentionArchivedChatsDays = retentionArchivedChatsDays;

  num? _retentionNotificationsDays;
  num? get retentionNotificationsDays => _$this._retentionNotificationsDays;
  set retentionNotificationsDays(num? retentionNotificationsDays) =>
      _$this._retentionNotificationsDays = retentionNotificationsDays;

  num? _retentionExpiredSessionsDays;
  num? get retentionExpiredSessionsDays => _$this._retentionExpiredSessionsDays;
  set retentionExpiredSessionsDays(num? retentionExpiredSessionsDays) =>
      _$this._retentionExpiredSessionsDays = retentionExpiredSessionsDays;

  num? _retentionAuditLogsDays;
  num? get retentionAuditLogsDays => _$this._retentionAuditLogsDays;
  set retentionAuditLogsDays(num? retentionAuditLogsDays) =>
      _$this._retentionAuditLogsDays = retentionAuditLogsDays;

  num? _retentionAbandonedCartsDays;
  num? get retentionAbandonedCartsDays => _$this._retentionAbandonedCartsDays;
  set retentionAbandonedCartsDays(num? retentionAbandonedCartsDays) =>
      _$this._retentionAbandonedCartsDays = retentionAbandonedCartsDays;

  num? _retentionPaymentReceiptsDays;
  num? get retentionPaymentReceiptsDays => _$this._retentionPaymentReceiptsDays;
  set retentionPaymentReceiptsDays(num? retentionPaymentReceiptsDays) =>
      _$this._retentionPaymentReceiptsDays = retentionPaymentReceiptsDays;

  num? _retentionShiftStartPhotosDays;
  num? get retentionShiftStartPhotosDays =>
      _$this._retentionShiftStartPhotosDays;
  set retentionShiftStartPhotosDays(num? retentionShiftStartPhotosDays) =>
      _$this._retentionShiftStartPhotosDays = retentionShiftStartPhotosDays;

  num? _retentionPickupPhotosDays;
  num? get retentionPickupPhotosDays => _$this._retentionPickupPhotosDays;
  set retentionPickupPhotosDays(num? retentionPickupPhotosDays) =>
      _$this._retentionPickupPhotosDays = retentionPickupPhotosDays;

  num? _retentionDeliveryPhotosDays;
  num? get retentionDeliveryPhotosDays => _$this._retentionDeliveryPhotosDays;
  set retentionDeliveryPhotosDays(num? retentionDeliveryPhotosDays) =>
      _$this._retentionDeliveryPhotosDays = retentionDeliveryPhotosDays;

  num? _retentionWalletTransactionsDays;
  num? get retentionWalletTransactionsDays =>
      _$this._retentionWalletTransactionsDays;
  set retentionWalletTransactionsDays(num? retentionWalletTransactionsDays) =>
      _$this._retentionWalletTransactionsDays = retentionWalletTransactionsDays;

  num? _retentionStatisticsDays;
  num? get retentionStatisticsDays => _$this._retentionStatisticsDays;
  set retentionStatisticsDays(num? retentionStatisticsDays) =>
      _$this._retentionStatisticsDays = retentionStatisticsDays;

  num? _maxKmForBicycle;
  num? get maxKmForBicycle => _$this._maxKmForBicycle;
  set maxKmForBicycle(num? maxKmForBicycle) =>
      _$this._maxKmForBicycle = maxKmForBicycle;

  num? _coinValue;
  num? get coinValue => _$this._coinValue;
  set coinValue(num? coinValue) => _$this._coinValue = coinValue;

  num? _amountSpentPerCoin;
  num? get amountSpentPerCoin => _$this._amountSpentPerCoin;
  set amountSpentPerCoin(num? amountSpentPerCoin) =>
      _$this._amountSpentPerCoin = amountSpentPerCoin;

  num? _minCoinsToUse;
  num? get minCoinsToUse => _$this._minCoinsToUse;
  set minCoinsToUse(num? minCoinsToUse) =>
      _$this._minCoinsToUse = minCoinsToUse;

  bool? _driverBonusActive;
  bool? get driverBonusActive => _$this._driverBonusActive;
  set driverBonusActive(bool? driverBonusActive) =>
      _$this._driverBonusActive = driverBonusActive;

  num? _driverBonusAmount;
  num? get driverBonusAmount => _$this._driverBonusAmount;
  set driverBonusAmount(num? driverBonusAmount) =>
      _$this._driverBonusAmount = driverBonusAmount;

  DateTime? _driverBonusStartDate;
  DateTime? get driverBonusStartDate => _$this._driverBonusStartDate;
  set driverBonusStartDate(DateTime? driverBonusStartDate) =>
      _$this._driverBonusStartDate = driverBonusStartDate;

  DateTime? _driverBonusEndDate;
  DateTime? get driverBonusEndDate => _$this._driverBonusEndDate;
  set driverBonusEndDate(DateTime? driverBonusEndDate) =>
      _$this._driverBonusEndDate = driverBonusEndDate;

  bool? _driverBonusPaidByCustomer;
  bool? get driverBonusPaidByCustomer => _$this._driverBonusPaidByCustomer;
  set driverBonusPaidByCustomer(bool? driverBonusPaidByCustomer) =>
      _$this._driverBonusPaidByCustomer = driverBonusPaidByCustomer;

  num? _highValueOrderThreshold;
  num? get highValueOrderThreshold => _$this._highValueOrderThreshold;
  set highValueOrderThreshold(num? highValueOrderThreshold) =>
      _$this._highValueOrderThreshold = highValueOrderThreshold;

  num? _highValueUpfrontRate;
  num? get highValueUpfrontRate => _$this._highValueUpfrontRate;
  set highValueUpfrontRate(num? highValueUpfrontRate) =>
      _$this._highValueUpfrontRate = highValueUpfrontRate;

  bool? _driverShiftsEnabled;
  bool? get driverShiftsEnabled => _$this._driverShiftsEnabled;
  set driverShiftsEnabled(bool? driverShiftsEnabled) =>
      _$this._driverShiftsEnabled = driverShiftsEnabled;

  bool? _breaksEnabled;
  bool? get breaksEnabled => _$this._breaksEnabled;
  set breaksEnabled(bool? breaksEnabled) =>
      _$this._breaksEnabled = breaksEnabled;

  num? _bronzeTierBonusPerKm;
  num? get bronzeTierBonusPerKm => _$this._bronzeTierBonusPerKm;
  set bronzeTierBonusPerKm(num? bronzeTierBonusPerKm) =>
      _$this._bronzeTierBonusPerKm = bronzeTierBonusPerKm;

  num? _silverTierBonusPerKm;
  num? get silverTierBonusPerKm => _$this._silverTierBonusPerKm;
  set silverTierBonusPerKm(num? silverTierBonusPerKm) =>
      _$this._silverTierBonusPerKm = silverTierBonusPerKm;

  num? _goldTierBonusPerKm;
  num? get goldTierBonusPerKm => _$this._goldTierBonusPerKm;
  set goldTierBonusPerKm(num? goldTierBonusPerKm) =>
      _$this._goldTierBonusPerKm = goldTierBonusPerKm;

  num? _driverSettlementOrderThreshold;
  num? get driverSettlementOrderThreshold =>
      _$this._driverSettlementOrderThreshold;
  set driverSettlementOrderThreshold(num? driverSettlementOrderThreshold) =>
      _$this._driverSettlementOrderThreshold = driverSettlementOrderThreshold;

  num? _maxBreakMinutesPerShift;
  num? get maxBreakMinutesPerShift => _$this._maxBreakMinutesPerShift;
  set maxBreakMinutesPerShift(num? maxBreakMinutesPerShift) =>
      _$this._maxBreakMinutesPerShift = maxBreakMinutesPerShift;

  num? _maxBreaksPerShift;
  num? get maxBreaksPerShift => _$this._maxBreaksPerShift;
  set maxBreaksPerShift(num? maxBreaksPerShift) =>
      _$this._maxBreaksPerShift = maxBreaksPerShift;

  num? _maxSingleBreakMinutes;
  num? get maxSingleBreakMinutes => _$this._maxSingleBreakMinutes;
  set maxSingleBreakMinutes(num? maxSingleBreakMinutes) =>
      _$this._maxSingleBreakMinutes = maxSingleBreakMinutes;

  num? _pendingBreakExpiryMins;
  num? get pendingBreakExpiryMins => _$this._pendingBreakExpiryMins;
  set pendingBreakExpiryMins(num? pendingBreakExpiryMins) =>
      _$this._pendingBreakExpiryMins = pendingBreakExpiryMins;

  UpdatePlatformSettingsDtoBuilder() {
    UpdatePlatformSettingsDto._defaults(this);
  }

  UpdatePlatformSettingsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currency = $v.currency;
      _defaultCommissionRate = $v.defaultCommissionRate;
      _deliveryCommissionRate = $v.deliveryCommissionRate;
      _driverManagerCommissionRate = $v.driverManagerCommissionRate;
      _customOrderPlatformFee = $v.customOrderPlatformFee;
      _defaultTaxRate = $v.defaultTaxRate;
      _minOrderAmount = $v.minOrderAmount;
      _baseDeliveryFee = $v.baseDeliveryFee;
      _extraVendorDeliveryFee = $v.extraVendorDeliveryFee;
      _pricePerKm = $v.pricePerKm;
      _pricePerKmBicycle = $v.pricePerKmBicycle;
      _pricePerKmMotorcycle = $v.pricePerKmMotorcycle;
      _pricePerKmCar = $v.pricePerKmCar;
      _pricePerKmVan = $v.pricePerKmVan;
      _pricePerKmTruck = $v.pricePerKmTruck;
      _pricePerKmMotorTricycle = $v.pricePerKmMotorTricycle;
      _maxDeliveryFee = $v.maxDeliveryFee;
      _minDeliveryFee = $v.minDeliveryFee;
      _minDeliveryFeeBicycle = $v.minDeliveryFeeBicycle;
      _maxDeliveryFeeBicycle = $v.maxDeliveryFeeBicycle;
      _minDeliveryFeeMotorcycle = $v.minDeliveryFeeMotorcycle;
      _maxDeliveryFeeMotorcycle = $v.maxDeliveryFeeMotorcycle;
      _minDeliveryFeeCar = $v.minDeliveryFeeCar;
      _maxDeliveryFeeCar = $v.maxDeliveryFeeCar;
      _minDeliveryFeeVan = $v.minDeliveryFeeVan;
      _maxDeliveryFeeVan = $v.maxDeliveryFeeVan;
      _minDeliveryFeeTruck = $v.minDeliveryFeeTruck;
      _maxDeliveryFeeTruck = $v.maxDeliveryFeeTruck;
      _minDeliveryFeeMotorTricycle = $v.minDeliveryFeeMotorTricycle;
      _maxDeliveryFeeMotorTricycle = $v.maxDeliveryFeeMotorTricycle;
      _allowBicycle = $v.allowBicycle;
      _allowMotorcycle = $v.allowMotorcycle;
      _allowCar = $v.allowCar;
      _allowVan = $v.allowVan;
      _allowTruck = $v.allowTruck;
      _allowMotorTricycle = $v.allowMotorTricycle;
      _minOrderKm = $v.minOrderKm;
      _minDistanceFixedPrice = $v.minDistanceFixedPrice;
      _maxDeliveryRadiusKm = $v.maxDeliveryRadiusKm;
      _driverSearchRadiusKm = $v.driverSearchRadiusKm;
      _driverSearchRadiusStepKm = $v.driverSearchRadiusStepKm;
      _driverSearchRadiusMaxKm = $v.driverSearchRadiusMaxKm;
      _driverSearchMaxAttempts = $v.driverSearchMaxAttempts;
      _driverSearchGeoCandidateLimit = $v.driverSearchGeoCandidateLimit;
      _driverLocationFreshnessTtlSecs = $v.driverLocationFreshnessTtlSecs;
      _driverLocationPrecisionMeters = $v.driverLocationPrecisionMeters;
      _groupingMaxBranchDistanceKm = $v.groupingMaxBranchDistanceKm;
      _groupingMaxVendorCustomerDistanceKm =
          $v.groupingMaxVendorCustomerDistanceKm;
      _autoCancelPendingMins = $v.autoCancelPendingMins;
      _mobileWalletTimeoutMins = $v.mobileWalletTimeoutMins;
      _driverAcceptTimeoutSecs = $v.driverAcceptTimeoutSecs;
      _assistDecisionTimeoutSecs = $v.assistDecisionTimeoutSecs;
      _maxNegativeDriverBalance = $v.maxNegativeDriverBalance;
      _maxDispatchBatchSize = $v.maxDispatchBatchSize;
      _maxActiveOrdersPerDriver = $v.maxActiveOrdersPerDriver;
      _stackedOrderDriverPercentage = $v.stackedOrderDriverPercentage;
      _batchMaxVendorDistanceKm = $v.batchMaxVendorDistanceKm;
      _batchMaxCustomerDistanceKm = $v.batchMaxCustomerDistanceKm;
      _isMaintenanceMode = $v.isMaintenanceMode;
      _androidMinVersion = $v.androidMinVersion;
      _androidLatestVersion = $v.androidLatestVersion;
      _androidForceUpdate = $v.androidForceUpdate;
      _androidStoreUrl = $v.androidStoreUrl;
      _iosMinVersion = $v.iosMinVersion;
      _iosLatestVersion = $v.iosLatestVersion;
      _maxActiveOrdersPerCustomer = $v.maxActiveOrdersPerCustomer;
      _requirePriorDeliveryForMultipleOrders =
          $v.requirePriorDeliveryForMultipleOrders;
      _maxOtpAttempts = $v.maxOtpAttempts;
      _otpExpirySeconds = $v.otpExpirySeconds;
      _iosForceUpdate = $v.iosForceUpdate;
      _iosStoreUrl = $v.iosStoreUrl;
      _supportEmail = $v.supportEmail;
      _supportPhone = $v.supportPhone;
      _supportWhatsapp = $v.supportWhatsapp;
      _termsUrl = $v.termsUrl;
      _privacyUrl = $v.privacyUrl;
      _retentionOrdersDays = $v.retentionOrdersDays;
      _retentionArchivedChatsDays = $v.retentionArchivedChatsDays;
      _retentionNotificationsDays = $v.retentionNotificationsDays;
      _retentionExpiredSessionsDays = $v.retentionExpiredSessionsDays;
      _retentionAuditLogsDays = $v.retentionAuditLogsDays;
      _retentionAbandonedCartsDays = $v.retentionAbandonedCartsDays;
      _retentionPaymentReceiptsDays = $v.retentionPaymentReceiptsDays;
      _retentionShiftStartPhotosDays = $v.retentionShiftStartPhotosDays;
      _retentionPickupPhotosDays = $v.retentionPickupPhotosDays;
      _retentionDeliveryPhotosDays = $v.retentionDeliveryPhotosDays;
      _retentionWalletTransactionsDays = $v.retentionWalletTransactionsDays;
      _retentionStatisticsDays = $v.retentionStatisticsDays;
      _maxKmForBicycle = $v.maxKmForBicycle;
      _coinValue = $v.coinValue;
      _amountSpentPerCoin = $v.amountSpentPerCoin;
      _minCoinsToUse = $v.minCoinsToUse;
      _driverBonusActive = $v.driverBonusActive;
      _driverBonusAmount = $v.driverBonusAmount;
      _driverBonusStartDate = $v.driverBonusStartDate;
      _driverBonusEndDate = $v.driverBonusEndDate;
      _driverBonusPaidByCustomer = $v.driverBonusPaidByCustomer;
      _highValueOrderThreshold = $v.highValueOrderThreshold;
      _highValueUpfrontRate = $v.highValueUpfrontRate;
      _driverShiftsEnabled = $v.driverShiftsEnabled;
      _breaksEnabled = $v.breaksEnabled;
      _bronzeTierBonusPerKm = $v.bronzeTierBonusPerKm;
      _silverTierBonusPerKm = $v.silverTierBonusPerKm;
      _goldTierBonusPerKm = $v.goldTierBonusPerKm;
      _driverSettlementOrderThreshold = $v.driverSettlementOrderThreshold;
      _maxBreakMinutesPerShift = $v.maxBreakMinutesPerShift;
      _maxBreaksPerShift = $v.maxBreaksPerShift;
      _maxSingleBreakMinutes = $v.maxSingleBreakMinutes;
      _pendingBreakExpiryMins = $v.pendingBreakExpiryMins;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePlatformSettingsDto other) {
    _$v = other as _$UpdatePlatformSettingsDto;
  }

  @override
  void update(void Function(UpdatePlatformSettingsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePlatformSettingsDto build() => _build();

  _$UpdatePlatformSettingsDto _build() {
    final _$result =
        _$v ??
        _$UpdatePlatformSettingsDto._(
          currency: currency,
          defaultCommissionRate: defaultCommissionRate,
          deliveryCommissionRate: deliveryCommissionRate,
          driverManagerCommissionRate: driverManagerCommissionRate,
          customOrderPlatformFee: customOrderPlatformFee,
          defaultTaxRate: defaultTaxRate,
          minOrderAmount: minOrderAmount,
          baseDeliveryFee: baseDeliveryFee,
          extraVendorDeliveryFee: extraVendorDeliveryFee,
          pricePerKm: pricePerKm,
          pricePerKmBicycle: pricePerKmBicycle,
          pricePerKmMotorcycle: pricePerKmMotorcycle,
          pricePerKmCar: pricePerKmCar,
          pricePerKmVan: pricePerKmVan,
          pricePerKmTruck: pricePerKmTruck,
          pricePerKmMotorTricycle: pricePerKmMotorTricycle,
          maxDeliveryFee: maxDeliveryFee,
          minDeliveryFee: minDeliveryFee,
          minDeliveryFeeBicycle: minDeliveryFeeBicycle,
          maxDeliveryFeeBicycle: maxDeliveryFeeBicycle,
          minDeliveryFeeMotorcycle: minDeliveryFeeMotorcycle,
          maxDeliveryFeeMotorcycle: maxDeliveryFeeMotorcycle,
          minDeliveryFeeCar: minDeliveryFeeCar,
          maxDeliveryFeeCar: maxDeliveryFeeCar,
          minDeliveryFeeVan: minDeliveryFeeVan,
          maxDeliveryFeeVan: maxDeliveryFeeVan,
          minDeliveryFeeTruck: minDeliveryFeeTruck,
          maxDeliveryFeeTruck: maxDeliveryFeeTruck,
          minDeliveryFeeMotorTricycle: minDeliveryFeeMotorTricycle,
          maxDeliveryFeeMotorTricycle: maxDeliveryFeeMotorTricycle,
          allowBicycle: allowBicycle,
          allowMotorcycle: allowMotorcycle,
          allowCar: allowCar,
          allowVan: allowVan,
          allowTruck: allowTruck,
          allowMotorTricycle: allowMotorTricycle,
          minOrderKm: minOrderKm,
          minDistanceFixedPrice: minDistanceFixedPrice,
          maxDeliveryRadiusKm: maxDeliveryRadiusKm,
          driverSearchRadiusKm: driverSearchRadiusKm,
          driverSearchRadiusStepKm: driverSearchRadiusStepKm,
          driverSearchRadiusMaxKm: driverSearchRadiusMaxKm,
          driverSearchMaxAttempts: driverSearchMaxAttempts,
          driverSearchGeoCandidateLimit: driverSearchGeoCandidateLimit,
          driverLocationFreshnessTtlSecs: driverLocationFreshnessTtlSecs,
          driverLocationPrecisionMeters: driverLocationPrecisionMeters,
          groupingMaxBranchDistanceKm: groupingMaxBranchDistanceKm,
          groupingMaxVendorCustomerDistanceKm:
              groupingMaxVendorCustomerDistanceKm,
          autoCancelPendingMins: autoCancelPendingMins,
          mobileWalletTimeoutMins: mobileWalletTimeoutMins,
          driverAcceptTimeoutSecs: driverAcceptTimeoutSecs,
          assistDecisionTimeoutSecs: assistDecisionTimeoutSecs,
          maxNegativeDriverBalance: maxNegativeDriverBalance,
          maxDispatchBatchSize: maxDispatchBatchSize,
          maxActiveOrdersPerDriver: maxActiveOrdersPerDriver,
          stackedOrderDriverPercentage: stackedOrderDriverPercentage,
          batchMaxVendorDistanceKm: batchMaxVendorDistanceKm,
          batchMaxCustomerDistanceKm: batchMaxCustomerDistanceKm,
          isMaintenanceMode: isMaintenanceMode,
          androidMinVersion: androidMinVersion,
          androidLatestVersion: androidLatestVersion,
          androidForceUpdate: androidForceUpdate,
          androidStoreUrl: androidStoreUrl,
          iosMinVersion: iosMinVersion,
          iosLatestVersion: iosLatestVersion,
          maxActiveOrdersPerCustomer: maxActiveOrdersPerCustomer,
          requirePriorDeliveryForMultipleOrders:
              requirePriorDeliveryForMultipleOrders,
          maxOtpAttempts: maxOtpAttempts,
          otpExpirySeconds: otpExpirySeconds,
          iosForceUpdate: iosForceUpdate,
          iosStoreUrl: iosStoreUrl,
          supportEmail: supportEmail,
          supportPhone: supportPhone,
          supportWhatsapp: supportWhatsapp,
          termsUrl: termsUrl,
          privacyUrl: privacyUrl,
          retentionOrdersDays: retentionOrdersDays,
          retentionArchivedChatsDays: retentionArchivedChatsDays,
          retentionNotificationsDays: retentionNotificationsDays,
          retentionExpiredSessionsDays: retentionExpiredSessionsDays,
          retentionAuditLogsDays: retentionAuditLogsDays,
          retentionAbandonedCartsDays: retentionAbandonedCartsDays,
          retentionPaymentReceiptsDays: retentionPaymentReceiptsDays,
          retentionShiftStartPhotosDays: retentionShiftStartPhotosDays,
          retentionPickupPhotosDays: retentionPickupPhotosDays,
          retentionDeliveryPhotosDays: retentionDeliveryPhotosDays,
          retentionWalletTransactionsDays: retentionWalletTransactionsDays,
          retentionStatisticsDays: retentionStatisticsDays,
          maxKmForBicycle: maxKmForBicycle,
          coinValue: coinValue,
          amountSpentPerCoin: amountSpentPerCoin,
          minCoinsToUse: minCoinsToUse,
          driverBonusActive: driverBonusActive,
          driverBonusAmount: driverBonusAmount,
          driverBonusStartDate: driverBonusStartDate,
          driverBonusEndDate: driverBonusEndDate,
          driverBonusPaidByCustomer: driverBonusPaidByCustomer,
          highValueOrderThreshold: highValueOrderThreshold,
          highValueUpfrontRate: highValueUpfrontRate,
          driverShiftsEnabled: driverShiftsEnabled,
          breaksEnabled: breaksEnabled,
          bronzeTierBonusPerKm: bronzeTierBonusPerKm,
          silverTierBonusPerKm: silverTierBonusPerKm,
          goldTierBonusPerKm: goldTierBonusPerKm,
          driverSettlementOrderThreshold: driverSettlementOrderThreshold,
          maxBreakMinutesPerShift: maxBreakMinutesPerShift,
          maxBreaksPerShift: maxBreaksPerShift,
          maxSingleBreakMinutes: maxSingleBreakMinutes,
          pendingBreakExpiryMins: pendingBreakExpiryMins,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
