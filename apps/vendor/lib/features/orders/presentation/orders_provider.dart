import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
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
    ref.listen<String?>(activeVendorProvider, (prev, next) {
      if (next != null && next.isNotEmpty && next != prev) {
        final currentParams =
            state.hasValue ? state.value!.params : const <String, dynamic>{};
        fetchOrders(params: currentParams);
      }
    });
    return const AsyncValue.loading();
  }

  void clear() {
    ref.read(orderRevisionTrackerProvider).clear();
    state = AsyncValue.data(OrdersStateData([], 0, {}));
  }

  Future<void> fetchOrders({Map<String, dynamic> params = const {}}) async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    if (!await authRepo.isLoggedIn()) {
      clear();
      return;
    }
    final effectiveParams =
        (params.isEmpty && state.hasValue && state.value!.params.isNotEmpty)
            ? state.value!.params
            : params;
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }

    try {
      final role = await authRepo.getUserRole();
      final status = effectiveParams['status'];
      final page = effectiveParams['page'] ?? 1;
      final limit = effectiveParams['limit'] ?? 20;

      dynamic result;
      if (role == 'VENDOR_MEMBER') {
        String? vendorId = ref.read(activeVendorProvider);
        if (vendorId == null || vendorId.isEmpty) {
          final memberships = await authRepo.getVendorMemberships();
          if (memberships.isNotEmpty && memberships.first is Map) {
            vendorId = (memberships.first as Map)['vendorId']?.toString();
            if (vendorId != null && vendorId.isNotEmpty) {
              await ref
                  .read(activeVendorProvider.notifier)
                  .setActiveVendor(vendorId);
            }
          }
        }
        final targetVendorId =
            (vendorId != null && vendorId.isNotEmpty) ? vendorId : 'my';
        result = await ref.read(vendorOrdersRepositoryProvider).ordersFindAll(
          vendorId: targetVendorId,
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

      final orders = result['orders'] ?? result['items'] ?? [];
      // Seed the realtime revision guard with the authoritative snapshot so a
      // socket event that was already in flight cannot regress it.
      if (orders is List) {
        final revisions = ref.read(orderRevisionTrackerProvider);
        for (final order in orders) {
          revisions.observeOrder(order);
        }
      }
      state = AsyncValue.data(
        OrdersStateData(orders, result['total'] ?? 0, effectiveParams),
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

  
  void updateOrderStatusFast(
    String orderId,
    String newStatus, {
    bool isFulfillmentDelta = false,
    String? fulfillmentId,
  }) {
    if (!state.hasValue) return;
    final currentData = state.value!;
    final newOrders = List<dynamic>.from(currentData.orders);
    final index = newOrders.indexWhere((o) => o['id'] == orderId);
    if (index == -1) return;

    final Map<String, dynamic> updatedOrder =
        Map<String, dynamic>.from(newOrders[index]);
    final isMultiVendorPortion = updatedOrder['myFulfillmentStatus'] != null;
    final myFulfillmentId = updatedOrder['myFulfillmentId']?.toString();

    bool updatedChild = false;
    if (isFulfillmentDelta &&
        fulfillmentId != null &&
        updatedOrder['vendorFulfillments'] is List) {
      final fulfillments = List<dynamic>.from(
        updatedOrder['vendorFulfillments'] as List,
      );
      for (int i = 0; i < fulfillments.length; i++) {
        final f = fulfillments[i];
        if (f is Map && f['id']?.toString() == fulfillmentId) {
          fulfillments[i] = {...f, 'status': newStatus};
          updatedChild = true;
        }
      }
      if (updatedChild) {
        updatedOrder['vendorFulfillments'] = fulfillments;
      }
    }

    final matchesMyFulfillment = fulfillmentId == null ||
        myFulfillmentId == null ||
        myFulfillmentId == fulfillmentId;

    bool changed = updatedChild;
    if (!isFulfillmentDelta) {
      if (isMultiVendorPortion) {
        updatedOrder['orderStatus'] = newStatus;
      } else {
        updatedOrder['status'] = newStatus;
      }
      changed = true;
    } else if (matchesMyFulfillment) {
      updatedOrder['status'] = newStatus;
      if (isMultiVendorPortion) {
        updatedOrder['myFulfillmentStatus'] = newStatus;
      }
      changed = true;
    }

    if (changed) {
      newOrders[index] = updatedOrder;
      state = AsyncValue.data(
        OrdersStateData(newOrders, currentData.total, currentData.params),
      );
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String nextStatus, {
    int? estimatedPrepTime,
    String? fulfillmentId,
  }) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    MvDebugLogger.setAppTag('VENDOR');
    MvDebugLogger.log(
      'STEP_4_VENDOR_UPDATE_STATUS',
      'Vendor/Admin updating order/fulfillment status to $nextStatus',
      data: {
        'orderId': orderId,
        'nextStatus': nextStatus,
        'fulfillmentId': fulfillmentId,
        'estimatedPrepTime': estimatedPrepTime,
        'role': role,
      },
    );
    if (role == 'VENDOR_MEMBER') {
       await ref.read(vendorOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.valueOf(nextStatus)
          ..estimatedPrepTime = estimatedPrepTime?.toDouble()
          ..fulfillmentId = fulfillmentId
         ),
       );
    } else {
       await ref.read(adminOrdersRepositoryProvider).ordersUpdate(
         orderId: orderId,
         updateOrderStatusDto: UpdateOrderStatusDto((b) => b
          ..status = UpdateOrderStatusDtoStatusEnum.valueOf(nextStatus)
          ..estimatedPrepTime = estimatedPrepTime?.toDouble()
          ..fulfillmentId = fulfillmentId
         ),
       );
    }

    await fetchOrders(params: currentParams);
  }

  Future<void> cancelOrder(
    String orderId,
    String reason, {
    String? fulfillmentId,
  }) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    if (fulfillmentId != null && fulfillmentId.isNotEmpty) {
      if (role == 'VENDOR_MEMBER') {
        await ref.read(vendorOrdersRepositoryProvider).ordersUpdate(
          orderId: orderId,
          updateOrderStatusDto: UpdateOrderStatusDto((b) => b
            ..status = UpdateOrderStatusDtoStatusEnum.CANCELLED
            ..note = reason
            ..fulfillmentId = fulfillmentId),
        );
      } else {
        await ref.read(adminOrdersRepositoryProvider).ordersUpdate(
          orderId: orderId,
          updateOrderStatusDto: UpdateOrderStatusDto((b) => b
            ..status = UpdateOrderStatusDtoStatusEnum.CANCELLED
            ..note = reason
            ..fulfillmentId = fulfillmentId),
        );
      }
    } else if (role == 'VENDOR_MEMBER') {
      await ref.read(vendorOrdersRepositoryProvider).cancelOrder(orderId);
    } else {
      await ref.read(adminOrdersRepositoryProvider).cancelOrder(orderId);
    }

    await fetchOrders(params: currentParams);
  }

  Future<void> acceptFulfillment(String fulfillmentId) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    MvDebugLogger.setAppTag('VENDOR');
    MvDebugLogger.log(
      'STEP_4_VENDOR_ACCEPT_FULFILLMENT',
      'Accepting vendor fulfillment $fulfillmentId',
      data: {'fulfillmentId': fulfillmentId, 'role': role},
    );
    if (role == 'VENDOR_MEMBER') {
      await ref.read(vendorOrdersRepositoryProvider).acceptFulfillment(fulfillmentId);
    } else {
      await ref.read(adminOrdersRepositoryProvider).acceptFulfillment(fulfillmentId);
    }

    await fetchOrders(params: currentParams);
  }

  Future<void> rejectFulfillment(String fulfillmentId, String reason, {String code = 'OTHER'}) async {
    Map<String, dynamic> currentParams = const {};
    if (state.hasValue) {
      currentParams = state.value!.params;
    }

    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    MvDebugLogger.setAppTag('VENDOR');
    MvDebugLogger.log(
      'STEP_4_VENDOR_REJECT_FULFILLMENT',
      'Rejecting vendor fulfillment $fulfillmentId ($code)',
      data: {
        'fulfillmentId': fulfillmentId,
        'code': code,
        'reason': reason,
        'role': role,
      },
    );
    if (role == 'VENDOR_MEMBER') {
      await ref.read(vendorOrdersRepositoryProvider).rejectFulfillment(fulfillmentId, reason: reason, code: code);
    } else {
      await ref.read(adminOrdersRepositoryProvider).rejectFulfillment(fulfillmentId, reason: reason, code: code);
    }

    await fetchOrders(params: currentParams);
  }
}


