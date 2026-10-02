import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:intl/intl.dart';

class SwapBoardTab extends ConsumerWidget {
  const SwapBoardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapState = ref.watch(swapBoardProvider);
    final l10n = AppLocalizations.of(context)!;

    return swapState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) {
        if (error.toString().toLowerCase().contains('shifts_disabled')) {
          return EmptyStateWidget(
            icon: LucideIcons.calendarOff,
            title: l10n.shiftsDisabledTitle,
            subtitle: l10n.shiftsDisabledSwapSubtitle,
          );
        }
        return Center(child: Text(ErrorUtils.translate(context, error)));
      },
      data: (swaps) {
        if (swaps.isEmpty) {
          return EmptyStateWidget(
            icon: LucideIcons.arrowLeftRight,
            title: l10n.noSwapsAvailable,
            subtitle: l10n.noSwapsSubtitle,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(swapBoardProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: swaps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final swap = swaps[index];
              return _buildSwapItem(context, ref, swap, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildSwapItem(BuildContext context, WidgetRef ref, Map<String, dynamic> swap, AppLocalizations l10n) {
    final shift = swap['driverShift'] ?? {};
    String startTime = shift['startTime'] ?? shift['shiftPool']?['startTime'] ?? '';
    String endTime = shift['endTime'] ?? shift['shiftPool']?['endTime'] ?? '';

    try {
      if (startTime.isNotEmpty) {
        final d = DateTime.parse(startTime).toLocal();
        startTime = DateFormat.jm().format(d);
      }
      if (endTime.isNotEmpty) {
        final d = DateTime.parse(endTime).toLocal();
        endTime = DateFormat.jm().format(d);
      }
    } catch (_) {}

    final zoneName = shift['zone']?['name'] ?? shift['shiftPool']?['zone']?['name'] ?? l10n.assignedZone;
    final driverName = shift['driver']?['name'] ?? swap['offeredByDriver']?['name'] ?? l10n.unknownDriver;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zoneName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.shiftSwap,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.user, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                driverName,
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: l10n.acceptSwap,
            onPressed: () {
              ref.read(swapBoardProvider.notifier).acceptSwap(swap['id']);
            },
          ),
        ],
      ),
    );
  }
}
