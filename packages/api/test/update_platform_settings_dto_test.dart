import 'package:test/test.dart';
import 'package:api/api.dart';

// tests for UpdatePlatformSettingsDto
void main() {
  final instance = UpdatePlatformSettingsDtoBuilder();
  // TODO add properties to the builder and call build()

  group(UpdatePlatformSettingsDto, () {
    // String currency
    test('to test the property `currency`', () async {
      // TODO
    });

    // num defaultCommissionRate
    test('to test the property `defaultCommissionRate`', () async {
      // TODO
    });

    // num deliveryCommissionRate
    test('to test the property `deliveryCommissionRate`', () async {
      // TODO
    });

    // num customOrderPlatformFee
    test('to test the property `customOrderPlatformFee`', () async {
      // TODO
    });

    // num defaultTaxRate
    test('to test the property `defaultTaxRate`', () async {
      // TODO
    });

    // num minOrderAmount
    test('to test the property `minOrderAmount`', () async {
      // TODO
    });

    // num baseDeliveryFee
    test('to test the property `baseDeliveryFee`', () async {
      // TODO
    });

    // num pricePerKm
    test('to test the property `pricePerKm`', () async {
      // TODO
    });

    // num maxDeliveryRadiusKm
    test('to test the property `maxDeliveryRadiusKm`', () async {
      // TODO
    });

    // num driverSearchRadiusKm
    test('to test the property `driverSearchRadiusKm`', () async {
      // TODO
    });

    // num driverSearchRadiusStepKm
    test('to test the property `driverSearchRadiusStepKm`', () async {
      // TODO
    });

    // num driverSearchRadiusMaxKm
    test('to test the property `driverSearchRadiusMaxKm`', () async {
      // TODO
    });

    // num driverSearchMaxAttempts
    test('to test the property `driverSearchMaxAttempts`', () async {
      // TODO
    });

    // num fallbackOrderDistanceKm
    test('to test the property `fallbackOrderDistanceKm`', () async {
      // TODO
    });

    // num driverAcceptTimeoutSecs
    test('to test the property `driverAcceptTimeoutSecs`', () async {
      // TODO
    });

    // num maxDispatchBatchSize
    test('to test the property `maxDispatchBatchSize`', () async {
      // TODO
    });

    // bool isMaintenanceMode
    test('to test the property `isMaintenanceMode`', () async {
      // TODO
    });

    // String androidMinVersion
    test('to test the property `androidMinVersion`', () async {
      // TODO
    });

    // String androidLatestVersion
    test('to test the property `androidLatestVersion`', () async {
      // TODO
    });

    // bool androidForceUpdate
    test('to test the property `androidForceUpdate`', () async {
      // TODO
    });

    // String androidStoreUrl
    test('to test the property `androidStoreUrl`', () async {
      // TODO
    });

    // String iosMinVersion
    test('to test the property `iosMinVersion`', () async {
      // TODO
    });

    // String iosLatestVersion
    test('to test the property `iosLatestVersion`', () async {
      // TODO
    });

    // bool iosForceUpdate
    test('to test the property `iosForceUpdate`', () async {
      // TODO
    });

    // String iosStoreUrl
    test('to test the property `iosStoreUrl`', () async {
      // TODO
    });

    // String supportEmail
    test('to test the property `supportEmail`', () async {
      // TODO
    });

    // String supportPhone
    test('to test the property `supportPhone`', () async {
      // TODO
    });

    // String supportWhatsapp
    test('to test the property `supportWhatsapp`', () async {
      // TODO
    });

    // String termsUrl
    test('to test the property `termsUrl`', () async {
      // TODO
    });

    // String privacyUrl
    test('to test the property `privacyUrl`', () async {
      // TODO
    });

    // Days before all old orders are hard-deleted
    // num retentionOrdersDays
    test('to test the property `retentionOrdersDays`', () async {
      // TODO
    });

    // Days before archived conversations are hard-deleted
    // num retentionArchivedChatsDays
    test('to test the property `retentionArchivedChatsDays`', () async {
      // TODO
    });

    // Days before old notifications are hard-deleted
    // num retentionNotificationsDays
    test('to test the property `retentionNotificationsDays`', () async {
      // TODO
    });

    // Days after expiry before sessions are hard-deleted
    // num retentionExpiredSessionsDays
    test('to test the property `retentionExpiredSessionsDays`', () async {
      // TODO
    });

    // Days before audit logs are hard-deleted
    // num retentionAuditLogsDays
    test('to test the property `retentionAuditLogsDays`', () async {
      // TODO
    });

    // Days before abandoned carts are hard-deleted
    // num retentionAbandonedCartsDays
    test('to test the property `retentionAbandonedCartsDays`', () async {
      // TODO
    });

    // Days before wallet transactions are hard-deleted
    // num retentionWalletTransactionsDays
    test('to test the property `retentionWalletTransactionsDays`', () async {
      // TODO
    });

    // Days before statistics records are hard-deleted
    // num retentionStatisticsDays
    test('to test the property `retentionStatisticsDays`', () async {
      // TODO
    });

    // Max distance for bicycle dispatch
    // num maxKmForBicycle
    test('to test the property `maxKmForBicycle`', () async {
      // TODO
    });

    // Value of 1 coin (e.g. 1 = 1 EGP)
    // num coinValue
    test('to test the property `coinValue`', () async {
      // TODO
    });

    // Amount spent to earn 1 coin (e.g. 10 = 10 EGP)
    // num amountSpentPerCoin
    test('to test the property `amountSpentPerCoin`', () async {
      // TODO
    });

    // Minimum coins required to use for partial payment
    // num minCoinsToUse
    test('to test the property `minCoinsToUse`', () async {
      // TODO
    });

    // Master switch for driver bonus
    // bool driverBonusActive
    test('to test the property `driverBonusActive`', () async {
      // TODO
    });

    // Bonus amount (e.g. 5 = 5 EGP)
    // num driverBonusAmount
    test('to test the property `driverBonusAmount`', () async {
      // TODO
    });

    // Start date of the bonus period
    // DateTime driverBonusStartDate
    test('to test the property `driverBonusStartDate`', () async {
      // TODO
    });

    // End date of the bonus period
    // DateTime driverBonusEndDate
    test('to test the property `driverBonusEndDate`', () async {
      // TODO
    });

    // If true, customer pays the bonus as a fee. If false, platform pays.
    // bool driverBonusPaidByCustomer
    test('to test the property `driverBonusPaidByCustomer`', () async {
      // TODO
    });

    // Threshold for high value orders (e.g. 2000 = 2000 EGP). 0 to disable.
    // num highValueOrderThreshold
    test('to test the property `highValueOrderThreshold`', () async {
      // TODO
    });

    // Upfront percentage rate for high value cash orders (e.g. 20 = 20%)
    // num highValueUpfrontRate
    test('to test the property `highValueUpfrontRate`', () async {
      // TODO
    });

    // Master switch for driver shifts feature
    // bool driverShiftsEnabled
    test('to test the property `driverShiftsEnabled`', () async {
      // TODO
    });

    // Per-km bonus for Bronze tier drivers
    // num bronzeTierBonusPerKm
    test('to test the property `bronzeTierBonusPerKm`', () async {
      // TODO
    });

    // Per-km bonus for Silver tier drivers
    // num silverTierBonusPerKm
    test('to test the property `silverTierBonusPerKm`', () async {
      // TODO
    });

    // Per-km bonus for Gold tier drivers (Used at checkout)
    // num goldTierBonusPerKm
    test('to test the property `goldTierBonusPerKm`', () async {
      // TODO
    });

  });
}
