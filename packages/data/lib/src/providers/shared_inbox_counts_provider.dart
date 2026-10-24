import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import '../../providers.dart';

class InboxCountsState {
  final int chatUnread;
  final int notificationsUnread;
  final int totalUnread;

  const InboxCountsState({
    this.chatUnread = 0,
    this.notificationsUnread = 0,
    this.totalUnread = 0,
  });

  InboxCountsState copyWith({
    int? chatUnread,
    int? notificationsUnread,
    int? totalUnread,
  }) {
    return InboxCountsState(
      chatUnread: chatUnread ?? this.chatUnread,
      notificationsUnread: notificationsUnread ?? this.notificationsUnread,
      totalUnread: totalUnread ?? this.totalUnread,
    );
  }
}

class SharedInboxCountsNotifier extends Notifier<InboxCountsState> {
  StreamSubscription? _msgSub;
  StreamSubscription? _readSub;
  StreamSubscription? _closedSub;
  StreamSubscription? _notifSub;

  @override
  InboxCountsState build() {
    Future.microtask(() async {
      final tokenService = ref.read(tokenServiceProvider);
      if (await tokenService.hasSession()) {
        fetchCounts();
      }
    });

    final socket = ref.read(coreSocketServiceProvider);
    _msgSub = socket.onEvent(SocketEvent.chatMessage).listen((_) async {
      final tokenService = ref.read(tokenServiceProvider);
      if (await tokenService.hasSession()) fetchCounts();
    });
    _readSub = socket.onEvent(SocketEvent.chatRead).listen((_) async {
      final tokenService = ref.read(tokenServiceProvider);
      if (await tokenService.hasSession()) fetchCounts();
    });
    _closedSub = socket.onEvent(SocketEvent.conversationClosed).listen((_) async {
      final tokenService = ref.read(tokenServiceProvider);
      if (await tokenService.hasSession()) fetchCounts();
    });
    _notifSub = socket.onEvent(SocketEvent.notificationNew).listen((_) async {
      final tokenService = ref.read(tokenServiceProvider);
      if (await tokenService.hasSession()) fetchCounts();
    });

    ref.onDispose(() {
      _msgSub?.cancel();
      _readSub?.cancel();
      _closedSub?.cancel();
      _notifSub?.cancel();
    });

    return const InboxCountsState();
  }

  void clear() {
    state = const InboxCountsState();
  }

  Future<void> fetchCounts() async {
    final tokenService = ref.read(tokenServiceProvider);
    if (!await tokenService.hasSession()) {
      state = const InboxCountsState();
      return;
    }
    try {
      final repo = ref.read(sharedInboxRepositoryProvider);
      final res = await repo.getCounts();
      final data = res is Map && res['data'] != null ? res['data'] : res;
      if (data is Map) {
        state = InboxCountsState(
          chatUnread: (data['chat'] as num?)?.toInt() ?? 0,
          notificationsUnread: (data['notifications'] as num?)?.toInt() ?? 0,
          totalUnread: (data['total'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch inbox counts: $e');
    }
  }

  Future<void> refresh() => fetchCounts();
}

final sharedInboxCountsProvider =
    NotifierProvider<SharedInboxCountsNotifier, InboxCountsState>(() {
  return SharedInboxCountsNotifier();
});

final inboxCountsProvider = sharedInboxCountsProvider;

