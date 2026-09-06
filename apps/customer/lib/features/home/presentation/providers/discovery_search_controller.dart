import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import 'package:flutter/foundation.dart';

import 'customer_location_provider.dart';

final discoverySearchControllerProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String query, String? verticalId})>((ref, arg) async {
  final dio = ref.read(dioProvider);
  
  if (arg.query.isEmpty) return [];

  // Convert verticalId 'all' to null for backend
  final vId = arg.verticalId == 'all' ? null : arg.verticalId;

  final location = await ref.watch(effectiveCustomerLocationProvider.future);

  try {
    final response = await dio.get(
      '/vendors/discovery/search',
      queryParameters: {
        'search': arg.query,
        'verticalId': ?vId,
        if (location != null) 'lat': location.lat,
        if (location != null) 'lng': location.lng,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final results = data['data']['results'] as List<dynamic>? ?? [];
    return results.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  } catch (e) {
    debugPrint('Discovery search error: $e');
    return [];
  }
});



