// Showcase of scroll-driven animations:
//   • SliverAppBar — a large header that collapses, stretches when overscrolled,
//     and pulls its background along with a parallax;
//   • Reading progress — a bar under the header that fills as you scroll;
//   • Parallax cards — the image inside a card moves slower than the list;
//   • Reveal on scroll — elements slide in as they enter the screen;
//   • Sticky header — sticks to the top and shrinks (SliverPersistentHeader).
//
// There are no timers or durations here: the animation's "time" is the
// scroll position. Effects are configured via toggles in the panel below the header.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';

const _stickyStart = Color(0xFFEDE7F6);

/// Height of the collapsed header: toolbar + progress bar.
const _collapsedAppBar = kToolbarHeight + 4;

List<(String, String)> _images() => [
  (tr('Cape Town', 'Кейптаун'), 'assets/eat_cape_town_sm.jpg'),
  (tr('New Orleans', 'Новый Орлеан'), 'assets/eat_new_orleans_sm.jpg'),
  (tr('Sydney', 'Сидней'), 'assets/eat_sydney_sm.jpg'),
];

enum _Reveal { slideUp, slideSide, scale, rotate }

extension on _Reveal {
  String get label => switch (this) {
    _Reveal.slideUp => tr('From below', 'Снизу'),
    _Reveal.slideSide => tr('From the side', 'Сбоку'),
    _Reveal.scale => tr('Zoom', 'Зум'),
    _Reveal.rotate => tr('Tilt', 'Поворот'),
  };

  /// What defines the effect's "strength": label, unit, range, default value.
  (String, String, double, double, double, int) get amount => switch (this) {
    _Reveal.slideUp => (
      tr('Offset from below', 'Сдвиг снизу'),
      'px',
      0,
      200,
      60,
      0,
    ),
    _Reveal.slideSide => (
      tr('Offset from the side', 'Сдвиг сбоку'),
      tr('% of width', '% ширины'),
      0,
      100,
      40,
      0,
    ),
    _Reveal.scale => (
      tr('Starting scale', 'Начальный масштаб'),
      '×',
      0.3,
      1,
      0.7,
      2,
    ),
    _Reveal.rotate => (
      tr('Starting X tilt', 'Начальный наклон по X'),
      '°',
      0,
      90,
      60,
      0,
    ),
  };

  String get specKey => switch (this) {
    _Reveal.slideUp => 'offset_y_px',
    _Reveal.slideSide => 'offset_x_percent_of_width',
    _Reveal.scale => 'start_scale',
    _Reveal.rotate => 'start_rotate_x_deg',
  };

  String get transform => switch (this) {
    _Reveal.slideUp => 'translateY(offset → 0)',
    _Reveal.slideSide => 'translateX(offset → 0)',
    _Reveal.scale => tr(
      'scale(start → 1) from center',
      'scale(start → 1) от центра',
    ),
    _Reveal.rotate => tr(
      'rotateX(start → 0°) around the bottom edge, perspective 0.002',
      'rotateX(start → 0°) вокруг нижнего края, perspective 0.002',
    ),
  };
}

class ScrollEffectsDemo extends StatefulWidget {
  const ScrollEffectsDemo({super.key});
  static const String routeName = 'scroll/effects';

  @override
  State<ScrollEffectsDemo> createState() => _ScrollEffectsDemoState();
}

class _ScrollEffectsDemoState extends State<ScrollEffectsDemo> {
  final _scroll = ScrollController();
  double _parallax = 0.5;
  _Reveal _reveal = _Reveal.slideUp;
  final _revealAmount = {for (final r in _Reveal.values) r: r.amount.$5};
  double _revealZone = 160;
  String _revealCurve = 'easeOutCubic';
  double _appBarHeight = 280;
  double _stickyMax = 120;
  double _stickyMin = 56;

  Map<String, Object?> _appBarSpec() => {
    'widget':
        'SliverAppBar(pinned, stretch) + FlexibleSpaceBar(CollapseMode.parallax)',
    'driver': tr('scroll position, no timers', 'позиция скролла, без таймеров'),
    'expanded_height_px': _appBarHeight.round(),
    'collapsed_height_px': _collapsedAppBar.round(),
    'collapse_scroll_range_px': [0, (_appBarHeight - _collapsedAppBar).round()],
    'background_parallax': tr(
      'background moves up by 1/4 of the header travel',
      'фон уезжает вверх на 1/4 хода шапки',
    ),
    'title_scale': [1.5, 1.0],
    'background_overlay_gradient': [
      hexColor(Colors.transparent),
      hexColor(Colors.black54),
    ],
    'collapsed_color': hexColor(kAccent),
    'stretch': {
      'trigger': tr(
        'pulling down at the very top (overscroll, BouncingScrollPhysics)',
        'оттягивание вниз в самом верху (overscroll, BouncingScrollPhysics)',
      ),
      'modes': ['zoomBackground', 'blurBackground', 'fadeTitle'],
    },
    'reading_progress': {
      'widget': tr(
        'LinearProgressIndicator under the header',
        'LinearProgressIndicator под шапкой',
      ),
      'value': 'scrollOffset / maxScrollExtent',
      'height_px': 4,
      'color': hexColor(Colors.orange),
      'track_color': hexColor(Colors.white24),
    },
  };

  Map<String, Object?> _parallaxSpec() => {
    'widget': 'Flow + FlowDelegate (Flutter cookbook «Parallax scrolling»)',
    'driver': tr(
      "the card's position in the viewport: 0 — at the top edge, 1 — at the bottom",
      'положение карточки в видимой области: 0 — у верхнего края, 1 — у нижнего',
    ),
    'parallax_strength': double.parse(_parallax.toStringAsFixed(2)),
    'image_height_factor': double.parse(
      (1 + _parallax * 1.2).toStringAsFixed(2),
    ),
    'image_offset': tr(
      'shifted up by (image height − card height) × position',
      'сдвиг вверх на (высота картинки − высота карточки) × позиция',
    ),
    'card_aspect_ratio': '16:7',
    'card_radius_px': 16,
    'overlay_gradient': [
      hexColor(Colors.transparent),
      hexColor(Colors.black54),
    ],
    'title': {'size_px': 22, 'weight': 700, 'color': hexColor(Colors.white)},
  };

  Map<String, Object?> _revealSpec() => {
    'widget': tr(
      'Flow + FlowDelegate (transform + opacity in paintChildren)',
      'Flow + FlowDelegate (transform + opacity в paintChildren)',
    ),
    'driver': tr(
      "the element's top relative to the bottom edge of the screen",
      'верх элемента относительно нижнего края экрана',
    ),
    'effect': _reveal.name,
    'transform': _reveal.transform,
    _reveal.specKey: double.parse(_revealAmount[_reveal]!.toStringAsFixed(2)),
    'reveal_zone_px': _revealZone.round(),
    'progress': tr(
      'from entering at the bottom to rising past reveal_zone_px',
      'от входа в экран снизу до поднятия на reveal_zone_px',
    ),
    'curve': _revealCurve,
    'curve_css':
        curveToCss(_revealCurve) ??
        tr(
          'no CSS equivalent — Flutter only',
          'нет аналога в CSS — только во Flutter',
        ),
    'opacity': [0, 1],
    'item_height_px': 76,
  };

  Map<String, Object?> _stickySpec() => {
    'widget': tr(
      'SliverPersistentHeader(pinned) + a custom SliverPersistentHeaderDelegate',
      'SliverPersistentHeader(pinned) + свой SliverPersistentHeaderDelegate',
    ),
    'driver': tr(
      'shrinkOffset — how many pixels the header has already shrunk',
      'shrinkOffset — сколько пикселей заголовок уже сжат',
    ),
    'max_height_px': _stickyMax.round(),
    'min_height_px': _stickyMin.round(),
    'shrink_scroll_range_px': [0, (_stickyMax - _stickyMin).round()],
    'background_color': [hexColor(_stickyStart), hexColor(kAccent)],
    'title_font_size_px': [26, 18],
    'title_color': [hexColor(Colors.black87), hexColor(Colors.white)],
    'subtitle_opacity': [1, 0],
    'subtitle_height_px': [28, 0],
    'curve': 'linear',
  };

  String get _parallaxCardsTitle => tr('Parallax cards', 'Parallax-карточки');

  Widget _sectionTitle(String title, Map<String, Object?> Function() spec) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        SpecButton(title: title, spec: spec),
      ],
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        // Bouncing physics is needed for the stretch effect on web/Android too.
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _appBarHeight,
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            actions: const [LangButton()],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Scroll Effects'),
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_images()[2].$2, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: _ReadingProgress(controller: _scroll),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                IntroCard(
                  title: tr('Scroll-driven animations', 'Анимации от скролла'),
                  text: tr(
                    "Here, the animation's \"time\" is the scroll position. The "
                        'header collapses and stretches, the background pulls away '
                        'with a parallax, the bar under the header shows reading '
                        'progress, and the cards below move their image and slide '
                        'in as they appear.',
                    'Здесь «время» анимации — это позиция прокрутки. Шапка '
                        'сжимается и растягивается, фон уходит с параллаксом, '
                        'полоска под шапкой показывает прогресс чтения, карточки '
                        'ниже двигают картинку и въезжают при появлении.',
                  ),
                  hint: tr(
                    'Scroll up and down. Pull the list down at the very top — '
                        'the header will stretch with a zoom and blur.',
                    'Скролль вверх-вниз. Потяни список вниз в самом верху — '
                        'шапка растянется с зумом и размытием.',
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Effect settings', 'Настройки эффектов'),
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _sectionTitle(
                          tr(
                            'Header and reading progress',
                            'Шапка и прогресс чтения',
                          ),
                          _appBarSpec,
                        ),
                        LabeledSlider(
                          label: tr(
                            'Expanded header height',
                            'Высота развёрнутой шапки',
                          ),
                          value: _appBarHeight,
                          min: 160,
                          max: 400,
                          unit: 'px',
                          onChanged: (v) => setState(() => _appBarHeight = v),
                        ),
                        const Divider(),
                        _sectionTitle(_parallaxCardsTitle, _parallaxSpec),
                        LabeledSlider(
                          label: tr('Parallax strength', 'Сила параллакса'),
                          value: _parallax * 100,
                          min: 0,
                          max: 100,
                          unit: '%',
                          onChanged: (v) => setState(() => _parallax = v / 100),
                        ),
                        const Divider(),
                        _sectionTitle(
                          tr('Reveal on scroll', 'Появление при скролле'),
                          _revealSpec,
                        ),
                        Text(
                          tr('Effect', 'Эффект'),
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final r in _Reveal.values)
                              ChoiceChip(
                                label: Text(r.label),
                                selected: _reveal == r,
                                onSelected: (_) => setState(() => _reveal = r),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LabeledSlider(
                          label: _reveal.amount.$1,
                          value: _revealAmount[_reveal]!,
                          min: _reveal.amount.$3,
                          max: _reveal.amount.$4,
                          unit: _reveal.amount.$2,
                          fractionDigits: _reveal.amount.$6,
                          onChanged: (v) =>
                              setState(() => _revealAmount[_reveal] = v),
                        ),
                        LabeledSlider(
                          label: tr(
                            'Slide-in zone from the bottom edge',
                            'Зона въезда от нижнего края',
                          ),
                          value: _revealZone,
                          min: 40,
                          max: 400,
                          unit: 'px',
                          onChanged: (v) => setState(() => _revealZone = v),
                        ),
                        CurveDropdown(
                          value: _revealCurve,
                          onChanged: (v) => setState(() => _revealCurve = v),
                        ),
                        const Divider(),
                        _sectionTitle(
                          tr('Sticky header', 'Липкий заголовок'),
                          _stickySpec,
                        ),
                        LabeledSlider(
                          label: tr('Expanded height', 'Высота развёрнутого'),
                          value: _stickyMax,
                          min: 80,
                          max: 200,
                          unit: 'px',
                          onChanged: (v) => setState(() {
                            _stickyMax = v;
                            _stickyMin = math.min(_stickyMin, v);
                          }),
                        ),
                        LabeledSlider(
                          label: tr('Collapsed height', 'Высота свёрнутого'),
                          value: _stickyMin,
                          min: 40,
                          max: 80,
                          unit: 'px',
                          onChanged: (v) => setState(() {
                            _stickyMin = v;
                            _stickyMax = math.max(_stickyMax, v);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _parallaxCardsTitle,
                        style: textTheme.titleLarge,
                      ),
                    ),
                    SpecButton(title: _parallaxCardsTitle, spec: _parallaxSpec),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    "The image inside the card moves slower than the card "
                        'itself, creating a sense of depth.',
                    'Картинка внутри карточки движется медленнее, чем сама '
                        'карточка, — появляется ощущение глубины.',
                  ),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final (name, path) in [..._images(), ..._images()])
                  _ParallaxCard(title: name, asset: path, strength: _parallax),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ShrinkingHeader(
              maxHeight: _stickyMax,
              minHeight: _stickyMin,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.builder(
              itemCount: 24,
              itemBuilder: (context, i) => _RevealOnScroll(
                effect: _reveal,
                amount: _revealAmount[_reveal]!,
                zone: _revealZone,
                curve: resolveCurve(_revealCurve),
                child: _ListItem(index: i),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(
              child: DesignerBrief(
                items: [
                  (
                    tr('What drives what', 'Что чем управляет'),
                    tr(
                      'for each effect: scroll range → property, e.g. "0–220 px '
                          'of scroll → header 280 → 60 px"',
                      'для каждого эффекта: диапазон скролла → свойство, например «0–220 px скролла → шапка 280 → 60 px»',
                    ),
                  ),
                  (
                    tr('Header', 'Шапка'),
                    tr(
                      'expanded and collapsed height (px), what happens to the '
                          'background (parallax, zoom, blur on pull), title size at '
                          'the start and end',
                      'высота развёрнутой и свёрнутой (px), что происходит с фоном (параллакс, зум, блюр при оттягивании), размер заголовка в начале и в конце',
                    ),
                  ),
                  (
                    tr('Parallax', 'Параллакс'),
                    tr(
                      'how many times slower the image moves than the list (in '
                          '% or as a factor), card size and corner radius',
                      'во сколько раз картинка медленнее списка (в % или как коэффициент), размеры и скругление карточки',
                    ),
                  ),
                  (
                    tr('Element reveal', 'Появление элементов'),
                    tr(
                      'type (slide / zoom / tilt), starting value in px / × / °, '
                          'slide-in zone from the bottom edge in px, curve (preset '
                          'or cubic-bezier)',
                      'тип (сдвиг / зум / поворот), стартовое значение в px / × / °, зона въезда от нижнего края в px, кривая (пресет или cubic-bezier)',
                    ),
                  ),
                  (
                    tr('Sticky header', 'Липкий заголовок'),
                    tr(
                      'expanded and collapsed height (px), what changes along '
                          'the way: background color, font size, subtitle opacity',
                      'высота развёрнутого и свёрнутого (px), что меняется по пути: цвет фона, размер шрифта, прозрачность подзаголовка',
                    ),
                  ),
                  (
                    tr('Colors', 'Цвета'),
                    tr(
                      '#hex for the starting and ending state, color and '
                          'thickness of the progress bar',
                      '#hex для начального и конечного состояния, цвет и толщина полоски прогресса',
                    ),
                  ),
                ],
                avoid: [
                  tr(
                    "Don't give a duration in ms for scroll effects — the "
                        '"time" here is scroll pixels.',
                    'Не указывать длительность в мс для скролл-эффектов — «время» здесь это пиксели прокрутки.',
                  ),
                  tr(
                    "Don't send only a scroll video without range numbers.",
                    'Не присылать только видео скролла без цифр диапазонов.',
                  ),
                ],
                playground: BriefPlayground(
                  fields: [
                    BriefField.duration(
                      'duration_ms',
                      tr(
                        'Demo scroll (preview only)',
                        'Демо-прокрутка (только для превью)',
                      ),
                      3000,
                    ),
                    BriefField.number(
                      'header_max',
                      tr('Expanded header', 'Шапка развёрнутая'),
                      280,
                      unit: 'px',
                      min: 60,
                      max: 600,
                    ),
                    BriefField.number(
                      'header_min',
                      tr('Collapsed header', 'Шапка свёрнутая'),
                      60,
                      unit: 'px',
                      min: 0,
                      max: 300,
                    ),
                    BriefField.number(
                      'parallax',
                      tr('Parallax strength', 'Сила параллакса'),
                      50,
                      unit: '%',
                      min: 0,
                      max: 100,
                    ),
                    BriefField.number(
                      'reveal_offset',
                      tr('Reveal offset from below', 'Сдвиг появления снизу'),
                      60,
                      unit: 'px',
                      min: 0,
                      max: 400,
                    ),
                    BriefField.number(
                      'reveal_zone',
                      tr(
                        'Slide-in zone from the bottom',
                        'Зона въезда от низа',
                      ),
                      160,
                      unit: 'px',
                      min: 1,
                      max: 844,
                    ),
                    BriefField.curve(
                      'curve',
                      tr('Reveal curve', 'Кривая появления'),
                      'easeOutCubic',
                    ),
                    BriefField.color(
                      'header_color',
                      tr('Header color', 'Цвет шапки'),
                      '#673AB7',
                    ),
                    BriefField.color(
                      'progress_color',
                      tr('Progress color', 'Цвет прогресса'),
                      '#FF9800',
                    ),
                  ],
                  previewHeight: 240,
                  builder: _scrollPlayground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── brief playground

/// Playground preview: a 390×844 "phone" that scrolls itself down and back
/// (t is the scroll position). You can see the header collapse, the progress
/// bar, the card image's parallax, and elements sliding in from below.
Widget _scrollPlayground(BuildContext context, BriefValues v, double t) {
  const w = 390.0, h = 844.0;
  const cardH = 170.0, itemH = 76.0, gap = 8.0, items = 10;
  final maxH = v.number('header_max');
  final minH = math.min(v.number('header_min'), maxH);
  final parallax = v.number('parallax') / 100;
  final zone = v.number('reveal_zone');
  final curve = v.curve('curve');
  const content = 16 + cardH + 16 + items * (itemH + gap);
  final maxScroll = math.max(1.0, maxH + content - h);
  final offset = t * maxScroll;
  final headerH = (maxH - offset).clamp(minH, maxH);
  final collapse = maxH - minH <= 0
      ? 1.0
      : ((maxH - headerH) / (maxH - minH)).clamp(0.0, 1.0);

  // Card with parallax.
  final cardTop = maxH + 16 - offset;
  final imageH = cardH * (1 + parallax * 1.2);
  final fraction = ((cardTop + cardH / 2) / h).clamp(0.0, 1.0);
  final imageDy = -(imageH - cardH) * fraction;

  final children = <Widget>[
    Positioned(
      left: 16,
      right: 16,
      top: cardTop,
      height: cardH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: imageDy,
              height: imageH,
              child: Image.asset(_images()[0].$2, fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    ),
    for (var i = 0; i < items; i++)
      Builder(
        builder: (context) {
          final top = cardTop + cardH + 16 + i * (itemH + gap);
          final raw = ((h - top) / zone).clamp(0.0, 1.0);
          final e = curve.transform(raw);
          return Positioned(
            left: 16,
            right: 16,
            top: top + v.number('reveal_offset') * (1 - e),
            height: itemH,
            child: Opacity(
              opacity: e.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: HSVColor.fromAHSV(
                    1,
                    (i * 23) % 360,
                    0.35,
                    0.95,
                  ).toColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    // Header + progress bar over the content.
    Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: headerH,
      child: ColoredBox(
        color: v.color('header_color'),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              tr('Title', 'Заголовок'),
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20 * (1.5 - 0.5 * collapse),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
    Positioned(
      left: 0,
      top: headerH,
      height: 6,
      width: w * t,
      child: ColoredBox(color: v.color('progress_color')),
    ),
  ];

  return Padding(
    padding: const EdgeInsets.all(8),
    child: FittedBox(
      child: Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.black87, width: 8),
        ),
        child: Stack(clipBehavior: Clip.hardEdge, children: children),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────── reading progress

class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress({required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        var progress = 0.0;
        if (controller.hasClients && controller.position.hasContentDimensions) {
          final max = controller.position.maxScrollExtent;
          progress = max <= 0 ? 0 : (controller.offset / max).clamp(0.0, 1.0);
        }
        return LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          color: Colors.orange,
          backgroundColor: Colors.white24,
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────── parallax card

class _ParallaxCard extends StatelessWidget {
  _ParallaxCard({
    required this.title,
    required this.asset,
    required this.strength,
  });

  final String title;
  final String asset;
  final double strength;
  final _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Flow(
                delegate: _ParallaxFlowDelegate(
                  scrollable: Scrollable.of(context),
                  itemContext: context,
                  imageKey: _imageKey,
                  strength: strength,
                ),
                children: [
                  Image.asset(asset, key: _imageKey, fit: BoxFit.cover),
                ],
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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

/// Shifts the image inside the card depending on the card's position in the
/// viewport (the technique from the Flutter cookbook's "Parallax scrolling").
class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.imageKey,
    required this.strength,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey imageKey;
  final double strength;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    // The image is taller than the card — there's slack to move it up and down.
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight * (1 + strength * 1.2),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final viewport = scrollable.context.findRenderObject() as RenderBox;
    final item = itemContext.findRenderObject() as RenderBox;
    final itemOffset = item.localToGlobal(
      item.size.centerLeft(Offset.zero),
      ancestor: viewport,
    );
    // 0 — card at the top edge of the screen, 1 — at the bottom.
    final fraction = (itemOffset.dy / viewport.size.height).clamp(0.0, 1.0);
    final imageSize =
        (imageKey.currentContext!.findRenderObject() as RenderBox).size;
    final extra = imageSize.height - context.size.height;
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -extra * fraction, 0),
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate old) =>
      old.scrollable != scrollable ||
      old.itemContext != itemContext ||
      old.imageKey != imageKey ||
      old.strength != strength;
}

// ────────────────────────────────────────────────────── reveal on scroll

/// Animates a child as it rises up from the bottom edge of the screen.
/// Progress is computed right inside Flow.paintChildren — no widget rebuilds.
class _RevealOnScroll extends StatelessWidget {
  const _RevealOnScroll({
    required this.effect,
    required this.amount,
    required this.zone,
    required this.curve,
    required this.child,
  });
  final _Reveal effect;
  final double amount;
  final double zone;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Flow(
        delegate: _RevealFlowDelegate(
          scrollable: Scrollable.of(context),
          itemContext: context,
          effect: effect,
          amount: amount,
          zone: zone,
          curve: curve,
        ),
        children: [child],
      ),
    );
  }
}

class _RevealFlowDelegate extends FlowDelegate {
  _RevealFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.effect,
    required this.amount,
    required this.zone,
    required this.curve,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final _Reveal effect;

  /// Effect strength in the units from [_Reveal.amount].
  final double amount;

  /// How many pixels from the bottom edge the "slide-in" zone occupies.
  final double zone;
  final Curve curve;

  @override
  void paintChildren(FlowPaintingContext context) {
    final viewport = scrollable.context.findRenderObject() as RenderBox;
    final item = itemContext.findRenderObject() as RenderBox;
    final top = item.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final raw = ((viewport.size.height - top) / zone).clamp(0.0, 1.0);
    final t = curve.transform(raw);
    final size = context.size;

    final m = Matrix4.identity();
    switch (effect) {
      case _Reveal.slideUp:
        m.translateByDouble(0, amount * (1 - t), 0, 1);
      case _Reveal.slideSide:
        m.translateByDouble(size.width * amount / 100 * (1 - t), 0, 0, 1);
      case _Reveal.scale:
        final s = amount + (1 - amount) * t;
        m
          ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
          ..scaleByDouble(s, s, 1, 1)
          ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
      case _Reveal.rotate:
        m
          ..translateByDouble(0, size.height, 0, 1)
          ..setEntry(3, 2, 0.002)
          ..rotateX(-(1 - t) * amount * math.pi / 180)
          ..translateByDouble(0, -size.height, 0, 1);
    }
    // Overshooting curves (back, elastic, spring) go beyond 0..1 — opacity can't.
    context.paintChild(0, transform: m, opacity: t.clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(_RevealFlowDelegate old) =>
      old.scrollable != scrollable ||
      old.itemContext != itemContext ||
      old.effect != effect ||
      old.amount != amount ||
      old.zone != zone ||
      old.curve != curve;
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = HSVColor.fromAHSV(1, (index * 23) % 360, 0.5, 0.9).toColor();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text('${index + 1}'),
        ),
        title: Text(
          tr('List item ${index + 1}', 'Элемент списка ${index + 1}'),
        ),
        subtitle: Text(
          tr(
            'Slides in as it enters the screen',
            'Въезжает, когда попадает в экран',
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── sticky header

/// Section header: sticks to the top and shrinks max → min px (default
/// 120 → 56), changing color, font size, and the subtitle's opacity along the way.
class _ShrinkingHeader extends SliverPersistentHeaderDelegate {
  _ShrinkingHeader({required this.maxHeight, required this.minHeight});

  final double maxHeight;
  final double minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxHeight - minHeight;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    return Container(
      color: Color.lerp(_stickyStart, kAccent, t),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Reveal on scroll', 'Появление при скролле'),
            style: TextStyle(
              fontSize: 26 - 8 * t,
              fontWeight: FontWeight.w700,
              color: Color.lerp(Colors.black87, Colors.white, t),
            ),
          ),
          if (t < 1)
            Opacity(
              opacity: 1 - t,
              child: SizedBox(
                height: 28 * (1 - t),
                child: Text(
                  tr(
                    'The sticky header shrinks as you scroll. The elements '
                        'below slide in as they appear — the effect is chosen in '
                        'the settings above.',
                    'Липкий заголовок сжимается, пока ты скроллишь. Элементы ниже '
                        'въезжают при появлении — эффект выбирается в настройках выше.',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ShrinkingHeader oldDelegate) =>
      oldDelegate.maxHeight != maxHeight || oldDelegate.minHeight != minHeight;
}
