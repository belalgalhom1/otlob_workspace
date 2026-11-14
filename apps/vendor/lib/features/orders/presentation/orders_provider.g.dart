// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrdersNotifier)
final ordersProvider = OrdersNotifierProvider._();

final class OrdersNotifierProvider
    extends $NotifierProvider<OrdersNotifier, AsyncValue<OrdersStateData>> {
  OrdersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersNotifierHash();

  @$internal
  @override
  OrdersNotifier create() => OrdersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<OrdersStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<OrdersStateData>>(value),
    );
  }
}

String _$ordersNotifierHash() => r'ee49b9bde206797ac9ca921e70ab3836ee7fdf15';

abstract class _$OrdersNotifier extends $Notifier<AsyncValue<OrdersStateData>> {
  AsyncValue<OrdersStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<OrdersStateData>, AsyncValue<OrdersStateData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<OrdersStateData>,
                AsyncValue<OrdersStateData>
              >,
              AsyncValue<OrdersStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
