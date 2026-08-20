// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vertical_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerticalNotifier)
final verticalProvider = VerticalNotifierProvider._();

final class VerticalNotifierProvider
    extends $NotifierProvider<VerticalNotifier, AsyncValue<List<dynamic>>> {
  VerticalNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verticalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verticalNotifierHash();

  @$internal
  @override
  VerticalNotifier create() => VerticalNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<dynamic>>>(value),
    );
  }
}

String _$verticalNotifierHash() => r'02507cbfc9e3aa26a82effe8bbece1a235684c77';

abstract class _$VerticalNotifier extends $Notifier<AsyncValue<List<dynamic>>> {
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
