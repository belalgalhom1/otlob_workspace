//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'package:api/src/serializers.dart';
import 'package:api/src/auth/api_key_auth.dart';
import 'package:api/src/auth/basic_auth.dart';
import 'package:api/src/auth/bearer_auth.dart';
import 'package:api/src/auth/oauth.dart';
import 'package:api/src/api/audit_logs_api.dart';
import 'package:api/src/api/authentication_api.dart';
import 'package:api/src/api/cart_api.dart';
import 'package:api/src/api/chat_conversations_api.dart';
import 'package:api/src/api/chat_messages_api.dart';
import 'package:api/src/api/customers_api.dart';
import 'package:api/src/api/devices_push_notifications_api.dart';
import 'package:api/src/api/driver_shifts_api.dart';
import 'package:api/src/api/drivers_api.dart';
import 'package:api/src/api/health_system_api.dart';
import 'package:api/src/api/inbox_summary_counts_api.dart';
import 'package:api/src/api/logistics_zones_api.dart';
import 'package:api/src/api/notifications_api.dart';
import 'package:api/src/api/offers_api.dart';
import 'package:api/src/api/orders_api.dart';
import 'package:api/src/api/platform_settings_versioning_api.dart';
import 'package:api/src/api/promotions_api.dart';
import 'package:api/src/api/reviews_api.dart';
import 'package:api/src/api/statistics_api.dart';
import 'package:api/src/api/support_tickets_api.dart';
import 'package:api/src/api/users_api.dart';
import 'package:api/src/api/vendors_branches_api.dart';
import 'package:api/src/api/vendors_core_management_api.dart';
import 'package:api/src/api/vendors_members_team_api.dart';
import 'package:api/src/api/vendors_menu_categories_api.dart';
import 'package:api/src/api/vendors_products_api.dart';
import 'package:api/src/api/vendors_verticals_categories_api.dart';
import 'package:api/src/api/vendors_wallet_transactions_api.dart';
import 'package:api/src/api/wallet_financials_api.dart';

class Api {
  static const String basePath = r'http://localhost';

  final Dio dio;
  final Serializers serializers;

  Api({
    Dio? dio,
    Serializers? serializers,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : this.serializers = serializers ?? standardSerializers,
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  /// Removes the OAuth token associated with the given [name].
  ///
  /// If no [OAuthInterceptor] is registered or no token exists for the given
  /// [name], this method has no effect.
  void removeOAuthToken(String name) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens.remove(name);
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  /// Removes the bearer authentication token associated with the given [name].
  ///
  /// If no [BearerAuthInterceptor] is registered or no token exists for the
  /// given [name], this method has no effect.
  void removeBearerAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens.remove(name);
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  /// Removes the basic authentication credentials associated with the given [name].
  ///
  /// If no [BasicAuthInterceptor] is registered or no credentials exist for the
  /// given [name], this method has no effect.
  void removeBasicAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo.remove(name);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Removes the API key associated with the given [name].
  ///
  /// If no [ApiKeyAuthInterceptor] is registered or no API key exists for the
  /// given [name], this method has no effect.
  void removeApiKey(String name) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys.remove(name);
    }
  }

  /// Get AuditLogsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuditLogsApi getAuditLogsApi() {
    return AuditLogsApi(dio, serializers);
  }

  /// Get AuthenticationApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthenticationApi getAuthenticationApi() {
    return AuthenticationApi(dio, serializers);
  }

  /// Get CartApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CartApi getCartApi() {
    return CartApi(dio, serializers);
  }

  /// Get ChatConversationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChatConversationsApi getChatConversationsApi() {
    return ChatConversationsApi(dio, serializers);
  }

  /// Get ChatMessagesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChatMessagesApi getChatMessagesApi() {
    return ChatMessagesApi(dio, serializers);
  }

  /// Get CustomersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CustomersApi getCustomersApi() {
    return CustomersApi(dio, serializers);
  }

  /// Get DevicesPushNotificationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DevicesPushNotificationsApi getDevicesPushNotificationsApi() {
    return DevicesPushNotificationsApi(dio, serializers);
  }

  /// Get DriverShiftsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DriverShiftsApi getDriverShiftsApi() {
    return DriverShiftsApi(dio, serializers);
  }

  /// Get DriversApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DriversApi getDriversApi() {
    return DriversApi(dio, serializers);
  }

  /// Get HealthSystemApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  HealthSystemApi getHealthSystemApi() {
    return HealthSystemApi(dio);
  }

  /// Get InboxSummaryCountsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  InboxSummaryCountsApi getInboxSummaryCountsApi() {
    return InboxSummaryCountsApi(dio, serializers);
  }

  /// Get LogisticsZonesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  LogisticsZonesApi getLogisticsZonesApi() {
    return LogisticsZonesApi(dio, serializers);
  }

  /// Get NotificationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  NotificationsApi getNotificationsApi() {
    return NotificationsApi(dio, serializers);
  }

  /// Get OffersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  OffersApi getOffersApi() {
    return OffersApi(dio, serializers);
  }

  /// Get OrdersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  OrdersApi getOrdersApi() {
    return OrdersApi(dio, serializers);
  }

  /// Get PlatformSettingsVersioningApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PlatformSettingsVersioningApi getPlatformSettingsVersioningApi() {
    return PlatformSettingsVersioningApi(dio, serializers);
  }

  /// Get PromotionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PromotionsApi getPromotionsApi() {
    return PromotionsApi(dio, serializers);
  }

  /// Get ReviewsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ReviewsApi getReviewsApi() {
    return ReviewsApi(dio, serializers);
  }

  /// Get StatisticsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  StatisticsApi getStatisticsApi() {
    return StatisticsApi(dio, serializers);
  }

  /// Get SupportTicketsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SupportTicketsApi getSupportTicketsApi() {
    return SupportTicketsApi(dio, serializers);
  }

  /// Get UsersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UsersApi getUsersApi() {
    return UsersApi(dio, serializers);
  }

  /// Get VendorsBranchesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsBranchesApi getVendorsBranchesApi() {
    return VendorsBranchesApi(dio, serializers);
  }

  /// Get VendorsCoreManagementApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsCoreManagementApi getVendorsCoreManagementApi() {
    return VendorsCoreManagementApi(dio, serializers);
  }

  /// Get VendorsMembersTeamApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsMembersTeamApi getVendorsMembersTeamApi() {
    return VendorsMembersTeamApi(dio, serializers);
  }

  /// Get VendorsMenuCategoriesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsMenuCategoriesApi getVendorsMenuCategoriesApi() {
    return VendorsMenuCategoriesApi(dio, serializers);
  }

  /// Get VendorsProductsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsProductsApi getVendorsProductsApi() {
    return VendorsProductsApi(dio, serializers);
  }

  /// Get VendorsVerticalsCategoriesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsVerticalsCategoriesApi getVendorsVerticalsCategoriesApi() {
    return VendorsVerticalsCategoriesApi(dio, serializers);
  }

  /// Get VendorsWalletTransactionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VendorsWalletTransactionsApi getVendorsWalletTransactionsApi() {
    return VendorsWalletTransactionsApi(dio, serializers);
  }

  /// Get WalletFinancialsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WalletFinancialsApi getWalletFinancialsApi() {
    return WalletFinancialsApi(dio, serializers);
  }
}
