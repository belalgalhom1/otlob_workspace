// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverLocation)
final driverLocationProvider = DriverLocationProvider._();

final class DriverLocationProvider
    extends $NotifierProvider<DriverLocation, Position?> {
  DriverLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverLocationHash();

  @$internal
  @override
  DriverLocation create() => DriverLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Position? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Position?>(value),
    );
  }
}

String _$driverLocationHash() => r'a32eef8b2afcfabaa71446978d8bcbafadb1278a';

abstract class _$DriverLocation extends $Notifier<Position?> {
  Position? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Position?, Position?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Position?, Position?>,
              Position?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
