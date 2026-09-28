// Smoke test for the flutter_bounceable, like_button, flutter_tilt showcases:
// the screen opens at phone and desktop width, the auto-demo runs,
// scrolling to the end — no exceptions and no layout overflows.

import 'package:animation_showcase/src/packages/packages_interaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};
  final screens = <String, Widget Function()>{
    'BounceableDemo': () => const BounceableDemo(),
    'LikeButtonDemo': () => const LikeButtonDemo(),
    'TiltDemo': () => const TiltDemo(),
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

        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var i = 0; i < 10; i++) {
            await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
            for (var j = 0; j < 3; j++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}
