import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingNotificationRoute {
  final String kind;
  final String id;
  final String? chatType;

  const PendingNotificationRoute({
    required this.kind,
    required this.id,
    this.chatType,
  });
}

class NotificationRouter extends Notifier<PendingNotificationRoute?> {
  @override
  PendingNotificationRoute? build() => null;

  void setRoute(PendingNotificationRoute? route) => state = route;

  void clear() => state = null;

  /// Maps an FCM data payload to an in-app destination. Wallet adjustments,
  /// chat pushes, and order updates are routed to their specific destinations.
  void handleTap(Map<String, String> data) {
    final kind = (data['kind'] ?? '').trim().toLowerCase();
    final route = (data['route'] ?? '').trim().toLowerCase();
    final topUpId = (data['topUpId'] ?? data['requestId'] ?? '').trim();
    if (kind == 'wallet_topup' ||
        route == 'wallet_topup_details' ||
        route == '/wallet/topups' ||
        (topUpId.isNotEmpty && route.contains('wallet_topup'))) {
      state = PendingNotificationRoute(kind: 'wallet_topup', id: topUpId);
      return;
    }

    final conversationId = (data['conversationId'] ?? '').trim();
    final orderId = (data['orderId'] ?? '').trim();
    if (conversationId.isNotEmpty) {
      final rawChatType = (data['chatType'] ?? '').trim().toUpperCase();
      final resolvedChatType = rawChatType.isNotEmpty
          ? rawChatType
          : (orderId.isNotEmpty ? 'ORDER' : 'SUPPORT');
      state = PendingNotificationRoute(
        kind: 'chat',
        id: conversationId,
        chatType: resolvedChatType,
      );
      return;
    }
    if (orderId.isNotEmpty) {
      state = PendingNotificationRoute(kind: 'order', id: orderId);
      return;
    }
  }
}

final notificationRouterProvider =
    NotifierProvider<NotificationRouter, PendingNotificationRoute?>(
        NotificationRouter.new);
