import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import '../../../../core/services/socket_service.dart';
import 'package:flutter/foundation.dart';

part 'inbox_counts_provider.g.dart';

class InboxCountsState {
  final int chatUnread;
  final int notificationsUnread;
  final int totalUnread;

  InboxCountsState({
    this.chatUnread = 0,
    this.notificationsUnread = 0,
    this.totalUnread = 0,
  });
}

@Riverpod(keepAlive: true)
class InboxCounts extends _$InboxCounts {
  @override
  InboxCountsState build() {
    Future.microtask(() => _fetchCounts());

    // Typed broadcast streams: survive socket re-auth (legacy socket.on
    // bindings die with the old socket instance).
    final socket = ref.read(socketServiceProvider);
    final chatSub =
        socket.onEvent('chat.message').listen(_onRealtimeEvent);
    final notifSub =
        socket.onEvent('notification.new').listen(_onRealtimeEvent);

    ref.onDispose(() {
      chatSub.cancel();
      notifSub.cancel();
    });

    return InboxCountsState();
  }

  void _onRealtimeEvent(dynamic data) {
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/inbox/counts');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        state = InboxCountsState(
          chatUnread: data['chat'] ?? 0,
          notificationsUnread: data['notifications'] ?? 0,
          totalUnread: data['total'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch inbox counts: $e');
    }
  }

  Future<void> refresh() async {
    await _fetchCounts();
  }
}
