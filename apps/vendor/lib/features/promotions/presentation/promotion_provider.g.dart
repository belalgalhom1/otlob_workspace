// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PromotionNotifier)
final promotionProvider = PromotionNotifierProvider._();

final class PromotionNotifierProvider
    extends $NotifierProvider<PromotionNotifier, AsyncValue<List<dynamic>>> {
  PromotionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionNotifierHash();

  @$internal
  @override
  PromotionNotifier create() => PromotionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<dynamic>>>(value),
    );
  }
}

String _$promotionNotifierHash() => r'526f0076f10571218718a3d0b59503645ced23bf';

abstract class _$PromotionNotifier
    extends $Notifier<AsyncValue<List<dynamic>>> {
  AsyncValue<List<dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<dynamic>>, AsyncValue<List<dynamic>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, AsyncValue<List<dynamic>>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
