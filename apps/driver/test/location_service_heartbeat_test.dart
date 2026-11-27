import 'dart:async';

import 'package:core/core.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/core/services/location_service.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _FakeSocketService extends CoreSocketService {
  _FakeSocketService()
      : super(
          isTokenExpired: () async => false,
          refreshToken: () async {},
        );

  bool connected = true;
  int connectCalls = 0;
  final List<Map<String, dynamic>> emittedLocations = [];

  @override
  bool get isConnected => connected;

  @override
  void connect() {
    connectCalls++;
  }

  @override
  void emit(SocketEvent event, dynamic data) {
    if (event == SocketEvent.driverLocationUpdate && data is Map<String, dynamic>) {
      emittedLocations.add(data);
    }
  }
}

class _FakeDriverProfile extends DriverProfile {
  _FakeDriverProfile(this._status);
  final String _status;

  @override
  AsyncValue<dynamic> build() => AsyncValue.data({
        'data': {'status': _status},
      });
}

class _FakeAppPreferences extends AppPreferences {
  @override
  AppPreferencesState build() => AppPreferencesState(
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
      );
}

class _FakeConfiguration extends Configuration {
  _FakeConfiguration(this._config);
  final Map<String, dynamic> _config;

  @override
  AsyncValue<Map<String, dynamic>> build() => AsyncValue.data(_config);

  void updateConfig(Map<String, dynamic> next) {
    state = AsyncValue.data(next);
  }
}

class _SilentStationaryGeolocatorPlatform extends GeolocatorPlatform {
  _SilentStationaryGeolocatorPlatform(this.position);

  final Position position;
  final StreamController<Position> _streamController =
      StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      position;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      position;

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) =>
      _streamController.stream;

  void close() {
    _streamController.close();
  }
}

Position _makePosition() => Position(
      longitude: 31.3565191,
      latitude: 30.2486891,
      timestamp: DateTime.utc(2026, 11, 27, 2, 40, 31),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'stationary online driver adapts heartbeat to driverLocationFreshnessTtlSecs and stops cleanly on stopTracking',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final fakeGeo = _SilentStationaryGeolocatorPlatform(_makePosition());
      final previousPlatform = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = fakeGeo;

      try {
        fakeAsync((async) {
          var fakeNow = DateTime.utc(2026, 11, 27, 2, 40, 31);
          final fakeSocket = _FakeSocketService();
          final fakeConfig = _FakeConfiguration({
            'driverLocationFreshnessTtlSecs': 50, // 40% -> 20s heartbeat
          });
          final container = ProviderContainer(
            overrides: [
              coreSocketServiceProvider.overrideWithValue(fakeSocket),
              appPreferencesProvider.overrideWith(_FakeAppPreferences.new),
              configurationProvider.overrideWith(() => fakeConfig),
              driverProfileProvider.overrideWith(() => _FakeDriverProfile('ONLINE')),
              locationServiceProvider.overrideWith((ref) {
                final svc = LocationService(ref, now: () => fakeNow);
                ref.onDispose(() {
                  svc.stopTracking();
                  svc.dispose();
                });
                return svc;
              }),
            ],
          );

          final service = container.read(locationServiceProvider);

          // Simulate dashboard UI preview populating _lastPosition before going online.
          final releaseObserver = service.retainUiLocationObserver();
          async.flushMicrotasks();
          expect(service.lastPosition, isNotNull);
          expect(fakeSocket.emittedLocations, isEmpty);

          // Going online should immediately broadcast the already-known position.
          unawaited(service.startTracking());
          async.flushMicrotasks();
          expect(fakeSocket.emittedLocations.length, 1);

          // With TTL=50s (heartbeat=20s), stationary driver re-emits at +20s.
          fakeNow = fakeNow.add(const Duration(seconds: 20));
          async.elapse(const Duration(seconds: 20));
          expect(fakeSocket.emittedLocations.length, 2);

          // Admin tightens driverLocationFreshnessTtlSecs to 25s -> 40% = 10s heartbeat.
          fakeConfig.updateConfig({'driverLocationFreshnessTtlSecs': 25});
          async.flushMicrotasks();

          fakeNow = fakeNow.add(const Duration(seconds: 10));
          async.elapse(const Duration(seconds: 10));
          expect(fakeSocket.emittedLocations.length, 3);

          // Going offline cancels the heartbeat timer cleanly.
          unawaited(service.stopTracking());
          releaseObserver();
          async.flushMicrotasks();

          fakeNow = fakeNow.add(const Duration(seconds: 40));
          async.elapse(const Duration(seconds: 40));
          expect(fakeSocket.emittedLocations.length, 3);

          container.dispose();
          async.flushMicrotasks();
        });
      } finally {
        fakeGeo.close();
        GeolocatorPlatform.instance = previousPlatform;
        debugDefaultTargetPlatformOverride = null;
      }
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
