// Smoke test of the whole catalog. Every screen, at phone and desktop width:
//   1. opens in English, scrolls through — no exceptions, no layout overflows
//      (an overflow fails the test on its own), no Cyrillic text on screen;
//   2. switches through Russian, German, French and Spanish at runtime,
//      scrolling each time — survives every switch and every text shown has
//      a translation. Layout overflows are only enforced for EN and RU: the
//      extra languages are best-effort and may run long (German especially);
//      in release builds an overflow is just clipped.
//   3. switches back to English — still no Cyrillic (catches strings that got
//      stuck in state in another language).

import 'package:animation_showcase/main.dart';
import 'package:animation_showcase/src/common/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _cyrillic = RegExp(r'[\u0400-\u04FF]');

String _plain(String? data, InlineSpan? span) => data ?? span?.toPlainText() ?? '';

/// Visible texts (Text / SelectableText) that contain Cyrillic.
List<String> _cyrillicTexts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    if (_cyrillic.hasMatch(_plain(t.data, t.textSpan))) _plain(t.data, t.textSpan),
  for (final t in tester.widgetList<SelectableText>(find.byType(SelectableText)))
    if (_cyrillic.hasMatch(_plain(t.data, t.textSpan))) _plain(t.data, t.textSpan),
];

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var ms = 0; ms < total.inMilliseconds; ms += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _scroll(WidgetTester tester, double dy) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollables.first, Offset(0, dy), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};

  for (final category in categories()) {
    for (final demo in category.demos) {
      for (final MapEntry(key: label, value: size) in sizes.entries) {
        testWidgets('${demo.route} ($label)', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          addTearDown(() => appLang.value = AppLang.en);

          appLang.value = AppLang.en;
          await tester.pumpWidget(const AnimationSamples());
          router.go('/${demo.route}');
          await _pumpFor(tester, const Duration(seconds: 3));
          expect(_cyrillicTexts(tester), isEmpty, reason: 'EN on open');

          await _scroll(tester, -600);
          expect(_cyrillicTexts(tester), isEmpty, reason: 'EN after scrolling');

          debugMissingTranslations.clear();
          var dy = 600.0;
          for (final lang in [AppLang.ru, AppLang.de, AppLang.fr, AppLang.es]) {
            appLang.value = lang;
            final report = FlutterError.onError;
            if (lang != AppLang.ru) {
              FlutterError.onError = (details) {
                if (details.exceptionAsString().contains('overflowed')) return;
                report?.call(details);
              };
            }
            try {
              await _pumpFor(tester, const Duration(seconds: 1));
              await _scroll(tester, dy);
            } finally {
              FlutterError.onError = report;
            }
            dy = -dy;
          }
          expect(
            debugMissingTranslations,
            isEmpty,
            reason: 'strings without es/fr/de translation — run tool/i18n_extract.py coverage',
          );

          appLang.value = AppLang.en;
          await _pumpFor(tester, const Duration(seconds: 1));
          expect(_cyrillicTexts(tester), isEmpty, reason: 'EN after RU -> EN');

          // Leave the screen and let timers/controllers shut down cleanly.
          router.go('/');
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }
  }
}
