import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for PromotionsApi
void main() {
  final instance = Api().getPromotionsApi();

  group(PromotionsApi, () {
    //Future<AuthControllerRegister200Response> promotionsControllerCreate({ MultipartFile file }) async
    test('test promotionsControllerCreate', () async {
      // TODO
    });

    // Get all promotions (Admin)
    //
    //Future<AuthControllerRegister200Response> promotionsControllerFindAll() async
    test('test promotionsControllerFindAll', () async {
      // TODO
    });

    // Get all active promotions for customer app
    //
    //Future<AuthControllerRegister200Response> promotionsControllerFindAllActive() async
    test('test promotionsControllerFindAllActive', () async {
      // TODO
    });

    //Future<AuthControllerRegister200Response> promotionsControllerFindOne(String id) async
    test('test promotionsControllerFindOne', () async {
      // TODO
    });

    //Future<AuthControllerRegister200Response> promotionsControllerRemove(String id) async
    test('test promotionsControllerRemove', () async {
      // TODO
    });

    //Future<AuthControllerRegister200Response> promotionsControllerUpdate(String id, UpdatePromotionDto updatePromotionDto) async
    test('test promotionsControllerUpdate', () async {
      // TODO
    });

    //Future<AuthControllerRegister200Response> promotionsControllerUploadImage(String id, { MultipartFile file }) async
    test('test promotionsControllerUploadImage', () async {
      // TODO
    });

  });
}
