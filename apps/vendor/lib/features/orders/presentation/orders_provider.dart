import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:api/api.dart';

part 'orders_provider.g.dart';

class OrdersStateData {
  final List<dynamic> orders;
  final int total;
  final Map<String, dynamic> params;

  OrdersStateData(this.orders, this.total, this.params);
}

class OrdersRefreshError extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final ordersRefreshErrorProvider =
    NotifierProvider<OrdersRefreshError, String?>(OrdersRefreshError.new);

@Riverpod(keepAlive: true)
class OrdersNotifier extends _$OrdersNotifier {
  @override
  AsyncValue<OrdersStateData> build() {
    return const AsyncValue.loading();
  }

  void clear() {
    state = AsyncValue.data(OrdersStateData([], 0, {}));
  }

  Future<void> fetchOrders({Map<String, dynamic> params = const {}}) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    if (!await authRepo.isLoggedIn()) {
      clear();
      return;
    }
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }

    try {
      final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
      final status = params['status'];
      final page = params['page'] ?? 1;
      final limit = params['limit'] ?? 20;

      dynamic result;
      if (role == 'VENDOR_MEMBER') {
        final vendorId = ref.read(activeVendorProvider);
        result = await ref.read(vendorOrdersRepositoryProvider).ordersFindAll(
          vendorId: vendorId ?? '',
          page: page,
          limit: limit,
          status: status,
        );
      } else {
        result = await ref.read(adminOrdersRepositoryProvider).ordersFindAll(
          page: page,
          limit: limit,
          status: status,
        );
      }

      state = AsyncValue.data(
        OrdersStateData(result['orders'] ?? result['items'] ?? [], result['total'] ?? 0, params),
      );
      ref.read(ordersRefreshErrorProvider.notifier).set(null);
    } catch (e, st) {
      if (state.hasValue) {
        // Refresh/pagination failure: keep the stale list visible and flag
        // the error on a side channel so the screen can offer a retry.
        ref.read(ordersRefreshErrorProvider.notifier).set(e.toString());
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  
  void updateOrderStatusFast(String orderId, String newStatus) {
    if (state.hasValue) {
      final currentData = state.value!;
      final newOrders = List<dynamic>.from(currentData.orders);
      final index = newOrders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        final Map<String, dynamic> updatedOrder = Map<String, dynamic>.from(newOrders[index]);
        updatedOrder['status'] = newStatus;
        newOrders[index] = updatedOrder;
        state = AsyncValue.data(
          OrdersStateData(newOrders, currentData.total, currentData.params)
        );
      }
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String nextStatus, {
    int? estimatedPrepTime,
  }) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    if (role == 'VENDOR_MEMBER') {
       await ref.read(vendorOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.valueOf(nextStatus)
          ..estimatedPrepTime = estimatedPrepTime?.toDouble()
         ),
       );
    } else {
       await ref.read(adminOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.valueOf(nextStatus)
          ..estimatedPrepTime = estimatedPrepTime?.toDouble()
         ),
       );
    }

    await fetchOrders(params: currentParams);
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    if (role == 'VENDOR_MEMBER') {
       await ref.read(vendorOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.CANCELLED
          ..note = reason
         ),
       );
    } else {
       await ref.read(adminOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.CANCELLED
          ..note = reason
         ),
       );
    }

    await fetchOrders(params: currentParams);
  }
}


