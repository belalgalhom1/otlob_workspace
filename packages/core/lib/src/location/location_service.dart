import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../permissions/permission_service.dart';

/// A generic service to fetch current location or listen to streams.
/// Does not push to any specific API endpoint directly.
class CoreLocationService {
  final PermissionService _permissionService;

  CoreLocationService(this._permissionService);

  /// Get the current position once
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await _permissionService.requestLocationPermission();
    if (!hasPermission) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('CoreLocationService: Location services are disabled.');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('CoreLocationService: Error getting location - $e');
      return null;
    }
  }

  /// Get a stream of continuous location updates
  Future<Stream<Position>?> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 10, // meters
  }) async {
    final hasPermission = await _permissionService.requestLocationPermission();
    if (!hasPermission) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('CoreLocationService: Location services are disabled.');
      return null;
    }

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
