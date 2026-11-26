// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(topUpDetails)
final topUpDetailsProvider = TopUpDetailsFamily._();

final class TopUpDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<WalletTopUpRequest>,
          WalletTopUpRequest,
          FutureOr<WalletTopUpRequest>
        >
    with
        $FutureModifier<WalletTopUpRequest>,
        $FutureProvider<WalletTopUpRequest> {
  TopUpDetailsProvider._({
    required TopUpDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'topUpDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$topUpDetailsHash();

  @override
  String toString() {
    return r'topUpDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WalletTopUpRequest> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WalletTopUpRequest> create(Ref ref) {
    final argument = this.argument as String;
    return topUpDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TopUpDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$topUpDetailsHash() => r'3c512f58c711aef70e1e45c2868f0b39ae01e2fa';

final class TopUpDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WalletTopUpRequest>, String> {
  TopUpDetailsFamily._()
    : super(
        retry: null,
        name: r'topUpDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TopUpDetailsProvider call(String id) =>
      TopUpDetailsProvider._(argument: id, from: this);

  @override
  String toString() => r'topUpDetailsProvider';
}

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

String _$pendingTopUpsHash() => r'61683897c4d1dc5cd742bb43001b7cc9701b726b';

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
