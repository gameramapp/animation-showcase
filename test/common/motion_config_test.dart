// Parsing curves and keyframe configs — what comes in from designers.

import 'package:animation_showcase/src/common/keyframe_spec.dart';
import 'package:animation_showcase/src/common/matrix_sequence.dart';
import 'package:animation_showcase/src/common/motion_spec.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('curves', () {
    test('preset, cubic-bezier and spring', () {
      expect(parseCurve('easeOutBack'), Curves.easeOutBack);
      final cubic = parseCurve('cubic-bezier(0.2, 0, 0, 1)') as Cubic;
      expect([cubic.a, cubic.b, cubic.c, cubic.d], [0.2, 0, 0, 1]);
      final spring = parseCurve('spring(300, 20, 1)') as SpringCurve;
      expect(spring.transform(0), 0);
      expect(spring.transform(1), 1);
      expect(spring.settleDuration.inMilliseconds, greaterThan(0));
    });

    test('errors and CSS equivalent', () {
      expect(() => parseCurve('bouncy'), throwsFormatException);
      expect(() => parseCurve('cubic-bezier(1.5, 0, 0, 1)'), throwsFormatException);
      expect(resolveCurve('bouncy'), Curves.easeInOut);
      expect(curveToCss('easeInOut'), 'cubic-bezier(0.42, 0.0, 0.58, 1.0)');
      expect(curveToCss('elasticOut'), isNull);
      expect(curveToCss('spring(300, 20, 1)'), 'spring(300, 20, 1)');
    });
  });

  group('keyframes', () {
    KeyframeSpec spec(Map<String, dynamic> json) => KeyframeSpec.fromJson(json);

    test('properties are inherited and interpolated', () {
      final s = spec({
        'duration_ms': 1000,
        'perspective': 0,
        'keyframes': [
          {'at': 0, 'x': 0, 'opacity': 0},
          {'at_ms': 500, 'x': 100},
          {'frame': 60, 'opacity': 1},
        ],
      });
      final mid = s.evaluate(0.25);
      expect(mid.transform.getTranslation().x, closeTo(50, 0.01));
      expect(mid.opacity, 0);
      // Frame 3 didn't set x — so x stays 100.
      expect(s.evaluate(1).transform.getTranslation().x, closeTo(100, 0.01));
      expect(s.evaluate(1).opacity, 1);
    });

    test('CSS transform and matrices from Figma', () {
      final css = parseCssTransform('transform: translate(10px, 20px) rotate(90deg);');
      expect(css.getTranslation().x, closeTo(10, 1e-9));
      expect(css.getTranslation().y, closeTo(20, 1e-9));
      final s = spec({
        'perspective': 0,
        'keyframes': [
          {'at': 0, 'matrix': 'matrix(1, 0, 0, 1, 0, 0)'},
          {'at': 1, 'css': 'matrix(1, 0, 0, 1, 40, -20)'},
        ],
      });
      final end = s.evaluate(1).transform.getTranslation();
      expect(end.x, closeTo(40, 1e-9));
      expect(end.y, closeTo(-20, 1e-9));
      expect(s.evaluate(0.5).transform.getTranslation().x, closeTo(20, 1e-6));
    });

    test('readable errors', () {
      expect(() => spec({'keyframes': []}), throwsFormatException);
      expect(
        () => spec({
          'keyframes': [
            {'at': 0.5},
            {'at': 0.2},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => spec({
          'keyframes': [
            {'at': 0},
            {'at': 1, 'css': 'rotate(45)'},
          ],
        }),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('deg'))),
      );
    });
  });

  group('matrix sequence', () {
    const fromDesigner = '''
matrix(1, 0, 0, 1, 0, 0)
matrix(0.966, -0.259, 0.259, 0.966, 40, -20) | 500 | easeOutBack
matrix(1.15, 0, 0, 1.15, 0, -30) | 400 | easeInOutCubic
matrix(0.94, 0.342, -0.342, 0.94, -40, 10) | 600 | spring(300, 20, 1)
''';

    test('the designer text parses as is', () {
      final seq = MatrixSequence.parse(fromDesigner, holdMs: 300);
      expect(seq.steps, hasLength(4));
      expect(seq.steps[1].durationMs, 500);
      expect(seq.steps[3].curve, 'spring(300, 20, 1)');
      // 4 holds of 300 + transitions of 500 + 400 + 600.
      expect(seq.duration.inMilliseconds, 4 * 300 + 1500);
      // At the end — exactly the last matrix.
      final end = seq.transform(1).getTranslation();
      expect(end.x, closeTo(-40, 1e-6));
      expect(end.y, closeTo(10, 1e-6));
    });

    test('errors carry the line number', () {
      expect(
        () => MatrixSequence.parse('matrix(1, 0, 0, 1, 0, 0)\nmatrix(oops)'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('line 2'))),
      );
      expect(() => MatrixSequence.parse('matrix(1, 0, 0, 1, 0, 0)'), throwsFormatException);
    });
  });
}
