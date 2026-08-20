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
    r'b6ab59779afd5b588b3ddfcb466edac61862df78';

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
