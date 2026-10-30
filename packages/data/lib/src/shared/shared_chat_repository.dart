import 'package:api/api.dart';
import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';
import 'response_parser.dart';

class SharedChatRepository {
  final ChatConversationsApi _conversationsApi;
  final ChatMessagesApi _messagesApi;
  final Dio _dio;
  SharedChatRepository(this._conversationsApi, this._messagesApi, this._dio);

  Future<dynamic> getConversations({
    num? page = 1,
    num? limit = 20,
    String? type,
  }) async {
    final response = await _conversationsApi.conversationsControllerListMine(
      page: page,
      limit: limit,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createDirectConversation(String userId) async {
    final response = await _conversationsApi
        .conversationsControllerCreateDirect(
          createDirectConversationDto: CreateDirectConversationDto(
            (b) => b..userId = userId,
          ),
        );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMessages(
    String conversationId, {
    num? page = 1,
    num? limit = 50,
    String? before,
  }) async {
    final response = await _messagesApi.messagesControllerList(
      conversationId: conversationId,
      limit: limit,
      before: before,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> sendMessage(
    String conversationId,
    String text, {
    Map<String, dynamic>? metadata,
    String type = 'text',
    String? replyToId,
    String? mediaUrl,
  }) async {
    final response = await _messagesApi.messagesControllerSend(
      conversationId: conversationId,
      sendMessageDto: SendMessageDto((b) {
        b.text = text.trim().isEmpty ? null : text;
        b.type = SendMessageDtoTypeEnum.valueOf(type.toUpperCase());
        if (metadata != null) {
          b.metadata = JsonObject(metadata);
        }
        if (replyToId != null) {
          b.replyToId = replyToId;
        }
        if (mediaUrl != null) {
          b.mediaUrl = mediaUrl;
        }
      }),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> markAsRead(
    String conversationId, [
    List<String> messageIds = const [],
  ]) async {
    final response = await _messagesApi.messagesControllerMarkRead(
      conversationId: conversationId,
      markReadDto: MarkReadDto((b) {
        if (messageIds.isNotEmpty) {
          b.lastReadMessageId = messageIds.last;
        }
      }),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> uploadMedia(String conversationId, String filePath) async {
    final file = await MultipartFile.fromFile(filePath);
    final response = await _messagesApi.messagesControllerUpload(
      conversationId: conversationId,
      file: file,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> updateMessage(
    String conversationId,
    String messageId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/chat/conversations/$conversationId/messages/$messageId',
      data: data,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteMessage(String conversationId, String messageId) async {
    final response = await _messagesApi.messagesControllerDelete(
      conversationId: JsonObject(conversationId),
      messageId: messageId,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> closeConversation(String id) async {
    final response = await _conversationsApi.conversationsControllerClose(
      id: id,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createOrderConversation(String orderId) async {
    final response = await _conversationsApi.conversationsControllerCreateOrder(
      createOrderConversationDto: CreateOrderConversationDto(
        (b) => b..orderId = orderId,
      ),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createSupportConversation() async {
    final response = await _conversationsApi
        .conversationsControllerCreateSupport(
          createSupportConversationDto: CreateSupportConversationDto(),
        );
    return ResponseParser.parse(response);
  }

  Future<dynamic> createVendorConversation(String vendorId) async {
    final response = await _conversationsApi
        .conversationsControllerCreateVendor(
          createVendorConversationDto: CreateVendorConversationDto(
            (b) => b..vendorId = vendorId,
          ),
        );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getConversation(String id) async {
    final response = await _conversationsApi.conversationsControllerGetOne(
      id: id,
    );
    return ResponseParser.parse(response);
  }
}
