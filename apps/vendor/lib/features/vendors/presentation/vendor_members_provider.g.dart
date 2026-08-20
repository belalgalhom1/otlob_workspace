// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VendorMembersNotifier)
final vendorMembersProvider = VendorMembersNotifierFamily._();

final class VendorMembersNotifierProvider
    extends
        $NotifierProvider<VendorMembersNotifier, AsyncValue<List<dynamic>>> {
  VendorMembersNotifierProvider._({
    required VendorMembersNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'vendorMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vendorMembersNotifierHash();

  @override
  String toString() {
    return r'vendorMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VendorMembersNotifier create() => VendorMembersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<dynamic>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VendorMembersNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vendorMembersNotifierHash() =>
    r'e905a4c6e93459902682f2042ebcbdcd18f64fcc';

final class VendorMembersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          VendorMembersNotifier,
          AsyncValue<List<dynamic>>,
          AsyncValue<List<dynamic>>,
          AsyncValue<List<dynamic>>,
          String
        > {
  VendorMembersNotifierFamily._()
    : super(
        retry: null,
        name: r'vendorMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VendorMembersNotifierProvider call(String vendorId) =>
      VendorMembersNotifierProvider._(argument: vendorId, from: this);

  @override
  String toString() => r'vendorMembersProvider';
}

abstract class _$VendorMembersNotifier
    extends $Notifier<AsyncValue<List<dynamic>>> {
  late final _$args = ref.$arg as String;
  String get vendorId => _$args;

  AsyncValue<List<dynamic>> build(String vendorId);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
