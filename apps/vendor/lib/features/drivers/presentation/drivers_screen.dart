import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/driver_providers.dart';
import '../data/driver_models.dart';
import 'widgets/assign_order_dialog.dart';
import 'widgets/driver_shifts_dialog.dart';
import '../../wallet/presentation/widgets/manual_transaction_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import 'widgets/driver_form_dialog.dart';
import 'widgets/assist_requests_dialog.dart';
import 'driver_statistics_screen.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DriverProfile? _selectedDriver;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // NOTE: no loadMore() here — DriversNotifier.build() already fetches
    // page 1; an extra call only double-fetched (or skipped to page 2).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driversProvider.notifier).loadMore();
    }
  }

  void _applyFilters() {
    ref
        .read(driversProvider.notifier)
        .filter(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          status: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driversProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: isMobile
                  ? _buildList(state)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildList(state)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildMap(context, state)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  bool _canManageDrivers = false;

  Future<void> _checkPermissions() async {
    final repo = ref.read(sharedAuthRepositoryProvider);
    final role = await repo.getUserRole();
    if (role == 'SUPER_ADMIN') {
      if (mounted) setState(() => _canManageDrivers = true);
      return;
    }
    final permissions = await repo.getUserPermissions();
    if (mounted) {
      setState(() {
        _canManageDrivers = permissions.contains('MANAGE_DRIVERS');
      });
    }
  }

  Future<void> _locateDriver(DriverProfile driver) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result =
          await ref
              .read(adminDriversRepositoryProvider)
              .getDriverLocation(driverId: driver.id);
      final data = (result is Map) ? result : null;
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lng = (data?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || !mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.driverNoLocation)),
        );
        return;
      }
      setState(() => _selectedDriver = driver);
      _mapController.move(LatLng(lat, lng), 16);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            data?['isLive'] == true
                ? l10n.driverLiveLocation
                : l10n.driverLastKnownLocation,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (err) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(ErrorUtils.translate(context, err)), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.searchDrivers,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  isDense: true,
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.status,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.filterAll)),
                  DropdownMenuItem(value: 'ONLINE', child: Text(AppLocalizations.of(context)!.statusOnline)),
                  DropdownMenuItem(value: 'ON_DELIVERY', child: Text(AppLocalizations.of(context)!.statusOnDelivery)),
                  DropdownMenuItem(value: 'OFFLINE', child: Text(AppLocalizations.of(context)!.statusOffline)),
                  DropdownMenuItem(value: 'ON_BREAK', child: Text(AppLocalizations.of(context)!.statusOnBreak)),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text(AppLocalizations.of(context)!.statusSuspended)),
                ],
                onChanged: (val) {
                  setState(() => _selectedStatus = val);
                  _applyFilters();
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(LucideIcons.filter, size: 16),
              label: Text(AppLocalizations.of(context)!.filterAction),
            ),
            if (_canManageDrivers) ...[
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AssistRequestsDialog(),
                  );
                },
                icon: const Icon(LucideIcons.users, size: 16),
                label: Text(
                  AppLocalizations.of(context)!.localeName == 'ar'
                      ? 'طلبات المساعدة'
                      : 'Assist Requests',
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DriverFormDialog(),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(AppLocalizations.of(context)!.createNewUser),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(AsyncValue<DriversState> state) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          ErrorUtils.translate(context, err),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (data) {
        if (data.drivers.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noDriversFound));
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: data.drivers.length + (data.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == data.drivers.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final driver = data.drivers[index];
              final isSelected = _selectedDriver?.id == driver.id;

              // Never hardcode the API host (breaks on non-prod backends)
              // and never assume a leading slash or relative path.
              final avatarPath = driver.avatar;
              final resolvedAvatar = (avatarPath == null || avatarPath.isEmpty)
                  ? ''
                  : ImageUtils.formatImageUrl(avatarPath);
              final avatarUrl = resolvedAvatar.isEmpty ? null : resolvedAvatar;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDriver = driver;
                  });
                  if (driver.location != null) {
                    _mapController.move(
                      LatLng(driver.location![1], driver.location![0]),
                      15,
                    );
                  }
                },
                child: Container(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _getStatusColor(context, driver.status).withValues(alpha: 0.1),
                        backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                        child: avatarUrl == null ? Icon(
                          LucideIcons.user,
                          color: _getStatusColor(context, driver.status),
                        ) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    driver.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDriverBadgeColor(driver).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getDriverBadgeText(context, driver),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getDriverBadgeColor(driver),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${AppLocalizations.of(context)!.status}: ${_translateDriverStatus(context, driver.status)} • ',
                                  ),
                                  TextSpan(
                                    text: '${AppLocalizations.of(context)!.driverBalance}: ${_formatBalance(driver.walletBalance)} ${AppLocalizations.of(context)!.egp}',
                                    style: TextStyle(
                                      color: driver.walletBalance < 0 ? AppColors.error : null,
                                      fontWeight: driver.walletBalance < 0 ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 0,
                              runSpacing: 4,
                              children: [
                                _buildActionButton(
                                  icon: LucideIcons.wallet,
                                  label: AppLocalizations.of(context)!.actionWallet,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => ManualTransactionDialog(
                                        entityId: driver.id,
                                        isVendor: false,
                                      ),
                                    ).then(
                                      (_) => ref.read(driversProvider.notifier).refresh(),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: LucideIcons.chartNoAxesCombined,
                                  label: Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'إحصائيات'
                                      : 'Statistics',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DriverStatisticsScreen(driverId: driver.id),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: LucideIcons.truck,
                                  label: AppLocalizations.of(context)!.actionAssign,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AssignOrderDialog(driver: driver),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: LucideIcons.calendarClock,
                                  label: AppLocalizations.of(context)!.actionShifts,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => DriverShiftsDialog(driver: driver),
                                    );
                                  },
                                ),
                                if (_canManageDrivers) ...[
                                  _buildActionButton(
                                    icon: LucideIcons.mapPin,
                                    label: AppLocalizations.of(context)!.actionLocation,
                                    onPressed: () => _locateDriver(driver),
                                  ),
                                  _buildActionButton(
                                    icon: LucideIcons.pencil,
                                    label: AppLocalizations.of(context)!.actionEdit,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => DriverFormDialog(driver: driver),
                                      );
                                    },
                                  ),
                                  if (!driver.isApproved)
                                    _buildActionButton(
                                      icon: LucideIcons.checkCircle,
                                      label: AppLocalizations.of(context)!.actionApprove,
                                      iconColor: AppColors.success,
                                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                      onPressed: () {
                                        final messenger = ScaffoldMessenger.of(context);
                                        ref.read(driversProvider.notifier).updateDriver(
                                          driver.id,
                                          {'isApproved': true},
                                        ).then((_) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Driver Approved')),
                                          );
                                        }).catchError((err) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(ErrorUtils.translate(context, err)), backgroundColor: AppColors.error),
                                          );
                                        });
                                      },
                                    )
                                  else
                                    _buildActionButton(
                                      icon: driver.isSuspended ? LucideIcons.checkCircle : LucideIcons.ban,
                                      label: driver.isSuspended ? AppLocalizations.of(context)!.actionUnsuspend : AppLocalizations.of(context)!.actionSuspend,
                                      iconColor: driver.isSuspended ? AppColors.success : AppColors.error,
                                      backgroundColor: (driver.isSuspended ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                                      onPressed: () {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final notifier = ref.read(driversProvider.notifier);
                                        final action = driver.isSuspended
                                            ? notifier.unsuspendDriver(driver.id)
                                            : notifier.suspendDriver(driver.id);
                                        
                                        action.then((_) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(driver.isSuspended ? 'Driver Unsuspended' : 'Driver Suspended')),
                                          );
                                        }).catchError((err) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(ErrorUtils.translate(context, err)), backgroundColor: AppColors.error),
                                          );
                                        });
                                      },
                                    ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, AsyncValue<DriversState> state) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: state.maybeWhen(
        data: (data) {
          final markers = data.drivers.where((d) => d.location != null).map((
            d,
          ) {
            final isSelected = _selectedDriver?.id == d.id;
            return Marker(
              point: LatLng(
                d.location![1],
                d.location![0],
              ), // [lat, lng] usually, but backend saves [lng, lat] for GeoJSON
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => setState(() => _selectedDriver = d),
                child: Icon(
                  LucideIcons.mapPin,
                  size: isSelected ? 40 : 30,
                  color: _getStatusColor(context, d.status),
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(30.0444, 31.2357), // Default Cairo
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otlob.admin',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Clean balance text: no trailing ".0" on whole amounts, negative
  /// balances (driver owes) stand out in red via the caller.
  String _formatBalance(double value) {
    final isWhole = value.truncateToDouble() == value;
    return value.toStringAsFixed(isWhole ? 0 : 2);
  }

  /// Theme-aware status color. (AppColors.textSecondary is fixed black and
  /// was invisible on dark backgrounds for OFFLINE/unknown drivers.)
  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'ONLINE':
        return AppColors.success;
      case 'ON_DELIVERY':
        return Colors.blue;
      case 'ON_BREAK':
        return AppColors.warning;
      case 'OFFLINE':
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
      case 'SUSPENDED':
        return AppColors.error;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    }
  }

  Color _getDriverBadgeColor(DriverProfile driver) {
    if (!driver.isApproved) return AppColors.warning;
    if (driver.isSuspended) return AppColors.error;
    return AppColors.success;
  }

  String _getDriverBadgeText(BuildContext context, DriverProfile driver) {
    final l10n = AppLocalizations.of(context)!;
    if (!driver.isApproved) return l10n.driverStatusPending;
    if (driver.isSuspended) return l10n.driverStatusSuspended;
    return l10n.driverStatusApproved;
  }

  String _translateDriverStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'ONLINE':
        return l10n.statusOnline;
      case 'ON_DELIVERY':
        return l10n.statusOnDelivery;
      case 'OFFLINE':
        return l10n.statusOffline;
      case 'ON_BREAK':
        return l10n.statusOnBreak;
      case 'SUSPENDED':
        return l10n.suspended;
      default:
        return status;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor ?? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

