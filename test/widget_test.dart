import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laststats_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const LastStatsApp(username: '', apiKey: ''),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
