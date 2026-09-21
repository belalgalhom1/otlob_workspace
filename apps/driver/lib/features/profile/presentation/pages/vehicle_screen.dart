import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../../../l10n/l10n_error_helper.dart';

class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key});

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen> {
  final _plateController = TextEditingController();
  String? _selectedVehicleType;
  bool _isEditing = false;
  bool _isLoading = false;

  static const List<String> _availableVehicleTypes = [
    'MOTORCYCLE',
    'BICYCLE',
    'CAR',
    'VAN',
    'TRUCK',
  ];

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(driverProfileProvider.notifier).updateProfile(
        vehicleType: _selectedVehicleType,
        vehiclePlate: _plateController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_updated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10nErrorHelper.translate(context, e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(driverProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehicleInformation),
        actions: [
          if (!_isEditing && profileState.hasValue && profileState.value != null)
            IconButton(
              icon: const Icon(LucideIcons.edit2),
              tooltip: l10n.edit,
              onPressed: () {
                final profileData = profileState.value;
                final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
                    ? profileData['data']
                    : (profileData ?? {});
                setState(() {
                  _isEditing = true;
                  _selectedVehicleType = data['vehicleType'] ?? 'MOTORCYCLE';
                  _plateController.text = data['vehiclePlate'] ?? '';
                });
              },
            ),
        ],
      ),
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

          final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
              ? profileData['data']
              : (profileData ?? {});

          if (!_isEditing && _selectedVehicleType == null) {
            _selectedVehicleType = data['vehicleType'] ?? 'MOTORCYCLE';
            _plateController.text = data['vehiclePlate'] ?? '';
          }

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
                      if (!_isEditing) ...[
                        _buildReadOnlyRow(
                          context,
                          l10n.vehicleType,
                          _getVehicleTypeTranslation(l10n, data['vehicleType'] ?? ''),
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
                      ] else ...[
                        Text(
                          l10n.vehicleType,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _availableVehicleTypes.contains(_selectedVehicleType)
                              ? _selectedVehicleType
                              : _availableVehicleTypes.first,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(LucideIcons.car),
                          ),
                          items: _availableVehicleTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(_getVehicleTypeTranslation(l10n, type)),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedVehicleType = val;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.vehiclePlate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _plateController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(LucideIcons.hash),
                            hintText: l10n.vehiclePlate,
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyRow(
                          context,
                          l10n.licenseNumber,
                          data['licenseNumber'] ?? l10n.notProvided,
                          LucideIcons.fileText,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditing = false;
                                        _selectedVehicleType = data['vehicleType'] ?? 'MOTORCYCLE';
                                        _plateController.text = data['vehiclePlate'] ?? '';
                                      });
                                    },
                              child: Text(l10n.cancelUpper),
                            ),
                            const SizedBox(width: 8),
                            PrimaryButton(
                              text: l10n.save,
                              onPressed: _isLoading ? null : _save,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
      case 'BICYCLE': return l10n.vehicleTypeBicycle;
      case 'MOTORCYCLE': return l10n.vehicleTypeMotorcycle;
      case 'CAR': return l10n.car;
      case 'VAN': return l10n.van;
      case 'TRUCK': return l10n.truck;
      default: return type.isNotEmpty ? type : l10n.notProvided;
    }
  }

  Widget _buildReadOnlyRow(BuildContext context, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 24),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
