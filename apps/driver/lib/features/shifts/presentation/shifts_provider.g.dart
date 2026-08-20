// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shifts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DriverShifts)
final driverShiftsProvider = DriverShiftsProvider._();

final class DriverShiftsProvider
    extends $NotifierProvider<DriverShifts, AsyncValue<List<dynamic>>> {
  DriverShiftsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverShiftsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverShiftsHash();

  @$internal
  @override
  DriverShifts create() => DriverShifts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<dynamic>>>(value),
    );
  }
}

String _$driverShiftsHash() => r'a7d9bb821b3be287be103cff82273b4de2fee21f';

abstract class _$DriverShifts extends $Notifier<AsyncValue<List<dynamic>>> {
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

@ProviderFor(AvailablePools)
final availablePoolsProvider = AvailablePoolsFamily._();

final class AvailablePoolsProvider
    extends $AsyncNotifierProvider<AvailablePools, List<dynamic>> {
  AvailablePoolsProvider._({
    required AvailablePoolsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'availablePoolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availablePoolsHash();

  @override
  String toString() {
    return r'availablePoolsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AvailablePools create() => AvailablePools();

  @override
  bool operator ==(Object other) {
    return other is AvailablePoolsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availablePoolsHash() => r'e44bb7a6aedda1b228a4a1a5d6f8f2c881b3636b';

final class AvailablePoolsFamily extends $Family
    with
        $ClassFamilyOverride<
          AvailablePools,
          AsyncValue<List<dynamic>>,
          List<dynamic>,
          FutureOr<List<dynamic>>,
          String
        > {
  AvailablePoolsFamily._()
    : super(
        retry: null,
        name: r'availablePoolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AvailablePoolsProvider call(String zoneId) =>
      AvailablePoolsProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'availablePoolsProvider';
}

abstract class _$AvailablePools extends $AsyncNotifier<List<dynamic>> {
  late final _$args = ref.$arg as String;
  String get zoneId => _$args;

  FutureOr<List<dynamic>> build(String zoneId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<dynamic>>, List<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, List<dynamic>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SwapBoard)
final swapBoardProvider = SwapBoardProvider._();

final class SwapBoardProvider
    extends $AsyncNotifierProvider<SwapBoard, List<dynamic>> {
  SwapBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swapBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swapBoardHash();

  @$internal
  @override
  SwapBoard create() => SwapBoard();
}

String _$swapBoardHash() => r'c52c9444173ff5ae6cc76687c4635ddbc5a3618c';

abstract class _$SwapBoard extends $AsyncNotifier<List<dynamic>> {
  FutureOr<List<dynamic>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<dynamic>>, List<dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<dynamic>>, List<dynamic>>,
              AsyncValue<List<dynamic>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
