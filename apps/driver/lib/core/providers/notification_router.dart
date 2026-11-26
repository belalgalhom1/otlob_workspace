import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DriverNotificationDestination { wallet, chat, order }

class DriverPendingNotificationRoute {
  final DriverNotificationDestination destination;
  final String? id;
  final String? chatType;
  final String? title;
  final String? topUpId;

  const DriverPendingNotificationRoute({
    required this.destination,
    this.id,
    this.chatType,
    this.title,
    this.topUpId,
  });
}

/// Persists tapped push notifications across cold-start Splash / Auth / Suspended
/// transitions in the Driver App so taps are never dropped while auth settles.
class DriverNotificationRouter
    extends Notifier<DriverPendingNotificationRoute?> {
  @override
  DriverPendingNotificationRoute? build() => null;

  void setRoute(DriverPendingNotificationRoute? route) => state = route;

  void clear() => state = null;

  static bool isWalletPayload(Map<dynamic, dynamic> data) {
    final kind = (data['kind'] ?? '').toString().trim().toLowerCase();
    final route = (data['route'] ?? '').toString().trim().toLowerCase();
    final topUpId = (data['topUpId'] ?? '').toString().trim();
    final type = (data['type'] ?? '').toString().trim().toUpperCase();
    return kind == 'wallet_topup' ||
        route == '/wallet' ||
        route == 'wallet' ||
        topUpId.isNotEmpty ||
        (type == 'PAYMENT' &&
            ((data['requestId'] ?? '').toString().trim().isNotEmpty ||
                route.contains('wallet')));
  }

  /// Parses an FCM / local notification tap payload into a destination.
  /// Wallet adjustments are checked BEFORE order/assist `requestId` checks so
  /// adjustment notifications are never swallowed by the assist-offer branch.
  DriverPendingNotificationRoute? parseTapPayload(Map<dynamic, dynamic> data) {
    if (isWalletPayload(data)) {
      final topUpId =
          (data['topUpId'] ?? data['requestId'] ?? '').toString().trim();
      return DriverPendingNotificationRoute(
        destination: DriverNotificationDestination.wallet,
        topUpId: topUpId.isNotEmpty ? topUpId : null,
      );
    }

    final conversationId = (data['conversationId'] ?? '').toString().trim();
    final orderId = (data['orderId'] ?? '').toString().trim();
    if (conversationId.isNotEmpty) {
      final rawChatType =
          (data['chatType'] ?? data['type'] ?? '').toString().trim().toLowerCase();
      final chatType = (rawChatType == 'order' || rawChatType == 'support')
          ? rawChatType
          : (orderId.isNotEmpty ? 'order' : 'support');
      return DriverPendingNotificationRoute(
        destination: DriverNotificationDestination.chat,
        id: conversationId,
        chatType: chatType,
        title: data['title']?.toString(),
      );
    }

    if (orderId.isNotEmpty) {
      return DriverPendingNotificationRoute(
        destination: DriverNotificationDestination.order,
        id: orderId,
      );
    }

    return null;
  }

  bool handleTap(Map<dynamic, dynamic> data) {
    final parsed = parseTapPayload(data);
    if (parsed == null) return false;
    state = parsed;
    return true;
  }
}

final driverNotificationRouterProvider = NotifierProvider<
  DriverNotificationRouter,
  DriverPendingNotificationRoute?
>(DriverNotificationRouter.new);

class DriverDashboardTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final driverDashboardTabProvider =
    NotifierProvider<DriverDashboardTabNotifier, int>(
      DriverDashboardTabNotifier.new,
    );
