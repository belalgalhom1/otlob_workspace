// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_control_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccessControlNotifier)
final accessControlProvider = AccessControlNotifierProvider._();

final class AccessControlNotifierProvider
    extends
        $NotifierProvider<
          AccessControlNotifier,
          AsyncValue<AccessControlStateData>
        > {
  AccessControlNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessControlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessControlNotifierHash();

  @$internal
  @override
  AccessControlNotifier create() => AccessControlNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AccessControlStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AccessControlStateData>>(
        value,
      ),
    );
  }
}

String _$accessControlNotifierHash() =>
    r'30e1c20c037a9e4750ad06808e1619107768283f';

abstract class _$AccessControlNotifier
    extends $Notifier<AsyncValue<AccessControlStateData>> {
  AsyncValue<AccessControlStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<AccessControlStateData>,
              AsyncValue<AccessControlStateData>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AccessControlStateData>,
                AsyncValue<AccessControlStateData>
              >,
              AsyncValue<AccessControlStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
