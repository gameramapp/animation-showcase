// Shared "spec" helpers for third-party package showcases: a package string
// with its version (as in pubspec), color in #RRGGBB, curve as Dart code, etc.
// Versions are from pubspec.lock; update them here when a package is bumped.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/animation_controls.dart';
import '../common/i18n.dart';

// Color for the spec — shared helper from motion_spec.dart.
export '../common/motion_spec.dart' show hexColor;

/// Package versions used by the screens under lib/src/packages/.
const packageVersions = <String, String>{
  'animated_text_kit': '4.3.0',
  'custom_refresh_indicator': '4.0.2',
  'flutter_bounceable': '1.2.0',
  'flutter_staggered_animations': '1.1.1',
  'flutter_tilt': '4.1.0',
  'like_button': '2.1.0',
  'lottie': '3.3.3',
  'matrix4_transform': '4.0.1',
  'rive': '0.14.11',
  'wolt_modal_sheet': '0.11.0',
  'zo_animated_border': '1.1.0',
};

/// Package string in pubspec format: `lottie: ^3.3.3`.
String packageSpec(String name) {
  final version = packageVersions[name];
  return version == null ? name : '$name: ^$version';
}

/// Rounding for JSON: 0.30000000004 → 0.3.
double round2(double v, [int digits = 2]) => double.parse(v.toStringAsFixed(digits));

/// Curve as Dart code for pasting into a package's `curve:` parameter.
/// Preset → `Curves.easeInOut`, bezier → `Cubic(…)`, spring → a description.
String curveCode(String curve) {
  if (animationCurves.containsKey(curve)) return 'Curves.$curve';
  final c = resolveCurve(curve);
  if (c is Cubic) {
    String f(double v) => round2(v, 3).toString();
    return 'Cubic(${f(c.a)}, ${f(c.b)}, ${f(c.c)}, ${f(c.d)})';
  }
  if (c is SpringCurve) {
    final note = tr('see motion_spec.dart', 'см. motion_spec.dart');
    return 'SpringCurve(stiffness: ${round2(c.stiffness)}, damping: ${round2(c.damping)}, '
        'mass: ${round2(c.mass)}) /* $note */';
  }
  return 'Curves.easeInOut';
}

/// Alignment → readable name (topLeft, center…) or `Alignment(x, y)`.
String alignmentName(AlignmentGeometry a) {
  final names = <Alignment, String>{
    Alignment.topLeft: 'topLeft',
    Alignment.topCenter: 'topCenter',
    Alignment.topRight: 'topRight',
    Alignment.centerLeft: 'centerLeft',
    Alignment.center: 'center',
    Alignment.centerRight: 'centerRight',
    Alignment.bottomLeft: 'bottomLeft',
    Alignment.bottomCenter: 'bottomCenter',
    Alignment.bottomRight: 'bottomRight',
  };
  if (a is Alignment) return names[a] ?? 'Alignment(${round2(a.x)}, ${round2(a.y)})';
  return a.toString();
}

/// A custom "clock" for a sandbox preview when a single pass is made up of
/// several durations (press + release, staircase, refresh cycle): loops time
/// 0…[periodMs] around with a pause of [pauseMs] and returns it in ms.
class LoopClock extends StatefulWidget {
  const LoopClock({super.key, required this.periodMs, required this.builder, this.pauseMs = 700});

  final int periodMs;
  final int pauseMs;
  final Widget Function(BuildContext context, double ms) builder;

  @override
  State<LoopClock> createState() => _LoopClockState();
}

class _LoopClockState extends State<LoopClock> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _total)..repeat();

  Duration get _total => Duration(milliseconds: math.max(1, widget.periodMs + widget.pauseMs));

  @override
  void didUpdateWidget(LoopClock old) {
    super.didUpdateWidget(old);
    if (old.periodMs != widget.periodMs || old.pauseMs != widget.pauseMs) {
      _c
        ..duration = _total
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(
      context,
      math.min(_c.value * _total.inMilliseconds, widget.periodMs.toDouble()),
    ),
  );
}

/// Fraction of [ms] within the segment [from, from + length] (0…1).
double phase(double ms, num from, num length) =>
    length <= 0 ? (ms >= from ? 1 : 0) : ((ms - from) / length).clamp(0.0, 1.0);
