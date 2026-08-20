// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_counts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InboxCounts)
final inboxCountsProvider = InboxCountsProvider._();

final class InboxCountsProvider
    extends $NotifierProvider<InboxCounts, InboxCountsState> {
  InboxCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxCountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxCountsHash();

  @$internal
  @override
  InboxCounts create() => InboxCounts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InboxCountsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InboxCountsState>(value),
    );
  }
}

String _$inboxCountsHash() => r'6f4ea82c3a868f03cbf92a02ca66403854978edf';

abstract class _$InboxCounts extends $Notifier<InboxCountsState> {
  InboxCountsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InboxCountsState, InboxCountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InboxCountsState, InboxCountsState>,
              InboxCountsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
