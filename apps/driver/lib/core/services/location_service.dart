import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  return LocationService(ref);
}

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  LocationService(this._ref);

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

    // Try to get background permission if needed
    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      // Background location denied, but foreground might still work
      // Proceeding with what we have
    }

    return true;
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isTracking = true;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Emit every 10 meters
    );

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      _broadcastLocation(initialPosition);
    } catch (e) {
      debugPrint('❌ LocationService: Failed to fetch initial position: $e');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
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
