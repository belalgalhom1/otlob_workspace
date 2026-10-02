import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import '../data/wallet_providers.dart';
import '../data/wallet_models.dart';

class PendingTopUpsScreen extends ConsumerWidget {
  const PendingTopUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pendingTopUpsProvider);
    final theme = Theme.of(context);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('$err', style: const TextStyle(color: AppColors.error)),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topUps.length,
          itemBuilder: (context, index) {
            final topUp = topUps[index] as WalletTopUpRequest;
            String dateStr = '';
            try {
              dateStr = DateFormat('dd MMM yyyy – HH:mm').format(topUp.createdAt.toLocal());
            } catch (_) {
              dateStr = topUp.createdAt.toString().split('.')[0];
            }

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
                                  Icon(
                                    LucideIcons.user,
                                    size: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                   Expanded(
                                     child: Text(
                                       '${l10n.driverId}: ${topUp.driverName ?? topUp.driverId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
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
                            textStyle: const TextStyle(fontSize: 13),
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
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(url, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.closeAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reviewTopUp(BuildContext context, WidgetRef ref, String id, String status, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (c) {
        final controller = TextEditingController();
        String? error;
        bool submitting = false;
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
                    content: Text(status == 'APPROVED' ? l10n.topUpApproved : l10n.topUpRejected),
                    backgroundColor: status == 'APPROVED' ? AppColors.success : AppColors.error,
                  ),
                );
              } catch (e) {
                if (!c.mounted) return;
                setState(() {
                  submitting = false;
                  error = '${l10n.topUpFailed}: $e';
                });
              }
            }

            return DialogScaffold(child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    status == 'APPROVED' ? LucideIcons.checkCircle : LucideIcons.xCircle,
                    color: status == 'APPROVED' ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.reviewTopUp),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: l10n.optionalNotes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(c),
                  child: Text(l10n.cancelAction),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'APPROVED' ? AppColors.success : AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(status == 'APPROVED' ? l10n.approve : l10n.reject),
                ),
              ],
            ));
          },
        );
      },
    );
  }
}
