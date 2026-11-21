import 'package:flutter/material.dart';

/// Canonical single source of truth for vehicle type identifiers, service
/// eligibility, icons, and localized EN/AR display names across all Otlob apps.
///
/// Mirrors backend `enum VehicleType` and `vehicle-eligibility.helper.ts`.
abstract final class VehicleTypeHelper {
  static const String bicycle = 'BICYCLE';
  static const String motorcycle = 'MOTORCYCLE';
  static const String car = 'CAR';
  static const String minibus = 'MINIBUS';
  static const String tukTuk = 'TUK_TUK';
  static const String motorTricycle = 'MOTOR_TRICYCLE';
  static const String quarterTruck = 'QUARTER_TRUCK';
  static const String halfTruck = 'HALF_TRUCK';

  /// All registered driver vehicle types supported by the backend.
  static const List<String> allVehicleTypes = <String>[
    bicycle,
    motorcycle,
    car,
    minibus,
    tukTuk,
    motorTricycle,
    quarterTruck,
    halfTruck,
  ];

  /// Default eligible vehicle types for STANDARD orders.
  static const List<String> standardEligibleVehicles = <String>[
    motorcycle,
    bicycle,
  ];

  /// Default eligible vehicle types for RIDE requests (Ride Tab).
  static const List<String> rideEligibleVehicles = <String>[
    motorcycle,
    car,
    minibus,
    tukTuk,
  ];

  /// Default eligible vehicle types for CUSTOM_DELIVERY requests (Custom Delivery Tab).
  static const List<String> customDeliveryEligibleVehicles = <String>[
    motorcycle,
    motorTricycle,
    quarterTruck,
    halfTruck,
  ];

  static const Set<String> _validSet = <String>{
    bicycle,
    motorcycle,
    car,
    minibus,
    tukTuk,
    motorTricycle,
    quarterTruck,
    halfTruck,
  };

  /// Normalizes a raw vehicle type string (upper/lower/mixed) to its canonical
  /// backend enum name, or returns `null` if empty or unrecognized.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().toUpperCase();
    if (cleaned.isEmpty) return null;
    return _validSet.contains(cleaned) ? cleaned : null;
  }

  /// Normalizes a raw order/service type string (`delivery`/`custom_delivery`,
  /// `ride`, `standard`) into canonical backend `OrderType` wire string.
  static String normalizeOrderType(String? raw) {
    final cleaned = raw?.trim().toUpperCase() ?? '';
    switch (cleaned) {
      case 'RIDE':
        return 'RIDE';
      case 'DELIVERY':
      case 'CUSTOM_DELIVERY':
        return 'CUSTOM_DELIVERY';
      case 'STANDARD':
        return 'STANDARD';
      default:
        return cleaned;
    }
  }

  /// Resolves the ordered eligible vehicle types for [orderType], preferring
  /// the backend-provided [backendMatrix] from `/platform-settings/public`
  /// whenever available.
  static List<String> eligibleForOrderType(
    String? orderType, {
    Map<String, List<String>>? backendMatrix,
  }) {
    final canonicalOrderType = normalizeOrderType(orderType);
    final fromBackend = backendMatrix?[canonicalOrderType];
    if (fromBackend != null && fromBackend.isNotEmpty) {
      final normalized = fromBackend
          .map(normalize)
          .whereType<String>()
          .toList(growable: false);
      if (normalized.isNotEmpty) return normalized;
    }

    switch (canonicalOrderType) {
      case 'STANDARD':
        return standardEligibleVehicles;
      case 'RIDE':
        return rideEligibleVehicles;
      case 'CUSTOM_DELIVERY':
        return customDeliveryEligibleVehicles;
      default:
        return allVehicleTypes;
    }
  }

  /// Returns whether [vehicleType] is eligible for [orderType] (and matches
  /// [requestedVehicleType] when specified on RIDE or CUSTOM_DELIVERY orders).
  static bool isEligibleForOrder({
    required String? orderType,
    required String? driverVehicleType,
    String? requestedVehicleType,
    Map<String, List<String>>? backendMatrix,
  }) {
    final normalizedDriver = normalize(driverVehicleType);
    if (normalizedDriver == null) return false;

    final eligible = eligibleForOrderType(
      orderType,
      backendMatrix: backendMatrix,
    );
    if (!eligible.contains(normalizedDriver)) return false;

    final canonicalOrderType = normalizeOrderType(orderType);
    final normalizedRequested = normalize(requestedVehicleType);
    if ((canonicalOrderType == 'RIDE' ||
            canonicalOrderType == 'CUSTOM_DELIVERY') &&
        normalizedRequested != null) {
      return normalizedDriver == normalizedRequested;
    }
    return true;
  }

  /// Returns the canonical localized display label in English or Arabic.
  static String label(String? raw, {required bool isArabic}) {
    switch (normalize(raw)) {
      case motorcycle:
        return isArabic ? 'موتوسيكل' : 'Motorcycle';
      case car:
        return isArabic ? 'سيارة خاصة' : 'Private Car';
      case minibus:
        return isArabic ? 'سيارة ميكروباص' : 'Minibus';
      case tukTuk:
        return isArabic ? 'توكتوك' : 'Tuk-tuk';
      case motorTricycle:
        return isArabic ? 'تروسيكل' : 'Tricycle';
      case quarterTruck:
        return isArabic ? 'شاحنة ربع نقل' : 'Quarter-ton Pickup Truck';
      case halfTruck:
        return isArabic ? 'شاحنة نص نقل' : 'Half-ton Pickup Truck';
      case bicycle:
        return isArabic ? 'دراجة هوائية' : 'Bicycle';
      default:
        final trimmed = raw?.trim() ?? '';
        if (trimmed.isNotEmpty) return trimmed;
        return isArabic ? 'موتوسيكل' : 'Motorcycle';
    }
  }

  /// Returns a crisp, semantically distinct icon for each vehicle type.
  static IconData icon(String? raw) {
    switch (normalize(raw)) {
      case bicycle:
        return Icons.pedal_bike_rounded;
      case motorcycle:
        return Icons.two_wheeler_rounded;
      case car:
        return Icons.directions_car_filled_rounded;
      case minibus:
        return Icons.airport_shuttle_rounded;
      case tukTuk:
        return Icons.electric_rickshaw_rounded;
      case motorTricycle:
        return Icons.moped_rounded;
      case quarterTruck:
        return Icons.local_shipping_outlined;
      case halfTruck:
        return Icons.local_shipping_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  /// Converts a canonical wire enum name to its lowercase backend icon upload slug.
  static String? uploadSlug(String? raw) => normalize(raw)?.toLowerCase();
}
