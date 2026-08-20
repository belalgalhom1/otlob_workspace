import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for LogisticsZonesApi
void main() {
  final instance = Api().getLogisticsZonesApi();

  group(LogisticsZonesApi, () {
    // Find zone by coordinates
    //
    //Future<AuthControllerRegister200Response> zonesControllerCheckLocation(CheckLocationDto checkLocationDto) async
    test('test zonesControllerCheckLocation', () async {
      // TODO
    });

    // Create a new delivery zone
    //
    //Future<AuthControllerRegister200Response> zonesControllerCreate(CreateZoneDto createZoneDto) async
    test('test zonesControllerCreate', () async {
      // TODO
    });

    // List all delivery zones
    //
    //Future<AuthControllerRegister200Response> zonesControllerFindAll() async
    test('test zonesControllerFindAll', () async {
      // TODO
    });

    // Get a specific zone by ID
    //
    //Future<AuthControllerRegister200Response> zonesControllerFindOne(String id) async
    test('test zonesControllerFindOne', () async {
      // TODO
    });

    // Delete a delivery zone
    //
    //Future<AuthControllerRegister200Response> zonesControllerRemove(String id) async
    test('test zonesControllerRemove', () async {
      // TODO
    });

    // Update a delivery zone
    //
    //Future<AuthControllerRegister200Response> zonesControllerUpdate(String id, UpdateZoneDto updateZoneDto) async
    test('test zonesControllerUpdate', () async {
      // TODO
    });

  });
}
