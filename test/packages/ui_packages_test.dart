// Smoke test for UI package screens (refresh indicator, wolt modal sheet,
// animated border, generative avatars): each screen opens at phone and
// desktop width, animations run for a couple of seconds, the screen
// scrolls — no exceptions and no layout overflows.

import 'package:animation_showcase/src/packages/packages_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};
  final screens = <String, Widget Function()>{
    'RefreshIndicatorDemo': () => const RefreshIndicatorDemo(),
    'WoltSheetDemo': () => const WoltSheetDemo(),
    'AnimatedBorderDemo': () => const AnimatedBorderDemo(),
    'GenerativeAvatarsDemo': () => const GenerativeAvatarsDemo(),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final MapEntry(key: label, value: size) in sizes.entries) {
      testWidgets('$name ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(home: build()));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Scroll the screen so all blocks get built.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var i = 0; i < 10; i++) {
            await tester.drag(scrollables.first, const Offset(0, -600), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 200));
          }
        }

        // Leave the screen and let timers/controllers die off properly.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}
