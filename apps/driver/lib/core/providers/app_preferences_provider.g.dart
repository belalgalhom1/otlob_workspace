// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppPreferences)
final appPreferencesProvider = AppPreferencesProvider._();

final class AppPreferencesProvider
    extends $NotifierProvider<AppPreferences, AppPreferencesState> {
  AppPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPreferencesHash();

  @$internal
  @override
  AppPreferences create() => AppPreferences();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppPreferencesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppPreferencesState>(value),
    );
  }
}

String _$appPreferencesHash() => r'21a40090825ea955515bcb1a7667d982559c3129';

abstract class _$AppPreferences extends $Notifier<AppPreferencesState> {
  AppPreferencesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppPreferencesState, AppPreferencesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppPreferencesState, AppPreferencesState>,
              AppPreferencesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
