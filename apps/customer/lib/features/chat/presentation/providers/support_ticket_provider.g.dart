// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupportTicket)
final supportTicketProvider = SupportTicketProvider._();

final class SupportTicketProvider
    extends $AsyncNotifierProvider<SupportTicket, void> {
  SupportTicketProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportTicketProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportTicketHash();

  @$internal
  @override
  SupportTicket create() => SupportTicket();
}

String _$supportTicketHash() => r'cdfd624779014947f49b95463e510e7bafcb67a0';

abstract class _$SupportTicket extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
