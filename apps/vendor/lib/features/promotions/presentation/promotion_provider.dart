import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';
import 'package:data/data.dart';

part 'promotion_provider.g.dart';

@Riverpod(keepAlive: true)
class PromotionNotifier extends _$PromotionNotifier {
  @override
  AsyncValue<List<dynamic>> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchPromotions() async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final repository = ref.read(adminVendorsRepositoryProvider);
      final results = await Future.wait([
        ref.read(vendorPromotionsRepositoryProvider).promotionsFindAll(),
        ref.read(adminOffersRepositoryProvider).offersFindAll(),
      ]);

      final promos = results[0].map((p) => {...p, '_isOffer': false}).toList();
      final offers = results[1].map((o) => {...o, '_isOffer': true}).toList();

      state = AsyncValue.data([...promos, ...offers]);
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error(e.toString(), st);
      }
    }
  }
}

