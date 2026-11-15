import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

enum ChatMediaPickerOption {
  cameraPhoto,
  cameraVideo,
  galleryPhoto,
  galleryVideo,
}

class ChatMediaPickerSheet extends StatelessWidget {
  final ValueChanged<ChatMediaPickerOption> onOptionSelected;
  final bool allowVideo;

  const ChatMediaPickerSheet({
    super.key,
    required this.onOptionSelected,
    this.allowVideo = true,
  });

  static Future<ChatMediaPickerOption?> show(
    BuildContext context, {
    bool allowVideo = true,
  }) {
    return showModalBottomSheet<ChatMediaPickerOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChatMediaPickerSheet(
        allowVideo: allowVideo,
        onOptionSelected: (option) {
          HapticFeedback.lightImpact();
          Navigator.of(ctx).pop(option);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleCol = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Row(
            children: [
              Text(
                isAr ? 'مشاركة وسائط' : 'Share Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                color: subtitleCol,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Options Grid
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  context,
                  icon: LucideIcons.camera,
                  iconBg: const Color(0xFF10B981), // Emerald
                  title: isAr ? 'التقاط صورة' : 'Take Photo',
                  subtitle: isAr ? 'كاميرا' : 'Camera',
                  onTap: () => onOptionSelected(ChatMediaPickerOption.cameraPhoto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTile(
                  context,
                  icon: LucideIcons.image,
                  iconBg: const Color(0xFF3B82F6), // Blue
                  title: isAr ? 'معرض الصور' : 'Photos',
                  subtitle: isAr ? 'الاستوديو' : 'Gallery',
                  onTap: () => onOptionSelected(ChatMediaPickerOption.galleryPhoto),
                ),
              ),
            ],
          ),
          if (allowVideo) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    icon: LucideIcons.video,
                    iconBg: const Color(0xFFF59E0B), // Amber
                    title: isAr ? 'تصوير فيديو' : 'Record Video',
                    subtitle: isAr ? 'كاميرا' : 'Camera',
                    onTap: () => onOptionSelected(ChatMediaPickerOption.cameraVideo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTile(
                    context,
                    icon: LucideIcons.film,
                    iconBg: const Color(0xFF8B5CF6), // Purple
                    title: isAr ? 'معرض الفيديو' : 'Videos',
                    subtitle: isAr ? 'الاستوديو' : 'Gallery',
                    onTap: () => onOptionSelected(ChatMediaPickerOption.galleryVideo),
                  ),
                ),
              ],
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : AppColors.textMuted,
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
}
