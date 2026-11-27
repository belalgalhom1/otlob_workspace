import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

part 'favorites_provider.g.dart';

/// Displays a concise, theme-aware toast message when a vendor is added to or
/// removed from the customer's favorites list.
void showVendorFavoriteFeedback(
  BuildContext context, {
  required bool? isFavorite,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final s = AppStrings.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final IconData icon;
  final Color iconColor;
  final String message;
  final Color backgroundColor;
  final Color textColor;

  if (isFavorite == null) {
    icon = Icons.error_outline_rounded;
    iconColor = Colors.white;
    message = s.favoriteUpdateFailed;
    backgroundColor = const Color(0xFFDC2626);
    textColor = Colors.white;
  } else if (isFavorite) {
    icon = Icons.favorite_rounded;
    iconColor = const Color(0xFFF87171);
    message = s.addedToFavorites;
    backgroundColor = isDark ? const Color(0xFF24211C) : const Color(0xFF181613);
    textColor = Colors.white;
  } else {
    icon = Icons.favorite_border_rounded;
    iconColor = const Color(0xFFE5A93C);
    message = s.removedFromFavorites;
    backgroundColor = isDark ? const Color(0xFF24211C) : const Color(0xFF181613);
    textColor = Colors.white;
  }

  messenger
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isFavorite == null
                ? Colors.transparent
                : const Color(0xFFE5A93C).withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

@riverpod
class Favorites extends _$Favorites {
  @override
  Set<String> build() {
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.authenticated) {
        _fetchFavorites();
      } else if (next == AuthStatus.unauthenticated) {
        state = {};
      }
    });

    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.authenticated) {
      _fetchFavorites();
    }
    return {};
  }

  Future<void> _fetchFavorites() async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus != AuthStatus.authenticated) {
      state = {};
      return;
    }

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

  Future<bool?> toggleFavorite(String vendorId) async {
    final isFav = state.contains(vendorId);
    final nextIsFav = !isFav;

    // Optimistic update
    if (isFav) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }

    try {
      final repo = ref.read(customerFavoritesRepositoryProvider);
      final response = await repo.toggleFavoriteVendor(vendorId);
      final serverIsFav = response is Map && response['isFavorite'] is bool
          ? response['isFavorite'] as bool
          : nextIsFav;
      if (serverIsFav) {
        state = {...state, vendorId};
      } else {
        state = {...state}..remove(vendorId);
      }
      return serverIsFav;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on error
      if (isFav) {
        state = {...state, vendorId};
      } else {
        state = {...state}..remove(vendorId);
      }
      return null;
    }
  }
}
