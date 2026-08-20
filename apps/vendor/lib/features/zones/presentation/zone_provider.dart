import 'package:data/data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';

part 'zone_provider.g.dart';

class ZoneStateData {
  final List<dynamic> zones;
  final int total;
  ZoneStateData(this.zones, {this.total = 0});
}

@Riverpod(keepAlive: true)
class ZoneNotifier extends _$ZoneNotifier {
  @override
  AsyncValue<ZoneStateData> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchZones() async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(zonesRepositoryProvider);
      final result = await repository.getZones();
      state = AsyncValue.data(ZoneStateData(result, total: result.length));
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error('Failed to fetch zones', st);
      }
    }
  }

  Future<void> createZone(Map<String, dynamic> zoneData) async {
    final repository = ref.read(zonesRepositoryProvider);
    await repository.zonesCreateRaw(zoneData);
    await fetchZones();
  }

  Future<void> updateZone(String id, Map<String, dynamic> zoneData) async {
    final repository = ref.read(zonesRepositoryProvider);
    await repository.zonesUpdateRaw(id, zoneData);
    await fetchZones();
  }

  Future<void> deleteZone(String id) async {
    final repository = ref.read(zonesRepositoryProvider);
    await repository.zonesRemove(id: id);
    await fetchZones();
  }
}

