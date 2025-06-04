import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:scan_n_save/stats/widgets/stats_summary.dart';

void main() {
  group('StatsSummary Widget Tests', () {
    testWidgets('Displays correct total and categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsSummary(totalExpense: 123, receiptCount: 5, displayMonth: 'lipiec', odmienParagon: (paragonId) {return 'ParagonID';})
        ),
      );

      expect(find.textContaining('123'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);
      expect(find.textContaining('lipiec'), findsOneWidget);
    });
  });
}
