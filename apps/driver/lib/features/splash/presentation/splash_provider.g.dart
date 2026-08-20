// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Splash)
final splashProvider = SplashProvider._();

final class SplashProvider
    extends $AsyncNotifierProvider<Splash, AppStartupState> {
  SplashProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashHash();

  @$internal
  @override
  Splash create() => Splash();
}

String _$splashHash() => r'08296191c594e627b68f8eae73ab0a8d5cc9a770';

abstract class _$Splash extends $AsyncNotifier<AppStartupState> {
  FutureOr<AppStartupState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppStartupState>, AppStartupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppStartupState>, AppStartupState>,
              AsyncValue<AppStartupState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
