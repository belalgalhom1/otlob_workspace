import 'package:core/core.dart' show ImageUtils;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/features/wallet/data/wallet_models.dart';
import 'package:vendor/features/wallet/data/wallet_providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

/// Dashboard overview panel surfacing pending driver settlement / top-up
/// requests directly on the main dashboard screen (mirroring Live Orders and
/// System Logs).
class DashboardSettlementRequestsCard extends ConsumerWidget {
  final bool isPhone;
  final VoidCallback onViewAll;
  final ValueChanged<String> onSelectRequest;

  const DashboardSettlementRequestsCard({
    super.key,
    required this.isPhone,
    required this.onViewAll,
    required this.onSelectRequest,
  });

  String _formatRelativeTime(DateTime createdAt, bool isArabic) {
    final local = createdAt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    return DateFormat('d MMM', isArabic ? 'ar' : 'en').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(pendingTopUpsProvider);

    final pendingRequests = state.asData?.value
            .whereType<WalletTopUpRequest>()
            .toList() ??
        const <WalletTopUpRequest>[];
    final pendingCount = pendingRequests.length;

    final titleText = isArabic ? 'طلبات التسوية' : 'Settlement Requests';
    final subtitleText = state.isLoading && !state.hasValue
        ? (isArabic ? 'جاري التحميل...' : 'Loading...')
        : pendingCount == 0
            ? (isArabic ? 'لا توجد طلبات معلقة' : 'All caught up')
            : (isArabic
                ? (pendingCount == 1
                    ? 'طلب واحد بانتظار المراجعة'
                    : '$pendingCount طلبات بانتظار المراجعة')
                : (pendingCount == 1
                    ? '1 request pending review'
                    : '$pendingCount requests pending review'));

    final dotColor = pendingCount > 0 ? AppColors.warning : AppColors.success;
    const accentColor = Color(0xFF0D9488);

    return Container(
      key: const ValueKey('dashboard_settlement_requests_card'),
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.banknote,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const ValueKey('dashboard_settlement_view_all_btn'),
                onPressed: onViewAll,
                icon: Icon(
                  isArabic ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                  size: 14,
                ),
                iconAlignment: IconAlignment.end,
                label: Text(
                  l10n.showMore,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          state.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ErrorUtils.translate(context, err),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      key: const ValueKey('dashboard_settlement_retry_btn'),
                      onPressed: () => ref.invalidate(pendingTopUpsProvider),
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
            ),
            data: (_) {
              if (pendingRequests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 36,
                          color: AppColors.success.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isArabic
                              ? 'لا توجد طلبات تسوية معلقة'
                              : 'No pending settlement requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final visibleItems = pendingRequests.take(5).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = visibleItems[index];
                  final driverName = (req.driverName ?? '').trim().isNotEmpty
                      ? req.driverName!.trim()
                      : l10n.driver;
                  final walletLabel = req.platformWalletLabel(
                    isArabic: isArabic,
                  );
                  final timeAgo = _formatRelativeTime(req.createdAt, isArabic);
                  final subtitleLine = walletLabel.isNotEmpty
                      ? '$walletLabel • $timeAgo'
                      : timeAgo;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('dashboard_settlement_item_${req.id}'),
                      onTap: () => onSelectRequest(req.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 10 : 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.06,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppNetworkAvatar(
                              imageUrl: ImageUtils.formatImageUrl(
                                req.driverAvatar,
                              ),
                              size: 36,
                              borderRadius: 10,
                              fallbackIcon: LucideIcons.user,
                              fallbackIconSize: 18,
                              backgroundColor: accentColor.withValues(
                                alpha: 0.12,
                              ),
                              foregroundColor: accentColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          driverName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${req.amount.toStringAsFixed(2)} ${l10n.egp}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: accentColor,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          isArabic ? 'قيد المراجعة' : 'Pending',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        req.receiptUrl.isNotEmpty
                                            ? LucideIcons.receipt
                                            : LucideIcons.wallet,
                                        size: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          subtitleLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFFF8FAFC)
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isArabic
                                  ? LucideIcons.chevronLeft
                                  : LucideIcons.chevronRight,
                              size: 14,
                              color: isDark
                                  ? Colors.white70
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
