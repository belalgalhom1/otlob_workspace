import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import '../../providers.dart';

part 'shared_inbox_provider.g.dart';

class InboxState {
  final List<Map<String, dynamic>> conversations;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  InboxState({
    this.conversations = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  InboxState copyWith({
    List<Map<String, dynamic>>? conversations,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return InboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error ?? this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class SharedInbox extends _$SharedInbox {
  @override
  InboxState build() {
    Future.microtask(() async {
      if (!ref.mounted) return;
      // Ensure the socket is connected before subscribing to events
      final socket = ref.read(coreSocketServiceProvider);
      await socket.init();
      if (!ref.mounted) return;
      _fetchConversations();
    });

    final socket = ref.read(coreSocketServiceProvider);
    final sub = socket
        .onEvent(SocketEvent.chatMessage)
        .listen(_onRealtimeEvent);
    final readSub = socket
        .onEvent(SocketEvent.chatRead)
        .listen(_onRealtimeEvent);

    ref.onDispose(() {
      sub.cancel();
      readSub.cancel();
    });

    return InboxState(isLoading: true);
  }

  void _onRealtimeEvent(dynamic data) {
    if (!ref.mounted) return;
    // When a new message comes in, refresh the inbox
    _fetchConversations(1, true); // true = silent refresh
  }

  Future<void> _fetchConversations([int page = 1, bool silent = false]) async {
    if (!ref.mounted) return;

    if (!silent) {
      if (page == 1) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          hasMore: true,
          page: 1,
        );
      } else {
        state = state.copyWith(isLoading: true, error: null);
      }
    }

    try {
      if (!ref.mounted) return;
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final response = await chatRepo.getConversations(page: page, limit: 20);

      if (!ref.mounted) return;

      if (response != null) {
        List<Map<String, dynamic>> convos = [];
        bool hasMore = false;

        // Handle direct response (ResponseParser already stripped { success, data })
        if (response is Map && response['conversations'] is List) {
          convos = List<Map<String, dynamic>>.from(response['conversations']);
          final currentPage = (response['page'] as num?)?.toInt() ?? page;
          final totalPages = (response['totalPages'] as num?)?.toInt() ?? 1;
          hasMore = currentPage < totalPages;
        }
        // Handle unstripped fallback
        else if (response is Map && response['data'] != null) {
          final data = response['data'];
          if (data is Map && data['conversations'] is List) {
            convos = List<Map<String, dynamic>>.from(data['conversations']);
            final currentPage = (data['page'] as num?)?.toInt() ?? page;
            final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
            hasMore = currentPage < totalPages;
          } else if (data is List) {
            convos = List<Map<String, dynamic>>.from(data);
            hasMore = convos.length == 20;
          }
        }
        // Handle plain list
        else if (response is List) {
          convos = List<Map<String, dynamic>>.from(response);
          hasMore = convos.length == 20;
        }

        if (!ref.mounted) return;

        if (page == 1) {
          _sortConversations(convos);
          state = state.copyWith(
            conversations: convos,
            isLoading: false,
            hasMore: hasMore,
            page: page,
          );
        } else {
          final allConvos = [...state.conversations, ...convos];
          _sortConversations(allConvos);
          state = state.copyWith(
            conversations: allConvos,
            isLoading: false,
            hasMore: hasMore,
            page: page,
          );
        }
      } else {
        if (!ref.mounted) return;
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e, stack) {
      if (!ref.mounted) return;
      debugPrint('SharedInbox fetch error: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.fromError(e),
      );
    }
  }

  void _sortConversations(List<Map<String, dynamic>> convos) {
    convos.sort((a, b) {
      final timeA = a['lastMessage']?['createdAt'] != null
          ? DateTime.parse(a['lastMessage']['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b['lastMessage']?['createdAt'] != null
          ? DateTime.parse(b['lastMessage']['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA); // newest first
    });
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    await _fetchConversations(1);
  }

  Future<void> loadMore() async {
    if (!ref.mounted) return;
    if (state.isLoading || !state.hasMore) return;
    await _fetchConversations(state.page + 1);
  }
}
