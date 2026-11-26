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

class DriverLocationState {
  const DriverLocationState({
    required this.status,
    this.position,
    this.errorMessage,
  });

  const DriverLocationState.loading()
      : status = DriverLocationStatus.loading,
        position = null,
        errorMessage = null;

  final DriverLocationStatus status;
  final Position? position;
  final String? errorMessage;
}

enum DriverLocationStatus {
  loading,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<Position>? _uiPositionSubscription;
  StreamSubscription<void>? _connectSub;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  final ValueNotifier<DriverLocationState> _locationState =
      ValueNotifier<DriverLocationState>(const DriverLocationState.loading());

  bool _isTracking = false;
  int _restartSeq = 0;
  int _uiSeq = 0;
  int _uiObserverCount = 0;
  bool _hasPromptedForegroundPermission = false;
  Position? _lastPosition;
  Position? _lastEmitted;
  DateTime? _lastEmitAt;

  LocationService(this._ref) {
    _listenToLocaleChanges();
    _listenToSocketReconnect();
    _listenToProfileStatus();
  }

  ValueListenable<DriverLocationState> get locationState => _locationState;
  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastPosition => _lastPosition;

  VoidCallback retainUiLocationObserver() {
    _uiObserverCount++;
    if (_uiObserverCount == 1 && !_isTracking) {
      unawaited(_startUiPreviewStream(requestPermission: false));
    }
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (_uiObserverCount > 0) {
        _uiObserverCount--;
      }
      if (_uiObserverCount == 0) {
        _stopUiPreviewStream();
      }
    };
  }

  Future<void> refreshUiLocation({bool requestPermission = false}) async {
    if (_isTracking) {
      if (requestPermission) {
        await requestPermissions();
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: _getUiPreviewSettings(),
        ).timeout(const Duration(seconds: 8));
        _recordLocalPosition(pos);
      } catch (e) {
        debugPrint('📍 LocationService: refreshUiLocation while tracking failed: $e');
      }
      return;
    }
    await _startUiPreviewStream(requestPermission: requestPermission);
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
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
      if (_isTracking) {
        if (_lastPosition != null) {
          debugPrint('📍 LocationService: Socket reconnected, re-broadcasting latest position.');
          _lastEmitted = _lastPosition;
          _lastEmitAt = DateTime.now();
          _emitPosition(_lastPosition!);
        } else {
          Geolocator.getLastKnownPosition().then((pos) {
            if (pos != null && _isTracking) {
              _broadcastLocation(pos);
            }
          }).catchError((_) => null);
        }
      }
    });
  }

  Future<bool> requestPermissions() async {
    debugPrint('📍 LocationService: Checking permissions...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ LocationService: Location services are disabled.');
        _setLocationStatus(DriverLocationStatus.serviceDisabled);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📍 LocationService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ LocationService: Location permissions are denied.');
          _setLocationStatus(DriverLocationStatus.permissionDenied);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ LocationService: Location permissions are permanently denied.');
        _setLocationStatus(DriverLocationStatus.permissionDeniedForever);
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
    } catch (e) {
      debugPrint('❌ LocationService: Permission check error: $e');
      _setLocationStatus(
        DriverLocationStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
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
    final seq = ++_restartSeq;

    final hasPermission = await requestPermissions();
    if (!hasPermission || seq != _restartSeq) return;

    _stopUiPreviewStream();
    _isTracking = true;
    // Reset the coalescing baseline so the first fix of this session is always
    // broadcast (and the customer's marker appears instantly).
    _lastEmitted = null;
    _lastEmitAt = null;
    await _startPositionStream(seq: seq, fetchInitial: true);
  }

  Future<void> _restartTracking() async {
    if (!_isTracking) return;
    // Serialize restarts: rapid locale/status changes would otherwise start two
    // GPS streams and leak a subscription (double emits, battery drain). Only
    // the most recent restart request gets to create the new stream.
    final seq = ++_restartSeq;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (!_isTracking || seq != _restartSeq) return;
    await _startPositionStream(seq: seq, fetchInitial: false);
  }

  Future<void> _startPositionStream({
    required int seq,
    bool fetchInitial = true,
  }) async {
    final locationSettings = _getLocationSettings();

    if (fetchInitial) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (!_isTracking || seq != _restartSeq) return;
        if (lastKnown != null && _lastPosition == null) {
          _broadcastLocation(lastKnown);
        }
        final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        ).timeout(const Duration(seconds: 10));
        if (!_isTracking || seq != _restartSeq) return;
        _broadcastLocation(initialPosition);
      } catch (e) {
        debugPrint('❌ LocationService: Failed to fetch initial position: $e');
      }
    }

    if (!_isTracking || seq != _restartSeq) return;

    await _positionStreamSubscription?.cancel();
    if (!_isTracking || seq != _restartSeq) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!_isTracking) return;
        _broadcastLocation(position);
      },
      onError: (Object error) {
        debugPrint('❌ LocationService: Position stream error: $error');
      },
    );
  }

  Future<void> stopTracking() async {
    _restartSeq++;
    _isTracking = false;
    final sub = _positionStreamSubscription;
    _positionStreamSubscription = null;
    await sub?.cancel();
    if (_uiObserverCount > 0) {
      unawaited(_startUiPreviewStream(requestPermission: false));
    }
  }

  void dispose() {
    _connectSub?.cancel();
    _connectSub = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _uiPositionSubscription?.cancel();
    _uiPositionSubscription = null;
    if (!_positionController.isClosed) {
      _positionController.close();
    }
    _locationState.dispose();
    _lastPosition = null;
  }

  void _setLocationStatus(
    DriverLocationStatus status, {
    String? errorMessage,
  }) {
    _locationState.value = DriverLocationState(
      status: status,
      position: status == DriverLocationStatus.ready ? _lastPosition : null,
      errorMessage: errorMessage,
    );
  }

  LocationSettings _getUiPreviewSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
    );
  }

  void _stopUiPreviewStream() {
    _uiSeq++;
    final sub = _uiPositionSubscription;
    _uiPositionSubscription = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
  }

  Future<void> _startUiPreviewStream({required bool requestPermission}) async {
    if (_isTracking || _uiObserverCount <= 0) return;
    final seq = ++_uiSeq;

    if (_lastPosition == null) {
      _locationState.value = const DriverLocationState.loading();
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
      if (!serviceEnabled) {
        _setLocationStatus(DriverLocationStatus.serviceDisabled);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;

      if (permission == LocationPermission.denied &&
          (requestPermission || !_hasPromptedForegroundPermission)) {
        _hasPromptedForegroundPermission = true;
        permission = await Geolocator.requestPermission();
        if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
      }

      if (permission == LocationPermission.denied) {
        _setLocationStatus(DriverLocationStatus.permissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationStatus(DriverLocationStatus.permissionDeniedForever);
        return;
      }

      if (_lastPosition == null) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
          if (lastKnown != null) {
            _recordLocalPosition(lastKnown);
          }
        } catch (_) {}
      }

      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: _getUiPreviewSettings(),
        );
        if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
        _recordLocalPosition(current);
      } catch (e) {
        if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
        if (_lastPosition == null) {
          _setLocationStatus(
            DriverLocationStatus.error,
            errorMessage: e.toString(),
          );
        }
      }

      await _uiPositionSubscription?.cancel();
      if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;

      // Foreground-only stream for UI display when OFFLINE/ON_BREAK; never emits
      // backend location updates or holds foreground service locks.
      _uiPositionSubscription = Geolocator.getPositionStream(
        locationSettings: _getUiPreviewSettings(),
      ).listen(
        (Position position) {
          if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
          _recordLocalPosition(position);
        },
        onError: (Object error) {
          if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
          debugPrint('❌ LocationService: UI preview stream error: $error');
          if (_lastPosition == null) {
            _setLocationStatus(
              DriverLocationStatus.error,
              errorMessage: error.toString(),
            );
          }
        },
      );
    } catch (e) {
      if (seq != _uiSeq || _isTracking || _uiObserverCount <= 0) return;
      debugPrint('❌ LocationService: UI preview setup error: $e');
      _setLocationStatus(
        DriverLocationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  bool _recordLocalPosition(Position position) {
    // Reject unreliable fixes so the map marker never sees random jumps.
    if (_lastPosition != null ? position.accuracy > 100 : position.accuracy > 250) {
      debugPrint('📍 LocationService: Dropping fix with accuracy ${position.accuracy}m');
      return false;
    }
    _lastPosition = position;
    _locationState.value = DriverLocationState(
      status: DriverLocationStatus.ready,
      position: position,
    );
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
    return true;
  }

  void _broadcastLocation(Position position) {
    if (!_recordLocalPosition(position)) return;

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
      'heading': (position.heading.isFinite && position.heading >= 0)
          ? position.heading
          : 0.0,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
