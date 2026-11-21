// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Unified Customer Dio client delegating directly to [core.dioProvider] so all
/// HTTP traffic shares one [AuthInterceptor] and one refresh-token mutex.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Unified Customer Dio client delegating directly to [core.dioProvider] so all
/// HTTP traffic shares one [AuthInterceptor] and one refresh-token mutex.

final class DioProvider
    extends $FunctionalProvider<core.Dio, core.Dio, core.Dio>
    with $Provider<core.Dio> {
  /// Unified Customer Dio client delegating directly to [core.dioProvider] so all
  /// HTTP traffic shares one [AuthInterceptor] and one refresh-token mutex.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<core.Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  core.Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(core.Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<core.Dio>(value),
    );
  }
}

String _$dioHash() => r'447cb7d1f44de1ac07a9239d0a392f25e7ccaa43';
