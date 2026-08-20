import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerCartRepository {
  final CartApi _api;
  CustomerCartRepository(this._api);

  Future<dynamic> getCart(String vendorId) async {
    final response = await _api.cartControllerGetCart(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMyCarts() async {
    final response = await _api.cartControllerGetMyCarts();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> addItem(String vendorId, AddCartItemDto addCartItemDto) async {
    final response = await _api.cartControllerAddItem(
      vendorId: vendorId,
      addCartItemDto: addCartItemDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateItem(String vendorId, String itemId, UpdateCartItemDto updateCartItemDto) async {
    final response = await _api.cartControllerUpdateItem(
      vendorId: vendorId,
      itemId: itemId,
      updateCartItemDto: updateCartItemDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> removeItem(String vendorId, String itemId) async {
    final response = await _api.cartControllerRemoveItem(vendorId: vendorId, itemId: itemId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> clearCart(String vendorId) async {
    final response = await _api.cartControllerClearCart(vendorId: vendorId);
    return ResponseParser.parse(response);
  }
}
