import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  @override
  Set<String> build() {
    // Fetch asynchronously so we don't block the UI with a loading state,
    // since the UI expects a synchronous Set<String>.
    _fetchFavorites();
    return {};
  }

  Future<void> _fetchFavorites() async {
    try {
      final repo = ref.read(customerFavoritesRepositoryProvider);
      final data = await repo.getFavorites();
      
      // The API returns the data wrapped. Depending on the exact structure:
      // If it returns a list of FavoriteVendor objects or maps:
      if (data is List) {
        state = data.map((e) {
          if (e is Map) return e['vendorId']?.toString();
          return null;
        }).where((e) => e != null).cast<String>().toSet();
      } else if (data is Map && data['vendors'] != null) {
        // Fallback in case of custom wrapped format
        state = (data['vendors'] as List).map((e) {
          if (e is Map) return e['vendorId']?.toString() ?? e['id']?.toString();
          return null;
        }).where((e) => e != null).cast<String>().toSet();
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<void> toggleFavorite(String vendorId) async {
    final isFav = state.contains(vendorId);
    
    // Optimistic update
    if (isFav) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
    
    try {
      final repo = ref.read(customerFavoritesRepositoryProvider);
      await repo.toggleFavoriteVendor(vendorId);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on error
      if (isFav) {
        state = {...state, vendorId};
      } else {
        state = {...state}..remove(vendorId);
      }
    }
  }
}
