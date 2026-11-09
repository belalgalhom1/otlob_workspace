import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

class ChatMediaCaptionDialog extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const ChatMediaCaptionDialog({
    super.key,
    required this.filePath,
    this.isVideo = false,
  });

  /// Opens the caption and media preview modal.
  /// Returns the caption string if the user taps send (can be empty string if no caption).
  /// Returns null if the user cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String filePath,
    bool isVideo = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      useSafeArea: true,
      builder: (ctx) => ChatMediaCaptionDialog(
        filePath: filePath,
        isVideo: isVideo,
      ),
    );
  }

  @override
  State<ChatMediaCaptionDialog> createState() => _ChatMediaCaptionDialogState();
}

class _ChatMediaCaptionDialogState extends State<ChatMediaCaptionDialog> {
  final TextEditingController _captionController = TextEditingController();
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    try {
      final f = File(widget.filePath);
      if (f.existsSync()) {
        _fileSizeBytes = f.lengthSync();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static const int maxFileSizeAllowed = 10 * 1024 * 1024; // 10MB limit
  bool get _isTooLarge => _fileSizeBytes > maxFileSizeAllowed;

  void _onSend() {
    if (_isTooLarge) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'حجم الملف يتجاوز الحد الأقصى المسموح به (10 ميجابايت)'
                : 'File size exceeds maximum 10MB limit',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(_captionController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final file = File(widget.filePath);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isVideo
                        ? (isAr ? 'معاينة الفيديو' : 'Preview Video')
                        : (isAr ? 'معاينة الصورة' : 'Preview Photo'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_fileSizeBytes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isTooLarge
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: _isTooLarge
                            ? Border.all(color: Colors.redAccent)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isTooLarge) ...[
                            const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _formatFileSize(_fileSizeBytes),
                            style: TextStyle(
                              color: _isTooLarge ? Colors.redAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Preview Area
            Expanded(
              child: Center(
                child: widget.isVideo
                    ? _buildVideoPlaceholder(isAr)
                    : _buildImagePreview(file),
              ),
            ),

            if (_isTooLarge)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'حجم الملف يتجاوز الحد الأقصى المسموح به (10 ميجابايت). يرجى اختيار ملف أصغر.'
                            : 'File size exceeds 10MB limit. Please choose a smaller file.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isTooLarge)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'حجم الملف يتجاوز الحد الأقصى المسموح به (10 ميجابايت). يرجى اختيار ملف أصغر.'
                            : 'File size exceeds 10MB limit. Please choose a smaller file.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Caption Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                border: const Border(
                  top: BorderSide(color: Colors.white12, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _onSend(),
                        decoration: InputDecoration(
                          hintText: isAr ? 'أضف تعليقاً...' : 'Add a caption...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _onSend,
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    if (!file.existsSync()) {
      return const Icon(LucideIcons.imageOff, color: Colors.white54, size: 48);
    }
    return InteractiveViewer(
      maxScale: 3.0,
      child: Image.file(
        file,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPlaceholder(bool isAr) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.video,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.filePath.split(Platform.pathSeparator).last,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'جاهز للإرسال كفيديو عالي الجودة' : 'Ready to send as HD video',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
