// Showcase of animations drawn by hand on the Canvas (CustomPainter):
//   • Activity rings — gradient arcs that animate toward new values;
//   • Path drawing — a path "draws itself" from start to end (PathMetrics);
//   • Shape morphing — one shape smoothly flows into another;
//   • Liquid with waves — sine waves in a circle, a fill level;
//   • Particles — gravity-driven confetti on a Ticker (its own physics).
//
// Everything is drawn frame by frame: the painter is subscribed to the
// animation (repaint), so only the canvas is redrawn, without rebuilding
// the widget tree.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';

double _round2(double v) => double.parse(v.toStringAsFixed(2));

class CustomPainterDemo extends StatelessWidget {
  const CustomPainterDemo({super.key});
  static const String routeName = 'painting/custom_painter';

  @override
  Widget build(BuildContext context) {
    final effectRing = tr('Ring', 'Кольцо');
    final effectPathDraw = tr('Path draw', 'Прорисовка');
    final effectWave = tr('Wave', 'Волна');
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomPainter & Canvas'),
        actions: [const LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Drawing on the Canvas', 'Рисование на Canvas'),
            text: tr(
              "When there's no ready-made widget — you draw it yourself. "
                  'CustomPainter gives you a canvas with lines, arcs, paths, '
                  'gradients and shaders, and the animation simply changes the '
                  'drawing parameters every frame. This is how charts, '
                  "indicators, illustrations, particles are made — anything that "
                  "can't be assembled from rectangles.",
              'Когда готового виджета нет — рисуем сами. CustomPainter даёт '
                  'холст с линиями, дугами, путями, градиентами и шейдерами, а '
                  'анимация просто меняет параметры рисования каждый кадр. Так '
                  'делают графики, индикаторы, иллюстрации, частицы — всё, что '
                  'нельзя собрать из прямоугольников.',
            ),
            hint: tr(
              'It all plays by itself; the controls on the right change parameters on the fly.',
              'Всё играет само; ручки справа меняют параметры на лету.',
            ),
          ),
          const SizedBox(height: 16),
          const _RingsBlock(),
          const SizedBox(height: 16),
          const _PathDrawBlock(),
          const SizedBox(height: 16),
          const _MorphBlock(),
          const SizedBox(height: 16),
          const _WaveBlock(),
          const SizedBox(height: 16),
          const _ParticlesBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            items: [
              (
                tr('Complexity', 'Сложность'),
                tr(
                  '"Complex": drawn frame by frame in code — first discuss a '
                      'prototype with the developer, then polish the numbers',
                  '«Сложно»: рисуется кодом покадрово — сначала обсуждаем прототип с разработчиком, потом полируем цифры',
                ),
              ),
              (
                tr('Vectors', 'Векторы'),
                tr(
                  "outlines and shapes — SVG or a path exported from Figma (no "
                      "raster images, don't convert strokes to fills)",
                  'контуры и фигуры — SVG или path, экспортированный из Figma (без растров, обводки не переводить в заливку)',
                ),
              ),
              (
                tr('Colors and thickness', 'Цвета и толщины'),
                tr(
                  '#hex for every element, gradients — all stops and direction, '
                      'line thickness in px, end-cap rounding',
                  '#hex для каждого элемента, градиенты — все точки и направление, толщина линий в px, скругления концов',
                ),
              ),
              (
                tr('What changes over time', 'Что меняется во времени'),
                tr(
                  'for every parameter: from → to, duration in ms, curve '
                      '(preset / cubic-bezier / spring), delays between elements, repeat',
                  'для каждого параметра: от → до, длительность в мс, кривая (пресет / cubic-bezier / spring), задержки между элементами, повтор',
                ),
              ),
              (
                tr('Particles', 'Частицы'),
                tr(
                  'count per burst, gravity (px/s²), spread speed (px/s), '
                      'lifetime (s), sizes, colors, rotation',
                  'количество за взрыв, гравитация (px/с²), скорость разлёта (px/с), время жизни (с), размеры, цвета, вращение',
                ),
              ),
              (
                tr('Reference', 'Референс'),
                tr(
                  'a video or prototype of how it should look — together with the numbers above',
                  'видео или прототип того, как должно выглядеть, — вместе с цифрами выше',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't send only a video without numbers — it won't be possible to reproduce it by eye.",
                'Не присылать только видео без цифр — повторить «на глаз» не получится.',
              ),
              tr(
                'Complex illustrations with hundreds of layers are better handed off to Lottie/Rive than drawn in code.',
                'Сложные иллюстрации с сотнями слоёв лучше отдать в Lottie/Rive, а не рисовать кодом.',
              ),
            ],
            playground: BriefPlayground(
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), [
                  effectRing,
                  effectPathDraw,
                  effectWave,
                ], effectRing),
                BriefField.duration(
                  'duration_ms',
                  tr('Duration', 'Длительность'),
                  1100,
                ),
                BriefField.curve(
                  'curve',
                  tr('Curve', 'Кривая'),
                  'easeOutCubic',
                ),
                BriefField.number(
                  'value',
                  tr('Value (ring / level)', 'Значение (кольцо / уровень)'),
                  80,
                  unit: '%',
                  min: 0,
                  max: 200,
                ),
                BriefField.number(
                  'stroke',
                  tr('Line thickness', 'Толщина линии'),
                  16,
                  unit: 'px',
                  min: 1,
                  max: 40,
                ),
                BriefField.number(
                  'amplitude',
                  tr('Wave height', 'Высота волны'),
                  8,
                  unit: 'px',
                  min: 0,
                  max: 40,
                ),
                BriefField.color(
                  'color',
                  tr('Primary color', 'Основной цвет'),
                  '#FF2D55',
                ),
                BriefField.color(
                  'color2',
                  tr(
                    'Second color (gradient / back wave)',
                    'Второй цвет (градиент / задняя волна)',
                  ),
                  '#FF6B8B',
                ),
              ],
              builder: _canvasPlayground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── brief playground

/// Playground preview: a ring, a star drawing, or a wave using the entered values.
Widget _canvasPlayground(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final value = v.number('value') / 100;
  final c1 = v.color('color');
  final c2 = v.color('color2');
  final effect = v.text('effect');
  if (effect == tr('Path draw', 'Прорисовка')) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: Size.infinite,
        painter: _PathDrawPainter(
          animation: AlwaysStoppedAnimation(e.clamp(0.0, 1.0)),
          path: _Shape.star.unitPath(),
          stroke: v.number('stroke'),
          fill: false,
          drawShare: 1,
          curve: Curves.linear,
          color: c1,
        ),
      ),
    );
  } else if (effect == tr('Wave', 'Волна')) {
    return SizedBox.square(
      dimension: 170,
      child: CustomPaint(
        painter: _WavePainter(
          animation: AlwaysStoppedAnimation(t),
          level: (value * e).clamp(0.0, 1.0),
          amplitude: v.number('amplitude'),
          color: c1,
          backColor: c2,
        ),
      ),
    );
  } else {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF111111),
        child: Center(
          child: SizedBox.square(
            dimension: 160,
            child: CustomPaint(
              painter: _RingPainter(
                value: value * e,
                stroke: v.number('stroke'),
                colors: [c1, c2],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── Activity rings

const _ringColors = [
  [Color(0xFFFF2D55), Color(0xFFFF6B8B)],
  [Color(0xFF7ED321), Color(0xFFB8F15A)],
  [Color(0xFF1FB5FF), Color(0xFF7FDBFF)],
];

class _RingsBlock extends StatefulWidget {
  const _RingsBlock();

  @override
  State<_RingsBlock> createState() => _RingsBlockState();
}

class _RingsBlockState extends State<_RingsBlock> {
  final _random = math.Random();
  List<double> _values = [0.8, 0.55, 1.25];
  double _stroke = 16;
  int _durationMs = 1100;
  int _staggerMs = 150;
  String _curve = 'easeOutCubic';
  Timer? _timer;
  bool _auto = true;

  Map<String, Object?> _spec() => {
    'widget': tr(
      'CustomPainter (drawArc + SweepGradient) in a TweenAnimationBuilder per ring',
      'CustomPainter (drawArc + SweepGradient) в TweenAnimationBuilder на каждое кольцо',
    ),
    'trigger': _auto
        ? tr(
            'auto-changing values every 2600 ms',
            'автосмена значений каждые 2600 мс',
          )
        : tr('value change', 'смена значения'),
    'rings': [
      for (var i = 0; i < 3; i++)
        {
          'value_percent': (_values[i] * 100).round(),
          'gradient': [for (final c in _ringColors[i]) hexColor(c)],
          'track_color': hexColor(_ringColors[i][0].withValues(alpha: 0.18)),
          ...timingSpec(
            durationMs: _durationMs + i * _staggerMs,
            curve: _curve,
          ),
        },
    ],
    'stagger_step_ms': _staggerMs,
    'stroke_px': _stroke.round(),
    'ring_gap_px': 3,
    'size_px': 190,
    'start_angle': tr(
      'from the top (−90°), clockwise',
      'сверху (−90°), по часовой',
    ),
    'stroke_cap': 'round',
    'over_100_percent': tr(
      'a second lap in the solid end color, a "head" with a ${hexColor(Colors.black54)} shadow, blur 4 px',
      'второй виток сплошным конечным цветом, «голова» с тенью ${hexColor(Colors.black54)}, blur 4 px',
    ),
    'background': hexColor(const Color(0xFF111111)),
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (_auto) _shuffle();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _shuffle() => setState(() {
    _values = [for (var i = 0; i < 3; i++) 0.15 + _random.nextDouble() * 1.2];
  });

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Activity rings', 'Кольца активности'),
      spec: _spec,
      description: tr(
        'Gradient arcs with rounded caps. Values over 100% wrap onto a '
            "second circle — the arc's end gets a shadow so the lap reads "
            'on top. Each ring animates to its new value via a '
            'TweenAnimationBuilder with its own delay.',
        'Дуги с градиентом и скруглёнными концами. Значения > 100% '
            'заходят на второй круг — конец дуги получает тень, чтобы виток '
            'читался поверх. Каждое кольцо тянется к новому значению через '
            'TweenAnimationBuilder со своей задержкой.',
      ),
      preview: Container(
        color: const Color(0xFF111111),
        alignment: Alignment.center,
        child: SizedBox.square(
          dimension: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.all(i * (_stroke + 3)),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _values[i]),
                    duration: Duration(
                      milliseconds: _durationMs + i * _staggerMs,
                    ),
                    curve: resolveCurve(_curve),
                    builder: (context, v, _) => CustomPaint(
                      painter: _RingPainter(
                        value: v,
                        stroke: _stroke,
                        colors: _ringColors[i],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.casino),
                label: Text(tr('New values', 'Новые значения')),
              ),
              FilterChip(
                label: Text(tr('Auto', 'Авто')),
                selected: _auto,
                onSelected: (v) => setState(() => _auto = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 3; i++)
            LabeledSlider(
              label: tr('Ring ${i + 1}', 'Кольцо ${i + 1}'),
              value: _values[i],
              min: 0,
              max: 2,
              unit: '×100%',
              fractionDigits: 2,
              onChanged: (v) => setState(() {
                _auto = false;
                _values = [..._values]..[i] = v;
              }),
            ),
          LabeledSlider(
            label: tr('Thickness', 'Толщина'),
            value: _stroke,
            min: 6,
            max: 22,
            unit: 'px',
            onChanged: (v) => setState(() => _stroke = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 200,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Delay between rings', 'Задержка между кольцами'),
            value: _staggerMs.toDouble(),
            min: 0,
            max: 600,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _staggerMs = v.round()),
          ),
          CurveDropdown(
            value: _curve,
            onChanged: (v) => setState(() => _curve = v),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.colors,
  });
  final double value;
  final double stroke;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[0].withValues(alpha: 0.18),
    );
    if (value <= 0) return;

    final sweep = value * 2 * math.pi;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.translate(-center.dx, -center.dy);
    if (value <= 1) {
      canvas.drawArc(rect, 0, sweep, false, paint);
    } else {
      // Second lap: a full circle in the end color + a shadowed "head".
      canvas.drawCircle(
        center,
        radius,
        paint
          ..shader = null
          ..color = colors[1],
      );
      final head = Offset(
        center.dx + radius * math.cos(sweep),
        center.dy + radius * math.sin(sweep),
      );
      canvas.drawCircle(
        head,
        stroke / 2,
        Paint()
          ..color = Colors.black54
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(head, stroke / 2, Paint()..color = colors[1]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.stroke != stroke || old.colors != colors;
}

// ────────────────────────────────────────────────────── Path drawing

enum _Shape { signature, star, check }

extension on _Shape {
  String get label => switch (this) {
    _Shape.signature => tr('Signature', 'Подпись'),
    _Shape.star => tr('Star', 'Звезда'),
    _Shape.check => tr('Checkmark', 'Галочка'),
  };

  /// The path in 0..1 coordinates.
  Path unitPath() {
    switch (this) {
      case _Shape.signature:
        return Path()
          ..moveTo(0.05, 0.65)
          ..cubicTo(0.15, 0.2, 0.25, 0.2, 0.22, 0.55)
          ..cubicTo(0.2, 0.8, 0.35, 0.8, 0.4, 0.5)
          ..cubicTo(0.45, 0.25, 0.5, 0.35, 0.5, 0.6)
          ..cubicTo(0.5, 0.8, 0.62, 0.75, 0.65, 0.5)
          ..cubicTo(0.68, 0.3, 0.78, 0.35, 0.75, 0.6)
          ..cubicTo(0.73, 0.8, 0.88, 0.75, 0.95, 0.45);
      case _Shape.star:
        final path = Path();
        for (var i = 0; i <= 10; i++) {
          final r = i.isEven ? 0.45 : 0.19;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = Offset(0.5 + r * math.cos(a), 0.52 + r * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path;
      case _Shape.check:
        return Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(0.5, 0.5), radius: 0.4),
          )
          ..moveTo(0.32, 0.52)
          ..lineTo(0.45, 0.65)
          ..lineTo(0.7, 0.38);
    }
  }
}

class _PathDrawBlock extends StatefulWidget {
  const _PathDrawBlock();

  @override
  State<_PathDrawBlock> createState() => _PathDrawBlockState();
}

class _PathDrawBlockState extends State<_PathDrawBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _Shape _shape = _Shape.signature;
  double _stroke = 4;
  int _durationMs = 2400;
  double _drawShare = 0.65;
  String _curve = 'easeInOut';

  Map<String, Object?> _spec() {
    final drawMs = (_durationMs * _drawShare).round();
    return {
      'widget': tr(
        'CustomPainter + PathMetrics.extractPath (trimming the path by length)',
        'CustomPainter + PathMetrics.extractPath (обрезка пути по длине)',
      ),
      'shape': _shape.name,
      'cycle_ms': _durationMs,
      'repeat': 'loop',
      'draw': timingSpec(durationMs: drawMs, curve: _curve),
      'fill': _shape != _Shape.signature
          ? {
              'delay_ms': drawMs,
              ...timingSpec(
                durationMs: (_durationMs * 0.15).round(),
                curve: 'easeOut',
              ),
              'color': hexColor(kAccent.withValues(alpha: 0.2)),
            }
          : false,
      'pause_ms': math.max(
        0,
        _durationMs - drawMs - (_durationMs * 0.15).round(),
      ),
      'stroke_px': _stroke.round(),
      'stroke_color': hexColor(kAccent),
      'stroke_cap': 'round',
      'stroke_join': 'round',
      'pen_tip': {
        'radius_px': (_stroke + 3).round(),
        'color': hexColor(Colors.orange),
      },
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Path drawing', 'Прорисовка контура'),
      spec: _spec,
      description: tr(
        'The path "draws itself" with a pen: we take the contour length '
            'from PathMetrics and each frame show only the piece from the '
            'start. The first 65% of the cycle is drawing, then the fill '
            'appears and there is a pause. This is how signatures, logos, '
            'success icons and map routes are animated.',
        'Путь «рисуется» пером: из PathMetrics берём длину контура и '
            'каждый кадр показываем только кусок от начала. Первые 65% цикла — '
            'прорисовка, дальше проявляется заливка и пауза. Так анимируют '
            'подписи, логотипы, иконки успеха, маршруты на карте.',
      ),
      preview: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomPaint(
          size: Size.infinite,
          painter: _PathDrawPainter(
            animation: _controller,
            path: _shape.unitPath(),
            stroke: _stroke,
            fill: _shape != _Shape.signature,
            drawShare: _drawShare,
            curve: resolveCurve(_curve),
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final s in _Shape.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _shape == s,
                  onSelected: (_) {
                    setState(() => _shape = s);
                    _controller.forward(from: 0).whenComplete(() {
                      if (mounted) _controller.repeat();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Line thickness', 'Толщина линии'),
            value: _stroke,
            min: 1,
            max: 12,
            unit: 'px',
            onChanged: (v) => setState(() => _stroke = v),
          ),
          LabeledSlider(
            label: tr('Cycle duration', 'Длительность цикла'),
            value: _durationMs.toDouble(),
            min: 800,
            max: 6000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              _controller
                ..duration = Duration(milliseconds: _durationMs)
                ..repeat();
            },
          ),
          LabeledSlider(
            label: tr(
              'Share of cycle spent drawing',
              'Доля цикла на прорисовку',
            ),
            value: _drawShare * 100,
            min: 30,
            max: 85,
            unit: '%',
            onChanged: (v) => setState(() => _drawShare = v / 100),
          ),
          CurveDropdown(
            value: _curve,
            onChanged: (v) => setState(() => _curve = v),
          ),
        ],
      ),
    );
  }
}

class _PathDrawPainter extends CustomPainter {
  _PathDrawPainter({
    required this.animation,
    required this.path,
    required this.stroke,
    required this.fill,
    this.drawShare = 0.65,
    this.curve = Curves.easeInOut,
    this.color = kAccent,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Path path;
  final double stroke;
  final bool fill;
  final double drawShare;
  final Curve curve;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;
    final scaled = path.transform(
      (Matrix4.identity()
            ..translateByDouble(dx, dy, 0, 1)
            ..scaleByDouble(side, side, 1, 1))
          .storage,
    );

    final t = animation.value;
    // Overshooting curves go beyond 0..1 — we clamp the path length.
    final draw = curve
        .transform((t / drawShare).clamp(0.0, 1.0))
        .clamp(0.0, 1.0);
    final fillT = Curves.easeOut.transform(
      ((t - drawShare) / 0.15).clamp(0.0, 1.0),
    );

    final metrics = scaled.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * draw;
    final visible = Path();
    for (final m in metrics) {
      if (remaining <= 0) break;
      visible.addPath(
        m.extractPath(0, math.min(remaining, m.length)),
        Offset.zero,
      );
      remaining -= m.length;
    }

    if (fill && fillT > 0) {
      canvas.drawPath(
        scaled,
        Paint()..color = color.withValues(alpha: 0.2 * fillT),
      );
    }
    canvas.drawPath(
      visible,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // "Pen tip" at the current point.
    if (draw > 0 && draw < 1) {
      var at = total * draw;
      for (final m in metrics) {
        if (at <= m.length) {
          final tangent = m.getTangentForOffset(at);
          if (tangent != null) {
            canvas.drawCircle(
              tangent.position,
              stroke + 3,
              Paint()..color = Colors.orange,
            );
          }
          break;
        }
        at -= m.length;
      }
    }
  }

  @override
  bool shouldRepaint(_PathDrawPainter old) =>
      old.path != path ||
      old.stroke != stroke ||
      old.fill != fill ||
      old.drawShare != drawShare ||
      old.curve != curve ||
      old.color != color;
}

// ────────────────────────────────────────────────────────────── Shape morphing

enum _Morph { circle, square, star, heart, flower }

extension on _Morph {
  String get label => switch (this) {
    _Morph.circle => tr('Circle', 'Круг'),
    _Morph.square => tr('Square', 'Квадрат'),
    _Morph.star => tr('Star', 'Звезда'),
    _Morph.heart => tr('Heart', 'Сердце'),
    _Morph.flower => tr('Flower', 'Цветок'),
  };

  /// Shape radius (0..1) as a function of angle — convenient for morphing:
  /// all shapes have the same number of points, so they can simply be interpolated.
  double radius(double a) {
    switch (this) {
      case _Morph.circle:
        return 0.9;
      case _Morph.square:
        return 0.72 / math.max(math.cos(a).abs(), math.sin(a).abs());
      case _Morph.star:
        final k = (a * 5 / (2 * math.pi) + 0.25) % 1;
        return 0.4 + 0.55 * (1 - (2 * k - 1).abs());
      case _Morph.heart:
        // The classic polar heart; the screen's Y axis points down, so
        // we mirror the angle to keep the point at the bottom.
        final s = math.sin(-a);
        return 0.23 *
            (2 - 2 * s + s * math.sqrt(math.cos(a).abs()) / (s + 1.4));
      case _Morph.flower:
        return 0.62 + 0.28 * math.cos(6 * a);
    }
  }
}

class _MorphBlock extends StatefulWidget {
  const _MorphBlock();

  @override
  State<_MorphBlock> createState() => _MorphBlockState();
}

class _MorphBlockState extends State<_MorphBlock>
    with SingleTickerProviderStateMixin {
  static const _points = 240;
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late List<double> _from = _sample(_Morph.circle);
  late List<double> _to = _sample(_Morph.circle);
  _Morph _target = _Morph.circle;
  String _curve = 'easeInOutBack';
  int _durationMs = 900;
  int _pauseMs = 900;
  bool _auto = true;
  Timer? _timer;

  Map<String, Object?> _spec() => {
    'widget': tr(
      'CustomPainter: polar shapes from $_points points, radius lerp',
      'CustomPainter: полярные фигуры из $_points точек, lerp радиусов',
    ),
    'trigger': _auto
        ? tr(
            'auto: next shape every ${_durationMs + _pauseMs} ms',
            'авто: следующая фигура каждые ${_durationMs + _pauseMs} мс',
          )
        : tr('shape selection', 'выбор фигуры'),
    ...timingSpec(durationMs: _durationMs, curve: _curve),
    if (_auto) 'pause_between_ms': _pauseMs,
    'sequence': [for (final m in _Morph.values) m.name],
    'current_target': _target.name,
    'interrupt': tr(
      'a new morph starts from the current intermediate shape',
      'новый морф стартует из текущей промежуточной формы',
    ),
    'fill_gradient': {
      'colors': [hexColor(kAccent), hexColor(Colors.pinkAccent)],
      'direction': 'topLeft → bottomRight',
    },
  };

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _durationMs + _pauseMs), (
      _,
    ) {
      if (!_auto) return;
      _morphTo(_Morph.values[(_target.index + 1) % _Morph.values.length]);
    });
  }

  static List<double> _sample(_Morph m) => [
    for (var i = 0; i < _points; i++) m.radius(i / _points * 2 * math.pi),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _curved = CurvedAnimation(parent: _controller, curve: resolveCurve(_curve));
    _restartTimer();
    _morphTo(_Morph.square);
  }

  void _morphTo(_Morph m) {
    final t = _curved.value;
    setState(() {
      _from = [
        for (var i = 0; i < _points; i++) ui.lerpDouble(_from[i], _to[i], t)!,
      ];
      _to = _sample(m);
      _target = m;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Shape morphing', 'Морфинг фигур'),
      spec: _spec,
      description: tr(
        'One shape smoothly flows into another. Every shape is described '
            'by the same number of points, so the transition is just point '
            'interpolation. With the easeInOutBack curve the shape slightly '
            '"overshoots" the target and comes back — it looks lively.',
        'Одна форма плавно перетекает в другую. Каждая фигура описана '
            'одинаковым числом точек, поэтому переход — это просто '
            'интерполяция точек. С кривой easeInOutBack форма слегка '
            '«перелетает» цель и возвращается — выглядит живо.',
      ),
      preview: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          size: Size.infinite,
          painter: _MorphPainter(animation: _curved, from: _from, to: _to),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _Morph.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _target == m,
                  onSelected: (_) {
                    setState(() => _auto = false);
                    _morphTo(m);
                  },
                ),
              FilterChip(
                label: Text(tr('Auto', 'Авто')),
                selected: _auto,
                onSelected: (v) => setState(() => _auto = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CurveDropdown(
            value: _curve,
            onChanged: (v) {
              setState(() => _curve = v);
              _curved.curve = resolveCurve(v);
            },
          ),
          LabeledSlider(
            label: tr('Morph duration', 'Длительность морфа'),
            value: _durationMs.toDouble(),
            min: 200,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              _controller.duration = Duration(milliseconds: _durationMs);
              _restartTimer();
            },
          ),
          LabeledSlider(
            label: tr(
              'Pause between shapes (auto)',
              'Пауза между фигурами (авто)',
            ),
            value: _pauseMs.toDouble(),
            min: 0,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _pauseMs = v.round());
              _restartTimer();
            },
          ),
        ],
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({required this.animation, required this.from, required this.to})
    : super(repaint: animation);

  final Animation<double> animation;
  final List<double> from;
  final List<double> to;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scale = size.shortestSide / 2;
    final t = animation.value;
    final path = Path();
    for (var i = 0; i < from.length; i++) {
      final a = i / from.length * 2 * math.pi;
      final r = ui.lerpDouble(from[i], to[i], t)! * scale;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    final rect = Rect.fromCircle(center: center, radius: scale);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [kAccent, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_MorphPainter old) => old.from != from || old.to != to;
}

// ──────────────────────────────────────────────────────── Liquid with waves

class _WaveBlock extends StatefulWidget {
  const _WaveBlock();

  @override
  State<_WaveBlock> createState() => _WaveBlockState();
}

class _WaveBlockState extends State<_WaveBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _level = 0.6;
  double _amplitude = 8;
  int _periodMs = 2000;
  int _levelMs = 800;
  String _levelCurve = 'easeOutCubic';

  Map<String, Object?> _spec() => {
    'widget': tr(
      'CustomPainter: two sine waves, circular clipPath; TweenAnimationBuilder for the level',
      'CustomPainter: две синусоиды, clipPath по кругу; TweenAnimationBuilder для уровня',
    ),
    'size_px': 180,
    'level_percent': (_level * 100).round(),
    'level_change': timingSpec(durationMs: _levelMs, curve: _levelCurve),
    'wave_period_ms': _periodMs,
    'repeat': tr('loop (phase runs forever)', 'loop (фаза бежит бесконечно)'),
    'front_wave': {
      'amplitude_px': _amplitude.round(),
      'waves_per_width': 1,
      'speed': tr('1 period per wave_period_ms', '1 период за wave_period_ms'),
      'color': hexColor(const Color(0xFF1E88E5)),
    },
    'back_wave': {
      'amplitude_px': _round2(_amplitude * 0.8),
      'waves_per_width': 1.3,
      'speed': tr('×2, reverse direction', '×2, в обратную сторону'),
      'phase_offset_rad': 1.2,
      'color': hexColor(const Color(0xFF64B5F6)),
    },
    'background': hexColor(const Color(0xFFE3F2FD)),
    'border': {'width_px': 4, 'color': hexColor(const Color(0xFF1E88E5))},
    'label': {'size_px': 34, 'weight': 700, 'color': hexColor(Colors.white)},
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _periodMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Liquid with waves', 'Жидкость с волнами'),
      spec: _spec,
      description: tr(
        'Two sine waves with different phase and speed, clipped by a '
            'circle. The phase runs around the circle forever, while the '
            'level smoothly eases to its new value. Used for charge '
            'indicators, loaders, a "water bottle".',
        'Две синусоиды с разной фазой и скоростью, обрезанные кругом. '
            'Фаза бежит по кругу бесконечно, а уровень плавно дотягивается до '
            'нового значения. Индикаторы заряда, загрузки, «бутылка воды».',
      ),
      preview: TweenAnimationBuilder<double>(
        tween: Tween(end: _level),
        duration: Duration(milliseconds: _levelMs),
        curve: resolveCurve(_levelCurve),
        builder: (context, rawLevel, _) {
          // Overshooting curves can push the level past 0..1.
          final level = rawLevel.clamp(0.0, 1.0);
          return SizedBox.square(
            dimension: 180,
            child: CustomPaint(
              painter: _WavePainter(
                animation: _controller,
                level: level,
                amplitude: _amplitude,
              ),
              child: Center(
                child: Text(
                  '${(level * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Level', 'Уровень'),
            value: _level,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _level = v),
          ),
          LabeledSlider(
            label: tr('Wave height', 'Высота волны'),
            value: _amplitude,
            min: 0,
            max: 20,
            unit: 'px',
            onChanged: (v) => setState(() => _amplitude = v),
          ),
          LabeledSlider(
            label: tr('Wave period', 'Период волны'),
            value: _periodMs.toDouble(),
            min: 500,
            max: 5000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _periodMs = v.round());
              _controller
                ..duration = Duration(milliseconds: _periodMs)
                ..repeat();
            },
          ),
          LabeledSlider(
            label: tr('Level change', 'Смена уровня'),
            value: _levelMs.toDouble(),
            min: 100,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _levelMs = v.round()),
          ),
          CurveDropdown(
            value: _levelCurve,
            onChanged: (v) => setState(() => _levelCurve = v),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.animation,
    required this.level,
    required this.amplitude,
    this.color = const Color(0xFF1E88E5),
    this.backColor = const Color(0xFF64B5F6),
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double level;
  final double amplitude;
  final Color color;
  final Color backColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    canvas.drawPath(circle, Paint()..color = const Color(0xFFE3F2FD));
    canvas.save();
    canvas.clipPath(circle);

    Path wave(double phase, double amp, double waves) {
      final baseY = size.height * (1 - level);
      final p = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y =
            baseY +
            amp * math.sin(x / size.width * waves * 2 * math.pi + phase);
        p.lineTo(x, y);
      }
      return p
        ..lineTo(size.width, size.height)
        ..close();
    }

    final phase = animation.value * 2 * math.pi;
    canvas.drawPath(
      wave(-phase * 2 + 1.2, amplitude * 0.8, 1.3),
      Paint()..color = backColor,
    );
    canvas.drawPath(wave(phase, amplitude, 1), Paint()..color = color);
    canvas.restore();

    canvas.drawCircle(
      rect.center,
      size.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.level != level ||
      old.amplitude != amplitude ||
      old.color != color ||
      old.backColor != backColor ||
      old.animation != animation;
}

// ────────────────────────────────────────────────────────────────── Particles

class _Particle {
  _Particle(this.position, this.velocity, this.color, this.size, this.spin);
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final double spin;
  double angle = 0;
  double life = 1;
}

/// Holds the particles and moves them; the painter is subscribed to it as a Listenable.
class _ParticleSystem extends ChangeNotifier {
  final particles = <_Particle>[];
  final _random = math.Random();
  double gravity = 900;

  /// Maximum starting speed, px/s (minimum is 30% of it).
  double maxSpeed = 500;

  /// Particle lifetime, in seconds (opacity fades linearly 1 → 0).
  double lifetime = 2;

  static const upwardKick = 200.0;
  static const drag = 0.99;

  static const _palette = [
    Color(0xFF673AB7),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFFFFEB3B),
  ];

  void burst(Offset at, int count) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = maxSpeed * (0.3 + _random.nextDouble() * 0.7);
      particles.add(
        _Particle(
          at,
          Offset(math.cos(angle), math.sin(angle)) * speed -
              const Offset(0, upwardKick),
          _palette[_random.nextInt(_palette.length)],
          4 + _random.nextDouble() * 6,
          (_random.nextDouble() - 0.5) * 12,
        ),
      );
    }
  }

  void tick(double dt) {
    for (final p in particles) {
      p.velocity = Offset(p.velocity.dx * drag, p.velocity.dy + gravity * dt);
      p.position += p.velocity * dt;
      p.angle += p.spin * dt;
      p.life -= dt / lifetime;
    }
    particles.removeWhere((p) => p.life <= 0);
    notifyListeners();
  }
}

class _ParticlesBlock extends StatefulWidget {
  const _ParticlesBlock();

  @override
  State<_ParticlesBlock> createState() => _ParticlesBlockState();
}

class _ParticlesBlockState extends State<_ParticlesBlock>
    with SingleTickerProviderStateMixin {
  final _system = _ParticleSystem();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  int _count = 60;
  bool _auto = true;
  double _sinceBurst = 0;
  double _interval = 1.4;

  Map<String, Object?> _spec() => {
    'widget': tr(
      'Ticker + custom physics (ChangeNotifier) + CustomPainter',
      'Ticker + своя физика (ChangeNotifier) + CustomPainter',
    ),
    'trigger': _auto
        ? tr(
            'tap the preview + auto-burst every ${(_interval * 1000).round()} ms',
            'тап по превью + автовзрыв каждые ${(_interval * 1000).round()} мс',
          )
        : tr('tap the preview', 'тап по превью'),
    'particles_per_burst': _count,
    'emit_angle': tr('0–360° uniform', '0–360° равномерно'),
    'speed_px_s': [
      _system.maxSpeed * 0.3,
      _system.maxSpeed,
    ].map((v) => v.round()).toList(),
    'upward_kick_px_s': _ParticleSystem.upwardKick.round(),
    'gravity_px_s2': _system.gravity.round(),
    'horizontal_drag_per_frame': _ParticleSystem.drag,
    'lifetime_s': _round2(_system.lifetime),
    'opacity': tr('linear 1 → 0 over lifetime', 'линейно 1 → 0 за lifetime'),
    'size_px': [4, 10],
    'shape': tr(
      'rectangle, height 0.6 × width',
      'прямоугольник, высота 0.6 × ширины',
    ),
    'spin_rad_s': [-6, 6],
    'palette': [for (final c in _ParticleSystem._palette) hexColor(c)],
  };

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _sinceBurst += dt;
    if (_auto && _sinceBurst > _interval && _size != Size.zero) {
      _sinceBurst = 0;
      final r = math.Random();
      _system.burst(
        Offset(
          _size.width * (0.25 + r.nextDouble() * 0.5),
          _size.height * 0.45,
        ),
        _count,
      );
    }
    _system.tick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _system.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Particles (custom physics)', 'Частицы (своя физика)'),
      spec: _spec,
      description: tr(
        'Confetti with no ready-made packages: a Ticker calls us every '
            'frame, we move the particles (speed, gravity, rotation, '
            'fade-out) and repaint the canvas. Tap the preview — you get a '
            'burst at the touch point.',
        'Конфетти без готовых пакетов: Ticker вызывает нас каждый кадр, '
            'мы двигаем частицы (скорость, гравитация, вращение, затухание) и '
            'перерисовываем холст. Тапни по превью — будет взрыв в точке касания.',
      ),
      preview: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _system.burst(d.localPosition, _count),
            child: CustomPaint(
              size: Size.infinite,
              painter: _ParticlesPainter(_system),
              child: Center(
                child: Text(
                  tr('Tap!', 'Тапни!'),
                  style: const TextStyle(color: Colors.black26, fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            label: Text(tr('Auto-bursts', 'Автовзрывы')),
            selected: _auto,
            onSelected: (v) => setState(() => _auto = v),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Particles per burst', 'Частиц за взрыв'),
            value: _count.toDouble(),
            min: 10,
            max: 200,
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          LabeledSlider(
            label: tr('Gravity', 'Гравитация'),
            value: _system.gravity,
            min: -300,
            max: 2000,
            unit: tr('px/s²', 'px/с²'),
            onChanged: (v) => setState(() => _system.gravity = v),
          ),
          LabeledSlider(
            label: tr('Spread speed (max)', 'Скорость разлёта (макс.)'),
            value: _system.maxSpeed,
            min: 100,
            max: 1200,
            unit: tr('px/s', 'px/с'),
            onChanged: (v) => setState(() => _system.maxSpeed = v),
          ),
          LabeledSlider(
            label: tr('Lifetime', 'Время жизни'),
            value: _system.lifetime,
            min: 0.5,
            max: 5,
            unit: tr('s', 'с'),
            fractionDigits: 1,
            onChanged: (v) => setState(() => _system.lifetime = v),
          ),
          LabeledSlider(
            label: tr('Auto-burst interval', 'Интервал автовзрывов'),
            value: _interval,
            min: 0.4,
            max: 4,
            unit: tr('s', 'с'),
            fractionDigits: 1,
            onChanged: (v) => setState(() => _interval = v),
          ),
        ],
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.system) : super(repaint: system);
  final _ParticleSystem system;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in system.particles) {
      paint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => false;
}
