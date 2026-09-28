// Showcase of the zo_animated_border package — animated borders around
// anything:
//   • Gallery of all 17 widgets in the package (gradient, fire, snake,
//     dotted, breathing, pulse, radar, ripples, running text, etc.);
//   • The same borders on real elements: button, story avatar, input field,
//     drop zone, promo card, notification bell, booking timer;
//   • Shared knobs: speed, thickness, radius, palette, dark/light background.
//
// All borders are a CustomPainter on top of the child, so they work in the
// web too.

import 'package:flutter/material.dart';
import 'package:zo_animated_border/zo_animated_border.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class AnimatedBorderDemo extends StatefulWidget {
  const AnimatedBorderDemo({super.key});
  static const String routeName = 'packages/animated_border';

  @override
  State<AnimatedBorderDemo> createState() => _AnimatedBorderDemoState();
}

/// Border palettes — 4 colors each. Ids are internal; display names go
/// through [_paletteLabel] so they translate.
const _palettes = <String, List<Color>>{
  'neon': [Color(0xFF00E5FF), Color(0xFF6B2AFF), Color(0xFFFF2A85), Color(0xFF00FF87)],
  'sunset': [Color(0xFFFF992A), Color(0xFFFF2A85), Color(0xFFFFD54F), Color(0xFFFF5252)],
  'brand': [Color(0xFF673AB7), Color(0xFFB388FF), Color(0xFF18FFFF), Color(0xFFE040FB)],
  'mono': [Color(0xFFFFFFFF), Color(0xFF9E9E9E), Color(0xFFE0E0E0), Color(0xFF616161)],
};

/// Display name for a palette id.
String _paletteLabel(String id) => switch (id) {
  'sunset' => tr('Sunset', 'Закат'),
  'brand' => tr('Brand', 'Фирменный'),
  'mono' => tr('Mono', 'Моно'),
  _ => tr('Neon', 'Неон'),
};

/// Current knob values — passed down to all tiles.
class _Knobs {
  const _Knobs({
    required this.speed,
    required this.width,
    required this.radius,
    required this.palette,
    required this.dark,
    required this.curveName,
  });

  final double speed;
  final double width;
  final double radius;
  final String palette;
  final bool dark;

  /// Curve for a single cycle (animationCurve) — for widgets that accept it.
  final String curveName;
  Curve get curve => resolveCurve(curveName);

  List<Color> get c {
    final p = _palettes[palette]!;
    // "Mono" on a light background — in dark tones, otherwise it's invisible.
    if (palette == 'mono' && !dark) {
      return const [Color(0xFF212121), Color(0xFF757575), Color(0xFF424242), Color(0xFFBDBDBD)];
    }
    return p;
  }

  Color get bg => dark ? const Color(0xFF14121A) : const Color(0xFFF7F5FB);
  Color get fill => dark ? const Color(0xFF231F2E) : Colors.white;
  Color get ink => dark ? Colors.white : Colors.black87;

  /// Duration adjusted by the speed multiplier.
  Duration d(int baseMs) => Duration(milliseconds: (baseMs / speed).round());

  /// Recreation key: some borders read duration and colors only in initState.
  Key key(String name) => ValueKey('$name|$speed|$palette|$curveName');

  List<String> hex(List<Color> colors) => [for (final c in colors) hexColor(c)];

  /// Shared values for the "spec".
  Map<String, Object?> common() => {
    'package': packageSpec('zo_animated_border'),
    'speed_multiplier': round2(speed),
    'palette': _paletteLabel(palette),
    'colors': hex(c),
    'background': hexColor(bg),
    'element_fill': hexColor(fill),
    'element_ink': hexColor(ink),
  };

  /// animationDuration + animationCurve + CSS equivalent.
  Map<String, Object?> timing(int baseMs, {bool curve = true}) => {
    'animationDuration_ms': d(baseMs).inMilliseconds,
    if (curve) ...{
      'animationCurve': curveName,
      'curve_css': curveToCss(curveName) ?? tr('no CSS equivalent — Flutter only', 'нет аналога в CSS — только во Flutter'),
      'curve_dart': curveCode(curveName),
    },
  };
}

class _AnimatedBorderDemoState extends State<AnimatedBorderDemo> {
  double _speed = 1;
  double _width = 3;
  double _radius = 18;
  String _palette = 'neon';
  bool _dark = true;
  String _curve = 'linear';

  _Knobs get _knobs => _Knobs(
    speed: _speed,
    width: _width,
    radius: _radius,
    palette: _palette,
    dark: _dark,
    curveName: _curve,
  );

  @override
  Widget build(BuildContext context) {
    final k = _knobs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Border'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Animated borders', 'Анимированные рамки'),
            text: tr(
              'The zo_animated_border package wraps any widget in a "living" '
                  'border: a running gradient, fire with sparks, a snake, dashes, '
                  'a pulse, a radar. It\'s a quick way to highlight what matters — '
                  'a buy button, an active field, a story, a promo card — without '
                  'drawing it by hand. Below are the same borders on real elements.',
              'Пакет zo_animated_border оборачивает любой виджет в «живую» '
                  'рамку: бегущий градиент, огонь с искрами, змейку, пунктир, '
                  'пульс, радар. Это быстрый способ выделить главное — кнопку '
                  'покупки, активное поле, сторис, промо-карточку — без ручной '
                  'отрисовки. Внизу — те же рамки на реальных элементах.',
            ),
            hint: tr(
              'Everything plays on its own. The knobs below change speed, '
                  'thickness, radius and palette for all borders at once.',
              'Всё играет само. Ручки ниже меняют скорость, толщину, '
                  'скругление и палитру сразу у всех рамок.',
            ),
          ),
          const SizedBox(height: 16),
          _knobsCard(context),
          const SizedBox(height: 16),
          _GalleryCard(knobs: k),
          const SizedBox(height: 16),
          _InUiCard(knobs: k),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.duration(
                  'animationDuration_ms',
                  tr('animationDuration — cycle', 'animationDuration — цикл'),
                  3000,
                ),
                BriefField.number('border_width', tr('Thickness', 'Толщина'), 3, unit: 'px', min: 0.5, max: 20),
                BriefField.number('border_radius', tr('Radius', 'Скругление'), 18, unit: 'px', min: 0, max: 60),
                BriefField.color('color1', tr('Color 1', 'Цвет 1'), '#00E5FF'),
                BriefField.color('color2', tr('Color 2', 'Цвет 2'), '#6B2AFF'),
                BriefField.color('color3', tr('Color 3', 'Цвет 3'), '#FF2A85'),
                BriefField.curve('curve', 'animationCurve', 'linear'),
                BriefField.choice(
                  'effect',
                  tr('Border', 'Рамка'),
                  [
                    tr('Running gradient', 'Бегущий градиент'),
                    tr('Snake', 'Змейка'),
                    tr('Breathing', 'Дыхание'),
                  ],
                  tr('Running gradient', 'Бегущий градиент'),
                ),
              ],
              builder: _borderPlayground,
            ),
            items: [
              (
                tr('Which border', 'Какая рамка'),
                tr(
                  'the effect name from the gallery (gradient, fire, snake, dashed, pulse, radar…) '
                      'and on which element',
                  'название эффекта из галереи (градиент, огонь, змейка, пунктир, пульс, радар…) '
                      'и на каком элементе',
                ),
              ),
              (
                tr('Colors', 'Цвета'),
                tr(
                  'the #hex palette in order; for the snake — head / tail / track, for the pulse — the wave color',
                  'палитра #hex по порядку; для змейки — голова / хвост / трек, для пульса — цвет волны',
                ),
              ),
              (
                tr('Thickness and radius', 'Толщина и скругление'),
                tr(
                  'line width in px and corner radius in px (or a circle)',
                  'ширина линии в px и радиус углов в px (или круг)',
                ),
              ),
              (
                tr('Speed', 'Скорость'),
                tr(
                  'duration of one cycle in ms; where the package allows it — the cycle curve (animationCurve)',
                  'длительность одного цикла в мс; где пакет позволяет — кривая цикла (animationCurve)',
                ),
              ),
              (
                tr('Glow', 'Свечение'),
                tr(
                  'glowOpacity / glowSpread / glowRadius, if the border glows',
                  'glowOpacity / glowSpread / glowRadius, если рамка светится',
                ),
              ),
              (
                tr('When it turns on', 'Когда включается'),
                tr(
                  'always, only on focus, until viewed (a story), for the duration of a promo — and when it fades out',
                  'всегда, только в фокусе, до просмотра (сторис), на время акции — и когда гаснет',
                ),
              ),
            ],
            avoid: [
              tr(
                'More than one "loud" border (fire, psychedelic) per screen — they compete for attention.',
                'Больше одной «громкой» рамки (огонь, психоделика) на экран — они спорят за внимание.',
              ),
              tr(
                'Overshoot curves on cyclical borders — the cycle will "jump" at the seam.',
                'Кривые с перелётом на циклических рамках — цикл будет «дёргаться» на стыке.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _knobsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('Settings for all borders', 'Настройки для всех рамок'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SpecButton(
                  title: tr('zo_animated_border — shared settings', 'zo_animated_border — общие настройки'),
                  spec: () => {
                    ..._knobs.common(),
                    'border_width_px': round2(_width, 1),
                    'border_radius_px': _radius.round(),
                    'dark_background': _dark,
                    'animationCurve': _curve,
                    'curve_css': curveToCss(_curve) ?? tr('no CSS equivalent — Flutter only', 'нет аналога в CSS — только во Flutter'),
                    'speed_note': tr(
                      'each border\'s animationDuration = base duration / speed_multiplier',
                      'animationDuration каждой рамки = базовая длительность / speed_multiplier',
                    ),
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: LabeledSlider(
                    label: tr('Speed', 'Скорость'),
                    value: _speed,
                    min: 0.25,
                    max: 3,
                    unit: '×',
                    fractionDigits: 2,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: LabeledSlider(
                    label: tr('Thickness', 'Толщина'),
                    value: _width,
                    min: 1,
                    max: 8,
                    unit: 'px',
                    fractionDigits: 1,
                    onChanged: (v) => setState(() => _width = v),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: LabeledSlider(
                    label: tr('Radius', 'Скругление'),
                    value: _radius,
                    min: 0,
                    max: 42,
                    unit: 'px',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: CurveDropdown(
                    value: _curve,
                    onChanged: (v) => setState(() => _curve = v),
                  ),
                ),
              ],
            ),
            Text(
              tr(
                'The single-cycle curve (animationCurve) — for borders that '
                    'accept it; the pulse and radar have their own easeOut.',
                'Кривая одного цикла (animationCurve) — у рамок, которые её '
                    'принимают; у пульса и радара своя easeOut.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _palettes.keys)
                  ChoiceChip(
                    avatar: _PaletteDots(colors: _palettes[name]!),
                    label: Text(_paletteLabel(name)),
                    selected: _palette == name,
                    onSelected: (_) => setState(() => _palette = name),
                  ),
                FilterChip(
                  label: Text(tr('Dark background', 'Тёмный фон')),
                  selected: _dark,
                  onSelected: (v) => setState(() => _dark = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteDots extends StatelessWidget {
  const _PaletteDots({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 4.0,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── border tile

/// A tile: preview on the chosen background, title, description and a code line.
class _BorderTile extends StatelessWidget {
  const _BorderTile({
    required this.knobs,
    required this.title,
    required this.caption,
    required this.code,
    required this.spec,
    required this.child,
  });

  final _Knobs knobs;
  final String title;
  final String caption;
  final String code;

  /// The package widget's parameters (widget + its arguments) for the "spec".
  final Map<String, Object?> Function() spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 180,
              decoration: BoxDecoration(
                color: knobs.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: child,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(title, style: textTheme.titleSmall)),
                SpecButton(title: title, spec: () => {...knobs.common(), ...spec()}),
              ],
            ),
            const SizedBox(height: 2),
            Text(caption, style: textTheme.bodySmall),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sample element inside the border — a rectangle or circle with a label.
Widget _sample(_Knobs k, String label, {double w = 150, double h = 84, bool circle = false, IconData? icon}) {
  return Container(
    width: circle ? h : w,
    height: h,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: k.fill,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(k.radius),
    ),
    child: icon != null
        ? Icon(icon, color: k.ink, size: h * 0.4)
        : Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: k.ink, fontWeight: FontWeight.w600, fontSize: 13),
          ),
  );
}

// ──────────────────────────────────────────────────────── gallery of all borders

class _GalleryCard extends StatefulWidget {
  const _GalleryCard({required this.knobs});

  final _Knobs knobs;

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  ZoMonoCromeBorderStyle _monoStyle = ZoMonoCromeBorderStyle.mirror;
  BorderStyleType _dotted = BorderStyleType.gradient;

  @override
  Widget build(BuildContext context) {
    final k = widget.knobs;
    final c = k.c;
    final br = BorderRadius.circular(k.radius);
    final textTheme = Theme.of(context).textTheme;

    final tiles = <Widget>[
      _BorderTile(
        knobs: k,
        title: tr('Running gradient', 'Бегущий градиент'),
        spec: () => {
          'widget': 'ZoAnimatedGradientBorder',
          'borderRadius_px': k.radius.round(),
          'borderThickness_px': round2(k.width, 1),
          'glowOpacity': 0.5,
          'glowSpread_px': 6,
          'gradientColor': k.hex(c),
          ...k.timing(3000),
        },
        caption: tr(
          'The gradient rotates around the outline and glows. For the primary button, premium card.',
          'Градиент вращается по контуру и светится. Для главной кнопки, премиум-карточки.',
        ),
        code: 'ZoAnimatedGradientBorder(gradientColor: [...], child: …)',
        child: ZoAnimatedGradientBorder(
          key: k.key('gradient'),
          animationCurve: k.curve,
          borderRadius: k.radius,
          borderThickness: k.width,
          glowOpacity: 0.5,
          glowSpread: 6,
          animationDuration: k.d(3000),
          gradientColor: c,
          child: _sample(k, 'Gradient'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Fire with sparks', 'Огонь с искрами'),
        spec: () => {
          'widget': 'ZoFireBorder',
          'duration_ms': k.d(3000).inMilliseconds,
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'snakeLength': 0.6,
          'gradient': k.hex([c[0], c[1], c[2]]),
          'particleColors': k.hex([c[0], c[2], Colors.white]),
        },
        caption: tr(
          '"Flame" runs along the outline with sparks flying. A blazing promo, a streak, a record.',
          'По контуру бежит «пламя» и сыплются искры. Горящая акция, стрик, рекорд.',
        ),
        code: 'ZoFireBorder(gradient: …, particleColors: [...], child: …)',
        child: ZoFireBorder(
          key: k.key('fire'),
          duration: k.d(3000),
          borderWidth: k.width,
          snakeLength: 0.6,
          borderRadius: br,
          gradient: LinearGradient(colors: [c[0], c[1], c[2]]),
          particleColors: [c[0], c[2], Colors.white],
          child: _sample(k, 'Fire'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Psychedelic', 'Психоделика'),
        spec: () => {
          'widget': 'ZoPsychoBorder',
          'ringCount': 4,
          'maxSpread_px': round2(4 + k.width * 1.5, 1),
          'colors': k.hex(c),
          'duration_ms': k.d(3000).inMilliseconds,
          'borderRadius_px': k.radius.round(),
        },
        caption: tr(
          'Several colored rippling rings spread out from the border. Celebration, game, a "wow" screen.',
          'Несколько цветных колец-волн расходятся от рамки. Праздник, игра, «вау»-экран.',
        ),
        code: 'ZoPsychoBorder(ringCount: 4, colors: [...], child: …)',
        child: ZoPsychoBorder(
          key: k.key('psycho'),
          ringCount: 4,
          maxSpread: 4 + k.width * 1.5,
          colors: c,
          duration: k.d(3000),
          borderRadius: br,
          child: _sample(k, 'Psycho'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Shifting glow', 'Смена свечения'),
        spec: () => {
          'widget': 'ZoSequentialGlowBorder',
          'borderRadius_px': k.radius.round(),
          'borderWidth_px': round2(k.width, 1),
          'glowRadius_px': 10,
          'duration_ms': k.d(4000).inMilliseconds,
          'gradientPalettes': [k.hex([c[0], c[1]]), k.hex([c[2], c[3]]), k.hex([c[1], c[2]])],
        },
        caption: tr(
          'The glowing border cycles through palettes in turn. AI features, "what\'s new".',
          'Светящаяся рамка по очереди перетекает между палитрами. AI-функции, «новинка».',
        ),
        code: 'ZoSequentialGlowBorder(gradientPalettes: [[a, b], [c, d]], child: …)',
        child: ZoSequentialGlowBorder(
          key: k.key('seq'),
          borderRadius: br,
          borderWidth: k.width,
          glowRadius: 10,
          duration: k.d(4000),
          gradientPalettes: [
            [c[0], c[1]],
            [c[2], c[3]],
            [c[1], c[2]],
          ],
          child: _sample(k, 'Sequential glow'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Multicolor segments', 'Многоцветные отрезки'),
        spec: () => {
          'widget': 'ZoMultiColorBorder',
          'colors': k.hex(c),
          'strokeWidth_px': round2(k.width, 1),
          'borderRadius_px': 50,
          'gapLength_px': 4,
          ...k.timing(2500),
        },
        caption: tr(
          'Colored segments travel around the circle. Story ring, "something unseen".',
          'Цветные сегменты едут по кругу. Кольцо сторис, «есть непросмотренное».',
        ),
        code: 'ZoMultiColorBorder(colors: [...], strokeWidth: 3, child: …)',
        child: ZoMultiColorBorder(
          key: k.key('multi'),
          animationCurve: k.curve,
          colors: c,
          strokeWidth: k.width,
          borderRadius: 50,
          gapLength: 4,
          animationDuration: k.d(2500),
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(k.width + 3),
            child: _sample(k, '', h: 90, circle: true, icon: Icons.person),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Running text', 'Бегущий текст'),
        spec: () => {
          'widget': 'ZoTextBorder',
          'text': 'SUPER SALE • -50% • SUPER SALE • -50% • ',
          'borderRadius_px': 60,
          'padding_px': 12,
          'duration_ms': k.d(12000).inMilliseconds,
          'textStyle': {'color': hexColor(c[0]), 'font_size_px': 11, 'font_weight': 700},
        },
        caption: tr(
          'Text runs along the outline. A "LIVE" badge, a promo avatar, a "SALE" stamp.',
          'Надпись едет по контуру. Бейдж «LIVE», промо-аватар, печать «SALE».',
        ),
        code: 'ZoTextBorder(text: \'SALE • \', textStyle: …, child: …)',
        child: ZoTextBorder(
          key: k.key('text'),
          text: 'SUPER SALE • -50% • SUPER SALE • -50% • ',
          borderRadius: BorderRadius.circular(60),
          padding: 12,
          duration: k.d(12000),
          textStyle: TextStyle(color: c[0], fontSize: 11, fontWeight: FontWeight.w700),
          child: _sample(k, '', h: 96, circle: true, icon: Icons.local_offer),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Glowing segment', 'Светящийся сегмент'),
        spec: () => {
          'widget': 'ZoSegmentBorder',
          'borderRadius_px': k.radius.round(),
          'segmentLength': 0.2,
          'glowOpacity': 1,
          'glowSpread_px': 8,
          'colors': k.hex([c[0], c[1]]),
          'speed_note': tr('speed is fixed in the package', 'скорость в пакете фиксирована'),
        },
        caption: tr(
          'A short bright segment runs around the outline (speed fixed in the package). Active field, search.',
          'Короткий яркий отрезок обегает контур (скорость фиксирована в пакете). Активное поле, поиск.',
        ),
        code: 'ZoSegmentBorder(segmentLength: 0.2, colors: [...], child: …)',
        child: ZoSegmentBorder(
          key: k.key('segment'),
          borderRadius: k.radius,
          segmentLength: 0.2,
          glowOpacity: 1,
          glowSpread: 8,
          colors: [c[0], c[1]],
          child: _sample(k, 'Segment'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Scribble', 'Каракули'),
        spec: () => {
          'widget': 'ZoScribbleBorder',
          'borderRadius_px': k.radius.round(),
          'borderColor': hexColor(c[0]),
          'borderWidth_px': round2(k.width, 1),
          'animationDuration_ms': k.d(4000).inMilliseconds,
          'padding_px': 10,
        },
        caption: tr(
          'The outline wobbles as if hand-drawn. Playful, child-friendly interfaces.',
          'Контур дрожит, будто нарисован от руки. Игривые, детские интерфейсы.',
        ),
        code: 'ZoScribbleBorder(borderRadius: 20, borderColor: …, child: …)',
        child: ZoScribbleBorder(
          key: k.key('scribble'),
          borderRadius: k.radius,
          borderColor: c[0],
          borderWidth: k.width,
          animationDuration: k.d(4000),
          padding: const EdgeInsets.all(10),
          child: _sample(k, 'Scribble', w: 130, h: 70),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Ripples on water', 'Круги на воде'),
        spec: () => {
          'widget': 'ZoRippleBorder',
          'rippleColor': hexColor(c[0]),
          'minCircleSize_px': 90,
          'numberOfCircles': 3,
          'animationDuration_ms': k.d(2500).inMilliseconds,
          'built_in_curves': tr('easeOutCubic / easeOut — not configurable in the package', 'easeOutCubic / easeOut — в пакете не настраиваются'),
        },
        caption: tr(
          'Soft waves spread out from the element. "On air", incoming call, geotag.',
          'От элемента расходятся мягкие волны. «В эфире», входящий звонок, геометка.',
        ),
        code: 'ZoRippleBorder(rippleColor: …, numberOfCircles: 3, child: …)',
        child: ZoRippleBorder(
          key: k.key('ripple'),
          rippleColor: c[0],
          minCircleSize: 90,
          numberOfCircles: 3,
          animationDuration: k.d(2500),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: c[0],
            child: const Icon(Icons.call, color: Colors.white),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Color changing', 'Меняющийся цвет'),
        spec: () => {
          'widget': 'ZoColorChangingBorder',
          'borderRadius_px': k.radius.round(),
          'borderWidth_px': round2(k.width, 1),
          'segmentLength': 0.25,
          'colors': k.hex(c),
          ...k.timing(3000),
        },
        caption: tr(
          'A segment runs along the outline, changing from one color to another.',
          'Отрезок бежит по контуру и перекрашивается из цвета в цвет.',
        ),
        code: 'ZoColorChangingBorder(colors: [...], segmentLength: 0.2, child: …)',
        child: ZoColorChangingBorder(
          key: k.key('colorchange'),
          animationCurve: k.curve,
          borderRadius: k.radius,
          borderWidth: k.width,
          segmentLength: 0.25,
          animationDuration: k.d(3000),
          colors: c,
          child: _sample(k, 'Color changing'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Signal', 'Сигнал'),
        spec: () => {
          'widget': 'ZoSignalBorder',
          'ringColors': k.hex(c),
          'spaceBetween_px': 10,
          ...k.timing(3000),
        },
        caption: tr(
          'Rings spread out like radio waves. Device search, "connected".',
          'Кольца расходятся как радиоволны. Поиск устройства, «на связи».',
        ),
        code: 'ZoSignalBorder(ringColors: [...], spaceBetween: 12, child: …)',
        child: ZoSignalBorder(
          key: k.key('signal'),
          animationCurve: k.curve,
          ringColors: c,
          spaceBetween: 10,
          animationDuration: k.d(3000),
          child: _sample(k, '', h: 70, circle: true, icon: Icons.wifi_tethering),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Two runners', 'Два бегуна'),
        spec: () => {
          'widget': 'ZoDualBorder',
          'firstBorderColor': hexColor(c[0]),
          'secondBorderColor': hexColor(c[2]),
          'trackBorderColor': hexColor(k.dark ? Colors.white12 : Colors.black12),
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'glowOpacity': 0.4,
          ...k.timing(2000),
        },
        caption: tr(
          'Two colored snakes chase each other around the track. Comparison, match, "VS".',
          'Две цветные змейки бегут по треку друг за другом. Сравнение, матч, «VS».',
        ),
        code: 'ZoDualBorder(firstBorderColor: a, secondBorderColor: b, child: …)',
        child: ZoDualBorder(
          key: k.key('dual'),
          animationCurve: k.curve,
          firstBorderColor: c[0],
          secondBorderColor: c[2],
          trackBorderColor: k.dark ? Colors.white12 : Colors.black12,
          borderWidth: k.width,
          borderRadius: br,
          glowOpacity: 0.4,
          animationDuration: k.d(2000),
          child: _sample(k, 'Dual'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Marching dashes', 'Бегущий пунктир'),
        spec: () => {
          'widget': 'ZoDottedBorder',
          'borderStyle': _dotted.name,
          'borderRadius_px': k.radius.round(),
          'strokeWidth_px': round2(k.width, 1),
          'dashLength_px': 10,
          'gapLength_px': 6,
          if (_dotted == BorderStyleType.monochrome) 'color': hexColor(c[0]) else 'gradient': k.hex([c[0], c[2]]),
          ...k.timing(10000),
        },
        caption: tr(
          '"Marching ants": dashes run along the outline. Loading zone, selection.',
          '«Марширующие муравьи»: штрихи едут по контуру. Зона загрузки, выделение.',
        ),
        code: 'ZoDottedBorder(dashLength: 10, gapLength: 5, borderStyle: …, child: …)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoDottedBorder(
              key: k.key('dotted'),
              animationCurve: k.curve,
              borderRadius: k.radius,
              strokeWidth: k.width,
              dashLength: 10,
              gapLength: 6,
              color: c[0],
              gradient: LinearGradient(colors: [c[0], c[2]]),
              borderStyle: _dotted,
              animationDuration: k.d(10000),
              padding: EdgeInsets.zero,
              child: _sample(k, 'Dotted', h: 76),
            ),
            const SizedBox(height: 10),
            _MiniToggle(
              dark: k.dark,
              labels: [tr('gradient', 'градиент'), tr('single color', 'один цвет')],
              index: _dotted == BorderStyleType.gradient ? 0 : 1,
              onChanged: (i) => setState(
                () => _dotted = i == 0 ? BorderStyleType.gradient : BorderStyleType.monochrome,
              ),
            ),
          ],
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Breathing', 'Дыхание'),
        spec: () => {
          'widget': 'ZoBreathingBorder',
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'colors': k.hex(c),
          ...k.timing(3000),
        },
        caption: tr(
          'The border smoothly shifts back and forth between colors. A calm accent.',
          'Рамка плавно перетекает между цветами туда-обратно. Спокойный акцент.',
        ),
        code: 'ZoBreathingBorder(colors: [...], borderWidth: 3, child: …)',
        child: ZoBreathingBorder(
          key: k.key('breath'),
          animationCurve: k.curve,
          borderWidth: k.width,
          borderRadius: br,
          colors: c,
          animationDuration: k.d(3000),
          child: _sample(k, 'Breathing', w: 140, h: 76),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Snake', 'Змейка'),
        spec: () => {
          'widget': 'ZoSnakeBorder',
          'snakeHeadColor': hexColor(c[0]),
          'snakeTailColor': hexColor(c[1]),
          'snakeTrackColor': hexColor(k.dark ? Colors.white12 : Colors.black12),
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'glowOpacity': 0.3,
          ...k.timing(4000),
        },
        caption: tr(
          'A gradient snake crawls along the track. Timer, waiting, progress.',
          'Градиентная змейка ползёт по треку. Таймер, ожидание, прогресс.',
        ),
        code: 'ZoSnakeBorder(snakeHeadColor: a, snakeTailColor: b, child: …)',
        child: ZoSnakeBorder(
          key: k.key('snake'),
          animationCurve: k.curve,
          snakeHeadColor: c[0],
          snakeTailColor: c[1],
          snakeTrackColor: k.dark ? Colors.white12 : Colors.black12,
          borderWidth: k.width,
          borderRadius: br,
          glowOpacity: 0.3,
          animationDuration: k.d(4000),
          child: _sample(k, 'Snake'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Glowing edge', 'Светящийся край'),
        spec: () => {
          'widget': 'ZoGlowingEdgeBorder',
          'gradientColors': k.hex(c),
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'edgeLength_px': 120,
          ...k.timing(3000),
        },
        caption: tr(
          'A bright gradient glint runs around the outline. A highlighted plan, a selected card.',
          'Яркий градиентный блик обегает контур. Выделенный тариф, выбранная карточка.',
        ),
        code: 'ZoGlowingEdgeBorder(gradientColors: [...], child: …)',
        child: ZoGlowingEdgeBorder(
          key: k.key('glowedge'),
          animationCurve: k.curve,
          gradientColors: c,
          borderWidth: k.width,
          borderRadius: k.radius,
          edgeLength: 120,
          animationDuration: k.d(3000),
          child: _sample(k, 'Glow edge'),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Pulse', 'Пульс'),
        spec: () => {
          'widget': 'ZoPulsatingBorder',
          'type': 'pulse',
          'pulseColor': hexColor(c[0]),
          'borderRadius_px': 40,
          'animationDuration_ms': k.d(1500).inMilliseconds,
          'animationCurve': tr('easeOut (package default)', 'easeOut (по умолчанию пакета)'),
        },
        caption: tr(
          'A shadow softly "breathes" around it. A call button, an important notification.',
          'Тень мягко «дышит» вокруг. Кнопка вызова, важное уведомление.',
        ),
        code: 'ZoPulsatingBorder(type: ZoPulsatingBorderType.pulse, child: …)',
        child: ZoPulsatingBorder(
          key: k.key('pulse'),
          type: ZoPulsatingBorderType.pulse,
          pulseColor: c[0],
          borderRadius: BorderRadius.circular(40),
          animationDuration: k.d(1500),
          child: _sample(k, '', h: 72, circle: true, icon: Icons.notifications),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Radar', 'Радар'),
        spec: () => {
          'widget': 'ZoPulsatingBorder',
          'type': 'radarPulse',
          'layerCount': 3,
          'pulseColor': hexColor(c[1]),
          'borderRadius_px': k.radius.round(),
          'animationDuration_ms': k.d(1500).inMilliseconds,
          'animationCurve': tr('easeOut (package default)', 'easeOut (по умолчанию пакета)'),
        },
        caption: tr(
          'Thin outlines spread out from the element, like a radar. Search, "nearby".',
          'Тонкие контуры расходятся от элемента, как на радаре. Поиск, «рядом с вами».',
        ),
        code: 'ZoPulsatingBorder(type: ZoPulsatingBorderType.radarPulse, child: …)',
        child: ZoPulsatingBorder(
          key: k.key('radar'),
          type: ZoPulsatingBorderType.radarPulse,
          layerCount: 3,
          pulseColor: c[1],
          borderRadius: br,
          animationDuration: k.d(1500),
          child: _sample(k, 'Radar', w: 120, h: 64),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Monochrome', 'Монохром'),
        spec: () => {
          'widget': 'ZoMonoCromeBorder',
          'borderStyle': _monoStyle.name,
          'trackBorderColor': hexColor(c[0]),
          'cornerRadius_px': k.radius.round(),
          'borderWidth_px': round2(k.width, 1),
          ...k.timing(4000),
        },
        caption: tr(
          'A glint runs along the track; stroke — once, repeated — repeats, mirror — mirrored.',
          'Блик бежит по треку; stroke — один, repeated — повторяется, mirror — зеркально.',
        ),
        code: 'ZoMonoCromeBorder(borderStyle: ZoMonoCromeBorderStyle.mirror, child: …)',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoMonoCromeBorder(
              key: k.key('mono-${_monoStyle.name}'),
              animationCurve: k.curve,
              trackBorderColor: c[0],
              cornerRadius: k.radius,
              borderWidth: k.width,
              borderStyle: _monoStyle,
              animationDuration: k.d(4000),
              child: _sample(k, 'Mono', h: 76),
            ),
            const SizedBox(height: 10),
            _MiniToggle(
              dark: k.dark,
              labels: [for (final s in ZoMonoCromeBorderStyle.values) s.name],
              index: _monoStyle.index,
              onChanged: (i) => setState(() => _monoStyle = ZoMonoCromeBorderStyle.values[i]),
            ),
          ],
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('All borders in the package', 'Все рамки пакета'), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(
                '19 variants (17 widgets, two of them have modes). Below each — where '
                    'that effect fits and how to hook it up in code.',
                '19 вариантов (17 виджетов, у двух есть режимы). Под каждой — где '
                    'такой эффект уместен и как он подключается в коде.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(minTileWidth: 260, children: tiles),
          ],
        ),
      ),
    );
  }
}

/// A small mode switcher inside the preview.
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.labels, required this.index, required this.onChanged, required this.dark});

  final bool dark;
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, l) in labels.indexed)
          GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: i == index ? (dark ? Colors.white : kAccent) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dark ? Colors.white38 : Colors.black26),
              ),
              child: Text(
                l,
                style: TextStyle(fontSize: 11, color: i == index ? (dark ? Colors.black87 : Colors.white) : (dark ? Colors.white70 : Colors.black54)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── borders in a real UI

class _InUiCard extends StatefulWidget {
  const _InUiCard({required this.knobs});

  final _Knobs knobs;

  @override
  State<_InUiCard> createState() => _InUiCardState();
}

class _InUiCardState extends State<_InUiCard> {
  final _focus = FocusNode();
  final Set<int> _seenStories = {};

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.knobs;
    final c = k.c;
    final br = BorderRadius.circular(k.radius);
    final textTheme = Theme.of(context).textTheme;

    final tiles = <Widget>[
      _BorderTile(
        knobs: k,
        title: tr('Primary button', 'Главная кнопка'),
        spec: () => {
          'widget': 'ZoAnimatedGradientBorder + FilledButton',
          'borderRadius_px': 28,
          'borderThickness_px': round2(k.width, 1),
          'glowOpacity': 0.6,
          'glowSpread_px': 8,
          'gradientColor': k.hex(c),
          ...k.timing(2500),
          'button_padding_px': {'horizontal': 22, 'vertical': 16},
        },
        caption: tr(
          'The running gradient draws the eye to the CTA — payment, subscription.',
          'Бегущий градиент притягивает взгляд к CTA — оплате, подписке.',
        ),
        code: 'ZoAnimatedGradientBorder(child: FilledButton(…))',
        child: ZoAnimatedGradientBorder(
          key: k.key('ui-cta'),
          animationCurve: k.curve,
          borderRadius: 28,
          borderThickness: k.width,
          glowOpacity: 0.6,
          glowSpread: 8,
          animationDuration: k.d(2500),
          gradientColor: c,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: k.fill,
              foregroundColor: k.ink,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            ),
            onPressed: () {},
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Premium'),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Story avatars', 'Сторис-аватары'),
        spec: () => {
          'widget': 'ZoMultiColorBorder',
          'animate': tr('true until the story is viewed', 'true, пока сторис не просмотрена'),
          'colors_unseen': k.hex(c),
          'colors_seen': k.hex(const [Color(0xFF9E9E9E), Color(0xFF9E9E9E)]),
          'strokeWidth_px': round2(k.width, 1),
          'borderRadius_px': 40,
          'gapLength_px': 3,
          'animationDuration_ms': [for (var i = 0; i < 3; i++) k.d(2000 + i * 400).inMilliseconds],
          ...k.timing(2000)..remove('animationDuration_ms'),
          'avatar_radius_px': 24,
        },
        caption: tr(
          'A colored ring — something new. Tap: the story is "viewed", the ring fades.',
          'Цветное кольцо — есть новое. Тапни: сторис «просмотрена», кольцо гаснет.',
        ),
        code: 'ZoMultiColorBorder(animate: !seen, colors: seen ? grey : [...])',
        child: Wrap(
          spacing: 10,
          children: [
            for (var i = 0; i < 3; i++)
              GestureDetector(
                onTap: () => setState(
                  () => _seenStories.contains(i) ? _seenStories.remove(i) : _seenStories.add(i),
                ),
                child: ZoMultiColorBorder(
                  key: k.key('ui-story-$i'),
                  animationCurve: k.curve,
                  animate: !_seenStories.contains(i),
                  colors: _seenStories.contains(i)
                      ? const [Color(0xFF9E9E9E), Color(0xFF9E9E9E)]
                      : c,
                  strokeWidth: k.width,
                  borderRadius: 40,
                  gapLength: 3,
                  animationDuration: k.d(2000 + i * 400),
                  padding: const EdgeInsets.all(2),
                  child: Padding(
                    padding: EdgeInsets.all(k.width + 2),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.primaries[(i * 5 + 2) % Colors.primaries.length].shade200,
                      child: Text(
                        [tr('AN', 'АН'), tr('OD', 'ОД'), tr('MK', 'МК')][i],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Focused input field', 'Поле ввода в фокусе'),
        spec: () => {
          'widget': tr('ZoGlowingEdgeBorder (focus only)', 'ZoGlowingEdgeBorder (только в фокусе)'),
          'gradientColors': k.hex(c),
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.clamp(0, 24).round(),
          'edgeLength_px': 90,
          ...k.timing(2200),
          'unfocused_border': {'color': hexColor(k.ink.withValues(alpha: 0.3)), 'width_px': 1},
        },
        caption: tr(
          'Tap into the field: a glowing glint runs around it. Out of focus — a normal border.',
          'Тапни в поле: вокруг побежит светящийся блик. Вне фокуса — обычная рамка.',
        ),
        code: 'focused ? ZoGlowingEdgeBorder(child: field) : field',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // The field always stays in place (so it doesn't lose focus), the border is an overlay layer.
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(k.width),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(k.radius.clamp(0, 24)),
                  border: Border.all(
                    color: _focus.hasFocus ? Colors.transparent : k.ink.withValues(alpha: 0.3),
                  ),
                ),
                child: _field(k),
              ),
              if (_focus.hasFocus)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ZoGlowingEdgeBorder(
                      key: k.key('ui-field-on'),
                      animationCurve: k.curve,
                      gradientColors: c,
                      borderWidth: k.width,
                      borderRadius: k.radius.clamp(0, 24),
                      edgeLength: 90,
                      animationDuration: k.d(2200),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('File drop zone', 'Зона загрузки файла'),
        spec: () => {
          'widget': 'ZoDottedBorder',
          'borderStyle': tr('gradient (default)', 'gradient (по умолчанию)'),
          'color': hexColor(c[0]),
          'borderRadius_px': k.radius.round(),
          'strokeWidth_px': round2(k.width.clamp(1, 4).toDouble(), 1),
          'dashLength_px': 8,
          'gapLength_px': 6,
          ...k.timing(8000),
          'zone_size_px': {'width': 200, 'height': 110},
        },
        caption: tr(
          'The running dashes hint: you can drag a file here.',
          'Бегущий пунктир подсказывает: сюда можно перетащить файл.',
        ),
        code: 'ZoDottedBorder(dashLength: 8, child: DropZone())',
        child: ZoDottedBorder(
          key: k.key('ui-drop'),
          animationCurve: k.curve,
          borderRadius: k.radius,
          strokeWidth: k.width.clamp(1, 4),
          dashLength: 8,
          gapLength: 6,
          color: c[0],
          animationDuration: k.d(8000),
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 200,
            height: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, color: k.ink, size: 36),
                const SizedBox(height: 6),
                Text(tr('Drop a file here', 'Перетащи файл сюда'), style: TextStyle(color: k.ink, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Blazing promo card', 'Горящая промо-карточка'),
        spec: () => {
          'widget': 'ZoFireBorder',
          'duration_ms': k.d(2600).inMilliseconds,
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': k.radius.round(),
          'snakeLength': 0.7,
          'gradient': k.hex([c[0], c[1], c[2]]),
          'particleColors': k.hex([c[0], c[2], Colors.white]),
          'card_width_px': 190,
        },
        caption: tr(
          'Fire along the edge — "grab it today". Best not more than one per screen.',
          'Огонь по краю — «успей сегодня». Лучше не больше одной на экран.',
        ),
        code: 'ZoFireBorder(child: PromoCard())',
        child: ZoFireBorder(
          key: k.key('ui-fire'),
          duration: k.d(2600),
          borderWidth: k.width,
          snakeLength: 0.7,
          borderRadius: br,
          gradient: LinearGradient(colors: [c[0], c[1], c[2]]),
          particleColors: [c[0], c[2], Colors.white],
          child: Container(
            width: 190,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(color: k.fill, borderRadius: br),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('−50% today', '−50% сегодня'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: k.ink, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('promo ends in 03:12:45', 'до конца акции 03:12:45'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: k.ink.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Notification bell', 'Колокольчик уведомлений'),
        spec: () => {
          'widget': 'ZoPulsatingBorder',
          'type': 'radarPulse',
          'layerCount': 2,
          'pulseColor': hexColor(c[0]),
          'borderRadius_px': 30,
          'animationDuration_ms': k.d(1400).inMilliseconds,
          'animationCurve': tr('easeOut (package default)', 'easeOut (по умолчанию пакета)'),
          'icon_button_size_px': 60,
        },
        caption: tr(
          'A radar around the icon — there\'s something unread. Calmer than a red dot.',
          'Радар вокруг иконки — есть непрочитанное. Спокойнее, чем красная точка.',
        ),
        code: 'ZoPulsatingBorder(type: radarPulse, child: IconButton(…))',
        child: ZoPulsatingBorder(
          key: k.key('ui-bell'),
          type: ZoPulsatingBorderType.radarPulse,
          layerCount: 2,
          pulseColor: c[0],
          borderRadius: BorderRadius.circular(30),
          animationDuration: k.d(1400),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: k.fill, shape: BoxShape.circle),
            child: Icon(Icons.notifications_active, color: k.ink),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Booking timer', 'Таймер брони'),
        spec: () => {
          'widget': 'ZoSnakeBorder',
          'snakeHeadColor': hexColor(c[0]),
          'snakeTailColor': hexColor(c[1]),
          'snakeTrackColor': hexColor(k.dark ? Colors.white12 : Colors.black12),
          'borderWidth_px': round2(k.width, 1),
          'borderRadius_px': 30,
          'glowOpacity': 0.3,
          ...k.timing(5000),
        },
        caption: tr(
          'A snake around the circle — "we\'re holding your spot". Waiting, countdown.',
          'Змейка по кругу — «место держим за вами». Ожидание, обратный отсчёт.',
        ),
        code: 'ZoSnakeBorder(animationDuration: 5.minutes, child: Chip(…))',
        child: ZoSnakeBorder(
          key: k.key('ui-timer'),
          animationCurve: k.curve,
          snakeHeadColor: c[0],
          snakeTailColor: c[1],
          snakeTrackColor: k.dark ? Colors.white12 : Colors.black12,
          borderWidth: k.width,
          borderRadius: BorderRadius.circular(30),
          glowOpacity: 0.3,
          animationDuration: k.d(5000),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: k.fill, borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: k.ink, size: 18),
                const SizedBox(width: 6),
                Text(tr('Booking 04:59', 'Бронь 04:59'), style: TextStyle(color: k.ink, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
      _BorderTile(
        knobs: k,
        title: tr('Selected plan', 'Выбранный тариф'),
        spec: () => {
          'widget': tr('ZoSequentialGlowBorder (on the selected one)', 'ZoSequentialGlowBorder (на выбранном)'),
          'borderRadius_px': k.radius.clamp(0, 16).round(),
          'borderWidth_px': round2(k.width.clamp(1, 4).toDouble(), 1),
          'glowRadius_px': 8,
          'duration_ms': k.d(4000).inMilliseconds,
          'gradientPalettes': [k.hex([c[0], c[1]]), k.hex([c[2], c[3]])],
          'plan_size_px': {'width': 84, 'height': 96},
        },
        caption: tr(
          'A glowing border highlights the recommended option among its neighbors.',
          'Светящаяся рамка выделяет рекомендуемый вариант среди соседей.',
        ),
        code: 'selected ? ZoSequentialGlowBorder(child: plan) : plan',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _plan(k, 'Basic', tr('\$0', '0 ₽')),
            const SizedBox(width: 10),
            ZoSequentialGlowBorder(
              key: k.key('ui-plan'),
              borderRadius: BorderRadius.circular(k.radius.clamp(0, 16)),
              borderWidth: k.width.clamp(1, 4),
              glowRadius: 8,
              duration: k.d(4000),
              gradientPalettes: [
                [c[0], c[1]],
                [c[2], c[3]],
              ],
              child: _plan(k, 'Pro', tr('\$4.99', '399 ₽')),
            ),
          ],
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('In a real interface', 'В реальном интерфейсе'), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(
                'How these borders look on real elements: a button, avatars, '
                    'an input field, cards. The story and the field are interactive.',
                'Как эти рамки выглядят на настоящих элементах: кнопке, аватарах, '
                    'поле ввода, карточках. Сторис и поле — интерактивные.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(minTileWidth: 260, children: tiles),
          ],
        ),
      ),
    );
  }

  Widget _field(_Knobs k) => Material(
    color: k.fill,
    borderRadius: BorderRadius.circular(k.radius.clamp(0, 24)),
    child: TextField(
      focusNode: _focus,
      style: TextStyle(color: k.ink),
      decoration: InputDecoration(
        hintText: tr('Promo code', 'Промокод'),
        hintStyle: TextStyle(color: k.ink.withValues(alpha: 0.5)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Icon(Icons.confirmation_number_outlined, color: k.ink),
      ),
    ),
  );

  Widget _plan(_Knobs k, String name, String price) => Container(
    width: 84,
    height: 96,
    decoration: BoxDecoration(
      color: k.fill,
      borderRadius: BorderRadius.circular(k.radius.clamp(0, 16)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(name, style: TextStyle(color: k.ink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(color: k.ink.withValues(alpha: 0.7), fontSize: 12)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────── brief playground

/// Real zo_animated_border widgets with the entered values (the borders run
/// their own animationDuration cycle). The key is derived from the values:
/// some borders read duration and colors only at creation time.
Widget _borderPlayground(BuildContext context, BriefValues v, double t) {
  final colors = [v.color('color1'), v.color('color2'), v.color('color3')];
  final width = v.number('border_width');
  final radius = v.number('border_radius');
  final duration = v.duration('animationDuration_ms');
  final curve = v.curve('curve');
  final effect = v.text('effect');
  final key = ValueKey('$effect|$colors|$width|$radius|$duration|${v.curveName('curve')}');
  final sample = Container(
    width: 160,
    height: 84,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: const Color(0xFF231F2E), borderRadius: BorderRadius.circular(radius)),
    child: const Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
  );
  final Widget border;
  if (effect == tr('Snake', 'Змейка')) {
    border = ZoSnakeBorder(
      key: key,
      snakeHeadColor: colors[0],
      snakeTailColor: colors[1],
      snakeTrackColor: Colors.white12,
      borderWidth: width,
      borderRadius: BorderRadius.circular(radius),
      animationDuration: duration,
      animationCurve: curve,
      child: sample,
    );
  } else if (effect == tr('Breathing', 'Дыхание')) {
    border = ZoBreathingBorder(
      key: key,
      borderWidth: width,
      borderRadius: BorderRadius.circular(radius),
      colors: colors,
      animationDuration: duration,
      animationCurve: curve,
      child: sample,
    );
  } else {
    border = ZoAnimatedGradientBorder(
      key: key,
      borderRadius: radius,
      borderThickness: width,
      glowOpacity: 0.5,
      glowSpread: 6,
      gradientColor: colors,
      animationDuration: duration,
      animationCurve: curve,
      child: sample,
    );
  }
  return Container(color: const Color(0xFF14121A), alignment: Alignment.center, child: border);
}
