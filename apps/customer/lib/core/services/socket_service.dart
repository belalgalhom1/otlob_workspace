import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:data/providers.dart';
import 'package:flutter/widgets.dart';

import 'token_service.dart';

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final service = SocketService(ref);
  ref.onDispose(service.disconnect);
  return service;
}

class SocketService with WidgetsBindingObserver {
  final Ref _ref;
  io.Socket? _socket;
  final Logger _logger = Logger();
  String? _connectedToken;
  bool _reAuthInProgress = false;

  // Typed broadcast streams — survive socket re-auth / re-creation.
  // Listeners attached here are never lost when initSocket creates a new socket
  // because the controller lives on the service, not on the socket instance.
  final Map<String, StreamController<dynamic>> _controllers =
      <String, StreamController<dynamic>>{};

  final StreamController<void> _connectController =
      StreamController<void>.broadcast();

  /// Fires on every (re)connect, including after token-rotation re-auth.
  Stream<void> get onConnect => _connectController.stream;

  StreamController<dynamic> _controllerFor(String event) =>
      _controllers.putIfAbsent(event, () => StreamController<dynamic>.broadcast());

  /// Subscribe to a socket event. The returned [StreamSubscription] can be
  /// cancelled without affecting any other consumer listening to the same event.
  Stream<dynamic> onEvent(String event) => _controllerFor(event).stream;

  void _forwardAllControllers() {
    for (final entry in _controllers.entries) {
      _socket?.on(entry.key, (dynamic data) => entry.value.add(data));
    }
  }

  SocketService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App Resumed: Ensuring socket connection');
      _ensureConnected();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      debugPrint('📱 App backgrounded: keeping socket alive');
      // Don't disconnect — keep the WebSocket open so background events
      // (payment status, order updates) keep flowing. The OS may kill it,
      // but resume will re-establish via _ensureConnected().
    }
  }

  /// Ensures the socket is connected with a valid token. Called on app resume
  /// and whenever a consumer needs a guaranteed connection. Re-authenticates
  /// if the token has expired so we never miss critical events (payments,
  /// order status) while backgrounded.
  Future<void> _ensureConnected() async {
    if (_socket != null && _socket!.connected && _connectedToken != null) {
      return;
    }

    final tokenService = _ref.read(tokenServiceProvider);
    final token = await tokenService.getAccessToken();
    if (token == null) {
      debugPrint('⚠️ Socket: No access token available, skipping connect');
      return;
    }

    // If token is expired, refresh first so the socket auth doesn't get
    // rejected by the server and we miss payment/order events.
    if (await tokenService.isAccessTokenExpired()) {
      try {
        final authRepo = _ref.read(sharedAuthRepositoryProvider);
        await authRepo.refreshToken();
      } catch (_) {}
    }

    final freshToken = await tokenService.getAccessToken();
    if (freshToken == null) {
      debugPrint('⚠️ Socket: No access token available after refresh, skipping connect');
      return;
    }
    await initSocket(freshToken);
  }

  /// Public entry point for consumers that need a guaranteed live socket
  /// (e.g. after coming back from background where payment events may have
  /// been missed).
  Future<void> ensureConnected() => _ensureConnected();

  Future<void> initSocket(String userToken) async {
    // Re-authing a different account (or a rotated token) must not reuse the
    // old socket: it stays bound to the previous user's session on the server.
    if (_socket != null && _socket!.connected && userToken == _connectedToken) {
      return;
    }

    _socket?.dispose(); // Clean up old socket
    _socket = null;
    _connectedToken = null;

    var baseUrl = dotenv.env['SOCKET_URL'] ?? 'https://ws.otlob-egy.online';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    debugPrint('📡 Attempting to connect to Socket: $baseUrl/events');

    _socket = io.io(
      '$baseUrl/events',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': userToken})
          // Keep the connection alive across drops/backgrounding: endless
          // retries with backoff, same as the driver app. Resume handler
          // reconnects immediately when the app returns to foreground.
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .build(),
    );

    _connectedToken = userToken;

    _socket?.connect();
    _socket?.onConnect((_) {
      _logger.i('✅ Socket connected');
      if (!_connectController.isClosed) _connectController.add(null);
      final preview = userToken.length > 20
          ? userToken.substring(0, 20)
          : userToken;
      debugPrint('👤 Connected with Token: $preview...');
    });

    _socket?.onConnectError((err) async {
      _logger.e('❌ Socket Connect Error: $err');
      final errorStr = err.toString().toLowerCase();
      if ((errorStr.contains('unauthorized') ||
              errorStr.contains('expired') ||
              errorStr.contains('auth')) &&
          !_reAuthInProgress) {
        _reAuthInProgress = true;
        _logger.w('🔐 Socket: Auth error detected, refreshing token...');
        try {
          final authRepo = _ref.read(sharedAuthRepositoryProvider);
          final newToken = await authRepo.refreshToken();
          await initSocket(newToken); // Retry with new token
        } catch (e) {
          _logger.e('❌ Socket: Re-auth failed: $e');
        } finally {
          _reAuthInProgress = false;
        }
      }
    });

    _socket?.onDisconnect((_) => _logger.w('❌ Socket disconnected'));

    // Wire every existing typed subscriber to the new socket.
    _forwardAllControllers();
  }

  // Legacy API kept for chat/notification consumers that have not yet migrated
  // to [onEvent]. New code should prefer [onEvent].
  void on(String eventName, Function(dynamic) callback) =>
      _socket?.on(eventName, callback);

  void emit(String eventName, dynamic data) =>
      _socket?.emit(eventName, data);

  void off(String eventName, [Function(dynamic)? callback]) => _socket?.off(eventName, callback);

  void connect() => _socket?.connect();

  void disconnect() {
    WidgetsBinding.instance.removeObserver(this);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}