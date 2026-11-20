import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Presentation-only banner that displays offline/online network transitions.
/// Adheres to packages/ui_kit rules (zero networking, pure visual/presentation).
class OfflineStatusBanner extends StatefulWidget {
  final bool isOnline;
  final String? offlineMessage;
  final String? onlineMessage;
  final VoidCallback? onRetry;
  final bool useSafeArea;

  const OfflineStatusBanner({
    super.key,
    required this.isOnline,
    this.offlineMessage,
    this.onlineMessage,
    this.onRetry,
    this.useSafeArea = true,
  });

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _heightFactor;
  bool _showBackOnlineBanner = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    if (!widget.isOnline) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant OfflineStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _hideTimer?.cancel();
      _hideTimer = null;

      if (!widget.isOnline) {
        // Just went offline
        setState(() {
          _showBackOnlineBanner = false;
        });
        _animController.forward();
      } else {
        // Just came back online
        setState(() {
          _showBackOnlineBanner = true;
        });
        // Keep "Back Online" message visible for 2.2 seconds then smoothly slide up
        _hideTimer = Timer(const Duration(milliseconds: 2200), () {
          if (mounted && widget.isOnline) {
            _animController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showBackOnlineBanner = false;
                });
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl ||
        Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final offlineText = widget.offlineMessage ??
        (isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No Internet Connection');
    final onlineText = widget.onlineMessage ??
        (isArabic ? 'تم استعادة الاتصال بالإنترنت' : 'Back Online');

    final backgroundColor = _showBackOnlineBanner
        ? const Color(0xFF10B981) // Emerald green
        : const Color(0xFFDC2626); // Strong red

    final icon = _showBackOnlineBanner
        ? LucideIcons.wifi
        : LucideIcons.wifiOff;

    final text = _showBackOnlineBanner ? onlineText : offlineText;

    return ClipRect(
      child: SizeTransition(
        sizeFactor: _heightFactor,
        child: Container(
          width: double.infinity,
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            bottom: false,
            top: widget.useSafeArea,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!widget.isOnline && widget.onRetry != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isArabic ? 'إعادة المحاولة' : 'Retry',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
