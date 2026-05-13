import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarthealth/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
