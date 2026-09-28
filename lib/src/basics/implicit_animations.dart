// Showcase of the implicit-animation family: AnimatedAlign, AnimatedScale,
// AnimatedRotation, AnimatedOpacity, AnimatedPadding, AnimatedSlide,
// AnimatedPositioned / AnimatedPositionedDirectional, AnimatedPhysicalModel,
// plus a combined block where a single slider drives everything at once.
//
// One screen with vertical scrolling: each widget is a separate block,
// with the live element on the left, description and settings on the right.
// AnimatedSize was moved to its own screen — see animated_size.dart.

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';

class ImplicitAnimationsDemo extends StatelessWidget {
  const ImplicitAnimationsDemo({super.key});
  static String routeName = 'basics/implicit_animations';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Implicit Animations'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const _AlignBlock(),
          const SizedBox(height: 16),
          const _ScaleBlock(),
          const SizedBox(height: 16),
          const _RotationBlock(),
          const SizedBox(height: 16),
          const _OpacityBlock(),
          const SizedBox(height: 16),
          const _PaddingBlock(),
          const SizedBox(height: 16),
          const _SlideBlock(),
          const SizedBox(height: 16),
          const _PositionedBlock(),
          const SizedBox(height: 16),
          const _PhysicalModelBlock(),
          const SizedBox(height: 16),
          const _CombinedBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              delayKey: 'delay_ms',
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), _pgEffects, _pgEffects[0]),
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 600),
                BriefField.duration('delay_ms', tr('Delay', 'Задержка'), 0),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeInOut'),
                BriefField.number('offset_x_px', tr('Shift X', 'Сдвиг по X'), 120, unit: 'px'),
                BriefField.number(
                  'scale_to',
                  tr('Scale "after"', 'Масштаб «после»'),
                  1.6,
                  unit: '×',
                  min: 0,
                ),
                BriefField.number(
                  'rotation_deg',
                  tr('Rotation "after"', 'Поворот «после»'),
                  180,
                  unit: '°',
                ),
                BriefField.number(
                  'opacity_to',
                  tr('Opacity "after"', 'Прозрачность «после»'),
                  0.2,
                  min: 0,
                  max: 1,
                ),
              ],
              builder: _implicitPreview,
            ),
            items: [
              (
                tr('Which property changes', 'Какое свойство меняется'),
                tr(
                  'position, scale, rotation, opacity, padding, offset, elevation/shadow — '
                      'several at once are fine',
                  'позиция, масштаб, поворот, прозрачность, отступ, сдвиг, высота/тень — '
                      'можно несколько сразу',
                ),
              ),
              (
                tr('"Before" and "after" values', 'Значения «до» и «после»'),
                tr(
                  'scale ×, rotation in degrees or turns, opacity 0–1, padding px, '
                      'offset px or as a fraction of its own size',
                  'масштаб ×, поворот в градусах или оборотах, opacity 0–1, отступ px, '
                      'сдвиг px или в долях своего размера',
                ),
              ),
              (
                tr('Position', 'Позиция'),
                tr(
                  'where the element travels from and to: px from an edge, or alignment '
                      '(corner, center); for RTL — from the start of the line',
                  'откуда и куда едет элемент: px от края или выравнивание (угол, центр); '
                      'для RTL — от начала строки',
                ),
              ),
              (
                tr('Timing', 'Тайминг'),
                tr(
                  'duration in ms and curve: preset, cubic-bezier(…) from Figma/CSS, or '
                      'spring(stiffness, damping, mass)',
                  'длительность мс и кривая: пресет, cubic-bezier(…) из Figma/CSS или '
                      'spring(stiffness, damping, mass)',
                ),
              ),
              (
                tr('Delay', 'Задержка'),
                tr(
                  'if any — ms; for several properties — each has its own',
                  'если есть — мс; для нескольких свойств — у каждого своя',
                ),
              ),
              (
                tr('Trigger', 'Триггер'),
                tr(
                  'tap, selection, appearing on screen, or a state change',
                  'тап, выбор, появление на экране или смена состояния',
                ),
              ),
            ],
            avoid: [
              tr(
                'Shift "by the element\'s width" and "by N px" are different things — say which '
                    'one you mean',
                'Сдвиг «на ширину элемента» и «на N px» — это разное, укажи, что имеется в виду',
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

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Implicit Animations', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'The family of Animated* widgets that each animate exactly one '
                'property. Same idea as AnimatedContainer: change the value — the '
                'widget smoothly transitions to the new one on its own. Each one '
                'has its own duration and curve to configure.',
                'Семейство виджетов Animated*, которые анимируют ровно одно '
                    'свойство. Принцип тот же, что у AnimatedContainer: меняем '
                    'значение — виджет сам плавно переходит к новому. У каждого '
                    'настраивается длительность (duration) и кривая (curve).',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Drag the handles on the right in each block — the element on the '
                'left animates in real time.',
                'Двигай ручки справа в каждом блоке — элемент слева анимируется '
                    'в реальном времени.',
              ),
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sample element animated by all blocks.
class _Sample extends StatelessWidget {
  const _Sample({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: label == null
          ? null
          : Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

/// Parameters of the [_Sample] — for the "Spec".
final _sampleSpec = <String, Object?>{
  'size_px': {'width': 72, 'height': 72},
  'border_radius_px': 16,
  'color': hexColor(kAccent),
};

/// Rounding for the spec: no tails like 0.30000000004.
double _r(double v, [int digits = 2]) => double.parse(v.toStringAsFixed(digits));

// ─────────────────────────────────────────────────────────── AnimatedAlign

class _AlignBlock extends StatefulWidget {
  const _AlignBlock();
  @override
  State<_AlignBlock> createState() => _AlignBlockState();
}

class _AlignBlockState extends State<_AlignBlock> {
  double x = -1, y = -1;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedAlign',
      spec: () => {
        'widget': 'AnimatedAlign',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'alignment_x': _r(x),
        'alignment_y': _r(y),
        'position_percent': {'x': _r((x + 1) * 50, 1), 'y': _r((y + 1) * 50, 1)},
        'element': _sampleSpec,
      },
      description: tr(
        'Smoothly moves the child within its parent by changing its alignment '
        '(Alignment from -1 to 1 on each axis). Handy for "traveling" indicators, '
        'popping buttons, accents.',
        'Плавно перемещает дочерний элемент внутри родителя, меняя его '
            'выравнивание (Alignment от -1 до 1 по каждой оси). Удобно для '
            '«переезжающих» индикаторов, всплывающих кнопок, акцентов.',
      ),
      preview: AnimatedAlign(
        alignment: Alignment(x, y),
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        child: const _Sample(),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Alignment X', 'Выравнивание X'),
            value: x,
            min: -1,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => x = v),
          ),
          LabeledSlider(
            label: tr('Alignment Y', 'Выравнивание Y'),
            value: y,
            min: -1,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => y = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── AnimatedScale

class _ScaleBlock extends StatefulWidget {
  const _ScaleBlock();
  @override
  State<_ScaleBlock> createState() => _ScaleBlockState();
}

class _ScaleBlockState extends State<_ScaleBlock> {
  double scale = 1;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedScale',
      spec: () => {
        'widget': 'AnimatedScale',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'scale': _r(scale),
        'origin': 'center',
        'element': _sampleSpec,
      },
      description: tr(
        'Smoothly scales an element up or down. Good for tap reactions, a '
        '"zoomed" appearance, or drawing attention. With the elasticOut curve you '
        'get a spring effect.',
        'Плавно масштабирует элемент (увеличивает/уменьшает). Хорошо для '
            'реакции на нажатие, появления с «зумом», привлечения внимания. '
            'С кривой elasticOut получается эффект пружины.',
      ),
      preview: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        child: const _Sample(),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Scale', 'Масштаб'),
            value: scale,
            min: 0,
            max: 3,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => setState(() => scale = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── AnimatedRotation

class _RotationBlock extends StatefulWidget {
  const _RotationBlock();
  @override
  State<_RotationBlock> createState() => _RotationBlockState();
}

class _RotationBlockState extends State<_RotationBlock> {
  double turns = 0;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedRotation',
      spec: () => {
        'widget': 'AnimatedRotation',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'turns': _r(turns),
        'rotation_deg': (turns * 360).round(),
        'origin': 'center',
        'element': _sampleSpec,
      },
      description: tr(
        'Smoothly rotates an element. The value is given in "turns": '
        '0.5 = 180°, 1 = 360°. Good for disclosure arrows, spinners, and '
        'state-toggle icons.',
        'Плавно поворачивает элемент. Значение задаётся в «оборотах»: '
            '0.5 = 180°, 1 = 360°. Подходит для иконок-стрелок (раскрытие), '
            'спиннеров, переключателей состояния.',
      ),
      preview: AnimatedRotation(
        turns: turns,
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        child: const _Sample(label: '↻'),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Rotation', 'Поворот'),
            value: turns,
            min: 0,
            max: 2,
            unit: '×360°',
            fractionDigits: 2,
            onChanged: (v) => setState(() => turns = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── AnimatedOpacity

class _OpacityBlock extends StatefulWidget {
  const _OpacityBlock();
  @override
  State<_OpacityBlock> createState() => _OpacityBlockState();
}

class _OpacityBlockState extends State<_OpacityBlock> {
  double opacity = 1;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedOpacity',
      spec: () => {
        'widget': 'AnimatedOpacity',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'opacity': _r(opacity),
        'element': _sampleSpec,
      },
      description: tr(
        'Smoothly changes an element\'s opacity (0 — transparent, 1 — opaque). '
        'The basic technique for showing and hiding blocks, smooth hints, '
        'overlays.',
        'Плавно меняет прозрачность элемента (0 — прозрачный, 1 — '
            'непрозрачный). Базовый приём для появления и скрытия блоков, '
            'плавных подсказок, оверлеев.',
      ),
      preview: AnimatedOpacity(
        opacity: opacity,
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        child: const _Sample(),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Opacity', 'Прозрачность'),
            value: opacity,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => opacity = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── AnimatedPadding

class _PaddingBlock extends StatefulWidget {
  const _PaddingBlock();
  @override
  State<_PaddingBlock> createState() => _PaddingBlockState();
}

class _PaddingBlockState extends State<_PaddingBlock> {
  double padding = 8;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedPadding',
      spec: () => {
        'widget': 'AnimatedPadding',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'padding_px': padding.round(),
        'padding_sides': 'all',
        'content_color': hexColor(kAccent),
        'content_border_radius_px': 12,
        'background_color': hexColor(kAccent),
        'background_opacity': 0.12,
      },
      description: tr(
        'Smoothly changes the padding around an element. Shifts the content '
        'without jumps — useful when neighboring blocks appear, interface '
        'density changes, or a card "breathes".',
        'Плавно меняет внутренние отступы вокруг элемента. Сдвигает контент '
            'без скачков — полезно при появлении соседних блоков, изменении '
            'плотности интерфейса, «дыхании» карточек.',
      ),
      preview: Container(
        color: kAccent.withValues(alpha: 0.12),
        child: AnimatedPadding(
          padding: EdgeInsets.all(padding),
          duration: Duration(milliseconds: durationMs),
          curve: resolveCurve(curve),
          child: Container(
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Padding', 'Отступ'),
            value: padding,
            min: 0,
            max: 64,
            unit: 'px',
            onChanged: (v) => setState(() => padding = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── AnimatedSlide

class _SlideBlock extends StatefulWidget {
  const _SlideBlock();
  @override
  State<_SlideBlock> createState() => _SlideBlockState();
}

class _SlideBlockState extends State<_SlideBlock> {
  double dx = 0, dy = 0;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedSlide',
      spec: () => {
        'widget': 'AnimatedSlide',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'offset_x_fraction_of_width': _r(dx),
        'offset_y_fraction_of_height': _r(dy),
        'offset_px': {'x': (dx * 72).round(), 'y': (dy * 72).round()},
        'affects_layout': false,
        'element': _sampleSpec,
      },
      description: tr(
        'Shifts an element relative to its normal place, by a fraction of its '
        'own size: offset (1, 0) = one of its own widths to the right. '
        'Neighbors don\'t move — the element still keeps its spot in the '
        'layout. Good for sliding sheets, toasts, hints.',
        'Сдвигает элемент относительно его обычного места на долю '
            'собственного размера: offset (1, 0) = на одну свою ширину вправо. '
            'Соседи не двигаются — место в раскладке остаётся за элементом. '
            'Подходит для выезжающих плашек, тостов, подсказок.',
      ),
      preview: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Ghost(),
          AnimatedSlide(
            offset: Offset(dx, dy),
            duration: Duration(milliseconds: durationMs),
            curve: resolveCurve(curve),
            child: _Sample(label: tr('me', 'я')),
          ),
          const _Ghost(),
        ],
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Shift X (in widths)', 'Сдвиг X (в ширинах)'),
            value: dx,
            min: -2,
            max: 2,
            fractionDigits: 2,
            onChanged: (v) => setState(() => dx = v),
          ),
          LabeledSlider(
            label: tr('Shift Y (in heights)', 'Сдвиг Y (в высотах)'),
            value: dy,
            min: -1,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => dy = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

/// A semi-transparent neighbor showing that AnimatedSlide doesn't shift the layout.
class _Ghost extends StatelessWidget {
  const _Ghost();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ──────────────────────────────── AnimatedPositioned / PositionedDirectional

class _PositionedBlock extends StatefulWidget {
  const _PositionedBlock();
  @override
  State<_PositionedBlock> createState() => _PositionedBlockState();
}

class _PositionedBlockState extends State<_PositionedBlock> {
  // Position and size as fractions of the preview area.
  double x = 0.1, y = 0.2, size = 0.3;
  bool rtl = false;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: durationMs);
    final c = resolveCurve(curve);
    return AnimBlock(
      title: 'AnimatedPositioned / AnimatedPositionedDirectional',
      spec: () => {
        'widget': tr(
          'AnimatedPositioned + AnimatedPositionedDirectional (in a Stack)',
          'AnimatedPositioned + AnimatedPositionedDirectional (в Stack)',
        ),
        ...timingSpec(durationMs: durationMs, curve: curve),
        'text_direction': rtl ? 'rtl' : 'ltr',
        'position_x_fraction_of_free_space': _r(x),
        'position_y_fraction_of_free_space': _r(y),
        'size_fraction_of_preview_short_side': _r(size),
        'directional_box': {
          'widget': 'AnimatedPositionedDirectional',
          'anchor': 'start, top',
          'color': hexColor(kAccent),
          'border_radius_px': 16,
        },
        'plain_box': {
          'widget': 'AnimatedPositioned',
          'anchor': tr('left, top (Y mirrored)', 'left, top (Y зеркально)'),
          'size_scale_vs_directional': 0.7,
          'color': hexColor(Colors.orange),
          'border_radius_px': 12,
        },
      },
      description: tr(
        'Smoothly changes an element\'s position and size within a Stack (left, '
        'top, width, height). The directional version measures the offset from '
        'the "start" of the line: in right-to-left writing (Arabic, Hebrew) the '
        'purple box moves to the right edge on its own, while the plain orange '
        'one doesn\'t.',
        'Плавно меняет позицию и размер элемента внутри Stack (left, top, '
            'width, height). Directional-версия считает отступ от «начала» '
            'строки: при письме справа налево (арабский, иврит) фиолетовый '
            'блок сам переезжает к правому краю, а обычный оранжевый — нет.',
      ),
      preview: LayoutBuilder(
        builder: (context, box) {
          final side = box.biggest.shortestSide * size;
          return Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: c,
                  left: (box.maxWidth - side) * x,
                  top: (box.maxHeight - side) * (1 - y),
                  width: side * 0.7,
                  height: side * 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: c,
                  start: (box.maxWidth - side) * x,
                  top: (box.maxHeight - side) * y,
                  width: side,
                  height: side,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      controls: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Right-to-left writing (RTL)', 'Письмо справа налево (RTL)')),
            value: rtl,
            onChanged: (v) => setState(() => rtl = v),
          ),
          LabeledSlider(
            label: tr('Position X (start / left)', 'Позиция X (start / left)'),
            value: x,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => x = v),
          ),
          LabeledSlider(
            label: tr('Position Y (top)', 'Позиция Y (top)'),
            value: y,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => y = v),
          ),
          LabeledSlider(
            label: tr('Size', 'Размер'),
            value: size,
            min: 0.15,
            max: 0.6,
            fractionDigits: 2,
            onChanged: (v) => setState(() => size = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── AnimatedPhysicalModel

class _PhysicalModelBlock extends StatefulWidget {
  const _PhysicalModelBlock();
  @override
  State<_PhysicalModelBlock> createState() => _PhysicalModelBlockState();
}

class _PhysicalModelBlockState extends State<_PhysicalModelBlock> {
  double elevation = 4, radius = 16;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'AnimatedPhysicalModel',
      spec: () => {
        'widget': 'AnimatedPhysicalModel',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'elevation': elevation.round(),
        'border_radius_px': radius.round(),
        'color': hexColor(kAccent),
        'shadow_color': hexColor(Colors.black),
        'size_px': {'width': 96, 'height': 96},
      },
      description: tr(
        'Animates the "physics" of a surface: elevation above the background '
        '(→ shadow), corner radius, and color. Gives a sense of material — '
        'lifting cards, presses, transitions between elevation states.',
        'Анимирует «физику» поверхности: высоту над фоном (elevation → тень), '
            'скругление и цвет. Даёт ощущение материала — поднимающиеся карточки, '
            'нажатия, переходы между состояниями высоты.',
      ),
      preview: AnimatedPhysicalModel(
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(radius),
        elevation: elevation,
        color: kAccent,
        shadowColor: Colors.black,
        child: const SizedBox(width: 96, height: 96),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Elevation', 'Высота (elevation)'),
            value: elevation,
            min: 0,
            max: 24,
            onChanged: (v) => setState(() => elevation = v),
          ),
          LabeledSlider(
            label: tr('Corner radius', 'Скругление'),
            value: radius,
            min: 0,
            max: 48,
            unit: 'px',
            onChanged: (v) => setState(() => radius = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Combined animation

class _CombinedBlock extends StatefulWidget {
  const _CombinedBlock();
  @override
  State<_CombinedBlock> createState() => _CombinedBlockState();
}

class _CombinedBlockState extends State<_CombinedBlock> {
  double percent = 0;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    final t = percent / 100;
    final duration = Duration(milliseconds: durationMs);
    final c = resolveCurve(curve);
    double lerp(double a, double b) => a + (b - a) * t;

    return AnimBlock(
      title: tr('Combined animation', 'Комбинированная анимация'),
      spec: () => {
        'widget':
            'AnimatedAlign + AnimatedOpacity + AnimatedRotation + AnimatedScale + AnimatedContainer',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'progress_percent': percent.round(),
        'note': tr(
          'all properties: value = from + (to − from) × progress',
          'все свойства: значение = from + (to − from) × progress',
        ),
        'alignment': {'from': 'topLeft', 'to': 'bottomRight'},
        'opacity': {'from': 0.35, 'to': 1.0, 'current': _r(lerp(0.35, 1))},
        'rotation_turns': {'from': 0, 'to': 1, 'current': _r(t)},
        'scale': {'from': 0.6, 'to': 1.25, 'current': _r(lerp(0.6, 1.25))},
        'size_px': {'from': 44, 'to': 96, 'current': lerp(44, 96).round()},
        'border_radius_px': {'from': 8, 'to': 36, 'current': lerp(8, 36).round()},
        'color': {
          'from': hexColor(kAccent),
          'to': hexColor(Colors.orange),
          'current': hexColor(Color.lerp(kAccent, Colors.orange, t)!),
        },
      },
      description: tr(
        'A single progress slider (0–100%) drives several implicit widgets on '
        'one element at once: AnimatedAlign (movement), AnimatedScale (scale), '
        'AnimatedRotation (rotation), AnimatedOpacity (opacity), and '
        'AnimatedContainer (size, color, corner radius). They all animate '
        'together — that\'s how simple building blocks combine into a complex '
        'transition.',
        'Один слайдер-прогресс (0–100%) одновременно гонит сразу несколько '
            'implicit-виджетов на одном элементе: AnimatedAlign (перемещение), '
            'AnimatedScale (масштаб), AnimatedRotation (поворот), AnimatedOpacity '
            '(прозрачность) и AnimatedContainer (размер, цвет, скругление). '
            'Все они анимируются вместе — так из простых кирпичиков собирается '
            'сложный переход.',
      ),
      preview: AnimatedAlign(
        duration: duration,
        curve: c,
        alignment: Alignment.lerp(Alignment.topLeft, Alignment.bottomRight, t)!,
        child: AnimatedOpacity(
          duration: duration,
          curve: c,
          opacity: lerp(0.35, 1),
          child: AnimatedRotation(
            duration: duration,
            curve: c,
            turns: t,
            child: AnimatedScale(
              duration: duration,
              curve: c,
              scale: lerp(0.6, 1.25),
              child: AnimatedContainer(
                duration: duration,
                curve: c,
                width: lerp(44, 96),
                height: lerp(44, 96),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.lerp(kAccent, Colors.orange, t),
                  borderRadius: BorderRadius.circular(lerp(8, 36)),
                ),
                child: const Text(
                  '★',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Progress', 'Прогресс'),
            value: percent,
            min: 0,
            max: 100,
            unit: '%',
            onChanged: (v) => setState(() => percent = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        ],
      ),
    );
  }
}

List<String> get _pgEffects => [
  tr('Slide', 'Сдвиг (Slide)'),
  tr('Scale', 'Масштаб (Scale)'),
  tr('Rotation', 'Поворот (Rotation)'),
  tr('Opacity', 'Прозрачность (Opacity)'),
];

/// Playground preview: the sample moves from the initial value to the entered one.
Widget _implicitPreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  const box = _Sample();
  final effect = v.text('effect');
  final Widget moved;
  if (effect == _pgEffects[0]) {
    final dx = v.number('offset_x_px');
    moved = Transform.translate(offset: Offset(-dx / 2 + dx * e, 0), child: box);
  } else if (effect == _pgEffects[1]) {
    moved = Transform.scale(scale: 1 + (v.number('scale_to') - 1) * e, child: box);
  } else if (effect == _pgEffects[2]) {
    moved = Transform.rotate(angle: v.number('rotation_deg') * e * 3.1415926535 / 180, child: box);
  } else {
    moved = Opacity(
      opacity: (1 + (v.number('opacity_to') - 1) * e).clamp(0.0, 1.0),
      child: box,
    );
  }
  return ClipRect(child: Center(child: moved));
}
