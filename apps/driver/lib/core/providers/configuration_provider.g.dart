// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Configuration)
final configurationProvider = ConfigurationProvider._();

final class ConfigurationProvider
    extends $NotifierProvider<Configuration, AsyncValue<Map<String, dynamic>>> {
  ConfigurationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configurationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configurationHash();

  @$internal
  @override
  Configuration create() => Configuration();

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

String _$configurationHash() => r'dbdc0ec9ce54a0320cf35aabc8f83ae0b6ca091e';

abstract class _$Configuration
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
