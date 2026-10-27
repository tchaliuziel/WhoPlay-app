import 'package:flutter_test/flutter_test.dart';
import 'package:whoplay/data/mock_data.dart';

void main() {
  test('Compatibilidade do mockup soma 91%', () {
    final total = compatibilityBreakdown.fold<int>(0, (sum, e) => sum + e.$2);
    expect(total, nearbyPlayers.first.compatibility);
  });
}
