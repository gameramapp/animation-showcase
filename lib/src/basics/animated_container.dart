// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';

/// Palette for the container fill.
const _palette = <Color>[
  Color(0xFF673AB7), // deepPurple
  Color(0xFF2196F3), // blue
  Color(0xFF009688), // teal
  Color(0xFF4CAF50), // green
  Color(0xFFFF9800), // orange
  Color(0xFFE91E63), // pink
];

/// Palette for the border (fill colors + contrasting black/white).
const _borderPalette = <Color>[
  Color(0xFF000000), // black
  Color(0xFFFFFFFF), // white
  Color(0xFF673AB7),
  Color(0xFF2196F3),
  Color(0xFF009688),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
];

class AnimatedContainerDemo extends StatefulWidget {
  const AnimatedContainerDemo({super.key});
  static String routeName = 'basics/animated_container';

  @override
  State<AnimatedContainerDemo> createState() => _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<AnimatedContainerDemo> {
  // Parameters the designer controls via the "handles".
  double width = 140;
  double height = 140;
  double borderRadius = 24;
  double rotation = 0; // in "turns": 0..1 == 0..360°
  Color color = _palette.first;
  int durationMs = 500;

  // Border.
  double borderWidth = 0;
  Color borderColor = Colors.black;

  // Shadow.
  double shadowBlur = 24;
  double shadowSpread = 0;
  double shadowOffsetY = 8;
  double shadowOpacity = 0.4;

  // Curve as a string: a Flutter preset, cubic-bezier(…) from Figma/CSS, or
  // spring(…) — see motion_spec.dart.
  String curve = 'fastOutSlowIn';

  Curve get _activeCurve => resolveCurve(curve);

  /// Current settings for the "Spec" button.
  Map<String, Object?> _spec() => {
    'widget': 'AnimatedContainer',
    ...timingSpec(durationMs: durationMs, curve: curve),
    'width_px': width.round(),
    'height_px': height.round(),
    'border_radius_px': borderRadius.round(),
    'rotation_turns': double.parse(rotation.toStringAsFixed(2)),
    'rotation_deg': (rotation * 360).round(),
    'color': hexColor(color),
    'border': borderWidth > 0
        ? {'width_px': double.parse(borderWidth.toStringAsFixed(1)), 'color': hexColor(borderColor)}
        : tr('none', 'нет'),
    'shadow': {
      'color': hexColor(color),
      'opacity': double.parse(shadowOpacity.toStringAsFixed(2)),
      'blur_px': shadowBlur.round(),
      'spread_px': shadowSpread.round(),
      'offset_x_px': 0,
      'offset_y_px': shadowOffsetY.round(),
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimatedContainer'),
        actions: const [LangButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow screen (mobile): a single scrolling column.
          if (constraints.maxWidth < 720) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _description(context),
                const SizedBox(height: 16),
                _preview(),
                const SizedBox(height: 24),
                _controls(context),
                const SizedBox(height: 24),
                _brief,
              ],
            );
          }
          // Wide screen: an always-visible preview on the left, scroll on the right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _preview(fill: true),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _description(context),
                    const SizedBox(height: 24),
                    _controls(context),
                    const SizedBox(height: 24),
                    _brief,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────── What's needed from the designer

  DesignerBrief get _brief => DesignerBrief(
    playground: BriefPlayground(
      previewHeight: 240,
      fields: [
        BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 500),
        BriefField.curve('curve', tr('Curve', 'Кривая'), 'fastOutSlowIn'),
        BriefField.number(
          'width_from',
          tr('Width "before"', 'Ширина «до»'),
          140,
          unit: 'px',
          min: 0,
          max: 400,
        ),
        BriefField.number(
          'width_to',
          tr('Width "after"', 'Ширина «после»'),
          220,
          unit: 'px',
          min: 0,
          max: 400,
        ),
        BriefField.number(
          'height_from',
          tr('Height "before"', 'Высота «до»'),
          140,
          unit: 'px',
          min: 0,
          max: 400,
        ),
        BriefField.number(
          'height_to',
          tr('Height "after"', 'Высота «после»'),
          100,
          unit: 'px',
          min: 0,
          max: 400,
        ),
        BriefField.number(
          'radius_from',
          tr('Corner radius "before"', 'Скругление «до»'),
          24,
          unit: 'px',
          min: 0,
        ),
        BriefField.number(
          'radius_to',
          tr('Corner radius "after"', 'Скругление «после»'),
          60,
          unit: 'px',
          min: 0,
        ),
        BriefField.number(
          'rotation_to_deg',
          tr('Rotation "after"', 'Поворот «после»'),
          45,
          unit: '°',
        ),
        BriefField.color('color_from', tr('Color "before"', 'Цвет «до»'), '#673AB7'),
        BriefField.color('color_to', tr('Color "after"', 'Цвет «после»'), '#FF9800'),
        BriefField.number(
          'shadow_blur',
          tr('Shadow: blur', 'Тень: blur'),
          24,
          unit: 'px',
          min: 0,
        ),
        BriefField.number(
          'shadow_offset_y',
          tr('Shadow: Y offset', 'Тень: смещение Y'),
          8,
          unit: 'px',
        ),
        BriefField.number(
          'shadow_opacity',
          tr('Shadow: opacity', 'Тень: прозрачность'),
          0.4,
          min: 0,
          max: 1,
        ),
      ],
      builder: _containerPreview,
    ),
    items: [
      (
        tr('Two frames in Figma', 'Два фрейма в Figma'),
        tr(
          '"before" and "after" with Smart Animate between them — the same layer in both',
          '«до» и «после» с Smart Animate между ними — один и тот же слой в обоих',
        ),
      ),
      (
        tr('Size and shape', 'Размер и форма'),
        tr(
          'width and height px, corner radius px, rotation in degrees — in both states',
          'ширина и высота px, скругление углов px, поворот в градусах — в обоих состояниях',
        ),
      ),
      (
        tr('Colors', 'Цвета'),
        tr(
          'fill and stroke #hex, stroke width px (0 — no stroke)',
          'заливка и обводка #hex, толщина обводки px (0 — без обводки)',
        ),
      ),
      (
        tr('Shadow', 'Тень'),
        tr(
          'blur px, spread px, X/Y offset px, color #hex and opacity 0–1',
          'blur px, spread px, смещение X/Y px, цвет #hex и прозрачность 0–1',
        ),
      ),
      (
        tr('Timing', 'Тайминг'),
        tr(
          'duration ms and curve: preset, cubic-bezier(x1, y1, x2, y2) from Figma, '
              'or spring(stiffness, damping, mass)',
          'длительность мс и кривая: пресет, cubic-bezier(x1, y1, x2, y2) из Figma или '
              'spring(stiffness, damping, mass)',
        ),
      ),
      (
        tr('Trigger', 'Триггер'),
        tr(
          'what starts the transition: tap, selection, hover, appearing; and how to go back',
          'что запускает переход: тап, выбор, hover, появление; и как вернуться обратно',
        ),
      ),
    ],
    avoid: [
      tr(
        'Different durations or curves forward/back — specify both',
        'Разные длительности или кривые туда/обратно — указать обе',
      ),
      tr(
        "Don't send just a video without numbers",
        'Не присылать только видео без цифр',
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────── Description

  Widget _description(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AnimatedContainer', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'The simplest way to animate in Flutter. We just change the '
                'container\'s properties — and it smoothly "travels" from the '
                'old value to the new one on its own. No manual timelines to set up.',
                'Самый простой способ анимации в Flutter. Мы просто меняем '
                    'свойства контейнера — а он сам плавно «переезжает» от старого '
                    'значения к новому. Никаких таймлайнов вручную настраивать не нужно.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(tr('What we can animate:', 'Что умеем анимировать:'), style: textTheme.titleSmall),
            const SizedBox(height: 4),
            _Bullet(
              tr(
                'Size — width and height (expanding/collapsing cards)',
                'Размер — ширина и высота (расширение/сжатие карточек)',
              ),
            ),
            _Bullet(
              tr('Corner radius — from a square to a circle', 'Скругление углов — от квадрата до круга'),
            ),
            _Bullet(tr('Color and background', 'Цвет и фон')),
            _Bullet(tr('Border — stroke width and color', 'Рамку — толщину и цвет обводки')),
            _Bullet(
              tr('Shadow — blur, spread, offset, opacity', 'Тень — размытие, разброс, смещение, прозрачность'),
            ),
            _Bullet(
              tr('Rotation, shift, scale (via transform)', 'Поворот, сдвиг, масштаб (через transform)'),
            ),
            const SizedBox(height: 12),
            Text(
              tr('How we tune the animation:', 'Как настраиваем анимацию:'),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            _Bullet(
              tr(
                'Duration — how fast the transition happens',
                'Длительность (duration) — насколько быстро происходит переход',
              ),
            ),
            _Bullet(
              tr(
                'Curve — the character of the motion: smooth, accelerating, with '
                'a bounce, with a "spring"',
                'Кривая (curve) — характер движения: плавно, с разгоном, '
                    'с отскоком, с «пружиной»',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('Where a designer will use this:', 'Где пригодится дизайнеру:'),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            _Bullet(tr('Cards that expand/collapse on tap', 'Карточки, которые разворачиваются/сворачиваются по тапу')),
            _Bullet(
              tr(
                'Buttons and chips that change color/shape on selection or press',
                'Кнопки и чипсы, меняющие цвет/форму при выборе или нажатии',
              ),
            ),
            _Bullet(
              tr(
                'Active states: highlight, border, shadow on the selected element',
                'Активные состояния: подсветка, рамка, тень у выбранного элемента',
              ),
            ),
            _Bullet(
              tr(
                'Blocks appearing and disappearing with a smooth size change',
                'Появление и скрытие блоков с плавным изменением размера',
              ),
            ),
            _Bullet(
              tr(
                'Switches and tabs with a "traveling" indicator',
                'Переключатели и табы с «переезжающим» индикатором',
              ),
            ),
            const SizedBox(height: 12),
            Text(tr('About curves:', 'Про кривые:'), style: textTheme.titleSmall),
            const SizedBox(height: 4),
            _Bullet(
              tr(
                'Flutter already ships 40+ ready-made curves (Curves): the ease* '
                'family (Sine/Quad/Cubic/Quart/Quint/Expo/Circ/Back), bounce* '
                '(bounce) and elastic* (spring).',
                'В Flutter уже встроено 40+ готовых кривых (Curves): семейства '
                    'ease* (Sine/Quad/Cubic/Quart/Quint/Expo/Circ/Back), bounce* '
                    '(отскок) и elastic* (пружина).',
              ),
            ),
            _Bullet(
              tr(
                'If the built-in ones aren\'t enough, define ANY custom curve with '
                'two control points: Cubic(x1, y1, x2, y2). That\'s exactly the '
                'same as cubic-bezier() in CSS. Y values can go outside 0..1 — '
                'that\'s how you get overshoot and anticipation.',
                'Если готовых не хватает — задаём ЛЮБУЮ свою кривую через две '
                    'контрольные точки: Cubic(x1, y1, x2, y2). Это ровно то же, что '
                    'cubic-bezier() в CSS. Значения Y можно выводить за пределы 0..1 — '
                    'так получаются «перелёт» (overshoot) и предварительный замах.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                'Move the handles below — the container animates to the new '
                'values in real time.',
                'Подвигай ручки ниже — контейнер анимируется к новым значениям '
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

  // ─────────────────────────────────────────────────────────── Preview

  Widget _preview({bool fill = false}) {
    return Container(
      // fill=true (wide screen) — stretch to fill the whole left panel.
      height: fill ? null : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: Duration(milliseconds: durationMs),
        curve: _activeCurve,
        width: width,
        height: height,
        transform: Matrix4.rotationZ(rotation * 2 * 3.1415926535),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderWidth > 0
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: shadowOpacity),
              blurRadius: shadowBlur,
              spreadRadius: shadowSpread,
              offset: Offset(0, shadowOffsetY),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── Handles

  Widget _controls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('Settings', 'Настройки'),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SpecButton(title: 'AnimatedContainer', spec: _spec),
          ],
        ),
        const SizedBox(height: 8),
        _slider(
          label: tr('Width', 'Ширина'),
          value: width,
          min: 40,
          max: 240,
          unit: 'px',
          onChanged: (v) => setState(() => width = v),
        ),
        _slider(
          label: tr('Height', 'Высота'),
          value: height,
          min: 40,
          max: 240,
          unit: 'px',
          onChanged: (v) => setState(() => height = v),
        ),
        _slider(
          label: tr('Corner radius', 'Скругление углов'),
          value: borderRadius,
          min: 0,
          max: 120,
          unit: 'px',
          onChanged: (v) => setState(() => borderRadius = v),
        ),
        _slider(
          label: tr('Rotation', 'Поворот'),
          value: rotation,
          min: 0,
          max: 1,
          unit: '×360°',
          fractionDigits: 2,
          onChanged: (v) => setState(() => rotation = v),
        ),
        _slider(
          label: tr('Duration', 'Длительность'),
          value: durationMs.toDouble(),
          min: 100,
          max: 2000,
          unit: tr('ms', 'мс'),
          onChanged: (v) => setState(() => durationMs = v.round()),
        ),
        const SizedBox(height: 12),
        _curveControls(context),
        const SizedBox(height: 16),
        Text(tr('Fill color', 'Цвет заливки'), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _swatchRow(
          palette: _palette,
          selected: color,
          onPick: (c) => setState(() => color = c),
        ),
        const Divider(height: 32),

        // ─── Border
        Text(tr('Border', 'Рамка'), style: Theme.of(context).textTheme.titleSmall),
        _slider(
          label: tr('Stroke width', 'Толщина обводки'),
          value: borderWidth,
          min: 0,
          max: 16,
          unit: 'px',
          onChanged: (v) => setState(() => borderWidth = v),
        ),
        const SizedBox(height: 8),
        Text(tr('Stroke color', 'Цвет обводки'), style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        _swatchRow(
          palette: _borderPalette,
          selected: borderColor,
          onPick: (c) => setState(() => borderColor = c),
        ),
        const Divider(height: 32),

        // ─── Shadow
        Text(tr('Shadow', 'Тень'), style: Theme.of(context).textTheme.titleSmall),
        _slider(
          label: tr('Blur', 'Размытие (blur)'),
          value: shadowBlur,
          min: 0,
          max: 60,
          unit: 'px',
          onChanged: (v) => setState(() => shadowBlur = v),
        ),
        _slider(
          label: tr('Spread', 'Разброс (spread)'),
          value: shadowSpread,
          min: 0,
          max: 30,
          unit: 'px',
          onChanged: (v) => setState(() => shadowSpread = v),
        ),
        _slider(
          label: tr('Downward offset', 'Смещение вниз'),
          value: shadowOffsetY,
          min: -30,
          max: 30,
          unit: 'px',
          onChanged: (v) => setState(() => shadowOffsetY = v),
        ),
        _slider(
          label: tr('Opacity', 'Прозрачность'),
          value: shadowOpacity,
          min: 0,
          max: 1,
          unit: '',
          fractionDigits: 2,
          onChanged: (v) => setState(() => shadowOpacity = v),
        ),
      ],
    );
  }

  /// A row of round color swatches with the selected one highlighted.
  Widget _swatchRow({
    required List<Color> palette,
    required Color selected,
    required ValueChanged<Color> onPick,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in palette)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black26,
                  width: selected == c ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────── Curve controls

  Widget _curveControls(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Flutter presets + "Custom…": cubic-bezier with handles, or a spring.
        CurveDropdown(value: curve, onChanged: (v) => setState(() => curve = v)),
        const SizedBox(height: 4),
        Text(
          tr(
            'For a custom curve, use the "Custom: cubic-bezier / spring…" option, '
            'or the button on the right: drag the handles or paste a '
            'cubic-bezier(…) from Figma / CSS. Y values outside 0..1 give the '
            'overshoot and spring effect. For example '
            'cubic-bezier(0.68, -0.55, 0.27, 1.55) is "back, with a bounce."',
            'Своя кривая — пункт «Своя: cubic-bezier / пружина…» или кнопка '
                'справа: тяни ручки или вставь cubic-bezier(…) из Figma / CSS. '
                'Значения Y вне 0..1 дают эффект перелёта и пружины. Например '
                'cubic-bezier(0.68, -0.55, 0.27, 1.55) — «назад и с отскоком».',
          ),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    int fractionDigits = 0,
  }) {
    return LabeledSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      unit: unit,
      fractionDigits: fractionDigits,
      onChanged: onChanged,
    );
  }
}

/// A bulleted list item for the description block.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Playground preview: the container moves from the "before" frame to the "after" frame.
Widget _containerPreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  double l(String a, String b) => v.number(a) + (v.number(b) - v.number(a)) * e;
  final color = Color.lerp(v.color('color_from'), v.color('color_to'), e.clamp(0.0, 1.0))!;
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox.square(
      dimension: 420,
      child: Center(
        child: Transform.rotate(
          angle: v.number('rotation_to_deg') * e * 3.1415926535 / 180,
          child: Container(
            width: l('width_from', 'width_to').clamp(0.0, 1000.0),
            height: l('height_from', 'height_to').clamp(0.0, 1000.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(l('radius_from', 'radius_to').clamp(0.0, 1000.0)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: v.number('shadow_opacity').clamp(0.0, 1.0)),
                  blurRadius: v.number('shadow_blur').clamp(0.0, 200.0),
                  offset: Offset(0, v.number('shadow_offset_y')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
