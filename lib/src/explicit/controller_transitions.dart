// Showcase of explicit animations: a single AnimationController (the "remote")
// drives all the built-in *Transition widgets at once:
//   FadeTransition, ScaleTransition, RotationTransition, SlideTransition,
//   SizeTransition, AlignTransition, DecoratedBoxTransition
// + AnimatedBuilder with Transform (3D flip) — "animate anything".
// At the bottom — TweenAnimationBuilder: a custom implicit animation without a controller.
//
// Unlike implicit widgets, here the animation is controlled manually:
// play / reverse / repeat / stop, scrubbing via a slider, reading progress.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';

class ControllerTransitionsDemo extends StatefulWidget {
  const ControllerTransitionsDemo({super.key});
  static const String routeName = 'explicit/controller_transitions';

  @override
  State<ControllerTransitionsDemo> createState() => _ControllerTransitionsDemoState();
}

class _ControllerTransitionsDemoState extends State<ControllerTransitionsDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;
  int _durationMs = 1200;
  String _curve = 'easeInOut';
  // Which remote command the controller is currently playing — for the "Spec".
  String _playback = 'repeat(reverse: true)';

  late final Animation<double> _scale;
  late final Animation<double> _turns;
  late final Animation<Offset> _slide;
  late final Animation<AlignmentGeometry> _align;
  late final Animation<Decoration> _decoration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: resolveCurve(_curve));

    _scale = Tween<double>(begin: 0.4, end: 1.2).animate(_animation);
    _turns = Tween<double>(begin: 0, end: 0.5).animate(_animation);
    _slide = Tween<Offset>(begin: const Offset(-1, 0), end: const Offset(1, 0)).animate(_animation);
    _align = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(_animation);
    _decoration = DecorationTween(
      begin: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 0)],
      ),
      end: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(48),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 12))],
      ),
    ).animate(_animation);
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Settings for the remote and all tiles — for the "Spec" button.
  Map<String, Object?> _spec() => {
    'widget': 'AnimationController + CurvedAnimation → *Transition',
    ...timingSpec(durationMs: _durationMs, curve: _curve),
    'playback': _playback,
    'progress': double.parse(_controller.value.toStringAsFixed(2)),
    'tiles': {
      'FadeTransition': {'opacity_from': 0, 'opacity_to': 1},
      'ScaleTransition': {'scale_from': 0.4, 'scale_to': 1.2},
      'RotationTransition': {'turns_from': 0, 'turns_to': 0.5, 'rotation_deg_to': 180},
      'SlideTransition': {
        'offset_x_fraction_of_width_from': -1,
        'offset_x_fraction_of_width_to': 1,
      },
      'SizeTransition': {
        'axis': 'horizontal',
        'axis_alignment': 'start',
        'size_factor_from': 0,
        'size_factor_to': 1,
      },
      'AlignTransition': {'alignment_from': 'topLeft', 'alignment_to': 'bottomRight'},
      'DecoratedBoxTransition': {
        'from': {
          'color': hexColor(kAccent),
          'border_radius_px': 8,
          'shadow': {'color': '#000000', 'opacity': 0.26, 'blur_px': 0, 'offset_y_px': 0},
        },
        'to': {
          'color': hexColor(Colors.orange),
          'border_radius_px': 48,
          'shadow': {'color': '#000000', 'opacity': 0.38, 'blur_px': 24, 'offset_y_px': 12},
        },
      },
      'AnimatedBuilder + Transform (3D flip)': {
        'axis': 'Y',
        'rotation_deg_from': 0,
        'rotation_deg_to': 180,
        'perspective': 0.0015,
        'card_size_px': {'width': 90, 'height': 120},
        'front_color': hexColor(kAccent),
        'back_color': hexColor(Colors.orange),
      },
    },
    'element': {'size_px': 64, 'border_radius_px': 14, 'color': hexColor(kAccent)},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller & Transitions'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Explicit animations', 'Explicit-анимации'),
            text: tr(
              'Here the animation is controlled explicitly: an AnimationController '
              'produces progress 0 → 1, a curve turns it into the "character" of '
              'the motion, and *Transition widgets apply it to properties. One '
              'controller can drive as many elements as you like in sync — all '
              'the tiles below live off one remote.',
              'Здесь анимацией управляют явно: AnimationController выдаёт '
                  'прогресс 0 → 1, кривая превращает его в «характер» движения, '
                  'а *Transition-виджеты применяют его к свойствам. Один контроллер '
                  'может синхронно вести сколько угодно элементов — все плитки ниже '
                  'живут от одного пульта.',
            ),
            hint: tr(
              'Press the remote buttons or drag the progress slider — the tiles '
              'and the curve graph move together.',
              'Жми кнопки пульта или тащи ползунок прогресса — плитки и '
                  'график кривой двигаются вместе.',
            ),
          ),
          const SizedBox(height: 16),
          _ControlPanel(
            controller: _controller,
            animation: _animation,
            durationMs: _durationMs,
            curve: _curve,
            onDurationChanged: (ms) {
              setState(() => _durationMs = ms);
              _controller.duration = Duration(milliseconds: ms);
            },
            onCurveChanged: (name) {
              setState(() => _curve = name);
              _animation.curve = resolveCurve(name);
            },
            onPlaybackChanged: (mode) => _playback = mode,
            spec: _spec,
          ),
          const SizedBox(height: 16),
          ResponsiveWrap(
            minTileWidth: 240,
            children: [
              ShowcaseTile(
                title: 'FadeTransition',
                caption: tr(
                  'Opacity 0 → 1. The cheapest way to show/hide something.',
                  'Прозрачность 0 → 1. Самый дешёвый способ показать/скрыть.',
                ),
                child: FadeTransition(opacity: _animation, child: const _Box()),
              ),
              ShowcaseTile(
                title: 'ScaleTransition',
                caption: tr(
                  'Scale 0.4× → 1.2×. Zoom, a "pop", a tap reaction.',
                  'Масштаб 0.4× → 1.2×. Зум, «pop», реакция на тап.',
                ),
                child: ScaleTransition(scale: _scale, child: const _Box()),
              ),
              ShowcaseTile(
                title: 'RotationTransition',
                caption: tr(
                  'Rotation 0 → 180°. Disclosure arrows, spinners.',
                  'Поворот 0 → 180°. Стрелки раскрытия, спиннеры.',
                ),
                child: RotationTransition(
                  turns: _turns,
                  child: const _Box(label: '➜'),
                ),
              ),
              ShowcaseTile(
                title: 'SlideTransition',
                caption: tr(
                  'Shift by a fraction of its own size (−1 → 1 of width).',
                  'Сдвиг на долю собственного размера (−1 → 1 ширины).',
                ),
                child: SlideTransition(position: _slide, child: const _Box()),
              ),
              ShowcaseTile(
                title: 'SizeTransition',
                caption: tr(
                  'Reveals an element along an axis, clipping it. Progress bars, expand/collapse.',
                  'Раскрывает элемент по оси, обрезая его. Прогресс-бары, раскрытия.',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.horizontal,
                    axisAlignment: -1,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              ShowcaseTile(
                title: 'AlignTransition',
                caption: tr(
                  'Movement within the parent: corner to corner.',
                  'Перемещение внутри родителя: из угла в угол.',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AlignTransition(alignment: _align, child: const _Box(size: 40)),
                ),
              ),
              ShowcaseTile(
                title: 'DecoratedBoxTransition',
                caption: tr(
                  'Color, corner radius and shadow in one tween (DecorationTween).',
                  'Цвет, скругление и тень одним твином (DecorationTween).',
                ),
                child: DecoratedBoxTransition(
                  decoration: _decoration,
                  child: const SizedBox(width: 80, height: 80),
                ),
              ),
              ShowcaseTile(
                title: 'AnimatedBuilder + Transform',
                caption: tr(
                  '3D card flip: with your own hands you can animate anything.',
                  '3D-переворот карточки: руками можно анимировать что угодно.',
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final angle = _animation.value * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: _Card(color: Colors.orange, label: tr('Back', 'Рубашка')),
                            )
                          : _Card(color: kAccent, label: tr('Face', 'Лицо')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _TweenAnimationBuilderBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), _pgEffects, _pgEffects[0]),
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 1200),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeInOut'),
                BriefField.number(
                  'offset_px',
                  tr('Shift (from −X to +X)', 'Сдвиг (от −X до +X)'),
                  80,
                  unit: 'px',
                ),
                BriefField.number('scale_from', tr('Scale "from"', 'Масштаб «от»'), 0.4, unit: '×', min: 0),
                BriefField.number('scale_to', tr('Scale "to"', 'Масштаб «до»'), 1.2, unit: '×', min: 0),
                BriefField.number('rotation_deg', tr('Rotation', 'Поворот'), 180, unit: '°'),
                BriefField.color('color_from', tr('Color "from"', 'Цвет «от»'), '#673AB7'),
                BriefField.color('color_to', tr('Color "to"', 'Цвет «до»'), '#FF9800'),
                BriefField.number(
                  'radius_to',
                  tr('Corner radius "to"', 'Скругление «до»'),
                  48,
                  unit: 'px',
                  min: 0,
                ),
              ],
              builder: _controllerPreview,
            ),
            items: [
              (
                tr('Playback mode', 'Режим проигрывания'),
                tr(
                  'once, looping (repeat), or back-and-forth (ping-pong); pause '
                      'between cycles, ms',
                  'один раз, по кругу (repeat) или туда-обратно (ping-pong); '
                      'пауза между циклами, мс',
                ),
              ),
              (
                tr('Total duration and curve', 'Общая длительность и кривая'),
                tr(
                  'ms + preset, cubic-bezier(…) from Figma/CSS, or spring(…)',
                  'мс + пресет, cubic-bezier(…) из Figma/CSS или spring(…)',
                ),
              ),
              (
                tr('Properties and their values', 'Свойства и их значения'),
                tr(
                  'for each element: opacity, scale ×, rotation °, offset px or as '
                      'a fraction of size — "from" and "to"',
                  'для каждого элемента: opacity, масштаб ×, поворот °, сдвиг px или '
                      'в долях размера — «от» и «до»',
                ),
              ),
              (
                tr('Color / shape / shadow', 'Цвет / форма / тень'),
                tr(
                  'starting and ending #hex, corner radius px, shadow blur and offset px',
                  'начальный и конечный #hex, скругление px, blur и смещение тени px',
                ),
              ),
              (
                tr('Control', 'Управление'),
                tr(
                  "what starts it, pauses it, reverses it; whether gesture scrubbing is needed",
                  'что запускает, ставит на паузу, реверсит; нужна ли перемотка жестом',
                ),
              ),
              (
                tr('Number/progress', 'Число/прогресс'),
                tr(
                  'from what value to what value, format (%, number), color at '
                      'the start and at the end',
                  'от какого до какого значения, формат (%, число), цвет в начале и в конце',
                ),
              ),
            ],
            avoid: [
              tr(
                "If elements need to move in sync, say so explicitly — otherwise "
                    "they'll be built separately",
                'Если элементы должны двигаться синхронно — так и написать, иначе сделают отдельно',
              ),
              tr(
                "Don't send just a video without numbers",
                'Не присылать только видео без цифр',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── remote

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.controller,
    required this.animation,
    required this.durationMs,
    required this.curve,
    required this.onDurationChanged,
    required this.onCurveChanged,
    required this.onPlaybackChanged,
    required this.spec,
  });

  final AnimationController controller;
  final Animation<double> animation;
  final int durationMs;
  final String curve;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<String> onCurveChanged;
  final ValueChanged<String> onPlaybackChanged;
  final Map<String, Object?> Function() spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: () {
            onPlaybackChanged('forward()');
            controller.forward();
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('forward'),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            onPlaybackChanged('reverse()');
            controller.reverse();
          },
          icon: const Icon(Icons.fast_rewind),
          label: const Text('reverse'),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            onPlaybackChanged('repeat()');
            controller.repeat();
          },
          icon: const Icon(Icons.repeat),
          label: const Text('repeat'),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            onPlaybackChanged('repeat(reverse: true)');
            controller.repeat(reverse: true);
          },
          icon: const Icon(Icons.swap_horiz),
          label: const Text('ping-pong'),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            onPlaybackChanged('stop()');
            controller.stop();
          },
          icon: const Icon(Icons.stop),
          label: const Text('stop'),
        ),
      ],
    );

    final status = AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    tr('Controller progress', 'Прогресс контроллера'),
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${controller.value.toStringAsFixed(2)} · ${controller.status.name}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            Slider(
              value: controller.value,
              onChanged: (v) {
                onPlaybackChanged(tr('stop() · manual scrub', 'stop() · перемотка вручную'));
                controller.stop();
                controller.value = v;
              },
            ),
          ],
        );
      },
    );

    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('AnimationController remote', 'Пульт AnimationController'),
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SpecButton(title: 'Controller & Transitions', spec: spec),
          ],
        ),
        const SizedBox(height: 12),
        buttons,
        const SizedBox(height: 12),
        status,
        LabeledSlider(
          label: tr('Duration', 'Длительность'),
          value: durationMs.toDouble(),
          min: 200,
          max: 4000,
          unit: tr('ms', 'мс'),
          onChanged: (v) => onDurationChanged(v.round()),
        ),
        CurveDropdown(value: curve, onChanged: onCurveChanged),
      ],
    );

    final plot = Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: CurvePlotPainter(
          curve: resolveCurve(curve),
          controller: controller,
          animation: animation,
          color: kAccent,
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [settings, const SizedBox(height: 12), plot],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: settings),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: plot),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Curve plot: X axis is time (controller progress), Y axis is the value
/// after applying the curve. The dot shows the current moment of the animation.
class CurvePlotPainter extends CustomPainter {
  CurvePlotPainter({
    required this.curve,
    required this.controller,
    required this.animation,
    required this.color,
  }) : super(repaint: controller);

  final Curve curve;
  final AnimationController controller;
  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Leave room for elastic/back curves "overshooting" past 0..1.
    final top = size.height * 0.15;
    final plotHeight = size.height * 0.7;
    double y(double v) => top + plotHeight * (1 - v);

    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), grid);
    canvas.drawLine(Offset(0, y(1)), Offset(size.width, y(1)), grid);

    final path = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(t * size.width, y(curve.transform(t)));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final dot = Offset(controller.value * size.width, y(animation.value));
    canvas.drawLine(
      Offset(dot.dx, 0),
      Offset(dot.dx, size.height),
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawCircle(dot, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CurvePlotPainter oldDelegate) => oldDelegate.curve != curve;
}

// ─────────────────────────────────────────────────── TweenAnimationBuilder

class _TweenAnimationBuilderBlock extends StatefulWidget {
  const _TweenAnimationBuilderBlock();

  @override
  State<_TweenAnimationBuilderBlock> createState() => _TweenAnimationBuilderBlockState();
}

class _TweenAnimationBuilderBlockState extends State<_TweenAnimationBuilderBlock> {
  final _random = math.Random();
  double _target = 0.72;
  int _durationMs = 900;
  String _curve = 'easeOutCubic';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'TweenAnimationBuilder',
      spec: () => {
        'widget': 'TweenAnimationBuilder<double>',
        ...timingSpec(durationMs: _durationMs, curve: _curve),
        'target_value': double.parse(_target.toStringAsFixed(2)),
        'target_percent': (_target * 100).round(),
        'animated': [
          tr('percentage number', 'число %'),
          tr('progress arc', 'дуга прогресса'),
          tr('color', 'цвет'),
        ],
        'color_from_at_0': hexColor(Colors.redAccent),
        'color_to_at_1': hexColor(Colors.green),
        'progress_ring': {
          'size_px': 150,
          'stroke_width_px': 12,
          'stroke_cap': 'round',
          'track_opacity': 0.15,
        },
      },
      description: tr(
        'Your own implicit animation for any value without a controller: set a '
        'target value — the widget smoothly reaches it from the current one on '
        'its own, even if the target changes mid-animation. Here it animates a '
        'number, a progress arc, and a color.',
        'Своя implicit-анимация для любого значения без контроллера: '
            'задаёшь целевое значение — виджет сам плавно дотягивается до него '
            'от текущего, даже если цель поменяли посреди анимации. Здесь так '
            'анимируются число, дуга прогресса и цвет.',
      ),
      preview: TweenAnimationBuilder<double>(
        tween: Tween(end: _target),
        duration: Duration(milliseconds: _durationMs),
        curve: resolveCurve(_curve),
        builder: (context, value, _) {
          final color = Color.lerp(Colors.redAccent, Colors.green, value.clamp(0.0, 1.0))!;
          return SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 12,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: () => setState(() => _target = _random.nextDouble()),
            icon: const Icon(Icons.casino),
            label: Text(tr('Random value', 'Случайное значение')),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Target value', 'Целевое значение'),
            value: _target,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _target = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 100,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = v.round()),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── samples

class _Box extends StatelessWidget {
  const _Box({this.size = 64, this.label});
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(14)),
      child: label == null
          ? null
          : Text(label!, style: const TextStyle(color: Colors.white, fontSize: 24)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

List<String> get _pgEffects => [
  tr('Shift + scale', 'Сдвиг + масштаб'),
  tr('3D flip', '3D-переворот'),
  tr('Color & shape', 'Цвет и форма'),
];

/// Playground preview: what a single controller does to the tiles above.
Widget _controllerPreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final k = e.clamp(0.0, 1.0);
  final from = v.color('color_from'), to = v.color('color_to');
  final effect = v.text('effect');
  if (effect == _pgEffects[1]) {
    final angle = v.number('rotation_deg') * e * math.pi / 180;
    final back = math.cos(angle) < 0;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateY(angle),
      child: Transform(
        alignment: Alignment.center,
        transform: back ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
        child: _Card(color: back ? to : from, label: back ? tr('Back', 'Рубашка') : tr('Face', 'Лицо')),
      ),
    );
  }
  if (effect == _pgEffects[2]) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Color.lerp(from, to, k),
        borderRadius: BorderRadius.circular(
          (8 + (v.number('radius_to') - 8) * e).clamp(0.0, 500.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26 + 0.12 * k),
            blurRadius: 24 * k,
            offset: Offset(0, 12 * k),
          ),
        ],
      ),
    );
  }
  final dx = v.number('offset_px');
  final scale = v.number('scale_from') + (v.number('scale_to') - v.number('scale_from')) * e;
  return ClipRect(
    child: Center(
      child: Transform.translate(
        offset: Offset(-dx + 2 * dx * e, 0),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Color.lerp(from, to, k),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ),
  );
}
