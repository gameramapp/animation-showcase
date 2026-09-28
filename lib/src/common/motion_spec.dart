// Common "language" of animation settings between designer and developer.
//
// A curve is given as a string in one of these formats:
//   • Flutter preset name:             easeInOut, easeOutBack, elasticOut …
//   • CSS / Figma cubic-bezier:        cubic-bezier(0.2, 0, 0, 1)
//   • Figma Smart Animate spring:      spring(stiffness, damping, mass)
//                                      e.g. spring(300, 20, 1)
// resolveCurve() turns the string into a Curve, curveToCss() — back into
// something Figma/CSS understands. These same strings end up in the "Spec"
// (settings JSON) that the designer copies and attaches to the task.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'animation_controls.dart' show animationCurves;
import 'i18n.dart';

final _cubicRe = RegExp(
  r'^cubic-bezier\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)$',
);
final _springRe = RegExp(r'^spring\(\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$');

/// Parses a curve string; throws [FormatException] if the format is unknown.
Curve parseCurve(String spec) {
  final s = spec.trim();
  final preset = animationCurves[s];
  if (preset != null) return preset;
  final cubic = _cubicRe.firstMatch(s);
  if (cubic != null) {
    final v = [for (var i = 1; i <= 4; i++) double.parse(cubic.group(i)!)];
    if (v[0] < 0 || v[0] > 1 || v[2] < 0 || v[2] > 1) {
      throw FormatException(
        tr(
          'x1 and x2 in cubic-bezier must be between 0 and 1',
          'x1 и x2 в cubic-bezier должны быть от 0 до 1',
        ),
      );
    }
    return Cubic(v[0], v[1], v[2], v[3]);
  }
  final spring = _springRe.firstMatch(s);
  if (spring != null) {
    return SpringCurve(
      stiffness: double.parse(spring.group(1)!),
      damping: double.parse(spring.group(2)!),
      mass: double.parse(spring.group(3) ?? '1'),
    );
  }
  throw FormatException(tr('Unknown curve: "$s"', 'Неизвестная кривая: «$s»'));
}

final _curveCache = <String, Curve>{};

/// Like [parseCurve], but without exceptions: unknown → easeInOut.
/// The result is cached — safe to call on every frame.
Curve resolveCurve(String spec) {
  return _curveCache.putIfAbsent(spec, () {
    try {
      return parseCurve(spec);
    } on FormatException {
      return Curves.easeInOut;
    }
  });
}

/// Whether the curve has a CSS/Figma equivalent (cubic-bezier / spring).
String? curveToCss(String spec) {
  final curve = resolveCurve(spec);
  if (curve is Cubic) {
    String f(double v) => double.parse(v.toStringAsFixed(3)).toString();
    return 'cubic-bezier(${f(curve.a)}, ${f(curve.b)}, ${f(curve.c)}, ${f(curve.d)})';
  }
  if (curve is SpringCurve) return curve.toString();
  if (curve == Curves.linear) return 'linear';
  return null;
}

/// A spring like in Figma Smart Animate: stiffness / damping / mass.
/// The curve is stretched over the time it takes the spring to settle
/// ([settleDuration]), so it's convenient to put into any duration.
class SpringCurve extends Curve {
  SpringCurve({required this.stiffness, required this.damping, this.mass = 1})
    : _simulation = SpringSimulation(
        SpringDescription(mass: mass, stiffness: stiffness, damping: damping),
        0,
        1,
        0,
        tolerance: const Tolerance(distance: 0.001, velocity: 0.001),
      ) {
    var t = 0.0;
    while (t < 10 && !_simulation.isDone(t)) {
      t += 0.01;
    }
    _settle = math.max(t, 0.05);
  }

  final double stiffness;
  final double damping;
  final double mass;
  final SpringSimulation _simulation;
  late final double _settle;

  /// The spring's "natural" duration — how long it actually moves.
  Duration get settleDuration => Duration(milliseconds: (_settle * 1000).round());

  @override
  double transformInternal(double t) => _simulation.x(t * _settle);

  @override
  String toString() {
    String f(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
    return 'spring(${f(stiffness)}, ${f(damping)}, ${f(mass)})';
  }

  @override
  bool operator ==(Object other) =>
      other is SpringCurve &&
      other.stiffness == stiffness &&
      other.damping == damping &&
      other.mass == mass;

  @override
  int get hashCode => Object.hash(stiffness, damping, mass);
}

/// The standard spec snippet about timing: duration, delay, curve
/// + its CSS equivalent (if any).
Map<String, Object?> timingSpec({required int durationMs, String? curve, int? delayMs}) {
  final css = curve == null ? null : curveToCss(curve);
  return {
    'duration_ms': durationMs,
    'delay_ms': ?delayMs,
    'curve': ?curve,
    if (curve != null) 'curve_css': css ?? tr('no CSS equivalent — Flutter only', 'нет аналога в CSS — только во Flutter'),
  };
}

/// Color for the spec: '#RRGGBB' (+ opacity, if it's not 100%).
String hexColor(Color c) {
  final rgb = (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  final alpha = (c.a * 100).round();
  return alpha >= 100 ? '#$rgb' : '#$rgb @ $alpha%';
}

// ─────────────────────────────────────────────────────────────── "Spec"

/// The "Spec" button: shows the block's current settings as JSON and copies them.
/// [spec] is called at press time — always returns up-to-date values.
class SpecButton extends StatelessWidget {
  const SpecButton({super.key, required this.title, required this.spec});

  final String title;
  final Map<String, Object?> Function() spec;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: () => showSpecDialog(context, title: title, spec: spec()),
      icon: const Icon(Icons.data_object, size: 18),
      label: Text(tr('Spec', 'Спека')),
    );
  }
}

Future<void> showSpecDialog(
  BuildContext context, {
  required String title,
  required Map<String, Object?> spec,
}) {
  final json = const JsonEncoder.withIndent('  ').convert({'effect': title, ...spec});
  final specLabel = tr('Spec', 'Спека');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$specLabel: $title'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(
                  "This block's current settings. Copy them and attach to the task — "
                  'the developer will reproduce the animation exactly.',
                  'Текущие настройки этого блока. Скопируй и приложи к задаче — '
                      'разработчик повторит анимацию один в один.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  json,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Close', 'Закрыть'))),
        FilledButton.icon(
          onPressed: () {
            // Grab the messenger before closing: after pop the dialog's context is already dead.
            final messenger = ScaffoldMessenger.maybeOf(context);
            Clipboard.setData(ClipboardData(text: json));
            Navigator.pop(context);
            messenger?.showSnackBar(SnackBar(content: Text(tr('Spec copied', 'Спека скопирована'))));
          },
          icon: const Icon(Icons.copy, size: 18),
          label: Text(tr('Copy', 'Скопировать')),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────── curve editor

/// Spring presets from Figma Smart Animate.
const figmaSprings = <String, String>{
  'Gentle': 'spring(100, 15, 1)',
  'Quick': 'spring(300, 20, 1)',
  'Bouncy': 'spring(600, 15, 1)',
  'Slow': 'spring(80, 20, 1)',
};

/// The "Custom curve" dialog: cubic-bezier with draggable handles or
/// a spring. Returns the curve string, or null if dismissed.
Future<String?> showCurveEditor(BuildContext context, String initial) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CurveEditorDialog(initial: initial),
  );
}

class _CurveEditorDialog extends StatefulWidget {
  const _CurveEditorDialog({required this.initial});
  final String initial;

  @override
  State<_CurveEditorDialog> createState() => _CurveEditorDialogState();
}

class _CurveEditorDialogState extends State<_CurveEditorDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _preview = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final TextEditingController _text;
  late bool _spring;
  // Bezier.
  Offset _p1 = const Offset(0.25, 0.1);
  Offset _p2 = const Offset(0.25, 1);
  // Spring.
  double _stiffness = 300, _damping = 20, _mass = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    final curve = resolveCurve(widget.initial);
    _spring = curve is SpringCurve;
    if (curve is Cubic) {
      _p1 = Offset(curve.a, curve.b);
      _p2 = Offset(curve.c, curve.d);
    } else if (curve is SpringCurve) {
      _stiffness = curve.stiffness;
      _damping = curve.damping;
      _mass = curve.mass;
    }
    _text = TextEditingController(text: _current);
  }

  @override
  void dispose() {
    _preview.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _current {
    if (_spring) {
      return SpringCurve(stiffness: _stiffness, damping: _damping, mass: _mass).toString();
    }
    String f(double v) => double.parse(v.toStringAsFixed(2)).toString();
    return 'cubic-bezier(${f(_p1.dx)}, ${f(_p1.dy)}, ${f(_p2.dx)}, ${f(_p2.dy)})';
  }

  void _syncText() {
    _text.text = _current;
    _error = null;
  }

  void _applyText(String value) {
    try {
      final curve = parseCurve(value);
      setState(() {
        _error = null;
        if (curve is Cubic) {
          _spring = false;
          _p1 = Offset(curve.a, curve.b);
          _p2 = Offset(curve.c, curve.d);
        } else if (curve is SpringCurve) {
          _spring = true;
          _stiffness = curve.stiffness;
          _damping = curve.damping;
          _mass = curve.mass;
        }
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final curve = resolveCurve(_current);
    return AlertDialog(
      title: Text(tr('Custom curve', 'Своя кривая')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(tr('Bezier', 'Безье'))),
                  ButtonSegment(value: true, label: Text(tr('Spring', 'Пружина'))),
                ],
                selected: {_spring},
                onSelectionChanged: (v) => setState(() {
                  _spring = v.first;
                  _syncText();
                }),
              ),
              const SizedBox(height: 12),
              Text(
                _spring
                    ? tr(
                        'Like Spring in Figma Smart Animate: stiffness, damping, mass.',
                        'Как Spring в Figma Smart Animate: жёсткость, затухание, масса.',
                      )
                    : tr(
                        'Drag the handles or paste cubic-bezier(…) from Figma / CSS / After Effects.',
                        'Тяни ручки или вставь cubic-bezier(…) из Figma / CSS / After Effects.',
                      ),
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox.square(
                  dimension: 240,
                  child: _BezierGraph(
                    curve: curve,
                    p1: _spring ? null : _p1,
                    p2: _spring ? null : _p2,
                    preview: _preview,
                    onDrag: (i, p) => setState(() {
                      i == 1 ? _p1 = p : _p2 = p;
                      _syncText();
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_spring) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final MapEntry(key: name, value: spec) in figmaSprings.entries)
                      ActionChip(label: Text(name), onPressed: () {
                        _text.text = spec;
                        _applyText(spec);
                      }),
                  ],
                ),
                _slider(tr('Stiffness', 'Жёсткость (stiffness)'), _stiffness, 10, 1000, (v) => _stiffness = v),
                _slider(tr('Damping', 'Затухание (damping)'), _damping, 1, 100, (v) => _damping = v),
                _slider(tr('Mass', 'Масса (mass)'), _mass, 0.1, 10, (v) => _mass = v, digits: 1),
                if (curve is SpringCurve)
                  Text(
                    tr(
                      'The spring settles in ≈ ${curve.settleDuration.inMilliseconds} ms — '
                          'that\'s a good duration for this kind of animation.',
                      'Пружина успокаивается за ≈ ${curve.settleDuration.inMilliseconds} мс — '
                          'это хорошая длительность для такой анимации.',
                    ),
                    style: textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  labelText: tr('Curve as text', 'Кривая строкой'),
                  errorText: _error,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _applyText,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Cancel', 'Отмена'))),
        FilledButton(
          onPressed: _error == null ? () => Navigator.pop(context, _current) : null,
          child: Text(tr('Apply', 'Применить')),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> set, {
    int digits = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            Text(value.toStringAsFixed(digits)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (v) => setState(() {
            set(v);
            _syncText();
          }),
        ),
      ],
    );
  }
}

/// A curve graph with bezier handles (if given) and a running preview dot.
class _BezierGraph extends StatefulWidget {
  const _BezierGraph({
    required this.curve,
    required this.p1,
    required this.p2,
    required this.preview,
    required this.onDrag,
  });

  final Curve curve;
  final Offset? p1;
  final Offset? p2;
  final Animation<double> preview;
  final void Function(int handle, Offset point) onDrag;

  // Y axis: from -0.5 to 1.5 — leaves room for back/elastic/spring "overshoot".
  static Offset toLocal(Offset p, Size s) => Offset(p.dx * s.width, s.height * (0.75 - p.dy * 0.5));
  static Offset fromLocal(Offset l, Size s) =>
      Offset((l.dx / s.width).clamp(0.0, 1.0), ((0.75 - l.dy / s.height) / 0.5).clamp(-0.5, 1.5));

  @override
  State<_BezierGraph> createState() => _BezierGraphState();
}

class _BezierGraphState extends State<_BezierGraph> {
  int? _dragging;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        return GestureDetector(
          onPanStart: (d) {
            final p1 = widget.p1, p2 = widget.p2;
            if (p1 == null || p2 == null) return;
            final d1 = (_BezierGraph.toLocal(p1, size) - d.localPosition).distance;
            final d2 = (_BezierGraph.toLocal(p2, size) - d.localPosition).distance;
            _dragging = d1 < d2 ? 1 : 2;
          },
          onPanUpdate: (d) {
            final i = _dragging;
            if (i != null) widget.onDrag(i, _BezierGraph.fromLocal(d.localPosition, size));
          },
          onPanEnd: (_) => _dragging = null,
          child: CustomPaint(
            size: size,
            painter: _BezierPainter(
              curve: widget.curve,
              p1: widget.p1,
              p2: widget.p2,
              preview: widget.preview,
            ),
          ),
        );
      },
    );
  }
}

class _BezierPainter extends CustomPainter {
  _BezierPainter({required this.curve, this.p1, this.p2, required this.preview})
    : super(repaint: preview);

  final Curve curve;
  final Offset? p1;
  final Offset? p2;
  final Animation<double> preview;

  static const _accent = Color(0xFF673AB7);

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset p) => _BezierGraph.toLocal(p, size);
    final grid = Paint()..color = Colors.black12;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x08000000));
    canvas.drawLine(at(const Offset(0, 0)), at(const Offset(1, 0)), grid);
    canvas.drawLine(at(const Offset(0, 1)), at(const Offset(1, 1)), grid);

    final path = Path();
    for (var i = 0; i <= 100; i++) {
      final t = i / 100;
      final p = at(Offset(t, curve.transform(t)));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (p1 != null && p2 != null) {
      final handle = Paint()
        ..color = Colors.orange
        ..strokeWidth = 1.5;
      canvas.drawLine(at(Offset.zero), at(p1!), handle);
      canvas.drawLine(at(const Offset(1, 1)), at(p2!), handle);
      canvas.drawCircle(at(p1!), 9, Paint()..color = Colors.orange);
      canvas.drawCircle(at(p2!), 9, Paint()..color = Colors.orange);
    }

    // Preview: the dot runs with a pause at the end.
    final t = (preview.value / 0.75).clamp(0.0, 1.0);
    final v = curve.transform(t);
    canvas.drawCircle(at(Offset(t, v)), 5, Paint()..color = _accent);
    // Track on the right: how the object will actually move.
    final track = Offset(size.width - 10, 0);
    canvas.drawCircle(
      Offset(track.dx, at(Offset(0, v)).dy),
      7,
      Paint()..color = Colors.orange.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_BezierPainter old) => old.curve != curve || old.p1 != p1 || old.p2 != p2;
}
