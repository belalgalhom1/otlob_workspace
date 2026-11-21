import 'package:core/core.dart' show VehicleTypeHelper;
import 'package:flutter/material.dart';

/// Maps backend `VehicleType` enum values (`BICYCLE`, `MOTORCYCLE`, `CAR`,
/// `MINIBUS`, `TUK_TUK`, `MOTOR_TRICYCLE`, `QUARTER_TRUCK`, `HALF_TRUCK`) to
/// clear, distinct vehicle icons via the canonical [VehicleTypeHelper].
IconData driverVehicleIcon(String? vehicleType) =>
    VehicleTypeHelper.icon(vehicleType);
