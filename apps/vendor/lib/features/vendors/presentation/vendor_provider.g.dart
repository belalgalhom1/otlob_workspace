// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VendorNotifier)
final vendorProvider = VendorNotifierProvider._();

final class VendorNotifierProvider
    extends $NotifierProvider<VendorNotifier, AsyncValue<VendorStateData>> {
  VendorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vendorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vendorNotifierHash();

  @$internal
  @override
  VendorNotifier create() => VendorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<VendorStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<VendorStateData>>(value),
    );
  }
}

String _$vendorNotifierHash() => r'83ff73e6e2713967e10972e1f5a6e48b6ac6a8bf';

abstract class _$VendorNotifier extends $Notifier<AsyncValue<VendorStateData>> {
  AsyncValue<VendorStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<VendorStateData>, AsyncValue<VendorStateData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<VendorStateData>,
                AsyncValue<VendorStateData>
              >,
              AsyncValue<VendorStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
