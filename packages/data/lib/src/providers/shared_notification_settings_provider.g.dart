// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_notification_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SharedNotificationSettings)
final sharedNotificationSettingsProvider =
    SharedNotificationSettingsProvider._();

final class SharedNotificationSettingsProvider
    extends $NotifierProvider<SharedNotificationSettings, AsyncValue<dynamic>> {
  SharedNotificationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedNotificationSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedNotificationSettingsHash();

  @$internal
  @override
  SharedNotificationSettings create() => SharedNotificationSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<dynamic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<dynamic>>(value),
    );
  }
}

String _$sharedNotificationSettingsHash() =>
    r'634e80d50c108763998c921ce615b087b20cf6ac';

abstract class _$SharedNotificationSettings
    extends $Notifier<AsyncValue<dynamic>> {
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
