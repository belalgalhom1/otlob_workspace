// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_message_listener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalMessageListener)
final globalMessageListenerProvider = GlobalMessageListenerProvider._();

final class GlobalMessageListenerProvider
    extends $NotifierProvider<GlobalMessageListener, void> {
  GlobalMessageListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalMessageListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalMessageListenerHash();

  @$internal
  @override
  GlobalMessageListener create() => GlobalMessageListener();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$globalMessageListenerHash() =>
    r'09297eb2e4c8690d4764f58416d07ba5aa6a53c7';

abstract class _$GlobalMessageListener extends $Notifier<void> {
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
