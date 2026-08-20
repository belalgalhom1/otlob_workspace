// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TicketNotifier)
final ticketProvider = TicketNotifierProvider._();

final class TicketNotifierProvider
    extends $NotifierProvider<TicketNotifier, AsyncValue<TicketStateData>> {
  TicketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketNotifierHash();

  @$internal
  @override
  TicketNotifier create() => TicketNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<TicketStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<TicketStateData>>(value),
    );
  }
}

String _$ticketNotifierHash() => r'c21ea8491a30e144521dddc5d68e1f505181adc1';

abstract class _$TicketNotifier extends $Notifier<AsyncValue<TicketStateData>> {
  AsyncValue<TicketStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<TicketStateData>, AsyncValue<TicketStateData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TicketStateData>,
                AsyncValue<TicketStateData>
              >,
              AsyncValue<TicketStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
