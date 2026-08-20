// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

final class SettingsNotifierProvider
    extends
        $NotifierProvider<SettingsNotifier, AsyncValue<Map<String, dynamic>>> {
  SettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Map<String, dynamic>>>(
        value,
      ),
    );
  }
}

String _$settingsNotifierHash() => r'8bbaea1d1783ffce76ae574c05ddd03bb0c0ef67';

abstract class _$SettingsNotifier
    extends $Notifier<AsyncValue<Map<String, dynamic>>> {
  AsyncValue<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, dynamic>>,
              AsyncValue<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                AsyncValue<Map<String, dynamic>>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
