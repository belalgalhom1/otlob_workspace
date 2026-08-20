import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:core/core.dart';
import 'home_state.dart';
import 'package:flutter/foundation.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  FutureOr<HomeData> build() async {
    return loadDashboardData();
  }

  Future<HomeData> loadDashboardData() async {
    final verticalsRepo = ref.read(sharedVerticalsRepositoryProvider);
    final vendorsRepo = ref.read(customerVendorsRepositoryProvider);
    final promotionsRepo = ref.read(customerPromotionsRepositoryProvider);
    final offersRepo = ref.read(customerOffersRepositoryProvider);

    try {
      final results = await Future.wait([
        verticalsRepo.getActiveVerticals().catchError((e) { debugPrint('Verticals error: $e'); return []; }),
        vendorsRepo.getVendors(limit: 20).catchError((e) { debugPrint('Vendors error: $e'); return []; }),
        promotionsRepo.getPromotions().catchError((e) { debugPrint('Promotions error: $e'); return []; }),
        offersRepo.getOffers().catchError((e) { debugPrint('Offers error: $e'); return []; }),
      ]);

      final resp0 = results[0];
      final resp1 = results[1];
      final resp2 = results[2];
      final resp3 = results[3];

      List<dynamic> verticalsData = [];
      if (resp0 is List) {
        verticalsData = resp0;
      } else if (resp0 is Map && resp0['data'] is List) {
        verticalsData = resp0['data'];
      }

      List<dynamic> vendorsData = [];
      if (resp1 is List) {
        vendorsData = resp1;
      } else if (resp1 is Map) {
        if (resp1.containsKey('vendors') && resp1['vendors'] is List) {
          vendorsData = resp1['vendors'];
        } else if (resp1.containsKey('data') && resp1['data'] is List) {
          vendorsData = resp1['data'];
        } else if (resp1.containsKey('data') && resp1['data'] is Map && resp1['data']['vendors'] is List) {
          vendorsData = resp1['data']['vendors'];
        }
      }

      // Map verticals to categories
      final categories = verticalsData.map((v) {
        final Map<String, dynamic> vert = Map<String, dynamic>.from(v as Map);
        return {
          'id': vert['id'],
          'name': vert['name'],
          'nameAr': vert['nameAr'],
          'iconUrl': vert['iconUrl'],
          'type': vert['slug'],
        };
      }).toList();

      // Add "All" category at the beginning
      categories.insert(0, {'id': 'all', 'name': 'All', 'nameAr': 'الكل', 'type': 'all'});

      // Map vendors
      final vendors = vendorsData.map((v) {
        final Map<String, dynamic> vendor = Map<String, dynamic>.from(v as Map);
        // Map backend fields to frontend expectations
        vendor['name'] = vendor['storeName'];
        vendor['nameAr'] = vendor['storeNameAr'];
        vendor['image'] = vendor['coverImage'] ?? vendor['logo'];
        vendor['logo'] = vendor['logo'];
        vendor['coverImage'] = vendor['coverImage'];
        vendor['vendor'] = vendor['description'];
        vendor['vendorAr'] = vendor['descriptionAr'];
        vendor['type'] = vendor['vertical']?['slug'] ?? 'other';
        return vendor;
      }).toList();

      List<dynamic> promotionsData = [];
      if (resp2 is List) {
        promotionsData = resp2;
      } else if (resp2 is Map && resp2['data'] is List) {
        promotionsData = resp2['data'];
      }
      
      final promotions = promotionsData.map((p) {
        final Map<String, dynamic> promo = Map<String, dynamic>.from(p as Map);
        return {
          'id': promo['id'],
          'title': promo['title'],
          'titleAr': promo['titleAr'],
          'description': promo['description'],
          'descriptionAr': promo['descriptionAr'],
          'imageUrl': promo['imageUrl'],
          'type': promo['type'],
          'vendorId': promo['vendorId'],
          'productId': promo['productId'],
          'externalUrl': promo['externalUrl'],
        };
      }).toList();

      List<dynamic> offersData = [];
      if (resp3 is List) {
        offersData = resp3;
      } else if (resp3 is Map && resp3['data'] is List) {
        offersData = resp3['data'];
      }

      final offers = offersData.map((o) {
        final Map<String, dynamic> offer = Map<String, dynamic>.from(o as Map);
        return {
          'id': offer['id'],
          'originalPrice': offer['originalPrice'],
          'offerPrice': offer['offerPrice'],
          'vendorId': offer['vendorId'],
          'productId': offer['productId'],
          'isActive': offer['isActive'],
          'sortOrder': offer['sortOrder'],
          // Enriched from relations
          'productImageUrl': offer['product']?['imageUrl'],
          'productName': offer['product']?['name'],
          'productNameAr': offer['product']?['nameAr'],
          'productBasePrice': offer['product']?['basePrice'],
          'productComparePrice': offer['product']?['comparePrice'],
          'vendorStoreName': offer['vendor']?['storeName'],
          'vendorStoreNameAr': offer['vendor']?['storeNameAr'],
        };
      }).toList();

      return HomeData(
        categories: categories,
        products: vendors,
        promotions: promotions,
        offers: offers,
        activeOrder: null,
      );
    } catch (e, stack) {
      debugPrint('Error loading dashboard data: $e');
      debugPrint('Stack trace: $stack');
      throw ApiErrorMapper.fromError(e);
    }
  }
}
