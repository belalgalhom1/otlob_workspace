/// Strict enumeration of all supported Socket.IO events broadcasted by the Otlob backend
enum SocketEvent {
  /// Notifications
  notificationNew('notification.new'),
  
  /// Chat
  chatMessage('chat.message'),
  chatRead('chat.read'),
  conversationCreated('conversation.created'),
  conversationClosed('conversation.closed'),
  
  /// Orders
  orderNew('order.new'),
  orderStatus('order.status'),
  orderCancelled('order.cancelled'),
  
  /// Dispatch
  dispatchIncoming('dispatch.incoming'),
  dispatchCancelled('dispatch.cancelled'),

  /// Driver (Server to Client)
  driverLocation('driver.location'),

  /// Platform settings (Server to Client)
  platformSettingsUpdated('platform.settings.updated'),

  /// Driver (Client to Server)
  driverLocationUpdate('driver.location.update');

  final String eventName;
  const SocketEvent(this.eventName);

  /// Helper to get the enum from a raw string event name
  static SocketEvent? fromString(String name) {
    try {
      return SocketEvent.values.firstWhere((e) => e.eventName == name);
    } catch (_) {
      return null;
    }
  }
}
