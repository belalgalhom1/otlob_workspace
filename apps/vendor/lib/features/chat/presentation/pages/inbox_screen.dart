import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/chat/presentation/pages/admin_chat_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/providers.dart';
import '../inbox_counts_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    Future.microtask(() => ref.read(sharedInboxProvider.notifier).refresh());
    _setupSocket();
  }

  StreamSubscription<dynamic>? _messageSubscription;

  void _setupSocket() {
    Future.microtask(() async {
      await ref.read(socketServiceProvider).init();
      _messageSubscription = ref
          .read(socketServiceProvider)
          .onEvent(SocketEvent.chatMessage)
          .listen((data) {
            if (mounted) {
              ref.read(sharedInboxProvider.notifier).refresh();
            }
          });
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await ref.read(sharedAuthRepositoryProvider).getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(sharedInboxProvider);
        
        if (state.isLoading && state.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state.error != null && state.conversations.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.failedWithError(state.error.toString())));
        }

        final conversations = state.conversations
            .where((c) {
              if (c['type'] == 'SUPPORT') return false;
              if (_currentUserId == null) return true;
              final participants = c['participants'] as List? ?? [];
              
              // If the current user is a participant, show it
              if (participants.any((p) => p['userId'] == _currentUserId)) return true;
              
              // If they are not a participant, only show it if NO OTHER vendor member has claimed it
              final hasOtherVendorMember = participants.any((p) {
                final user = p['user'];
                if (user == null) return false;
                final roles = user['roles'] as List? ?? [];
                return roles.contains('VENDOR_MEMBER') || roles.contains('ADMIN') || roles.contains('SUPER_ADMIN');
              });
              
              return !hasOtherVendorMember;
            })
            .toList();
            
        if (conversations.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.separated(
          itemCount: conversations.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Theme.of(context).dividerColor),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(conversation);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 64,
            
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noConversationsYet,
            style: const TextStyle(
              fontSize: 18,
              
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'] as Map<String, dynamic>?;
    final participants = conversation['participants'] as List<dynamic>? ?? [];

    final creator = conversation['creator'] as Map<String, dynamic>?;

    // Find the target (the other person in the chat)
    Map<String, dynamic>? target = creator;

    // If I am the creator, look for the other participant
    if (creator?['id'] == _currentUserId) {
      final p = participants.where((p) => p['userId'] != _currentUserId).firstOrNull;
      if (p != null) {
        target = p as Map<String, dynamic>;
      }
    } else if (participants.isNotEmpty) {
      final p = participants.where((p) => p['userId'] != _currentUserId).firstOrNull ?? participants.first;
      target = p as Map<String, dynamic>;
    }

    final targetUser = target?['user'] is Map ? target!['user'] as Map<String, dynamic> : target;
    final String rawName = (targetUser?['name'] ?? target?['name'])?.toString().trim() ?? '';
    final String name = rawName.isNotEmpty ? rawName : AppLocalizations.of(context)!.unknownUser;
    final String? avatar = (targetUser?['avatar'] ?? target?['avatar'])?.toString();
    final String? phoneNumber = (targetUser?['phoneNumber'] ?? target?['phoneNumber'])?.toString();
    final String? vendorName = conversation['vendorName'];
    final String lastMsgText = lastMessage != null
        ? lastMessage['text'] ?? AppLocalizations.of(context)!.media
        : AppLocalizations.of(context)!.noMessages;
    final DateTime? lastTime = lastMessage != null && lastMessage['createdAt'] != null
        ? DateTime.parse(lastMessage['createdAt'].toString()).toLocal()
        : null;

    final DateTime? myLastReadAt = conversation['myLastReadAt'] != null
        ? DateTime.parse(conversation['myLastReadAt'].toString()).toLocal()
        : null;

    bool isUnread = false;
    if (lastMessage != null && lastMessage['senderId'] != _currentUserId) {
      if (lastTime != null) {
        if (myLastReadAt == null) {
          isUnread = true;
        } else {
          isUnread = lastTime.isAfter(myLastReadAt);
        }
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => AdminChatScreen(
                  conversationId: conversation['id'].toString(),
                  title: name,
                  avatar: avatar,
                  phoneNumber: phoneNumber,
                  vendorName: vendorName,
                  vendorId: conversation['vendorId']?.toString(),
                  type: conversation['type']?.toString() ?? 'ORDER',
                ),
              ),
            )
            .then((_) {
              ref.read(sharedInboxProvider.notifier).refresh();
              ref.read(inboxCountsProvider.notifier).refresh();
            });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.03) : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar Section
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnread ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? NetworkImage(ImageUtils.formatImageUrl(avatar))
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(
                            (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (lastTime != null)
                        Text(
                          _formatTime(lastTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsgText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (vendorName != null)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vendorName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return TimeFormatter.formatTimeAgo(context, time, short: true);
  }
}


