import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import '../data/wallet_localization.dart';
import '../data/wallet_providers.dart';
import '../data/wallet_models.dart';
import 'topup_details_screen.dart';

class PendingTopUpsScreen extends ConsumerStatefulWidget {
  const PendingTopUpsScreen({super.key});

  @override
  ConsumerState<PendingTopUpsScreen> createState() => _PendingTopUpsScreenState();
}

class _PendingTopUpsScreenState extends ConsumerState<PendingTopUpsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pendingTopUpsProvider);
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: DashboardSearchBar(
            controller: _searchController,
            hintText: isAr
                ? 'بحث باسم السائق، المبلغ، الملاحظات، أو الرقم التعريفي...'
                : 'Search by driver, amount, notes, or ID...',
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(ErrorUtils.translate(context, err), style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(pendingTopUpsProvider),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text(l10n.refresh),
                  ),
                ],
              ),
            ),
            data: (topUps) {
              if (topUps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        size: 64,
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPendingTopUps,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }

              var filtered = topUps;
              if (_searchQuery.isNotEmpty) {
                filtered = topUps.where((item) {
                  final req = item as WalletTopUpRequest;
                  final name = (req.driverName ?? '').toLowerCase();
                  final amount = req.amount.toString();
                  final id = req.id.toLowerCase();
                  final notes = (req.notes ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      amount.contains(_searchQuery) ||
                      id.contains(_searchQuery) ||
                      notes.contains(_searchQuery);
                }).toList();
              }

              if (filtered.isEmpty && topUps.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.searchX,
                            size: 28,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr
                              ? 'لا توجد طلبات شحن تطابق بحثك'
                              : 'No top-up requests matching your search',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Text(
                            isAr ? 'مسح البحث' : 'Clear search',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final topUp = filtered[index] as WalletTopUpRequest;
            final dateStr = WalletLocalization.formatDateTime(
              topUp.createdAt,
              isArabic: isAr,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DriverAdjustmentDetailsScreen(
                          requestId: topUp.id,
                          initialRequest: topUp,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.banknote,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${topUp.amount} ${l10n.egp}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  AppNetworkAvatar(
                                    imageUrl: ImageUtils.formatImageUrl(
                                      topUp.driverAvatar,
                                    ),
                                    size: 20,
                                    fallbackIcon: LucideIcons.user,
                                    fallbackIconSize: 11,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      (topUp.driverName ?? '').trim().isNotEmpty
                                          ? '${isAr ? 'السائق' : 'Driver'}: ${topUp.driverName}'
                                          : '${l10n.driverId}: ${topUp.driverId}',
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (topUp.platformWalletLabel(isArabic: isAr).isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  topUp.platformWalletLabel(isArabic: isAr),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // View screenshot
                        if (topUp.receiptUrl.isNotEmpty)
                          IconButton(
                            tooltip: l10n.viewScreenshot,
                            icon: const Icon(LucideIcons.image, size: 20),
                            color: AppColors.info,
                            onPressed: () => _showScreenshot(context, _resolveReceiptUrl(ref, topUp.receiptUrl), l10n),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reject
                            OutlinedButton.icon(
                              onPressed: () => _reviewTopUp(context, ref, topUp.id, 'REJECTED', l10n),
                              icon: const Icon(LucideIcons.xCircle, size: 15),
                              label: Text(l10n.reject),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                textStyle: theme.textTheme.labelMedium?.copyWith(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Approve
                            ElevatedButton.icon(
                              onPressed: () => _reviewTopUp(context, ref, topUp.id, 'APPROVED', l10n),
                              icon: const Icon(LucideIcons.checkCircle, size: 15),
                              label: Text(l10n.approve),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                textStyle: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  ),
],
);
}

  String _resolveReceiptUrl(WidgetRef ref, String url) {
    if (url.startsWith('http')) return url;
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBaseUrl$cleanPath';
  }

  void _showScreenshot(BuildContext context, String url, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (c) => AppDialog(
        maxWidth: 680,
        scrollableBody: false,
        bodyPadding: const EdgeInsets.all(16),
        header: AppDialogHeader(
          icon: LucideIcons.image,
          title: isAr ? 'إيصال التحويل' : 'Transfer Receipt',
          onClose: () => Navigator.pop(c),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, err, stack) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Icon(
                      LucideIcons.image,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        footer: AppDialogFooter(
          cancelLabel: l10n.closeAction,
          onCancel: () => Navigator.pop(c),
        ),
      ),
    );
  }

  void _reviewTopUp(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    String? error;
    bool submitting = false;
    final isApprove = status == 'APPROVED';
    final statusColor = isApprove ? AppColors.success : AppColors.error;

    showDialog<void>(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              setState(() {
                submitting = true;
                error = null;
              });
              try {
                await ref
                    .read(pendingTopUpsProvider.notifier)
                    .reviewTopUp(id, status, notes: controller.text);
                if (!c.mounted) return;
                Navigator.pop(c);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isApprove ? l10n.topUpApproved : l10n.topUpRejected,
                    ),
                    backgroundColor: statusColor,
                  ),
                );
              } catch (e) {
                if (!c.mounted) return;
                setState(() {
                  submitting = false;
                  error =
                      '${l10n.topUpFailed}: ${ErrorUtils.translate(context, e)}';
                });
              }
            }

            return AppDialog(
              maxWidth: 460,
              canPop: !submitting,
              header: AppDialogHeader(
                icon: isApprove ? LucideIcons.checkCircle : LucideIcons.xCircle,
                accentColor: statusColor,
                title: l10n.reviewTopUp,
                isCloseDisabled: submitting,
                onClose: () => Navigator.pop(c),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFieldLabel(label: l10n.reviewNotesLabel),
                  TextField(
                    controller: controller,
                    enabled: !submitting,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: AppDialogStyles.inputDecoration(
                      dialogContext,
                      hintText: isApprove ? l10n.optionalNotes : l10n.rejectionReasonHint,
                      icon: LucideIcons.messageSquare,
                      isMultiline: true,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    AppDialogErrorBanner(message: error!),
                  ],
                ],
              ),
              footer: AppDialogFooter(
                cancelLabel: l10n.cancelAction,
                onCancel: () => Navigator.pop(c),
                confirmLabel: isApprove ? l10n.approve : l10n.reject,
                confirmIcon:
                    isApprove ? LucideIcons.checkCircle : LucideIcons.xCircle,
                confirmBackgroundColor: statusColor,
                confirmForegroundColor: Colors.white,
                isLoading: submitting,
                onConfirm: submit,
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        controller.dispose,
      );
    });
  }
}
