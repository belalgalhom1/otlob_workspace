// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VendorWalletData)
final vendorWalletDataProvider = VendorWalletDataProvider._();

final class VendorWalletDataProvider
    extends $AsyncNotifierProvider<VendorWalletData, Map<String, dynamic>> {
  VendorWalletDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vendorWalletDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vendorWalletDataHash();

  @$internal
  @override
  VendorWalletData create() => VendorWalletData();
}

String _$vendorWalletDataHash() => r'e5bbc3835856975bd62e66a1ae91911f35a2f404';

abstract class _$VendorWalletData extends $AsyncNotifier<Map<String, dynamic>> {
  FutureOr<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                Map<String, dynamic>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
