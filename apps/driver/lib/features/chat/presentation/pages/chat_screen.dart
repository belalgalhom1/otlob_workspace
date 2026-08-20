import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderChatScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  SharedChatArgs get _args => SharedChatArgs(id: widget.orderId, type: 'order');

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(sharedChatProvider(_args).notifier).sendMessage(text);
      _textController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      ref
          .read(sharedChatProvider(_args).notifier)
          .sendMedia(pickedFile.path, MessageType.image);
    }
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;
    var baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:3000';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final path = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(sharedChatProvider(_args));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.orderChat),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(sharedChatProvider(_args)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 40,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.errorOccurred(error.toString()),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(sharedChatProvider(_args)),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text(l10n.noMessagesYet));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest messages at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ChatBubbleWidget(
                      isMe: msg.isMe,
                      senderName: msg.senderName,
                      senderRole: msg.senderRole,
                      mediaUrl: msg.mediaUrl,
                      content: msg.content,
                      type: msg.type.name,
                      time: DateFormat.Hm().format(msg.timestamp.toLocal()),
                      metadata: msg.metadata,
                      uploadingText: 'Uploading...',
                      fileAttachmentText: 'File Attachment',
                      formatImageUrl: _formatImageUrl,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.image,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _pickImage,
            tooltip: 'Send Image',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: IconButton(
              icon: Icon(
                LucideIcons.send,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
