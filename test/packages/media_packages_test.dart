// Smoke tests for the Lottie and Rive showcases: the screen opens on phone
// and desktop, scrolls and closes without exceptions or overflows.
// Under `flutter test`, Rive usually can't find the native rive_native
// library — in that case the screen should show a "Rive failed to load"
// placeholder instead of crashing.

import 'package:animation_showcase/src/packages/packages_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = [Size(390, 844), Size(1440, 900)];
  final screens = <String, Widget Function()>{
    'Lottie': () => const LottieDemo(),
    'Rive': () => const RiveDemo(),
  };

  for (final MapEntry(key: title, value: build) in screens.entries) {
    for (final size in sizes) {
      testWidgets('$title: ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        Future<void> letAssetsLoad() => tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(home: build()));
        });
        await letAssetsLoad();
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(title), findsWidgets);

        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
          await letAssetsLoad();
          for (var j = 0; j < 5; j++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
