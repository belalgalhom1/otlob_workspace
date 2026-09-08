import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatBubbleWidget extends StatelessWidget {
  final bool isMe;
  final String? senderName;
  final String? senderRole;
  final String? mediaUrl;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'file'
  final Map<String, dynamic>? metadata;
  final String? time;
  final bool isRead;
  
  // Localization Strings
  final String uploadingText;
  final String fileAttachmentText;
  
  // Custom Builders for feature-specific logic
  final Widget Function(Map<String, dynamic> metadata, bool isDark)? buildOfferBubble;
  final String Function(String url)? formatImageUrl;

  const ChatBubbleWidget({
    super.key,
    required this.isMe,
    this.senderName,
    this.senderRole,
    this.mediaUrl,
    required this.content,
    required this.type,
    this.metadata,
    this.time,
    this.isRead = false,
    required this.uploadingText,
    required this.fileAttachmentText,
    this.buildOfferBubble,
    this.formatImageUrl,
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? defaultGradient : null,
          color: isMe 
              ? null 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
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
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  senderRole != null 
                    ? '$senderName (${senderRole!.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ')})'
                    : senderName!, 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5))
                ),
              ),
            if (type == 'image')
              mediaUrl == null 
                ? _buildUploadingState(colorScheme, primaryColor)
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      maxHeight: 250,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        formatImageUrl != null ? formatImageUrl!(mediaUrl!) : mediaUrl!, 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: colorScheme.onSurface.withValues(alpha: 0.08),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
            if (type == 'audio')
              mediaUrl == null 
                ? _buildUploadingState(colorScheme, primaryColor)
                : AudioPlayerWidget(url: mediaUrl!, isMe: isMe, primaryColor: primaryColor),
            if (type == 'file' && mediaUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, color: isMe ? Colors.white : primaryColor),
                  const SizedBox(width: 8),
                  Flexible(child: Text(fileAttachmentText, style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface))),
                ],
              ),
            if (content.isNotEmpty && mediaUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(content, style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface)),
              ),
            if (type == 'text' && content.isNotEmpty && metadata?['type'] != 'OFFER')
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(content, style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface)),
              ),
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
                      color: isRead
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          uploadingText,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final Color primaryColor;

  const AudioPlayerWidget({super.key, required this.url, required this.isMe, required this.primaryColor});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!_isPlayerInitialized) return;

    if (_isPlaying) {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      if (_player.isPaused) {
        await _player.resumePlayer();
      } else {
        await _player.startPlayer(
          fromURI: widget.url,
          whenFinished: () {
            setState(() => _isPlaying = false);
          },
        );
      }
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
          color: widget.isMe ? Colors.white : widget.primaryColor,
          onPressed: _playPause,
        ),
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.white54 : widget.primaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: _isPlaying ? 50 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white : widget.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
