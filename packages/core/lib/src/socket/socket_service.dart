import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/connectivity_service.dart';
import '../providers/core_providers.dart';
import 'socket_events.dart';

class CoreSocketService with WidgetsBindingObserver {
  io.Socket? _socket;
  String? _connectedToken;
  final String _baseUrl = ((dotenv.isInitialized
              ? (dotenv.env['WS_URL'] ?? dotenv.env['SOCKET_URL'])
              : null)
          ?.replaceAll('/events', '') ??
      'https://ws.otlob-egy.online')
      .replaceAll(RegExp(r'/$'), '');
  
  final Future<bool> Function() isTokenExpired;
  final Future<void> Function() refreshToken;
  final IConnectivityService? connectivityService;
  StreamSubscription<bool>? _connectivitySub;
  
  // Stream Controllers for strictly typed events
  final Map<SocketEvent, StreamController<dynamic>> _controllers = {};
  final Map<String, StreamController<dynamic>> _rawControllers = {};
  final StreamController<void> _connectController = StreamController<void>.broadcast();

  Stream<void> get onConnect => _connectController.stream;
  bool get isConnected => _socket?.connected ?? false;
  
  DateTime? _lastRefreshTime;

  CoreSocketService({
    required this.isTokenExpired,
    required this.refreshToken,
    this.connectivityService,
  }) {
    // Initialize stream controllers for all supported backend events
    for (var event in SocketEvent.values) {
      _controllers[event] = StreamController<dynamic>.broadcast();
    }
    WidgetsBinding.instance.addObserver(this);

    final conn = connectivityService;
    if (conn != null) {
      _connectivitySub = conn.onConnectivityChanged.listen((isOnline) {
        if (isOnline) {
          debugPrint('🌐 Core Socket: Hardware internet reconnected -> Auto-reconnecting socket');
          connect();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App Resumed: Forcing socket reconnect if disconnected');
      connect();
    }
  }

  /// Get a strongly typed stream for a specific SocketEvent
  Stream<dynamic> onEvent(SocketEvent event) {
    return _controllers[event]!.stream;
  }

  /// Get a stream by raw event name (reuses typed controller if one matches).
  Stream<dynamic> onEventName(String eventName) {
    for (final ev in SocketEvent.values) {
      if (ev.eventName == eventName) {
        return _controllers[ev]!.stream;
      }
    }
    final existing = _rawControllers[eventName];
    if (existing != null) return existing.stream;
    final ctrl = StreamController<dynamic>.broadcast();
    _rawControllers[eventName] = ctrl;
    _socket?.on(eventName, (dynamic data) {
      if (!ctrl.isClosed) ctrl.add(data);
    });
    return ctrl.stream;
  }

  Future<void> init({String? forceToken, bool autoConnect = true}) async {
    // Check if token is expired or about to expire (5 min buffer)
    bool needsRefresh = await isTokenExpired();
    if (!needsRefresh) {
      final token = await appSecureStorage.read(key: 'access_token');
      if (token != null) {
        final remaining = JwtDecoder.getRemainingTime(token);
        if (remaining.inSeconds < 60) needsRefresh = true;
      }
    }

    if (needsRefresh) {
      debugPrint('🔄 Core Socket: Token expiring soon, attempting refresh...');
      try {
        await refreshToken();
        debugPrint('✅ Core Socket: Token refreshed successfully');
      } catch (e) {
        debugPrint('❌ Core Socket: Token refresh failed: $e');
      }
    }

    final token = forceToken ?? await appSecureStorage.read(key: 'access_token');
    
    if (token == null) return;

    // If already connected with the same token, don't re-init
    if (_socket != null && _socket!.connected && token == _connectedToken) {
      return;
    }

    _socket?.dispose(); // Clean up old socket if any
    _connectedToken = token;
    
    _socket = io.io(
      '$_baseUrl/events',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .disableAutoConnect()
          .build(),
    );

    if (autoConnect) {
      _socket?.connect();
    }

    // Forward backend events into the typed broadcast controllers. Registered
    // ONCE per socket instance: socket_io_client keeps listeners across
    // automatic reconnects, so re-registering inside onConnect (as before)
    // stacked a duplicate handler on every reconnect, doubling each event.
    for (var event in SocketEvent.values) {
      // Skip client-emitted events
      if (event == SocketEvent.driverLocationUpdate ||
          event == SocketEvent.driverTrack ||
          event == SocketEvent.driverUntrack) {
        continue;
      }

      _socket?.on(event.eventName, (data) {
        if (!_controllers[event]!.isClosed) {
          _controllers[event]!.add(data);
        }
      });
    }
    for (final entry in _rawControllers.entries) {
      _socket?.on(entry.key, (dynamic data) {
        if (!entry.value.isClosed) entry.value.add(data);
      });
    }

    _socket?.onConnect((_) {
      debugPrint('✅ Core Socket connected');
      if (!_connectController.isClosed) {
        _connectController.add(null);
      }
    });
    
    _socket?.onConnectError((err) async {
      debugPrint('❌ Core Socket Connect Error: $err');
      final errorStr = err.toString().toLowerCase();
      if (errorStr.contains('unauthorized') || errorStr.contains('expired') || errorStr.contains('auth')) {
        
        final now = DateTime.now();
        if (_lastRefreshTime != null && now.difference(_lastRefreshTime!).inSeconds < 10) {
          debugPrint('⚠️ Core Socket: Skipping token refresh to prevent infinite loop (Likely Role/Offline restriction).');
          return;
        }
        
        _lastRefreshTime = now;
        debugPrint('🔐 Core Socket: Auth error detected, refreshing token...');
        try {
          await refreshToken();
          await init(); // Retry initialization with new token (awaited: a
          // dropped future here would surface as an unhandled async error)
        } catch (e) {
          debugPrint('❌ Core Socket: Re-auth failed: $e');
        }
      }
    });

    _socket?.onDisconnect((_) => debugPrint('❌ Core Socket disconnected'));
  }

  /// Emit strongly typed events back to the server
  void emit(SocketEvent event, dynamic data) {
    _socket?.emit(event.eventName, data);
  }

  /// Emit raw string event back to the server
  void emitRaw(String eventName, dynamic data) {
    _socket?.emit(eventName, data);
  }

  void onRaw(String eventName, void Function(dynamic) callback) {
    _socket?.on(eventName, callback);
  }

  void offRaw(String eventName, [void Function(dynamic)? callback]) {
    _socket?.off(eventName, callback);
  }

  void connect() {
    if (_socket == null) {
      unawaited(init(autoConnect: true));
    } else if (!_socket!.connected) {
      _socket!.connect();
    }
  }

  void disconnect() {
    _connectedToken = null;
    _socket?.disconnect();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
    disconnect();
    _socket?.dispose();
    _socket = null;
    _connectController.close();
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    for (var controller in _rawControllers.values) {
      controller.close();
    }
    _rawControllers.clear();
  }
}
