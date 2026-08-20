// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverNotifications)
final driverNotificationsProvider = DriverNotificationsProvider._();

final class DriverNotificationsProvider
    extends $NotifierProvider<DriverNotifications, AsyncValue<List<dynamic>>> {
  DriverNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverNotificationsHash();

  @$internal
  @override
  DriverNotifications create() => DriverNotifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<dynamic>>>(value),
    );
  }
}

String _$driverNotificationsHash() =>
    r'c4ffbc6340cdc7962da55786ba0fad75dc788ccf';

abstract class _$DriverNotifications
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
