// Switching the language rebuilds every widget but keeps the current page and state.

import 'package:animation_showcase/main.dart';
import 'package:animation_showcase/src/basics/basics.dart';
import 'package:animation_showcase/src/common/i18n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('language switch keeps the current route', (tester) async {
    addTearDown(() => appLang.value = AppLang.en);
    await tester.pumpWidget(const AnimationSamples());
    router.go('/${ImplicitAnimationsDemo.routeName}');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ImplicitAnimationsDemo), findsOneWidget);

    final before = tester.element(find.byType(ImplicitAnimationsDemo).first);
    appLang.value = AppLang.ru;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Same element, not re-created.
    expect(
      identical(
        tester.element(find.byType(ImplicitAnimationsDemo).first),
        before,
      ),
      isTrue,
    );
    expect(find.byType(ImplicitAnimationsDemo), findsOneWidget);
    expect(tr('Duration', 'Длительность'), isNot('Duration'));

    router.go('/');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  test('es/fr/de: exact strings and interpolated templates are translated', () {
    addTearDown(() => appLang.value = AppLang.en);
    const ms = 500;
    for (final lang in [AppLang.es, AppLang.fr, AppLang.de]) {
      appLang.value = lang;
      expect(tr('Duration', 'Длительность'), isNot('Duration'), reason: lang.name);
      final speed = tr('Speed (cycle $ms ms)', 'Скорость (цикл $ms мс)');
      expect(speed, contains('500'), reason: lang.name);
      expect(speed, isNot('Speed (cycle 500 ms)'), reason: lang.name);
    }
    // Unknown text falls back to English and is recorded as missing.
    appLang.value = AppLang.de;
    debugMissingTranslations.clear();
    expect(tr('Totally new string', 'Совсем новая строка'), 'Totally new string');
    expect(debugMissingTranslations, contains('Totally new string'));
  });
}
