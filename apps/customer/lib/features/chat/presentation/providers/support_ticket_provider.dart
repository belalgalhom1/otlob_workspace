import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter/foundation.dart';

part 'support_ticket_provider.g.dart';

@riverpod
class SupportTicket extends _$SupportTicket {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String category,
    String? subCategory,
    String? description,
    String? orderId,
    String? vendorId,
    Map<String, dynamic>? metadata,
  }) async {
    final ticketsRepo = ref.read(sharedTicketsRepositoryProvider);
    
    try {
      final builder = CreateTicketDtoBuilder()
        ..subject = subject
        ..category = CreateTicketDtoCategoryEnum.valueOf(category.toUpperCase());
        
      if (subCategory != null) builder.subCategory = subCategory;
      if (description != null) builder.description = description;
      if (orderId != null) builder.orderId = orderId;
      if (vendorId != null) builder.vendorId = vendorId;
      if (metadata != null) builder.metadata = JsonObject(metadata);
        
      final response = await ticketsRepo.createTicket(builder.build());
      if (response is Map) {
        if (response.containsKey('data')) {
          return Map<String, dynamic>.from(response['data'] as Map);
        }
        return Map<String, dynamic>.from(response);
      }
      return {};
    } catch (e) {
      debugPrint('❌ SupportTicketProvider: Create error: $e');
      return {};
    }
  }

  Future<List<dynamic>> getTickets() async {
    final ticketsRepo = ref.read(sharedTicketsRepositoryProvider);
    try {
      final response = await ticketsRepo.getMyTickets();
      if (response is List) {
        return response;
      }
      if (response is Map) {
        if (response.containsKey('tickets') && response['tickets'] is List) {
          return response['tickets'];
        }
        if (response.containsKey('data') && response['data'] is List) {
          return response['data'];
        }
        if (response.containsKey('data') && response['data'] is Map && response['data']['tickets'] is List) {
          return response['data']['tickets'];
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ SupportTicketProvider: Get tickets error: $e');
      return [];
    }
  }
}
