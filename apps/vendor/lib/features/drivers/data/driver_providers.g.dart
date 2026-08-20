// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriversNotifier)
final driversProvider = DriversNotifierProvider._();

final class DriversNotifierProvider
    extends $AsyncNotifierProvider<DriversNotifier, DriversState> {
  DriversNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driversProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driversNotifierHash();

  @$internal
  @override
  DriversNotifier create() => DriversNotifier();
}

String _$driversNotifierHash() => r'8798ebf938220539994e2c667a9360fe442b2fd4';

abstract class _$DriversNotifier extends $AsyncNotifier<DriversState> {
  FutureOr<DriversState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DriversState>, DriversState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DriversState>, DriversState>,
              AsyncValue<DriversState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
