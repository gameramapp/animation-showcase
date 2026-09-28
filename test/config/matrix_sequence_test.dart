// The "Matrix Sequence" screen: input errors in the editor and sandbox don't
// crash the screen, presets switch correctly, the brief with the sandbox is in place.


import 'package:animation_showcase/src/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('matrix sequence $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: MatrixSequenceDemo()));
      await tester.pump(const Duration(seconds: 1));
      final editor = find.byType(TextField).first;
      await tester.enterText(editor, 'matrix(1, 0, 0, 1, 0, 0)\nmatrix(oops)\nrotate(45deg) | 300 | easeOutBack');
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Error'), findsWidgets);
      for (final chip in ['3D: matrix3d', 'Skew (compare methods)', 'Rotate 0 → 180°']) {
        final f = find.text(chip).first;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pump(const Duration(milliseconds: 800));
      }
      await tester.scrollUntilVisible(find.text('What we need from the designer'), 400, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(seconds: 1));
      final pg = find.widgetWithText(TextField, 'Matrix 2');
      await tester.ensureVisible(pg);
      await tester.enterText(pg, 'matrix(bad)');
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining("Couldn't parse matrix 2"), findsOneWidget);
      await tester.enterText(pg, 'transform: rotate(30deg) scale(1.2);');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
