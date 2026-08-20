import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:intl/intl.dart';

class AvailableShiftsTab extends ConsumerWidget {
  const AvailableShiftsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(driverProfileProvider);
    String zoneId = '';
    
    if (profileState.hasValue && profileState.value != null) {
      final profileData = profileState.value;
      final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
          ? profileData['data']
          : (profileData ?? {});
      zoneId = data['zoneId']?.toString() ?? data['zone']?['id']?.toString() ?? '';
    }

    final availableState = ref.watch(availablePoolsProvider(zoneId)); 
    final l10n = AppLocalizations.of(context)!;

    if (profileState.isLoading && zoneId.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return availableState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) {
        if (error.toString().contains('shifts_disabled')) {
          return EmptyStateWidget(
            icon: LucideIcons.calendarOff,
            title: l10n.localeName == 'ar' ? 'نظام النوبات معطل' : 'Shifts System Disabled',
            subtitle: l10n.localeName == 'ar' 
                ? 'لا توجد نوبات متاحة حالياً لأن الإدارة قامت بتعطيل نظام النوبات.' 
                : 'No shifts are currently available because the administration has disabled the shifts system.',
          );
        }
        return Center(child: Text(l10n.errorGeneric(error.toString())));
      },
      data: (pools) {
        if (pools.isEmpty) {
          return EmptyStateWidget(
            icon: LucideIcons.calendarX,
            title: l10n.noAvailableShifts,
            subtitle: l10n.noAvailableShiftsSubtitle,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availablePoolsProvider(zoneId));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pools.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pool = pools[index];
              return _buildPoolItem(context, ref, pool, l10n, zoneId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPoolItem(BuildContext context, WidgetRef ref, Map<String, dynamic> pool, AppLocalizations l10n, String currentZoneId) {
    String startTime = pool['startTime'] ?? '';
    String endTime = pool['endTime'] ?? '';

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
    final zoneName = pool['zone']?['name'] ?? l10n.assignedZone;
    final isWeekly = pool['type'] == 'WEEKLY';

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
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWeekly ? l10n.weeklyShift : l10n.overtimeShift,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
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
          PrimaryButton(
            text: l10n.bookShift,
            onPressed: () {
              if (isWeekly) {
                ref.read(availablePoolsProvider(currentZoneId).notifier).bookWeeklyShifts([pool['id']]);
              } else {
                ref.read(availablePoolsProvider(currentZoneId).notifier).bookOvertimeShift(pool['id']);
              }
            },
          ),
        ],
      ),
    );
  }
}
