// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_inbox_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SharedInbox)
final sharedInboxProvider = SharedInboxProvider._();

final class SharedInboxProvider
    extends $NotifierProvider<SharedInbox, InboxState> {
  SharedInboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedInboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedInboxHash();

  @$internal
  @override
  SharedInbox create() => SharedInbox();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InboxState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InboxState>(value),
    );
  }
}

String _$sharedInboxHash() => r'7ac4c60490a8a221ab3274995a32a0dc3dff0b8b';

abstract class _$SharedInbox extends $Notifier<InboxState> {
  InboxState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InboxState, InboxState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InboxState, InboxState>,
              InboxState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
