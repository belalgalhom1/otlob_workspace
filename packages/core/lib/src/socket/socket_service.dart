import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'socket_events.dart';

class CoreSocketService with WidgetsBindingObserver {
  io.Socket? _socket;
  final String _baseUrl = dotenv.env['WS_URL']?.replaceAll('/events', '') ?? 'https://ws.otlob-egy.online';
  
  final Future<bool> Function() isTokenExpired;
  final Future<void> Function() refreshToken;
  
  // Stream Controllers for strictly typed events
  final Map<SocketEvent, StreamController<dynamic>> _controllers = {};
  
  DateTime? _lastRefreshTime;

  CoreSocketService({required this.isTokenExpired, required this.refreshToken}) {
    // Initialize stream controllers for all supported backend events
    for (var event in SocketEvent.values) {
      _controllers[event] = StreamController<dynamic>.broadcast();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App Resumed: Forcing socket reconnect if disconnected');
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
      }
    }
  }

  /// Get a strongly typed stream for a specific SocketEvent
  Stream<dynamic> onEvent(SocketEvent event) {
    return _controllers[event]!.stream;
  }

  Future<void> init({String? forceToken, bool autoConnect = true}) async {
    // Check if token is expired or about to expire (5 min buffer)
    bool needsRefresh = await isTokenExpired();
    if (!needsRefresh) {
      final token = await const FlutterSecureStorage().read(key: 'access_token');
      if (token != null) {
        final remaining = JwtDecoder.getRemainingTime(token);
        if (remaining.inMinutes < 5) needsRefresh = true;
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

    const storage = FlutterSecureStorage();
    final token = forceToken ?? await storage.read(key: 'access_token');
    
    if (token == null) return;

    // If already connected with the same token, don't re-init
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket?.dispose(); // Clean up old socket if any
    
    _socket = io.io(
      '$_baseUrl/events',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    if (autoConnect) {
      _socket?.connect();
    }
    
    _socket?.onConnect((_) {
      debugPrint('✅ Core Socket connected');
      // Reattach listeners to stream controllers automatically
      for (var event in SocketEvent.values) {
        // Skip client-emitted events
        if (event == SocketEvent.driverLocationUpdate) continue;
        
        _socket?.on(event.eventName, (data) {
          if (!_controllers[event]!.isClosed) {
            _controllers[event]!.add(data);
          }
        });
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
          init(); // Retry initialization with new token
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

  void connect() => _socket?.connect();

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _socket?.dispose();
    _socket = null;
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
