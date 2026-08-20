// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserNotifier)
final userProvider = UserNotifierProvider._();

final class UserNotifierProvider
    extends $NotifierProvider<UserNotifier, AsyncValue<UsersStateData>> {
  UserNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userNotifierHash();

  @$internal
  @override
  UserNotifier create() => UserNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<UsersStateData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<UsersStateData>>(value),
    );
  }
}

String _$userNotifierHash() => r'de3c1dcd0dd00cf085edb9745ec1d2c87ef1286a';

abstract class _$UserNotifier extends $Notifier<AsyncValue<UsersStateData>> {
  AsyncValue<UsersStateData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<UsersStateData>, AsyncValue<UsersStateData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UsersStateData>,
                AsyncValue<UsersStateData>
              >,
              AsyncValue<UsersStateData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
