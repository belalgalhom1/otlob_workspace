// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SharedChat)
final sharedChatProvider = SharedChatFamily._();

final class SharedChatProvider
    extends $AsyncNotifierProvider<SharedChat, List<Message>> {
  SharedChatProvider._({
    required SharedChatFamily super.from,
    required SharedChatArgs super.argument,
  }) : super(
         retry: null,
         name: r'sharedChatProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sharedChatHash();

  @override
  String toString() {
    return r'sharedChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SharedChat create() => SharedChat();

  @override
  bool operator ==(Object other) {
    return other is SharedChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sharedChatHash() => r'd0768c2b75142a7f2cc52b1c6c1d65db76e3f5c6';

final class SharedChatFamily extends $Family
    with
        $ClassFamilyOverride<
          SharedChat,
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>,
          SharedChatArgs
        > {
  SharedChatFamily._()
    : super(
        retry: null,
        name: r'sharedChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SharedChatProvider call(SharedChatArgs args) =>
      SharedChatProvider._(argument: args, from: this);

  @override
  String toString() => r'sharedChatProvider';
}

abstract class _$SharedChat extends $AsyncNotifier<List<Message>> {
  late final _$args = ref.$arg as SharedChatArgs;
  SharedChatArgs get args => _$args;

  FutureOr<List<Message>> build(SharedChatArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Message>>, List<Message>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Message>>, List<Message>>,
              AsyncValue<List<Message>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
