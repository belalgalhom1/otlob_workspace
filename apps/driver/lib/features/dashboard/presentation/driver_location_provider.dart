import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

part 'driver_location_provider.g.dart';

@riverpod
class DriverLocation extends _$DriverLocation {
  StreamSubscription<Position>? _positionSubscription;

  @override
  Position? build() {
    _listenToProfileStatus();
    
    ref.onDispose(() {
      stopTracking();
    });
    
    return null;
  }

  void _listenToProfileStatus() {
    ref.listen<AsyncValue<dynamic>>(driverProfileProvider, (previous, next) {
      next.whenData((profileData) {
        final status = profileData?['data']?['status'] ?? 'OFFLINE';
        if (status == 'ONLINE' || status == 'ON_DELIVERY') {
          startTracking();
        } else {
          stopTracking();
        }
      });
    });
  }

  Future<void> startTracking() async {
    if (_positionSubscription != null) return; // Already tracking

    final locationService = ref.read(coreLocationServiceProvider);
    final stream = await locationService.getPositionStream(distanceFilter: 10);
    
    if (stream != null) {
      _positionSubscription = stream.listen((position) {
        state = position;
        _broadcastLocation(position);
      });
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _broadcastLocation(Position position) {
    final socketService = ref.read(coreSocketServiceProvider);
    socketService.emit(SocketEvent.driverLocationUpdate, {
      'location': [position.longitude, position.latitude],
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': position.heading,
      'speed': position.speed,
    });
  }
}
