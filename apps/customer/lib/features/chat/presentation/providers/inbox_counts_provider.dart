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
    
    // Listen to real-time events to refresh counts
    final socket = ref.read(socketServiceProvider);
    socket.on('chat.message', _onRealtimeEvent);
    socket.on('notification.new', _onRealtimeEvent);
    
    ref.onDispose(() {
      socket.off('chat.message', _onRealtimeEvent);
      socket.off('notification.new', _onRealtimeEvent);
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
