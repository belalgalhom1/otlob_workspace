import 'package:vendor/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:api/api.dart'
    show
        CreateMobileWalletDto,
        CreateMobileWalletDtoTypeEnum,
        ReviewWalletTopUpDto,
        ReviewWalletTopUpDtoStatusEnum;
import 'package:core/core.dart';
import 'wallet_models.dart';
part 'wallet_providers.g.dart';

@riverpod
Future<WalletTopUpRequest> topUpDetails(Ref ref, String id) async {
  final repo = ref.watch(adminWalletRepositoryProvider);
  final result = await repo.walletGetTopUpById(id: id);
  if (result is Map) {
    return WalletTopUpRequest.fromJson(Map<String, dynamic>.from(result));
  }
  throw Exception('Invalid top-up details payload');
}

@riverpod
class PendingTopUps extends _$PendingTopUps {
  @override
  Future<List<dynamic>> build() async {
    final repo = ref.watch(adminWalletRepositoryProvider);
    final result = await repo.walletGetPendingTopUps();
    if (result is List) {
      return result
          .map((e) => WalletTopUpRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<void> reviewTopUp(String id, String status, {String? notes}) async {
    final link = ref.keepAlive();
    try {
      final repo = ref.read(adminWalletRepositoryProvider);
      final trimmedNotes = notes?.trim();
      await repo.walletReviewTopUp(
        id: id,
        reviewWalletTopUpDto: ReviewWalletTopUpDto(
          (b) => b
            ..status =
                ReviewWalletTopUpDtoStatusEnum.valueOf(status.toUpperCase())
            ..notes =
                (trimmedNotes != null && trimmedNotes.isNotEmpty)
                    ? trimmedNotes
                    : null,
        ),
      );
      if (ref.mounted) {
        ref.invalidate(topUpDetailsProvider(id));
        ref.invalidateSelf();
      }
    } finally {
      link.close();
    }
  }
}

@riverpod
class PlatformWallets extends _$PlatformWallets {
  @override
  Future<List<dynamic>> build() async {
    final repo = ref.watch(adminWalletRepositoryProvider);
    final result = await repo.walletGetAllPlatformWallets();
    return result is List ? result : [];
  }

  Future<void> createWallet(String provider, String number) async {
    final repo = ref.read(adminWalletRepositoryProvider);
    await repo.walletCreatePlatformWallet(createMobileWalletDto: CreateMobileWalletDto((b) => b
      ..type = CreateMobileWalletDtoTypeEnum.valueOf(provider)
      ..number = number
    ));
    ref.invalidateSelf();
  }

  Future<void> toggleWallet(String id, bool isActive) async {
    final dio = ref.read(apiClientProvider).dio;
    await dio.patch('/wallet/platform/$id', data: {'isActive': isActive});
    ref.invalidateSelf();
  }
}


