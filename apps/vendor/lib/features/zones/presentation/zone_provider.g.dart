// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ZoneNotifier)
final zoneProvider = ZoneNotifierProvider._();

final class ZoneNotifierProvider
    extends $NotifierProvider<ZoneNotifier, AsyncValue<ZoneStateData>> {
  ZoneNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zoneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zoneNotifierHash();

  @$internal
  @override
  ZoneNotifier create() => ZoneNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ZoneStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ZoneStateData>>(value),
    );
  }
}

String _$zoneNotifierHash() => r'e3dec5f99f9dda6610b0d4709f00462f8a4c9d79';

abstract class _$ZoneNotifier extends $Notifier<AsyncValue<ZoneStateData>> {
  AsyncValue<ZoneStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ZoneStateData>, AsyncValue<ZoneStateData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ZoneStateData>, AsyncValue<ZoneStateData>>,
              AsyncValue<ZoneStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
