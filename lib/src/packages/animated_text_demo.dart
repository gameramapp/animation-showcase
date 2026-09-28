// Showcase of the animated_text_kit package — a gallery of ALL text
// animation kinds from the installed version (4.3.0):
//   Rotate, Fade, Typer, Typewriter, Scale, Colorize, TextLiquidFill,
//   Wavy, Flicker, Scramble, Bounce + a "mix" of several kinds in one chain.
// Shared settings (text, speed, pause, size, curve) apply to all tiles at
// once. AnimatedTextKit doesn't react to parameter changes "on the fly",
// so tiles are recreated via ValueKey on any change.

import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class AnimatedTextDemo extends StatefulWidget {
  const AnimatedTextDemo({super.key});
  static const String routeName = 'packages/animated_text';

  @override
  State<AnimatedTextDemo> createState() => _AnimatedTextDemoState();
}

/// Current shared parameters for all tiles.
class _TextParams {
  const _TextParams({
    required this.phrases,
    required this.speed,
    required this.pauseMs,
    required this.fontSize,
    required this.curveName,
    required this.generation,
  });

  final List<String> phrases;
  final double speed;
  final int pauseMs;
  final double fontSize;
  final String curveName;

  /// The "generation" number: increases on any change — tiles restart.
  final int generation;

  Curve get curve => resolveCurve(curveName);
  Duration get pause => Duration(milliseconds: pauseMs);

  /// The package's base duration divided by the speed multiplier.
  Duration scaled(int baseMs) => Duration(milliseconds: (baseMs / speed).round());

  String ms(int baseMs) => 'Duration(milliseconds: ${scaled(baseMs).inMilliseconds})';

  int msOf(int baseMs) => scaled(baseMs).inMilliseconds;

  /// The shared part of the "spec" — AnimatedTextKit parameters and text style.
  Map<String, Object?> commonSpec(BuildContext context) => {
    'package': packageSpec('animated_text_kit'),
    'widget': 'AnimatedTextKit',
    'phrases': phrases,
    'pause_ms': pauseMs,
    'repeatForever': true,
    'displayFullTextOnTap': true,
    'speed_multiplier': round2(speed),
    'textStyle': {
      'font_size_px': fontSize.round(),
      'font_weight': 700,
      'color': hexColor(Theme.of(context).colorScheme.onSurface),
    },
  };

  /// Spec for a single tile: shared part + the AnimatedText class and its params.
  Map<String, Object?> kitSpec(
    BuildContext context,
    String animatedText,
    Map<String, Object?> params,
  ) => {
    ...commonSpec(context),
    'animated_text': animatedText,
    ...params,
  };
}

/// Curve without a duration: name + CSS equivalent + Dart code.
Map<String, Object?> _curveSpec(String curve) => {
  'curve': curve,
  'curve_css': curveToCss(curve) ?? tr('no CSS equivalent — Flutter only', 'нет аналога в CSS — только во Flutter'),
  'curve_dart': curveCode(curve),
};

String get _defaultPhrases => tr('Hello / Animations / For designers', 'Привет / Анимации / Для дизайнеров');

class _AnimatedTextDemoState extends State<AnimatedTextDemo> {
  final _textController = TextEditingController(text: _defaultPhrases);
  double _speed = 1.0;
  int _pauseMs = 1000;
  double _fontSize = 28;
  String _curve = 'linear';
  int _generation = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Changes a parameter and restarts all animations.
  void _update(VoidCallback change) {
    setState(() {
      change();
      _generation++;
    });
  }

  List<String> get _phrases {
    final list = _textController.text
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return list.isEmpty ? [tr('Hello', 'Привет')] : list;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final params = _TextParams(
      phrases: _phrases,
      speed: _speed,
      pauseMs: _pauseMs,
      fontSize: _fontSize,
      curveName: _curve,
      generation: _generation,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('animated_text_kit'),
        actions: [
          IconButton(
            tooltip: tr('Restart all', 'Перезапустить все'),
            onPressed: () => _update(() {}),
            icon: const Icon(Icons.replay),
          ),
          const LangButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Package animated_text_kit', 'Пакет animated_text_kit'),
            text: tr(
              'A ready-made collection of "living" text: a typewriter, '
              'rotating phrases, color washes, a wave, neon flicker, liquid '
              'text fill and more. Great for onboarding titles, promo '
              'screens, taglines and loading screens. Works in the web '
              'without limits — these are plain Flutter widgets.',
              'Готовая коллекция «живого» текста: печатная машинка, '
              'вращение фраз, переливы цвета, волна, мерцание неона, '
              'заливка текста жидкостью и другие. Подходит для заголовков '
              'онбординга, промо-экранов, слоганов и экранов загрузки. '
              'Работает в вебе без ограничений — это обычные виджеты Flutter.',
            ),
            hint: tr(
              'Everything loops. Change the text and the knobs below — the '
              'tiles will restart. Tap a tile to skip the phrase.',
              'Всё крутится по кругу. Меняй текст и ручки ниже — плитки '
              'перезапустятся. Тап по плитке — пропустить фразу.',
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            textController: _textController,
            speed: _speed,
            pauseMs: _pauseMs,
            fontSize: _fontSize,
            curve: _curve,
            onTextChanged: () => _update(() {}),
            onSpeed: (v) => _update(() => _speed = v),
            onPause: (v) => _update(() => _pauseMs = v),
            onFontSize: (v) => _update(() => _fontSize = v),
            onCurve: (v) => _update(() => _curve = v),
            spec: () => {
              ...params.commonSpec(context),
              'speed_note': tr(
                'All package durations are divided by speed_multiplier.',
                'Все длительности пакета делятся на speed_multiplier.',
              ),
              ..._curveSpec(_curve),
              'curve_applies_to': ['TyperAnimatedText', 'TypewriterAnimatedText', 'BounceAnimatedText'],
            },
            onReset: () => _update(() {
              _textController.text = _defaultPhrases;
              _speed = 1.0;
              _pauseMs = 1000;
              _fontSize = 28;
              _curve = 'linear';
            }),
          ),
          const SizedBox(height: 24),
          Text(tr('All kinds of animated text', 'Все виды анимированного текста'), style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            tr(
              'Under each tile — a line of code. All of them plug into '
              'AnimatedTextKit(animatedTexts: [...], repeatForever: true).',
              'Под каждой плиткой — строка кода. Все они вставляются в '
              'AnimatedTextKit(animatedTexts: [...], repeatForever: true).',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ResponsiveWrap(
            minTileWidth: 300,
            children: [for (final kit in _kits) kit(context, params)],
          ),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              mode: PlaygroundMode.loop,
              delayKey: 'pause_ms',
              fields: [
                BriefField.duration('duration_ms', tr('Phrase duration (duration)', 'Длительность фразы (duration)'), 2000),
                BriefField.duration('pause_ms', tr('Pause between phrases (pause)', 'Пауза между фразами (pause)'), 1000),
                BriefField.choice('effect', tr('Effect', 'Эффект'), ['Typewriter', 'Fade', 'Scale', 'Bounce'], 'Typewriter'),
                BriefField.text('phrase', tr('Phrase', 'Фраза'), tr('For designers', 'Для дизайнеров')),
                BriefField.curve('curve', tr('Curve (Typewriter / Bounce)', 'Кривая (Typewriter / Bounce)'), 'linear'),
                BriefField.number('font_size', tr('Font size', 'Размер шрифта'), 28, unit: 'px', min: 8, max: 64),
                BriefField.color('color', tr('Text color', 'Цвет текста'), '#673AB7'),
              ],
              builder: _textPlayground,
            ),
            items: [
              (
                tr('Effect kind', 'Вид эффекта'),
                tr(
                  'Rotate / Fade / Typer / Typewriter / Scale / Colorize / TextLiquidFill / Wavy / Flicker / Scramble / Bounce, or a chain of them',
                  'Rotate / Fade / Typer / Typewriter / Scale / Colorize / TextLiquidFill / Wavy / Flicker / Scramble / Bounce или их цепочка',
                ),
              ),
              (
                tr('Phrases', 'Фразы'),
                tr(
                  'the exact texts in order, accounting for line breaks and maximum length',
                  'точные тексты по порядку, с учётом переносов и максимальной длины',
                ),
              ),
              (
                tr('Timing', 'Тайминг'),
                tr(
                  'phrase duration (duration) or speed per letter (speed) in ms, and the pause between phrases (pause)',
                  'длительность фразы (duration) или скорость на букву (speed) в мс и пауза между фразами (pause)',
                ),
              ),
              (
                tr('Repeat', 'Повтор'),
                tr(
                  'looping (repeatForever), N times (totalRepeatCount), or once and stay',
                  'по кругу (repeatForever), N раз (totalRepeatCount) или один раз и остаться',
                ),
              ),
              (
                tr('Text style', 'Стиль текста'),
                tr(
                  'font, size in px, weight, color #hex; for Colorize — the gradient color list',
                  'шрифт, размер в px, начертание, цвет #hex; для Colorize — список цветов градиента',
                ),
              ),
              (
                tr('Curve', 'Кривая'),
                tr(
                  'for Typer / Typewriter / Bounce — a preset or a cubic-bezier from Figma',
                  'для Typer / Typewriter / Bounce — пресет или cubic-bezier из Figma',
                ),
              ),
              (
                tr('Effect specifics', 'Особенности эффекта'),
                tr(
                  'the Typewriter cursor, Bounce jump height (bounceHeight), Scale\'s scalingFactor, LiquidFill\'s wave and background color',
                  'курсор Typewriter, высота прыжка Bounce (bounceHeight), scalingFactor у Scale, цвет волны и фона у LiquidFill',
                ),
              ),
            ],
            avoid: [
              tr(
                'Emoji and composite characters in Wavy and Scramble — the package cuts text by UTF-16 and breaks them.',
                'Эмодзи и составные символы в Wavy и Scramble — пакет режет текст по UTF-16 и ломает их.',
              ),
              tr(
                'Custom curves for Rotate / Fade / Scale / Colorize / Flicker — they\'re hardcoded in the package.',
                'Свои кривые для Rotate / Fade / Scale / Colorize / Flicker — в пакете они зашиты.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Settings

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.textController,
    required this.speed,
    required this.pauseMs,
    required this.fontSize,
    required this.curve,
    required this.onTextChanged,
    required this.onSpeed,
    required this.onPause,
    required this.onFontSize,
    required this.onCurve,
    required this.onReset,
    required this.spec,
  });

  final TextEditingController textController;
  final double speed;
  final int pauseMs;
  final double fontSize;
  final String curve;
  final VoidCallback onTextChanged;
  final ValueChanged<double> onSpeed;
  final ValueChanged<int> onPause;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onCurve;
  final VoidCallback onReset;
  final Map<String, Object?> Function() spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tr('Shared settings for all tiles', 'Общие настройки для всех плиток'), style: textTheme.titleMedium),
                ),
                SpecButton(title: tr('animated_text_kit — shared settings', 'animated_text_kit — общие настройки'), spec: spec),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              onChanged: (_) => onTextChanged(),
              decoration: InputDecoration(
                labelText: tr('Text (several phrases — separated by " / ")', 'Текст (несколько фраз — через « / »)'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Speed', 'Скорость'),
                    value: speed,
                    min: 0.25,
                    max: 3,
                    unit: '×',
                    fractionDigits: 2,
                    onChanged: onSpeed,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Pause between phrases', 'Пауза между фразами'),
                    value: pauseMs.toDouble(),
                    min: 0,
                    max: 3000,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) => onPause(v.round()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Font size', 'Размер шрифта'),
                    value: fontSize,
                    min: 16,
                    max: 40,
                    unit: 'px',
                    onChanged: (v) => onFontSize(v.roundToDouble()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: CurveDropdown(value: curve, onChanged: onCurve),
                ),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(tr('Reset', 'Сбросить')),
                ),
              ],
            ),
            Text(
              tr(
                'The curve affects Typer, Typewriter and Bounce — for the '
                'other kinds it\'s hardcoded in the package.',
                'Кривая влияет на Typer, Typewriter и Bounce — у остальных видов '
                'она зашита в пакет.',
              ),
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Tiles

typedef _KitBuilder = Widget Function(BuildContext context, _TextParams p);

/// All text kinds from the package, ordered "from simple to flashy".
final List<_KitBuilder> _kits = [
  _rotate,
  _fade,
  _typer,
  _typewriter,
  _scale,
  _colorize,
  _liquidFill,
  _wavy,
  _flicker,
  _scramble,
  _bounce,
  _mix,
];

TextStyle _style(BuildContext context, _TextParams p, {Color? color}) => TextStyle(
      fontSize: p.fontSize,
      fontWeight: FontWeight.w700,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );

/// Standard wrapper: AnimatedTextKit, loops forever, tap to skip.
Widget _kit(String id, _TextParams p, List<AnimatedText> texts) => AnimatedTextKit(
      key: ValueKey('$id-${p.generation}'),
      animatedTexts: texts,
      pause: p.pause,
      repeatForever: true,
      displayFullTextOnTap: true,
      stopPauseOnTap: true,
    );

Widget _rotate(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Rotate — swapping phrases', 'Rotate — смена фраз'),
    caption: tr(
      'A phrase rolls in from the top and rolls out the bottom, like a drum. '
      'For taglines like "We make ___" with a changing word.',
      'Фраза въезжает сверху и уезжает вниз, как барабан. Для слоганов '
      '«Мы делаем ___» с меняющимся словом.',
    ),
    code: "RotateAnimatedText('$sample', duration: ${p.ms(2000)})",
    spec: () => p.kitSpec(context, 'RotateAnimatedText', {
      'duration_ms': p.msOf(2000),
      'rotateOut': true,
      'alignment': 'center',
      'built_in_curves': tr(
        'entry linear/easeOut, exit easeIn — not configurable',
        'вход linear/easeOut, выход easeIn — не настраиваются',
      ),
    }),
    child: _kit('rotate', p, [
      for (final t in p.phrases)
        RotateAnimatedText(t, textStyle: _style(context, p), duration: p.scaled(2000)),
    ]),
  );
}

Widget _fade(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Fade — appearing', 'Fade — проявление'),
    caption: tr(
      'A gentle appear and disappear. A calm option for hints, quotes, '
      'waiting screens.',
      'Мягкое появление и исчезновение. Спокойный вариант для подсказок, '
      'цитат, экранов ожидания.',
    ),
    code: "FadeAnimatedText('$sample', duration: ${p.ms(2000)})",
    spec: () => p.kitSpec(context, 'FadeAnimatedText', {
      'duration_ms': p.msOf(2000),
      'fadeInEnd': 0.5,
      'fadeOutBegin': 0.8,
    }),
    child: _kit('fade', p, [
      for (final t in p.phrases)
        FadeAnimatedText(t, textStyle: _style(context, p), duration: p.scaled(2000)),
    ]),
  );
}

Widget _typer(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Typer — typing letter by letter', 'Typer — набор по буквам'),
    caption: tr(
      'Text "types" one letter at a time, no cursor. For chats, assistant '
      'replies, greetings.',
      'Текст «печатается» по одной букве, без курсора. Для чатов, '
      'ответов ассистента, приветствий.',
    ),
    code: "TyperAnimatedText('$sample', speed: ${p.ms(80)}, curve: ${curveCode(p.curveName)})",
    spec: () => p.kitSpec(context, 'TyperAnimatedText', {
      'speed_ms_per_char': p.msOf(80),
      ..._curveSpec(p.curveName),
    }),
    child: _kit('typer', p, [
      for (final t in p.phrases)
        TyperAnimatedText(
          t,
          textStyle: _style(context, p),
          speed: p.scaled(80),
          curve: p.curve,
        ),
    ]),
  );
}

Widget _typewriter(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Typewriter — a typewriter', 'Typewriter — печатная машинка'),
    caption: tr(
      'Like Typer, but with a blinking cursor at the end. A classic for '
      'terminals, promos and "live" titles.',
      'Как Typer, но с мигающим курсором в конце. Классика для терминалов, '
      'промо и «живых» заголовков.',
    ),
    code:
        "TypewriterAnimatedText('$sample', speed: ${p.ms(80)}, cursor: '|', "
        'curve: ${curveCode(p.curveName)})',
    spec: () => p.kitSpec(context, 'TypewriterAnimatedText', {
      'speed_ms_per_char': p.msOf(80),
      'cursor': '|',
      ..._curveSpec(p.curveName),
    }),
    child: _kit('typewriter', p, [
      for (final t in p.phrases)
        TypewriterAnimatedText(
          t,
          textStyle: _style(context, p),
          speed: p.scaled(80),
          cursor: '|',
          curve: p.curve,
        ),
    ]),
  );
}

Widget _scale(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Scale — flying at the viewer', 'Scale — «вылет» на зрителя'),
    caption: tr(
      'A phrase grows from small and disappears. An accent on one word: '
      '"Sale", "Done", "Level 2".',
      'Фраза увеличивается из маленькой и исчезает. Акцент на одном '
      'слове: «Скидка», «Готово», «Уровень 2».',
    ),
    code: "ScaleAnimatedText('$sample', scalingFactor: 0.2, duration: ${p.ms(2000)})",
    spec: () => p.kitSpec(context, 'ScaleAnimatedText', {
      'duration_ms': p.msOf(2000),
      'scalingFactor': 0.2,
    }),
    child: _kit('scale', p, [
      for (final t in p.phrases)
        ScaleAnimatedText(
          t,
          textStyle: _style(context, p),
          scalingFactor: 0.2,
          duration: p.scaled(2000),
        ),
    ]),
  );
}

const _colorizeColors = [kAccent, Colors.blue, Colors.yellow, Colors.red];

Widget _colorize(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Colorize — color wash', 'Colorize — перелив цвета'),
    caption: tr(
      'A gradient runs across the text from the given colors. For logos, '
      'premium badges, festive titles.',
      'По тексту пробегает градиент из заданных цветов. Для логотипов, '
      'премиум-бейджей, праздничных заголовков.',
    ),
    code:
        "ColorizeAnimatedText('$sample', speed: ${p.ms(300)}, colors: [...], "
        'textStyle: ...)',
    spec: () => p.kitSpec(context, 'ColorizeAnimatedText', {
      'speed_ms': p.msOf(300),
      'colors': [for (final c in _colorizeColors) hexColor(c)],
    }),
    child: _kit('colorize', p, [
      for (final t in p.phrases)
        ColorizeAnimatedText(
          t,
          textStyle: _style(context, p),
          colors: _colorizeColors,
          speed: p.scaled(300),
        ),
    ]),
  );
}

Widget _liquidFill(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('TextLiquidFill — liquid fill', 'TextLiquidFill — заливка жидкостью'),
    caption: tr(
      'Text fills up with "water" with a wave on the surface. A separate '
      'widget, not part of AnimatedTextKit. For splash screens and loading '
      'progress.',
      'Текст наполняется «водой» с волной на поверхности. Отдельный '
      'виджет, не входит в AnimatedTextKit. Для сплэша и прогресса загрузки.',
    ),
    code:
        "TextLiquidFill(text: '$sample', loadDuration: ${p.ms(4000)}, "
        'waveColor: ..., boxBackgroundColor: ...)',
    spec: () => {
      'package': packageSpec('animated_text_kit'),
      'widget': 'TextLiquidFill',
      'text': p.phrases.first,
      'loadDuration_ms': p.msOf(4000),
      'waveDuration_ms': p.msOf(1500),
      'waveColor': hexColor(kAccent),
      'boxBackgroundColor': hexColor(Theme.of(context).colorScheme.surface),
      'boxHeight_px': 160,
      'boxWidth': tr('the tile\'s width', 'по ширине плитки'),
      'textStyle': {'font_size_px': (p.fontSize * 1.5).round(), 'font_weight': 900},
      'textAlign': 'center',
      'loop': tr(
        'the package plays it once; here it restarts every ${p.msOf(4000) + p.pauseMs + 600} ms',
        'пакет играет один раз; здесь перезапуск каждые '
            '${p.msOf(4000) + p.pauseMs + 600} мс',
      ),
    },
    padding: EdgeInsets.zero,
    child: _LiquidFillPreview(params: p),
  );
}

Widget _wavy(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Wavy — a wave across letters', 'Wavy — волна по буквам'),
    caption: tr(
      'Letters bounce one after another, like a stadium wave. Playful: for '
      'kids\' and game products, "Loading…".',
      'Буквы по очереди подпрыгивают, как волна на стадионе. Игриво: '
      'для детских и игровых продуктов, «Загрузка…».',
    ),
    code: "WavyAnimatedText('$sample', speed: ${p.ms(250)})",
    spec: () => p.kitSpec(context, 'WavyAnimatedText', {'speed_ms': p.msOf(250)}),
    child: _kit('wavy', p, [
      for (final t in p.phrases)
        WavyAnimatedText(_utf16Safe(t), textStyle: _style(context, p), speed: p.scaled(250)),
    ]),
  );
}

Widget _flicker(BuildContext context, _TextParams p) {
  final neon = _style(context, p, color: Colors.white).copyWith(
    shadows: const [
      Shadow(color: Color(0xFFE040FB), blurRadius: 12),
      Shadow(color: Color(0xFFE040FB), blurRadius: 24),
    ],
  );
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Flicker — a neon sign', 'Flicker — неоновая вывеска'),
    caption: tr(
      'Text "lights up" with a flicker, like a neon lamp. Looks best on a '
      'dark background: night themes, games, promos.',
      'Текст «загорается» с мерцанием, как неоновая лампа. Лучше всего '
      'на тёмном фоне: ночные темы, игры, промо.',
    ),
    code: "FlickerAnimatedText('$sample', speed: ${p.ms(1600)}, entryEnd: 0.7)",
    spec: () => p.kitSpec(context, 'FlickerAnimatedText', {
      'speed_ms': p.msOf(1600),
      'entryEnd': 0.7,
      'text_color': hexColor(Colors.white),
      'text_glow': [
        {'color': hexColor(const Color(0xFFE040FB)), 'blur_px': 12},
        {'color': hexColor(const Color(0xFFE040FB)), 'blur_px': 24},
      ],
      'background': hexColor(const Color(0xFF14101E)),
    }),
    background: const Color(0xFF14101E),
    child: _kit('flicker', p, [
      for (final t in p.phrases)
        FlickerAnimatedText(t, textStyle: neon, speed: p.scaled(1600), entryEnd: 0.7),
    ]),
  );
}

/// Scramble and Wavy split text by UTF-16 units: emoji and composite
/// characters break rendering (an assert in Scramble, "not well-formed
/// UTF-16" in Wavy). For these two kinds we replace such characters with "*".
String _utf16Safe(String text) =>
    text.characters.map((c) => c.length == 1 ? c : '*').join();

Widget _scramble(BuildContext context, _TextParams p) {
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Scramble — a "hacker" reveal', 'Scramble — «хакерский» подбор'),
    caption: tr(
      'Each letter first cycles through random symbols and only then '
      'settles into place. For codes, passwords, tech themes.',
      'Каждая буква сначала перебирает случайные символы и лишь потом '
      'встаёт на место. Для кодов, паролей, тех-тематики.',
    ),
    code: "ScrambleAnimatedText('$sample', speed: ${p.ms(150)})",
    spec: () => p.kitSpec(context, 'ScrambleAnimatedText', {'speed_ms': p.msOf(150)}),
    child: _kit('scramble', p, [
      for (final t in p.phrases)
        ScrambleAnimatedText(
          _utf16Safe(t),
          textStyle: _style(context, p),
          speed: p.scaled(150),
        ),
    ]),
  );
}

Widget _bounce(BuildContext context, _TextParams p) {
  // Bounce defaults to the elasticOut curve; linear from the shared settings
  // looks boring here, so we swap it for the "native" curve.
  final curve = p.curveName == 'linear' ? Curves.elasticOut : p.curve;
  final curveName = p.curveName == 'linear' ? 'elasticOut' : p.curveName;
  final sample = tr('text', 'текст');
  return _KitTile(
    title: tr('Bounce — a jump from below', 'Bounce — прыжок снизу'),
    caption: tr(
      'A phrase jumps up from below and springs. For congratulations, '
      'awards, results ("+100 points").',
      'Фраза выпрыгивает снизу и пружинит. Для поздравлений, наград, '
      'результатов («+100 очков»).',
    ),
    code:
        "BounceAnimatedText('$sample', bounceHeight: 40, duration: ${p.ms(1500)}, "
        'curve: ${curveCode(curveName)})',
    spec: () => p.kitSpec(context, 'BounceAnimatedText', {
      'duration_ms': p.msOf(1500),
      'bounceHeight_px': 40,
      ..._curveSpec(curveName),
    }),
    child: _kit('bounce', p, [
      for (final t in p.phrases)
        BounceAnimatedText(
          t,
          textStyle: _style(context, p),
          bounceHeight: 40,
          duration: p.scaled(1500),
          curve: curve,
        ),
    ]),
  );
}

Widget _mix(BuildContext context, _TextParams p) {
  // At least three phrases, to show three different kinds in a row.
  final phrases = [for (var i = 0; i < 3; i++) p.phrases[i % p.phrases.length]];
  final style = _style(context, p, color: kAccent);
  return _KitTile(
    title: tr('Mix — different kinds in one chain', 'Микс — разные виды в одной цепочке'),
    caption: tr(
      'You can stack different effects in a single AnimatedTextKit: typing '
      'first, then a jump, then a wave. For storytelling in onboarding.',
      'В один AnimatedTextKit можно сложить разные эффекты: сначала '
      'печать, потом прыжок, потом волна. Для сторителлинга в онбординге.',
    ),
    code:
        'AnimatedTextKit(animatedTexts: [TypewriterAnimatedText(..), '
        'BounceAnimatedText(..), WavyAnimatedText(..)])',
    spec: () => {
      ...p.commonSpec(context),
      'textStyle': {
        'font_size_px': p.fontSize.round(),
        'font_weight': 700,
        'color': hexColor(kAccent),
      },
      'animatedTexts': [
        {'animated_text': 'TypewriterAnimatedText', 'text': phrases[0], 'speed_ms_per_char': p.msOf(80)},
        {'animated_text': 'BounceAnimatedText', 'text': phrases[1], 'duration_ms': p.msOf(1500), 'curve': 'elasticOut'},
        {'animated_text': 'WavyAnimatedText', 'text': phrases[2], 'speed_ms': p.msOf(250)},
      ],
    },
    child: _kit('mix', p, [
      TypewriterAnimatedText(phrases[0], textStyle: style, speed: p.scaled(80)),
      BounceAnimatedText(phrases[1], textStyle: style, duration: p.scaled(1500)),
      WavyAnimatedText(_utf16Safe(phrases[2]), textStyle: style, speed: p.scaled(250)),
    ]),
  );
}

// ───────────────────────────────────────────────────── TextLiquidFill preview

/// TextLiquidFill plays once, so we loop it ourselves: a timer changes the
/// key — the widget is recreated and fills again.
class _LiquidFillPreview extends StatefulWidget {
  const _LiquidFillPreview({required this.params});

  final _TextParams params;

  @override
  State<_LiquidFillPreview> createState() => _LiquidFillPreviewState();
}

class _LiquidFillPreviewState extends State<_LiquidFillPreview> {
  Timer? _timer;
  int _run = 0;

  Duration get _load => widget.params.scaled(4000);

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_LiquidFillPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params.generation != widget.params.generation) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final period = _load + widget.params.pause + const Duration(milliseconds: 600);
    _timer = Timer.periodic(period, (_) {
      if (mounted) setState(() => _run++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    return LayoutBuilder(
      builder: (context, constraints) {
        return TextLiquidFill(
          key: ValueKey('liquid-${p.generation}-$_run'),
          text: p.phrases.first,
          textAlign: TextAlign.center,
          loadDuration: _load,
          waveDuration: p.scaled(1500),
          boxWidth: constraints.maxWidth,
          boxHeight: constraints.maxHeight,
          boxBackgroundColor: Theme.of(context).colorScheme.surface,
          waveColor: kAccent,
          textStyle: TextStyle(fontSize: p.fontSize * 1.5, fontWeight: FontWeight.w900),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────── Tile

/// A gallery tile: preview + title + description + code line.
class _KitTile extends StatelessWidget {
  const _KitTile({
    required this.title,
    required this.caption,
    required this.code,
    required this.child,
    required this.spec,
    this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String title;
  final String caption;
  final String code;
  final Widget child;
  final Map<String, Object?> Function() spec;
  final Color? background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              clipBehavior: Clip.antiAlias,
              padding: padding,
              alignment: Alignment.center,
              child: child,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(title, style: textTheme.titleSmall)),
                SpecButton(title: title, spec: spec),
              ],
            ),
            const SizedBox(height: 2),
            Text(caption, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── brief playground

/// One phrase with the chosen effect following the package's logic:
/// Typewriter types along the curve and blinks a cursor, Fade — fades in up
/// to 0.5 and fades out from 0.8, Scale — grows from 0.2 and disappears,
/// Bounce — jumps from below along the curve.
Widget _textPlayground(BuildContext context, BriefValues v, double t) {
  final phrase = v.text('phrase');
  final style = TextStyle(
    fontSize: v.number('font_size'),
    fontWeight: FontWeight.w700,
    color: v.color('color'),
  );
  final e = v.curve('curve').transform(t);
  final Widget child;
  switch (v.text('effect')) {
    case 'Fade':
      final o = t < 0.5 ? t / 0.5 : (t < 0.8 ? 1.0 : 1 - (t - 0.8) / 0.2);
      child = Opacity(opacity: o.clamp(0.0, 1.0), child: Text(phrase, style: style));
    case 'Scale':
      final grow = Curves.easeOut.transform((t / 0.5).clamp(0.0, 1.0));
      final fade = t < 0.5 ? 1.0 : 1 - Curves.easeIn.transform((t - 0.5) / 0.5);
      child = Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.2 + 0.8 * grow, child: Text(phrase, style: style)),
      );
    case 'Bounce':
      child = Transform.translate(offset: Offset(0, 40 * (1 - e)), child: Text(phrase, style: style));
    default:
      final chars = phrase.characters;
      final n = (e.clamp(0.0, 1.0) * chars.length).round();
      final cursor = t >= 1 && (DateTime.now().millisecondsSinceEpoch ~/ 400).isEven ? ' ' : '|';
      child = Text('${chars.take(n)}$cursor', style: style);
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: FittedBox(fit: BoxFit.scaleDown, child: child),
  );
}
