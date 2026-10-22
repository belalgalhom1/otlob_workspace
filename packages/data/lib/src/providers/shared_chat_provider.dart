import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';

part 'shared_chat_provider.g.dart';

class SharedChatArgs {
  final String id; // vendorId, orderId, or conversationId
  final String type; // 'vendor', 'order', 'support', 'direct'

  SharedChatArgs({required this.id, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedChatArgs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

@Riverpod(keepAlive: true)
class SharedChat extends _$SharedChat {
  String? _conversationId;
  String? _currentUserId;
  final List<Message> _earlyMessages = [];
  bool hasMore = true;
  String? nextCursor;
  bool isLoadingMore = false;

  @override
  Future<List<Message>> build(SharedChatArgs args) async {
    final tokenService = ref.read(tokenServiceProvider);
    _currentUserId = await tokenService.getUserId();

    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);

      dynamic conversation;
      if (args.type == 'vendor') {
        conversation = await chatRepo.createVendorConversation(args.id);
      } else if (args.type == 'order') {
        try {
          conversation = await chatRepo.createOrderConversation(args.id);
        } catch (_) {
          conversation = await chatRepo.getConversation(args.id);
        }
      } else if (args.type == 'support' && (args.id.isEmpty || args.id == '0')) {
        conversation = await chatRepo.createSupportConversation();
      } else {
        conversation = await chatRepo.getConversation(args.id);
      }

      final conversationData =
          conversation is Map && conversation.containsKey('data')
          ? conversation['data']
          : conversation;
      _conversationId = conversationData['id'];

      final socket = ref.read(coreSocketServiceProvider);
      await socket.init();

      final sub = socket
          .onEvent(SocketEvent.chatMessage)
          .listen(_onSocketMessage);

      final readSub = socket
          .onEvent(SocketEvent.chatRead)
          .listen(_onSocketRead);

      final closedSub = socket
          .onEvent(SocketEvent.conversationClosed)
          .listen(_onSocketClosed);

      ref.onDispose(() {
        sub.cancel();
        readSub.cancel();
        closedSub.cancel();
      });

      final fetchedMessages = await _fetchMessages();

      final combined = [..._earlyMessages, ...fetchedMessages];
      _earlyMessages.clear();

      final unique = <String, Message>{};
      for (var m in combined) {
        unique[m.id] = m;
      }
      final result = unique.values.toList();
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return result;
    } catch (e) {
      print('SharedChat init error: $e');
      rethrow;
    }
  }

  void _onSocketClosed(dynamic data) {
    if (data is Map && data['conversationId'] == _conversationId) {
      state = AsyncError('CHAT_CONVERSATION_CLOSED', StackTrace.current);
    }
  }

  void _onSocketMessage(dynamic data) {
    if (data['conversationId'] == _conversationId) {
      final content = data['text'] ?? '';
      bool isMe = data['senderId']?.toString() == _currentUserId?.toString();
      String senderName = data['senderName'] ?? 'Unknown';
      String? senderRole = data['senderRole'];

      final newMessage = Message(
        id: data['messageId'],
        content: content,
        type: _mapMessageType(data['type']),
        isMe: isMe,
        timestamp: DateTime.parse(data['createdAt']),
        senderName: senderName,
        senderRole: senderRole,
        mediaUrl: _getFullUrl(data['mediaUrl']),
        metadata: data['metadata'],
      );

      _addRealtimeMessage(newMessage);
    }
  }

  void _onSocketRead(dynamic data) {
    if (data is Map && data['conversationId'] == _conversationId) {
      final lastReadAtStr = data['lastReadAt'];
      final lastReadAt = lastReadAtStr != null
          ? DateTime.tryParse(lastReadAtStr.toString())
          : null;
      final lastReadMessageId = data['lastReadMessageId'];
      final readerUserId = data['userId']?.toString();

      if (readerUserId != _currentUserId) {
        state.whenData((messages) {
          final updated = messages.map((m) {
            if (!m.isMe || m.isRead) return m;
            if (lastReadMessageId != null && m.id == lastReadMessageId) {
              return m.copyWith(isRead: true);
            }
            if (lastReadAt != null && !m.timestamp.isAfter(lastReadAt)) {
              return m.copyWith(isRead: true);
            }
            return m;
          }).toList();
          state = AsyncData(updated);
        });
      }
    }
  }

  void _addRealtimeMessage(Message message) {
    if (state.isLoading) {
      _earlyMessages.add(message);
      return;
    }
    state.whenData((messages) {
      if (messages.any((m) => m.id == message.id)) return;

      final filteredMessages = messages.where((m) {
        if (!m.id.startsWith('temp-') && !m.id.startsWith('upload-')) {
          return true;
        }
        if (!message.isMe) return true;
        if (message.mediaUrl != null && m.mediaUrl == message.mediaUrl) {
          return false;
        }
        if (message.content.isNotEmpty && m.content == message.content) {
          return false;
        }
        return true;
      }).toList();

      state = AsyncData([message, ...filteredMessages]);
    });
  }

  Future<List<Message>> _fetchMessages({String? cursor}) async {
    if (_conversationId == null) return [];

    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final response = await chatRepo.getMessages(_conversationId!, before: cursor);

      List<dynamic> data = [];
      if (response is Map) {
        if (response.containsKey('hasMore')) {
          hasMore = response['hasMore'] == true;
        }
        if (response.containsKey('nextCursor')) {
          nextCursor = response['nextCursor'];
        }
      }
      if (response is List) {
        data = response;
      } else if (response is Map && response.containsKey('messages')) {
        data = response['messages'];
      } else if (response is Map && response.containsKey('data')) {
        final resData = response['data'];
        if (resData is Map && resData.containsKey('messages')) {
          data = resData['messages'];
        } else if (resData is List) {
          data = resData;
        }
      }

      final ordered = data.map((m) {
        final mapData = Map<String, dynamic>.from(m as Map);
        final content = mapData['text'] ?? '';
        final sender = mapData['sender'] as Map?;
        final senderId = sender?['id'];

        bool isMe = senderId == _currentUserId;
        String senderName = sender?['name'] ?? 'Unknown';
        String? senderRole = sender?['role'];

        return Message(
          id: mapData['id'] ?? '',
          content: content,
          type: _mapMessageType(mapData['type']),
          isMe: isMe,
          timestamp: mapData['createdAt'] != null
              ? DateTime.parse(mapData['createdAt'])
              : DateTime.now(),
          senderName: senderName,
          senderRole: senderRole,
          mediaUrl: _getFullUrl(mapData['mediaUrl']),
          metadata: mapData['metadata'],
          isRead: mapData['isRead'] == true,
        );
      }).toList();

      try {
        if (ordered.isNotEmpty) {
          final messageIds = ordered.map((m) => m.id).toList();
          await chatRepo.markAsRead(_conversationId!, messageIds);
        }
      } catch (_) {}

      return ordered.reversed.toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore || _conversationId == null) return;
    isLoadingMore = true;

    try {
      final oldMessages = await _fetchMessages(cursor: nextCursor);
      if (oldMessages.isNotEmpty) {
        state.whenData((currentMessages) {
          state = AsyncData([...currentMessages, ...oldMessages]);
        });
      }
    } finally {
      isLoadingMore = false;
    }
  }

  String? _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    // Assuming dioProvider is available in core
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBaseUrl$cleanPath';
  }

  MessageType _mapMessageType(String? type) {
    switch (type?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'AUDIO':
        return MessageType.audio;
      case 'FILE':
        return MessageType.file;
      case 'LOCATION':
        return MessageType.location;
      case 'SYSTEM':
        return MessageType.system;
      case 'PRODUCT':
        return MessageType.product;
      default:
        return MessageType.text;
    }
  }

  Future<String?> uploadMedia(String filePath) async {
    if (_conversationId == null) return null;
    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final responseData = await chatRepo.uploadMedia(
        _conversationId!,
        filePath,
      );
      String? url;
      if (responseData is Map) {
        if (responseData['data'] != null &&
            responseData['data'] is Map &&
            responseData['data']['url'] != null) {
          url = responseData['data']['url'];
        } else if (responseData['url'] != null) {
          url = responseData['url'];
        }
      }
      return _getFullUrl(url);
    } catch (e) {
      return null;
    }
  }

  Future<void> sendMedia(String filePath, MessageType type) async {
    if (_conversationId == null) return;

    final tempId = 'upload-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      content: 'Uploading...',
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
      mediaUrl: null,
    );

    state.whenData((messages) {
      state = AsyncData([optimisticMessage, ...messages]);
    });

    final mediaUrl = await uploadMedia(filePath);
    if (mediaUrl != null) {
      await sendMessage(
        '',
        type: type,
        mediaUrl: mediaUrl,
        tempIdToRemove: tempId,
      );
    } else {
      state.whenData((messages) {
        state = AsyncData(messages.where((m) => m.id != tempId).toList());
      });
    }
  }

  Future<void> sendMessage(
    String content, {
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? tempIdToRemove,
  }) async {
    if (_conversationId == null) return;
    final tempId =
        tempIdToRemove ?? 'temp-${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMessage = Message(
      id: tempId,
      content: content,
      type: type,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: 'Me',
      mediaUrl: mediaUrl,
    );

    state.whenData((messages) {
      final filtered = messages.where((m) => m.id != tempIdToRemove).toList();
      state = AsyncData([optimisticMessage, ...filtered]);
    });

    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      await chatRepo.sendMessage(
        _conversationId!,
        content.isEmpty ? '' : content,
        type: type.name.toUpperCase(),
        mediaUrl: mediaUrl,
      );
      // Socket echo from backend will update state via _onSocketMessage.
      // We only replace the temp message with the real one when the socket
      // event comes back, so no full re-fetch is needed here.
    } catch (e) {
      // On failure, remove the optimistic message so the user knows it failed.
      state.whenData((messages) {
        state = AsyncData(messages.where((m) => m.id != tempId).toList());
      });
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final oldState = state;
    if (!state.hasValue || _conversationId == null) return;

    try {
      final repository = ref.read(sharedChatRepositoryProvider);
      // Backend updateMessage DTO uses 'text', not 'content'
      await repository.updateMessage(_conversationId!, messageId, {
        'text': newContent,
      });

      final currentMsgs = List<Message>.from(state.value ?? []);
      final index = currentMsgs.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMsgs[index] = currentMsgs[index].copyWith(content: newContent);
        state = AsyncValue.data(currentMsgs);
      }
    } catch (e) {
      state = oldState;
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_conversationId == null) return;
    state.whenData((messages) {
      state = AsyncData(messages.where((m) => m.id != messageId).toList());
    });
    if (messageId.startsWith('temp-') || messageId.startsWith('upload-')) {
      return;
    }
    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      await chatRepo.deleteMessage(_conversationId!, messageId);
    } catch (e) {
      // ignore
    }
  }
}
