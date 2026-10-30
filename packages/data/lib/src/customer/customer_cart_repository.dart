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

  Future<dynamic> addItem(
    String vendorId, {
    String? productId,
    int quantity = 1,
    String? selectedUnit,
    String? variantId,
    List<String>? optionIds,
    String? specialRequest,
    String? offerMessageId,
  }) async {
    final builder = AddCartItemDtoBuilder()..quantity = quantity;
    if (productId != null) builder.productId = productId;
    if (selectedUnit != null) builder.selectedUnit = AddCartItemDtoSelectedUnitEnum.valueOf(selectedUnit);
    if (variantId != null) builder.variantId = variantId;
    if (optionIds != null && optionIds.isNotEmpty) {
      builder.optionIds.replace(optionIds);
    }
    if (specialRequest != null) builder.specialRequest = specialRequest;
    if (offerMessageId != null) builder.offerMessageId = offerMessageId;
    final response = await _api.cartControllerAddItem(
      vendorId: vendorId,
      addCartItemDto: builder.build(),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateItem(
    String vendorId,
    String itemId, {
    required int quantity,
    List<String>? optionIds,
    String? specialRequest,
  }) async {
    final builder = UpdateCartItemDtoBuilder()..quantity = quantity;
    if (optionIds != null) builder.optionIds.replace(optionIds);
    // NOTE: generated UpdateCartItemDto predates backend `selectedUnit`;
    // unit changes ride with the next packages/api regen.
    if (specialRequest != null) builder.specialRequest = specialRequest;
    final response = await _api.cartControllerUpdateItem(
      vendorId: vendorId,
      itemId: itemId,
      updateCartItemDto: builder.build(),
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
