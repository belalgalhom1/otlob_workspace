import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:data/providers.dart' show sharedChatRepositoryProvider;
import '../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
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
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.authenticated) {
        _fetchCounts();
      } else if (next == AuthStatus.unauthenticated) {
        state = InboxCountsState();
      }
    });

    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(() => _fetchCounts());
    }

    // Typed broadcast streams: survive socket re-auth (legacy socket.on
    // bindings die with the old socket instance).
    final socket = ref.read(socketServiceProvider);
    final chatSub =
        socket.onEvent(SocketEvent.chatMessage.eventName).listen(_onRealtimeEvent);
    final readSub =
        socket.onEvent(SocketEvent.chatRead.eventName).listen(_onRealtimeEvent);
    final createdSub = socket
        .onEvent(SocketEvent.conversationCreated.eventName)
        .listen(_onRealtimeEvent);
    final closedSub = socket
        .onEvent(SocketEvent.conversationClosed.eventName)
        .listen(_onRealtimeEvent);
    final notifSub = socket
        .onEvent(SocketEvent.notificationNew.eventName)
        .listen(_onRealtimeEvent);
    final connectSub = socket.onConnect.listen(_onRealtimeEvent);

    ref.onDispose(() {
      chatSub.cancel();
      readSub.cancel();
      createdSub.cancel();
      closedSub.cancel();
      notifSub.cancel();
      connectSub.cancel();
    });

    return InboxCountsState();
  }

  void _onRealtimeEvent(dynamic data) {
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus != AuthStatus.authenticated) {
      state = InboxCountsState();
      return;
    }
    try {
      final result = await ref.read(sharedChatRepositoryProvider).getInboxCounts();
      if (result is Map) {
        state = InboxCountsState(
          chatUnread: (result['chat'] as num?)?.toInt() ?? 0,
          notificationsUnread: (result['notifications'] as num?)?.toInt() ?? 0,
          totalUnread: (result['total'] as num?)?.toInt() ?? 0,
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
