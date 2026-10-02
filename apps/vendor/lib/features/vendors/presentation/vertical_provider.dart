import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';
import 'package:core/core.dart';
import 'package:api/api.dart';
import 'package:dio/dio.dart' as dio;

part 'vertical_provider.g.dart';

@Riverpod(keepAlive: true)
class VerticalNotifier extends _$VerticalNotifier {
  @override
  AsyncValue<List<dynamic>> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchVerticals() async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(adminVerticalsRepositoryProvider);
      final result = await repository.getVerticals();
      state = AsyncValue.data(result);
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error(ApiErrorMapper.fromError(e), st);
      }
    }
  }

  Future<void> createVertical(Map<String, dynamic> data) async {
    final repository = ref.read(adminVerticalsRepositoryProvider);
    final dto = CreateVendorVerticalDto((b) {
      b.name = data['name'];
      if (data['nameAr'] != null) b.nameAr = data['nameAr'];
      b.slug = data['name'].toString().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      b.isActive = data['isActive'] ?? true;
      b.sortOrder = data['sortOrder'] ?? 0;
    });

    final result = await repository.createVertical(dto);
    
    if (data['iconFile'] != null && result != null && result['id'] != null) {
      final file = data['iconFile'];
      final multipartFile = await dio.MultipartFile.fromFile(file.path, filename: file.name);
      await repository.uploadVerticalIcon(result['id'], multipartFile);
    }
    await fetchVerticals();
  }

  Future<void> updateVertical(String id, Map<String, dynamic> data) async {
    final repository = ref.read(adminVerticalsRepositoryProvider);
    final dto = UpdateVendorVerticalDto((b) {
      if (data['name'] != null) b.name = data['name'];
      if (data['nameAr'] != null) b.nameAr = data['nameAr'];
      if (data['isActive'] != null) b.isActive = data['isActive'];
      if (data['sortOrder'] != null) b.sortOrder = data['sortOrder'];
    });

    await repository.updateVertical(id, dto);

    if (data['iconFile'] != null) {
      final file = data['iconFile'];
      final multipartFile = await dio.MultipartFile.fromFile(file.path, filename: file.name);
      await repository.uploadVerticalIcon(id, multipartFile);
    }
    await fetchVerticals();
  }

  Future<void> deleteVertical(String id) async {
    final repository = ref.read(adminVerticalsRepositoryProvider);
    await repository.deleteVertical(id);
    await fetchVerticals();
  }
}

