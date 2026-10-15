import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import 'package:flutter/foundation.dart';

part 'notifications_provider.g.dart';

class NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error, // Can be null to clear
    );
  }
}

@riverpod
class Notifications extends _$Notifications {
  @override
  NotificationsState build() {
    Future.microtask(() => _fetchNotifications(1));
    
    final socket = ref.read(socketServiceProvider);
    final sub = socket.onEvent(SocketEvent.notificationNew).listen(_onRealtimeEvent);
    
    ref.onDispose(() {
      sub.cancel();
    });

    return NotificationsState(isLoading: true);
  }

  DateTime? _lastRealtimeFetch;

  void _onRealtimeEvent(dynamic data) {
    // Coalesce event bursts: one refresh per 2s window at most.
    final now = DateTime.now();
    if (_lastRealtimeFetch != null &&
        now.difference(_lastRealtimeFetch!).inMilliseconds < 2000) {
      return;
    }
    _lastRealtimeFetch = now;
    _fetchNotifications(1); // Refresh from top
  }

  Future<void> _fetchNotifications(int page) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true); // background load more
    }
    
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/notifications?page=$page&limit=20');
      
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        List<Map<String, dynamic>> notifs = [];
        
        if (data is Map && data['notifications'] is List) {
           notifs = List<Map<String, dynamic>>.from(data['notifications']);
        } else if (data is List) {
           notifs = List<Map<String, dynamic>>.from(data);
        }
        
        final hasMore = notifs.length == 20;
        
        if (page == 1) {
          state = state.copyWith(
            notifications: notifs,
            isLoading: false,
            hasMore: hasMore,
            page: 1,
          );
        } else {
          state = state.copyWith(
            notifications: [...state.notifications, ...notifs],
            isLoading: false,
            hasMore: hasMore,
            page: page,
          );
        }
      } else {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiErrorMapper.fromError(e));
    }
  }

  Future<void> refresh() async {
    await _fetchNotifications(1);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _fetchNotifications(state.page + 1);
  }

  Future<void> markAsRead(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/notifications/$id/read');
      
      final updated = state.notifications.map((n) {
        if (n['id'] == id) {
          return {...n, 'isRead': true};
        }
        return n;
      }).toList();
      
      state = state.copyWith(notifications: updated);
    } catch (e) {
      debugPrint('Failed to mark read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/notifications/read', data: {});
      
      final updated = state.notifications.map((n) {
        return {...n, 'isRead': true};
      }).toList();
      
      state = state.copyWith(notifications: updated);
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    // Optimistic delete with rollback on failure.
    final previous = state.notifications;
    final index = previous.indexWhere((n) => n['id'] == id);
    state = state.copyWith(
      notifications: previous.where((n) => n['id'] != id).toList(),
    );

    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/notifications/$id');
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
      final restored = List<Map<String, dynamic>>.from(state.notifications);
      if (index >= 0 && index <= restored.length) {
        restored.insert(index, previous[index]);
      } else if (index >= 0) {
        restored.add(previous[index]);
      }
      state = state.copyWith(notifications: restored);
      rethrow;
    }
  }
}
