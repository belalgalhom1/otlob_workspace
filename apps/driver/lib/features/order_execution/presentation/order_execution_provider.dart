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

  Future<void> updateOrderStatus(String newStatus) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(driverOrdersRepositoryProvider);

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
  Future<void> confirmPickupWithPhoto(XFile photo) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    try {
      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
      });
      await dio.post('/orders/driver/$orderId/pickup', data: formData);
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

  // Confirms delivery by uploading the mandatory order photo and marking DELIVERED.
  Future<void> confirmDeliveryWithPhoto(XFile photo) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return;
    try {
      state = const AsyncValue.loading();
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(photo.path, filename: photo.name),
      });
      await dio.post('/orders/driver/$orderId/delivery', data: formData);
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

  Future<bool> requestAssist({required String reason, String? note}) async {
    final prev = state;
    final orderId = _activeOrderId(prev);
    if (orderId == null) return false;
    try {
      final repository = ref.read(driverOrdersRepositoryProvider);
      await repository.requestAssistOrder(orderId, reason: reason, note: note);
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
