import 'dart:async';
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
  Timer? _realtimeDebounce;
  bool _isFetchingPage1 = false;
  bool _pendingSilentRefresh = false;

  @override
  InboxState build() {
    Future.microtask(() async {
      if (!ref.mounted) return;
      final tokenService = ref.read(tokenServiceProvider);
      if (!await tokenService.hasSession()) {
        state = InboxState(isLoading: false);
        return;
      }
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
    final createdSub = socket
        .onEvent(SocketEvent.conversationCreated)
        .listen(_onRealtimeEvent);
    final closedSub = socket
        .onEvent(SocketEvent.conversationClosed)
        .listen(_onConversationClosed);

    ref.onDispose(() {
      _realtimeDebounce?.cancel();
      sub.cancel();
      readSub.cancel();
      createdSub.cancel();
      closedSub.cancel();
    });

    return InboxState(isLoading: true);
  }

  void clear() {
    _realtimeDebounce?.cancel();
    state = InboxState();
  }

  void _onRealtimeEvent(dynamic data) {
    if (!ref.mounted) return;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!ref.mounted) return;
      final tokenService = ref.read(tokenServiceProvider);
      if (!await tokenService.hasSession()) return;
      _fetchConversations(1, true);
    });
  }

  void _onConversationClosed(dynamic data) {
    if (!ref.mounted) return;
    final closedId = data is Map ? data['conversationId']?.toString() : null;
    if (closedId != null && closedId.isNotEmpty) {
      state = state.copyWith(
        conversations: state.conversations
            .where((c) => c['id']?.toString() != closedId)
            .toList(),
      );
    }
    _onRealtimeEvent(data);
  }

  Future<void> _fetchConversations([int page = 1, bool silent = false]) async {
    if (!ref.mounted) return;
    if (page == 1 && _isFetchingPage1) {
      if (silent) _pendingSilentRefresh = true;
      return;
    }
    if (page == 1) _isFetchingPage1 = true;
    try {
      await _performFetchConversations(page, silent);
    } finally {
      if (page == 1) {
        _isFetchingPage1 = false;
        if (_pendingSilentRefresh && ref.mounted) {
          _pendingSilentRefresh = false;
          unawaited(_fetchConversations(1, true));
        }
      }
    }
  }

  Future<void> _performFetchConversations([
    int page = 1,
    bool silent = false,
  ]) async {
    if (!ref.mounted) return;
    final tokenService = ref.read(tokenServiceProvider);
    if (!await tokenService.hasSession()) {
      if (ref.mounted) {
        state = InboxState(isLoading: false);
      }
      return;
    }

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
      final currentUserId = await tokenService.getUserId();
      if (!ref.mounted) return;
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final response = await chatRepo.getConversations(page: page, limit: 20);

      if (!ref.mounted) return;

      if (response != null) {
        List<Map<String, dynamic>> convos = [];
        bool hasMore = false;

        // Handle direct response (ResponseParser already stripped { success, data })
        if (response is Map && response['conversations'] is List) {
          convos = (response['conversations'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final currentPage = (response['page'] as num?)?.toInt() ?? page;
          final totalPages = (response['totalPages'] as num?)?.toInt() ?? 1;
          hasMore = currentPage < totalPages;
        }
        // Handle unstripped fallback
        else if (response is Map && response['data'] != null) {
          final data = response['data'];
          if (data is Map && data['conversations'] is List) {
            convos = (data['conversations'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            final currentPage = (data['page'] as num?)?.toInt() ?? page;
            final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
            hasMore = currentPage < totalPages;
          } else if (data is List) {
            convos = data
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            hasMore = convos.length == 20;
          }
        }
        // Handle plain list
        else if (response is List) {
          convos = response
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          hasMore = convos.length == 20;
        }

        if (!ref.mounted) return;

        // Enrich SUPPORT conversations with ticket metadata (ticketNumber, subject, etc.)
        // Only fall back to getMyTickets() if a SUPPORT conversation is missing inline supportTicket/ticketId.
        final needsTicketFetch = convos.any(
          (c) =>
              (c['type']?.toString().toUpperCase() ?? '') == 'SUPPORT' &&
              c['ticketId'] == null &&
              c['supportTicket'] == null,
        );
        Map<String, Map<String, dynamic>> ticketByConvoId = {};
        if (needsTicketFetch) {
          try {
            final ticketsRes =
                await ref.read(sharedTicketsRepositoryProvider).getMyTickets();
            List<dynamic> rawTickets = [];
            if (ticketsRes is List) {
              rawTickets = ticketsRes;
            } else if (ticketsRes is Map) {
              if (ticketsRes['tickets'] is List) {
                rawTickets = ticketsRes['tickets'] as List;
              } else if (ticketsRes['data'] is List) {
                rawTickets = ticketsRes['data'] as List;
              } else if (ticketsRes['data'] is Map &&
                  ticketsRes['data']['tickets'] is List) {
                rawTickets = ticketsRes['data']['tickets'] as List;
              }
            }
            for (final t in rawTickets) {
              if (t is Map) {
                final cId = t['conversationId']?.toString();
                if (cId != null && cId.isNotEmpty) {
                  ticketByConvoId[cId] = Map<String, dynamic>.from(t);
                }
              }
            }
          } catch (_) {
            // Non-fatal if tickets endpoint is unavailable for a role
          }
        }

        if (!ref.mounted) return;

        for (final c in convos) {
          final convoId = c['id']?.toString();
          if (convoId != null && ticketByConvoId.containsKey(convoId)) {
            final ticket = ticketByConvoId[convoId]!;
            c['ticketId'] ??= ticket['id'];
            c['ticketNumber'] ??= ticket['ticketNumber'];
            c['subject'] ??= ticket['subject'];
            c['ticketStatus'] ??= ticket['status'];
            c['ticketCategory'] ??= ticket['category'];
            c['ticketSubCategory'] ??= ticket['subCategory'];
            if (c['order'] == null && ticket['order'] != null) {
              c['order'] = ticket['order'];
            }
            if (c['orderId'] == null && ticket['orderId'] != null) {
              c['orderId'] = ticket['orderId'];
            }
            if (c['assignee'] == null && ticket['assignee'] != null) {
              c['assignee'] = ticket['assignee'];
            }
          }

          if (c['unreadCount'] == null) {
            final lastMsg = c['lastMessage'];
            if (lastMsg is Map) {
              final senderId = lastMsg['senderId']?.toString();
              final createdAtStr = lastMsg['createdAt']?.toString();
              final myLastReadAtStr = c['myLastReadAt']?.toString();
              if (senderId != null &&
                  currentUserId != null &&
                  senderId == currentUserId) {
                c['unreadCount'] = 0;
              } else if (createdAtStr != null) {
                final msgTime = DateTime.tryParse(createdAtStr);
                if (myLastReadAtStr == null || myLastReadAtStr.isEmpty) {
                  c['unreadCount'] = msgTime != null ? 1 : 0;
                } else {
                  final readTime = DateTime.tryParse(myLastReadAtStr);
                  c['unreadCount'] = (msgTime != null &&
                          readTime != null &&
                          msgTime.isAfter(readTime))
                      ? 1
                      : 0;
                }
              } else {
                c['unreadCount'] = 0;
              }
            } else {
              c['unreadCount'] = 0;
            }
          }
        }

        if (page == 1) {
          _sortConversations(convos);
          state = state.copyWith(
            conversations: convos,
            isLoading: false,
            hasMore: hasMore,
            page: page,
          );
        } else {
          final byId = <String, Map<String, dynamic>>{};
          for (final existing in state.conversations) {
            final k = existing['id']?.toString() ?? '';
            if (k.isNotEmpty) byId[k] = existing;
          }
          for (final incoming in convos) {
            final k = incoming['id']?.toString() ?? '';
            if (k.isNotEmpty) byId[k] = incoming;
          }
          final allConvos = byId.values.toList();
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

  DateTime _extractConversationTime(Map<String, dynamic> c) {
    final lastMsgTime = c['lastMessage'] is Map
        ? c['lastMessage']['createdAt']
        : null;
    final raw = lastMsgTime ?? c['updatedAt'] ?? c['createdAt'];
    if (raw != null) {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _sortConversations(List<Map<String, dynamic>> convos) {
    convos.sort((a, b) {
      final timeA = _extractConversationTime(a);
      final timeB = _extractConversationTime(b);
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
