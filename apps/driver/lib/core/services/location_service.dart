import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_preferences_provider.dart';

part 'location_service.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  final service = LocationService(ref);
  ref.onDispose(() {
    service.stopTracking();
  });
  return service;
}

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  LocationService(this._ref) {
    _listenToLocaleChanges();
  }

  void _listenToLocaleChanges() {
    _ref.listen<AppPreferencesState>(appPreferencesProvider, (previous, next) {
      if (previous?.locale.languageCode != next.locale.languageCode && _isTracking) {
        debugPrint('🌐 LocationService: App locale changed to ${next.locale.languageCode}, refreshing foreground notification...');
        _restartTracking();
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
        distanceFilter: 10, // Emit every 10 meters
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
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
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    await _startPositionStream(fetchInitial: true);
  }

  Future<void> _restartTracking() async {
    if (!_isTracking) return;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
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

  void _broadcastLocation(Position position) {
    final socketService = _ref.read(coreSocketServiceProvider);
    
    final payload = {
      'location': [position.longitude, position.latitude],
      'heading': position.heading,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    
    socketService.emit(SocketEvent.driverLocationUpdate, payload);
  }
}
