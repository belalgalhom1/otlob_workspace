import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'data.dart';
export 'src/providers/shared_chat_provider.dart';
export 'src/providers/shared_inbox_provider.dart';
export 'src/providers/shared_notification_settings_provider.dart';
export 'src/providers/shared_inbox_counts_provider.dart';

final adminAuditLogsRepositoryProvider = Provider<AdminAuditLogsRepository>((ref) => AdminAuditLogsRepository(ref.watch(apiClientProvider).getAuditLogsApi()));
final adminCustomersRepositoryProvider = Provider<AdminCustomersRepository>((ref) => AdminCustomersRepository(ref.watch(apiClientProvider).getCustomersApi()));
final adminDriverShiftsRepositoryProvider = Provider<AdminDriverShiftsRepository>((ref) => AdminDriverShiftsRepository(ref.watch(apiClientProvider).getDriverShiftsApi()));
final adminDriversRepositoryProvider = Provider<AdminDriversRepository>((ref) => AdminDriversRepository(ref.watch(apiClientProvider).getDriversApi(), ref.watch(apiClientProvider).getOrdersApi(), ref.watch(apiClientProvider).getDriverShiftsApi(), dio: ref.watch(dioProvider)));
final adminOffersRepositoryProvider = Provider<AdminOffersRepository>((ref) => AdminOffersRepository(ref.watch(apiClientProvider).getOffersApi()));
final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>((ref) => AdminOrdersRepository(ref.watch(apiClientProvider).getOrdersApi()));
final adminPlatformSettingsRepositoryProvider = Provider<AdminPlatformSettingsRepository>((ref) => AdminPlatformSettingsRepository(ref.watch(apiClientProvider).getPlatformSettingsVersioningApi(), dio: ref.watch(dioProvider)));
final adminStatisticsRepositoryProvider = Provider<AdminStatisticsRepository>((ref) => AdminStatisticsRepository(ref.watch(apiClientProvider).getStatisticsApi(), dio: ref.watch(dioProvider)));
final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) => AdminUsersRepository(ref.watch(apiClientProvider).getUsersApi()));
final adminVendorBranchesRepositoryProvider = Provider<AdminVendorBranchesRepository>((ref) => AdminVendorBranchesRepository(ref.watch(apiClientProvider).getVendorsBranchesApi()));

final adminVendorsRepositoryProvider = Provider<AdminVendorsRepository>((ref) => AdminVendorsRepository(
  ref.watch(apiClientProvider).getVendorsCoreManagementApi(),
  ref.watch(apiClientProvider).getVendorsProductsApi(),
  ref.watch(apiClientProvider).getVendorsMenuCategoriesApi(),
  ref.watch(apiClientProvider).getVendorsBranchesApi(),
  ref.watch(apiClientProvider).getPromotionsApi(),
  ref.watch(apiClientProvider).dio,
));
final adminVendorWalletRepositoryProvider = Provider<AdminVendorWalletRepository>((ref) => AdminVendorWalletRepository(ref.watch(apiClientProvider).getVendorsWalletTransactionsApi()));
final adminVerticalsRepositoryProvider = Provider<AdminVerticalsRepository>((ref) => AdminVerticalsRepository(ref.watch(apiClientProvider).getVendorsVerticalsCategoriesApi()));
final adminWalletRepositoryProvider = Provider<AdminWalletRepository>((ref) => AdminWalletRepository(ref.watch(apiClientProvider).getWalletFinancialsApi()));
final adminZonesRepositoryProvider = Provider<AdminZonesRepository>((ref) => AdminZonesRepository(ref.watch(apiClientProvider).getLogisticsZonesApi(), dio: ref.watch(dioProvider)));
final customerAddressesRepositoryProvider = Provider<CustomerAddressesRepository>((ref) => CustomerAddressesRepository(ref.watch(apiClientProvider).getCustomersApi()));
final customerCartRepositoryProvider = Provider<CustomerCartRepository>((ref) => CustomerCartRepository(ref.watch(apiClientProvider).getCartApi()));
final customerFavoritesRepositoryProvider = Provider<CustomerFavoritesRepository>((ref) => CustomerFavoritesRepository(ref.watch(apiClientProvider).getCustomersApi()));
final customerLoyaltyRepositoryProvider = Provider<CustomerLoyaltyRepository>((ref) => CustomerLoyaltyRepository(ref.watch(apiClientProvider).getCustomersApi()));
final customerOffersRepositoryProvider = Provider<CustomerOffersRepository>((ref) => CustomerOffersRepository(ref.watch(apiClientProvider).getOffersApi()));
final customerOrderRepositoryProvider = Provider<CustomerOrderRepository>((ref) => CustomerOrderRepository(ref.watch(apiClientProvider).getOrdersApi(), ref.watch(apiClientProvider).getReviewsApi(), dio: ref.watch(dioProvider)));
final customerPromotionsRepositoryProvider = Provider<CustomerPromotionsRepository>((ref) => CustomerPromotionsRepository(ref.watch(apiClientProvider).getPromotionsApi()));
final customerVendorsRepositoryProvider = Provider<CustomerVendorsRepository>((ref) => CustomerVendorsRepository(ref.watch(apiClientProvider).getVendorsCoreManagementApi()));
final customerZonesRepositoryProvider = Provider<CustomerZonesRepository>((ref) => CustomerZonesRepository(ref.watch(apiClientProvider).getLogisticsZonesApi()));
final driverBreaksRepositoryProvider = Provider<DriverBreaksRepository>((ref) => DriverBreaksRepository(dio: ref.watch(dioProvider)));
final driverDispatchRepositoryProvider = Provider<DriverDispatchRepository>((ref) => DriverDispatchRepository(ref.watch(apiClientProvider).getOrdersApi()));
final driverOrdersRepositoryProvider = Provider<DriverOrdersRepository>((ref) => DriverOrdersRepository(ref.watch(apiClientProvider).getOrdersApi()));
final driverProfileRepositoryProvider = Provider<DriverProfileRepository>((ref) => DriverProfileRepository(ref.watch(apiClientProvider).getDriversApi()));
final driverShiftsRepositoryProvider = Provider<DriverShiftsRepository>((ref) => DriverShiftsRepository(ref.watch(apiClientProvider).getDriverShiftsApi(), ref.watch(apiClientProvider).getDriversApi(), dio: ref.watch(dioProvider)));
final driverStatisticsRepositoryProvider = Provider<DriverStatisticsRepository>((ref) => DriverStatisticsRepository(ref.watch(apiClientProvider).getStatisticsApi(), dio: ref.watch(dioProvider)));
final driverWalletRepositoryProvider = Provider<DriverWalletRepository>((ref) => DriverWalletRepository(ref.watch(apiClientProvider).getWalletFinancialsApi(), ref.watch(apiClientProvider).getDriversApi()));
final sharedAuthRepositoryProvider = Provider<SharedAuthRepository>((ref) => SharedAuthRepository(ref.watch(apiClientProvider).getAuthenticationApi(), ref.watch(tokenServiceProvider)));
final sharedChatRepositoryProvider = Provider<SharedChatRepository>((ref) => SharedChatRepository(ref.watch(apiClientProvider).getChatConversationsApi(), ref.watch(apiClientProvider).getChatMessagesApi(), ref.watch(apiClientProvider).dio));
final sharedDevicesRepositoryProvider = Provider<SharedDevicesRepository>((ref) => SharedDevicesRepository(ref.watch(apiClientProvider).getDevicesPushNotificationsApi()));
final sharedHealthRepositoryProvider = Provider<SharedHealthRepository>((ref) => SharedHealthRepository(ref.watch(apiClientProvider).getHealthSystemApi()));
final sharedInboxRepositoryProvider = Provider<SharedInboxRepository>((ref) => SharedInboxRepository(ref.watch(apiClientProvider).getInboxSummaryCountsApi()));
final sharedNotificationsRepositoryProvider = Provider<SharedNotificationsRepository>((ref) => SharedNotificationsRepository(ref.watch(apiClientProvider).getNotificationsApi()));

final sharedPlatformSettingsRepositoryProvider = Provider<SharedPlatformSettingsRepository>((ref) => SharedPlatformSettingsRepository(ref.watch(apiClientProvider).getPlatformSettingsVersioningApi()));
final sharedSupportTicketsRepositoryProvider = Provider<SharedTicketsRepository>((ref) => SharedTicketsRepository(ref.watch(apiClientProvider).getSupportTicketsApi()));
final sharedTicketsRepositoryProvider = sharedSupportTicketsRepositoryProvider;
final sharedUserRepositoryProvider = Provider<SharedUserRepository>((ref) => SharedUserRepository(ref.watch(apiClientProvider).getUsersApi()));
final sharedVerticalsRepositoryProvider = Provider<SharedVerticalsRepository>((ref) => SharedVerticalsRepository(ref.watch(apiClientProvider).getVendorsVerticalsCategoriesApi()));
final sharedWalletRepositoryProvider = Provider<SharedWalletRepository>((ref) => SharedWalletRepository(ref.watch(apiClientProvider).getWalletFinancialsApi()));
final zonesRepositoryProvider = adminZonesRepositoryProvider; // Alias for zonesRepositoryProvider used in UI
final vendorBranchesRepositoryProvider = Provider<VendorBranchesRepository>((ref) => VendorBranchesRepository(ref.watch(apiClientProvider).getVendorsBranchesApi()));
final vendorCatalogRepositoryProvider = Provider<VendorCatalogRepository>((ref) => VendorCatalogRepository(ref.watch(apiClientProvider).getVendorsProductsApi()));
final vendorCategoriesRepositoryProvider = Provider<VendorCategoriesRepository>((ref) => VendorCategoriesRepository(ref.watch(apiClientProvider).getVendorsMenuCategoriesApi()));
final vendorMembersRepositoryProvider = Provider<VendorMembersRepository>((ref) => VendorMembersRepository(ref.watch(apiClientProvider).getVendorsMembersTeamApi()));
final vendorOrdersRepositoryProvider = Provider<VendorOrdersRepository>((ref) => VendorOrdersRepository(ref.watch(apiClientProvider).getOrdersApi()));
final vendorProfileRepositoryProvider = Provider<VendorProfileRepository>((ref) => VendorProfileRepository(ref.watch(apiClientProvider).getVendorsCoreManagementApi()));
final vendorPromotionsRepositoryProvider = Provider<VendorPromotionsRepository>((ref) => VendorPromotionsRepository(ref.watch(apiClientProvider).getPromotionsApi()));
final vendorStatisticsRepositoryProvider = Provider<VendorStatisticsRepository>((ref) => VendorStatisticsRepository(ref.watch(apiClientProvider).getStatisticsApi(), dio: ref.watch(dioProvider)));
final vendorWalletRepositoryProvider = Provider<VendorWalletRepository>((ref) => VendorWalletRepository(ref.watch(apiClientProvider).getVendorsWalletTransactionsApi(), ref.watch(apiClientProvider).getWalletFinancialsApi()));

