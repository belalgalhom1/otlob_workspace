import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingNotificationRoute {
  final String kind;
  final String id;

  const PendingNotificationRoute({required this.kind, required this.id});
}

class NotificationRouter extends Notifier<PendingNotificationRoute?> {
  @override
  PendingNotificationRoute? build() => null;

  void setRoute(PendingNotificationRoute? route) => state = route;

  void clear() => state = null;

  /// Maps an FCM data payload to an in-app destination. Order pushes carry
  /// `orderId`; chat pushes carry `conversationId`. Anything else is ignored.
  void handleTap(Map<String, String> data) {
    final orderId = (data['orderId'] ?? '').trim();
    if (orderId.isNotEmpty) {
      state = PendingNotificationRoute(kind: 'order', id: orderId);
      return;
    }
    final conversationId = (data['conversationId'] ?? '').trim();
    if (conversationId.isNotEmpty) {
      state = PendingNotificationRoute(kind: 'chat', id: conversationId);
      return;
    }
  }
}

final notificationRouterProvider =
    NotifierProvider<NotificationRouter, PendingNotificationRoute?>(
        NotificationRouter.new);
