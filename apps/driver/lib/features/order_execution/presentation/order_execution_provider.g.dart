// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_execution_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OrderExecution)
final orderExecutionProvider = OrderExecutionProvider._();

final class OrderExecutionProvider
    extends $NotifierProvider<OrderExecution, AsyncValue<dynamic>> {
  OrderExecutionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderExecutionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderExecutionHash();

  @$internal
  @override
  OrderExecution create() => OrderExecution();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<dynamic>>(value),
    );
  }
}

String _$orderExecutionHash() => r'696e9804ee52f878d244cf3fc81427eb6dc4fa5b';

abstract class _$OrderExecution extends $Notifier<AsyncValue<dynamic>> {
  AsyncValue<dynamic> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<dynamic>, AsyncValue<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<dynamic>, AsyncValue<dynamic>>,
              AsyncValue<dynamic>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
