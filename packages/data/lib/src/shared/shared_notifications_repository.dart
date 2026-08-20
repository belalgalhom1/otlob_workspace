import 'package:api/api.dart';
import 'response_parser.dart';

class SharedNotificationsRepository {
  final NotificationsApi _api;
  SharedNotificationsRepository(this._api);

  Future<dynamic> dispatchAnnouncement(DispatchAnnouncementDto dto) async {
    final response = await _api.notificationsControllerDispatchAnnouncement(
      dispatchAnnouncementDto: dto,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> list({int? page, int? limit, bool? unreadOnly}) async {
    final response = await _api.notificationsControllerList(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
    return ResponseParser.parseList(response);
  }

  Future<dynamic> getOne(String id) async {
    final response = await _api.notificationsControllerGetOne(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> markRead() async {
    final response = await _api.notificationsControllerMarkRead(
      markNotificationsReadDto: MarkNotificationsReadDto(),
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> markOneRead(String id) async {
    final response = await _api.notificationsControllerMarkOneRead(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> unreadCount() async {
    final response = await _api.notificationsControllerUnreadCount();
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteOne(String id) async {
    final response = await _api.notificationsControllerDeleteOne(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> deleteAllRead() async {
    final response = await _api.notificationsControllerDeleteAllRead();
    return ResponseParser.parse(response);
  }
}
