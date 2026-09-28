// "Specs" and the brief on third-party package screens: on phone and
// desktop we scroll the screen top to bottom, open EVERY "Spec" button (the
// JSON dialog must appear and close) and finally find the
// "What the designer needs" block.

import 'dart:math' as math;

import 'package:animation_showcase/src/common/brief_playground.dart';
import 'package:animation_showcase/src/common/motion_spec.dart';
import 'package:animation_showcase/src/packages/packages_content.dart';
import 'package:animation_showcase/src/packages/packages_interaction.dart';
import 'package:animation_showcase/src/packages/packages_media.dart';
import 'package:animation_showcase/src/packages/packages_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};
  final screens = <String, Widget Function()>{
    'BounceableDemo': () => const BounceableDemo(),
    'LikeButtonDemo': () => const LikeButtonDemo(),
    'TiltDemo': () => const TiltDemo(),
    'AnimatedTextDemo': () => const AnimatedTextDemo(),
    'StaggeredListDemo': () => const StaggeredListDemo(),
    'Matrix4TransformDemo': () => const Matrix4TransformDemo(),
    'LottieDemo': () => const LottieDemo(),
    'RiveDemo': () => const RiveDemo(),
    'RefreshIndicatorDemo': () => const RefreshIndicatorDemo(),
    'WoltSheetDemo': () => const WoltSheetDemo(),
    'AnimatedBorderDemo': () => const AnimatedBorderDemo(),
    'GenerativeAvatarsDemo': () => const GenerativeAvatarsDemo(),
  };

  Future<void> pumpFor(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Lottie/Rive load assets genuinely asynchronously.
  Future<void> letAssetsLoad(WidgetTester tester) =>
      tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final MapEntry(key: label, value: size) in sizes.entries) {
      testWidgets('$name: every Spec opens ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(home: build()));
        });
        await letAssetsLoad(tester);
        await pumpFor(tester, 1500);

        final scrollable = find.byType(Scrollable).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final opened = <String>{};

        for (var step = 0; step < 80; step++) {
          final titles = [
            for (final e in find.byType(SpecButton).evaluate()) (e.widget as SpecButton).title,
          ];
          for (final title in titles) {
            if (opened.contains(title)) continue;
            final button = find.byWidgetPredicate((w) => w is SpecButton && w.title == title);
            if (button.evaluate().isEmpty) continue;
            await tester.ensureVisible(button.first);
            await tester.pump(const Duration(milliseconds: 100));
            await tester.tap(find.descendant(of: button.first, matching: find.text('Spec')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.text('Spec: $title'), findsOneWidget, reason: title);
            await tester.tap(find.text('Close'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.text('Spec: $title'), findsNothing, reason: title);
            opened.add(title);
          }

          if (position.pixels >= position.maxScrollExtent - 1) break;
          // Scroll programmatically: a finger drag on phone would be "eaten" by
          // tiltable cards (flutter_tilt) and other gestures inside the blocks.
          position.jumpTo(math.min(position.pixels + 400, position.maxScrollExtent));
          await letAssetsLoad(tester);
          await pumpFor(tester, 300);
        }

        expect(opened, isNotEmpty);
        expect(find.text('What we need from the designer'), findsOneWidget);

        // Brief playground: a valid value in the first field → the preview
        // stays alive; garbage ('abc') → an error under the field, no crash.
        final fields = find.descendant(
          of: find.byType(BriefPlayground),
          matching: find.byType(TextField),
        );
        expect(fields, findsWidgets);
        TextField first() => tester.widget<TextField>(fields.first);
        await tester.ensureVisible(fields.first);
        await tester.pump();
        await tester.enterText(fields.first, _variation(first().controller!.text));
        await letAssetsLoad(tester);
        await pumpFor(tester, 1000);
        expect(first().decoration?.errorText, isNull, reason: 'valid value');
        await tester.enterText(fields.first, 'abc');
        await letAssetsLoad(tester);
        await pumpFor(tester, 2000);
        expect(first().decoration?.errorText, isNotNull, reason: 'abc must produce an error');

        // All variants of the playground's choice fields — each preview must build.
        final dropdowns = find.descendant(
          of: find.byType(BriefPlayground),
          matching: find.byType(DropdownButton<String>),
        );
        for (var d = 0; d < dropdowns.evaluate().length; d++) {
          final options = [
            for (final e in find
                .descendant(of: dropdowns.at(d), matching: find.byType(DropdownMenuItem<String>))
                .evaluate())
              (e.widget as DropdownMenuItem<String>).value!,
          ];
          for (final option in options) {
            await tester.ensureVisible(dropdowns.at(d));
            await tester.pump();
            await tester.tap(dropdowns.at(d));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            await tester.tap(find.text(option).last, warnIfMissed: false);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            await letAssetsLoad(tester);
            await pumpFor(tester, 600);
            expect(tester.widget<DropdownButton<String>>(dropdowns.at(d)).value, option);
          }
        }
        // ignore: avoid_print
        print('$name ($label): specs opened — ${opened.length}');

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }

  // The Wolt sheet opens and pages through with the new knobs (page-slide
  // curve, hero on scroll) — no exceptions.
  for (final MapEntry(key: label, value: size) in sizes.entries) {
    testWidgets('WoltSheetDemo: the flow opens and pages ($label)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: WoltSheetDemo()));
      await pumpFor(tester, 500);
      final open = find.text('Open sheet');
      await tester.ensureVisible(open);
      await tester.pump();
      await tester.tap(open);
      await pumpFor(tester, 800);
      expect(find.text('Step 1 of 3 · Pick a dish'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpFor(tester, 800);
      await tester.tap(find.text('Order'));
      await pumpFor(tester, 1200);
      expect(find.text('Order placed!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}

/// A "new" valid value for a playground field: a slightly smaller number
/// (within the same bounds), a different curve, or a different color.
String _variation(String current) {
  final n = double.tryParse(current.replaceAll(',', '.'));
  if (n != null) return n == 0 ? '1' : (n * 0.8).toStringAsFixed(2);
  if (current.startsWith('#')) return '#FF5722';
  return 'easeOutBack';
}
