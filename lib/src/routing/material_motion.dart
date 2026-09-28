// Material Motion screen — official patterns from the `animations` package:
//   • OpenContainer        — container transform (card → page);
//   • SharedAxisTransition  — shared axis X / Y / Z (via PageTransitionSwitcher);
//   • FadeThroughTransition — fade through (same widget);
//   • showModal + FadeScaleTransitionConfiguration — a fade + scale modal.

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import 'section_card.dart';

const _accent = Color(0xFF673AB7);

class MaterialMotionDemo extends StatelessWidget {
  const MaterialMotionDemo({super.key});
  static const String routeName = 'routing/material_motion';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Motion'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const _ContainerTransformSection(),
          const SizedBox(height: 16),
          const _InPlaceSection(),
          const SizedBox(height: 16),
          const _FadeScaleSection(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.choice(
                  'effect',
                  tr('Pattern', 'Паттерн'),
                  _pgEffects,
                  'Container transform',
                ),
                BriefField.duration(
                  'duration_ms',
                  tr('Duration', 'Длительность'),
                  450,
                ),
                BriefField.color(
                  'closed_color',
                  tr('Card color', 'Цвет карточки'),
                  '#673AB7',
                ),
                BriefField.number(
                  'closed_radius_px',
                  tr('Card corner radius', 'Скругление карточки'),
                  16,
                  unit: 'px',
                  min: 0,
                ),
              ],
              builder: _motionPreview,
            ),
            items: [
              (
                tr('Pattern', 'Паттерн'),
                tr(
                  'container transform / shared axis X·Y·Z / fade through / fade-scale modal — '
                      'by name from Material Motion',
                  'container transform / shared axis X·Y·Z / fade through / fade-scale модалка — '
                      'по названию из Material Motion',
                ),
              ),
              (
                tr('Duration, ms', 'Длительность, мс'),
                tr(
                  'opening and closing; if closing has a different length — both numbers',
                  'открытие и закрытие; если закрытие другой длины — обе цифры',
                ),
              ),
              (
                tr('Container transform', 'Container transform'),
                tr(
                  '"closed" and "open" frames in Figma: #hex color, corner radius in px, '
                      'elevation; type fade or fadeThrough',
                  'фрейм «закрыто» и «открыто» в Figma: цвет #hex, скругление px, '
                      'elevation; тип fade или fadeThrough',
                ),
              ),
              (
                tr('Shared axis / fade through', 'Shared axis / fade through'),
                tr(
                  'axis (X, Y or Z) and "forward/back" direction; what changes — steps, '
                      'tabs or sections',
                  'ось (X, Y или Z) и направление «вперёд/назад»; что меняется — шаги, '
                      'вкладки или разделы',
                ),
              ),
              (
                tr('Modal', 'Модалка'),
                tr(
                  'what opens (dialog, menu, FAB surface) and the backdrop color/opacity',
                  'что открывается (диалог, меню, FAB-поверхность) и цвет/прозрачность подложки',
                ),
              ),
              (
                tr('Trigger', 'Триггер'),
                tr(
                  'tap on a card, a "next" button, a tab switch, etc.',
                  'тап по карточке, кнопка «далее», смена вкладки и т.п.',
                ),
              ),
            ],
            avoid: [
              tr(
                "These patterns' curves and offsets are baked in by the Material spec — "
                    'you can send your own curve, but that\'s already a custom transition '
                    '(see "Transitions Playground")',
                'Кривые и сдвиги у этих паттернов зашиты по Material-спеке — свою '
                    'кривую прислать можно, но это уже кастомный переход (см. «Песочницу переходов»)',
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
            Text('Material Motion', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'Official Material 3 motion patterns from the animations '
                    'package: container transform, shared axis, fade through, '
                    'and a fade-scale modal. Ready-made transitions, verified '
                    'against the spec.',
                'Официальные паттерны движения Material 3 из пакета animations: '
                    'container transform, shared axis, fade through и fade-scale '
                    'модалка. Готовые, выверенные по спецификации переходы.',
              ),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────── OpenContainer (container transform)

class _ContainerTransformSection extends StatefulWidget {
  const _ContainerTransformSection();
  @override
  State<_ContainerTransformSection> createState() =>
      _ContainerTransformSectionState();
}

class _ContainerTransformSectionState
    extends State<_ContainerTransformSection> {
  ContainerTransitionType type = ContainerTransitionType.fade;
  int durationMs = 450;
  double radius = 16;

  @override
  Widget build(BuildContext context) {
    return RoutingSection(
      title: 'Container transform (OpenContainer)',
      description: tr(
        'A closed element (card, tile, FAB) smoothly expands into a full '
            'page on tap and collapses back. The content transition type is '
            'fade or fadeThrough.',
        'Закрытый элемент (карточка, тайл, FAB) по тапу плавно разворачивается '
            'в целую страницу и сворачивается обратно. Тип перехода контента — '
            'fade или fadeThrough.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ContainerTransitionType>(
            segments: const [
              ButtonSegment(
                value: ContainerTransitionType.fade,
                label: Text('fade'),
              ),
              ButtonSegment(
                value: ContainerTransitionType.fadeThrough,
                label: Text('fadeThrough'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Card corner radius', 'Скругление карточки'),
            value: radius,
            min: 0,
            max: 36,
            unit: 'px',
            onChanged: (v) => setState(() => radius = v),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SpecButton(
              title: 'Container transform (OpenContainer)',
              spec: () => {
                'widget': 'OpenContainer (package:animations)',
                'transition_type': type.name,
                'open': timingSpec(
                  durationMs: durationMs,
                  curve: 'fastOutSlowIn',
                ),
                'close': timingSpec(
                  durationMs: durationMs,
                  curve: 'fastOutSlowIn',
                ),
                'curve_note': tr(
                  'curve is baked into OpenContainer (Material standard)',
                  'кривая зашита в OpenContainer (Material standard)',
                ),
                'closed': {
                  'color': hexColor(_accent),
                  'elevation': 2,
                  'border_radius_px': radius.round(),
                  'height_px': 72,
                },
                'open_state': {
                  'color': '#FFFFFF',
                  'elevation': 4,
                  'border_radius_px': 0,
                  'is': tr('a fullscreen page', 'полноэкранная страница'),
                },
                'content_fade': type == ContainerTransitionType.fade
                    ? tr(
                        'fade: new content appears on top of the old one',
                        'fade: новый контент проявляется поверх старого',
                      )
                    : tr(
                        'fadeThrough: the old one fades out, then the new one appears',
                        'fadeThrough: старый гаснет, затем проявляется новый',
                      ),
              },
            ),
          ),
          const SizedBox(height: 8),
          OpenContainer(
            transitionType: type,
            transitionDuration: Duration(milliseconds: durationMs),
            closedColor: _accent,
            closedElevation: 2,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radius)),
            ),
            closedBuilder: (context, openContainer) => SizedBox(
              height: 72,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.photo, color: Colors.white),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      tr('Open the card', 'Открыть карточку'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
            openBuilder: (context, closeContainer) => const _OpenedPage(),
          ),
        ],
      ),
    );
  }
}

class _OpenedPage extends StatelessWidget {
  const _OpenedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Expanded page', 'Развёрнутая страница'))),
      body: ListView(
        children: [
          Container(
            height: 200,
            color: _accent,
            child: const Center(
              child: Icon(Icons.photo, color: Colors.white, size: 80),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr(
                'The card expanded into a full page in one motion '
                    '(container transform). Back — the reverse collapse.',
                'Карточка развернулась в целую страницу единым движением '
                    '(container transform). Назад — обратное сворачивание.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── PageTransitionSwitcher (shared axis / fade through)

enum _InPlace { sharedX, sharedY, sharedZ, fadeThrough }

class _InPlaceSection extends StatefulWidget {
  const _InPlaceSection();
  @override
  State<_InPlaceSection> createState() => _InPlaceSectionState();
}

class _InPlaceSectionState extends State<_InPlaceSection> {
  _InPlace kind = _InPlace.sharedX;
  int step = 0;
  int durationMs = 450;

  static const _steps = [
    (icon: Icons.looks_one, color: Color(0xFF673AB7)),
    (icon: Icons.looks_two, color: Color(0xFF009688)),
    (icon: Icons.looks_3, color: Color(0xFFE91E63)),
  ];

  Widget _transition(
    Widget child,
    Animation<double> primary,
    Animation<double> secondary,
  ) {
    if (kind == _InPlace.fadeThrough) {
      return FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        child: child,
      );
    }
    return SharedAxisTransition(
      animation: primary,
      secondaryAnimation: secondary,
      transitionType: switch (kind) {
        _InPlace.sharedX => SharedAxisTransitionType.horizontal,
        _InPlace.sharedY => SharedAxisTransitionType.vertical,
        _ => SharedAxisTransitionType.scaled,
      },
      child: child,
    );
  }

  Map<String, Object?> _spec() => {
    'widget':
        'PageTransitionSwitcher + '
        '${kind == _InPlace.fadeThrough ? 'FadeThroughTransition' : 'SharedAxisTransition'}'
        ' (package:animations)',
    'type': switch (kind) {
      _InPlace.sharedX => 'shared axis X (horizontal)',
      _InPlace.sharedY => 'shared axis Y (vertical)',
      _InPlace.sharedZ => 'shared axis Z (scaled)',
      _InPlace.fadeThrough => 'fade through',
    },
    'duration_ms': durationMs,
    'curve_note': tr(
      'curves and intervals are baked in per the Material spec',
      'кривые и интервалы зашиты по Material-спеке',
    ),
    ...switch (kind) {
      _InPlace.fadeThrough => {
        'outgoing': {
          'opacity': {'from': 1, 'to': 0},
          'interval': '0–30%',
          ...timingSpec(
            durationMs: (durationMs * 0.3).round(),
            curve: 'cubic-bezier(0.4, 0, 1, 1)',
          ),
        },
        'incoming': {
          'opacity': {'from': 0, 'to': 1},
          'scale': {'from': 0.92, 'to': 1},
          'interval': '30–100%',
          ...timingSpec(
            durationMs: (durationMs * 0.7).round(),
            curve: 'cubic-bezier(0, 0, 0.2, 1)',
            delayMs: (durationMs * 0.3).round(),
          ),
        },
      },
      _InPlace.sharedZ => {
        'outgoing': {
          'scale': {'from': 1, 'to': 1.1},
          'fade_out_interval': '0–30%',
        },
        'incoming': {
          'scale': {'from': 0.8, 'to': 1},
          'fade_in_interval': '30–100%',
        },
        'scale_curve': timingSpec(
          durationMs: durationMs,
          curve: 'fastOutSlowIn',
        ),
      },
      _ => {
        'axis': kind == _InPlace.sharedX ? 'X' : 'Y',
        'offset_px': 30,
        'outgoing': {
          'offset_px': {'from': 0, 'to': -30},
          'fade_out_interval': '0–30%',
        },
        'incoming': {
          'offset_px': {'from': 30, 'to': 0},
          'fade_in_interval': '30–100%',
        },
        'offset_curve': timingSpec(
          durationMs: durationMs,
          curve: 'fastOutSlowIn',
        ),
      },
    },
    'element': {
      'height_px': 120,
      'border_radius_px': 16,
      'colors': [for (final st in _steps) hexColor(st.color)],
    },
  };

  @override
  Widget build(BuildContext context) {
    final current = _steps[step % _steps.length];
    return RoutingSection(
      title: 'Shared axis / Fade through (PageTransitionSwitcher)',
      description: tr(
        'Animated in-place content replacement. Shared axis (X/Y/Z) — for '
            'wizard steps and tabs; fade through — for switching between '
            'unrelated sections. Press "Next step".',
        'Анимированная подмена контента на месте. Shared axis (X/Y/Z) — для '
            'шагов визарда и вкладок; fade through — для смены несвязанных '
            'разделов. Жми «Следующий шаг».',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<_InPlace>(
            isExpanded: true,
            value: kind,
            items: [
              DropdownMenuItem(
                value: _InPlace.sharedX,
                child: Text(
                  tr(
                    'Shared axis X (horizontal)',
                    'Shared axis X (горизонталь)',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: _InPlace.sharedY,
                child: Text(
                  tr('Shared axis Y (vertical)', 'Shared axis Y (вертикаль)'),
                ),
              ),
              DropdownMenuItem(
                value: _InPlace.sharedZ,
                child: Text(
                  tr('Shared axis Z (scale)', 'Shared axis Z (масштаб)'),
                ),
              ),
              const DropdownMenuItem(
                value: _InPlace.fadeThrough,
                child: Text('Fade through'),
              ),
            ],
            onChanged: (v) => setState(() => kind = v ?? kind),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SpecButton(title: 'Shared axis / Fade through', spec: _spec),
          ),
          PageTransitionSwitcher(
            duration: Duration(milliseconds: durationMs),
            transitionBuilder: _transition,
            child: Container(
              key: ValueKey(step),
              width: double.infinity,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: current.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(current.icon, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() => step++),
              icon: const Icon(Icons.skip_next),
              label: Text(tr('Next step', 'Следующий шаг')),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────── showModal + FadeScaleTransitionConfiguration

class _FadeScaleSection extends StatefulWidget {
  const _FadeScaleSection();
  @override
  State<_FadeScaleSection> createState() => _FadeScaleSectionState();
}

class _FadeScaleSectionState extends State<_FadeScaleSection> {
  int durationMs = 150;
  int reverseMs = 75;

  @override
  Widget build(BuildContext context) {
    return RoutingSection(
      title: 'Fade scale modal (showModal)',
      description: tr(
        'A modal layer appearing/closing per the Material spec: fade + a '
            'light scale. For dialogs, menus, FAB surfaces.',
        'Появление/закрытие модального слоя по Material-спеке: затухание + '
            'лёгкий масштаб. Для диалогов, меню, FAB-поверхностей.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Closing duration', 'Длительность закрытия'),
            value: reverseMs.toDouble(),
            min: 50,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => reverseMs = v.round()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => showModal<void>(
                  context: context,
                  configuration: FadeScaleTransitionConfiguration(
                    transitionDuration: Duration(milliseconds: durationMs),
                    reverseTransitionDuration: Duration(
                      milliseconds: reverseMs,
                    ),
                  ),
                  builder: (context) => AlertDialog(
                    title: const Text('Fade + Scale'),
                    content: Text(
                      tr(
                        'This modal appeared with a fade and a light scale, '
                            'via showModal + FadeScaleTransitionConfiguration.',
                        'Эта модалка появилась с затуханием и лёгким масштабированием '
                            'через showModal + FadeScaleTransitionConfiguration.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(tr('Close', 'Закрыть')),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.open_in_full),
                label: Text(tr('Show modal', 'Показать модалку')),
              ),
              SpecButton(
                title: 'Fade scale modal (showModal)',
                spec: () => {
                  'widget':
                      'showModal + FadeScaleTransitionConfiguration (package:animations)',
                  'open': {
                    'duration_ms': durationMs,
                    'opacity': {
                      'from': 0,
                      'to': 1,
                      'interval': '0–30%',
                      'curve': 'linear',
                    },
                    'scale': {
                      'from': 0.8,
                      'to': 1,
                      ...timingSpec(
                        durationMs: durationMs,
                        curve: 'cubic-bezier(0, 0, 0.2, 1)',
                      ),
                    },
                  },
                  'close': {
                    'duration_ms': reverseMs,
                    'opacity': {'from': 1, 'to': 0, 'curve': 'linear'},
                    'scale': tr('no change', 'без изменения'),
                  },
                  'barrier_color': '#000000',
                  'barrier_opacity': 0.54,
                  'barrier_dismissible': true,
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<String> get _pgEffects => [
  'Container transform',
  'Shared axis X',
  'Fade through',
  tr('Fade scale modal', 'Fade scale модалка'),
];

/// Playground preview: a Material Motion pattern with its "baked-in" curves,
/// duration, and card — using the entered values.
Widget _motionPreview(BuildContext context, BriefValues v, double t) {
  const w = 120.0, h = 190.0;
  final color = v.color('closed_color');
  final radius = v.number('closed_radius_px');
  const standard = Curves.fastOutSlowIn;
  const decelerate = Cubic(0, 0, 0.2, 1);
  const accelerate = Cubic(0.4, 0, 1, 1);
  double interval(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
  Widget page(Color c, IconData icon) => Container(
    width: w,
    height: h,
    color: Colors.white,
    alignment: Alignment.center,
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );

  final Widget content;
  switch (v.text('effect')) {
    case 'Shared axis X':
      final e = standard.transform(t);
      content = Stack(
        children: [
          Opacity(
            opacity: 1 - accelerate.transform(interval(0, 0.3)),
            child: Transform.translate(
              offset: Offset(-30 * e, 0),
              child: page(color, Icons.looks_one),
            ),
          ),
          Opacity(
            opacity: decelerate.transform(interval(0.3, 1)),
            child: Transform.translate(
              offset: Offset(30 * (1 - e), 0),
              child: page(const Color(0xFF009688), Icons.looks_two),
            ),
          ),
        ],
      );
    case 'Fade through':
      final k = decelerate.transform(interval(0.3, 1));
      content = Stack(
        children: [
          Opacity(
            opacity: 1 - accelerate.transform(interval(0, 0.3)),
            child: page(color, Icons.looks_one),
          ),
          Opacity(
            opacity: k,
            child: Transform.scale(
              scale: 0.92 + 0.08 * k,
              child: page(const Color(0xFF009688), Icons.looks_two),
            ),
          ),
        ],
      );
    case _
        when v.text('effect') == tr('Fade scale modal', 'Fade scale модалка'):
      final fade = interval(0, 0.3);
      content = Stack(
        alignment: Alignment.center,
        children: [
          page(color, Icons.photo),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.54 * fade),
            ),
          ),
          Opacity(
            opacity: fade,
            child: Transform.scale(
              scale: 0.8 + 0.2 * decelerate.transform(t),
              child: Container(
                width: 96,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius.clamp(0.0, 32.0)),
                ),
              ),
            ),
          ),
        ],
      );
    default:
      final e = standard.transform(t);
      final rect = Rect.lerp(
        const Rect.fromLTWH(12, h - 12 - 40, w - 24, 40),
        const Rect.fromLTWH(0, 0, w, h),
        e,
      )!;
      content = Stack(
        children: [
          Container(width: w, height: h, color: Colors.white),
          Positioned.fromRect(
            rect: rect,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.lerp(color, Colors.white, interval(0.2, 0.6)),
                borderRadius: BorderRadius.circular(
                  (radius * (1 - e)).clamp(0.0, 1000.0),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 1 - interval(0, 0.3),
                    child: const Center(
                      child: Icon(Icons.photo, color: Colors.white, size: 18),
                    ),
                  ),
                  Opacity(
                    opacity: interval(0.3, 1),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(height: 70, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Container(
      width: w,
      height: h,
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black87, width: 3),
      ),
      child: content,
    ),
  );
}
