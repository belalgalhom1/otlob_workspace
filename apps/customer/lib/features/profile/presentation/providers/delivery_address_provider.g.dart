// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_address_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ManualSelectedAddressId)
final manualSelectedAddressIdProvider = ManualSelectedAddressIdProvider._();

final class ManualSelectedAddressIdProvider
    extends $NotifierProvider<ManualSelectedAddressId, String?> {
  ManualSelectedAddressIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualSelectedAddressIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualSelectedAddressIdHash();

  @$internal
  @override
  ManualSelectedAddressId create() => ManualSelectedAddressId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$manualSelectedAddressIdHash() =>
    r'a77175e06204dbdb9ea405c38477f551e1f26f5d';

abstract class _$ManualSelectedAddressId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(activeDeliveryAddress)
final activeDeliveryAddressProvider = ActiveDeliveryAddressProvider._();

final class ActiveDeliveryAddressProvider
    extends
        $FunctionalProvider<
          Map<String, dynamic>?,
          Map<String, dynamic>?,
          Map<String, dynamic>?
        >
    with $Provider<Map<String, dynamic>?> {
  ActiveDeliveryAddressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDeliveryAddressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDeliveryAddressHash();

  @$internal
  @override
  $ProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, dynamic>? create(Ref ref) {
    return activeDeliveryAddress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, dynamic>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, dynamic>?>(value),
    );
  }
}

String _$activeDeliveryAddressHash() =>
    r'26e2105bc7fcc75d06dcad9a5106322365235b8d';
