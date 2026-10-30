import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('Driver Statistics & Calculations', () {
    test('calculates acceptance rate correctly', () {
      int calculateAcceptance(dynamic row) {
        final received = StatisticsFormat.intOf(row['totalDispatchesReceived']);
        final accepted = StatisticsFormat.intOf(row['dispatchesAccepted']);
        return received > 0 ? (accepted * 100 / received).round() : 0;
      }

      expect(calculateAcceptance({'totalDispatchesReceived': 10, 'dispatchesAccepted': 8}), 80);
      expect(calculateAcceptance({'totalDispatchesReceived': 0, 'dispatchesAccepted': 0}), 0);
      expect(calculateAcceptance({'totalDispatchesReceived': 3, 'dispatchesAccepted': 1}), 33);
    });

    test('formats delivery fee and driver earnings correctly', () {
      final row = {
        'totalEarnings': 807.0,
        'deliveryFee': 1008.75,
        'onlineHours': 7.7,
      };

      final earnings = StatisticsFormat.numOf(row['totalEarnings']);
      final deliveryFee = StatisticsFormat.numOf(row['deliveryFee']);
      final onlineHours = StatisticsFormat.numOf(row['onlineHours']);

      expect(earnings, 807.0);
      expect(deliveryFee, 1008.75);
      expect(onlineHours, 7.7);
    });
  });
}
