import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/socket_service.dart';
import '../services/navigation_service.dart';
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/orders/presentation/widgets/customer_approval_bottom_sheet.dart';

part 'global_order_listener.g.dart';

@Riverpod(keepAlive: true)
class GlobalOrderListener extends _$GlobalOrderListener {
  String? _lastShownOrderId;

  @override
  void build() {
    final authStatus = ref.watch(authControllerProvider);
    
    if (authStatus == AuthStatus.authenticated) {
      _init();
    }
    
    return;
  }

  Future<void> _init() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final accessToken = await tokenService.getAccessToken();
    
    if (accessToken != null) {
      socket.initSocket(accessToken);
      
      socket.off('order.status'); // Clean up old listeners
      socket.on('order.status', (data) {
        _handleOrderStatusUpdate(data);
      });
    }
  }

  void _handleOrderStatusUpdate(dynamic rawData) {
    if (rawData == null) return;
    
    // Convert to map safely depending on socket payload
    Map<String, dynamic> data;
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      return;
    }

    final orderId = data['orderId']?.toString();
    final status = data['newStatus']?.toString() ?? data['status']?.toString();

    if (orderId == null || status == null) return;

    if (status == 'PENDING_CUSTOMER_APPROVAL' || status == 'DRIVER_ASSIGNED') {
      if (orderId == _lastShownOrderId) return;
      _lastShownOrderId = orderId;
      
      final navigation = ref.read(navigationServiceProvider);
      final context = navigation.navigatorKey.currentContext;
      
      if (context != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false, // Force them to take action or explicitly dismiss with a button
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => CustomerApprovalBottomSheet(
            orderId: orderId,
          ),
        ).then((_) {
          // Allow showing it again if it was dismissed (if they revisit)
          _lastShownOrderId = null;
        });
      }
    }
  }
}
