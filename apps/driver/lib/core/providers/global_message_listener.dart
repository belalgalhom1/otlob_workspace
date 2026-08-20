import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/features/dispatch/presentation/pages/dispatch_modal.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';

final globalMessageListenerProvider = Provider<void>((ref) {
  final socketService = ref.watch(coreSocketServiceProvider);

  // Read location service to initialize it
  ref.read(locationServiceProvider);

  // Listen to incoming dispatches
  socketService.onEvent(SocketEvent.dispatchIncoming).listen((eventData) {
    debugPrint('Global listener: Received dispatchIncoming -> $eventData');
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted && eventData is Map) {
      DispatchModal.show(context, Map<String, dynamic>.from(eventData));
    }
  });

  socketService.onEvent(SocketEvent.dispatchCancelled).listen((eventData) {
    debugPrint('Global listener: Received dispatchCancelled -> $eventData');
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      // Pop routes until we find one that IS NOT the modal.
      // This safely closes the modal if it's open, but doesn't pop twice.
      Navigator.of(context).popUntil((route) {
        if (route.settings.name == 'dispatch_modal_route') {
          return false; // keep popping
        }
        return true; // stop popping
      });
    }
  });

  socketService.onEvent(SocketEvent.orderStatus).listen((eventData) {
    debugPrint('Global listener: Received orderStatus -> $eventData');
    if (eventData == null) return;

    final newStatus = eventData['newStatus']?.toString() ?? eventData['status']?.toString() ?? '';

    if (newStatus == 'CANCELLED' || newStatus == 'DELIVERED') {
      // Order ended — clear active order and refresh profile to hide the placeholder
      ref.invalidate(orderExecutionProvider);
      ref.invalidate(driverProfileProvider);
    } else if (newStatus.isNotEmpty) {
      // Any other status change (e.g. customer approved fee, payment confirmed) —
      // refresh the active order data so the screen reflects the latest state
      final orderExecution = ref.read(orderExecutionProvider);
      if (orderExecution.hasValue && orderExecution.value != null) {
        final orderId = orderExecution.value['id']?.toString();
        final updatedOrderId = eventData['orderId']?.toString() ?? eventData['id']?.toString();
        if (orderId != null && orderId == updatedOrderId) {
          // Update the state directly if payload contains order data, otherwise re-fetch
          if (eventData.containsKey('status')) {
            ref.read(orderExecutionProvider.notifier).handleSocketUpdate(
              Map<String, dynamic>.from(eventData),
            );
          } else {
            ref.invalidate(orderExecutionProvider);
          }
        }
      }
    }
  });
});
