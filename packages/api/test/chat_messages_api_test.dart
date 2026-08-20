import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for ChatMessagesApi
void main() {
  final instance = Api().getChatMessagesApi();

  group(ChatMessagesApi, () {
    // Delete a message
    //
    //Future<AuthControllerRegister200Response> messagesControllerDelete(String conversationId, String messageId) async
    test('test messagesControllerDelete', () async {
      // TODO
    });

    // List messages in a conversation
    //
    //Future<AuthControllerRegister200Response> messagesControllerList(String conversationId, { String before, num limit }) async
    test('test messagesControllerList', () async {
      // TODO
    });

    // Mark messages as read
    //
    //Future<AuthControllerRegister200Response> messagesControllerMarkRead(String conversationId, MarkReadDto markReadDto) async
    test('test messagesControllerMarkRead', () async {
      // TODO
    });

    // Send a message in a conversation
    //
    //Future<AuthControllerRegister200Response> messagesControllerSend(String conversationId, SendMessageDto sendMessageDto) async
    test('test messagesControllerSend', () async {
      // TODO
    });

    // Update a message
    //
    //Future<AuthControllerRegister200Response> messagesControllerUpdate(String conversationId, String messageId) async
    test('test messagesControllerUpdate', () async {
      // TODO
    });

    // Upload a media file for chat
    //
    //Future<AuthControllerRegister200Response> messagesControllerUpload(String conversationId, { MultipartFile file }) async
    test('test messagesControllerUpload', () async {
      // TODO
    });

  });
}
