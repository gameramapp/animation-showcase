// Showcase of the last "text and theme" implicit animations:
//   • AnimatedDefaultTextStyle — smoothly changes the text style (size, weight,
//     color, letter spacing, slant, underline);
//   • AnimatedTheme — smoothly transitions between ThemeData: all child widgets
//     (buttons, chips, switches, background) change colors in sync.

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';

class TextThemeAnimationsDemo extends StatelessWidget {
  const TextThemeAnimationsDemo({super.key});
  static String routeName = 'basics/text_theme';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text & Theme'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const _DefaultTextStyleBlock(),
          const SizedBox(height: 16),
          const _ThemeBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.choice(
                  'effect',
                  tr('Effect', 'Эффект'),
                  _effectOptions,
                  _effectOptions[0],
                ),
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 500),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeInOut'),
                BriefField.number(
                  'font_size_from',
                  tr('Size "before"', 'Кегль «до»'),
                  24,
                  unit: 'px',
                  min: 1,
                  max: 120,
                ),
                BriefField.number(
                  'font_size_to',
                  tr('Size "after"', 'Кегль «после»'),
                  40,
                  unit: 'px',
                  min: 1,
                  max: 120,
                ),
                BriefField.number(
                  'letter_spacing_to',
                  tr('Tracking "after"', 'Трекинг «после»'),
                  4,
                  unit: 'px',
                ),
                BriefField.color('color_from', tr('Color / seed "before"', 'Цвет / seed «до»'), '#673AB7'),
                BriefField.color('color_to', tr('Color / seed "after"', 'Цвет / seed «после»'), '#E91E63'),
                BriefField.choice(
                  'brightness_to',
                  tr('Theme "after"', 'Тема «после»'),
                  _brightnessOptions,
                  _brightnessOptions[1],
                ),
              ],
              builder: _textThemePreview,
            ),
            items: [
              (
                tr('Text style "before" and "after"', 'Стиль текста «до» и «после»'),
                tr(
                  'font size px, tracking px, color #hex, background #hex + opacity',
                  'кегль px, трекинг px, цвет #hex, подложка #hex + прозрачность',
                ),
              ),
              (
                tr('Text shadow', 'Тень текста'),
                tr(
                  'blur px, X/Y offset px, color #hex and opacity',
                  'blur px, смещение X/Y px, цвет #hex и прозрачность',
                ),
              ),
              (
                tr('Theme', 'Тема'),
                tr(
                  'seed color #hex (or a ready palette primary / surface / '
                      'onSurface) and light/dark',
                  'seed-цвет #hex (или готовая палитра primary / surface / onSurface) и '
                      'светлая/тёмная',
                ),
              ),
              (
                tr('Timing', 'Тайминг'),
                tr(
                  'duration ms and curve: preset, cubic-bezier(…), or spring(…)',
                  'длительность мс и кривая: пресет, cubic-bezier(…) или spring(…)',
                ),
              ),
              (
                tr('Trigger', 'Триггер'),
                tr(
                  'selection, focus, scrolling to a heading, theme toggle',
                  'выбор, фокус, скролл до заголовка, переключатель темы',
                ),
              ),
            ],
            avoid: [
              tr(
                "Changing the font or weight doesn't animate smoothly — it will jump",
                'Смена шрифта и насыщенности (weight) не анимируется плавно — будет скачок',
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
            Text('Text & Theme', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'The last two of the implicit-animation family. '
                'AnimatedDefaultTextStyle smoothly changes the text style, '
                'AnimatedTheme changes an entire theme: you change a value, and '
                'the widgets flow to the new state on their own. Turn the handles '
                'on the right.',
                'Последние из семейства implicit-анимаций. '
                    'AnimatedDefaultTextStyle плавно меняет стиль текста, '
                    'AnimatedTheme — целую тему оформления: меняешь значение, а '
                    'виджеты сами перетекают к новому состоянию. Крути ручки справа.',
              ),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── palette for both blocks

List<(String, Color)> get _swatches => [
  (tr('Purple', 'Фиолетовый'), const Color(0xFF673AB7)),
  (tr('Teal', 'Бирюзовый'), const Color(0xFF009688)),
  (tr('Pink', 'Розовый'), const Color(0xFFE91E63)),
  (tr('Orange', 'Оранжевый'), const Color(0xFFFF9800)),
];

/// A row of selectable color circles.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final swatches = _swatches;
    return Row(
      children: [
        for (var i = 0; i < swatches.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(i),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: swatches[i].$2,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected == i ? Colors.black87 : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────── AnimatedDefaultTextStyle

class _DefaultTextStyleBlock extends StatefulWidget {
  const _DefaultTextStyleBlock();
  @override
  State<_DefaultTextStyleBlock> createState() => _DefaultTextStyleBlockState();
}

class _DefaultTextStyleBlockState extends State<_DefaultTextStyleBlock> {
  double fontSize = 24;
  double letterSpacing = 0;
  double shadowBlur = 0;
  int colorIndex = 0;
  bool highlight = false;
  int durationMs = 500;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    final swatches = _swatches;
    final color = swatches[colorIndex].$2;
    final sampleWord = tr('Design', 'Дизайн');
    return AnimBlock(
      title: 'AnimatedDefaultTextStyle',
      spec: () => {
        'widget': 'AnimatedDefaultTextStyle',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'text': sampleWord,
        'font_size_px': fontSize.round(),
        'letter_spacing_px': double.parse(letterSpacing.toStringAsFixed(1)),
        'color': hexColor(color),
        'color_name': swatches[colorIndex].$1,
        'background': highlight ? {'color': hexColor(color), 'opacity': 0.22} : tr('none', 'нет'),
        'text_shadow': shadowBlur > 0
            ? {
                'color': '#000000',
                'opacity': 0.54,
                'blur_px': shadowBlur.round(),
                'offset_x_px': 0,
                'offset_y_px': double.parse((shadowBlur / 3).toStringAsFixed(1)),
              }
            : tr('none', 'нет'),
      },
      description: tr(
        'Smoothly animates a text style change. Font size, color, tracking '
        '(letterSpacing), shadows and background color (backgroundColor) are '
        'all continuously interpolated — and those are what we\'re turning '
        'here. Indispensable for accents and "coming alive" headings with no jumps.',
        'Плавно анимирует стиль текста при его смене. Непрерывно '
            'интерполируются размер (fontSize), цвет, трекинг (letterSpacing), '
            'тень (shadows) и подложка (backgroundColor) — их и крутим. '
            'Незаменимо для акцентов и «оживающих» заголовков без скачков.',
      ),
      preview: AnimatedDefaultTextStyle(
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        style: TextStyle(
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          color: color,
          backgroundColor: highlight
              ? color.withValues(alpha: 0.22)
              : Colors.transparent,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: shadowBlur,
              offset: Offset(0, shadowBlur / 3),
            ),
          ],
        ),
        child: Text(sampleWord),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            label: tr('Size', 'Размер'),
            value: fontSize,
            min: 12,
            max: 56,
            unit: 'px',
            onChanged: (v) => setState(() => fontSize = v),
          ),
          LabeledSlider(
            label: tr('Tracking (letterSpacing)', 'Трекинг (letterSpacing)'),
            value: letterSpacing,
            min: -2,
            max: 12,
            fractionDigits: 1,
            onChanged: (v) => setState(() => letterSpacing = v),
          ),
          LabeledSlider(
            label: tr('Shadow (blur)', 'Тень (размытие)'),
            value: shadowBlur,
            min: 0,
            max: 24,
            unit: 'px',
            onChanged: (v) => setState(() => shadowBlur = v),
          ),
          const SizedBox(height: 8),
          Text(tr('Color', 'Цвет'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          _SwatchRow(
            selected: colorIndex,
            onChanged: (i) => setState(() => colorIndex = i),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Background (backgroundColor)', 'Подложка (backgroundColor)')),
            value: highlight,
            onChanged: (v) => setState(() => highlight = v),
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

// ─────────────────────────────────────────────────────────── AnimatedTheme

class _ThemeBlock extends StatefulWidget {
  const _ThemeBlock();
  @override
  State<_ThemeBlock> createState() => _ThemeBlockState();
}

class _ThemeBlockState extends State<_ThemeBlock> {
  int seedIndex = 0;
  bool dark = false;
  int durationMs = 600;
  String curve = 'easeInOut';

  @override
  Widget build(BuildContext context) {
    final swatches = _swatches;
    final theme = ThemeData(
      colorSchemeSeed: swatches[seedIndex].$2,
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    return AnimBlock(
      title: 'AnimatedTheme',
      spec: () => {
        'widget': 'AnimatedTheme',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'theme': 'ThemeData(colorSchemeSeed, brightness) — Material 3',
        'seed_color': hexColor(swatches[seedIndex].$2),
        'seed_color_name': swatches[seedIndex].$1,
        'brightness': dark ? 'dark' : 'light',
        'resulting_colors': {
          'primary': hexColor(theme.colorScheme.primary),
          'on_primary': hexColor(theme.colorScheme.onPrimary),
          'surface': hexColor(theme.colorScheme.surface),
          'on_surface': hexColor(theme.colorScheme.onSurface),
          'outline_variant': hexColor(theme.colorScheme.outlineVariant),
        },
      },
      description: tr(
        'Smoothly flows between ThemeData. Change the seed color or the '
        'brightness — and the whole UI below (buttons, chips, switches, '
        'background, text) travels to the new colors in sync. Perfect for a '
        'brand-palette change or a soft transition into dark mode.',
        'Плавно перетекает между ThemeData. Меняешь seed-цвет или яркость — '
            'и весь UI ниже (кнопки, чипы, переключатели, фон, текст) синхронно '
            'переезжает в новые цвета. Идеально для смены бренд-палитры и мягкого '
            'перехода в тёмную тему.',
      ),
      preview: AnimatedTheme(
        data: theme,
        duration: Duration(milliseconds: durationMs),
        curve: resolveCurve(curve),
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        tr('Heading', 'Заголовок'),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(onPressed: () {}, child: Text(tr('Button', 'Кнопка'))),
                      OutlinedButton(
                        onPressed: () {},
                        child: Text(tr('Outline', 'Контур')),
                      ),
                      Chip(label: const Text('Chip')),
                      Switch(value: true, onChanged: (_) {}),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Seed color', 'Seed-цвет'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          _SwatchRow(
            selected: seedIndex,
            onChanged: (i) => setState(() => seedIndex = i),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Dark theme', 'Тёмная тема')),
            value: dark,
            onChanged: (v) => setState(() => dark = v),
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

List<String> get _effectOptions => [tr('Text style', 'Стиль текста'), tr('Theme', 'Тема')];

List<String> get _brightnessOptions => [tr('light', 'светлая'), tr('dark', 'тёмная')];

/// Playground preview: the text style or theme transitions to the entered values.
Widget _textThemePreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final k = e.clamp(0.0, 1.0);
  if (v.text('effect') == _effectOptions[1]) {
    final from = ColorScheme.fromSeed(seedColor: v.color('color_from'));
    final to = ColorScheme.fromSeed(
      seedColor: v.color('color_to'),
      brightness: v.text('brightness_to') == _brightnessOptions[1] ? Brightness.dark : Brightness.light,
    );
    final s = ColorScheme.lerp(from, to, k);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: s.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    tr('Heading', 'Заголовок'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: s.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tr('Button', 'Кнопка'), style: TextStyle(color: s.onPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: s.outline),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tr('Outline', 'Контур'), style: TextStyle(color: s.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  double l(String a, String b) => v.number(a) + (v.number(b) - v.number(a)) * e;
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        tr('Design', 'Дизайн'),
        style: TextStyle(
          fontSize: l('font_size_from', 'font_size_to').clamp(1.0, 400.0),
          letterSpacing: v.number('letter_spacing_to') * e,
          color: Color.lerp(v.color('color_from'), v.color('color_to'), k),
        ),
      ),
    ),
  );
}
