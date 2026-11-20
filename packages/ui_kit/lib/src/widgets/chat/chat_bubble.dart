import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/external_action_launcher.dart';
import '../../utils/voice_audio_helper.dart';
import '../common/app_network_avatar.dart';
import '../map/navigation_map_launcher.dart';

class ChatBubbleWidget extends StatelessWidget {
  final bool isMe;
  final String? senderName;
  final String? senderRole;
  final String? senderTitle;
  final String? senderTitleAr;
  final String? senderAvatarUrl;
  final String? mediaUrl;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'file', 'system'
  final Map<String, dynamic>? metadata;
  final String? time;
  final bool isRead;

  // Localization Strings
  final String uploadingText;
  final String fileAttachmentText;

  // Media upload progress & local preview fields (WhatsApp style)
  final double? uploadProgress;
  final String? localFilePath;
  final bool isUploadFailed;
  final VoidCallback? onRetryUpload;
  final VoidCallback? onCancelUpload;

  // Reply fields
  final String? replyToSenderName;
  final String? replyToContent;
  final String? replyToType;
  final String? replyToMediaUrl;
  final VoidCallback? onReplyTap;
  final VoidCallback? onSwipeToReply;

  // Custom Builders for feature-specific logic
  final Widget Function(Map<String, dynamic> metadata, bool isDark)? buildOfferBubble;
  final String Function(String url)? formatImageUrl;
  final void Function(String url)? onVideoTap;
  final void Function(String url)? onImageTap;

  const ChatBubbleWidget({
    super.key,
    required this.isMe,
    this.senderName,
    this.senderRole,
    this.senderTitle,
    this.senderTitleAr,
    this.senderAvatarUrl,
    this.mediaUrl,
    required this.content,
    required this.type,
    this.metadata,
    this.time,
    this.isRead = false,
    required this.uploadingText,
    required this.fileAttachmentText,
    this.uploadProgress,
    this.localFilePath,
    this.isUploadFailed = false,
    this.onRetryUpload,
    this.onCancelUpload,
    this.buildOfferBubble,
    this.formatImageUrl,
    this.onVideoTap,
    this.onImageTap,
    this.replyToSenderName,
    this.replyToContent,
    this.replyToType,
    this.replyToMediaUrl,
    this.onReplyTap,
    this.onSwipeToReply,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = const LinearGradient(
      colors: [Color(0xFFD4920E), Color(0xFFE5A824)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final primaryColor = const Color(0xFFD4920E);

    if (type == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    Widget bubble = Align(
      alignment: isMe
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          gradient: isMe ? defaultGradient : null,
          color: isMe ? null : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(20),
            topEnd: const Radius.circular(20),
            bottomStart: Radius.circular(isMe ? 20 : 4),
            bottomEnd: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe &&
                (senderName != null ||
                    (senderAvatarUrl != null && senderAvatarUrl!.trim().isNotEmpty)))
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 6, start: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderAvatarUrl != null &&
                        senderAvatarUrl!.trim().isNotEmpty) ...[
                      AppNetworkAvatar(
                        imageUrl: formatImageUrl != null
                            ? formatImageUrl!(senderAvatarUrl!)
                            : senderAvatarUrl,
                        size: 20,
                        fallbackIcon: Icons.person_rounded,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                        foregroundColor: colorScheme.primary,
                      ),
                      if (senderName != null) const SizedBox(width: 6),
                    ],
                    if (senderName != null)
                      Flexible(
                        child: Text(
                          _formatSenderBadge(context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (replyToSenderName != null || replyToContent != null)
              _buildQuotedReply(context, colorScheme, isDark, primaryColor),
            if (type == 'image')
              mediaUrl == null
                  ? _buildUploadingMediaState(context, colorScheme, primaryColor)
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                        maxHeight: 260,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => _openImage(context, mediaUrl!),
                          child: CachedNetworkImage(
                            imageUrl: formatImageUrl != null ? formatImageUrl!(mediaUrl!) : mediaUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              width: double.infinity,
                              color: colorScheme.onSurface.withValues(alpha: 0.08),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: colorScheme.onSurface.withValues(alpha: 0.08),
                              child: const Icon(LucideIcons.imageOff, size: 32),
                            ),
                          ),
                        ),
                      ),
                    ),
            if (type == 'video')
              mediaUrl == null
                  ? _buildUploadingMediaState(context, colorScheme, primaryColor)
                  : VideoPreviewWidget(
                      url: mediaUrl!,
                      isMe: isMe,
                      primaryColor: primaryColor,
                      metadata: metadata,
                      formatImageUrl: formatImageUrl,
                      onVideoTap: onVideoTap,
                    ),
            if (type == 'audio')
              mediaUrl == null
                  ? _buildUploadingState(colorScheme, primaryColor)
                  : WaveformAudioWidget(
                      url: mediaUrl!,
                      isMe: isMe,
                      primaryColor: primaryColor,
                      metadata: metadata,
                    ),
            if (type == 'file' && mediaUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, color: isMe ? Colors.white : primaryColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileAttachmentText,
                      style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            if (content.isNotEmpty && (mediaUrl != null || localFilePath != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  content,
                  style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface),
                ),
              ),
            if (type == 'text' && content.isNotEmpty && metadata?['type'] != 'OFFER')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  content,
                  style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface),
                ),
              ),
            if (type.toLowerCase() == 'location')
              _buildLocationBubble(context, colorScheme, primaryColor),
            if (metadata?['type'] == 'OFFER' && buildOfferBubble != null)
              buildOfferBubble!(metadata!, isDark),
            if (time != null || isMe) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? Colors.white : Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (onSwipeToReply != null) {
      bubble = Dismissible(
        key: ValueKey('swipe-${time ?? ''}-${content.hashCode}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          HapticFeedback.lightImpact();
          onSwipeToReply?.call();
          return false;
        },
        background: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.reply,
                size: 18,
                color: primaryColor,
              ),
            ),
          ),
        ),
        child: bubble,
      );
    }

    return bubble;
  }

  String _formatSenderBadge(BuildContext context) {
    if (senderName == null) return '';
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar' ||
        Directionality.of(context) == TextDirection.rtl;

    final localizedTitle = isArabic
        ? (senderTitleAr?.trim().isNotEmpty == true ? senderTitleAr!.trim() : (senderTitle?.trim().isNotEmpty == true ? senderTitle!.trim() : null))
        : (senderTitle?.trim().isNotEmpty == true ? senderTitle!.trim() : (senderTitleAr?.trim().isNotEmpty == true ? senderTitleAr!.trim() : null));

    if (localizedTitle != null) {
      return '$senderName ($localizedTitle)';
    }

    if (senderRole != null) {
      final roleUpper = senderRole!.toUpperCase();
      String roleLabel;
      if (isArabic) {
        if (roleUpper.contains('DRIVER')) {
          roleLabel = 'سائق';
        } else if (roleUpper.contains('CUSTOMER')) {
          roleLabel = 'عميل';
        } else if (roleUpper.contains('ADMIN')) {
          roleLabel = 'إدارة';
        } else if (roleUpper.contains('VENDOR')) {
          roleLabel = 'المتجر';
        } else {
          roleLabel = senderRole!;
        }
      } else {
        roleLabel = senderRole!
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
      }
      return '$senderName ($roleLabel)';
    }

    return senderName!;
  }

  Widget _buildQuotedReply(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primaryColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final accentColor = isMe ? Colors.white : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.14)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : colorScheme.surface.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: isRtl ? BorderSide.none : BorderSide(color: accentColor, width: 3.5),
          right: isRtl ? BorderSide(color: accentColor, width: 3.5) : BorderSide.none,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onReplyTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        replyToSenderName ?? 'Reply',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyToType != null && replyToType!.toLowerCase() != 'text') ...[
                            Icon(
                              _getReplyTypeIcon(replyToType!),
                              size: 11,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              _getReplyPreviewText(replyToType, replyToContent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (replyToMediaUrl != null && replyToMediaUrl!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: formatImageUrl != null
                          ? formatImageUrl!(replyToMediaUrl!)
                          : replyToMediaUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getReplyTypeIcon(String type) {
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

  String _getReplyPreviewText(String? type, String? content) {
    if (content != null && content.isNotEmpty) return content;
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

  void _openImage(BuildContext context, String rawUrl) {
    final resolved = formatImageUrl != null ? formatImageUrl!(rawUrl) : rawUrl;
    if (onImageTap != null) {
      onImageTap!(resolved);
    } else {
      FullScreenImageViewer.show(context, resolved);
    }
  }

  Widget _buildLocationBubble(
    BuildContext context,
    ColorScheme colorScheme,
    Color primaryColor,
  ) {
    final lat = metadata?['lat'] ?? metadata?['latitude'];
    final lng = metadata?['lng'] ?? metadata?['longitude'];
    final address = metadata?['address']?.toString() ?? content;

    return Container(
      width: 210,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.15)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? Colors.white.withValues(alpha: 0.25)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 85,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.12)
                  : primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.map,
                  size: 48,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.25)
                      : primaryColor.withValues(alpha: 0.25),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white : primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: isMe ? primaryColor : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.navigation,
                      size: 12,
                      color: isMe ? Colors.white : primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Shared Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty && address != 'Shared Location' && !address.startsWith('📍')) ...[
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    if (lat != null && lng != null) {
                      await MapNavigationLauncher.launchLocation(
                        latitude: lat,
                        longitude: lng,
                        context: context,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.25)
                          : primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.externalLink,
                          size: 12,
                          color: isMe ? Colors.white : primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Open in Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState(ColorScheme colorScheme, Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(isMe ? Colors.white : primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          uploadingText,
          style: TextStyle(
            fontSize: 12,
            color: isMe ? Colors.white.withValues(alpha: 0.8) : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingMediaState(
    BuildContext context,
    ColorScheme colorScheme,
    Color primaryColor,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final hasLocalFile = localFilePath != null &&
        localFilePath!.isNotEmpty &&
        File(localFilePath!).existsSync();

    final maxW = MediaQuery.of(context).size.width * 0.65;
    const double maxH = 200.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxW,
        maxHeight: maxH,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Background layer: Local file thumbnail or placeholder
            if (type == 'image' && hasLocalFile)
              Image.file(
                File(localFilePath!),
                width: maxW,
                height: maxH,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: maxW,
                  height: maxH,
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(LucideIcons.image, color: Colors.white54, size: 36),
                  ),
                ),
              )
            else if (type == 'video')
              Container(
                width: maxW,
                height: maxH,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.video,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              )
            else
              Container(
                width: maxW,
                height: maxH,
                color: colorScheme.onSurface.withValues(alpha: 0.12),
                child: const Center(
                  child: Icon(LucideIcons.paperclip, color: Colors.white54, size: 36),
                ),
              ),

            // 2. Translucent WhatsApp-style glass scrim
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),

            // 3. Central WhatsApp-style circular action badge
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: isUploadFailed
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRetryUpload,
                        borderRadius: BorderRadius.circular(27),
                        child: const Center(
                          child: Icon(
                            LucideIcons.rotateCcw,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: (uploadProgress != null && uploadProgress! > 0.02)
                                ? uploadProgress
                                : null,
                            strokeWidth: 3.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        if (onCancelUpload != null)
                          GestureDetector(
                            onTap: onCancelUpload,
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          )
                        else
                          Icon(
                            type == 'video' ? LucideIcons.arrowUp : LucideIcons.arrowUp,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                      ],
                    ),
            ),

            // 4. Bottom WhatsApp-style status pill (progress % or retry message)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUploadFailed
                        ? const Color(0xFFDC2626).withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUploadFailed
                            ? LucideIcons.alertCircle
                            : (type == 'video' ? LucideIcons.video : LucideIcons.image),
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isUploadFailed
                            ? (isAr ? 'فشل الرفع • اضغط للإعادة' : 'Upload failed • Tap to retry')
                            : (uploadProgress != null
                                ? '${(uploadProgress! * 100).toInt()}% • $uploadingText'
                                : uploadingText),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enterprise Voice Note Widget featuring dynamic waveforms, timeline seeking,
/// and instant duration display.
class WaveformAudioWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final Color primaryColor;
  final Map<String, dynamic>? metadata;

  const WaveformAudioWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.primaryColor,
    this.metadata,
  });

  @override
  State<WaveformAudioWidget> createState() => _WaveformAudioWidgetState();
}

class _WaveformAudioWidgetState extends State<WaveformAudioWidget> {
  static final ValueNotifier<String?> _currentlyPlayingUrl = ValueNotifier<String?>(null);

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _playerSubscription;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  double _playbackSpeed = 1.0;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<double> _waveformBars = [];

  void _onActiveUrlChanged() {
    if (_currentlyPlayingUrl.value != widget.url && _isPlaying) {
      _player.pausePlayer();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentlyPlayingUrl.addListener(_onActiveUrlChanged);
    _extractMetadata();
    _initPlayer();
  }

  void _extractMetadata() {
    // 1. Extract Initial Duration
    final durSec = widget.metadata?['durationSeconds'];
    final durMs = widget.metadata?['durationMs'];
    if (durSec != null && durSec is num && durSec > 0) {
      _totalDuration = Duration(seconds: durSec.toInt());
    } else if (durMs != null && durMs is num && durMs > 0) {
      _totalDuration = Duration(milliseconds: durMs.toInt());
    }

    // 2. Extract or Generate Waveform Bars (35 normalized bars)
    final rawWave = widget.metadata?['waveform'] ?? widget.metadata?['waveforms'];
    if (rawWave is List && rawWave.isNotEmpty) {
      _waveformBars = rawWave.map((v) {
        if (v is num) {
          return (v.toDouble()).clamp(0.12, 1.0);
        }
        return 0.3;
      }).toList();
    } else {
      // Deterministic fallback waveform based on URL hash
      final seed = widget.url.hashCode.abs();
      _waveformBars = List.generate(35, (index) {
        final val = ((seed * (index + 7)) % 100) / 100.0;
        final envelope = 0.3 + 0.65 * ((index < 18 ? index / 18.0 : (35 - index) / 17.0));
        return (val * envelope).clamp(0.15, 0.95);
      });
    }
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 60));
      _playerSubscription = _player.onProgress?.listen((e) {
        if (mounted) {
          setState(() {
            _currentPosition = e.position;
            if (e.duration.inMilliseconds > 0) {
              _totalDuration = e.duration;
            }
          });
        }
      });
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
      }
    } catch (_) {
      // Handle audio session failure gracefully
    }
  }

  @override
  void dispose() {
    _currentlyPlayingUrl.removeListener(_onActiveUrlChanged);
    if (_currentlyPlayingUrl.value == widget.url) {
      _currentlyPlayingUrl.value = null;
    }
    _playerSubscription?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!_isPlayerInitialized) return;

    if (_isPlaying) {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      await VoiceAudioHelper.configureForPlayback();
      _currentlyPlayingUrl.value = widget.url;
      if (_player.isPaused) {
        await _player.resumePlayer();
      } else {
        await _player.startPlayer(
          fromURI: widget.url,
          codec: VoiceAudioHelper.codecFromSource(widget.url),
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _currentPosition = Duration.zero;
              });
            }
            if (_currentlyPlayingUrl.value == widget.url) {
              _currentlyPlayingUrl.value = null;
            }
          },
        );
        if (_playbackSpeed != 1.0) {
          await _player.setSpeed(_playbackSpeed);
        }
      }
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _seekToFraction(double fraction) async {
    if (!_isPlayerInitialized || _totalDuration.inMilliseconds <= 0) return;
    final clamped = fraction.clamp(0.0, 1.0);
    final targetMs = (clamped * _totalDuration.inMilliseconds).round();
    final targetDuration = Duration(milliseconds: targetMs);

    await _player.seekToPlayer(targetDuration);
    setState(() {
      _currentPosition = targetDuration;
    });
  }

  Future<void> _toggleSpeed() async {
    final next = _playbackSpeed == 1.0
        ? 1.5
        : (_playbackSpeed == 1.5 ? 2.0 : 1.0);
    setState(() => _playbackSpeed = next);
    if (_isPlayerInitialized && _isPlaying) {
      await _player.setSpeed(next);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final activeColor = widget.isMe ? Colors.white : widget.primaryColor;
    final inactiveColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.35)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

    final displayDuration = _isPlaying
        ? _currentPosition
        : (_totalDuration.inMilliseconds > 0 ? _totalDuration : _currentPosition);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Circle Button
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.22)
                    : widget.primaryColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                _isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: activeColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Interactive Waveform & Duration Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        _seekToFraction(details.localPosition.dx / width);
                      },
                      onHorizontalDragUpdate: (details) {
                        _seekToFraction(details.localPosition.dx / width);
                      },
                      child: SizedBox(
                        height: 28,
                        width: width,
                        child: CustomPaint(
                          painter: _WaveformPainter(
                            bars: _waveformBars,
                            progress: progress,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(displayDuration),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.isMe
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? Colors.white.withValues(alpha: 0.22)
                              : widget.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeed == 1.0 ? '1' : (_playbackSpeed == 1.5 ? '1.5' : '2')}x',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: widget.isMe ? Colors.white : widget.primaryColor,
                          ),
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
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final count = bars.length;
    final totalSpacing = (count - 1) * 2.0;
    final barWidth = ((size.width - totalSpacing) / count).clamp(1.5, 4.0);
    final paintActive = Paint()..color = activeColor;
    final paintInactive = Paint()..color = inactiveColor;

    final progressX = size.width * progress;

    for (int i = 0; i < count; i++) {
      final x = i * (barWidth + 2.0);
      final barHeight = (bars[i] * size.height).clamp(4.0, size.height);
      final y = (size.height - barHeight) / 2.0;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      final isPast = (x + barWidth / 2) <= progressX;
      canvas.drawRRect(rect, isPast ? paintActive : paintInactive);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bars != bars ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

/// Enterprise Video Bubble Widget with keyframe thumbnail, frosted play button,
/// duration badge, and fullscreen tap.
class VideoPreviewWidget extends StatelessWidget {
  final String url;
  final bool isMe;
  final Color primaryColor;
  final Map<String, dynamic>? metadata;
  final String Function(String url)? formatImageUrl;
  final void Function(String url)? onVideoTap;

  const VideoPreviewWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.primaryColor,
    this.metadata,
    this.formatImageUrl,
    this.onVideoTap,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = metadata?['thumbnailUrl'] as String?;
    final durSec = (metadata?['durationSeconds'] as num?)?.toInt();

    final resolvedThumb = thumbnailUrl != null
        ? (formatImageUrl != null ? formatImageUrl!(thumbnailUrl) : thumbnailUrl)
        : null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
        maxHeight: 220,
        minHeight: 140,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTap: () async {
            if (onVideoTap != null) {
              onVideoTap!(url);
            } else {
              await ExternalActionLauncher.openWebUrl(url, context: context);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Thumbnail Image or Dark Placeholder
              if (resolvedThumb != null)
                CachedNetworkImage(
                  imageUrl: resolvedThumb,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.black45,
                    child: const Center(
                      child: Icon(LucideIcons.video, color: Colors.white60, size: 36),
                    ),
                  ),
                )
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E1E24), Color(0xFF121216)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.video, color: Colors.white54, size: 40),
                  ),
                ),

              // 2. Play Button Badge with Frosted Glass Effect
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              // 3. Duration Badge in Lower Right
              if (durSec != null && durSec > 0)
                PositionedDirectional(
                  bottom: 8,
                  end: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(durSec),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fullscreen interactive zoomable image viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  static void show(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, anim1, anim2) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(LucideIcons.imageOff, color: Colors.white60, size: 48),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 12, end: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
