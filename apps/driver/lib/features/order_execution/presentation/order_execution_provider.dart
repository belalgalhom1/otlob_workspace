import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

part 'order_execution_provider.g.dart';

@riverpod
class OrderExecution extends _$OrderExecution {
  @override
  AsyncValue<dynamic> build() {
    _fetchActiveOrder();
    return const AsyncValue.loading();
  }

  String? _selectedOrderId;

  void selectOrder(String orderId) {
    _selectedOrderId = orderId;
    state = const AsyncValue.loading();
    _fetchActiveOrder();
  }

  void clearSelectedOrder() {
    _selectedOrderId = null;
  }

  Future<void> refresh() => _fetchActiveOrder();

  Future<void> _fetchActiveOrder() async {
    try {
      final repository = ref.read(driverOrdersRepositoryProvider);
      final response = await repository.getActiveDriverOrder(orderId: _selectedOrderId);
      // The provider can be auto-disposed while this network call is in
      // flight (e.g. a transient ref.read with no active listener). Guard so
      // we never write state after the Ref is gone.
      if (!ref.mounted) return;
      if (response['data'] == null) {
        // No active order found, perhaps completed?
        _selectedOrderId = null;
        state = const AsyncValue.data(null);
      } else {
        // REST detail is authoritative: keep the revision guard above any
        // socket event that may still be queued behind this response.
        ref.read(orderRevisionTrackerProvider).observeOrder(response['data']);
        _selectedOrderId = response['data']['id']?.toString();
        state = AsyncValue.data(response['data']);
      }
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  String? _activeOrderId(AsyncValue<dynamic> prev) {
    final value = prev.value;
    if (value is! Map) return null;
    final id = value['id']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  String? _activeDeliveryGroupId(AsyncValue<dynamic> prev) {
    final value = prev.value;
    if (value is! Map) return null;
    final direct = value['activeDeliveryGroupId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final groups = value['deliveryGroups'];
    final driverId = value['driverId']?.toString();
    if (groups is List && groups.isNotEmpty) {
      for (final g in groups) {
        if (g is Map &&
            g['status'] != 'DELIVERED' &&
            g['status'] != 'CANCELLED' &&
            (driverId == null ||
                g['primaryDriverId']?.toString() == driverId ||
                g['assistDriverId']?.toString() == driverId)) {
          return g['id']?.toString();
        }
      }
    }
    return null;
  }

  Future<void> updateOrderStatus(String newStatus) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    final activeGroupId = _activeDeliveryGroupId(prev);
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(driverOrdersRepositoryProvider);

      await repository.updateOrderStatus(
        orderId,
        newStatus,
        deliveryGroupId: activeGroupId,
      );
      if (newStatus == 'DELIVERED' || newStatus == 'CANCELLED') {
        _selectedOrderId = null;
      }
      await _fetchActiveOrder();
      
      if (newStatus == 'DELIVERED') {
        // Automatically go offline or online based on logic, or just let them stay on Dashboard
        ref.read(driverProfileProvider.notifier).fetchProfile();
      }
    } catch (e, st) {
      if (prev.hasValue) {
        state = prev; // Restore on error
      } else {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }

  Future<void> confirmPayment({required bool received}) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(driverOrdersRepositoryProvider);

      await repository.confirmPayment(orderId, received: received);
      await _fetchActiveOrder();
    } catch (e, st) {
      if (prev.hasValue) {
        state = prev;
      } else {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }

  // Confirms pickup by uploading the mandatory order photo and marking PICKED_UP.
  // Supports per-fulfillment pickup stops for multi-vendor orders.
  Future<void> confirmPickupWithPhoto(XFile photo, {String? fulfillmentId}) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    try {
      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
      });
      final path = fulfillmentId != null && fulfillmentId.isNotEmpty
          ? '/orders/driver/$orderId/fulfillment/$fulfillmentId/pickup'
          : '/orders/driver/$orderId/pickup';
      MvDebugLogger.setAppTag('DRIVER');
      MvDebugLogger.log(
        'STEP_5_DRIVER_STOP_PICKUP_START',
        'Driver confirming pickup stop (orderId=$orderId, fulfillmentId=$fulfillmentId)',
        data: {
          'orderId': orderId,
          'fulfillmentId': fulfillmentId,
          'path': path,
        },
      );
      await dio.post(path, data: formData);
      MvDebugLogger.log(
        'STEP_5_DRIVER_STOP_PICKUP_DONE',
        'Driver pickup stop confirmed (orderId=$orderId, fulfillmentId=$fulfillmentId)',
        data: {'orderId': orderId, 'fulfillmentId': fulfillmentId},
      );
      await _fetchActiveOrder();
    } catch (e, st) {
      if (prev.hasValue) {
        state = prev;
      } else {
        state = AsyncValue.error(e, st);
      }
      // Sync with server in case the upload succeeded right before a network drop.
      _fetchActiveOrder();
      rethrow;
    }
  }

  // Confirms delivery by uploading the mandatory order photo and marking DELIVERED.
  Future<void> confirmDeliveryWithPhoto(XFile photo, {String? deliveryGroupId}) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    final resolvedGroupId = (deliveryGroupId != null && deliveryGroupId.isNotEmpty)
        ? deliveryGroupId
        : _activeDeliveryGroupId(prev);
    try {
      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
      });
      final query = resolvedGroupId != null && resolvedGroupId.isNotEmpty
          ? '?deliveryGroupId=$resolvedGroupId'
          : '';
      MvDebugLogger.setAppTag('DRIVER');
      MvDebugLogger.log(
        'STEP_6_DRIVER_DELIVERY_START',
        'Driver confirming customer delivery (orderId=$orderId, deliveryGroupId=$resolvedGroupId)',
        data: {
          'orderId': orderId,
          'deliveryGroupId': resolvedGroupId,
        },
      );
      await dio.post('/orders/driver/$orderId/delivery$query', data: formData);
      MvDebugLogger.log(
        'STEP_6_DRIVER_DELIVERY_DONE',
        'Driver customer delivery confirmed (orderId=$orderId, deliveryGroupId=$resolvedGroupId)',
        data: {
          'orderId': orderId,
          'deliveryGroupId': resolvedGroupId,
        },
      );
      _selectedOrderId = null;
      await _fetchActiveOrder();
      if (ref.mounted) {
        ref.read(driverProfileProvider.notifier).fetchProfile();
      }
    } catch (e, st) {
      if (prev.hasValue) {
        state = prev;
      } else {
        state = AsyncValue.error(e, st);
      }
      _fetchActiveOrder();
      rethrow;
    }
  }
  
  void handleSocketUpdate(Map<String, dynamic> data) {
    if (state.hasValue && state.value != null) {
      final orderId = state.value['id']?.toString();
      final incomingId = (data['orderId'] ?? data['id'])?.toString();
      if (incomingId != null && incomingId == orderId) {
        // Same guard as the global listener: never apply a stale transition.
        if (!ref
            .read(orderRevisionTrackerProvider)
            .accept(incomingId, orderRevisionOf(data))) {
          return;
        }
        if (data['fulfillmentId'] != null) {
          final updated = Map<String, dynamic>.from(state.value as Map);
          final incomingFId = data['fulfillmentId'].toString();
          final incomingFStatus = (data['fulfillmentStatus'] ?? data['status'])?.toString();
          if (incomingFStatus == 'REJECTED' || incomingFStatus == 'CANCELLED') {
            // Portion removed from route: refetch full order so stops/fees stay exact.
            _fetchActiveOrder();
            return;
          }
          final rawFulfillments = updated['vendorFulfillments'];
          var matchesMyStop = false;
          if (rawFulfillments is List) {
            final nextFulfillments = List<dynamic>.from(rawFulfillments);
            for (int i = 0; i < nextFulfillments.length; i++) {
              final f = nextFulfillments[i];
              if (f is Map && f['id']?.toString() == incomingFId) {
                matchesMyStop = true;
                final copy = Map<String, dynamic>.from(f);
                if (incomingFStatus != null) copy['status'] = incomingFStatus;
                if (data['pickedUpAt'] != null) copy['pickedUpAt'] = data['pickedUpAt'];
                if (data['pickupImageUrl'] != null) copy['pickupImageUrl'] = data['pickupImageUrl'];
                nextFulfillments[i] = copy;
              }
            }
            updated['vendorFulfillments'] = nextFulfillments;
          }
          final groups = updated['deliveryGroups'];
          final isMultiGroup = groups is List && groups.length > 1;
          if (!isMultiGroup) {
            final status = data['orderStatus'] ?? data['parentStatus'];
            if (status != null) updated['status'] = status;
          }
          if (matchesMyStop) {
            state = AsyncValue.data(updated);
          }
          if (isMultiGroup) {
            _fetchActiveOrder();
          }
          return;
        }

        final updatedState = Map<String, dynamic>.from(state.value);
        final groups = updatedState['deliveryGroups'];
        final isMultiGroup = groups is List && groups.length > 1;
        final newStatus = data['newStatus'] ?? data['status'];
        final normalized = newStatus?.toString().toUpperCase();
        if (normalized == 'DELIVERED' || normalized == 'CANCELLED') {
          _selectedOrderId = null;
          _fetchActiveOrder();
        } else if (isMultiGroup || newStatus == null) {
          // Multi-group aggregate order status or payment-only socket updates
          // must re-fetch the group-projected active order instead of letting
          // another group's status overwrite this driver's execution state.
          _fetchActiveOrder();
        } else {
          updatedState['status'] = newStatus;
          state = AsyncValue.data(updatedState);
        }
      }
    }
  }

  void handleFulfillmentSocketUpdate(Map<String, dynamic> data) {
    handleSocketUpdate(data);
  }

  Future<bool> requestAssist({
    required String reason,
    String? note,
    String? deliveryGroupId,
  }) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return false;
    final resolvedGroupId = (deliveryGroupId != null && deliveryGroupId.isNotEmpty)
        ? deliveryGroupId
        : _activeDeliveryGroupId(prev);
    try {
      final repository = ref.read(driverOrdersRepositoryProvider);
      if (resolvedGroupId != null && resolvedGroupId.isNotEmpty) {
        await repository.requestAssist(
          orderId,
          deliveryGroupId: resolvedGroupId,
          reason: reason,
          note: note,
        );
      } else {
        await repository.requestAssistOrder(orderId, reason: reason, note: note);
      }
      await _fetchActiveOrder();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelAssist(String requestId) async {
    try {
      final repository = ref.read(driverOrdersRepositoryProvider);
      await repository.cancelAssistRequest(requestId);
      await _fetchActiveOrder();
      return true;
    } catch (e) {
      return false;
    }
  }

}
