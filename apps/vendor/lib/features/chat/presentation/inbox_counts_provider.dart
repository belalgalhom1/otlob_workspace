import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
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
    
    // Listen to real-time events to refresh counts
    final socket = ref.read(socketServiceProvider);
    final sub1 = socket.onEvent(SocketEvent.chatMessage).listen(_onRealtimeEvent);
    final sub2 = socket.onEvent(SocketEvent.notificationNew).listen(_onRealtimeEvent);
    
    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
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
      debugPrint('Failed to fetch vendor inbox counts: $e');
    }
  }

  Future<void> refresh() async {
    await _fetchCounts();
  }
}
