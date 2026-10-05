import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(driverProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleInformation)),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorLoadingProfile),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(driverProfileProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (profileData) {
          if (profileData == null) {
            return Center(child: Text(l10n.noDataAvailable));
          }

          final data = profileData is Map &&
                  profileData.containsKey('data') &&
                  profileData['data'] is Map
              ? profileData['data']
              : (profileData ?? {});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyRow(
                        context,
                        l10n.vehicleType,
                        _getVehicleTypeTranslation(
                          l10n,
                          data['vehicleType']?.toString() ?? '',
                        ),
                        LucideIcons.car,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyRow(
                        context,
                        l10n.vehiclePlate,
                        data['vehiclePlate'] ?? l10n.notProvided,
                        LucideIcons.hash,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyRow(
                        context,
                        l10n.licenseNumber,
                        data['licenseNumber'] ?? l10n.notProvided,
                        LucideIcons.fileText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'لتعديل بيانات المركبة، يرجى التواصل مع الدعم'
                            : 'To change your vehicle details, please contact support',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getVehicleTypeTranslation(AppLocalizations l10n, String type) {
    switch (type) {
      case 'BICYCLE':
        return l10n.vehicleTypeBicycle;
      case 'MOTORCYCLE':
        return l10n.vehicleTypeMotorcycle;
      case 'CAR':
        return l10n.car;
      case 'VAN':
        return l10n.van;
      case 'TRUCK':
        return l10n.truck;
      default:
        return type.isNotEmpty ? type : l10n.notProvided;
    }
  }

  Widget _buildReadOnlyRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
