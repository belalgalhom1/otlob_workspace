import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart' hide CartItem;
import 'package:built_collection/built_collection.dart';
import 'package:core/core.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import 'package:flutter/foundation.dart';

part 'orders_provider.g.dart';

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
      final active = await _fetchFromApi(page: 1, limit: _limit, isActive: true);
      final past = await _fetchFromApi(page: 1, limit: _limit, isActive: false);
      
      state = state.copyWith(
        activeOrders: active,
        pastOrders: past,
        isLoading: false,
        hasMoreActive: active.length == _limit,
        hasMorePast: past.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  static const _activeStatuses = {
    'PENDING', 'CHANGES_REQUESTED', 'ACCEPTED', 'PREPARING',
    'LOOKING_FOR_DRIVER', 'DRIVER_ASSIGNED', 'PENDING_PAYMENT',
    'READY_FOR_PICKUP', 'PICKED_UP', 'PENDING_CUSTOMER_APPROVAL',
  };

  static const _pastStatuses = {'DELIVERED', 'CANCELLED'};

  Future<List<Map<String, dynamic>>> _fetchFromApi({required int page, required int limit, required bool isActive}) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      final allOrders = await repo.getMyOrders(page: page, limit: limit);
      if (allOrders != null) {
        final targetSet = isActive ? _activeStatuses : _pastStatuses;
        return (allOrders as List)
            .whereType<Map>()
            .where((o) => targetSet.contains(o['status']?.toString()))
            .map((o) => Map<String, dynamic>.from(o))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
    return [];
  }


  Future<void> loadMoreActive() async {
    if (state.isLoadingMoreActive || !state.hasMoreActive) return;
    state = state.copyWith(isLoadingMoreActive: true);
    
    final nextPage = state.activePage + 1;
    final newOrders = await _fetchFromApi(page: nextPage, limit: _limit, isActive: true);
    
    state = state.copyWith(
      activeOrders: [...state.activeOrders, ...newOrders],
      activePage: nextPage,
      hasMoreActive: newOrders.length == _limit,
      isLoadingMoreActive: false,
    );
  }

  Future<void> loadMorePast() async {
    if (state.isLoadingMorePast || !state.hasMorePast) return;
    state = state.copyWith(isLoadingMorePast: true);
    
    final nextPage = state.pastPage + 1;
    final newOrders = await _fetchFromApi(page: nextPage, limit: _limit, isActive: false);
    
    state = state.copyWith(
      pastOrders: [...state.pastOrders, ...newOrders],
      pastPage: nextPage,
      hasMorePast: newOrders.length == _limit,
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

  Future<void> approveOrderFee(String orderId) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    try {
      await repository.approveFee(orderId);
      // Let backend process, then fetch updated order details (e.g. status changes to DRIVER_ASSIGNED or PENDING_PAYMENT)
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchOrderDetails(orderId);
    } catch (e) {
      debugPrint('Approve fee error: $e');
      throw ApiErrorMapper.fromError(e);
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
  }) async {
    final repository = ref.read(customerOrderRepositoryProvider);
    
    try {
      PlaceOrderDtoPaymentMethodEnum method;
      if (paymentMethod == 'MOBILE_WALLET') {
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

      final result = await repository.placeOrder(builder.build());
      ref.invalidateSelf();
      
      String? orderId;
      if (result is Map && result['id'] != null) {
        orderId = result['id'].toString();
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

      final result = await repo.placeCustomOrder(dto);
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

  Future<bool> acceptOrderChanges(String orderId) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      await repo.acceptOrderChanges(orderId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Accept changes error: $e');
      return false;
    }
  }

  Future<bool> rejectOrderChanges(String orderId) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      await repo.rejectOrderChanges(orderId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('Reject changes error: $e');
      return false;
    }
  }

  Future<bool> markPaymentPaid(String orderId) async {
    final repo = ref.read(customerOrderRepositoryProvider);
    try {
      await repo.markPaid(orderId);
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
}
