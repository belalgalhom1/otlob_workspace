import 'dart:ui' show lerpDouble;

import 'package:core/core.dart'
    show ApiErrorMapper, OrderTypeHelper, VehicleTypeHelper;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart'
    show
        AppMapStyle,
        AppMapTileLayer,
        DriverSearchRadarPulse,
        InDriveVehicleMarker,
        NavigationRoutePolylines;
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/custom_delivery_search_controller.dart';
import '../widgets/custom_delivery_search_sheets.dart';

/// Interpolates between two compass bearings in degrees along the shortest arc.
double _lerpAngleDegrees(double fromDeg, double toDeg, double t) {
  final delta = ((toDeg - fromDeg + 540.0) % 360.0) - 180.0;
  return (fromDeg + delta * t + 360.0) % 360.0;
}

class _SearchLifecycleObserver with WidgetsBindingObserver {
  _SearchLifecycleObserver({required this.onResume, required this.onPause});
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      onPause();
    }
  }
}

/// Real-time Custom Delivery & Ride Driver Search Screen inspired by inDrive's
/// map-first matching flow while preserving Otlob branding, zero-lag rebuild
/// isolation, full SafeArea compliance, and arbitrary [TextScaler] adaptation.
class CustomDeliverySearchScreen extends ConsumerStatefulWidget {
  const CustomDeliverySearchScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.mapBuilder,
  });

  final String orderId;
  final Map<String, dynamic>? initialOrder;

  /// Optional override primarily for fast deterministic widget testing without
  /// network tile fetches.
  final Widget Function(BuildContext, CustomDeliverySearchState)? mapBuilder;

  @override
  ConsumerState<CustomDeliverySearchScreen> createState() =>
      _CustomDeliverySearchScreenState();
}

class _CustomDeliverySearchScreenState
    extends ConsumerState<CustomDeliverySearchScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final _SearchLifecycleObserver _lifecycleObserver;
  late final AnimationController _cameraAnimController;

  LatLng? _camFromCenter;
  LatLng? _camToCenter;
  double? _camFromZoom;
  double? _camToZoom;

  bool _hasFittedInitialBounds = false;
  bool _hasFittedDriverMatchBounds = false;
  bool _hasFittedAssignedDriverLocation = false;
  ValueListenable<DriverLiveMarkerState?>? _observedDriverLocListenable;
  String? _lastShownNotice;

  @override
  void initState() {
    super.initState();
    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(_onCameraAnimationTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = ref.read(
        customDeliverySearchControllerProvider(widget.orderId).notifier,
      );
      ctrl.seedOrderSnapshot(widget.initialOrder);
      _attachDriverLocationFitListener(ctrl.driverLocationNotifier);
    });

    _lifecycleObserver = _SearchLifecycleObserver(
      onResume: () {
        if (!mounted) return;
        ref
            .read(
              customDeliverySearchControllerProvider(widget.orderId).notifier,
            )
            .onAppResumed();
      },
      onPause: () {
        if (!mounted) return;
        ref
            .read(
              customDeliverySearchControllerProvider(widget.orderId).notifier,
            )
            .onAppPaused();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  void _onCameraAnimationTick() {
    if (!mounted ||
        _camFromCenter == null ||
        _camToCenter == null ||
        _camFromZoom == null ||
        _camToZoom == null) {
      return;
    }
    final t = Curves.easeOutCubic.transform(_cameraAnimController.value);
    final lat = lerpDouble(
      _camFromCenter!.latitude,
      _camToCenter!.latitude,
      t,
    )!;
    final lng = lerpDouble(
      _camFromCenter!.longitude,
      _camToCenter!.longitude,
      t,
    )!;
    final zoom = lerpDouble(_camFromZoom!, _camToZoom!, t)!;
    try {
      _mapController.move(LatLng(lat, lng), zoom);
    } catch (_) {
      // Ignore if map controller is not attached yet.
    }
  }

  void _cancelCameraAnimation() {
    if (_cameraAnimController.isAnimating) {
      _cameraAnimController.stop();
    }
  }

  void _attachDriverLocationFitListener(
    ValueListenable<DriverLiveMarkerState?> listenable,
  ) {
    if (_observedDriverLocListenable == listenable) return;
    _observedDriverLocListenable?.removeListener(_onFirstAssignedDriverLocation);
    _observedDriverLocListenable = listenable;
    listenable.addListener(_onFirstAssignedDriverLocation);
  }

  void _onFirstAssignedDriverLocation() {
    if (!mounted || _hasFittedAssignedDriverLocation) return;
    final live = _observedDriverLocListenable?.value;
    if (live == null) return;
    final currentState = ref.read(
      customDeliverySearchControllerProvider(widget.orderId),
    );
    if (!currentState.isDriverMatched) return;
    _hasFittedAssignedDriverLocation = true;
    _recenterMap(currentState, live, animated: true);
  }

  @override
  void dispose() {
    _observedDriverLocListenable?.removeListener(_onFirstAssignedDriverLocation);
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _cameraAnimController.removeListener(_onCameraAnimationTick);
    _cameraAnimController.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _animateCameraToPoints(List<LatLng> points, {bool animated = true}) {
    if (points.isEmpty || widget.mapBuilder != null || !mounted) return;
    try {
      final currentCamera = _mapController.camera;
      LatLng targetCenter;
      double targetZoom;

      if (points.length == 1) {
        targetCenter = points.first;
        targetZoom = 14.8;
      } else {
        final bounds = LatLngBounds.fromPoints(points);
        final screenHeight = MediaQuery.sizeOf(context).height;
        final topInset = MediaQuery.paddingOf(context).top;
        final fitted = CameraFit.bounds(
          bounds: bounds,
          maxZoom: 16.2,
          padding: EdgeInsets.fromLTRB(
            52,
            topInset + 96,
            52,
            (screenHeight * 0.44).clamp(160.0, 380.0),
          ),
        ).fit(currentCamera);
        targetCenter = fitted.center;
        targetZoom = fitted.zoom;
      }

      if (!animated) {
        _cancelCameraAnimation();
        _mapController.move(targetCenter, targetZoom);
        return;
      }

      _camFromCenter = currentCamera.center;
      _camFromZoom = currentCamera.zoom;
      _camToCenter = targetCenter;
      _camToZoom = targetZoom;
      _cameraAnimController.forward(from: 0.0);
    } catch (_) {
      try {
        _mapController.move(points.first, 14.2);
      } catch (_) {}
    }
  }

  void _recenterMap(
    CustomDeliverySearchState state,
    DriverLiveMarkerState? driverLoc, {
    bool animated = true,
  }) {
    final pts = <LatLng>[];
    if (state.isDriverArrived && state.pickupPoint != null) {
      pts.add(state.pickupPoint!);
      if (driverLoc != null) pts.add(driverLoc.position);
    } else if (state.isTripInProgress) {
      if (driverLoc != null) pts.add(driverLoc.position);
      if (state.dropoffPoint != null) pts.add(state.dropoffPoint!);
      if (pts.isEmpty && state.pickupPoint != null) {
        pts.add(state.pickupPoint!);
      }
    } else {
      if (state.pickupPoint != null) pts.add(state.pickupPoint!);
      if (state.dropoffPoint != null) pts.add(state.dropoffPoint!);
      if (state.isDriverMatched && driverLoc != null) {
        pts.add(driverLoc.position);
      }
    }
    if (pts.isNotEmpty) {
      _animateCameraToPoints(pts, animated: animated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = customDeliverySearchControllerProvider(widget.orderId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final currency =
        ref.watch(platformSettingsProvider).value?.currency ?? 'EGP';

    ref.listen<CustomDeliverySearchState>(provider, (prev, next) {
      if (!mounted) return;
      final notice = next.transientNoticeKey;
      if (notice != null && notice != _lastShownNotice) {
        _lastShownNotice = notice;
        final text = notice.startsWith('app.')
            ? notice.tr(context: context)
            : ApiErrorMapper.translate(notice, context: context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.clearTransientNotice();
        });
      } else if (notice == null) {
        _lastShownNotice = null;
      }

      if (!_hasFittedInitialBounds &&
          (next.pickupPoint != null || next.dropoffPoint != null)) {
        _hasFittedInitialBounds = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _recenterMap(
              next,
              controller.driverLocationNotifier.value,
              animated: false,
            );
          }
        });
      }
      if ((prev?.isDriverMatched != true) && next.isDriverMatched) {
        if (!_hasFittedDriverMatchBounds) {
          _hasFittedDriverMatchBounds = true;
          final live = controller.driverLocationNotifier.value;
          if (live != null) {
            _hasFittedAssignedDriverLocation = true;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _recenterMap(
                next,
                controller.driverLocationNotifier.value,
                animated: true,
              );
            }
          });
        }
      } else if (!next.isDriverMatched) {
        _hasFittedDriverMatchBounds = false;
        _hasFittedAssignedDriverLocation = false;
      }

      if (prev != null && prev.orderStatus != next.orderStatus) {
        if (next.isDriverArrived || next.isTripInProgress || next.isTripCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _recenterMap(
                next,
                controller.driverLocationNotifier.value,
                animated: true,
              );
            }
          });
        }
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    if (state.isInitialLoading && state.order == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'app.searchQueuedStatus'.tr(context: context),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state.errorKey != null && state.order == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorKey!.startsWith('app.')
                        ? state.errorKey!.tr(context: context)
                        : ApiErrorMapper.translate(
                            state.errorKey!,
                            context: context,
                          ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => controller.resync(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('app.retrySearch'.tr(context: context)),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/orders');
                          }
                        },
                        child: Text('app.backToHome'.tr(context: context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.mapBuilder != null
                ? widget.mapBuilder!(context, state)
                : _buildInteractiveMap(context, state, controller, isDark),
          ),
          // Top floating navigation + service pill + connection status bar inside SafeArea.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _FloatingCircleAction(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/orders');
                            }
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _OrderStatusHeaderBadge(
                              orderNumber: (state.order?['orderNumber'] ?? '')
                                  .toString(),
                              isRide: state.isRide,
                              vehicleType: state.requestedVehicleType,
                              isRefreshing: state.isRefreshing,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FloatingCircleAction(
                          icon: Icons.my_location_rounded,
                          tooltip: 'app.recenterMapTooltip'.tr(
                            context: context,
                          ),
                          onPressed: () => _recenterMap(
                            state,
                            controller.driverLocationNotifier.value,
                            animated: true,
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    if (state.isSearching &&
                        !state.isOffline &&
                        !state.isSocketReconnecting) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _LiveNearbyVehiclesFloatingPill(
                          vehiclesListenable: controller.nearbyVehiclesNotifier,
                          vehicleType: state.requestedVehicleType,
                          isDark: isDark,
                        ),
                      ),
                    ],
                    if (state.isDriverMatched &&
                        !state.isOffline &&
                        !state.isSocketReconnecting) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _LiveJourneyStatusFloatingPill(
                          state: state,
                          driverLocationListenable:
                              controller.driverLocationNotifier,
                          isDark: isDark,
                        ),
                      ),
                    ],
                    if (state.isOffline || state.isSocketReconnecting) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: state.isOffline
                              ? AppColors.error
                              : Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              state.isOffline
                                  ? Icons.wifi_off_rounded
                                  : Icons.sync_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.isOffline
                                    ? 'app.offlineSearchBanner'.tr(
                                        context: context,
                                      )
                                    : 'app.reconnectingStatus'.tr(
                                        context: context,
                                      ),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Responsive, draggable, SafeArea-aware bottom sheet.
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.44,
            minChildSize: 0.26,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: const [0.28, 0.45, 0.88],
            builder: (sheetCtx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161616) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16 + bottomInset,
                        ),
                        child: CustomDeliverySearchSheetBody(
                          state: state,
                          driverLocationListenable:
                              controller.driverLocationNotifier,
                          nearbyVehiclesListenable:
                              controller.nearbyVehiclesNotifier,
                          onCancelConfirmed: () => controller.cancelSearch(),
                          onRetrySearch: () => controller.retrySearch(),
                          onPaymentSubmitted: () => controller.resync(),
                          onEditRequest: () {
                            final draft = CustomDeliveryDraft.fromOrder(
                              state.order,
                            );
                            context.go('/custom-delivery', extra: draft);
                          },
                          currency: currency,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(
    BuildContext context,
    CustomDeliverySearchState state,
    CustomDeliverySearchController controller,
    bool isDark,
  ) {
    final pickup = state.pickupPoint;
    final dropoff = state.dropoffPoint;
    final initialCenter = pickup ?? dropoff ?? const LatLng(30.0444, 31.2357);

    final polylinePoints =
        state.routePoints ??
        ((pickup != null && dropoff != null)
            ? <LatLng>[pickup, dropoff]
            : const <LatLng>[]);

    final driverVehicleType =
        (state.driver?['vehicleType'] ?? state.requestedVehicleType).toString();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14.0,
        minZoom: 4,
        maxZoom: 18.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapEvent: (event) {
          if (event.source == MapEventSource.onDrag ||
              event.source == MapEventSource.onMultiFinger ||
              event.source == MapEventSource.scrollWheel) {
            _cancelCameraAnimation();
          }
        },
      ),
      children: [
        const AppMapTileLayer(
          style: AppMapStyle.auto,
          userAgentPackageName: 'com.otlob.customer',
        ),
        // 1. Primary Pickup -> Destination trip route
        if (polylinePoints.length >= 2)
          RepaintBoundary(
            child: PolylineLayer(
              polylines: NavigationRoutePolylines.build(
                points: polylinePoints,
                foregroundColor: AppColors.primary,
                casingColor: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                    : const Color(0xFF1E293B).withValues(alpha: 0.72),
                strokeWidth: 5.2,
                casingWidth: 8.8,
              ),
            ),
          ),
        // 2. Assigned Driver -> Active target (Pickup or Destination) live road route
        if (state.isDriverMatched && !state.isDriverArrived && !state.isTripCompleted)
          _DriverApproachRouteLayer(
            routeListenable: controller.driverApproachRouteNotifier,
            isDark: isDark,
            routeColor: state.isTripInProgress
                ? AppColors.success
                : const Color(0xFF2563EB),
          ),
        // 3. Repaint-isolated radar pulse centered on pickup while actively searching.
        if (pickup != null && state.isSearching)
          MarkerLayer(
            markers: [
              Marker(
                point: pickup,
                width: 248,
                height: 248,
                alignment: Alignment.center,
                child: DriverSearchRadarPulse(
                  size: 248,
                  color: AppColors.primary,
                  isActive: !state.isOffline,
                ),
              ),
            ],
          ),
        // 4. Single-ticker 60fps real-time animated nearby vehicles layer.
        _AnimatedNearbyVehiclesLayer(
          vehiclesListenable: controller.nearbyVehiclesNotifier,
          isRide: state.isRide,
          isActive: state.isSearching,
        ),
        // 5. Clear Pickup & Destination endpoint markers with floating labels.
        RepaintBoundary(
          child: MarkerLayer(
            markers: [
              if (pickup != null)
                Marker(
                  point: pickup,
                  width: 112,
                  height: 70,
                  alignment: Alignment.center,
                  child: _MapEndpointMarker(
                    icon: Icons.trip_origin_rounded,
                    label: (state.isRide
                            ? 'app.mapRidePickupPinLabel'
                            : 'app.mapPickupPinLabel')
                        .tr(context: context),
                    color: AppColors.primary,
                    foreground: Colors.black,
                    isDark: isDark,
                  ),
                ),
              if (dropoff != null)
                Marker(
                  point: dropoff,
                  width: 112,
                  height: 70,
                  alignment: Alignment.center,
                  child: _MapEndpointMarker(
                    icon: Icons.flag_rounded,
                    label: (state.isRide
                            ? 'app.mapRideDropoffPinLabel'
                            : 'app.mapDropoffPinLabel')
                        .tr(context: context),
                    color: const Color(0xFFEF4444),
                    foreground: Colors.white,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ),
        // 6. Smooth live assigned driver marker isolated from whole-screen rebuilds.
        if (state.isDriverMatched)
          _AnimatedAssignedDriverLayer(
            locationListenable: controller.driverLocationNotifier,
            vehicleType: driverVehicleType,
            plateNumber: state.driver?['vehiclePlate']?.toString(),
            showCargoBox: !state.isRide,
          ),
      ],
    );
  }
}

/// Repaint-isolated live route from the assigned driver's real position
/// to the active waypoint (pickup before start, destination during trip).
class _DriverApproachRouteLayer extends StatelessWidget {
  const _DriverApproachRouteLayer({
    required this.routeListenable,
    required this.isDark,
    this.routeColor = const Color(0xFF2563EB),
  });

  final ValueListenable<List<LatLng>> routeListenable;
  final bool isDark;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<List<LatLng>>(
        valueListenable: routeListenable,
        builder: (context, points, _) {
          if (points.length < 2) return const SizedBox.shrink();
          return PolylineLayer(
            polylines: NavigationRoutePolylines.build(
              points: points,
              foregroundColor: routeColor,
              casingColor: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.90),
              strokeWidth: 4.5,
              casingWidth: 7.5,
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedVehicleSlot {
  _AnimatedVehicleSlot({
    required this.markerKey,
    required this.vehicleType,
    required LatLng position,
    required double heading,
    required this.isMoving,
    required Duration now,
  }) : fromPos = position,
       toPos = position,
       currentPos = position,
       fromHeading = heading,
       toHeading = heading,
       currentHeading = heading,
       moveStart = now,
       rotStart = now,
       fadeStart = now,
       fromOpacity = 0.0,
       toOpacity = 0.96,
       currentOpacity = 0.0,
       fromScale = 0.65,
       toScale = 1.0,
       currentScale = 0.65,
       isExiting = false;

  final String markerKey;
  String vehicleType;
  LatLng fromPos;
  LatLng toPos;
  LatLng currentPos;
  double fromHeading;
  double toHeading;
  double currentHeading;
  bool isMoving;

  Duration moveStart;
  Duration rotStart;
  Duration fadeStart;

  double fromOpacity;
  double toOpacity;
  double currentOpacity;
  double fromScale;
  double toScale;
  double currentScale;
  bool isExiting;

  static const int _moveDurationMs = 3400;
  static const int _rotDurationMs = 700;
  static const int _fadeInDurationMs = 420;
  static const int _fadeOutDurationMs = 340;

  void updateTarget({
    required LatLng nextPos,
    required double nextHeading,
    required String nextVehicleType,
    required bool nextIsMoving,
    required Duration now,
  }) {
    vehicleType = nextVehicleType;
    final posChanged =
        (toPos.latitude - nextPos.latitude).abs() > 1e-7 ||
        (toPos.longitude - nextPos.longitude).abs() > 1e-7;
    if (posChanged) {
      fromPos = currentPos;
      toPos = nextPos;
      moveStart = now;
    }

    final headingDelta = ((nextHeading - toHeading + 540.0) % 360.0) - 180.0;
    if (headingDelta.abs() > 1.5) {
      fromHeading = currentHeading;
      toHeading = nextHeading;
      rotStart = now;
    }

    isMoving = nextIsMoving;

    if (isExiting) {
      isExiting = false;
      fromOpacity = currentOpacity;
      toOpacity = 0.96;
      fromScale = currentScale;
      toScale = 1.0;
      fadeStart = now;
    }
  }

  void startExit(Duration now) {
    if (isExiting) return;
    isExiting = true;
    isMoving = false;
    fromOpacity = currentOpacity;
    toOpacity = 0.0;
    fromScale = currentScale;
    toScale = 0.62;
    fadeStart = now;
  }

  /// Advances slot interpolation and returns `true` if still animating.
  bool advance(Duration now) {
    var active = false;

    final moveElapsed = (now - moveStart).inMilliseconds;
    if (moveElapsed < _moveDurationMs && fromPos != toPos) {
      final raw = (moveElapsed / _moveDurationMs).clamp(0.0, 1.0);
      final t = Curves.easeInOutCubic.transform(raw);
      currentPos = LatLng(
        fromPos.latitude + (toPos.latitude - fromPos.latitude) * t,
        fromPos.longitude + (toPos.longitude - fromPos.longitude) * t,
      );
      active = true;
    } else {
      currentPos = toPos;
      fromPos = toPos;
      isMoving = false;
    }

    final rotElapsed = (now - rotStart).inMilliseconds;
    if (rotElapsed < _rotDurationMs &&
        (((toHeading - fromHeading + 540.0) % 360.0) - 180.0).abs() > 0.25) {
      final raw = (rotElapsed / _rotDurationMs).clamp(0.0, 1.0);
      final t = Curves.easeOutCubic.transform(raw);
      currentHeading = _lerpAngleDegrees(fromHeading, toHeading, t);
      active = true;
    } else {
      currentHeading = toHeading;
      fromHeading = toHeading;
    }

    final fadeDuration = isExiting ? _fadeOutDurationMs : _fadeInDurationMs;
    final fadeElapsed = (now - fadeStart).inMilliseconds;
    final needsFade =
        (fromOpacity - toOpacity).abs() > 0.005 ||
        (fromScale - toScale).abs() > 0.005;
    if (needsFade && fadeElapsed < fadeDuration) {
      final raw = (fadeElapsed / fadeDuration).clamp(0.0, 1.0);
      final opacityT = Curves.easeOut.transform(raw);
      final scaleT = isExiting
          ? Curves.easeIn.transform(raw)
          : Curves.easeOutBack.transform(raw);
      currentOpacity = lerpDouble(fromOpacity, toOpacity, opacityT)!.clamp(
        0.0,
        1.0,
      );
      currentScale = lerpDouble(fromScale, toScale, scaleT)!.clamp(0.5, 1.12);
      active = true;
    } else {
      currentOpacity = toOpacity;
      fromOpacity = toOpacity;
      currentScale = toScale;
      fromScale = toScale;
    }

    return active;
  }

  bool get shouldRemove => isExiting && currentOpacity <= 0.01;
}

/// High-performance single-ticker animation layer for ALL real anonymized
/// nearby vehicles on the map.
///
/// Guarantees:
/// - Exactly ONE [Ticker] shared across all visible vehicles (never 1 per marker).
/// - Automatically stops the [Ticker] when all vehicles settle (0% idle CPU).
/// - Completely repaint-isolated from tiles, polylines, and the bottom sheet.
/// - Strictly interpolates between real backend coordinates only.
class _AnimatedNearbyVehiclesLayer extends StatefulWidget {
  const _AnimatedNearbyVehiclesLayer({
    required this.vehiclesListenable,
    required this.isRide,
    required this.isActive,
  });

  final ValueListenable<List<NearbyVehicleMarkerState>> vehiclesListenable;
  final bool isRide;
  final bool isActive;

  @override
  State<_AnimatedNearbyVehiclesLayer> createState() =>
      _AnimatedNearbyVehiclesLayerState();
}

class _AnimatedNearbyVehiclesLayerState
    extends State<_AnimatedNearbyVehiclesLayer>
    with SingleTickerProviderStateMixin {
  final Map<String, _AnimatedVehicleSlot> _slots = {};
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.vehiclesListenable.addListener(_syncFromListenable);
    _syncFromListenable();
  }

  @override
  void didUpdateWidget(covariant _AnimatedNearbyVehiclesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehiclesListenable != widget.vehiclesListenable) {
      oldWidget.vehiclesListenable.removeListener(_syncFromListenable);
      widget.vehiclesListenable.addListener(_syncFromListenable);
      _syncFromListenable();
    } else if (oldWidget.isActive != widget.isActive) {
      _syncFromListenable();
    }
  }

  Duration _nowElapsed() {
    return _ticker.isActive ? _lastElapsed : Duration.zero;
  }

  void _syncFromListenable() {
    if (!mounted) return;
    final incoming = widget.isActive
        ? widget.vehiclesListenable.value
        : const <NearbyVehicleMarkerState>[];
    final now = _nowElapsed();
    final seen = <String>{};

    for (final vehicle in incoming) {
      seen.add(vehicle.markerKey);
      final existing = _slots[vehicle.markerKey];
      if (existing == null) {
        _slots[vehicle.markerKey] = _AnimatedVehicleSlot(
          markerKey: vehicle.markerKey,
          vehicleType: vehicle.vehicleType,
          position: vehicle.position,
          heading: vehicle.heading,
          isMoving: vehicle.isMoving,
          now: now,
        );
      } else {
        existing.updateTarget(
          nextPos: vehicle.position,
          nextHeading: vehicle.heading,
          nextVehicleType: vehicle.vehicleType,
          nextIsMoving: vehicle.isMoving,
          now: now,
        );
      }
    }

    for (final entry in _slots.entries) {
      if (!seen.contains(entry.key)) {
        entry.value.startExit(now);
      }
    }

    if (_slots.isNotEmpty) {
      _ensureTicking();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      // Re-anchor active slot start timestamps to 0 before restarting ticker.
      for (final slot in _slots.values) {
        slot.moveStart = Duration.zero;
        slot.rotStart = Duration.zero;
        slot.fadeStart = Duration.zero;
      }
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _lastElapsed = elapsed;
    if (!mounted) {
      _ticker.stop();
      return;
    }

    var anyAnimating = false;
    final toRemove = <String>[];

    for (final entry in _slots.entries) {
      final slot = entry.value;
      if (slot.advance(elapsed)) {
        anyAnimating = true;
      }
      if (slot.shouldRemove) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _slots.remove(key);
    }

    setState(() {});

    if (!anyAnimating) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.vehiclesListenable.removeListener(_syncFromListenable);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slots.isEmpty) return const SizedBox.shrink();
    return RepaintBoundary(
      child: MarkerLayer(
        markers: _slots.values
            .map((slot) {
              return Marker(
                key: ValueKey('nearby_${slot.markerKey}'),
                point: slot.currentPos,
                width: 54,
                height: 54,
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: slot.currentOpacity,
                    child: Transform.scale(
                      scale: slot.currentScale,
                      child: InDriveVehicleMarker(
                        size: 40,
                        color: AppColors.primary,
                        heading: slot.currentHeading,
                        isMoving: slot.isMoving,
                        vehicleType: slot.vehicleType,
                        showHeadlightGlow: slot.isMoving,
                        showRadarPulse: false,
                        showCargoBox: !widget.isRide,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _AnimatedAssignedDriverLayer extends StatefulWidget {
  const _AnimatedAssignedDriverLayer({
    required this.locationListenable,
    required this.vehicleType,
    required this.showCargoBox,
    this.plateNumber,
  });

  final ValueListenable<DriverLiveMarkerState?> locationListenable;
  final String vehicleType;
  final bool showCargoBox;
  final String? plateNumber;

  @override
  State<_AnimatedAssignedDriverLayer> createState() =>
      _AnimatedAssignedDriverLayerState();
}

class _AnimatedAssignedDriverLayerState
    extends State<_AnimatedAssignedDriverLayer>
    with TickerProviderStateMixin {
  late final AnimationController _moveController;
  late final AnimationController _entryController;
  LatLng? _from;
  LatLng? _to;
  LatLng? _current;
  double _fromHeading = 0.0;
  double _toHeading = 0.0;
  double _heading = 0.0;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..addListener(_onAnimationTick);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    widget.locationListenable.addListener(_onLocationChanged);
    _applyInitial(widget.locationListenable.value);
  }

  void _applyInitial(DriverLiveMarkerState? snapshot) {
    if (snapshot == null) return;
    _current = snapshot.position;
    _from = snapshot.position;
    _to = snapshot.position;
    _fromHeading = snapshot.heading;
    _toHeading = snapshot.heading;
    _heading = snapshot.heading;
    _isMoving = snapshot.isMoving;
    _entryController.forward(from: 0.0);
  }

  void _onLocationChanged() {
    final next = widget.locationListenable.value;
    if (next == null || !mounted) return;
    if (_current == null) {
      setState(() => _applyInitial(next));
      return;
    }
    _from = _current;
    _to = next.position;
    _fromHeading = _heading;
    _toHeading = next.heading;
    _isMoving = next.isMoving;
    _moveController.forward(from: 0);
  }

  void _onAnimationTick() {
    if (_from == null || _to == null || !mounted) return;
    final t = Curves.easeOutCubic.transform(_moveController.value);
    setState(() {
      _current = LatLng(
        _from!.latitude + (_to!.latitude - _from!.latitude) * t,
        _from!.longitude + (_to!.longitude - _from!.longitude) * t,
      );
      _heading = _lerpAngleDegrees(_fromHeading, _toHeading, t);
      if (t >= 1.0) {
        _isMoving = false;
      }
    });
  }

  @override
  void dispose() {
    widget.locationListenable.removeListener(_onLocationChanged);
    _moveController.removeListener(_onAnimationTick);
    _moveController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _current;
    if (pos == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: MarkerLayer(
        markers: [
          Marker(
            point: pos,
            width: 84,
            height: 84,
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _entryController,
                curve: Curves.easeOutBack,
              ),
              child: InDriveVehicleMarker(
                size: 54,
                color: AppColors.primary,
                heading: _heading,
                isMoving: _isMoving,
                vehicleType: widget.vehicleType,
                plateNumber: widget.plateNumber,
                showCargoBox: widget.showCargoBox,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveNearbyVehiclesFloatingPill extends StatelessWidget {
  const _LiveNearbyVehiclesFloatingPill({
    required this.vehiclesListenable,
    required this.vehicleType,
    required this.isDark,
  });

  final ValueListenable<List<NearbyVehicleMarkerState>> vehiclesListenable;
  final String vehicleType;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NearbyVehicleMarkerState>>(
      valueListenable: vehiclesListenable,
      builder: (context, vehicles, _) {
        final count = vehicles.length;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: count == 0
              ? const SizedBox.shrink(key: ValueKey('empty_pill'))
              : Container(
                  key: const ValueKey('active_nearby_pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1F2937) : Colors.white)
                        .withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        VehicleTypeHelper.icon(vehicleType),
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'app.nearbyDriversOnlineCount'.tr(
                            context: context,
                            namedArgs: {'count': '$count'},
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _FloatingCircleAction extends StatelessWidget {
  const _FloatingCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusHeaderBadge extends StatelessWidget {
  const _OrderStatusHeaderBadge({
    required this.orderNumber,
    required this.isRide,
    required this.vehicleType,
    required this.isRefreshing,
    required this.isDark,
  });

  final String orderNumber;
  final bool isRide;
  final String vehicleType;
  final bool isRefreshing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final serviceLabel = isRide
        ? 'app.rideServiceBadge'.tr(context: context)
        : 'app.customDeliveryServiceBadge'.tr(context: context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            VehicleTypeHelper.icon(vehicleType),
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              orderNumber.isNotEmpty
                  ? '$serviceLabel · #$orderNumber'
                  : serviceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (isRefreshing) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapEndpointMarker extends StatelessWidget {
  const _MapEndpointMarker({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xEE0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: foreground, size: 17),
          ),
        ],
      ),
    );
  }
}

/// Isolated live status / road-ETA pill shown above the map once a driver is
/// matched, smoothly animating across approach, arrival, active trip, and completion.
class _LiveJourneyStatusFloatingPill extends StatelessWidget {
  const _LiveJourneyStatusFloatingPill({
    required this.state,
    required this.driverLocationListenable,
    required this.isDark,
  });

  final CustomDeliverySearchState state;
  final ValueListenable<DriverLiveMarkerState?> driverLocationListenable;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final orderType = OrderTypeHelper.resolve(
      state.order ?? {'type': state.isRide ? 'RIDE' : 'CUSTOM_DELIVERY'},
    );

    return RepaintBoundary(
      child: ValueListenableBuilder<DriverLiveMarkerState?>(
        valueListenable: driverLocationListenable,
        builder: (context, liveLoc, _) {
          final etaMinutes =
              liveLoc?.etaMinutes ??
              state.searchStatus?.driverEtaMinutes?.toInt();

          String? label;
          IconData icon = Icons.schedule_rounded;
          Color accent = AppColors.primary;
          bool filled = false;

          if (state.isDriverArrived) {
            label = OrderTypeHelper.customerStatusLabel(
              orderType,
              'READY_FOR_PICKUP',
              isArabic: isAr,
            );
            icon = Icons.where_to_vote_rounded;
            accent = AppColors.success;
            filled = true;
          } else if (state.isTripCompleted) {
            label = OrderTypeHelper.customerStatusLabel(
              orderType,
              'DELIVERED',
              isArabic: isAr,
            );
            icon = Icons.check_circle_rounded;
            accent = AppColors.success;
            filled = true;
          } else if (state.isTripInProgress) {
            icon = VehicleTypeHelper.icon(
              (state.driver?['vehicleType'] ?? state.requestedVehicleType)
                  .toString(),
            );
            accent = AppColors.success;
            if (etaMinutes != null && etaMinutes > 0) {
              label = 'app.etaToDestinationMin'.tr(
                context: context,
                namedArgs: {'minutes': '$etaMinutes'},
              );
            } else {
              label = OrderTypeHelper.customerStatusLabel(
                orderType,
                'PICKED_UP',
                isArabic: isAr,
              );
            }
          } else if (state.orderStatus == 'DRIVER_ASSIGNED') {
            if (etaMinutes != null) {
              icon = Icons.schedule_rounded;
              accent = AppColors.success;
              label = etaMinutes <= 0
                  ? 'app.driverArrivingSoon'.tr(context: context)
                  : 'app.driverArrivingInMin'.tr(
                      context: context,
                      namedArgs: {'minutes': '$etaMinutes'},
                    );
            }
          }

          if (label == null || label.isEmpty) {
            return const SizedBox.shrink();
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey('${state.orderStatus}_$label'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: filled
                    ? accent
                    : (isDark
                          ? const Color(0xEA0F172A)
                          : Colors.white.withValues(alpha: 0.95)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: filled ? accent : accent.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: filled ? Colors.white : accent,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: filled
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
