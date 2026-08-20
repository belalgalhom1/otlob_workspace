import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for CartApi
void main() {
  final instance = Api().getCartApi();

  group(CartApi, () {
    // Add item to cart
    //
    //Future<AuthControllerRegister200Response> cartControllerAddItem(String vendorId, AddCartItemDto addCartItemDto) async
    test('test cartControllerAddItem', () async {
      // TODO
    });

    // Clear entire cart for a vendor
    //
    //Future<AuthControllerRegister200Response> cartControllerClearCart(String vendorId) async
    test('test cartControllerClearCart', () async {
      // TODO
    });

    // Get cart for a specific vendor
    //
    //Future<AuthControllerRegister200Response> cartControllerGetCart(String vendorId) async
    test('test cartControllerGetCart', () async {
      // TODO
    });

    // Get all my carts (one per vendor)
    //
    //Future<AuthControllerRegister200Response> cartControllerGetMyCarts() async
    test('test cartControllerGetMyCarts', () async {
      // TODO
    });

    // Remove item from cart
    //
    //Future<AuthControllerRegister200Response> cartControllerRemoveItem(String vendorId, String itemId) async
    test('test cartControllerRemoveItem', () async {
      // TODO
    });

    // Update cart item (quantity / options)
    //
    //Future<AuthControllerRegister200Response> cartControllerUpdateItem(String vendorId, String itemId, UpdateCartItemDto updateCartItemDto) async
    test('test cartControllerUpdateItem', () async {
      // TODO
    });

  });
}
