// Reusable controls for showcases: the full list of curves,
// a labeled slider and a curve-picker dropdown.

import 'package:flutter/material.dart';

import 'i18n.dart';
import 'motion_spec.dart';

export 'motion_spec.dart';

/// ALL curves (easing) from `Curves` — in the same order as the Flutter SDK.
const animationCurves = <String, Curve>{
  'linear': Curves.linear,
  'decelerate': Curves.decelerate,
  'fastLinearToSlowEaseIn': Curves.fastLinearToSlowEaseIn,
  'fastEaseInToSlowEaseOut': Curves.fastEaseInToSlowEaseOut,
  'ease': Curves.ease,
  'easeIn': Curves.easeIn,
  'easeInToLinear': Curves.easeInToLinear,
  'easeInSine': Curves.easeInSine,
  'easeInQuad': Curves.easeInQuad,
  'easeInCubic': Curves.easeInCubic,
  'easeInQuart': Curves.easeInQuart,
  'easeInQuint': Curves.easeInQuint,
  'easeInExpo': Curves.easeInExpo,
  'easeInCirc': Curves.easeInCirc,
  'easeInBack': Curves.easeInBack,
  'easeOut': Curves.easeOut,
  'linearToEaseOut': Curves.linearToEaseOut,
  'easeOutSine': Curves.easeOutSine,
  'easeOutQuad': Curves.easeOutQuad,
  'easeOutCubic': Curves.easeOutCubic,
  'easeOutQuart': Curves.easeOutQuart,
  'easeOutQuint': Curves.easeOutQuint,
  'easeOutExpo': Curves.easeOutExpo,
  'easeOutCirc': Curves.easeOutCirc,
  'easeOutBack': Curves.easeOutBack,
  'easeInOut': Curves.easeInOut,
  'easeInOutSine': Curves.easeInOutSine,
  'easeInOutQuad': Curves.easeInOutQuad,
  'easeInOutCubic': Curves.easeInOutCubic,
  'easeInOutCubicEmphasized': Curves.easeInOutCubicEmphasized,
  'easeInOutQuart': Curves.easeInOutQuart,
  'easeInOutQuint': Curves.easeInOutQuint,
  'easeInOutExpo': Curves.easeInOutExpo,
  'easeInOutCirc': Curves.easeInOutCirc,
  'easeInOutBack': Curves.easeInOutBack,
  'fastOutSlowIn': Curves.fastOutSlowIn,
  'slowMiddle': Curves.slowMiddle,
  'bounceIn': Curves.bounceIn,
  'bounceOut': Curves.bounceOut,
  'bounceInOut': Curves.bounceInOut,
  'elasticIn': Curves.elasticIn,
  'elasticOut': Curves.elasticOut,
  'elasticInOut': Curves.elasticInOut,
};

/// A slider with a label and the current value shown on the right.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.fractionDigits = 0,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final suffix = unit.isEmpty ? '' : ' $unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(fractionDigits)}$suffix',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

/// Curve picker: Flutter presets + "Custom…" — cubic-bezier from Figma/CSS
/// or a spring. The value is a curve string (see motion_spec.dart);
/// turn it into a Curve via [resolveCurve].
class CurveDropdown extends StatelessWidget {
  const CurveDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _custom = '__custom__';

  @override
  Widget build(BuildContext context) {
    final isPreset = animationCurves.containsKey(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Curve (easing)', 'Кривая (easing)'), style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            CustomPaint(
              size: const Size(36, 28),
              painter: _MiniCurvePainter(resolveCurve(value), Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                items: [
                  if (!isPreset)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  for (final name in animationCurves.keys)
                    DropdownMenuItem(value: name, child: Text(name)),
                  DropdownMenuItem(
                    value: _custom,
                    child: Text(
                      tr('Custom: cubic-bezier / spring…', 'Своя: cubic-bezier / пружина…'),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  if (v != _custom) return onChanged(v);
                  final custom = await showCurveEditor(context, value);
                  if (custom != null) onChanged(custom);
                },
              ),
            ),
            IconButton(
              tooltip: tr('Curve editor', 'Редактор кривой'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.tune, size: 20),
              onPressed: () async {
                final custom = await showCurveEditor(context, value);
                if (custom != null) onChanged(custom);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// A small curve graph next to the dropdown.
class _MiniCurvePainter extends CustomPainter {
  _MiniCurvePainter(this.curve, this.color);
  final Curve curve;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i <= 30; i++) {
      final t = i / 30;
      final p = Offset(t * size.width, size.height * (0.8 - curve.transform(t) * 0.6));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MiniCurvePainter old) => old.curve != curve || old.color != color;
}
