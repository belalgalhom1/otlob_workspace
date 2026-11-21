import 'package:api/api.dart';
import 'package:core/core.dart' show ApiErrorMapper;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class _SearchLifecycleObserver with WidgetsBindingObserver {
  _SearchLifecycleObserver(this.onResume);
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

/// Real-time Custom Delivery & Ride Driver Search Screen inspired by inDrive's
/// matching flow while preserving Otlob branding, zero-lag rebuild isolation,
/// full SafeArea compliance, and arbitrary [TextScaler] adaptation.
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
    extends ConsumerState<CustomDeliverySearchScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final _SearchLifecycleObserver _lifecycleObserver;

  bool _hasFittedInitialBounds = false;
  bool _hasFittedDriverMatchBounds = false;
  String? _lastShownNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = ref.read(
        customDeliverySearchControllerProvider(widget.orderId).notifier,
      );
      ctrl.seedOrderSnapshot(widget.initialOrder);
    });

    _lifecycleObserver = _SearchLifecycleObserver(() {
      if (!mounted) return;
      ref
          .read(customDeliverySearchControllerProvider(widget.orderId).notifier)
          .onAppResumed();
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _fitCameraToPoints(List<LatLng> points) {
    if (points.isEmpty || widget.mapBuilder != null) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14.8);
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(points);
      final screenHeight = MediaQuery.sizeOf(context).height;
      final topInset = MediaQuery.paddingOf(context).top;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.fromLTRB(
            48,
            topInset + 84,
            48,
            (screenHeight * 0.45).clamp(160.0, 380.0),
          ),
        ),
      );
    } catch (_) {
      _mapController.move(points.first, 14.0);
    }
  }

  void _recenterMap(
    CustomDeliverySearchState state,
    DriverLiveMarkerState? driverLoc,
  ) {
    final pts = <LatLng>[];
    if (state.pickupPoint != null) pts.add(state.pickupPoint!);
    if (state.dropoffPoint != null) pts.add(state.dropoffPoint!);
    if (state.isDriverMatched && driverLoc != null) {
      pts.add(driverLoc.position);
    }
    if (pts.isNotEmpty) {
      _fitCameraToPoints(pts);
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
            _recenterMap(next, controller.driverLocationNotifier.value);
          }
        });
      }
      if ((prev?.isDriverMatched != true) && next.isDriverMatched) {
        if (!_hasFittedDriverMatchBounds) {
          _hasFittedDriverMatchBounds = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _recenterMap(next, controller.driverLocationNotifier.value);
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
          // Top floating navigation + connection status bar inside SafeArea.
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
                              isRefreshing: state.isRefreshing,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FloatingCircleAction(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Recenter',
                          onPressed: () => _recenterMap(
                            state,
                            controller.driverLocationNotifier.value,
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
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
            initialChildSize: 0.46,
            minChildSize: 0.28,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: const [0.30, 0.48, 0.88],
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
                          onCancelConfirmed: () => controller.cancelSearch(),
                          onRetrySearch: () => controller.retrySearch(),
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

    final nearby = state.isSearching
        ? (state.searchStatus?.nearbyDrivers.toList() ??
              const <NearbyDriverPreviewDto>[])
        : const <NearbyDriverPreviewDto>[];

    final driverVehicleType =
        (state.driver?['vehicleType'] ??
                state.order?['requestedVehicleType'] ??
                'MOTORCYCLE')
            .toString();

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
      ),
      children: [
        const AppMapTileLayer(
          style: AppMapStyle.auto,
          userAgentPackageName: 'com.otlob.customer',
        ),
        if (polylinePoints.length >= 2)
          RepaintBoundary(
            child: PolylineLayer(
              polylines: NavigationRoutePolylines.build(
                points: polylinePoints,
                foregroundColor: AppColors.primary,
                casingColor: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                    : const Color(0xFF1E293B).withValues(alpha: 0.72),
              ),
            ),
          ),
        // Repaint-isolated radar pulse centered on pickup while actively searching.
        if (pickup != null && state.isSearching)
          MarkerLayer(
            markers: [
              Marker(
                point: pickup,
                width: 240,
                height: 240,
                alignment: Alignment.center,
                child: DriverSearchRadarPulse(
                  size: 240,
                  color: AppColors.primary,
                  isActive: !state.isOffline,
                ),
              ),
            ],
          ),
        // Real anonymized nearby eligible drivers around pickup.
        if (nearby.isNotEmpty)
          RepaintBoundary(
            child: MarkerLayer(
              markers: nearby
                  .map((d) {
                    return Marker(
                      point: LatLng(
                        d.latitude.toDouble(),
                        d.longitude.toDouble(),
                      ),
                      width: 44,
                      height: 44,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.88,
                          child: InDriveVehicleMarker(
                            size: 40,
                            color: AppColors.primary,
                            vehicleType: d.vehicleType.name,
                            showHeadlightGlow: false,
                            showRadarPulse: false,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        // Origin and destination markers.
        RepaintBoundary(
          child: MarkerLayer(
            markers: [
              if (pickup != null)
                Marker(
                  point: pickup,
                  width: 40,
                  height: 40,
                  child: const _MapPinBadge(
                    icon: Icons.my_location_rounded,
                    color: AppColors.primary,
                    foreground: Colors.black,
                  ),
                ),
              if (dropoff != null)
                Marker(
                  point: dropoff,
                  width: 40,
                  height: 40,
                  child: const _MapPinBadge(
                    icon: Icons.flag_rounded,
                    color: Color(0xFFEF4444),
                    foreground: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // Smooth live driver marker isolated from whole-screen rebuilds.
        if (state.isDriverMatched)
          _AnimatedAssignedDriverLayer(
            locationListenable: controller.driverLocationNotifier,
            vehicleType: driverVehicleType,
            plateNumber: state.driver?['vehiclePlate']?.toString(),
          ),
      ],
    );
  }
}

class _AnimatedAssignedDriverLayer extends StatefulWidget {
  const _AnimatedAssignedDriverLayer({
    required this.locationListenable,
    required this.vehicleType,
    this.plateNumber,
  });

  final ValueListenable<DriverLiveMarkerState?> locationListenable;
  final String vehicleType;
  final String? plateNumber;

  @override
  State<_AnimatedAssignedDriverLayer> createState() =>
      _AnimatedAssignedDriverLayerState();
}

class _AnimatedAssignedDriverLayerState
    extends State<_AnimatedAssignedDriverLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _moveController;
  LatLng? _from;
  LatLng? _to;
  LatLng? _current;
  double _heading = 0.0;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(_onAnimationTick);
    widget.locationListenable.addListener(_onLocationChanged);
    _applyInitial(widget.locationListenable.value);
  }

  void _applyInitial(DriverLiveMarkerState? snapshot) {
    if (snapshot == null) return;
    _current = snapshot.position;
    _from = snapshot.position;
    _to = snapshot.position;
    _heading = snapshot.heading;
    _isMoving = snapshot.isMoving;
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
    _heading = next.heading;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _current;
    if (pos == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: pos,
          width: 80,
          height: 80,
          child: RepaintBoundary(
            child: InDriveVehicleMarker(
              size: 54,
              color: AppColors.primary,
              heading: _heading,
              isMoving: _isMoving,
              vehicleType: widget.vehicleType,
              plateNumber: widget.plateNumber,
            ),
          ),
        ),
      ],
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
    required this.isRefreshing,
    required this.isDark,
  });

  final String orderNumber;
  final bool isRefreshing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Icons.local_shipping_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              orderNumber.isNotEmpty ? '#$orderNumber' : 'OTLOB',
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

class _MapPinBadge extends StatelessWidget {
  const _MapPinBadge({
    required this.icon,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}
