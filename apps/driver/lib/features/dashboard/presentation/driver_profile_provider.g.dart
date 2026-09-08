// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverProfile)
final driverProfileProvider = DriverProfileProvider._();

final class DriverProfileProvider
    extends $NotifierProvider<DriverProfile, AsyncValue<dynamic>> {
  DriverProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverProfileHash();

  @$internal
  @override
  DriverProfile create() => DriverProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<dynamic>>(value),
    );
  }
}

String _$driverProfileHash() => r'a8107a7cda381b260d2509f1688b26f7e703810c';

abstract class _$DriverProfile extends $Notifier<AsyncValue<dynamic>> {
  AsyncValue<dynamic> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<dynamic>, AsyncValue<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<dynamic>, AsyncValue<dynamic>>,
              AsyncValue<dynamic>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
