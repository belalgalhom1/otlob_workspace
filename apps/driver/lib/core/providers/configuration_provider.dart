import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';

part 'configuration_provider.g.dart';

@Riverpod(keepAlive: true)
class Configuration extends _$Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() {
    _fetchConfig();
    return const AsyncValue.loading();
  }

  Future<void> _fetchConfig() async {
    try {
      final repository = ref.read(sharedPlatformSettingsRepositoryProvider);
      final response = await repository.getPublicSettings();
      state = AsyncValue.data(response ?? {});
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String get currency {
    return state.value?['currency'] ?? 'EGP';
  }
}
