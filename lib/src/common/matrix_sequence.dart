// Animation through a sequence of matrices — runtime for the product.
//
// The designer sends text: one matrix per line, after "|" — optional
// duration of the transition INTO this matrix (ms) and a curve:
//
//   matrix(1, 0, 0, 1, 0, 0)
//   matrix(0.966, -0.259, 0.259, 0.966, 40, -20) | 500 | easeOutBack
//   matrix(1.15, 0, 0, 1.15, 0, -30) | 400 | easeInOutCubic
//   matrix(0.94, 0.342, -0.342, 0.94, -40, 10) | 600 | spring(300, 20, 1)
//
// A line can be matrix(…), matrix3d(…) or any CSS transform
// ("transform: rotate(-12deg) scale(1.2);" — like Figma → Copy as CSS).
// Empty lines and lines starting with `//` are skipped.
//
// In code:
//   final seq = MatrixSequence.parse(textFromDesigner);
//   controller.duration = seq.duration;  controller.repeat();
//   MatrixSequenceAnimator(sequence: seq, animation: controller, child: MyCard());
//
// Depends only on Flutter, motion_spec.dart and keyframe_spec.dart
// (parseCssTransform) — these three files can be moved into the product as is.

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'i18n.dart';
import 'keyframe_spec.dart' show parseCssTransform;
import 'motion_spec.dart';

/// One line: a matrix plus optional duration and curve of the transition into it.
class MatrixStep {
  const MatrixStep(this.raw, this.matrix, {this.durationMs, this.curve});
  final String raw;
  final Matrix4 matrix;
  final int? durationMs;
  final String? curve;
}

class MatrixSequence {
  MatrixSequence._(this.steps, this.duration, this.tween, this.marks);

  final List<MatrixStep> steps;

  /// Full duration of one pass (transitions + holds).
  final Duration duration;

  /// The ready-made tween sequence: tween.transform(t), t = 0…1.
  final TweenSequence<Matrix4> tween;

  /// The moment (0…1) when the element reaches each matrix.
  final List<double> marks;

  /// Parses the designer's text. Throws [FormatException] with a list of
  /// per-line errors if any line failed to parse.
  ///
  /// [defaultDurationMs] and [defaultCurve] — for lines without their own values,
  /// [holdMs] — hold time on each matrix, [linear] — element-wise
  /// interpolation instead of Matrix4Tween (for comparison only, not needed in the product).
  factory MatrixSequence.parse(
    String text, {
    int defaultDurationMs = 600,
    String defaultCurve = 'easeInOutCubic',
    int holdMs = 0,
    bool linear = false,
  }) {
    final (steps, errors) = parseLines(text);
    if (errors.isNotEmpty) {
      throw FormatException(errors.entries.map((e) => e.value).join('\n'));
    }
    return MatrixSequence.fromSteps(
      steps,
      defaultDurationMs: defaultDurationMs,
      defaultCurve: defaultCurve,
      holdMs: holdMs,
      linear: linear,
    );
  }

  /// Lenient parsing for editors: valid lines + errors by line number.
  static (List<MatrixStep>, Map<int, String>) parseLines(String text) {
    final steps = <MatrixStep>[];
    final errors = <int, String>{};
    for (final (i, line) in text.split('\n').indexed) {
      final s = line.trim();
      if (s.isEmpty || s.startsWith('//')) continue;
      final parts = s.split('|').map((p) => p.trim()).toList();
      final where = tr('line ${i + 1}', 'строка ${i + 1}');
      try {
        final matrix = parseCssTransform(parts[0], where: where);
        int? ms;
        String? curve;
        if (parts.length > 1 && parts[1].isNotEmpty) {
          // Accept a duration written with either the Latin "ms" or the
          // Cyrillic abbreviation for it — this only matches what the
          // designer typed, it isn't UI copy, so it doesn't go through
          // tr(). Built from code points (not a Cyrillic literal) so this
          // file stays free of bare Cyrillic strings outside tr().
          final cyrillicMs = String.fromCharCodes([0x043c, 0x0441]);
          ms = int.tryParse(parts[1].replaceAll('ms', '').replaceAll(cyrillicMs, '').trim());
          if (ms == null || ms <= 0) {
            throw FormatException(tr('$where: "${parts[1]}" is not a duration in ms', '$where: «${parts[1]}» — не длительность в мс'));
          }
        }
        if (parts.length > 2 && parts[2].isNotEmpty) {
          try {
            parseCurve(parts[2]);
          } on FormatException catch (e) {
            throw FormatException('$where: ${e.message}');
          }
          curve = parts[2];
        }
        steps.add(MatrixStep(parts[0], matrix, durationMs: ms, curve: curve));
      } on FormatException catch (e) {
        errors[i + 1] = e.message;
      }
    }
    return (steps, errors);
  }

  factory MatrixSequence.fromSteps(
    List<MatrixStep> steps, {
    int defaultDurationMs = 600,
    String defaultCurve = 'easeInOutCubic',
    int holdMs = 0,
    bool linear = false,
  }) {
    if (steps.length < 2) {
      throw FormatException(tr('at least two matrices are required', 'нужно минимум две матрицы'));
    }
    final items = <TweenSequenceItem<Matrix4>>[];
    final marks = <double>[0];
    var at = 0;
    void hold(Matrix4 m) {
      if (holdMs <= 0) return;
      items.add(TweenSequenceItem(tween: ConstantTween(m), weight: holdMs.toDouble()));
      at += holdMs;
    }

    hold(steps.first.matrix);
    for (var i = 1; i < steps.length; i++) {
      final a = steps[i - 1].matrix, b = steps[i].matrix;
      final ms = steps[i].durationMs ?? defaultDurationMs;
      final curve = resolveCurve(steps[i].curve ?? defaultCurve);
      final Tween<Matrix4> base = linear
          ? LinearMatrix4Tween(begin: a, end: b)
          : Matrix4Tween(begin: a, end: b);
      items.add(
        TweenSequenceItem(tween: base.chain(CurveTween(curve: curve)), weight: ms.toDouble()),
      );
      at += ms;
      marks.add(at.toDouble());
      hold(b);
    }
    return MatrixSequence._(
      steps,
      Duration(milliseconds: at),
      TweenSequence(items),
      [for (final m in marks) m / at],
    );
  }

  /// The matrix at moment [t] (0…1 of [duration]).
  Matrix4 transform(double t) => tween.transform(t);
}

/// Element-wise lerp of 16 numbers — a "naive" approach, for comparison only:
/// on rotations the element flattens along the way.
class LinearMatrix4Tween extends Tween<Matrix4> {
  LinearMatrix4Tween({required Matrix4 begin, required Matrix4 end})
    : super(begin: begin, end: end);

  @override
  Matrix4 lerp(double t) => Matrix4.fromList([
    for (var i = 0; i < 16; i++) lerpDouble(begin!.storage[i], end!.storage[i], t)!,
  ]);
}

/// Plays [sequence] on [child]. [animation] is usually an AnimationController
/// with duration = sequence.duration.
class MatrixSequenceAnimator extends StatelessWidget {
  const MatrixSequenceAnimator({
    super.key,
    required this.sequence,
    required this.animation,
    required this.child,
    this.alignment = Alignment.center,
    this.perspective = 0,
  });

  final MatrixSequence sequence;
  final Animation<double> animation;
  final Widget child;

  /// transform-origin.
  final Alignment alignment;

  /// Depth for 3D matrices in px (0 — no perspective).
  final double perspective;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final m = sequence.transform(animation.value);
        final p = Matrix4.identity();
        if (perspective > 0) p.setEntry(3, 2, 1 / perspective);
        return Transform(alignment: alignment, transform: p..multiply(m), child: child);
      },
    );
  }
}
