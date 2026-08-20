// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_shifts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShiftPools)
final shiftPoolsProvider = ShiftPoolsProvider._();

final class ShiftPoolsProvider
    extends $AsyncNotifierProvider<ShiftPools, List<ShiftPool>> {
  ShiftPoolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftPoolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftPoolsHash();

  @$internal
  @override
  ShiftPools create() => ShiftPools();
}

String _$shiftPoolsHash() => r'054e4105a6018ab0a80df589a3f63b97ff6adde4';

abstract class _$ShiftPools extends $AsyncNotifier<List<ShiftPool>> {
  FutureOr<List<ShiftPool>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<ShiftPool>>, List<ShiftPool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ShiftPool>>, List<ShiftPool>>,
              AsyncValue<List<ShiftPool>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
