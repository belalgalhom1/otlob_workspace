import 'dart:async';
import 'package:core/core.dart' show CoreSocketService, coreSocketServiceProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final service = SocketService(ref);
  ref.onDispose(service.dispose);
  return service;
}

/// Thin adapter over [coreSocketServiceProvider] so orders, notifications,
/// live tracking, inbox counts, and chat all share a single Socket.IO
/// connection across the Customer App.
class SocketService {
  final Ref _ref;

  SocketService(this._ref);

  CoreSocketService get _core => _ref.read(coreSocketServiceProvider);

  Stream<void> get onConnect => _core.onConnect;

  bool get isConnected => _core.isConnected;

  Stream<dynamic> onEvent(String event) => _core.onEventName(event);

  Future<void> ensureConnected() async {
    _core.connect();
  }

  Future<void> initSocket(String userToken) =>
      _core.init(forceToken: userToken, autoConnect: true);

  void on(String eventName, void Function(dynamic) callback) =>
      _core.onRaw(eventName, callback);

  void emit(String eventName, dynamic data) => _core.emitRaw(eventName, data);

  void off(String eventName, [void Function(dynamic)? callback]) =>
      _core.offRaw(eventName, callback);

  void connect() => _core.connect();

  void disconnect() => _core.disconnect();

  void dispose() {}
}