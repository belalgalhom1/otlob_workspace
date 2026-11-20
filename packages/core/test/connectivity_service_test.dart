import 'dart:async';
import 'package:core/src/network/connectivity_service.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:test/test.dart';

class _FakeInternetConnection extends InternetConnection {
  final _controller = StreamController<InternetStatus>.broadcast();
  bool _mockHasAccess = true;

  _FakeInternetConnection({bool initialAccess = true})
      : _mockHasAccess = initialAccess,
        super.createInstance(useDefaultOptions: false, customCheckOptions: [
          InternetCheckOption(uri: Uri.parse('https://example.com')),
        ]);

  @override
  Future<bool> get hasInternetAccess async => _mockHasAccess;

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  void emitStatus(InternetStatus status) {
    _mockHasAccess = status == InternetStatus.connected;
    _controller.add(status);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  group('ConnectivityService', () {
    late _FakeInternetConnection fakeChecker;
    late ConnectivityService service;

    setUp(() {
      fakeChecker = _FakeInternetConnection(initialAccess: true);
      service = ConnectivityService(fakeChecker);
    });

    tearDown(() async {
      service.dispose();
      await fakeChecker.dispose();
    });

    test('primes initial status and yields on subscribe', () async {
      fakeChecker.emitStatus(InternetStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.lastKnownStatus, isTrue);

      final statusEvents = <bool>[];
      final sub = service.onConnectivityChanged.listen(statusEvents.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(statusEvents, equals([true]));

      await sub.cancel();
    });

    test('emits updates on connectivity status changes', () async {
      final statusEvents = <bool>[];
      final sub = service.onConnectivityChanged.listen(statusEvents.add);

      fakeChecker.emitStatus(InternetStatus.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      fakeChecker.emitStatus(InternetStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(statusEvents.contains(false), isTrue);
      expect(statusEvents.last, isTrue);
      expect(service.lastKnownStatus, isTrue);

      await sub.cancel();
    });
  });
}
