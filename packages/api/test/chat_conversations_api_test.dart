import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for ChatConversationsApi
void main() {
  final instance = Api().getChatConversationsApi();

  group(ChatConversationsApi, () {
    // Close a conversation
    //
    //Future<AuthControllerRegister200Response> conversationsControllerClose(String id) async
    test('test conversationsControllerClose', () async {
      // TODO
    });

    // Create or get a direct conversation with a user
    //
    //Future<AuthControllerRegister200Response> conversationsControllerCreateDirect(CreateDirectConversationDto createDirectConversationDto) async
    test('test conversationsControllerCreateDirect', () async {
      // TODO
    });

    // Create a new conversation for an order
    //
    //Future<AuthControllerRegister200Response> conversationsControllerCreateOrder(CreateOrderConversationDto createOrderConversationDto) async
    test('test conversationsControllerCreateOrder', () async {
      // TODO
    });

    // Create a new support conversation
    //
    //Future<AuthControllerRegister200Response> conversationsControllerCreateSupport(CreateSupportConversationDto createSupportConversationDto) async
    test('test conversationsControllerCreateSupport', () async {
      // TODO
    });

    // Create a new vendor conversation
    //
    //Future<AuthControllerRegister200Response> conversationsControllerCreateVendor(CreateVendorConversationDto createVendorConversationDto) async
    test('test conversationsControllerCreateVendor', () async {
      // TODO
    });

    // Get a specific conversation by ID
    //
    //Future<AuthControllerRegister200Response> conversationsControllerGetOne(String id) async
    test('test conversationsControllerGetOne', () async {
      // TODO
    });

    // List my conversations
    //
    //Future<AuthControllerRegister200Response> conversationsControllerListMine({ num page, num limit }) async
    test('test conversationsControllerListMine', () async {
      // TODO
    });

  });
}
