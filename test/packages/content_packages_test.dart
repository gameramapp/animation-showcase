// Smoke test for third-party package screens (animated_text_kit,
// flutter_staggered_animations, matrix4_transform): each screen opens at
// phone and desktop width, animations run, the screen scrolls — no
// exceptions and no layout overflows.

import 'package:animation_showcase/src/packages/packages_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};
  final screens = <String, Widget Function()>{
    'AnimatedTextDemo': () => const AnimatedTextDemo(),
    'StaggeredListDemo': () => const StaggeredListDemo(),
    'Matrix4TransformDemo': () => const Matrix4TransformDemo(),
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
          for (var i = 0; i < 8; i++) {
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

  // Exercise the main knobs: text changes (with emoji), layout, effects
  // and presets — everything must restart without errors.
  group('Interaction', () {
    Future<void> pumpFor(WidgetTester tester, int ms) async {
      for (var t = 0; t < ms; t += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      final f = find.text(text);
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first, warnIfMissed: false);
      await tester.pump();
    }

    for (final MapEntry(key: label, value: size) in sizes.entries) {
      testWidgets('AnimatedTextDemo: custom text ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const MaterialApp(home: AnimatedTextDemo()));
        await tester.enterText(find.byType(TextField), 'Hi 👋 / A very long phrase to check line wrapping / Ok');
        // Longer than TextLiquidFill's full cycle (4s + pause) — checking the restart.
        await pumpFor(tester, 7000);
        await tapText(tester, 'Reset');
        await pumpFor(tester, 1500);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('StaggeredListDemo: grid and effects ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const MaterialApp(home: StaggeredListDemo()));
        await pumpFor(tester, 1000);
        for (final chip in ['Grid', 'Scale — grow', 'Flip — flip', 'From the left', 'List', 'From above']) {
          await tapText(tester, chip);
          await pumpFor(tester, 1200);
        }
        await pumpFor(tester, 4000); // auto-repeat
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('Matrix4TransformDemo: presets ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const MaterialApp(home: Matrix4TransformDemo()));
        await pumpFor(tester, 6000); // auto-demo
        for (final preset in ['Fly away', 'Flip', 'Skew', 'Swing from corner', 'flipVertically', 'Reset']) {
          await tapText(tester, preset);
          await pumpFor(tester, 900);
        }
        await tester.ensureVisible(find.byTooltip('bottom-right corner'));
        await tester.tap(find.byTooltip('bottom-right corner'), warnIfMissed: false);
        await tapText(tester, 'Card tilt');
        await pumpFor(tester, 900);
        await tester.dragUntilVisible(
          find.byTooltip('upRight'),
          find.byType(Scrollable).first,
          const Offset(0, -300),
        );
        await tester.tap(find.byTooltip('upRight'), warnIfMissed: false);
        await pumpFor(tester, 900);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });
}
