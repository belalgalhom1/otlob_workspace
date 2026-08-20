import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for DriversApi
void main() {
  final instance = Api().getDriversApi();

  group(DriversApi, () {
    // [Admin] Create a shift for a driver
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerAdminCreateShift(String driverId, CreateDriverShiftDto createDriverShiftDto) async
    test('test driversControllerAdminCreateShift', () async {
      // TODO
    });

    // [Admin] List all drivers
    //
    //Future<DriversControllerRegister200Response> driversControllerAdminFindAll({ String status, String search, num page, num limit }) async
    test('test driversControllerAdminFindAll', () async {
      // TODO
    });

    // [Admin] Get a driver by ID
    //
    //Future<DriversControllerRegister200Response> driversControllerAdminFindOne(String driverId) async
    test('test driversControllerAdminFindOne', () async {
      // TODO
    });

    // [Admin] Get shifts for a driver
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerAdminGetShifts(String driverId) async
    test('test driversControllerAdminGetShifts', () async {
      // TODO
    });

    // [Admin] Suspend a driver
    //
    //Future<DriversControllerRegister200Response> driversControllerAdminSuspend(String driverId) async
    test('test driversControllerAdminSuspend', () async {
      // TODO
    });

    // [Admin] Unsuspend a driver
    //
    //Future<DriversControllerRegister200Response> driversControllerAdminUnsuspend(String driverId) async
    test('test driversControllerAdminUnsuspend', () async {
      // TODO
    });

    // Create a shift
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerCreateShift(CreateDriverShiftDto createDriverShiftDto) async
    test('test driversControllerCreateShift', () async {
      // TODO
    });

    // End a shift
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerEndShift(String shiftId) async
    test('test driversControllerEndShift', () async {
      // TODO
    });

    // Get my driver profile
    //
    //Future<DriversControllerRegister200Response> driversControllerGetMyProfile() async
    test('test driversControllerGetMyProfile', () async {
      // TODO
    });

    // Get my shifts
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerGetMyShifts() async
    test('test driversControllerGetMyShifts', () async {
      // TODO
    });

    // Get wallet balance
    //
    //Future<AuthControllerRegister200Response> driversControllerGetWalletBalance() async
    test('test driversControllerGetWalletBalance', () async {
      // TODO
    });

    // Get wallet transaction history
    //
    //Future<DriversControllerGetWalletTransactions200Response> driversControllerGetWalletTransactions({ num page, num limit }) async
    test('test driversControllerGetWalletTransactions', () async {
      // TODO
    });

    // Register as a driver (creates driver profile, upgrades role)
    //
    //Future<DriversControllerRegister200Response> driversControllerRegister(RegisterDriverDto registerDriverDto) async
    test('test driversControllerRegister', () async {
      // TODO
    });

    // Start a shift
    //
    //Future<DriversControllerGetMyShifts200Response> driversControllerStartShift(String shiftId) async
    test('test driversControllerStartShift', () async {
      // TODO
    });

    // Update my driver profile
    //
    //Future<DriversControllerRegister200Response> driversControllerUpdateProfile(UpdateDriverProfileDto updateDriverProfileDto) async
    test('test driversControllerUpdateProfile', () async {
      // TODO
    });

    // Update driver status (ONLINE / OFFLINE / ON_BREAK)
    //
    //Future<DriversControllerRegister200Response> driversControllerUpdateStatus(UpdateDriverStatusDto updateDriverStatusDto) async
    test('test driversControllerUpdateStatus', () async {
      // TODO
    });

    // Upload driver avatar
    //
    //Future<AuthControllerRegister200Response> driversControllerUploadAvatar({ MultipartFile file }) async
    test('test driversControllerUploadAvatar', () async {
      // TODO
    });

  });
}
