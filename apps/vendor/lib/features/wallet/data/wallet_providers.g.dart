// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingTopUps)
final pendingTopUpsProvider = PendingTopUpsProvider._();

final class PendingTopUpsProvider
    extends $AsyncNotifierProvider<PendingTopUps, List<dynamic>> {
  PendingTopUpsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingTopUpsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingTopUpsHash();

  @$internal
  @override
  PendingTopUps create() => PendingTopUps();
}

String _$pendingTopUpsHash() => r'1c1ddc0d0567151fd135243cb4271e61b4cebb90';

abstract class _$PendingTopUps extends $AsyncNotifier<List<dynamic>> {
  FutureOr<List<dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<dynamic>>, List<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, List<dynamic>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PlatformWallets)
final platformWalletsProvider = PlatformWalletsProvider._();

final class PlatformWalletsProvider
    extends $AsyncNotifierProvider<PlatformWallets, List<dynamic>> {
  PlatformWalletsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformWalletsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformWalletsHash();

  @$internal
  @override
  PlatformWallets create() => PlatformWallets();
}

String _$platformWalletsHash() => r'080f5ad63b329680e68377b0791f7774d19ea741';

abstract class _$PlatformWallets extends $AsyncNotifier<List<dynamic>> {
  FutureOr<List<dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<dynamic>>, List<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, List<dynamic>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
