import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for OffersApi
void main() {
  final instance = Api().getOffersApi();

  group(OffersApi, () {
    // Create new product offer
    //
    //Future<AuthControllerRegister200Response> offersControllerCreate(CreateOfferDto createOfferDto) async
    test('test offersControllerCreate', () async {
      // TODO
    });

    // Get all offers (Admin)
    //
    //Future<AuthControllerRegister200Response> offersControllerFindAll() async
    test('test offersControllerFindAll', () async {
      // TODO
    });

    // Get all active product offers
    //
    //Future<AuthControllerRegister200Response> offersControllerFindAllActive() async
    test('test offersControllerFindAllActive', () async {
      // TODO
    });

    // Delete product offer
    //
    //Future<AuthControllerRegister200Response> offersControllerRemove(String id) async
    test('test offersControllerRemove', () async {
      // TODO
    });

    // Update product offer
    //
    //Future<AuthControllerRegister200Response> offersControllerUpdate(String id, UpdateOfferDto updateOfferDto) async
    test('test offersControllerUpdate', () async {
      // TODO
    });

  });
}
