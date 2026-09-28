// Hero & Heroine screen: shared-element transitions between screens.
//
//   • Flutter Hero — the built-in mechanism: a shared tag makes an element
//     "fly" from the list into the detail page and back.
//   • Heroine (the heroine package) — the same trick but with spring physics:
//     you can pick a shuttle-builder (fade / single / flip / fade-through), a
//     spring (motion), and close the detail page by dragging (drag-to-dismiss),
//     with the element springing back into place.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heroine/heroine.dart';

import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';

class HeroDemo extends StatelessWidget {
  const HeroDemo({super.key});
  static const String routeName = 'hero/showcase';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero & Heroine'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const _StandardHeroSection(),
          const SizedBox(height: 16),
          const _HeroineSection(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.duration(
                  'duration_ms',
                  tr('Flight duration', 'Длительность перелёта'),
                  300,
                ),
                BriefField.curve(
                  'curve',
                  tr('Curve or spring', 'Кривая или пружина'),
                  'fastOutSlowIn',
                ),
                BriefField.choice('path', tr('Path', 'Траектория'), [
                  tr('Arc', 'дуга'),
                  tr('Straight', 'прямая'),
                ], tr('Arc', 'дуга')),
                BriefField.number(
                  'from_size_px',
                  tr('Size in the list', 'Размер в списке'),
                  40,
                  unit: 'px',
                  min: 1,
                  max: 200,
                ),
                BriefField.number(
                  'to_size_px',
                  tr('Size in the header', 'Размер в шапке'),
                  110,
                  unit: 'px',
                  min: 1,
                  max: 200,
                ),
                BriefField.number(
                  'from_radius_px',
                  tr('Corner radius in the list', 'Скругление в списке'),
                  12,
                  unit: 'px',
                  min: 0,
                ),
                BriefField.number(
                  'to_radius_px',
                  tr('Corner radius in the header', 'Скругление в шапке'),
                  28,
                  unit: 'px',
                  min: 0,
                ),
                BriefField.color(
                  'color',
                  tr('Element color', 'Цвет элемента'),
                  '#673AB7',
                ),
              ],
              builder: _heroPreview,
            ),
            items: [
              (
                tr('Shared element', 'Общий элемент'),
                tr(
                  'which layer "flies": the same layer name in both Figma frames '
                      '(this becomes the shared tag)',
                  'какой слой «перелетает»: одинаковое имя слоя в обоих фреймах Figma '
                      '(это будет общий tag)',
                ),
              ),
              (
                tr('"Before" and "after" frames', 'Фреймы «до» и «после»'),
                tr(
                  "size in px, corner radius in px, the element's #hex color in "
                      'the list and on the detail screen',
                  'размер px, скругление px, цвет #hex элемента на списке и на детальном экране',
                ),
              ),
              (
                'Hero',
                tr(
                  'flight duration there and back, ms; path — arc or straight',
                  'длительность перелёта туда и обратно, мс; траектория — дуга или прямая',
                ),
              ),
              (
                tr('Heroine / spring', 'Heroine / пружина'),
                tr(
                  'preset Smooth / Bouncy / Snappy + duration in ms, or '
                      'spring(stiffness, damping, mass) from Figma Smart Animate',
                  'пресет Smooth / Bouncy / Snappy + длительность мс, либо spring(stiffness, '
                      'damping, mass) из Figma Smart Animate',
                ),
              ),
              (
                tr('How the element morphs', 'Как элемент перетекает'),
                tr(
                  'fade, single, flip (3D flip) or fade through',
                  'fade, single, flip (3D-переворот) или fade through',
                ),
              ),
              (
                tr('The rest of the screen', 'Остальной экран'),
                tr(
                  'what the background and other elements do during the '
                      'flight (fade, shift) and over how many ms',
                  'что делает фон и другие элементы во время перелёта (fade, сдвиг) и за сколько мс',
                ),
              ),
              (
                'Drag-to-dismiss',
                tr(
                  'whether a swipe is needed to close, in which direction and '
                      'from what distance it should dismiss',
                  'нужен ли свайп для закрытия, в какую сторону и с какого расстояния закрывать',
                ),
              ),
            ],
            avoid: [
              tr(
                'Different elements sharing one name on the same screen — the '
                    'flight will break',
                'Разные элементы с одним именем на одном экране — перелёт сломается',
              ),
              tr(
                "Don't send only a video without numbers",
                'Не присылать только видео без цифр',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── data/scaffold

class _Item {
  const _Item(this.id, this.color, this.icon, this.title);
  final String id;
  final Color color;
  final IconData icon;
  final String title;
}

List<_Item> _items() => [
  _Item('photo', const Color(0xFF673AB7), Icons.photo, tr('Photo', 'Фото')),
  _Item(
    'music',
    const Color(0xFF009688),
    Icons.music_note,
    tr('Music', 'Музыка'),
  ),
  _Item(
    'like',
    const Color(0xFFE91E63),
    Icons.favorite,
    tr('Favorites', 'Избранное'),
  ),
  _Item('star', const Color(0xFFFF9800), Icons.star, tr('Awards', 'Награды')),
];

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.child,
    this.spec,
  });

  final String title;
  final String description;
  final Widget child;

  /// Current section settings for the "Spec" button.
  final Map<String, Object?> Function()? spec;

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
                Expanded(child: Text(title, style: textTheme.titleMedium)),
                if (spec != null) SpecButton(title: title, spec: spec!),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Small source tile (in the list).
class _Thumb extends StatelessWidget {
  const _Thumb(this.item);
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(item.icon, color: Colors.white, size: 30),
    );
  }
}

/// Large card on the detail page.
class _BigCard extends StatelessWidget {
  const _BigCard(this.item);
  final _Item item;

  @override
  Widget build(BuildContext context) {
    // Material is needed so that during the "flight" (in the Overlay, outside
    // the usual Material ancestor) text and other material widgets render correctly.
    // The Material itself handles the color and rounding — and clips nicely too.
    return Material(
      color: item.color,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 220,
        height: 220,
        // FittedBox scales the content to the box size on intermediate "flight"
        // frames, otherwise the Column doesn't fit and throws a RenderFlex overflow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: 88),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
            Text('Hero & Heroine', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'Shared-element transitions: the same element visually flies '
                    'between screens. The built-in Hero and the heroine package '
                    '(spring physics + drag-to-dismiss). Tap a tile — it expands '
                    'into the detail page.',
                'Shared-element переходы: один и тот же элемент визуально '
                    'перелетает между экранами. Встроенный Hero и пакет heroine '
                    '(пружинная физика + drag-to-dismiss). Тапни плитку — она '
                    'развернётся в детальную страницу.',
              ),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Flutter Hero

class _StandardHeroSection extends StatefulWidget {
  const _StandardHeroSection();

  @override
  State<_StandardHeroSection> createState() => _StandardHeroSectionState();
}

class _StandardHeroSectionState extends State<_StandardHeroSection> {
  int durationMs = 300;
  // true — MaterialRectArcTween (flight along an arc, the MaterialApp default),
  // false — RectTween (a straight line).
  bool arc = true;

  CreateRectTween get _rectTween => arc
      ? (begin, end) => MaterialRectArcTween(begin: begin, end: end)
      : (begin, end) => RectTween(begin: begin, end: end);

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: tr('Flutter Hero (built-in)', 'Flutter Hero (встроенный)'),
      spec: () => {
        'widget': 'Hero + PageRouteBuilder',
        'shared_element_tag': 'std-<id>',
        'flight_path': arc
            ? 'arc (MaterialRectArcTween)'
            : 'straight (RectTween)',
        'forward': timingSpec(durationMs: durationMs, curve: 'fastOutSlowIn'),
        'back': timingSpec(durationMs: durationMs, curve: 'fastOutSlowIn'),
        'curve_note': tr(
          'the flight curve is baked into Hero: fastOutSlowIn (reversed going back)',
          'кривая перелёта зашита в Hero: fastOutSlowIn (назад — flipped)',
        ),
        'page_transition': {
          'type': 'fade',
          'opacity_from': 0,
          'opacity_to': 1,
          'curve': 'linear',
        },
        'from': {'size_px': 72, 'border_radius_px': 16},
        'to': {'size_px': 220, 'border_radius_px': 28},
        'colors': {for (final i in _items()) i.title: hexColor(i.color)},
      },
      description: tr(
        'We wrap the element in a Hero with a shared tag on both screens — '
            'Flutter animates the "flight" itself on push/pop. Flight duration = '
            "route transition duration, so it's controlled by the slider.",
        'Оборачиваем элемент в Hero с общим тегом на обоих экранах — Flutter '
            'сам анимирует «перелёт» при push/pop. Длительность перелёта = '
            'длительность перехода маршрута, поэтому регулируется слайдером.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _items())
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration(milliseconds: durationMs),
                      reverseTransitionDuration: Duration(
                        milliseconds: durationMs,
                      ),
                      pageBuilder: (_, _, _) =>
                          _StandardDetailPage(item, _rectTween),
                      transitionsBuilder: (_, animation, _, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  ),
                  child: Hero(
                    tag: 'std-${item.id}',
                    createRectTween: _rectTween,
                    child: _Thumb(item),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr(
              'Speed (flight duration)',
              'Скорость (длительность перелёта)',
            ),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr(
                'Flight along an arc (MaterialRectArcTween)',
                'Перелёт по дуге (MaterialRectArcTween)',
              ),
            ),
            subtitle: Text(
              tr(
                'Turn off — the element flies in a straight line (RectTween)',
                'Выключи — элемент полетит по прямой (RectTween)',
              ),
            ),
            value: arc,
            onChanged: (v) => setState(() => arc = v),
          ),
        ],
      ),
    );
  }
}

class _StandardDetailPage extends StatelessWidget {
  const _StandardDetailPage(this.item, this.rectTween);
  final _Item item;
  final CreateRectTween rectTween;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: Center(
        child: Hero(
          tag: 'std-${item.id}',
          createRectTween: rectTween,
          child: _BigCard(item),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── Heroine

enum _Shuttle { fade, single, flip, fadeThrough }

enum _MotionKind { smooth, bouncy, snappy }

class _HeroineSection extends StatefulWidget {
  const _HeroineSection();

  @override
  State<_HeroineSection> createState() => _HeroineSectionState();
}

class _HeroineSectionState extends State<_HeroineSection> {
  _Shuttle shuttle = _Shuttle.flip;
  _MotionKind motion = _MotionKind.smooth;
  int durationMs = 500;
  double extraBounce = 0;

  /// Final spring bounce: the preset's base value plus the slider's extra amount.
  double get _bounce =>
      switch (motion) {
        _MotionKind.smooth => 0.0,
        _MotionKind.bouncy => 0.3,
        _MotionKind.snappy => 0.15,
      } +
      extraBounce;

  Map<String, Object?> _spec() {
    // Converting (duration, bounce) into spring physics — the Apple/SwiftUI
    // formula, also used by CupertinoMotion. Mass = 1.
    final d = durationMs / 1000;
    final stiffness = math.pow(2 * math.pi / d, 2);
    final damping = 4 * math.pi * (1 - _bounce) / d;
    return {
      'widget': 'Heroine + HeroineController (package:heroine)',
      'shared_element_tag': 'hero-<id>',
      'shuttle': shuttle.name,
      'motion': 'CupertinoMotion.${motion.name}',
      'spring': {
        'duration_ms': durationMs,
        'bounce': double.parse(_bounce.toStringAsFixed(2)),
        'figma_spring':
            'spring(${stiffness.round()}, ${damping.toStringAsFixed(1)}, 1)',
        'stiffness': stiffness.round(),
        'damping': double.parse(damping.toStringAsFixed(1)),
        'mass': 1,
      },
      'route_fade': {
        'duration_ms': durationMs,
        'opacity_from': 0,
        'opacity_to': 1,
      },
      'drag_to_dismiss': {
        'dismiss_distance_px': 140,
        'dismiss_velocity_px_s': 1000,
        'background': tr(
          'fades in proportion to the drag',
          'тает пропорционально перетаскиванию',
        ),
      },
      'from': {'size_px': 72, 'border_radius_px': 16},
      'to': {'size_px': 220, 'border_radius_px': 28},
      'colors': {for (final i in _items()) i.title: hexColor(i.color)},
    };
  }

  HeroineShuttleBuilder get _shuttleBuilder => switch (shuttle) {
    _Shuttle.fade => const FadeShuttleBuilder(),
    _Shuttle.single => const SingleShuttleBuilder(),
    _Shuttle.flip => const FlipShuttleBuilder(),
    _Shuttle.fadeThrough => const FadeThroughShuttleBuilder(),
  };

  Motion get _motion {
    final d = Duration(milliseconds: durationMs);
    return switch (motion) {
      _MotionKind.smooth => CupertinoMotion.smooth(
        duration: d,
        extraBounce: extraBounce,
      ),
      _MotionKind.bouncy => CupertinoMotion.bouncy(
        duration: d,
        extraBounce: extraBounce,
      ),
      _MotionKind.snappy => CupertinoMotion.snappy(
        duration: d,
        extraBounce: extraBounce,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: tr(
        'Heroine (heroine package, spring physics)',
        'Heroine (пакет heroine, пружинная физика)',
      ),
      spec: _spec,
      description: tr(
        'The same trick with springs: pick a shuttle-builder (exactly how the '
            'elements morph into each other), a spring (motion), and tap a tile. '
            'On the detail page you can drag the card with a finger — it springs '
            'back or closes the screen (drag-to-dismiss), fading the background '
            'as it goes.',
        'Тот же приём на пружинах: выбери shuttle-builder (как именно '
            'элементы перетекают друг в друга), пружину (motion) и тапни плитку. '
            'На детальной странице карточку можно утащить пальцем — она пружинисто '
            'вернётся или закроет экран (drag-to-dismiss), а фон при этом тает.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledDropdown<_Shuttle>(
            label: 'Shuttle builder',
            value: shuttle,
            values: _Shuttle.values,
            itemLabel: (s) => switch (s) {
              _Shuttle.fade => tr(
                'Fade (smooth dissolve)',
                'Fade (плавное растворение)',
              ),
              _Shuttle.single => tr(
                'Single (like Flutter Hero)',
                'Single (как у Flutter Hero)',
              ),
              _Shuttle.flip => tr('Flip (3D flip)', 'Flip (3D-переворот)'),
              _Shuttle.fadeThrough => tr(
                'Fade through (via a color)',
                'Fade through (через цвет)',
              ),
            },
            onChanged: (v) => setState(() => shuttle = v),
          ),
          _LabeledDropdown<_MotionKind>(
            label: tr('Motion (spring)', 'Motion (пружина)'),
            value: motion,
            values: _MotionKind.values,
            itemLabel: (m) => switch (m) {
              _MotionKind.smooth => tr(
                'Smooth (no bounce)',
                'Smooth (без отскока)',
              ),
              _MotionKind.bouncy => tr(
                'Bouncy (with bounce)',
                'Bouncy (с отскоком)',
              ),
              _MotionKind.snappy => tr('Snappy (sharp)', 'Snappy (резкая)'),
            },
            onChanged: (v) => setState(() => motion = v),
          ),
          LabeledSlider(
            label: tr(
              'Speed (spring duration)',
              'Скорость (длительность пружины)',
            ),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr(
              'Extra bounce (extraBounce) · result ${_bounce.toStringAsFixed(2)}',
              'Доп. отскок (extraBounce) · итог ${_bounce.toStringAsFixed(2)}',
            ),
            value: extraBounce,
            min: 0,
            max: 0.5,
            fractionDigits: 2,
            onChanged: (v) => setState(() => extraBounce = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _items())
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    _HeroineRoute(
                      duration: Duration(milliseconds: durationMs),
                      builder: (_) => _HeroineDetailPage(
                        item: item,
                        motion: _motion,
                        shuttle: _shuttleBuilder,
                      ),
                    ),
                  ),
                  child: Heroine(
                    tag: 'hero-${item.id}',
                    motion: _motion,
                    flightShuttleBuilder: _shuttleBuilder,
                    child: _Thumb(item),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A transparent route that reacts to Heroine's drag-dismiss gesture: while
/// dragging, the screen below is visible, and the detail page's content can
/// be faded out via [ReactToHeroineDismiss].
class _HeroineRoute<T> extends PageRoute<T> with HeroinePageRouteMixin<T> {
  _HeroineRoute({required this.builder, required this.duration});

  final WidgetBuilder builder;

  /// Route animation duration. The shuttle-builder (e.g. a flip) is driven
  /// precisely by routeAnimation, so we keep it equal to the spring's
  /// duration — otherwise the flip speed won't match the flight.
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Heroine itself draws the element's flight; the page just fades in smoothly.
    return FadeTransition(opacity: animation, child: child);
  }
}

class _HeroineDetailPage extends StatelessWidget {
  const _HeroineDetailPage({
    required this.item,
    required this.motion,
    required this.shuttle,
  });

  final _Item item;
  final Motion motion;
  final HeroineShuttleBuilder shuttle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Transparent background: the route's opaque=false, so as the
      // background layer fades, the screen below shows through it.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The background, title, and hint fade out as the card is dragged.
          Positioned.fill(
            child: ReactToHeroineDismiss(
              builder: (context, progress, offset, child) => Opacity(
                opacity: (1 - progress).clamp(0.0, 1.0),
                child: child,
              ),
              child: ColoredBox(
                color: scheme.surface,
                child: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const BackButton(),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text(
                          tr(
                            'Drag the card to close',
                            'Утащи карточку, чтобы закрыть',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The card stays opaque while it's being dragged.
          Center(
            child: DragDismissable(
              child: Heroine(
                tag: 'hero-${item.id}',
                motion: motion,
                flightShuttleBuilder: shuttle,
                child: _BigCard(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── helpers

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: [
            for (final v in values)
              DropdownMenuItem(value: v, child: Text(itemLabel(v))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// Playground preview: the element flies from a list row to the detail
/// screen's header, and the detail screen's background fades in.
Widget _heroPreview(BuildContext context, BriefValues v, double t) {
  const w = 260.0, h = 200.0;
  final e = v.curve('curve').transform(t);
  final from = v.number('from_size_px'), to = v.number('to_size_px');
  final begin = Rect.fromLTWH(16, h - 16 - from, from, from);
  final end = Rect.fromLTWH((w - to) / 2, 12, to, to);
  final rect = v.text('path') == tr('Arc', 'дуга')
      ? MaterialRectArcTween(begin: begin, end: end).lerp(e)
      : Rect.lerp(begin, end, e)!;
  final radius =
      v.number('from_radius_px') +
      (v.number('to_radius_px') - v.number('from_radius_px')) * e;
  final color = v.color('color');
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          // List: the source element and neighboring rows.
          for (var i = 0; i < 3; i++)
            Positioned(
              left: 16 + from + 12,
              right: 16,
              top: h - 16 - from + from / 2 - 6 - i * (from + 10),
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          // The detail screen's background fades in together with the flight.
          Positioned.fill(
            child: Opacity(
              opacity: t,
              child: ColoredBox(color: color.withValues(alpha: 0.10)),
            ),
          ),
          Positioned(
            left: rect.left,
            top: rect.top,
            width: math.max(0, rect.width),
            height: math.max(0, rect.height),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius.clamp(0.0, 1000.0)),
              ),
              child: const FittedBox(
                child: Icon(Icons.photo, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
