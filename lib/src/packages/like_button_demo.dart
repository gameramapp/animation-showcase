// Showcase of the like_button package: a "like" button with animation like
// on Twitter/X.
//   • Variants — heart, star, thumb, bookmark, fire: own icon and colors;
//   • Burst tuning — size, duration, "bubble" and ring radius, palette;
//   • Counter — digit animation types (none / part / all), position, duration.
//
// Buttons "like" themselves on a timer until the user taps them.
// The package is pure Flutter (CustomPainter + AnimationController),
// fully web-compatible.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class LikeButtonDemo extends StatelessWidget {
  const LikeButtonDemo({super.key});
  static const String routeName = 'packages/like_button';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('like_button'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('The like_button package', 'Пакет like_button'),
            text: tr(
              'A ready-made "like" button with a Twitter/X-style effect: the '
              'icon squeezes and pops, a ring spreads outward, colored dots '
              'burst around it, and the counter flips over. The icon can be '
              'swapped for anything (star, bookmark, thumb), colors can be '
              'customized. Fully web-compatible.',
              'Готовая кнопка «лайк» с эффектом как в Twitter/X: иконка '
                  'сжимается и выпрыгивает, вокруг расходится кольцо и '
                  'разлетаются цветные точки, а счётчик перелистывается. '
                  'Иконку можно заменить на любую (звезда, закладка, палец), '
                  'цвета — настроить. Пакет полностью web-совместим.',
            ),
            hint: tr(
              'The buttons "like" themselves. Tap any one — its auto-demo stops, '
              "and you're in control from then on.",
              'Кнопки лайкаются сами. Нажми на любую — автодемо этой кнопки '
                  'остановится, дальше управляешь ты.',
            ),
          ),
          const SizedBox(height: 16),
          _VariantsBlock(),
          const SizedBox(height: 16),
          _TuningBlock(),
          const SizedBox(height: 16),
          _CounterBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              mode: PlaygroundMode.loop,
              durationKey: 'animationDuration_ms',
              fields: [
                BriefField.number('size', tr('size — icon size', 'size — размер иконки'), 64, unit: 'px', min: 16, max: 120),
                BriefField.duration('animationDuration_ms', 'animationDuration', 1000),
                BriefField.number('bubblesSize_x', 'bubblesSize (× size)', 2, unit: '×', min: 0, max: 4),
                BriefField.number('circleSize_x', 'circleSize (× size)', 0.8, unit: '×', min: 0, max: 3),
                BriefField.color('icon_color', tr('Like color', 'Цвет лайка'), '#FF4081'),
                BriefField.color('circle_start', 'circleColor.start', '#FF5722'),
                BriefField.color('circle_end', 'circleColor.end', '#FFC107'),
                BriefField.color('dot_primary', 'dotPrimaryColor', '#FFC107'),
                BriefField.color('dot_secondary', 'dotSecondaryColor', '#FF9800'),
              ],
              builder: _likePlayground,
            ),
            items: [
              (
                tr('"On" and "off" icons', 'Иконки «вкл» и «выкл»'),
                tr(
                  'an SVG/icon from the set for likeBuilder — two states, size size in px',
                  'SVG/иконка из набора для likeBuilder — два состояния, размер size в px',
                ),
              ),
              (
                tr('Colors', 'Цвета'),
                tr(
                  'the icon liked and unliked (#hex), the ring circleColor (start → end), '
                  '4 dot colors bubblesColor',
                  'иконки в состоянии лайка и без (#hex), кольца circleColor (start → end), 4 цвета точек bubblesColor',
                ),
              ),
              (
                tr('Burst size', 'Размер взрыва'),
                tr(
                  'bubblesSize and circleSize in px or as a multiplier of the icon size',
                  'bubblesSize и circleSize в px или как множитель от размера иконки',
                ),
              ),
              (
                'animationDuration',
                tr('duration of the whole like animation, in ms', 'длительность всей анимации лайка в мс'),
              ),
              (
                tr('Counter', 'Счётчик'),
                tr(
                  'is it needed, where it sits (countPostion), the likeCountAnimationType mode '
                  '(none / part / all), duration, text style',
                  'нужен ли, где стоит (countPostion), режим likeCountAnimationType (none / part / all), длительность, стиль текста',
                ),
              ),
              (
                tr('Behavior', 'Поведение'),
                tr(
                  'can the like be removed with another tap, what to show at 0',
                  'можно ли снять лайк повторным тапом, что показывать при 0',
                ),
              ),
            ],
            avoid: [
              tr(
                "Custom phase curves (ring/icon/dots) — they're hardcoded in the "
                'package and not configurable.',
                'Свои кривые фаз (кольцо/иконка/точки) — в пакете они зашиты и не настраиваются.',
              ),
              tr(
                'A particle shape other than dots needs a different implementation '
                '(Lottie/Rive).',
                'Форма частиц, отличная от точек, — нужна другая реализация (Lottie/Rive).',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── button with auto-demo

typedef _LikeBuilder =
    Widget Function(
      GlobalKey<LikeButtonState> key,
      bool isLiked,
      int? likeCount,
      LikeButtonTapCallback onTap,
    );

/// Wrapper around LikeButton: "taps" the button itself on a timer until the
/// user does. Keeps the current state (like/counter) so a rebuild of the
/// parent (sliders) doesn't reset the button.
class _AutoLike extends StatefulWidget {
  const _AutoLike({
    required this.builder,
    this.auto = true,
    this.initialDelay = const Duration(milliseconds: 700),
    this.period = const Duration(milliseconds: 2200),
    this.initialCount,
    this.onUserTap,
  });

  final _LikeBuilder builder;
  final bool auto;
  final Duration initialDelay;
  final Duration period;
  final int? initialCount;
  final VoidCallback? onUserTap;

  @override
  State<_AutoLike> createState() => _AutoLikeState();
}

class _AutoLikeState extends State<_AutoLike> {
  final _key = GlobalKey<LikeButtonState>();
  bool _liked = false;
  int? _count;
  bool _userTapped = false;
  bool _autoTap = false;
  Timer? _delay;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _syncAuto();
  }

  @override
  void didUpdateWidget(_AutoLike old) {
    super.didUpdateWidget(old);
    if (!old.auto && widget.auto) _userTapped = false;
    if (old.initialCount != widget.initialCount) {
      _count = widget.initialCount;
      _liked = false;
    }
    _syncAuto();
  }

  void _syncAuto() {
    final shouldRun = widget.auto && !_userTapped;
    final running = _delay != null || _timer != null;
    if (shouldRun && !running) {
      _delay = Timer(widget.initialDelay, () {
        _autoPress();
        _timer = Timer.periodic(widget.period, (_) => _autoPress());
      });
    } else if (!shouldRun && running) {
      _stop();
    }
  }

  void _stop() {
    _delay?.cancel();
    _timer?.cancel();
    _delay = null;
    _timer = null;
  }

  // Programmatic tap: LikeButtonState.onTap() is a public method of the package.
  void _autoPress() {
    _autoTap = true;
    _key.currentState?.onTap();
    _autoTap = false;
  }

  // Any user touch stops the auto-demo — even if the package ignored the tap
  // because the animation was still running.
  void _onUserTouch() {
    if (_userTapped) return;
    _userTapped = true;
    _stop();
    widget.onUserTap?.call();
  }

  Future<bool?> _onTap(bool isLiked) async {
    if (!_autoTap) _onUserTouch();
    // Remember it without setState: the button itself animates its state.
    _liked = !isLiked;
    if (_count != null) _count = _count! + (_liked ? 1 : -1);
    return !isLiked;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _onUserTouch(),
    child: widget.builder(_key, _liked, _count, _onTap),
  );
}

// ─────────────────────────────────────────────────────────────── palettes

class _Palette {
  const _Palette(this.key, this.icon, this.bubbles, this.circle);
  final String key;
  final Color icon;
  final BubblesColor bubbles;
  final CircleColor circle;

  String get name => switch (key) {
    'classic' => tr('Classic', 'Классика'),
    'gold' => tr('Gold', 'Золото'),
    'ocean' => tr('Ocean', 'Океан'),
    'mint' => tr('Mint', 'Мята'),
    'neon' => tr('Neon', 'Неон'),
    _ => key,
  };

  /// Palette colors expressed as LikeButton parameter names.
  Map<String, Object?> spec() => {
    'palette': name,
    'icon_color_liked': hexColor(icon),
    'circleColor': {'start': hexColor(circle.start), 'end': hexColor(circle.end)},
    'bubblesColor': {
      'dotPrimaryColor': hexColor(bubbles.dotPrimaryColor),
      'dotSecondaryColor': hexColor(bubbles.dotSecondaryColor),
      'dotThirdColor': hexColor(bubbles.dotThirdColor ?? bubbles.dotPrimaryColor),
      'dotLastColor': hexColor(bubbles.dotLastColor ?? bubbles.dotSecondaryColor),
    },
  };
}

const _palettes = [
  _Palette(
    'classic',
    Colors.pinkAccent,
    BubblesColor(
      dotPrimaryColor: Color(0xFFFFC107),
      dotSecondaryColor: Color(0xFFFF9800),
      dotThirdColor: Color(0xFFFF5722),
      dotLastColor: Color(0xFFF44336),
    ),
    CircleColor(start: Color(0xFFFF5722), end: Color(0xFFFFC107)),
  ),
  _Palette(
    'gold',
    Color(0xFFFFB300),
    BubblesColor(
      dotPrimaryColor: Color(0xFFFFE082),
      dotSecondaryColor: Color(0xFFFFC107),
      dotThirdColor: Color(0xFFFF8F00),
      dotLastColor: Color(0xFFFFD54F),
    ),
    CircleColor(start: Color(0xFFFFE082), end: Color(0xFFFFA000)),
  ),
  _Palette(
    'ocean',
    Color(0xFF1E88E5),
    BubblesColor(
      dotPrimaryColor: Color(0xFF4FC3F7),
      dotSecondaryColor: Color(0xFF29B6F6),
      dotThirdColor: Color(0xFF1E88E5),
      dotLastColor: Color(0xFF00ACC1),
    ),
    CircleColor(start: Color(0xFF80DEEA), end: Color(0xFF1E88E5)),
  ),
  _Palette(
    'mint',
    Color(0xFF43A047),
    BubblesColor(
      dotPrimaryColor: Color(0xFFA5D6A7),
      dotSecondaryColor: Color(0xFF66BB6A),
      dotThirdColor: Color(0xFF26A69A),
      dotLastColor: Color(0xFFC5E1A5),
    ),
    CircleColor(start: Color(0xFFA5D6A7), end: Color(0xFF2E7D32)),
  ),
  _Palette(
    'neon',
    kAccent,
    BubblesColor(
      dotPrimaryColor: Color(0xFFE040FB),
      dotSecondaryColor: Color(0xFF7C4DFF),
      dotThirdColor: Color(0xFF00E5FF),
      dotLastColor: Color(0xFFFF4081),
    ),
    CircleColor(start: Color(0xFFE040FB), end: Color(0xFF7C4DFF)),
  ),
];

// ──────────────────────────────────────────────────────────────── variants

class _Variant {
  const _Variant(this.title, this.caption, this.on, this.off, this.palette);
  final String title;
  final String caption;
  final IconData on;
  final IconData off;
  final _Palette palette;
}

List<_Variant> _variants() => [
  _Variant(
    tr('Heart', 'Сердце'),
    tr(
      "Like on a post/photo. The package's standard look.\nlikeBuilder not needed",
      'Лайк поста/фото. Стандартный вид пакета.\nlikeBuilder не нужен',
    ),
    Icons.favorite,
    Icons.favorite,
    _palettes[0],
  ),
  _Variant(
    tr('Star', 'Звезда'),
    tr('Favorite, rating.\nlikeBuilder: Icon(Icons.star)', 'Избранное, оценка.\nlikeBuilder: Icon(Icons.star)'),
    Icons.star,
    Icons.star_border,
    _palettes[1],
  ),
  _Variant(
    tr('Thumbs up', 'Палец вверх'),
    tr(
      '"Helpful", vote for an idea.\nlikeBuilder: Icon(Icons.thumb_up)',
      '«Полезно», голос за идею.\nlikeBuilder: Icon(Icons.thumb_up)',
    ),
    Icons.thumb_up,
    Icons.thumb_up_off_alt,
    _palettes[2],
  ),
  _Variant(
    tr('Bookmark', 'Закладка'),
    tr('Save for later.\nlikeBuilder: Icon(Icons.bookmark)', 'Сохранить на потом.\nlikeBuilder: Icon(Icons.bookmark)'),
    Icons.bookmark,
    Icons.bookmark_border,
    _palettes[3],
  ),
  _Variant(
    tr('Fire', 'Огонь'),
    tr(
      '"Fire" reaction, a streak.\nlikeBuilder: Icon(Icons.local_fire_department)',
      'Реакция «огонь», стрик.\nlikeBuilder: Icon(Icons.local_fire_department)',
    ),
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,
    _palettes[4],
  ),
];

/// Icon names for the "spec" (IconData doesn't know its own name).
final _iconNames = <IconData, String>{
  Icons.favorite: 'favorite',
  Icons.star: 'star',
  Icons.star_border: 'star_border',
  Icons.thumb_up: 'thumb_up',
  Icons.thumb_up_off_alt: 'thumb_up_off_alt',
  Icons.bookmark: 'bookmark',
  Icons.bookmark_border: 'bookmark_border',
  Icons.local_fire_department: 'local_fire_department',
  Icons.local_fire_department_outlined: 'local_fire_department_outlined',
};

class _VariantsBlock extends StatelessWidget {
  const _VariantsBlock();

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
                Expanded(child: Text(tr('Icon and color variants', 'Варианты иконок и цветов'), style: textTheme.titleMedium)),
                SpecButton(
                  title: tr('LikeButton — variants', 'LikeButton — варианты'),
                  spec: () => {
                    'package': packageSpec('like_button'),
                    'widget': 'LikeButton',
                    'size_px': 48,
                    'animationDuration_ms': 1000,
                    'icon_color_unliked': hexColor(Colors.grey),
                    'variants': [
                      for (final v in _variants())
                        {
                          'variant': v.title,
                          'likeBuilder_icon_liked': 'Icons.${_iconNames[v.on]}',
                          'likeBuilder_icon_unliked': 'Icons.${_iconNames[v.off]}',
                          ...v.palette.spec(),
                        },
                    ],
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'The icon is set by likeBuilder — any widget for the "on/off" '
                'states. Ring colors (circleColor) and dot colors '
                '(bubblesColor) are matched to the icon. This way the same '
                'mechanic becomes a like, a favorite, a bookmark, or a reaction.',
                'Иконку задаёт likeBuilder — любой виджет для состояний «вкл/выкл». '
                    'Цвета кольца (circleColor) и точек (bubblesColor) подбираются '
                    'под иконку. Так одна и та же механика становится лайком, '
                    'избранным, закладкой или реакцией.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 200,
              children: [
                for (final (i, v) in _variants().indexed)
                  ShowcaseTile(
                    title: v.title,
                    caption: v.caption,
                    previewHeight: 130,
                    child: _AutoLike(
                      initialDelay: Duration(milliseconds: 300 + i * 450),
                      period: const Duration(milliseconds: 2600),
                      builder: (key, liked, count, onTap) => LikeButton(
                        key: key,
                        size: 48,
                        isLiked: liked,
                        onTap: onTap,
                        circleColor: v.palette.circle,
                        bubblesColor: v.palette.bubbles,
                        likeBuilder: (isLiked) => Icon(
                          isLiked ? v.on : v.off,
                          size: 48,
                          color: isLiked ? v.palette.icon : Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── burst tuning

class _TuningBlock extends StatefulWidget {
  const _TuningBlock();

  @override
  State<_TuningBlock> createState() => _TuningBlockState();
}

class _TuningBlockState extends State<_TuningBlock> {
  bool _auto = true;
  double _size = 64;
  int _durationMs = 1000;
  double _bubblesK = 2;
  double _circleK = 0.8;
  int _palette = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = _palettes[_palette];
    return AnimBlock(
      title: tr('Tuning the "burst"', 'Настройка «взрыва»'),
      spec: () => {
        'package': packageSpec('like_button'),
        'widget': 'LikeButton',
        'size_px': _size.round(),
        'animationDuration_ms': _durationMs,
        'bubblesSize_px': (_size * _bubblesK).round(),
        'bubbles_size_x_size': round2(_bubblesK, 1),
        'circleSize_px': (_size * _circleK).round(),
        'circle_size_x_size': round2(_circleK, 1),
        'likeBuilder_icon': 'Icons.favorite',
        'icon_color_unliked': hexColor(Colors.grey.shade400),
        ...palette.spec(),
        'built_in_curves': tr(
          'ring ease, icon OvershootCurve(2.5), dots decelerate — not configurable in the package',
          'кольцо ease, иконка OvershootCurve(2.5), точки decelerate — '
              'в пакете не настраиваются',
        ),
      },
      description: tr(
        'The animation runs in three phases within animationDuration: the ring '
        'spreads out (circleSize), the icon pops with overshoot, dots scatter '
        'out to bubblesSize. By default dots are 2× the icon size, the ring is '
        '0.8×. A large burst suits the "main" reaction, a small one suits lists.',
        'Анимация идёт в три фазы за animationDuration: расходится кольцо '
            '(circleSize), иконка выпрыгивает с перелётом (overshoot), точки '
            'разлетаются на bubblesSize. По умолчанию точки — 2× размер иконки, '
            'кольцо — 0.8×. Крупный взрыв — для «главной» реакции, мелкий — для '
            'списков.',
      ),
      preview: _AutoLike(
        auto: _auto,
        onUserTap: () => setState(() => _auto = false),
        builder: (key, liked, count, onTap) => LikeButton(
          key: key,
          size: _size,
          isLiked: liked,
          onTap: onTap,
          animationDuration: Duration(milliseconds: _durationMs),
          bubblesSize: _size * _bubblesK,
          circleSize: _size * _circleK,
          circleColor: palette.circle,
          bubblesColor: palette.bubbles,
          likeBuilder: (isLiked) => Icon(
            Icons.favorite,
            size: _size,
            color: isLiked ? palette.icon : Colors.grey.shade400,
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            label: Text(tr('Auto', 'Авто')),
            selected: _auto,
            onSelected: (v) => setState(() => _auto = v),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('size — icon size', 'size — размер иконки'),
            value: _size,
            min: 24,
            max: 96,
            unit: 'px',
            onChanged: (v) => setState(() => _size = v.roundToDouble()),
          ),
          LabeledSlider(
            label: 'animationDuration',
            value: _durationMs.toDouble(),
            min: 300,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = (v / 50).round() * 50),
          ),
          LabeledSlider(
            label: tr('bubblesSize — dot spread', 'bubblesSize — разлёт точек'),
            value: _bubblesK,
            min: 1,
            max: 3,
            unit: '× size',
            fractionDigits: 1,
            onChanged: (v) => setState(() => _bubblesK = v),
          ),
          LabeledSlider(
            label: tr('circleSize — ring radius', 'circleSize — радиус кольца'),
            value: _circleK,
            min: 0.3,
            max: 1.5,
            unit: '× size',
            fractionDigits: 1,
            onChanged: (v) => setState(() => _circleK = v),
          ),
          Text(tr('Palette (circleColor + bubblesColor)', 'Палитра (circleColor + bubblesColor)'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (i, p) in _palettes.indexed)
                ChoiceChip(
                  label: Text(p.name),
                  avatar: CircleAvatar(backgroundColor: p.icon, radius: 6),
                  selected: _palette == i,
                  onSelected: (_) => setState(() => _palette = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _CodeBox(
            'LikeButton(\n'
            '  size: ${_size.round()},\n'
            '  animationDuration: Duration(milliseconds: $_durationMs),\n'
            '  bubblesSize: ${(_size * _bubblesK).round()},\n'
            '  circleSize: ${(_size * _circleK).round()},\n'
            '  circleColor: CircleColor(start: …, end: …),\n'
            '  bubblesColor: BubblesColor(dotPrimaryColor: …, …),\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── counter

String _countTypeLabel(LikeCountAnimationType t) => switch (t) {
  LikeCountAnimationType.none => tr('none — no animation', 'none — без анимации'),
  LikeCountAnimationType.part => tr('part — only the changed digits', 'part — только изменённые цифры'),
  LikeCountAnimationType.all => tr('all — the whole number', 'all — всё число'),
};

String _positionLabel(CountPostion p) => switch (p) {
  CountPostion.right => tr('right', 'справа'),
  CountPostion.left => tr('left', 'слева'),
  CountPostion.top => tr('top', 'сверху'),
  CountPostion.bottom => tr('bottom', 'снизу'),
};

class _CounterBlock extends StatefulWidget {
  const _CounterBlock();

  @override
  State<_CounterBlock> createState() => _CounterBlockState();
}

class _CounterBlockState extends State<_CounterBlock> {
  bool _auto = true;
  LikeCountAnimationType _type = LikeCountAnimationType.part;
  CountPostion _position = CountPostion.right;
  int _countMs = 500;
  int _start = 1299;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimBlock(
      title: tr('Like counter', 'Счётчик лайков'),
      spec: () => {
        'package': packageSpec('like_button'),
        'widget': 'LikeButton',
        'size_px': 40,
        'likeCount': _start,
        'likeCountAnimationType': _type.name,
        'likeCountAnimationDuration_ms': _countMs,
        'countPostion': _position.name,
        'likeCountPadding_px': 6,
        'count_text': {
          'font_size_px': 22,
          'font_weight': 600,
          'color_liked': hexColor(Colors.pinkAccent),
          'color_unliked': hexColor(Colors.grey),
        },
      },
      description: tr(
        'The number next to the button flips up/down. Mode part moves only '
        'the digits that changed (1299 → 1300: "1" stays, "299" slides away), '
        'all moves the whole number, none just swaps it. Try a starting value '
        'of 99 or 9999: when the number\'s length changes, part behaves like all.',
        'Число рядом с кнопкой перелистывается вверх/вниз. Режим part '
            'двигает только изменившиеся цифры (1299 → 1300: «1» стоит, «299» '
            'уезжает), all — всё число целиком, none — просто подменяет. '
            'Попробуй старт 99 или 9999: при смене длины числа part ведёт себя '
            'как all.',
      ),
      preview: _AutoLike(
        auto: _auto,
        initialCount: _start,
        onUserTap: () => setState(() => _auto = false),
        builder: (key, liked, count, onTap) => LikeButton(
          key: key,
          size: 40,
          isLiked: liked,
          likeCount: count,
          onTap: onTap,
          countPostion: _position,
          likeCountAnimationType: _type,
          likeCountAnimationDuration: Duration(milliseconds: _countMs),
          likeCountPadding: const EdgeInsets.all(6),
          countBuilder: (c, isLiked, text) => Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isLiked ? Colors.pinkAccent : Colors.grey,
            ),
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            label: Text(tr('Auto', 'Авто')),
            selected: _auto,
            onSelected: (v) => setState(() => _auto = v),
          ),
          const SizedBox(height: 8),
          Text('likeCountAnimationType', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in LikeCountAnimationType.values)
                ChoiceChip(
                  label: Text(_countTypeLabel(t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'likeCountAnimationDuration',
            value: _countMs.toDouble(),
            min: 100,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _countMs = (v / 50).round() * 50),
          ),
          Text(tr('countPostion — where the number sits', 'countPostion — где число'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in CountPostion.values)
                ChoiceChip(
                  label: Text(_positionLabel(p)),
                  selected: _position == p,
                  onSelected: (_) => setState(() => _position = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tr('Starting number', 'Стартовое число'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final n in const [41, 99, 1299, 9999])
                ChoiceChip(
                  label: Text('$n'),
                  selected: _start == n,
                  onSelected: (_) => setState(() => _start = n),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _CodeBox(
            'LikeButton(\n'
            '  likeCount: $_start,\n'
            '  likeCountAnimationType: LikeCountAnimationType.${_type.name},\n'
            '  likeCountAnimationDuration: Duration(milliseconds: $_countMs),\n'
            '  countPostion: CountPostion.${_position.name},\n'
            '  countBuilder: (count, isLiked, text) => Text(text, …),\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── code caption

class _CodeBox extends StatelessWidget {
  const _CodeBox(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────── brief playground

/// "Burst" phases exactly as in the package: ring Interval(0–0.3, ease), hole
/// in the ring Interval(0.2–0.5, ease), icon Interval(0.35–0.7, OvershootCurve),
/// dots Interval(0.1–1, decelerate).
Widget _likePlayground(BuildContext context, BriefValues v, double t) {
  final size = v.number('size');
  final bubbles = size * v.number('bubblesSize_x');
  final box = math.max(bubbles, size * v.number('circleSize_x')) + 8;
  return FittedBox(
    child: SizedBox.square(
      dimension: math.max(box, size),
      child: CustomPaint(
        painter: _LikeBurstPainter(
          t: t,
          circleRadius: size * v.number('circleSize_x') / 2,
          bubblesRadius: bubbles / 2,
          circleStart: v.color('circle_start'),
          circleEnd: v.color('circle_end'),
          dots: [v.color('dot_primary'), v.color('dot_secondary')],
        ),
        child: Center(
          child: Transform.scale(
            scale: 0.2 + 0.8 * const Interval(0.35, 0.7, curve: OvershootCurve()).transform(t),
            child: Icon(Icons.favorite, size: size, color: v.color('icon_color')),
          ),
        ),
      ),
    ),
  );
}

class _LikeBurstPainter extends CustomPainter {
  _LikeBurstPainter({
    required this.t,
    required this.circleRadius,
    required this.bubblesRadius,
    required this.circleStart,
    required this.circleEnd,
    required this.dots,
  });

  final double t;
  final double circleRadius;
  final double bubblesRadius;
  final Color circleStart;
  final Color circleEnd;
  final List<Color> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = 0.1 + 0.9 * const Interval(0, 0.3, curve: Curves.ease).transform(t);
    final inner = t < 0.2 ? 0.0 : 0.2 + 0.8 * const Interval(0.2, 0.5, curve: Curves.ease).transform(t);
    final ro = circleRadius * outer;
    final ri = circleRadius * inner;
    if (ro - ri > 0.5 && t < 0.5) {
      canvas.drawCircle(
        c,
        (ro + ri) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ro - ri
          ..color = Color.lerp(circleStart, circleEnd, outer)!,
      );
    }
    if (t > 0.1 && t < 1) {
      final p = const Interval(0.1, 1, curve: Curves.decelerate).transform(t);
      final r = circleRadius + (bubblesRadius - circleRadius) * p;
      final dot = math.max(0.0, 4 * (1 - p));
      for (var i = 0; i < 7; i++) {
        final a = i / 7 * 2 * math.pi - math.pi / 2;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, dot, Paint()..color = dots[0]);
        canvas.drawCircle(
          c + Offset(math.cos(a + 0.25), math.sin(a + 0.25)) * r * 0.85,
          dot * 0.8,
          Paint()..color = dots[1],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LikeBurstPainter old) => true;
}
