import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vendors within [radiusKm] of the driver, each with its recent order count.
///
/// The backend picks the closest branch per vendor and counts both
/// single-vendor orders and multi-vendor fulfillments over the last [days].
final nearbyVendorsProvider = FutureProvider.family<List<dynamic>,
    ({double lat, double lng, double radiusKm, int days})>((ref, args) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<dynamic>(
    '/drivers/me/nearby-vendors',
    queryParameters: {
      'lat': args.lat,
      'lng': args.lng,
      'radiusKm': args.radiusKm,
      'days': args.days,
    },
  );

  final body = response.data;
  final raw = body is Map ? (body['data'] ?? body['items']) : body;
  if (raw is List) return raw;
  return const [];
});
