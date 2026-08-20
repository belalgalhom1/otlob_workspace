// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverWallet)
final driverWalletProvider = DriverWalletProvider._();

final class DriverWalletProvider
    extends $NotifierProvider<DriverWallet, AsyncValue<Map<String, dynamic>>> {
  DriverWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverWalletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverWalletHash();

  @$internal
  @override
  DriverWallet create() => DriverWallet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Map<String, dynamic>>>(
        value,
      ),
    );
  }
}

String _$driverWalletHash() => r'b06d30d68ab581655b8097938c197745b7b71b37';

abstract class _$DriverWallet
    extends $Notifier<AsyncValue<Map<String, dynamic>>> {
  AsyncValue<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, dynamic>>,
              AsyncValue<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                AsyncValue<Map<String, dynamic>>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
