import 'package:api/api.dart';
import '../shared/response_parser.dart';

class CustomerAddressesRepository {
  final CustomersApi _api;
  CustomerAddressesRepository(this._api);

  Future<dynamic> getAddresses() async {
    final response = await _api.customersControllerGetAddresses();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> createAddress(CreateAddressDto createAddressDto) async {
    final response = await _api.customersControllerCreateAddress(
      createAddressDto: createAddressDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateAddress(String id, UpdateAddressDto updateAddressDto) async {
    final response = await _api.customersControllerUpdateAddress(
      id: id,
      updateAddressDto: updateAddressDto
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteAddress(String id) async {
    final response = await _api.customersControllerDeleteAddress(id: id);
    return ResponseParser.parse(response);
  }
}
