// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuralens_ai_photo_editor/main.dart';

void main() {
  testWidgets('App smoke test: primary UI elements render', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NeuraLensApp()));
    // Expect core call-to-action buttons from header section.
    expect(find.text('Select Photo'), findsOneWidget);
    expect(find.text('Use Sample'), findsOneWidget);
    // Section title
    expect(find.text('AI Tools'), findsOneWidget);
  });
}
