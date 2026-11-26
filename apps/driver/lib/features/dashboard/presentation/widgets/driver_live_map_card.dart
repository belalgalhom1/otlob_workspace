import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

/// Resolved visual metadata for a backend [DriverStatus] string.
class DriverStatusPresentation {
  const DriverStatusPresentation({
    required this.rawStatus,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.isWorkingShift,
    required this.isOnBreak,
    required this.isSuspended,
  });

  final String rawStatus;
  final String label;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final bool isWorkingShift;
  final bool isOnBreak;
  final bool isSuspended;

  static DriverStatusPresentation resolve(
    String rawStatus,
    AppLocalizations l10n,
  ) {
    final normalized = rawStatus.toUpperCase().trim();
    switch (normalized) {
      case 'ONLINE':
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.driverStatusOnline,
          title: l10n.youAreOnline,
          subtitle: l10n.waitingForRequests,
          accent: AppColors.success,
          icon: LucideIcons.checkCircle,
          isWorkingShift: true,
          isOnBreak: false,
          isSuspended: false,
        );
      case 'ON_DELIVERY':
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.driverStatusOnTrip,
          title: l10n.driverStatusOnTripTitle,
          subtitle: l10n.driverStatusOnTripSubtitle,
          accent: AppColors.info,
          icon: LucideIcons.navigation,
          isWorkingShift: true,
          isOnBreak: false,
          isSuspended: false,
        );
      case 'BUSY':
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.driverStatusBusy,
          title: l10n.driverStatusBusyTitle,
          subtitle: l10n.driverStatusBusySubtitle,
          accent: const Color(0xFFF97316),
          icon: LucideIcons.clock,
          isWorkingShift: true,
          isOnBreak: false,
          isSuspended: false,
        );
      case 'ON_BREAK':
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.driverStatusOnBreak,
          title: l10n.youAreOnBreak,
          subtitle: l10n.onBreakSubtitle,
          accent: Colors.amber.shade700,
          icon: LucideIcons.coffee,
          isWorkingShift: false,
          isOnBreak: true,
          isSuspended: false,
        );
      case 'SUSPENDED':
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.statusSuspended,
          title: l10n.driverStatusSuspendedTitle,
          subtitle: l10n.driverStatusSuspendedSubtitle,
          accent: AppColors.error,
          icon: Icons.warning_amber_rounded,
          isWorkingShift: false,
          isOnBreak: false,
          isSuspended: true,
        );
      case 'OFFLINE':
      default:
        return DriverStatusPresentation(
          rawStatus: normalized,
          label: l10n.driverStatusOffline,
          title: l10n.youAreOffline,
          subtitle: l10n.goOnlineToReceive,
          accent: AppColors.error,
          icon: LucideIcons.xCircle,
          isWorkingShift: false,
          isOnBreak: false,
          isSuspended: false,
        );
    }
  }
}

/// Interactive dashboard live-map card that consumes real GPS updates from
/// [LocationService], displays the driver's registered vehicle marker smoothly
/// animated across position/heading changes, mirrors the backend driver status
/// right above the map surface, and handles permission/GPS/error states cleanly.
class DriverLiveMapCard extends ConsumerStatefulWidget {
  const DriverLiveMapCard({
    super.key,
    required this.driverStatus,
    required this.vehicleType,
    this.plateNumber,
    this.driverName,
  });

  final String driverStatus;
  final String vehicleType;
  final String? plateNumber;
  final String? driverName;

  @override
  ConsumerState<DriverLiveMapCard> createState() => _DriverLiveMapCardState();
}

class _DriverLiveMapCardState extends ConsumerState<DriverLiveMapCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _defaultZoom = 16.0;

  late final MapController _mapController;
  late final AnimationController _markerAnimController;
  LocationService? _locationService;
  VoidCallback? _releaseObserver;
  StreamSubscription<Position>? _positionSub;

  bool _mapReady = false;
  bool _followDriver = true;
  double _currentZoom = _defaultZoom;

  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  LatLng? _displayLatLng;
  double _fromHeading = 0;
  double _toHeading = 0;
  double _displayHeading = 0;
  bool _isMoving = false;
  double? _lastAccuracyMeters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(_onAnimationTick);

    _attachLocationService();
  }

  void _attachLocationService() {
    final service = ref.read(locationServiceProvider);
    _locationService = service;
    _releaseObserver = service.retainUiLocationObserver();
    service.locationState.addListener(_handleLocationStateChanged);

    final initialPos = service.locationState.value.position ?? service.lastPosition;
    if (initialPos != null) {
      _applyNewPosition(initialPos, animate: false);
    }

    _positionSub = service.positionStream.listen((pos) {
      if (!mounted) return;
      _applyNewPosition(pos, animate: true);
    });
  }

  void _handleLocationStateChanged() {
    if (!mounted) return;
    final state = _locationService?.locationState.value;
    if (state != null && state.position != null && _displayLatLng == null) {
      _applyNewPosition(state.position!, animate: false);
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = _locationService;
    if (service == null) return;
    if (state == AppLifecycleState.resumed) {
      _releaseObserver ??= service.retainUiLocationObserver();
      unawaited(service.refreshUiLocation(requestPermission: false));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _releaseObserver?.call();
      _releaseObserver = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService?.locationState.removeListener(_handleLocationStateChanged);
    _positionSub?.cancel();
    _positionSub = null;
    _releaseObserver?.call();
    _releaseObserver = null;
    _markerAnimController.removeListener(_onAnimationTick);
    _markerAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!mounted || _fromLatLng == null || _toLatLng == null) return;
    final t = Curves.easeOutCubic.transform(_markerAnimController.value);
    final lat =
        _fromLatLng!.latitude + (_toLatLng!.latitude - _fromLatLng!.latitude) * t;
    final lng =
        _fromLatLng!.longitude +
        (_toLatLng!.longitude - _fromLatLng!.longitude) * t;
    final nextPoint = LatLng(lat, lng);

    var delta = ((_toHeading - _fromHeading + 540.0) % 360.0) - 180.0;
    final nextHeading = (_fromHeading + delta * t + 360.0) % 360.0;

    setState(() {
      _displayLatLng = nextPoint;
      _displayHeading = nextHeading;
    });
  }

  void _applyNewPosition(Position pos, {required bool animate}) {
    final nextLatLng = LatLng(pos.latitude, pos.longitude);
    final distanceMoved = _displayLatLng == null
        ? 0.0
        : Geolocator.distanceBetween(
            _displayLatLng!.latitude,
            _displayLatLng!.longitude,
            nextLatLng.latitude,
            nextLatLng.longitude,
          );

    double resolvedHeading = _displayHeading;
    if (pos.heading.isFinite && pos.heading >= 0 && (pos.speed > 0.4 || pos.heading > 0)) {
      resolvedHeading = pos.heading % 360.0;
    } else if (_displayLatLng != null && distanceMoved >= 2.0) {
      resolvedHeading = _computeBearing(_displayLatLng!, nextLatLng);
    }

    final movingNow = (pos.speed.isFinite && pos.speed > 0.6) || distanceMoved >= 3.0;
    _lastAccuracyMeters = pos.accuracy.isFinite ? pos.accuracy : null;

    if (!animate || _displayLatLng == null || distanceMoved < 0.3) {
      _fromLatLng = nextLatLng;
      _toLatLng = nextLatLng;
      _fromHeading = resolvedHeading;
      _toHeading = resolvedHeading;
      if (mounted) {
        setState(() {
          _displayLatLng = nextLatLng;
          _displayHeading = resolvedHeading;
          _isMoving = movingNow;
        });
      }
    } else {
      _fromLatLng = _displayLatLng;
      _toLatLng = nextLatLng;
      _fromHeading = _displayHeading;
      _toHeading = resolvedHeading;
      _isMoving = movingNow;
      _markerAnimController.forward(from: 0.0);
    }

    if (_followDriver && _mapReady) {
      try {
        _mapController.move(nextLatLng, _currentZoom);
      } catch (_) {}
    }
  }

  double _computeBearing(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lon1 = from.longitudeInRad;
    final lat2 = to.latitudeInRad;
    final lon2 = to.longitudeInRad;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  void _recenterOnDriver() {
    final target = _toLatLng ?? _displayLatLng;
    if (target == null) {
      unawaited(_locationService?.refreshUiLocation(requestPermission: false));
      return;
    }
    setState(() {
      _followDriver = true;
      _currentZoom = math.max(_currentZoom, _defaultZoom);
    });
    if (_mapReady) {
      try {
        _mapController.move(target, _currentZoom);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusInfo = DriverStatusPresentation.resolve(widget.driverStatus, l10n);
    final vehicleNorm =
        VehicleTypeHelper.normalize(widget.vehicleType) ??
        VehicleTypeHelper.motorcycle;
    final resolvedVehicleType =
        vehicleNorm.isEmpty ? VehicleTypeHelper.motorcycle : vehicleNorm;
    final vehicleLabel = VehicleTypeHelper.label(
      resolvedVehicleType,
      isArabic: isAr,
    );
    final vehicleIcon = VehicleTypeHelper.icon(resolvedVehicleType);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = screenHeight < 680 ? 220.0 : 265.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.isWorkingShift
              ? statusInfo.accent.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBar(
            context,
            l10n: l10n,
            statusInfo: statusInfo,
            vehicleIcon: vehicleIcon,
            vehicleLabel: vehicleLabel,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: mapHeight,
                child: _buildMapArea(
                  context,
                  l10n: l10n,
                  isDark: isDark,
                  isAr: isAr,
                  statusInfo: statusInfo,
                  vehicleNorm: resolvedVehicleType,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context, {
    required AppLocalizations l10n,
    required DriverStatusPresentation statusInfo,
    required IconData vehicleIcon,
    required String vehicleLabel,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final plate = widget.plateNumber?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusInfo.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.mapPin,
              size: 18,
              color: statusInfo.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.liveMapTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      vehicleIcon,
                      size: 13,
                      color: onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        plate.isNotEmpty ? '$vehicleLabel • $plate' : vehicleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: statusInfo.accent.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusInfo.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusInfo.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea(
    BuildContext context, {
    required AppLocalizations l10n,
    required bool isDark,
    required bool isAr,
    required DriverStatusPresentation statusInfo,
    required String vehicleNorm,
  }) {
    final locationState =
        _locationService?.locationState.value ?? const DriverLocationState.loading();
    final centerPoint = _displayLatLng;

    if (centerPoint == null) {
      return _buildUnavailableState(
        context,
        l10n: l10n,
        isDark: isDark,
        locationState: locationState,
      );
    }

    final resolvedVehicleType =
        vehicleNorm.isEmpty ? VehicleTypeHelper.motorcycle : vehicleNorm;
    final labelText = (widget.plateNumber?.trim().isNotEmpty ?? false)
        ? widget.plateNumber!.trim()
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: _currentZoom,
            minZoom: 5.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              _mapReady = true;
              if (_followDriver && _toLatLng != null) {
                try {
                  _mapController.move(_toLatLng!, _currentZoom);
                } catch (_) {}
              }
            },
            onPositionChanged: (camera, hasGesture) {
              _currentZoom = camera.zoom;
              if (hasGesture && _followDriver) {
                setState(() => _followDriver = false);
              }
            },
          ),
          children: [
            AppMapTileLayer(
              style: isDark
                  ? AppMapStyle.navigationDark
                  : AppMapStyle.navigationLight,
              userAgentPackageName: 'com.otlobegy.driver',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: centerPoint,
                  width: 82,
                  height: 82,
                  child: RepaintBoundary(
                    child: InDriveVehicleMarker(
                      size: 48,
                      heading: _displayHeading,
                      isMoving: _isMoving,
                      vehicleType: resolvedVehicleType,
                      plateNumber: widget.plateNumber?.trim(),
                      label: labelText,
                      color: AppColors.primary,
                      showRadarPulse: statusInfo.isWorkingShift,
                      showHeadlightGlow: statusInfo.isWorkingShift,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_lastAccuracyMeters != null)
          Positioned.directional(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            bottom: 10,
            start: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.backgroundDark : Colors.white)
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    'GPS ±${_lastAccuracyMeters!.round()}m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.directional(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          bottom: 10,
          end: 10,
          child: Material(
            color: _followDriver
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : AppColors.primary,
            elevation: 4,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              key: const ValueKey('dashboard_live_map_recenter_btn'),
              onTap: _recenterOnDriver,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: _followDriver
                          ? statusInfo.accent
                          : AppColors.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.liveMapCenterButton,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _followDriver
                            ? Theme.of(context).colorScheme.onSurface
                            : AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableState(
    BuildContext context, {
    required AppLocalizations l10n,
    required bool isDark,
    required DriverLocationState locationState,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bgColor =
        isDark ? AppColors.backgroundDark.withValues(alpha: 0.7) : AppColors.surfaceLight;

    if (locationState.status == DriverLocationStatus.loading) {
      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.liveMapLoading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    late final IconData icon;
    late final Color iconColor;
    late final String title;
    late final String subtitle;
    late final String buttonLabel;
    late final VoidCallback onAction;

    switch (locationState.status) {
      case DriverLocationStatus.serviceDisabled:
        icon = Icons.location_off_rounded;
        iconColor = AppColors.warning;
        title = l10n.liveMapGpsDisabledTitle;
        subtitle = l10n.liveMapGpsDisabledSubtitle;
        buttonLabel = l10n.locationRequiredButton;
        onAction = () async {
          await _locationService?.openLocationSettings();
          if (mounted) {
            await _locationService?.refreshUiLocation(requestPermission: false);
          }
        };
        break;
      case DriverLocationStatus.permissionDenied:
        icon = Icons.location_disabled_rounded;
        iconColor = AppColors.info;
        title = l10n.liveMapPermissionDeniedTitle;
        subtitle = l10n.liveMapPermissionDeniedSubtitle;
        buttonLabel = l10n.liveMapAllowAction;
        onAction = () {
          unawaited(_locationService?.refreshUiLocation(requestPermission: true));
        };
        break;
      case DriverLocationStatus.permissionDeniedForever:
        icon = Icons.location_disabled_rounded;
        iconColor = AppColors.error;
        title = l10n.liveMapPermissionDeniedTitle;
        subtitle = l10n.liveMapPermissionDeniedForeverSubtitle;
        buttonLabel = l10n.liveMapOpenSettingsAction;
        onAction = () async {
          await _locationService?.openAppSettings();
          if (mounted) {
            await _locationService?.refreshUiLocation(requestPermission: false);
          }
        };
        break;
      case DriverLocationStatus.error:
      case DriverLocationStatus.ready:
      case DriverLocationStatus.loading:
        icon = LucideIcons.mapPin;
        iconColor = AppColors.error;
        title = l10n.liveMapErrorTitle;
        subtitle = l10n.liveMapPermissionDeniedSubtitle;
        buttonLabel = l10n.liveMapRetryAction;
        onAction = () {
          unawaited(_locationService?.refreshUiLocation(requestPermission: true));
        };
        break;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
