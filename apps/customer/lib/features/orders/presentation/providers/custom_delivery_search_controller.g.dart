// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_delivery_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomDeliverySearchController)
final customDeliverySearchControllerProvider =
    CustomDeliverySearchControllerFamily._();

final class CustomDeliverySearchControllerProvider
    extends
        $NotifierProvider<
          CustomDeliverySearchController,
          CustomDeliverySearchState
        > {
  CustomDeliverySearchControllerProvider._({
    required CustomDeliverySearchControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customDeliverySearchControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customDeliverySearchControllerHash();

  @override
  String toString() {
    return r'customDeliverySearchControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CustomDeliverySearchController create() => CustomDeliverySearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomDeliverySearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomDeliverySearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CustomDeliverySearchControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customDeliverySearchControllerHash() =>
    r'3a4e48bef81297e58164bb3331275c1f0d584cb3';

final class CustomDeliverySearchControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CustomDeliverySearchController,
          CustomDeliverySearchState,
          CustomDeliverySearchState,
          CustomDeliverySearchState,
          String
        > {
  CustomDeliverySearchControllerFamily._()
    : super(
        retry: null,
        name: r'customDeliverySearchControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomDeliverySearchControllerProvider call(String orderId) =>
      CustomDeliverySearchControllerProvider._(argument: orderId, from: this);

  @override
  String toString() => r'customDeliverySearchControllerProvider';
}

abstract class _$CustomDeliverySearchController
    extends $Notifier<CustomDeliverySearchState> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  CustomDeliverySearchState build(String orderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CustomDeliverySearchState, CustomDeliverySearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomDeliverySearchState, CustomDeliverySearchState>,
              CustomDeliverySearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
