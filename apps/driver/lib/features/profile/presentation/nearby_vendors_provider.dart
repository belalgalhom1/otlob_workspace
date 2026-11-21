import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vendors within [radiusKm] of the driver, with their real-time order density in current time.
///
/// The backend picks the closest branch per vendor and counts active in-flight orders
/// (preparing, ready for pickup, looking for driver) + orders in the current time window.
final nearbyVendorsProvider = FutureProvider.autoDispose.family<List<dynamic>,
    ({double lat, double lng, double radiusKm, int? hours, int? days})>(
  (ref, args) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<dynamic>(
      '/drivers/me/nearby-vendors',
      queryParameters: {
        'lat': args.lat,
        'lng': args.lng,
        'radiusKm': args.radiusKm,
        if (args.hours != null) 'hours': args.hours,
        if (args.days != null) 'days': args.days,
      },
    );

    final body = response.data;
    final raw = body is Map ? (body['data'] ?? body['items']) : body;
    if (raw is List) return raw;
    return const [];
  },
);
