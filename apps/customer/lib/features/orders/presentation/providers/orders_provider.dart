import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart' hide CartItem;
import 'package:built_collection/built_collection.dart';
import 'package:core/core.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

part 'orders_provider.g.dart';

final _keyRandom = Random.secure();

/// Generates a random UUID (v4) used as the Idempotency-Key for order
/// creation. The key is created once per checkout intent and re-sent unchanged
/// on retries so the server can deduplicate a double-tap or a repeated request.
String generateClientOrderKey() {
  final bytes = List<int>.generate(16, (_) => _keyRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class OrdersState {
  final List<Map<String, dynamic>> activeOrders;
  final List<Map<String, dynamic>> pastOrders;
  final bool isLoading;
  final bool isLoadingMoreActive;
  final bool isLoadingMorePast;
  final int activePage;
  final int pastPage;
  final bool hasMoreActive;
  final bool hasMorePast;
  final String? error;

  OrdersState({
    this.activeOrders = const <Map<String, dynamic>>[],
    this.pastOrders = const <Map<String, dynamic>>[],
    this.isLoading = true,
    this.isLoadingMoreActive = false,
    this.isLoadingMorePast = false,
    this.activePage = 1,
    this.pastPage = 1,
    this.hasMoreActive = true,
    this.hasMorePast = true,
    this.error,
  });

  OrdersState copyWith({
    List<Map<String, dynamic>>? activeOrders,
    List<Map<String, dynamic>>? pastOrders,
    bool? isLoading,
    bool? isLoadingMoreActive,
    bool? isLoadingMorePast,
    int? activePage,
    int? pastPage,
    bool? hasMoreActive,
    bool? hasMorePast,
    String? error,
  }) {
    return OrdersState(
      activeOrders: activeOrders ?? this.activeOrders,
      pastOrders: pastOrders ?? this.pastOrders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMoreActive: isLoadingMoreActive ?? this.isLoadingMoreActive,
      isLoadingMorePast: isLoadingMorePast ?? this.isLoadingMorePast,
      activePage: activePage ?? this.activePage,
      pastPage: pastPage ?? this.pastPage,
      hasMoreActive: hasMoreActive ?? this.hasMoreActive,
      hasMorePast: hasMorePast ?? this.hasMorePast,
      error: error ?? this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class Orders extends _$Orders {
  static const int _limit = 10;

  @override
  OrdersState build() {
    Future.microtask(() => _initFetch());
    return OrdersState(isLoading: true);
  }

  Future<void> _initFetch() async {
    state = state.copyWith(isLoading: true, error: null, activePage: 1, pastPage: 1);
    try {
      final activeResult = await _fetchFromApi(page: 1, limit: _limit, isActive: true);
      final pastResult = await _fetchFromApi(page: 1, limit: _limit, isActive: false);
      
      state = state.copyWith(
        activeOrders: activeResult.orders,
        pastOrders: pastResult.orders,
        isLoading: false,
        hasMoreActive: activeResult.hasMore,
        hasMorePast: pastResult.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  static const _activeStatuses = {
    'PENDING', 'ACCEPTED', 'PREPARING',
    'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT',
    'READY_FOR_PICKUP', 'PICKED_UP',
  };

  static const _pastStatuses = {'DELIVERED', 'CANCELLED'};

  Future<({List<Map<String, dynamic>> orders, bool hasMore})> _fetchFromApi({
    required int page,
    required int limit,
    required bool isActive,
  }) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      final allOrders = await repo.getMyOrders(page: page, limit: limit);
      if (allOrders != null) {
        final targetSet = isActive ? _activeStatuses : _pastStatuses;
        final rawList = allOrders is Map
            ? (allOrders['orders'] ?? allOrders['data'] ?? allOrders['items'])
            : allOrders;

        final totalPages = allOrders is Map ? (allOrders['totalPages'] as num?)?.toInt() ?? 1 : 1;
        final hasMore = page < totalPages;

        if (rawList is List) {
          final mapped = rawList
              .whereType<Map>()
              .where((o) => targetSet.contains(o['status']?.toString()))
              .map((o) => Map<String, dynamic>.from(o))
              .toList();
          return (orders: mapped, hasMore: hasMore);
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
    return (orders: <Map<String, dynamic>>[], hasMore: false);
  }

  Future<void> loadMoreActive() async {
    if (state.isLoadingMoreActive || !state.hasMoreActive) return;
    state = state.copyWith(isLoadingMoreActive: true);
    
    final nextPage = state.activePage + 1;
    final result = await _fetchFromApi(page: nextPage, limit: _limit, isActive: true);
    
    state = state.copyWith(
      activeOrders: [...state.activeOrders, ...result.orders],
      activePage: nextPage,
      hasMoreActive: result.hasMore,
      isLoadingMoreActive: false,
    );
  }

  Future<void> loadMorePast() async {
    if (state.isLoadingMorePast || !state.hasMorePast) return;
    state = state.copyWith(isLoadingMorePast: true);
    
    final nextPage = state.pastPage + 1;
    final result = await _fetchFromApi(page: nextPage, limit: _limit, isActive: false);
    
    state = state.copyWith(
      pastOrders: [...state.pastOrders, ...result.orders],
      pastPage: nextPage,
      hasMorePast: result.hasMore,
      isLoadingMorePast: false,
    );
  }

  
  void updateOrderStatusFast(String orderId, String newStatus) {
    bool updated = false;
    final activeIndex = state.activeOrders.indexWhere((o) => o['id'] == orderId);
    if (activeIndex != -1) {
      final newOrders = List<Map<String, dynamic>>.from(state.activeOrders);
      newOrders[activeIndex] = {
        ...newOrders[activeIndex],
        'status': newStatus,
      };
      if (_pastStatuses.contains(newStatus)) {
        final orderToMove = newOrders.removeAt(activeIndex);
        state = state.copyWith(
          activeOrders: newOrders,
          pastOrders: [orderToMove, ...state.pastOrders],
        );
      } else {
        state = state.copyWith(activeOrders: newOrders);
      }
      updated = true;
    }
    
    if (!updated) {
      final pastIndex = state.pastOrders.indexWhere((o) => o['id'] == orderId);
      if (pastIndex != -1) {
        final newOrders = List<Map<String, dynamic>>.from(state.pastOrders);
        newOrders[pastIndex] = {
          ...newOrders[pastIndex],
          'status': newStatus,
        };
        if (_activeStatuses.contains(newStatus)) {
          final orderToMove = newOrders.removeAt(pastIndex);
          state = state.copyWith(
            pastOrders: newOrders,
            activeOrders: [orderToMove, ...state.activeOrders],
          );
        } else {
          state = state.copyWith(pastOrders: newOrders);
        }
      }
    }
  }

  Future<void> refresh() async {
    await _initFetch();
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/orders/$orderId');
      if (response.data != null) {
        var updatedOrder = response.data;
        if (updatedOrder is Map && updatedOrder['data'] != null) {
          updatedOrder = updatedOrder['data'];
        }
        if (updatedOrder is Map<String, dynamic>) {
          final index = state.activeOrders.indexWhere((o) => o['id'] == orderId);
          if (index != -1) {
            final newOrders = List<Map<String, dynamic>>.from(state.activeOrders);
            newOrders[index] = updatedOrder;
            state = state.copyWith(activeOrders: newOrders);
          }
          return updatedOrder;
        }
      }
    } catch (e) {
      debugPrint('Error fetching order details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> estimateOrder({
    required String vendorId,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
    int? coinsToUse,
  }) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      PlaceOrderDtoPaymentMethodEnum method;
      if (paymentMethod.startsWith('MOBILE_WALLET')) {
        method = PlaceOrderDtoPaymentMethodEnum.MOBILE_WALLET;
      } else {
        method = PlaceOrderDtoPaymentMethodEnum.CASH_ON_DELIVERY;
      }

      final builder = PlaceOrderDtoBuilder()
        ..vendorId = vendorId
        ..paymentMethod = method
        ..deliveryAddress = address;

      if (specialRequest != null) {
        builder.specialRequest = specialRequest;
      }

      if (coinsToUse != null && coinsToUse > 0) {
        builder.coinsToUse = coinsToUse;
      }

      if (location.length >= 2) {
        builder.deliveryLocation.replace([location[0], location[1]]);
      }

      final result = await repository.estimateOrder(builder.build());
      if (result is Map<String, dynamic>) {
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Estimate order error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> estimateCustomOrder({
    required String type,
    required String pickup,
    required List<double> pickupLocation,
    required String dropoff,
    required List<double> deliveryLocation,
    String? vehicleType,
    String? details,
    int? coinsToUse,
  }) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      PlaceCustomOrderDtoVehicleTypeEnum vType;
      switch (vehicleType) {
        case 'motorcycle':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.MOTORCYCLE;
          break;
        case 'car':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.CAR;
          break;
        case 'van':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.VAN;
          break;
        case 'truck':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.TRUCK;
          break;
        case 'motor_tricycle':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.MOTOR_TRICYCLE;
          break;
        default:
          vType = PlaceCustomOrderDtoVehicleTypeEnum.BICYCLE;
      }

      final dto = PlaceCustomOrderDto((b) => b
        ..type = type == 'ride'
            ? PlaceCustomOrderDtoTypeEnum.RIDE
            : PlaceCustomOrderDtoTypeEnum.CUSTOM_DELIVERY
        ..paymentMethod = PlaceCustomOrderDtoPaymentMethodEnum.CASH_ON_DELIVERY
        ..pickupAddress = pickup
        ..deliveryAddress = dropoff
        ..vehicleType = vType
        ..pickupLocation = ListBuilder<num>(
            pickupLocation.length >= 2
                ? [pickupLocation[0], pickupLocation[1]]
                : [0.0, 0.0])
        ..deliveryLocation = ListBuilder<num>(
            deliveryLocation.length >= 2
                ? [deliveryLocation[0], deliveryLocation[1]]
                : [0.0, 0.0])
        ..itemDetails = details
        ..coinsToUse = coinsToUse);

      final result = await repo.estimateCustomOrder(dto);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Estimate custom order error: $e');
      return null;
    }
  }

  Future<(String?, String?)> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
    int? coinsToUse,
    String? idempotencyKey,
  }) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    
    try {
      PlaceOrderDtoPaymentMethodEnum method;
      if (paymentMethod.startsWith('MOBILE_WALLET')) {
        method = PlaceOrderDtoPaymentMethodEnum.MOBILE_WALLET;
      } else {
        method = PlaceOrderDtoPaymentMethodEnum.CASH_ON_DELIVERY;
      }

      final builder = PlaceOrderDtoBuilder()
        ..vendorId = vendorId
        ..paymentMethod = method
        ..deliveryAddress = address;

      if (specialRequest != null) {
        builder.specialRequest = specialRequest;
      }

      if (coinsToUse != null && coinsToUse > 0) {
        builder.coinsToUse = coinsToUse;
      }

      if (location.length >= 2) {
        builder.deliveryLocation.replace([
          location[0],
          location[1]
        ]);
      }

      final result = await repository.placeOrder(builder.build(),
          idempotencyKey: idempotencyKey);
      ref.invalidateSelf();
      
      String? orderId;
      if (result is Map) {
        if (result['id'] != null) {
          orderId = result['id'].toString();
        } else if (result['data'] is Map && result['data']['id'] != null) {
          orderId = result['data']['id'].toString();
        }
      }
      
      return (null, orderId); // Success
    } catch (e) {
      debugPrint('Place order error: $e');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return (data['message'].toString(), null);
        }
      }
      return ('Failed to place order', null);
    }
  }

  Future<String?> placeCustomOrder({
    required String type,
    required String pickup,
    required List<double> pickupLocation,
    required String dropoff,
    required List<double> deliveryLocation,
    String? vehicleType,
    String? details,
    int? coinsToUse,
    String? idempotencyKey,
  }) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      PlaceCustomOrderDtoVehicleTypeEnum vType;
      switch (vehicleType) {
        case 'motorcycle':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.MOTORCYCLE;
          break;
        case 'car':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.CAR;
          break;
        case 'van':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.VAN;
          break;
        case 'truck':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.TRUCK;
          break;
        case 'motor_tricycle':
          vType = PlaceCustomOrderDtoVehicleTypeEnum.MOTOR_TRICYCLE;
          break;
        default:
          vType = PlaceCustomOrderDtoVehicleTypeEnum.BICYCLE;
      }

      final dto = PlaceCustomOrderDto((b) => b
        ..type = type == 'ride'
            ? PlaceCustomOrderDtoTypeEnum.RIDE
            : PlaceCustomOrderDtoTypeEnum.CUSTOM_DELIVERY
        ..paymentMethod = PlaceCustomOrderDtoPaymentMethodEnum.CASH_ON_DELIVERY
        ..pickupAddress = pickup
        ..deliveryAddress = dropoff
        ..vehicleType = vType
        ..pickupLocation = ListBuilder<num>(
            pickupLocation.length >= 2
                ? [pickupLocation[0], pickupLocation[1]]
                : [0.0, 0.0])
        ..deliveryLocation = ListBuilder<num>(
            deliveryLocation.length >= 2
                ? [deliveryLocation[0], deliveryLocation[1]]
                : [0.0, 0.0])
        ..itemDetails = details
        ..coinsToUse = coinsToUse);

      final result = await repo.placeCustomOrder(dto,
          idempotencyKey: idempotencyKey);
      ref.invalidateSelf();
      
      if (result is Map && result['data'] != null && result['data']['id'] != null) {
        return result['data']['id'].toString();
      } else if (result is Map && result['id'] != null) {
        return result['id'].toString();
      }
      return 'SUCCESS';
    } catch (e) {
      debugPrint('Custom order error: $e');
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      await repository.cancelOrder(orderId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Cancel order error: $e');
      return false;
    }
  }

  Future<bool> markPaymentPaid(
    String orderId, {
    String? receiptPath,
  }) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      MultipartFile? receipt;
      if (receiptPath != null && receiptPath.isNotEmpty) {
        receipt = await MultipartFile.fromFile(receiptPath);
      }
      await repo.markPaid(orderId, receipt: receipt);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Mark payment paid error: $e');
      return false;
    }
  }

  Future<bool> rateOrder(String orderId, int rating, String comment) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      final builder = CreateReviewDtoBuilder()
        ..vendorRating = rating
        ..driverRating = rating
        ..comment = comment;
      
      await repository.rateOrder(orderId, builder.build());
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Rate order error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> estimateMultiVendorOrder({
    required List<String> vendorIds,
    required String paymentMethod,
    required String address,
    required List<double> location,
    int? coinsToUse,
  }) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      final dto = PlaceMultiVendorOrderDto((b) => b
        ..vendorIds = ListBuilder<String>(vendorIds)
        ..paymentMethod = paymentMethod.startsWith('MOBILE_WALLET') ? 'MOBILE_WALLET' : 'CASH_ON_DELIVERY'
        ..deliveryAddress = address
        ..deliveryLocation = ListBuilder<num>(location.length >= 2 ? [location[0], location[1]] : [0.0, 0.0])
        ..coinsToUse = coinsToUse
      );
      final result = await repository.estimateMultiVendor(dto);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      debugPrint('Estimate multi vendor error: $e');
      return null;
    }
  }

  Future<(String?, String?)> placeMultiVendorOrder({
    required List<String> vendorIds,
    required String paymentMethod,
    required String address,
    required List<double> location,
    String? specialRequest,
    int? coinsToUse,
    String? idempotencyKey,
  }) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      final dto = PlaceMultiVendorOrderDto((b) => b
        ..vendorIds = ListBuilder<String>(vendorIds)
        ..paymentMethod = paymentMethod.startsWith('MOBILE_WALLET') ? 'MOBILE_WALLET' : 'CASH_ON_DELIVERY'
        ..deliveryAddress = address
        ..deliveryLocation = ListBuilder<num>(location.length >= 2 ? [location[0], location[1]] : [0.0, 0.0])
        ..specialRequest = specialRequest
        ..coinsToUse = coinsToUse
      );
      final result = await repository.placeMultiVendorOrder(dto, idempotencyKey: idempotencyKey);
      ref.invalidateSelf();
      String? orderId;
      if (result is Map) {
        if (result['id'] != null) {
          orderId = result['id'].toString();
        } else if (result['data'] is Map && result['data']['id'] != null) {
          orderId = result['data']['id'].toString();
        }
      }
      return (null, orderId);
    } catch (e) {
      debugPrint('Place multi vendor order error: $e');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return (data['message'].toString(), null);
        }
      }
      return ('Failed to place multi-vendor order', null);
    }
  }

  Future<bool> decideAssistOrder(String orderId, {required bool approve, String? deliveryGroupId}) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      await repository.decideAssistOrder(orderId, approved: approve, deliveryGroupId: deliveryGroupId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Customer decide assist error: $e');
      return false;
    }
  }
}
