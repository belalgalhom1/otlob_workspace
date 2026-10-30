import 'package:url_launcher/url_launcher.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'driver_managers_screen.dart';
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
import '../../zones/presentation/zone_provider.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  String? _selectedStatus;
  String? _selectedZoneId;
  List<LatLng> _selectedZonePolygon = [];
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
      ref.read(zoneProvider.notifier).fetchZones();
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
          zoneId: _selectedZoneId,
        );
  }

  List<LatLng> _extractPolygonPoints(dynamic boundary) {
    if (boundary is! Map) return [];
    final coordinates = boundary['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return [];
    final firstRing = coordinates[0];
    if (firstRing is! List) return [];
    final points = <LatLng>[];
    for (final coord in firstRing) {
      if (coord is List && coord.length >= 2) {
        final lng = (coord[0] as num?)?.toDouble();
        final lat = (coord[1] as num?)?.toDouble();
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }
    return points;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(30.0444, 31.2357);
    double latSum = 0;
    double lngSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  void _onZoneSelected(String? zoneId, List<dynamic> zones) {
    _selectedZoneId = zoneId;
    if (zoneId == null) {
      _selectedZonePolygon = [];
    } else {
      final zone = zones.firstWhere(
        (z) => z is Map && z['id']?.toString() == zoneId,
        orElse: () => null,
      );
      if (zone != null) {
        _selectedZonePolygon = _extractPolygonPoints(zone['boundary']);
        if (_selectedZonePolygon.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(
                _calculateCentroid(_selectedZonePolygon),
                13,
              );
            }
          });
        }
      } else {
        _selectedZonePolygon = [];
      }
    }
  }

  Future<void> _callDriver(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driversProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Column(
          children: [
            _buildFilters(isMobile),
            const SizedBox(height: 14),
            Expanded(
              child: isMobile
                  ? _buildList(state, isMobile)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildList(state, isMobile)),
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
    if (role == 'SUPER_ADMIN' || role == 'DRIVER_MANAGER') {
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
      final result = await ref
          .read(adminDriversRepositoryProvider)
          .getDriverLocation(driverId: driver.id);
      final data = (result is Map) ? result : null;
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lng = (data?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || !mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(l10n.driverNoLocation)));
        return;
      }
      setState(() => _selectedDriver = driver);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(LatLng(lat, lng), 16);
        }
      });

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
        SnackBar(
          content: Text(ErrorUtils.translate(context, err)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildFilters(bool isMobile) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final zones = ref.watch(zoneProvider).value?.zones ?? const [];
    final hasActiveFilters = _searchController.text.trim().isNotEmpty ||
        _selectedStatus != null ||
        _selectedZoneId != null;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dashboard Search Bar + Primary 'Add Driver' Button
          Row(
            children: [
              Expanded(
                child: DashboardSearchBar(
                  controller: _searchController,
                  hintText: l10n.searchDrivers,
                  onChanged: (val) => _applyFilters(),
                  onClear: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DriverFormDialog(),
                  );
                },
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: Text(
                  isMobile
                      ? (isArabic ? 'سائق جديد' : 'New')
                      : l10n.createNewUser,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Status Filter Chips & Zone Selector & Auxiliary Action Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(null, l10n.filterAll),
                _buildStatusChip('ONLINE', l10n.statusOnline, color: AppColors.success),
                _buildStatusChip('ON_DELIVERY', l10n.statusOnDelivery, color: Colors.blue),
                _buildStatusChip('ON_BREAK', l10n.statusOnBreak, color: AppColors.warning),
                _buildStatusChip('OFFLINE', l10n.statusOffline, color: Colors.grey),
                _buildStatusChip('SUSPENDED', l10n.statusSuspended, color: AppColors.error),

                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),

                _buildZoneDropdown(zones, isArabic, l10n),

                if (_canManageDrivers) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DriverManagersScreen(isEmbedded: false),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.userCheck, size: 14),
                    label: Text(
                      isArabic ? 'مسؤولو السائقين' : 'Driver Managers',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AssistRequestsDialog(),
                      );
                    },
                    icon: const Icon(LucideIcons.lifeBuoy, size: 14),
                    label: Text(
                      isArabic ? 'طلبات المساعدة' : 'Assist Requests',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],

                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedStatus = null;
                        _selectedZoneId = null;
                        _selectedZonePolygon = [];
                      });
                      _applyFilters();
                    },
                    icon: const Icon(LucideIcons.x, size: 14, color: AppColors.error),
                    label: Text(
                      l10n.resetFilters,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status, String label, {Color? color}) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: color != null
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : const Color(0xFFF1F3F5),
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() => _selectedStatus = status);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildZoneDropdown(
    List<dynamic> zones,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedZoneId != null
              ? AppColors.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedZoneId,
          icon: const Icon(LucideIcons.chevronDown, size: 14),
          style: TextStyle(
            fontSize: 12,
            fontWeight: _selectedZoneId != null ? FontWeight.bold : FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.mapPin, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                l10n.allZones,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.mapPin, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(l10n.allZones, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            for (final z in zones)
              DropdownMenuItem(
                value: z['id']?.toString(),
                child: Text(
                  (isArabic ? (z['nameAr'] ?? z['name']) : z['name'])?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (val) {
            setState(() {
              _onZoneSelected(val, zones);
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildList(AsyncValue<DriversState> state, bool isMobile) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.truck,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noDriversFound,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: _scrollController,
          itemCount: data.drivers.length + (data.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == data.drivers.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final driver = data.drivers[index];
            return _buildDriverCard(driver, isArabic, l10n, isMobile);
          },
        );
      },
    );
  }

  Widget _buildDriverCard(
    DriverProfile driver,
    bool isArabic,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedDriver?.id == driver.id;

    final avatarPath = driver.avatar;
    final resolvedAvatar = (avatarPath == null || avatarPath.isEmpty)
        ? ''
        : ImageUtils.formatImageUrl(avatarPath);
    final avatarUrl = resolvedAvatar.isEmpty ? null : resolvedAvatar;
    final statusColor = _getStatusColor(context, driver.status);

    return InkWell(
      onTap: () {
        setState(() => _selectedDriver = driver);
        if (driver.location != null) {
          _mapController.move(
            LatLng(driver.location![1], driver.location![0]),
            15,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar with Status Indicator + Name & Phone + Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(LucideIcons.user, color: statusColor, size: 24)
                          : null,
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name.isNotEmpty
                            ? driver.name
                            : (isArabic ? 'سائق' : 'Driver'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (driver.phone != null && driver.phone!.isNotEmpty)
                        InkWell(
                          onTap: () => _callDriver(driver.phone),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    driver.phone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          'ID: ${driver.id.substring(0, driver.id.length > 8 ? 8 : driver.id.length)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _translateDriverStatus(context, driver.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Approval Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getDriverBadgeColor(driver).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getDriverBadgeText(context, driver),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDriverBadgeColor(driver),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Contextual tags (Zone, Manager, Vehicle)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (driver.zoneName != null && driver.zoneName!.isNotEmpty)
                  _buildTagPill(
                    icon: LucideIcons.mapPin,
                    label: driver.zoneName!,
                    color: Colors.teal,
                  ),
                if (driver.driverManagerName != null && driver.driverManagerName!.isNotEmpty)
                  _buildTagPill(
                    icon: LucideIcons.userCheck,
                    label: '${isArabic ? "مسؤول السائقين" : "Manager"}: ${driver.driverManagerName}',
                    color: AppColors.primary,
                  ),
                if ((driver.vehiclePlate != null && driver.vehiclePlate!.isNotEmpty) ||
                    (driver.vehicleType != null && driver.vehicleType!.isNotEmpty))
                  _buildTagPill(
                    icon: LucideIcons.bike,
                    label: '${driver.vehicleType ?? ""} ${driver.vehiclePlate ?? ""}'.trim(),
                    color: Colors.blueGrey,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Financial & Wallet Snapshot Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.03)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        driver.walletBalance < 0
                            ? LucideIcons.alertTriangle
                            : LucideIcons.wallet,
                        size: 15,
                        color: driver.walletBalance < 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        driver.walletBalance < 0
                            ? (isArabic ? 'المديونية المستحقة: ' : 'Owed Debt: ')
                            : (isArabic ? 'رصيد المحفظة: ' : 'Wallet Balance: '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatBalance(driver.walletBalance.abs())} ${l10n.egp}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: driver.walletBalance < 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Row 4: Elegant Horizontal Action Strip (All actions in 1 smooth scrolling line)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionPill(
                    icon: LucideIcons.wallet,
                    label: l10n.actionWallet,
                    color: AppColors.primary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ManualTransactionDialog(
                          entityId: driver.id,
                          isVendor: false,
                        ),
                      ).then((_) => ref.read(driversProvider.notifier).refresh());
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.barChart3,
                    label: isArabic ? 'إحصائيات' : 'Statistics',
                    color: Colors.indigoAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverStatisticsScreen(driverId: driver.id, driverName: driver.name),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.truck,
                    label: l10n.actionAssign,
                    color: Colors.blue,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AssignOrderDialog(driver: driver),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.calendarClock,
                    label: l10n.actionShifts,
                    color: Colors.purpleAccent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => DriverShiftsDialog(driver: driver),
                      );
                    },
                  ),
                  if (_canManageDrivers) ...[
                    const SizedBox(width: 8),
                    _buildActionPill(
                      icon: LucideIcons.mapPin,
                      label: l10n.actionLocation,
                      color: Colors.teal,
                      onTap: () => _locateDriver(driver),
                    ),
                    const SizedBox(width: 8),
                    _buildActionPill(
                      icon: LucideIcons.pencil,
                      label: l10n.actionEdit,
                      color: Colors.grey,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => DriverFormDialog(driver: driver),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (!driver.isApproved)
                      _buildActionPill(
                        icon: LucideIcons.checkCircle,
                        label: l10n.actionApprove,
                        color: AppColors.success,
                        bg: AppColors.success.withValues(alpha: 0.12),
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          ref.read(driversProvider.notifier).updateDriver(driver.id, {
                            'isApproved': true,
                          }).then((_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Driver Approved')),
                            );
                          }).catchError((err) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorUtils.translate(context, err)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          });
                        },
                      )
                    else
                      _buildActionPill(
                        icon: driver.isSuspended ? LucideIcons.checkCircle : LucideIcons.ban,
                        label: driver.isSuspended
                            ? l10n.actionUnsuspend
                            : l10n.actionSuspend,
                        color: driver.isSuspended ? AppColors.success : AppColors.error,
                        bg: (driver.isSuspended ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.12),
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          final notifier = ref.read(driversProvider.notifier);
                          final action = driver.isSuspended
                              ? notifier.unsuspendDriver(driver.id)
                              : notifier.suspendDriver(driver.id);
                          action.then((_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  driver.isSuspended
                                      ? 'Driver Unsuspended'
                                      : 'Driver Suspended',
                                ),
                              ),
                            );
                          }).catchError((err) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorUtils.translate(context, err)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          });
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? bg,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    final effectiveBg = bg ?? (isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
        : const Color(0xFFF1F3F5));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
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
              const AppMapTileLayer(userAgentPackageName: 'com.otlob.admin'),
              if (_selectedZonePolygon.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _selectedZonePolygon,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
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
}
