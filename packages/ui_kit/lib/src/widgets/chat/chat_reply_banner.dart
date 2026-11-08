import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';

/// A sleek, elevated banner placed immediately above the message input bar
/// when the user is replying to a specific message.
class ChatReplyBanner extends StatelessWidget {
  final String senderName;
  final String content;
  final String? type;
  final String? mediaUrl;
  final VoidCallback onCancel;
  final String Function(String url)? formatImageUrl;

  const ChatReplyBanner({
    super.key,
    required this.senderName,
    required this.content,
    this.type,
    this.mediaUrl,
    required this.onCancel,
    this.formatImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final displayText = content.isNotEmpty
        ? content
        : _getDefaultTextForType(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left vertical colored accent bar
          Container(
            width: 3.5,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),

          // Reply Icon
          const Icon(
            LucideIcons.reply,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),

          // Sender & snippet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (type != null && type!.toLowerCase() != 'text') ...[
                      Icon(
                        _getTypeIcon(type!),
                        size: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        displayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Optional tiny thumbnail preview
          if (mediaUrl != null && mediaUrl!.isNotEmpty) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: formatImageUrl != null
                    ? formatImageUrl!(mediaUrl!)
                    : mediaUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ],

          // Cancel button
          const SizedBox(width: 4),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(LucideIcons.x, size: 16),
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Cancel reply',
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return LucideIcons.image;
      case 'video':
        return LucideIcons.video;
      case 'audio':
        return LucideIcons.mic;
      case 'file':
        return LucideIcons.fileText;
      case 'location':
        return LucideIcons.mapPin;
      default:
        return LucideIcons.messageSquare;
    }
  }

  String _getDefaultTextForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      case 'file':
        return 'Document';
      case 'location':
        return 'Location';
      default:
        return 'Message';
    }
  }
}
