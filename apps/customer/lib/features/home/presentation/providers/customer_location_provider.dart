import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';

class EffectiveLocation {
  final double lat;
  final double lng;
  final bool isGps;
  final String? addressLabel;

  const EffectiveLocation({
    required this.lat,
    required this.lng,
    required this.isGps,
    this.addressLabel,
  });
}

final effectiveCustomerLocationProvider = FutureProvider<EffectiveLocation?>((ref) async {
  // Tier 1: Active saved delivery address in profile
  final activeAddress = ref.watch(activeDeliveryAddressProvider);
  if (activeAddress != null) {
    final locationData = activeAddress['location'];
    List<double> coords = [];
    if (locationData is List) {
      coords = locationData.map((e) => (e as num).toDouble()).toList();
    } else if (locationData is Map && locationData['coordinates'] is List) {
      final list = locationData['coordinates'] as List<dynamic>;
      coords = list.map((e) => (e as num).toDouble()).toList();
    }

    if (coords.length == 2) {
      // GeoJSON standard is [longitude, latitude]
      return EffectiveLocation(
        lng: coords[0],
        lat: coords[1],
        isGps: false,
        addressLabel: activeAddress['address'] as String?,
      );
    }
  }

  // Tier 2: Live device GPS (last known or quick current location)
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position? pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {
            pos = null;
          }
        }

        if (pos != null) {
          return EffectiveLocation(
            lat: pos.latitude,
            lng: pos.longitude,
            isGps: true,
            addressLabel: null,
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Device location check failed: $e');
  }

  // Tier 3: No address & GPS unavailable -> return null (backend falls back to popularity/open stores)
  return null;
});
