import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:api/api.dart';
import 'core_providers.dart';

final authenticationApiProvider = Provider<AuthenticationApi>((ref) => ref.watch(apiClientProvider).getAuthenticationApi());
final customersApiProvider = Provider<CustomersApi>((ref) => ref.watch(apiClientProvider).getCustomersApi());
final ordersApiProvider = Provider<OrdersApi>((ref) => ref.watch(apiClientProvider).getOrdersApi());
final driversApiProvider = Provider<DriversApi>((ref) => ref.watch(apiClientProvider).getDriversApi());
final driverShiftsApiProvider = Provider<DriverShiftsApi>((ref) => ref.watch(apiClientProvider).getDriverShiftsApi());
final vendorsProductsApiProvider = Provider<VendorsProductsApi>((ref) => ref.watch(apiClientProvider).getVendorsProductsApi());
final vendorsCoreManagementApiProvider = Provider<VendorsCoreManagementApi>((ref) => ref.watch(apiClientProvider).getVendorsCoreManagementApi());
final devicesPushNotificationsApiProvider = Provider<DevicesPushNotificationsApi>((ref) => ref.watch(apiClientProvider).getDevicesPushNotificationsApi());
final cartApiProvider = Provider<CartApi>((ref) => ref.watch(apiClientProvider).getCartApi());
final offersApiProvider = Provider<OffersApi>((ref) => ref.watch(apiClientProvider).getOffersApi());
final vendorsVerticalsCategoriesApiProvider = Provider<VendorsVerticalsCategoriesApi>((ref) => ref.watch(apiClientProvider).getVendorsVerticalsCategoriesApi());
final vendorsMenuCategoriesApiProvider = Provider<VendorsMenuCategoriesApi>((ref) => ref.watch(apiClientProvider).getVendorsMenuCategoriesApi());
final logisticsZonesApiProvider = Provider<LogisticsZonesApi>((ref) => ref.watch(apiClientProvider).getLogisticsZonesApi());
final usersApiProvider = Provider<UsersApi>((ref) => ref.watch(apiClientProvider).getUsersApi());
final notificationsApiProvider = Provider<NotificationsApi>((ref) => ref.watch(apiClientProvider).getNotificationsApi());

