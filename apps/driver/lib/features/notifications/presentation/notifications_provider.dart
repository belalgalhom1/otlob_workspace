import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';

import 'package:core/core.dart';

part 'notifications_provider.g.dart';

@riverpod
class DriverNotifications extends _$DriverNotifications {
  @override
  AsyncValue<List<dynamic>> build() {
    _fetchNotifications();

    final socket = ref.read(coreSocketServiceProvider);
    final sub = socket.onEvent(SocketEvent.notificationNew).listen((_) {
      _fetchNotifications();
    });

    ref.onDispose(() {
      sub.cancel();
    });

    return const AsyncValue.loading();
  }

  Future<void> _fetchNotifications() async {
    try {
      final repo = ref.read(sharedNotificationsRepositoryProvider);
      final res = await repo.list(page: 1, limit: 50);
      List<dynamic> notifications = [];
      if (res is List) {
        notifications = res;
      } else if (res is Map) {
        if (res['notifications'] is List) {
          notifications = res['notifications'] as List<dynamic>;
        } else if (res['data'] is List) {
          notifications = res['data'] as List<dynamic>;
        } else if (res['data'] is Map && res['data']['notifications'] is List) {
          notifications = res['data']['notifications'] as List<dynamic>;
        }
      }
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    final prev = state;
    try {
      final repo = ref.read(sharedNotificationsRepositoryProvider);
      await repo.markOneRead(id);
      await _fetchNotifications();
      ref.read(inboxCountsProvider.notifier).refresh();
    } catch (e) {
      if (prev.hasValue) {
        state = prev;
      }
    }
  }

  Future<void> markAllAsRead() async {
    final prev = state;
    try {
      final repo = ref.read(sharedNotificationsRepositoryProvider);
      await repo.markRead();
      await _fetchNotifications();
      ref.read(inboxCountsProvider.notifier).refresh();
    } catch (e) {
      if (prev.hasValue) {
        state = prev;
      }
    }
  }
}
