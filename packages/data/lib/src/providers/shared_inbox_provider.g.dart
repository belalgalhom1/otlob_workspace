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
        isAutoDispose: true,
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

String _$sharedInboxHash() => r'3047849da2cbf7f16793268d37c39bdb4cef22a9';

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
