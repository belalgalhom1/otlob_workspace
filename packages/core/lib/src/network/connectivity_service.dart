import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class IConnectivityService {
  Future<bool> get isConnected;
  bool? get lastKnownStatus;
  Stream<bool> get onConnectivityChanged;
  Stream<InternetStatus> get onStatusChange;
  void dispose();
}

class ConnectivityService implements IConnectivityService {
  final InternetConnection _checker;
  bool? _lastKnownStatus;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<InternetStatus>? _statusSub;

  ConnectivityService([InternetConnection? checker])
      : _checker = checker ?? InternetConnection() {
    _statusSub = _checker.onStatusChange.listen((status) {
      final isOnline = status == InternetStatus.connected;
      _lastKnownStatus = isOnline;
      if (!_controller.isClosed) {
        _controller.add(isOnline);
      }
    });

    // Run an initial quick reachability check so state is primed ASAP
    unawaited(_primeInitialStatus());
  }

  Future<void> _primeInitialStatus() async {
    try {
      final isOnline = await _checker.hasInternetAccess;
      if (_lastKnownStatus == null && !_controller.isClosed) {
        _lastKnownStatus = isOnline;
        _controller.add(isOnline);
      }
    } catch (e) {
      debugPrint('Initial connectivity prime failed: $e');
    }
  }

  @override
  bool? get lastKnownStatus => _lastKnownStatus;

  @override
  Future<bool> get isConnected async {
    try {
      return await _checker.hasInternetAccess;
    } catch (e) {
      debugPrint('ConnectivityService check failed: $e');
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    late final StreamController<bool> streamController;
    StreamSubscription<bool>? sub;

    streamController = StreamController<bool>(
      onListen: () {
        if (_lastKnownStatus != null) {
          streamController.add(_lastKnownStatus!);
        }
        sub = _controller.stream.listen(
          (event) {
            if (!streamController.isClosed) {
              streamController.add(event);
            }
          },
          onError: streamController.addError,
          onDone: streamController.close,
        );
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return streamController.stream;
  }

  @override
  Stream<InternetStatus> get onStatusChange => _checker.onStatusChange;

  @override
  void dispose() {
    _statusSub?.cancel();
    _statusSub = null;
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<IConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

final connectivityStatusStreamProvider = StreamProvider<InternetStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});
