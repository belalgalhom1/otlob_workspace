import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/socket_service.dart';
import '../services/navigation_service.dart';
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/chat/presentation/widgets/order_offer_bottom_sheet.dart';

part 'global_message_listener.g.dart';

@Riverpod(keepAlive: true)
class GlobalMessageListener extends _$GlobalMessageListener {
  String? _lastShownOfferId;
  StreamSubscription<dynamic>? _chatSub;

  @override
  void build() {
    ref.onDispose(() {
      _chatSub?.cancel();
      _chatSub = null;
    });

    final authStatus = ref.watch(authControllerProvider);

    if (authStatus == AuthStatus.authenticated) {
      _init();
    } else {
      _disconnect();
    }

    return;
  }

  void _disconnect() {
    _lastShownOfferId = null;
    _chatSub?.cancel();
    _chatSub = null;
    ref.read(socketServiceProvider).disconnect();
  }

  Future<void> _init() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final accessToken = await tokenService.getAccessToken();
    if (!ref.mounted) return;

    if (accessToken != null) {
      await socket.initSocket(accessToken);
      if (!ref.mounted) return;

      _chatSub?.cancel();
      _chatSub = socket.onEvent('chat.message').listen((data) {
        if (!ref.mounted || data is! Map) return;
        _handleIncomingMessage(Map<String, dynamic>.from(data));
      });
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final metadata = data['metadata'];
    if (metadata == null) return;

    if (metadata['type'] == 'OFFER') {
      final offerId = data['messageId'] ?? data['id'];
      if (offerId == _lastShownOfferId) return;

      final product = metadata['product'] as Map<String, dynamic>?;
      if (product == null) return;

      _lastShownOfferId = offerId;
      
      // Show popup globally
      final navigation = ref.read(navigationServiceProvider);
      final context = navigation.navigatorKey.currentContext;
      
      if (context != null) {
        // Optional: Check if we are already in the chat screen for this vendor
        // to avoid duplicate popups if ChatScreen is also listening.
        // For now, we allow it as requested "not only in chat we make it appear auto popup"
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OrderOfferBottomSheet(
            product: product,
            vendorId: data['senderId'] ?? '', // Sender is the vendor
            vendorName: data['senderName'] ?? 'Vendor',
          ),
        );
      }
    }
  }
}
