import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for DriverShiftsApi
void main() {
  final instance = Api().getDriverShiftsApi();

  group(DriverShiftsApi, () {
    // Claim someone else's shift from the swap board
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerAcceptSwap(String swapId) async
    test('test driverShiftsControllerAcceptSwap', () async {
      // TODO
    });

    // [Admin] Force-assign a driver to a shift pool
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerAdminAssignShift(AdminAssignShiftDto adminAssignShiftDto) async
    test('test driverShiftsControllerAdminAssignShift', () async {
      // TODO
    });

    // Book a single extra shift
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerBookOvertimeShift(BookOvertimeShiftDto bookOvertimeShiftDto) async
    test('test driverShiftsControllerBookOvertimeShift', () async {
      // TODO
    });

    // Book 6 shifts for the week
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerBookWeeklyShifts(BookWeeklyShiftsDto bookWeeklyShiftsDto) async
    test('test driverShiftsControllerBookWeeklyShifts', () async {
      // TODO
    });

    // [Admin] Delete a shift pool
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerDeleteShiftPool(String poolId) async
    test('test driverShiftsControllerDeleteShiftPool', () async {
      // TODO
    });

    // [Admin] Generate shift pools for a date range
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerGenerateShiftPools(GenerateShiftPoolsDto generateShiftPoolsDto) async
    test('test driverShiftsControllerGenerateShiftPools', () async {
      // TODO
    });

    // Get available shift pools for booking
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerGetAvailablePools(String zoneId) async
    test('test driverShiftsControllerGetAvailablePools', () async {
      // TODO
    });

    // [Admin] Get shift pools
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerGetShiftPools({ String date, String zoneId }) async
    test('test driverShiftsControllerGetShiftPools', () async {
      // TODO
    });

    // View available swaps from other drivers
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerGetSwapBoard() async
    test('test driverShiftsControllerGetSwapBoard', () async {
      // TODO
    });

    // Offer a shift to the swap board
    //
    //Future<AuthControllerRegister200Response> driverShiftsControllerOfferSwap(String shiftId) async
    test('test driverShiftsControllerOfferSwap', () async {
      // TODO
    });

  });
}
