import 'package:core/src/socket/order_revision.dart';
import 'package:test/test.dart';

void main() {
  group('OrderRevisionTracker', () {
    test('accepts the first event and records it', () {
      final tracker = OrderRevisionTracker();
      expect(tracker.accept('o1', 3), isTrue);
      expect(tracker.latest('o1'), 3);
    });

    test('drops an event older than the highest revision seen', () {
      final tracker = OrderRevisionTracker();
      expect(tracker.accept('o1', 5), isTrue);
      expect(tracker.accept('o1', 4), isFalse);
      expect(tracker.latest('o1'), 5);
    });

    test('accepts equal revisions (one transition, several events)', () {
      final tracker = OrderRevisionTracker();
      expect(tracker.accept('o1', 5), isTrue);
      expect(tracker.accept('o1', 5), isTrue);
    });

    test('accepts payloads without a revision (legacy / FCM)', () {
      final tracker = OrderRevisionTracker();
      expect(tracker.accept('o1', null), isTrue);
      expect(tracker.latest('o1'), isNull);
    });

    test('keeps orders independent', () {
      final tracker = OrderRevisionTracker();
      expect(tracker.accept('o1', 9), isTrue);
      expect(tracker.accept('o2', 1), isTrue);
    });

    test('a REST snapshot raises the floor for in-flight events', () {
      final tracker = OrderRevisionTracker();
      tracker.observe('o1', 7);
      expect(tracker.accept('o1', 6), isFalse);
      expect(tracker.accept('o1', 7), isTrue);
      expect(tracker.accept('o1', 8), isTrue);
    });

    test('observeOrder reads id and revision from a raw map', () {
      final tracker = OrderRevisionTracker();
      tracker.observeOrder({'id': 'o1', 'revision': 12});
      expect(tracker.latest('o1'), 12);
    });

    test('forget and clear drop remembered revisions', () {
      final tracker = OrderRevisionTracker();
      tracker.observe('o1', 4);
      tracker.observe('o2', 4);
      tracker.forget('o1');
      expect(tracker.latest('o1'), isNull);
      expect(tracker.latest('o2'), 4);
      tracker.clear();
      expect(tracker.latest('o2'), isNull);
    });
  });

  group('orderRevisionOf', () {
    test('reads int, double and numeric strings', () {
      expect(orderRevisionOf({'revision': 4}), 4);
      expect(orderRevisionOf({'revision': 4.0}), 4);
      expect(orderRevisionOf({'revision': '4'}), 4);
    });

    test('returns null for missing or invalid values', () {
      expect(orderRevisionOf(<String, dynamic>{}), isNull);
      expect(orderRevisionOf({'revision': 'abc'}), isNull);
      expect(orderRevisionOf(null), isNull);
      expect(orderRevisionOf('not a map'), isNull);
    });
  });
}
