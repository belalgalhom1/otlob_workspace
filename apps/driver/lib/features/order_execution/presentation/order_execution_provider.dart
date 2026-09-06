import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

part 'order_execution_provider.g.dart';

@riverpod
class OrderExecution extends _$OrderExecution {
  @override
  AsyncValue<dynamic> build() {
    _fetchActiveOrder();
    return const AsyncValue.loading();
  }

  Future<void> _fetchActiveOrder() async {
    try {
      final repository = ref.read(driverOrdersRepositoryProvider);
      final response = await repository.getActiveDriverOrder();
      
      if (response['data'] == null) {
        // No active order found, perhaps completed?
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.data(response['data']);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOrderStatus(String newStatus) async {
    final prev = state;
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(driverOrdersRepositoryProvider);
      final orderId = prev.value['id'];
      
      await repository.updateOrderStatus(orderId, newStatus);
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
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(driverOrdersRepositoryProvider);
      final orderId = prev.value['id'];
      
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
  
  void handleSocketUpdate(Map<String, dynamic> data) {
    if (state.hasValue && state.value != null) {
      final orderId = state.value['id']?.toString();
      final incomingId = (data['orderId'] ?? data['id'])?.toString();
      if (incomingId != null && incomingId == orderId) {
        final updatedState = Map<String, dynamic>.from(state.value);
        final newStatus = data['newStatus'] ?? data['status'];
        if (newStatus != null) {
          updatedState['status'] = newStatus;
          state = AsyncValue.data(updatedState);
        } else {
          _fetchActiveOrder();
        }
      }
    }
  }
}
