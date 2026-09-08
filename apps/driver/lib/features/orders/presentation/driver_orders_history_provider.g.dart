// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_orders_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverOrdersHistory)
final driverOrdersHistoryProvider = DriverOrdersHistoryProvider._();

final class DriverOrdersHistoryProvider
    extends $NotifierProvider<DriverOrdersHistory, DriverOrdersHistoryState> {
  DriverOrdersHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverOrdersHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverOrdersHistoryHash();

  @$internal
  @override
  DriverOrdersHistory create() => DriverOrdersHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriverOrdersHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriverOrdersHistoryState>(value),
    );
  }
}

String _$driverOrdersHistoryHash() =>
    r'f6fc54d95fa751f7174e6029377b189bcad90807';

abstract class _$DriverOrdersHistory
    extends $Notifier<DriverOrdersHistoryState> {
  DriverOrdersHistoryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<DriverOrdersHistoryState, DriverOrdersHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DriverOrdersHistoryState, DriverOrdersHistoryState>,
              DriverOrdersHistoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
