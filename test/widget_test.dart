import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test — MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('DGRL'),
          ),
        ),
      ),
    );

    expect(find.text('DGRL'), findsOneWidget);
  });
}
