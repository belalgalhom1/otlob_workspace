// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_order_listener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalOrderListener)
final globalOrderListenerProvider = GlobalOrderListenerProvider._();

final class GlobalOrderListenerProvider
    extends $NotifierProvider<GlobalOrderListener, void> {
  GlobalOrderListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalOrderListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalOrderListenerHash();

  @$internal
  @override
  GlobalOrderListener create() => GlobalOrderListener();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$globalOrderListenerHash() =>
    r'41c400ef8657c90e1f563859ca586c7bd803062e';

abstract class _$GlobalOrderListener extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
