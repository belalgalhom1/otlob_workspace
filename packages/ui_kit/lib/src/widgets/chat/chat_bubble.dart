import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatBubbleWidget extends StatelessWidget {
  final bool isMe;
  final String? senderName;
  final String? senderRole;
  final String? mediaUrl;
  final String content;
  final String type; // 'text', 'image', 'video', 'audio', 'file', 'system'
  final Map<String, dynamic>? metadata;
  final String? time;
  final bool isRead;

  // Localization Strings
  final String uploadingText;
  final String fileAttachmentText;

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
    this.onVideoTap,
    this.onImageTap,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isMe ? defaultGradient : null,
          color: isMe ? null : colorScheme.surfaceContainerHighest,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            if (type == 'image')
              mediaUrl == null
                  ? _buildUploadingState(colorScheme, primaryColor)
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
                  ? _buildUploadingState(colorScheme, primaryColor)
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
            if (content.isNotEmpty && mediaUrl != null)
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
  }

  void _openImage(BuildContext context, String rawUrl) {
    final resolved = formatImageUrl != null ? formatImageUrl!(rawUrl) : rawUrl;
    if (onImageTap != null) {
      onImageTap!(resolved);
    } else {
      FullScreenImageViewer.show(context, resolved);
    }
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
      _currentlyPlayingUrl.value = widget.url;
      if (_player.isPaused) {
        await _player.resumePlayer();
      } else {
        await _player.startPlayer(
          fromURI: widget.url,
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
          onTap: () {
            if (onVideoTap != null) {
              onVideoTap!(url);
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
                Positioned(
                  bottom: 8,
                  right: 8,
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
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
        ],
      ),
    );
  }
}
