// Showcase of animation "choreography" on a single controller:
//   • Staggered (Interval) — the card assembles itself piece by piece, each
//     piece with its own time window inside the overall animation; a timeline
//     with a playhead sits alongside;
//   • Stagger list — items appear one after another with a delay step;
//   • Keyframes (TweenSequence) — a "heartbeat": the value passes through
//     several keyframes, each with its own weight and curve on its segment.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';

class StaggeredDemo extends StatelessWidget {
  const StaggeredDemo({super.key});
  static const String routeName = 'explicit/staggered';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staggered & Keyframes'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Animation choreography', 'Хореография анимаций'),
            text: tr(
              'Complex transitions are built from simple ones: one controller '
              'sets the overall time, and Interval slices it into a window for '
              'each element. This is how screen entrances, onboarding flows, and '
              'card assembly are made. TweenSequence is keyframes, just like in '
              'After Effects.',
              'Сложные переходы собираются из простых: один контроллер '
                  'задаёт общее время, а Interval нарезает его на окна для каждого '
                  'элемента. Так делают появление экранов, онбординги, сборку '
                  'карточек. TweenSequence — это ключевые кадры, как в After Effects.',
            ),
            hint: tr(
              'All the blocks play on their own; the timeline shows who moves when.',
              'Все блоки играют сами; таймлайн показывает, кто когда двигается.',
            ),
          ),
          const SizedBox(height: 16),
          const _StaggeredCardBlock(),
          const SizedBox(height: 16),
          const _StaggerListBlock(),
          const SizedBox(height: 16),
          const _KeyframesBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              mode: PlaygroundMode.loop,
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), _pgEffects, _pgEffects[0]),
                BriefField.duration('duration_ms', tr('Total duration', 'Общая длительность'), 900),
                BriefField.duration('step_ms', tr('Delay step', 'Шаг задержки'), 90),
                BriefField.number('count', tr('Items', 'Элементов'), 6, min: 1, max: 10),
                BriefField.curve('curve', tr('Element curve', 'Кривая элемента'), 'easeOutCubic'),
                BriefField.choice('entrance', tr('Entrance', 'Вход'), _entranceOptions, _entranceOptions[0]),
                BriefField.number('offset_px', tr('Entrance distance', 'Дистанция входа'), 30, unit: 'px'),
                BriefField.number(
                  'peak1',
                  tr('Frame 1: scale', 'Кадр 1: масштаб'),
                  1.3,
                  unit: '×',
                  min: 0,
                ),
                BriefField.number(
                  'peak2',
                  tr('Frame 3: scale', 'Кадр 3: масштаб'),
                  1.18,
                  unit: '×',
                  min: 0,
                ),
              ],
              builder: _staggerPreview,
            ),
            items: [
              (
                tr('Total duration', 'Общая длительность'),
                tr('of the whole sequence, ms', 'всей последовательности, мс'),
              ),
              (
                tr('Per-element timeline', 'Таймлайн по элементам'),
                tr(
                  'for each layer: start and end in ms (or % of the total '
                      'duration) — overlaps are visible right away',
                  'для каждого слоя: старт и конец в мс (или % от общей длительности), '
                      'перекрытия видно сразу',
                ),
              ),
              (
                tr('What each element does', 'Что делает каждый элемент'),
                tr(
                  'opacity, scale ×, offset px, width px — "from" and "to", each '
                      'with its own curve',
                  'opacity, масштаб ×, сдвиг px, ширина px — «от» и «до», кривая у каждого своя',
                ),
              ),
              (
                tr('Stagger list', 'Stagger-список'),
                tr(
                  'delay step between elements in ms, duration of one element in '
                      'ms, entrance type (from bottom / from side / zoom / flip) '
                      'and by how many px',
                  'шаг задержки между элементами мс, длительность одного элемента мс, '
                      'тип входа (снизу / сбоку / зум / переворот) и на сколько px',
                ),
              ),
              (
                tr('Keyframes', 'Ключевые кадры'),
                tr(
                  'value at each keyframe + keyframe time (ms or weight) + segment curve',
                  'значение в каждом кадре + время кадра (мс или вес) + кривая отрезка',
                ),
              ),
              (
                tr('Repeat', 'Повтор'),
                tr(
                  'once, looping, or back-and-forth; pause between cycles, ms',
                  'один раз, по кругу или туда-обратно; пауза между циклами, мс',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't send just a video without numbers — a timeline from After "
                    'Effects / Figma with values works better',
                'Не присылать только видео без цифр — таймлайн из After Effects / Figma со '
                    'значениями подойдёт лучше',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Staggered (Interval)

class _Stage {
  const _Stage(this.label, this.begin, this.end, this.animates, [this.curve = 'easeOutCubic']);
  final String label;
  final double begin;
  final double end;

  /// What exactly is animated in this stage — for the "Spec".
  final Map<String, Object?> animates;

  /// Curve as a string (see motion_spec.dart).
  final String curve;
}

List<_Stage> get _stages => [
  _Stage(tr('Card background', 'Фон карточки'), 0.0, 0.3, {
    'opacity': {'from': 0, 'to': 1},
    'scale': {'from': 0.8, 'to': 1},
  }),
  _Stage(tr('Avatar', 'Аватар'), 0.2, 0.5, {
    'scale': {'from': 0, 'to': 1},
  }, 'elasticOut'),
  _Stage(tr('Title', 'Заголовок'), 0.35, 0.6, {
    'opacity': {'from': 0, 'to': 1},
    'offset_x_px': {'from': -24, 'to': 0},
  }),
  _Stage(tr('Line 1', 'Строка 1'), 0.5, 0.72, {
    'width_px': {'from': 0, 'to': 208},
  }),
  _Stage(tr('Line 2', 'Строка 2'), 0.58, 0.8, {
    'width_px': {'from': 0, 'to': 140},
  }),
  _Stage(tr('Button', 'Кнопка'), 0.75, 1.0, {
    'opacity': {'from': 0, 'to': 1},
    'offset_y_px': {'from': 16, 'to': 0},
  }, 'easeOutBack'),
];

class _StaggeredCardBlock extends StatefulWidget {
  const _StaggeredCardBlock();

  @override
  State<_StaggeredCardBlock> createState() => _StaggeredCardBlockState();
}

class _StaggeredCardBlockState extends State<_StaggeredCardBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<CurvedAnimation> _parts;
  int _durationMs = 2000;
  bool _loop = true;
  int _pauseMs = 900;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: _durationMs),
          )
          ..addStatusListener(_onStatus)
          ..forward();
    _parts = [
      for (final s in _stages)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(s.begin, s.end, curve: resolveCurve(s.curve)),
        ),
    ];
  }

  void _onStatus(AnimationStatus status) {
    if (!_loop) return;
    Future.delayed(Duration(milliseconds: _pauseMs), () {
      if (!mounted || !_loop || _controller.isAnimating) return;
      if (status == AnimationStatus.completed) _controller.reverse();
      if (status == AnimationStatus.dismissed) _controller.forward();
    });
  }

  @override
  void dispose() {
    for (final p in _parts) {
      p.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stages = _stages;
    return AnimBlock(
      title: tr('Staggered animation (Interval)', 'Staggered-анимация (Interval)'),
      spec: () => {
        'widget': 'AnimationController + CurvedAnimation(Interval) × ${stages.length}',
        'total_duration_ms': _durationMs,
        'loop': _loop
            ? tr('forward → pause → reverse → pause …', 'forward → пауза → reverse → пауза …')
            : tr('none', 'нет'),
        if (_loop) 'loop_pause_ms': _pauseMs,
        'stages': [
          for (final s in stages)
            {
              'name': s.label,
              'interval': {'begin': s.begin, 'end': s.end},
              ...timingSpec(
                durationMs: ((s.end - s.begin) * _durationMs).round(),
                curve: s.curve,
                delayMs: (s.begin * _durationMs).round(),
              ),
              'animates': s.animates,
            },
        ],
        'card': {
          'width_px': 240,
          'padding_px': 16,
          'border_radius_px': 16,
          'color': '#FFFFFF',
          'shadow': {'color': '#000000', 'opacity': 0.12, 'blur_px': 16, 'offset_y_px': 6},
          'accent': hexColor(kAccent),
        },
      },
      description: tr(
        'One animation ${_durationMs}ms long, but each part of the card lives '
        'in its own time window and with its own curve (elasticOut for the '
        'avatar, easeOutBack for the button). The windows overlap — that\'s why '
        'the motion looks fluid rather than "one after another".',
        'Одна анимация длиной ${_durationMs}мс, но каждая часть карточки '
            'живёт в своём окне времени и со своей кривой (у аватара — '
            'elasticOut, у кнопки — easeOutBack). Окна перекрываются — поэтому '
            'движение выглядит слитным, а не «по очереди».',
      ),
      preview: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _AssemblingCard(parts: [for (final p in _parts) p.value]),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Timeline', 'Таймлайн'), style: textTheme.titleSmall),
          const SizedBox(height: 8),
          _Timeline(controller: _controller),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _controller.forward(from: 0),
                icon: const Icon(Icons.play_arrow),
                label: Text(tr('Assemble', 'Собрать')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _controller.reverse(),
                icon: const Icon(Icons.fast_rewind),
                label: Text(tr('Disassemble', 'Разобрать')),
              ),
              FilterChip(
                label: Text(tr('Loop', 'Цикл')),
                selected: _loop,
                onSelected: (v) {
                  setState(() => _loop = v);
                  if (v) _onStatus(_controller.status);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LabeledSlider(
              label: tr('Scrub', 'Перемотка'),
              value: _controller.value,
              min: 0,
              max: 1,
              fractionDigits: 2,
              onChanged: (v) {
                setState(() => _loop = false);
                _controller.value = v;
              },
            ),
          ),
          LabeledSlider(
            label: tr('Total duration', 'Общая длительность'),
            value: _durationMs.toDouble(),
            min: 500,
            max: 5000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              _controller.duration = Duration(milliseconds: _durationMs);
            },
          ),
          LabeledSlider(
            label: tr('Pause between cycles', 'Пауза между циклами'),
            value: _pauseMs.toDouble(),
            min: 0,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _pauseMs = v.round()),
          ),
        ],
      ),
    );
  }
}

/// A profile card; [parts] is the progress of each stage from [_stages].
class _AssemblingCard extends StatelessWidget {
  const _AssemblingCard({required this.parts});
  final List<double> parts;

  @override
  Widget build(BuildContext context) {
    final [bg, avatar, title, line1, line2, button] = parts;
    Widget line(double t, double width) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width * t.clamp(0.0, 1.0),
        height: 10,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(5)),
      ),
    );

    return Opacity(
      opacity: bg.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.8 + 0.2 * bg,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.scale(
                    scale: avatar,
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: kAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: title.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(-24 * (1 - title), 0),
                        child: Text(
                          tr('Anna Designer', 'Анна Дизайнер'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              line(line1, 208),
              const SizedBox(height: 8),
              line(line2, 140),
              const SizedBox(height: 14),
              Opacity(
                opacity: button.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - button)),
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(tr('Follow', 'Подписаться'), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Window bars for each stage and a vertical playhead for the current moment.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            for (final s in _stages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: Text(s.label, style: small)),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final active = controller.value >= s.begin && controller.value <= s.end;
                          return SizedBox(
                            height: 14,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: c.maxWidth * s.begin,
                                  width: c.maxWidth * (s.end - s.begin),
                                  top: 2,
                                  bottom: 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: kAccent.withValues(alpha: active ? 0.9 : 0.3),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: (c.maxWidth - 2) * controller.value,
                                  width: 2,
                                  top: 0,
                                  bottom: 0,
                                  child: const ColoredBox(color: Colors.orange),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────── Stagger list

enum _Entrance { slideUp, slideLeft, scale, flip }

extension on _Entrance {
  String get label => switch (this) {
    _Entrance.slideUp => tr('From bottom', 'Снизу'),
    _Entrance.slideLeft => tr('From side', 'Сбоку'),
    _Entrance.scale => tr('Zoom', 'Зум'),
    _Entrance.flip => tr('Flip', 'Переворот'),
  };
}

class _StaggerListBlock extends StatefulWidget {
  const _StaggerListBlock();

  @override
  State<_StaggerListBlock> createState() => _StaggerListBlockState();
}

class _StaggerListBlockState extends State<_StaggerListBlock> with SingleTickerProviderStateMixin {
  static const _count = 6;
  late final AnimationController _controller;
  int _stepMs = 90;
  int _itemMs = 450;
  String _curve = 'easeOutCubic';
  _Entrance _entrance = _Entrance.slideUp;

  int get _totalMs => _itemMs + _stepMs * (_count - 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    )..forward();
  }

  void _replay() {
    _controller
      ..duration = Duration(milliseconds: _totalMs)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _item(int i) {
    final start = _stepMs * i / _totalMs;
    final end = (_stepMs * i + _itemMs) / _totalMs;
    final t = Interval(start, end, curve: resolveCurve(_curve)).transform(_controller.value);
    final tile = Container(
      height: 26,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color.lerp(kAccent, Colors.orange, i / (_count - 1)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Text(tr('Item ${i + 1}', 'Элемент ${i + 1}'), style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
    final moved = switch (_entrance) {
      _Entrance.slideUp => Transform.translate(offset: Offset(0, 30 * (1 - t)), child: tile),
      _Entrance.slideLeft => Transform.translate(offset: Offset(80 * (1 - t), 0), child: tile),
      _Entrance.scale => Transform.scale(scale: 0.6 + 0.4 * t, child: tile),
      _Entrance.flip => Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.003)
          ..rotateX(-1.4 * (1 - t)),
        child: tile,
      ),
    };
    return Opacity(opacity: t, child: moved);
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Stagger list', 'Stagger-список'),
      spec: () => {
        'widget': tr('AnimationController + Interval per element', 'AnimationController + Interval на каждый элемент'),
        'items_count': _count,
        'stagger_step_ms': _stepMs,
        'item': timingSpec(durationMs: _itemMs, curve: _curve),
        'total_duration_ms': _totalMs,
        'entrance': _entrance.name,
        'entrance_params': switch (_entrance) {
          _Entrance.slideUp => {'offset_y_px_from': 30, 'offset_y_px_to': 0},
          _Entrance.slideLeft => {'offset_x_px_from': 80, 'offset_x_px_to': 0},
          _Entrance.scale => {'scale_from': 0.6, 'scale_to': 1},
          _Entrance.flip => {
            'axis': 'X',
            'rotation_deg_from': -80,
            'rotation_deg_to': 0,
            'origin': 'topCenter',
            'perspective': 0.003,
          },
        },
        'opacity': {'from': 0, 'to': 1},
        'item_style': {
          'height_px': 26,
          'gap_px': 6,
          'border_radius_px': 8,
          'color_first': hexColor(kAccent),
          'color_last': hexColor(Colors.orange),
        },
      },
      description: tr(
        'The classic content-entrance pattern: items travel in one after '
        'another with a small step. A step of 0 ms — all at once, 60–120 ms — '
        'lively and rhythmic, 250+ ms — a slow, "ceremonial" entrance.',
        'Классика появления контента: элементы въезжают по очереди с '
            'небольшим шагом. Шаг 0 мс — все вместе, 60–120 мс — живо и '
            'ритмично, 250+ мс — медленное «торжественное» появление.',
      ),
      preview: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var i = 0; i < _count; i++) _item(i)],
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _replay,
            icon: const Icon(Icons.replay),
            label: Text(tr('Play again', 'Проиграть ещё раз')),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _Entrance.values)
                ChoiceChip(
                  label: Text(e.label),
                  selected: _entrance == e,
                  onSelected: (_) {
                    setState(() => _entrance = e);
                    _replay();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Delay step', 'Шаг задержки'),
            value: _stepMs.toDouble(),
            min: 0,
            max: 400,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _stepMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Item duration', 'Длительность элемента'),
            value: _itemMs.toDouble(),
            min: 150,
            max: 1200,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _itemMs = v.round()),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
          Text(
            tr('Sliders apply on the next play.', 'Слайдеры применяются при следующем проигрывании.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Keyframes (TweenSequence)

class _Keyframe {
  const _Keyframe(this.from, this.to, this.weight, this.curve);
  final double from;
  final double to;
  final double weight;

  /// Curve as a string (see motion_spec.dart).
  final String curve;
}

/// "Heartbeat": two beats of different strength and a pause.
const _heartbeat = [
  _Keyframe(1.0, 1.3, 12, 'easeOut'),
  _Keyframe(1.3, 1.0, 12, 'easeIn'),
  _Keyframe(1.0, 1.18, 10, 'easeOut'),
  _Keyframe(1.18, 1.0, 16, 'easeIn'),
  _Keyframe(1.0, 1.0, 50, 'linear'),
];

class _KeyframesBlock extends StatefulWidget {
  const _KeyframesBlock();

  @override
  State<_KeyframesBlock> createState() => _KeyframesBlockState();
}

class _KeyframesBlockState extends State<_KeyframesBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Color?> _color;
  int _bpm = 60;

  Duration get _period => Duration(milliseconds: (60000 / _bpm).round());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _period)..repeat();
    _scale = TweenSequence([
      for (final k in _heartbeat)
        TweenSequenceItem(
          tween: Tween(begin: k.from, end: k.to).chain(CurveTween(curve: resolveCurve(k.curve))),
          weight: k.weight,
        ),
    ]).animate(_controller);
    _color = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: kAccent, end: Colors.pink),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.pink, end: kAccent),
        weight: 38,
      ),
      TweenSequenceItem(tween: ConstantTween(kAccent), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWeight = _heartbeat.fold<double>(0, (sum, k) => sum + k.weight);
    return AnimBlock(
      title: tr('Keyframes (TweenSequence)', 'Ключевые кадры (TweenSequence)'),
      spec: () {
        final period = _period.inMilliseconds;
        var at = 0.0;
        return {
          'widget': 'AnimationController.repeat() + TweenSequence',
          'repeat': tr('infinite', 'бесконечно'),
          'period_ms': period,
          'bpm': _bpm,
          'property': 'scale',
          'keyframes': [
            for (final k in _heartbeat)
              {
                'scale_from': k.from,
                'scale_to': k.to,
                'weight': k.weight,
                ...timingSpec(
                  durationMs: (period * k.weight / totalWeight).round(),
                  curve: k.curve,
                  delayMs:
                      (period * (at += k.weight) / totalWeight - period * k.weight / totalWeight)
                          .round(),
                ),
              },
          ],
          'color_keyframes': [
            {'from': hexColor(kAccent), 'to': hexColor(Colors.pink), 'weight': 12, 'curve': 'linear'},
            {'from': hexColor(Colors.pink), 'to': hexColor(kAccent), 'weight': 38, 'curve': 'linear'},
            {'from': hexColor(kAccent), 'to': hexColor(kAccent), 'weight': 50},
          ],
          'icon_size_px': 96,
        };
      },
      description: tr(
        'The value runs through a chain of keyframes: 1 → 1.3 → 1 → 1.18 → 1 → '
        'pause. Each segment has its own weight (share of the time) and its own '
        'curve. The color changes in parallel with its own keyframes. The bar '
        'below is the frame layout over time.',
        'Значение проходит цепочку ключевых кадров: 1 → 1.3 → 1 → 1.18 → 1 → '
            'пауза. У каждого отрезка свой вес (доля времени) и своя кривая. '
            'Параллельно по своим кадрам меняется цвет. Полоса ниже — '
            'раскладка кадров по времени.',
      ),
      preview: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Transform.scale(
          scale: _scale.value,
          child: Icon(Icons.favorite, size: 96, color: _color.value),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Frames', 'Кадры'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LayoutBuilder(
              builder: (context, c) => SizedBox(
                height: 36,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (final (i, k) in _heartbeat.indexed)
                          Expanded(
                            flex: (k.weight * 10).round(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kAccent.withValues(alpha: i.isEven ? 0.35 : 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                k.from == k.to ? tr('pause', 'пауза') : '→${k.to}',
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      left: (c.maxWidth - 2) * _controller.value,
                      width: 2,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Total weight: ${totalWeight.round()} — the frame with weight 50 '
              'takes up half the cycle.',
              'Вес всего: ${totalWeight.round()} — кадр с весом 50 занимает половину цикла.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Pulse', 'Пульс'),
            value: _bpm.toDouble(),
            min: 30,
            max: 180,
            unit: tr('bpm', 'уд/мин'),
            onChanged: (v) {
              setState(() => _bpm = v.round());
              _controller
                ..duration = _period
                ..repeat();
            },
          ),
        ],
      ),
    );
  }
}

List<String> get _entranceOptions => [
  tr('from bottom', 'снизу'),
  tr('from side', 'сбоку'),
  tr('zoom', 'зум'),
];

List<String> get _pgEffects => [
  tr('Stagger list', 'Stagger-список'),
  tr('Keyframes (pulse)', 'Ключевые кадры (пульс)'),
];

/// Playground preview: a stagger list following the entered timeline, or a pulse
/// following keyframes (weights like the "heartbeat" above).
Widget _staggerPreview(BuildContext context, BriefValues v, double t) {
  final total = v.ms('duration_ms').clamp(1, 60000);
  if (v.text('effect') == _pgEffects[1]) {
    final p1 = v.number('peak1'), p2 = v.number('peak2');
    final frames = [
      (1.0, p1, 12.0, Curves.easeOut),
      (p1, 1.0, 12.0, Curves.easeIn),
      (1.0, p2, 10.0, Curves.easeOut),
      (p2, 1.0, 16.0, Curves.easeIn),
      (1.0, 1.0, 50.0, Curves.linear),
    ];
    var scale = 1.0;
    var at = 0.0;
    for (final (from, to, w, c) in frames) {
      final start = at / 100, end = (at + w) / 100;
      if (t >= start && t <= end) {
        scale = from + (to - from) * c.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
        break;
      }
      at += w;
    }
    return Transform.scale(
      scale: scale,
      child: const Icon(Icons.favorite, size: 80, color: kAccent),
    );
  }
  final count = v.number('count').round().clamp(1, 10);
  final step = v.ms('step_ms');
  final itemMs = (total - step * (count - 1)).clamp(1, total);
  final curve = v.curve('curve');
  final offset = v.number('offset_px');
  final entrance = v.text('entrance');
  final ms = t * total;
  final entranceOptions = _entranceOptions;
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Builder(
              builder: (context) {
                final start = math.min(step * i, total - itemMs);
                final local = ((ms - start) / itemMs).clamp(0.0, 1.0);
                final e = curve.transform(local);
                final tile = Container(
                  width: 180,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Color.lerp(kAccent, Colors.orange, count == 1 ? 0 : i / (count - 1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
                final moved = switch (entrance) {
                  _ when entrance == entranceOptions[1] =>
                    Transform.translate(offset: Offset(offset * (1 - e), 0), child: tile),
                  _ when entrance == entranceOptions[2] =>
                    Transform.scale(scale: 0.6 + 0.4 * e, child: tile),
                  _ => Transform.translate(offset: Offset(0, offset * (1 - e)), child: tile),
                };
                return Opacity(opacity: local, child: moved);
              },
            ),
          const SizedBox(height: 6),
          Text(
            tr('item: $itemMs ms', 'элемент: $itemMs мс'),
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
