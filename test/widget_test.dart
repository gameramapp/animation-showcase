// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:animation_showcase/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AnimationSamples());

    // The first catalog item is visible right away, the rest after scrolling.
    expect(find.text('Animation from config'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('AnimatedContainer'), 300);
    expect(find.text('AnimatedContainer'), findsOneWidget);
  });
}
