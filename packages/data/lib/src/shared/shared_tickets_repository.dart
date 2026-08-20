import 'package:api/api.dart';
import 'response_parser.dart';

class SharedTicketsRepository {
  final SupportTicketsApi _api;
  
  SharedTicketsRepository(this._api);

  Future<dynamic> getMyTickets() async {
    final response = await _api.ticketsControllerList();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> createTicket(dynamic dto) async {
    final response = await _api.ticketsControllerCreate(createTicketDto: dto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getTicket(String id) async {
    final response = await _api.ticketsControllerGetOne(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> ticketsList({int? page, int? limit, String? status}) async {
    final response = await _api.ticketsControllerList(
      page: page,
      limit: limit,
      status: status,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getTickets({int? page, int? limit, String? status}) async {
    return ticketsList(page: page, limit: limit, status: status);
  }

  Future<dynamic> ticketsRemove({required String id}) async {
    final response = await _api.ticketsControllerRemove(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> ticketsUpdate({
    required String id,
    required UpdateTicketDto updateTicketDto,
  }) async {
    final response = await _api.ticketsControllerUpdate(
      id: id,
      updateTicketDto: updateTicketDto,
    );
    return ResponseParser.parse(response);
  }
}
