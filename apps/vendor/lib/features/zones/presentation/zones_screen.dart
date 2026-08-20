import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/zones/presentation/customer_polygon_selection_screen.dart' as vendor_audience;
import 'package:vendor/features/zones/presentation/zone_edit_screen.dart' as vendor_zone_edit;

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ZoneStateData>>(zoneProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Section
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(zoneProvider);
                String total = '0';
                if (state.hasValue) total = (state.value!.total).toString();
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      title: AppLocalizations.of(context)!.activeZones,
                      value: total,
                      icon: LucideIcons.map,
                      color: AppColors.primary,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.busyZones,
                      value: '0',
                      icon: LucideIcons.activity,
                      color: AppColors.warning,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.deliveries,
                      value: '0',
                      icon: LucideIcons.navigation,
                      color: AppColors.success,
                      isMobile: isMobile,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Management Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.deliveryZones,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const vendor_audience.CustomerPolygonSelectionScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(LucideIcons.users, size: 14),
                                label: Text(AppLocalizations.of(context)!.audienceSelection),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  minimumSize: const Size(100, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const vendor_zone_edit.ZoneEditScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(LucideIcons.plus, size: 14),
                                label: Text(AppLocalizations.of(context)!.addZone),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(100, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.deliveryZones,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const vendor_audience.CustomerPolygonSelectionScreen(),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.users, size: 14),
                            label: Text(AppLocalizations.of(context)!.audienceSelection),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              minimumSize: const Size(100, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const vendor_zone_edit.ZoneEditScreen(),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.plus, size: 14),
                            label: Text(AppLocalizations.of(context)!.addZone),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(zoneProvider);
                      if (state.isLoading && !state.hasValue) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (state.hasValue) {
                        if (constraints.maxWidth < 600) {
                          return _buildZonesList(state.value!.zones, context, ref);
                        } else {
                          return _buildZonesTable(state.value!.zones, context, ref);
                        }
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZonesTable(List<dynamic> zones, BuildContext context, WidgetRef ref) {
    if (zones.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 48,
              
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noZonesDefined,
              style: const TextStyle(
                
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const vendor_zone_edit.ZoneEditScreen(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.addZone,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 48,
        ),
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context)!.name)),
            DataColumn(label: Text(AppLocalizations.of(context)!.activeStatus)),
            DataColumn(label: Text(AppLocalizations.of(context)!.points)),
            DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
          ],
          rows: zones
              .map(
                (z) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        z['name'] ?? AppLocalizations.of(context)!.unknown,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusChip(z['isActive'] ?? true, context)),
                    DataCell(
                      Text(
                        '${(z['coordinates'] as List?)?.length ?? 0}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit, size: 16),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => vendor_zone_edit.ZoneEditScreen(zone: z),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash,
                              size: 16,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              _confirmDelete(context, ref, z);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildZonesList(List<dynamic> zones, BuildContext context, WidgetRef ref) {
    if (zones.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 48,
              
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noZonesDefined,
              style: const TextStyle(
                
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: zones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final z = zones[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      z['name'] ?? AppLocalizations.of(context)!.unknown,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _buildStatusChip(z['isActive'] ?? true, context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.points}: ${(z['coordinates'] as List?)?.length ?? 0}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.edit, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => vendor_zone_edit.ZoneEditScreen(zone: z),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.error),
                        onPressed: () {
                          _confirmDelete(context, ref, z);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool isActive, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive
            ? AppLocalizations.of(context)!.activeStatus
            : AppLocalizations.of(context)!.inactiveStatus,
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.error,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic zone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.deleteConfirmContent(zone['name'] ?? 'Zone')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(zoneProvider.notifier).deleteZone(zone['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

