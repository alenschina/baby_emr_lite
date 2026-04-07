// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_emr_lite/app.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: BabyEmrLiteApp()));

    // Let any async init settle a bit.
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Baseline sanity: app renders a Material root without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
