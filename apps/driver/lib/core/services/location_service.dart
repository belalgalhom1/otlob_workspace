import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_preferences_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

part 'location_service.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  final service = LocationService(ref);
  ref.onDispose(() {
    service.stopTracking();
    service.dispose();
  });
  return service;
}

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<void>? _connectSub;
  bool _isTracking = false;
  int _restartSeq = 0;
  Position? _lastPosition;
  Position? _lastEmitted;
  DateTime? _lastEmitAt;

  LocationService(this._ref) {
    _listenToLocaleChanges();
    _listenToSocketReconnect();
    _listenToProfileStatus();
  }

  void _listenToLocaleChanges() {
    _ref.listen<AppPreferencesState>(appPreferencesProvider, (previous, next) {
      if (previous?.locale.languageCode != next.locale.languageCode && _isTracking) {
        debugPrint('🌐 LocationService: App locale changed to ${next.locale.languageCode}, refreshing foreground notification...');
        _restartTracking();
      }
    });
  }

  void _listenToProfileStatus() {
    _ref.listen(driverProfileProvider, (previous, next) {
      if (!_isTracking) return;
      final prevDelivery = _extractStatus(previous?.value) == 'ON_DELIVERY';
      final nextDelivery = _extractStatus(next.value) == 'ON_DELIVERY';
      if (prevDelivery != nextDelivery) {
        debugPrint(
          '📍 LocationService: Delivery state '
          '(${prevDelivery ? 'delivering' : 'idle'} -> '
          '${nextDelivery ? 'delivering' : 'idle'}), adapting GPS rate.',
        );
        _restartTracking();
      }
    });
  }

  String? _extractStatus(Object? profile) {
    if (profile is Map) {
      final data = profile['data'];
      if (data is Map && data['status'] != null) {
        return data['status']?.toString();
      }
      return profile['status']?.toString();
    }
    return null;
  }

  bool get _onDelivery =>
      _extractStatus(_ref.read(driverProfileProvider).value) == 'ON_DELIVERY';

  void _listenToSocketReconnect() {
    _connectSub = _ref
        .read(coreSocketServiceProvider)
        .onConnect
        .listen((_) {
      if (_isTracking && _lastPosition != null) {
        debugPrint('📍 LocationService: Socket reconnected, re-broadcasting latest position.');
        // Bypass coalescing so the customer gets a fresh fix immediately.
        _lastEmitted = _lastPosition;
        _lastEmitAt = DateTime.now();
        _emitPosition(_lastPosition!);
      }
    });
  }

  Future<bool> requestPermissions() async {
    debugPrint('📍 LocationService: Checking permissions...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ LocationService: Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('📍 LocationService: Requesting permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ LocationService: Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ LocationService: Location permissions are permanently denied.');
      return false;
    }

    // Request notification permission on Android 13+ (POST_NOTIFICATIONS) for foreground service
    if (defaultTargetPlatform == TargetPlatform.android) {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    }

    // Try to get background permission if needed
    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      // Background location denied, but foreground might still work
      // Proceeding with what we have
    }

    return true;
  }

  LocationSettings _getLocationSettings() {
    // Adaptive sampling: faster fixes while actively delivering (a customer is
    // watching), slower while idle-online to save battery.
    final active = _onDelivery;
    final interval = active
        ? const Duration(seconds: 3)
        : const Duration(seconds: 15);
    final distanceMeters = active ? 5 : 15;

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Prioritize driver app preferences, fallback to system locale
      final prefLocale = _ref.read(appPreferencesProvider).locale;
      final systemLocale = PlatformDispatcher.instance.locale;
      final langCode = prefLocale.languageCode.isNotEmpty
          ? prefLocale.languageCode
          : systemLocale.languageCode;
      final isArabic = langCode.toLowerCase().startsWith('ar');

      final notificationTitle = isArabic
          ? 'اطلب كابتن - الخدمة نشطة'
          : 'Otlob Captain - Service Active';
      final notificationText = isArabic
          ? 'أنت متصل وجاهز لاستقبال طلبات التوصيل'
          : 'You are online and ready to receive delivery orders';

      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceMeters,
        forceLocationManager: false,
        intervalDuration: interval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
          enableWakeLock: true,
          enableWifiLock: true,
          setOngoing: true,
          notificationIcon: const AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: distanceMeters,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      );
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    // Reset the coalescing baseline so the first fix of this session is always
    // broadcast (and the customer's marker appears instantly).
    _lastEmitted = null;
    _lastEmitAt = null;
    await _startPositionStream(fetchInitial: true);
  }

  Future<void> _restartTracking() async {
    if (!_isTracking) return;
    // Serialize restarts: rapid locale/status changes would otherwise start two
    // GPS streams and leak a subscription (double emits, battery drain). Only
    // the most recent restart request gets to create the new stream.
    final seq = ++_restartSeq;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (seq != _restartSeq) return;
    await _startPositionStream(fetchInitial: false);
  }

  Future<void> _startPositionStream({bool fetchInitial = true}) async {
    final locationSettings = _getLocationSettings();

    if (fetchInitial) {
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        ).timeout(const Duration(seconds: 10));
        _broadcastLocation(initialPosition);
      } catch (e) {
        debugPrint('❌ LocationService: Failed to fetch initial position: $e');
      }
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _broadcastLocation(position);
    });
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;
    _isTracking = false;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void dispose() {
    _connectSub?.cancel();
    _connectSub = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _lastPosition = null;
  }

  void _broadcastLocation(Position position) {
    // Reject unreliable fixes so the customer never sees random jumps.
    if (position.accuracy > 100) {
      debugPrint('📍 LocationService: Dropping fix with accuracy ${position.accuracy}m');
      return;
    }
    _lastPosition = position;

    final now = DateTime.now();
    final active = _onDelivery;
    final minDistance = active ? 5.0 : 15.0;
    final heartbeatSeconds = active ? 15 : 30;

    // Coalesce: emit only when the driver actually moved far enough, or enough
    // time has passed that the customer needs a fresh heartbeat.
    final moved = _lastEmitted == null ||
        Geolocator.distanceBetween(
              _lastEmitted!.latitude,
              _lastEmitted!.longitude,
              position.latitude,
              position.longitude,
            ) >=
            minDistance;
    final heartbeat = _lastEmitAt == null ||
        now.difference(_lastEmitAt!).inSeconds >= heartbeatSeconds;

    if (!moved && !heartbeat) return;

    _lastEmitted = position;
    _lastEmitAt = now;
    _emitPosition(position);
  }

  void _emitPosition(Position position) {
    // Lean payload: only what the backend/customer actually consume.
    _ref.read(coreSocketServiceProvider).emit(SocketEvent.driverLocationUpdate, {
      'location': [position.longitude, position.latitude],
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
