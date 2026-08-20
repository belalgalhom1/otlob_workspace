import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerFavoritesRepository {
  final CustomersApi _api;
  CustomerFavoritesRepository(this._api);

  Future<dynamic> getFavorites() async {
    final response = await _api.customersControllerGetFavorites();
    return ResponseParser.parse(response);
  }

  Future<dynamic> toggleFavoriteProduct(String productId) async {
    final response = await _api.customersControllerToggleFavoriteProduct(productId: productId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> toggleFavoriteVendor(String vendorId) async {
    final response = await _api.customersControllerToggleFavoriteVendor(vendorId: vendorId);
    return ResponseParser.parse(response);
  }
}
