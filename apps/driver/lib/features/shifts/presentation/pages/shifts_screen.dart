import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:driver/features/shifts/presentation/widgets/available_shifts_tab.dart';
import 'package:driver/features/shifts/presentation/widgets/swap_board_tab.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myShiftsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.myShiftsTab),
              Tab(text: l10n.availableShiftsTab),
              Tab(text: l10n.swapBoardTab),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        body: const TabBarView(
          children: [
            _MyShiftsTab(),
            AvailableShiftsTab(),
            SwapBoardTab(),
          ],
        ),
      ),
    );
  }
}

class _MyShiftsTab extends ConsumerWidget {
  const _MyShiftsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsState = ref.watch(driverShiftsProvider);
    final l10n = AppLocalizations.of(context)!;

    return shiftsState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) {
        if (error.toString().contains('shifts_disabled')) {
          return EmptyStateWidget(
            icon: LucideIcons.calendarOff,
            title: l10n.localeName == 'ar' ? 'نظام النوبات معطل' : 'Shifts System Disabled',
            subtitle: l10n.localeName == 'ar' 
                ? 'نظام النوبات معطل حالياً من قبل الإدارة.' 
                : 'The shifts system is currently disabled by administration.',
          );
        }
        return Center(child: Text(l10n.errorGeneric(error.toString())));
      },
      data: (shifts) {
        if (shifts.isEmpty) {
          return EmptyStateWidget(
            icon: LucideIcons.calendar,
            title: l10n.noShiftsScheduled,
            subtitle: l10n.noUpcomingShifts,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverShiftsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildShiftItem(context, ref, shifts[index], l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildShiftItem(BuildContext context, WidgetRef ref, Map<String, dynamic> shift, AppLocalizations l10n) {
    final status = shift['status'] ?? 'UNKNOWN';
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

    final isUpcoming = status == 'SCHEDULED';
    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
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
                  color: isActive ? AppColors.primary.withValues(alpha: 0.2) : (isUpcoming ? AppColors.warning.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : (isUpcoming ? AppColors.warning : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          if (isUpcoming)
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: l10n.startShift,
                    onPressed: () {
                      ref.read(driverShiftsProvider.notifier).startShift(shift['id']);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showOfferSwapDialog(context, ref, shift['id'], l10n);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.offerSwap, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  void _showOfferSwapDialog(BuildContext context, WidgetRef ref, String shiftId, AppLocalizations l10n) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return DialogScaffold(child: AlertDialog(
          title: Text(l10n.offerSwap),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: l10n.reasonOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelAction),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(driverShiftsProvider.notifier).offerSwap(shiftId, reasonController.text);
                Navigator.pop(context);
              },
              child: Text(l10n.offerSwapAction),
            ),
          ],
        ));
      },
    );
  }
}
