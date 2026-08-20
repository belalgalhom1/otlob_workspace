import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class VendorProfileRepository {
  final VendorsCoreManagementApi _api;
  VendorProfileRepository(this._api);

  Future<dynamic> vendorProfileFind(String vendorId) async {
    final response = await _api.vendorsControllerFindOne(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> vendorProfileUpdate(String vendorId, dynamic dto) async {
    final response = await _api.vendorsControllerUpdate(vendorId: vendorId, updateVendorDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMyVendor(String vendorId) async {
    final response = await _api.vendorsControllerGetMyVendor(vendorId: vendorId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateStatus(String vendorId, String status) async {
    final response = await _api.vendorsControllerUpdateStatus(
      vendorId: vendorId,
      updateVendorStatusDto: UpdateVendorStatusDto((b) => b..status = UpdateVendorStatusDtoStatusEnum.valueOf(status.toUpperCase()))
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadCover(String vendorId, MultipartFile? file) async {
    final response = await _api.vendorsControllerUploadCover(vendorId: vendorId, file: file);
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadLogo(String vendorId, MultipartFile? file) async {
    final response = await _api.vendorsControllerUploadLogo(vendorId: vendorId, file: file);
    return ResponseParser.parse(response);
  }
}
