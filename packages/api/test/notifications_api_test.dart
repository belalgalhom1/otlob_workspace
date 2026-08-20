import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for NotificationsApi
void main() {
  final instance = Api().getNotificationsApi();

  group(NotificationsApi, () {
    // Delete all read notifications
    //
    //Future<AuthControllerRegister200Response> notificationsControllerDeleteAllRead() async
    test('test notificationsControllerDeleteAllRead', () async {
      // TODO
    });

    // Delete a specific notification
    //
    //Future<NotificationsControllerList200Response> notificationsControllerDeleteOne(String id) async
    test('test notificationsControllerDeleteOne', () async {
      // TODO
    });

    // Dispatch an announcement to a topic
    //
    //Future<AuthControllerRegister200Response> notificationsControllerDispatchAnnouncement(DispatchAnnouncementDto dispatchAnnouncementDto) async
    test('test notificationsControllerDispatchAnnouncement', () async {
      // TODO
    });

    // Get a specific notification by ID
    //
    //Future<NotificationsControllerList200Response> notificationsControllerGetOne(String id) async
    test('test notificationsControllerGetOne', () async {
      // TODO
    });

    // List my notifications
    //
    //Future<NotificationsControllerList200Response> notificationsControllerList({ bool unreadOnly, String type, num page, num limit }) async
    test('test notificationsControllerList', () async {
      // TODO
    });

    // Mark a specific notification as read
    //
    //Future<NotificationsControllerList200Response> notificationsControllerMarkOneRead(String id) async
    test('test notificationsControllerMarkOneRead', () async {
      // TODO
    });

    // Mark multiple notifications as read
    //
    //Future<AuthControllerRegister200Response> notificationsControllerMarkRead(MarkNotificationsReadDto markNotificationsReadDto) async
    test('test notificationsControllerMarkRead', () async {
      // TODO
    });

    // Get unread notifications count
    //
    //Future<AuthControllerRegister200Response> notificationsControllerUnreadCount() async
    test('test notificationsControllerUnreadCount', () async {
      // TODO
    });

  });
}
