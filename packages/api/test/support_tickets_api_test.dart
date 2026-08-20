import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for SupportTicketsApi
void main() {
  final instance = Api().getSupportTicketsApi();

  group(SupportTicketsApi, () {
    // Create a new support ticket
    //
    //Future<AuthControllerRegister200Response> ticketsControllerCreate(CreateTicketDto createTicketDto) async
    test('test ticketsControllerCreate', () async {
      // TODO
    });

    // Get a specific support ticket by ID
    //
    //Future<AuthControllerRegister200Response> ticketsControllerGetOne(String id) async
    test('test ticketsControllerGetOne', () async {
      // TODO
    });

    // List support tickets with filters
    //
    //Future<AuthControllerRegister200Response> ticketsControllerList({ String status, String priority, String category, String assigneeId, String creatorId, num page, num limit }) async
    test('test ticketsControllerList', () async {
      // TODO
    });

    // Delete/Cancel a support ticket
    //
    //Future<AuthControllerRegister200Response> ticketsControllerRemove(String id) async
    test('test ticketsControllerRemove', () async {
      // TODO
    });

    // Update a support ticket
    //
    //Future<AuthControllerRegister200Response> ticketsControllerUpdate(String id, UpdateTicketDto updateTicketDto) async
    test('test ticketsControllerUpdate', () async {
      // TODO
    });

  });
}
