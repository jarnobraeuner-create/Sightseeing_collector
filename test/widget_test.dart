import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic widget tree renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Sightseeing Collector'),
        ),
      ),
    );

    expect(find.text('Sightseeing Collector'), findsOneWidget);
  });
}
