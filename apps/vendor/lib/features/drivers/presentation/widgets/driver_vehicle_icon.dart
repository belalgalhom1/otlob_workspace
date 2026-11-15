import 'package:flutter/material.dart';

/// Maps backend `VehicleType` enum values (`BICYCLE`, `MOTORCYCLE`, `CAR`,
/// `VAN`, `TRUCK`, `MOTOR_TRICYCLE`) to clear, distinct vehicle icons.
///
/// Defaults to `Icons.two_wheeler_rounded` to match the backend Prisma default
/// (`VehicleType.MOTORCYCLE`).
IconData driverVehicleIcon(String? vehicleType) {
  switch ((vehicleType ?? '').toUpperCase().trim()) {
    case 'CAR':
      return Icons.directions_car_rounded;
    case 'BICYCLE':
      return Icons.pedal_bike_rounded;
    case 'VAN':
      return Icons.airport_shuttle_rounded;
    case 'TRUCK':
      return Icons.local_shipping_rounded;
    case 'MOTOR_TRICYCLE':
      return Icons.electric_rickshaw_rounded;
    case 'MOTORCYCLE':
    default:
      return Icons.two_wheeler_rounded;
  }
}
