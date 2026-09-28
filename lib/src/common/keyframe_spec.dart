// Animation from a config: the designer describes keyframes in JSON, the app
// plays them back exactly. This file is self-contained — it can be taken into
// the product as is (depends only on Flutter and motion_spec.dart).
//
// Format (all fields except keyframes are optional):
// {
//   "name": "Card appearance",
//   "duration_ms": 1200,
//   "repeat": "loop" | "ping-pong" | "once",
//   "curve": "easeInOut",            // default curve for all segments
//   "origin": [0.5, 0.5],            // pivot point (fraction of width/height)
//   "perspective": 800,              // depth for rotate_x / rotate_y, px
//   "fps": 60,                       // if frame time is given as "frame"
//   "keyframes": [
//     { "at": 0, "opacity": 0, "y": 40, "scale": 0.8 },
//     { "at": 0.6, "y": -6, "scale": 1.04, "curve": "cubic-bezier(0.2, 0, 0, 1)" },
//     { "at": 1, "y": 0, "scale": 1, "curve": "spring(300, 20, 1)" }
//   ]
// }
//
// Frame time: "at" (0…1), "at_ms" (ms from start) or "frame" (+ "fps").
// Frame properties: opacity, x, y (px), scale (a number or [sx, sy]), rotate,
// rotate_x, rotate_y (degrees), skew ([x, y] in degrees). An unspecified
// property is taken from the previous frame.
// Instead of properties, a transform can be given whole:
//   "css": "translate(10px, 0) rotate(15deg) scale(1.2)"  — like Figma → Copy as CSS
//   "matrix": "matrix(a, b, c, d, tx, ty)" | "matrix3d(16 numbers)" | [6 or 16 numbers]
// A frame's "curve" is the curve the animation uses to ARRIVE at this frame.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'i18n.dart';
import 'motion_spec.dart';

enum KeyframeRepeat { once, loop, pingPong }

/// A parsed animation from JSON.
class KeyframeSpec {
  KeyframeSpec({
    required this.name,
    required this.duration,
    required this.repeat,
    required this.curve,
    required this.origin,
    required this.perspective,
    required this.keyframes,
  });

  final String name;
  final Duration duration;
  final KeyframeRepeat repeat;
  final String curve;
  final Alignment origin;
  final double perspective;
  final List<Keyframe> keyframes;

  /// Parses JSON. Throws [FormatException] with a clear message.
  factory KeyframeSpec.fromJson(Map<String, dynamic> json) {
    final durationMs = _num(json['duration_ms'] ?? 1000, 'duration_ms');
    if (durationMs <= 0) {
      throw FormatException(tr('duration_ms must be greater than 0', 'duration_ms должен быть больше 0'));
    }
    final fps = _num(json['fps'] ?? 60, 'fps');
    final repeat = switch (json['repeat'] ?? 'loop') {
      'loop' => KeyframeRepeat.loop,
      'ping-pong' || 'pingpong' || 'ping_pong' => KeyframeRepeat.pingPong,
      'once' => KeyframeRepeat.once,
      final other => throw FormatException(
        tr(
          'repeat: "$other" — expected loop, ping-pong or once',
          'repeat: «$other» — ожидается loop, ping-pong или once',
        ),
      ),
    };
    final curve = (json['curve'] ?? 'linear').toString();
    parseCurve(curve);
    final origin = _pair(json['origin'] ?? [0.5, 0.5], 'origin');

    final raw = json['keyframes'];
    if (raw is! List || raw.length < 2) {
      throw FormatException(
        tr('keyframes — a list of at least two frames', 'keyframes — список минимум из двух кадров'),
      );
    }
    final frames = <Keyframe>[];
    _Props previous = const _Props();
    for (final (i, item) in raw.indexed) {
      if (item is! Map) {
        throw FormatException(tr('keyframes[$i] must be an object {…}', 'keyframes[$i] должен быть объектом {…}'));
      }
      final kf = Keyframe._parse(
        item.cast<String, dynamic>(),
        index: i,
        durationMs: durationMs.toDouble(),
        fps: fps.toDouble(),
        previous: previous,
      );
      previous = kf._props;
      frames.add(kf);
    }
    for (var i = 1; i < frames.length; i++) {
      if (frames[i].at < frames[i - 1].at) {
        throw FormatException(
          tr(
            'keyframes[$i]: frame time is earlier than the previous one',
            'keyframes[$i]: время кадра меньше, чем у предыдущего',
          ),
        );
      }
    }
    return KeyframeSpec(
      name: (json['name'] ?? tr('Untitled', 'Без названия')).toString(),
      duration: Duration(milliseconds: durationMs.round()),
      repeat: repeat,
      curve: curve,
      origin: Alignment(origin.$1 * 2 - 1, origin.$2 * 2 - 1),
      perspective: _num(json['perspective'] ?? 800, 'perspective').toDouble(),
      keyframes: frames,
    );
  }

  /// The animation state at moment [t] (0…1 of duration).
  KeyframeFrame evaluate(double t) {
    final first = keyframes.first, last = keyframes.last;
    if (t <= first.at) return _withPerspective(first.matrix, first._props.opacity);
    if (t >= last.at) return _withPerspective(last.matrix, last._props.opacity);
    var i = 0;
    while (keyframes[i + 1].at < t) {
      i++;
    }
    final a = keyframes[i], b = keyframes[i + 1];
    final span = b.at - a.at;
    final local = span <= 0 ? 1.0 : (t - a.at) / span;
    final e = resolveCurve(b.curve ?? curve).transform(local);
    final opacity = lerpDouble(a._props.opacity, b._props.opacity, e)!;
    if (a._explicit == null && b._explicit == null) {
      return _withPerspective(_Props.lerp(a._props, b._props, e).toMatrix(), opacity);
    }
    // We interpolate matrices via decomposition (translate / rotate / scale),
    // the way browsers do for CSS transform.
    return _withPerspective(Matrix4Tween(begin: a.matrix, end: b.matrix).lerp(e), opacity);
  }

  KeyframeFrame _withPerspective(Matrix4 m, double opacity) {
    final p = Matrix4.identity();
    if (perspective > 0) p.setEntry(3, 2, 1 / perspective);
    return KeyframeFrame(p..multiply(m), opacity.clamp(0.0, 1.0));
  }

  /// Starts [controller] according to duration and repeat.
  void play(AnimationController controller) {
    controller.duration = duration;
    switch (repeat) {
      case KeyframeRepeat.loop:
        controller.repeat();
      case KeyframeRepeat.pingPong:
        controller.repeat(reverse: true);
      case KeyframeRepeat.once:
        controller.forward(from: 0);
    }
  }
}

class KeyframeFrame {
  const KeyframeFrame(this.transform, this.opacity);
  final Matrix4 transform;
  final double opacity;
}

class Keyframe {
  Keyframe._(this.at, this.curve, this._props, this._explicit);

  /// Frame time, a fraction 0…1.
  final double at;

  /// The curve we arrive at this frame with (null — the default curve).
  final String? curve;
  final _Props _props;

  /// The transform given as a whole (css / matrix), if any.
  final Matrix4? _explicit;

  Matrix4 get matrix => _explicit ?? _props.toMatrix();

  /// A short summary for the timeline: which properties are set.
  late final String summary;

  static Keyframe _parse(
    Map<String, dynamic> j, {
    required int index,
    required double durationMs,
    required double fps,
    required _Props previous,
  }) {
    final where = 'keyframes[$index]';
    double at;
    if (j.containsKey('at')) {
      at = _num(j['at'], '$where.at').toDouble();
    } else if (j.containsKey('at_ms')) {
      at = _num(j['at_ms'], '$where.at_ms') / durationMs;
    } else if (j.containsKey('frame')) {
      at = _num(j['frame'], '$where.frame') / fps * 1000 / durationMs;
    } else {
      throw FormatException(
        tr('$where: needs a frame time — at, at_ms or frame', '$where: нужно время кадра — at, at_ms или frame'),
      );
    }
    if (at < 0 || at > 1.0001) {
      throw FormatException(
        tr(
          '$where: time is outside the animation (got ${(at * 100).round()}%)',
          '$where: время вне анимации (получилось ${(at * 100).round()}%)',
        ),
      );
    }
    final curve = j['curve']?.toString();
    if (curve != null) {
      try {
        parseCurve(curve);
      } on FormatException catch (e) {
        throw FormatException('$where.curve: ${e.message}');
      }
    }

    Matrix4? explicit;
    if (j['css'] != null) explicit = parseCssTransform(j['css'].toString(), where: '$where.css');
    if (j['matrix'] != null) explicit = _parseMatrix(j['matrix'], '$where.matrix');

    double? n(String key) => j[key] == null ? null : _num(j[key], '$where.$key').toDouble();
    final scale = j['scale'] == null ? null : _pairOrSingle(j['scale'], '$where.scale');
    final skew = j['skew'] == null ? null : _pair(j['skew'], '$where.skew');
    final props = _Props(
      opacity: n('opacity') ?? previous.opacity,
      x: n('x') ?? previous.x,
      y: n('y') ?? previous.y,
      scaleX: scale?.$1 ?? previous.scaleX,
      scaleY: scale?.$2 ?? previous.scaleY,
      rotate: n('rotate') ?? previous.rotate,
      rotateX: n('rotate_x') ?? previous.rotateX,
      rotateY: n('rotate_y') ?? previous.rotateY,
      skewX: skew?.$1 ?? previous.skewX,
      skewY: skew?.$2 ?? previous.skewY,
    );

    final parts = <String>[
      for (final k in const ['opacity', 'x', 'y', 'scale', 'rotate', 'rotate_x', 'rotate_y', 'skew'])
        if (j.containsKey(k)) '$k ${j[k]}',
      if (j['css'] != null) 'css',
      if (j['matrix'] != null) 'matrix',
    ];
    return Keyframe._(at.clamp(0.0, 1.0), curve, props, explicit)
      ..summary = parts.isEmpty ? tr('no changes', 'без изменений') : parts.join(', ');
  }
}

/// A set of frame properties (degrees, pixels).
class _Props {
  const _Props({
    this.opacity = 1,
    this.x = 0,
    this.y = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotate = 0,
    this.rotateX = 0,
    this.rotateY = 0,
    this.skewX = 0,
    this.skewY = 0,
  });

  final double opacity, x, y, scaleX, scaleY, rotate, rotateX, rotateY, skewX, skewY;

  static _Props lerp(_Props a, _Props b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return _Props(
      opacity: l(a.opacity, b.opacity),
      x: l(a.x, b.x),
      y: l(a.y, b.y),
      scaleX: l(a.scaleX, b.scaleX),
      scaleY: l(a.scaleY, b.scaleY),
      rotate: l(a.rotate, b.rotate),
      rotateX: l(a.rotateX, b.rotateX),
      rotateY: l(a.rotateY, b.rotateY),
      skewX: l(a.skewX, b.skewX),
      skewY: l(a.skewY, b.skewY),
    );
  }

  /// Order matches CSS `translate() rotate() skew() scale()`.
  Matrix4 toMatrix() {
    const rad = math.pi / 180;
    return Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..rotateZ(rotate * rad)
      ..rotateX(rotateX * rad)
      ..rotateY(rotateY * rad)
      ..multiply(Matrix4.skew(skewX * rad, skewY * rad))
      ..scaleByDouble(scaleX, scaleY, 1, 1);
  }
}

// ──────────────────────────────────────────────────────────── CSS transform

final _fnRe = RegExp(r'([a-zA-Z0-9]+)\(([^)]*)\)');

/// Parses a CSS `transform` (what Figma → Copy as CSS produces):
/// translate / translateX / translateY, scale / scaleX / scaleY,
/// rotate / rotateX / rotateY / rotateZ, skew / skewX / skewY,
/// matrix, matrix3d. Units: px, deg, rad, turn.
Matrix4 parseCssTransform(String css, {String where = 'css'}) {
  var s = css.trim();
  if (s.startsWith('transform:')) s = s.substring('transform:'.length);
  s = s.replaceAll(';', '').trim();
  final m = Matrix4.identity();
  final matches = _fnRe.allMatches(s).toList();
  if (matches.isEmpty) {
    throw FormatException(
      tr('$where: found no transform function', '$where: не нашёл ни одной функции transform'),
    );
  }
  for (final f in matches) {
    final name = f.group(1)!;
    final args = f
        .group(2)!
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    double len(int i) => _cssNumber(args, i, where, name);
    double ang(int i) => _cssAngle(args, i, where, name);
    switch (name) {
      case 'translate':
        m.translateByDouble(len(0), args.length > 1 ? len(1) : 0, 0, 1);
      case 'translateX':
        m.translateByDouble(len(0), 0, 0, 1);
      case 'translateY':
        m.translateByDouble(0, len(0), 0, 1);
      case 'scale':
        m.scaleByDouble(len(0), args.length > 1 ? len(1) : len(0), 1, 1);
      case 'scaleX':
        m.scaleByDouble(len(0), 1, 1, 1);
      case 'scaleY':
        m.scaleByDouble(1, len(0), 1, 1);
      case 'rotate' || 'rotateZ':
        m.rotateZ(ang(0));
      case 'rotateX':
        m.rotateX(ang(0));
      case 'rotateY':
        m.rotateY(ang(0));
      case 'skew':
        m.multiply(Matrix4.skew(ang(0), args.length > 1 ? ang(1) : 0));
      case 'skewX':
        m.multiply(Matrix4.skewX(ang(0)));
      case 'skewY':
        m.multiply(Matrix4.skewY(ang(0)));
      case 'matrix' || 'matrix3d':
        m.multiply(_parseMatrix('$name(${f.group(2)})', where));
      default:
        throw FormatException(
          tr('$where: function $name() is not supported', '$where: функция $name() не поддерживается'),
        );
    }
  }
  return m;
}

Matrix4 _parseMatrix(Object? value, String where) {
  List<double> nums;
  if (value is List) {
    nums = [for (final v in value) _num(v, where).toDouble()];
  } else {
    final s = value.toString().trim();
    final match = RegExp(r'^(matrix3d|matrix)\(([^)]*)\)$').firstMatch(s);
    if (match == null) {
      throw FormatException(
        tr('$where: expected matrix(…) or matrix3d(…)', '$where: ожидается matrix(…) или matrix3d(…)'),
      );
    }
    nums = [
      for (final a in match.group(2)!.split(','))
        double.tryParse(a.trim()) ??
            (throw FormatException(
              tr('$where: "${a.trim()}" is not a number', '$where: «${a.trim()}» — не число'),
            )),
    ];
  }
  // CSS and Flutter store matrices the same way — column-major.
  if (nums.length == 6) {
    final [a, b, c, d, tx, ty] = nums;
    return Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }
  if (nums.length == 16) return Matrix4.fromList(nums);
  throw FormatException(
    tr(
      '$where: a matrix must have 6 or 16 numbers, not ${nums.length}',
      '$where: в матрице должно быть 6 или 16 чисел, а не ${nums.length}',
    ),
  );
}

double _cssNumber(List<String> args, int i, String where, String fn) {
  if (i >= args.length) {
    throw FormatException(tr('$where: $fn() is missing arguments', '$where: в $fn() не хватает аргументов'));
  }
  final raw = args[i].replaceAll('px', '').trim();
  return double.tryParse(raw) ??
      (throw FormatException(tr('$where: $fn(${args[i]}) is not a number', '$where: $fn(${args[i]}) — не число')));
}

double _cssAngle(List<String> args, int i, String where, String fn) {
  if (i >= args.length) {
    throw FormatException(tr('$where: $fn() is missing arguments', '$where: в $fn() не хватает аргументов'));
  }
  final a = args[i];
  double parse(String suffix) =>
      double.tryParse(a.substring(0, a.length - suffix.length).trim()) ??
      (throw FormatException(tr('$where: $fn($a) is not an angle', '$where: $fn($a) — не угол')));
  if (a.endsWith('deg')) return parse('deg') * math.pi / 180;
  if (a.endsWith('turn')) return parse('turn') * 2 * math.pi;
  if (a.endsWith('rad')) return parse('rad');
  final v = double.tryParse(a);
  if (v == 0) return 0;
  throw FormatException(
    tr('$where: $fn($a) — specify a unit: deg, rad or turn', '$where: $fn($a) — укажи единицы: deg, rad или turn'),
  );
}

// ────────────────────────────────────────────────────────────── JSON helpers

num _num(Object? v, String where) {
  if (v is num) return v;
  throw FormatException(tr('$where: expected a number, not "$v"', '$where: ожидается число, а не «$v»'));
}

(double, double) _pair(Object? v, String where) {
  if (v is List && v.length == 2) {
    return (_num(v[0], where).toDouble(), _num(v[1], where).toDouble());
  }
  throw FormatException(tr('$where: expected a pair of numbers [x, y]', '$where: ожидается пара чисел [x, y]'));
}

(double, double) _pairOrSingle(Object? v, String where) {
  if (v is num) return (v.toDouble(), v.toDouble());
  return _pair(v, where);
}

// ─────────────────────────────────────────────────────────────── widget

/// Plays [spec] on [child]. Time comes from [animation] (0…1) —
/// usually an AnimationController started via [KeyframeSpec.play].
class KeyframeAnimator extends StatelessWidget {
  const KeyframeAnimator({
    super.key,
    required this.spec,
    required this.animation,
    required this.child,
  });

  final KeyframeSpec spec;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final frame = spec.evaluate(animation.value);
        return Opacity(
          opacity: frame.opacity,
          child: Transform(alignment: spec.origin, transform: frame.transform, child: child),
        );
      },
    );
  }
}
