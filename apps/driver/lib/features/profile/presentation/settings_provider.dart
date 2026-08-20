import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:core/core.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  AsyncValue<dynamic> build() {
    Future.microtask(() => fetchSettings());
    return const AsyncValue.loading();
  }

  Future<void> fetchSettings() async {
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(sharedUserRepositoryProvider);
      final response = await repository.getNotificationSettings();
      state = AsyncValue.data(response);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateNotificationSetting({
    bool? pushEnabled,
    bool? orderUpdates,
    bool? chatMessages,
    bool? promotions,
    bool? system,
  }) async {
    final prev = state;
    try {
      final repository = ref.read(sharedUserRepositoryProvider);
      final dto = UpdateNotificationSettingsDto((b) {
        if (pushEnabled != null) b.pushEnabled = pushEnabled;
        if (orderUpdates != null) b.orderUpdates = orderUpdates;
        if (chatMessages != null) b.chatMessages = chatMessages;
        if (promotions != null) b.promotions = promotions;
        if (system != null) b.system = system;
      });
      await repository.updateNotificationSettings(dto);
      await fetchSettings();
    } catch (e) {
      if (prev.hasValue) {
        state = prev;
      }
      throw ApiErrorMapper.fromError(e);
    }
  }
}
