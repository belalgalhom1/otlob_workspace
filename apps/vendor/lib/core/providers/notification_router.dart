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

  /// Maps an FCM data payload to an in-app destination. Chat pushes for order
  /// conversations carry BOTH `conversationId` and `orderId`, so `conversationId`
  /// is checked first.
  void handleTap(Map<String, String> data) {
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
