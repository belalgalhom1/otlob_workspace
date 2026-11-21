import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../app_adaptive_chevron.dart';

/// Pinned order banner displayed at the top of an order chat screen,
/// providing live context on order status, total, and direct phone call fallback.
class OrderContextBar extends StatelessWidget {
  final String orderNumber;
  final String statusLabel;
  final Color? statusColor;
  final String? totalAmount;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  const OrderContextBar({
    super.key,
    required this.orderNumber,
    required this.statusLabel,
    this.statusColor,
    this.totalAmount,
    this.onTap,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final activeColor = statusColor ?? AppColors.primary;

    return Material(
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Order Icon in subtle container
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.packageCheck,
                  size: 16,
                  color: isDark ? AppColors.primary : const Color(0xFF92400E),
                ),
              ),
              const SizedBox(width: 10),

              // Order Number and Total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '#$orderNumber',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        if (totalAmount != null && totalAmount!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              totalAmount!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Status Badge with pulsing indicator dot
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: activeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons (Call + Chevron)
              if (onCall != null) ...[
                IconButton(
                  onPressed: onCall,
                  icon: const Icon(LucideIcons.phoneCall, size: 16),
                  color: isDark ? AppColors.primary : const Color(0xFF92400E),
                  tooltip: 'Call',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],

              if (onTap != null)
                AppAdaptiveChevron(
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
