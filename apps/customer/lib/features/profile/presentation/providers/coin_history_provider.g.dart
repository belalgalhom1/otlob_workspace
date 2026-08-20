// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoinHistory)
final coinHistoryProvider = CoinHistoryProvider._();

final class CoinHistoryProvider
    extends $NotifierProvider<CoinHistory, CoinHistoryState> {
  CoinHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coinHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coinHistoryHash();

  @$internal
  @override
  CoinHistory create() => CoinHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoinHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoinHistoryState>(value),
    );
  }
}

String _$coinHistoryHash() => r'f4d3148f5724b2ae5d72e0b6604a319333454e1b';

abstract class _$CoinHistory extends $Notifier<CoinHistoryState> {
  CoinHistoryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoinHistoryState, CoinHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoinHistoryState, CoinHistoryState>,
              CoinHistoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
