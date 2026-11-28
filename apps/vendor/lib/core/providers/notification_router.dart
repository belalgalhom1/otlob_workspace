import 'dart:convert';

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

  /// Maps an FCM or local notification data payload to an in-app destination.
  /// Wallet adjustments/settlements, chat pushes, and order updates are routed
  /// to their specific destinations.
  void handleTap(Map<String, String> data) {
    final normalized = <String, String>{...data};
    final nestedRaw = data['data'];
    if (nestedRaw != null && nestedRaw.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(nestedRaw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key.toString();
            final value = entry.value?.toString() ?? '';
            if (value.isNotEmpty && (normalized[key] ?? '').trim().isEmpty) {
              normalized[key] = value;
            }
          }
        }
      } catch (_) {}
    }

    final kind = (normalized['kind'] ?? '').trim().toLowerCase();
    final route = (normalized['route'] ?? '').trim().toLowerCase();
    final type = (normalized['type'] ?? '').trim().toUpperCase();
    final topUpId = (normalized['topUpId'] ??
            normalized['requestId'] ??
            normalized['top_up_id'] ??
            normalized['request_id'] ??
            '')
        .trim();
    if (kind == 'driver_manager_payout' ||
        route == 'driver_manager_wallet') {
      final txId = (normalized['transactionId'] ?? '').trim();
      state = PendingNotificationRoute(
        kind: 'driver_manager_wallet',
        id: txId,
      );
      return;
    }

    if (kind == 'wallet_topup' ||
        route == 'wallet_topup_details' ||
        route == '/wallet/topups' ||
        (topUpId.isNotEmpty && route.contains('wallet_topup')) ||
        (type == 'PAYMENT' && topUpId.isNotEmpty)) {
      state = PendingNotificationRoute(kind: 'wallet_topup', id: topUpId);
      return;
    }

    final conversationId =
        (normalized['conversationId'] ?? normalized['conversation_id'] ?? '')
            .trim();
    final orderId =
        (normalized['orderId'] ?? normalized['order_id'] ?? '').trim();
    if (conversationId.isNotEmpty) {
      final rawChatType =
          (normalized['chatType'] ?? normalized['chat_type'] ?? '')
              .trim()
              .toUpperCase();
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
