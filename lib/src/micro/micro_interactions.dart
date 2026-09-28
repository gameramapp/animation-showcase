// Showcase of micro-interactions — small animated reactions in the UI:
//   • AnimatedIcon — all 14 built-in Material morphing icons;
//   • Like — a "springy" heart, a burst of sparks, and a flipping counter;
//   • Tap feedback — squeeze, spring, lift;
//   • Input error — the field shakes and turns red, success — a green checkmark;
//   • Switches — day/night and a segmented control with a "sliding" indicator;
//   • Loaders — dots, pulse, skeleton shimmer, and built-in indicators.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/intro_card.dart';
import '../common/i18n.dart';

/// Card title with the "Spec" button on the right.
class _TitleWithSpec extends StatelessWidget {
  const _TitleWithSpec({required this.title, required this.spec});
  final String title;
  final Map<String, Object?> Function() spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        SpecButton(title: title, spec: spec),
      ],
    );
  }
}

class MicroInteractionsDemo extends StatelessWidget {
  const MicroInteractionsDemo({super.key});
  static const String routeName = 'micro/interactions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Micro-interactions', 'Микро-взаимодействия')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Micro-interactions', 'Микро-взаимодействия'),
            text: tr(
              'Small animated responses to user actions: tap — the button '
                  'reacts, a mistake — the field shakes, a like — the heart '
                  'jumps. Each lasts 150–600 ms, but these are exactly what '
                  'makes an interface feel "alive". Everything below uses '
                  'stock Flutter, no third-party packages.',
              'Маленькие анимации-ответы на действия пользователя: нажал — '
                  'кнопка откликнулась, ошибся — поле встряхнулось, лайкнул — '
                  'сердце подпрыгнуло. Каждая длится 150–600 мс, но именно они '
                  'делают интерфейс «живым». Всё ниже — на стандартных средствах '
                  'Flutter, без сторонних пакетов.',
            ),
            hint: tr(
              'Everything is clickable: tap, press and hold, type text.',
              'Всё кликабельно: тапай, нажимай и удерживай, вводи текст.',
            ),
          ),
          const SizedBox(height: 16),
          const _AnimatedIconsBlock(),
          const SizedBox(height: 16),
          const _LikeBlock(),
          const SizedBox(height: 16),
          const _PressBlock(),
          const SizedBox(height: 16),
          const _ShakeBlock(),
          const SizedBox(height: 16),
          const _TogglesBlock(),
          const SizedBox(height: 16),
          const _LoadersBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            items: [
              (
                tr('Trigger', 'Триггер'),
                tr(
                  'what starts the animation: tap, hold, hover, validation error, server response',
                  'что запускает анимацию: тап, удержание, наведение, ошибка валидации, ответ сервера',
                ),
              ),
              (
                tr('States', 'Состояния'),
                tr(
                  'list of states (idle / pressed / success / error / loading…) and what each looks like',
                  'список состояний (idle / pressed / success / error / loading…) и как выглядит каждое',
                ),
              ),
              (
                tr('Transitions', 'Переходы'),
                tr(
                  'for each transition between states — duration in ms and curve: preset, cubic-bezier(…) from Figma, or spring(stiffness, damping, mass)',
                  'для каждого перехода между состояниями — длительность в мс и кривая: пресет, cubic-bezier(…) из Figma или spring(stiffness, damping, mass)',
                ),
              ),
              (
                tr('Magnitudes', 'Величины'),
                tr(
                  'press scale (×), lift and shadow (px), shake amplitude (px) and number of oscillations, like-jump strength (×)',
                  'масштаб при нажатии (×), подъём и тень (px), амплитуда тряски (px) и число качаний, сила прыжка лайка (×)',
                ),
              ),
              (
                tr('Colors', 'Цвета'),
                tr(
                  '#hex for each state: normal, error, success, like; gradients — all stops',
                  '#hex для каждого состояния: обычное, ошибка, успех, лайк; градиенты — все точки',
                ),
              ),
              (
                tr('Morph icons', 'Иконки-морфы'),
                tr(
                  'a "from → to" pair (e.g. menu → arrow); if the pair you need isn\'t among the 14 built-in ones — SVG for both states',
                  'пара «из → в» (например menu → arrow); если нужной пары нет среди 14 встроенных — SVG обоих состояний',
                ),
              ),
              (
                tr('Loaders', 'Лоадеры'),
                tr(
                  'duration of one cycle in ms, sizes and colors of the elements, phase shift between dots/rings',
                  'длительность одного цикла в мс, размеры и цвета элементов, сдвиг фазы между точками/кольцами',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't send just a video without numbers — timings guessed \"by eye\" won't match.",
                'Не присылать только видео без цифр — тайминги «на глаз» не совпадут.',
              ),
              tr(
                'A morph between arbitrary icons — AnimatedIcon only knows the 14 built-in pairs; for your own you need Lottie/Rive.',
                'Морф между произвольными иконками — AnimatedIcon умеет только 14 встроенных пар; для своих нужен Lottie/Rive.',
              ),
            ],
            playground: BriefPlayground(
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), [
                  tr('Like', 'Лайк'),
                  tr('Shake', 'Тряска'),
                  tr('Press', 'Нажатие'),
                  tr('Switch', 'Переключатель'),
                ], tr('Like', 'Лайк')),
                BriefField.duration(
                  'duration_ms',
                  tr('Transition duration', 'Длительность перехода'),
                  500,
                ),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeOutBack'),
                BriefField.number(
                  'like_scale',
                  tr('Like jump', 'Прыжок лайка'),
                  1.35,
                  unit: '×',
                  min: 0.5,
                  max: 3,
                ),
                BriefField.number(
                  'press_scale',
                  tr('Press scale', 'Масштаб при нажатии'),
                  0.92,
                  unit: '×',
                  min: 0.3,
                  max: 1.5,
                ),
                BriefField.number(
                  'shake_px',
                  tr('Shake amplitude', 'Амплитуда тряски'),
                  12,
                  unit: 'px',
                  min: 0,
                  max: 100,
                ),
                BriefField.number(
                  'shake_count',
                  tr('Oscillations', 'Качаний'),
                  4,
                  min: 1,
                  max: 20,
                ),
                BriefField.color(
                  'color',
                  tr('Active state color', 'Цвет активного состояния'),
                  '#E91E63',
                ),
                BriefField.color(
                  'color_idle',
                  tr('Idle state color', 'Цвет обычного состояния'),
                  '#9E9E9E',
                ),
              ],
              builder: _microPlayground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── brief playground

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Playground preview: one of the four main effects using the entered values.
Widget _microPlayground(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final k = e.clamp(0.0, 1.0);
  final color = v.color('color');
  final idle = v.color('color_idle');
  final effect = v.text('effect');
  if (effect == tr('Shake', 'Тряска')) {
    // Shaking always follows a decaying sine wave; the curve is for the border color change.
    final dx =
        math.sin(t * math.pi * 2 * v.number('shake_count')) *
        v.number('shake_px') *
        (1 - t);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Container(
        width: 200,
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.lerp(idle, color, k)!, width: 2),
        ),
        child: Text(
          tr('Code', 'Код'),
          style: const TextStyle(color: Colors.black38),
        ),
      ),
    );
  } else if (effect == tr('Press', 'Нажатие')) {
    return Transform.scale(
      scale: _lerp(1, v.number('press_scale'), e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Color.lerp(kAccent, color, k),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          tr('Button', 'Кнопка'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  } else if (effect == tr('Switch', 'Переключатель')) {
    return Container(
      width: 120,
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color.lerp(idle, color, k),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Align(
        alignment: Alignment(_lerp(-1, 1, e), 0),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
      ),
    );
  } else {
    // Like: bounces up to the "Jump" value and returns to 1×.
    final scale = 1 + (v.number('like_scale') - 1) * math.sin(math.pi * k);
    return Transform.scale(
      scale: scale,
      child: Icon(
        t > 0.05 ? Icons.favorite : Icons.favorite_border,
        size: 72,
        color: Color.lerp(idle, color, (t * 4).clamp(0.0, 1.0)),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────── AnimatedIcon

const _animatedIcons = <String, AnimatedIconData>{
  'menu_arrow': AnimatedIcons.menu_arrow,
  'menu_close': AnimatedIcons.menu_close,
  'menu_home': AnimatedIcons.menu_home,
  'play_pause': AnimatedIcons.play_pause,
  'pause_play': AnimatedIcons.pause_play,
  'add_event': AnimatedIcons.add_event,
  'event_add': AnimatedIcons.event_add,
  'arrow_menu': AnimatedIcons.arrow_menu,
  'close_menu': AnimatedIcons.close_menu,
  'home_menu': AnimatedIcons.home_menu,
  'list_view': AnimatedIcons.list_view,
  'view_list': AnimatedIcons.view_list,
  'search_ellipsis': AnimatedIcons.search_ellipsis,
  'ellipsis_search': AnimatedIcons.ellipsis_search,
};

class _AnimatedIconsBlock extends StatefulWidget {
  const _AnimatedIconsBlock();

  @override
  State<_AnimatedIconsBlock> createState() => _AnimatedIconsBlockState();
}

class _AnimatedIconsBlockState extends State<_AnimatedIconsBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  bool _auto = true;
  int _durationMs = 450;
  int _pauseMs = 1000;
  String _curve = 'easeInOut';

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
    _curved = CurvedAnimation(parent: _controller, curve: resolveCurve(_curve));
  }

  void _onStatus(AnimationStatus status) {
    Future.delayed(Duration(milliseconds: _pauseMs), () {
      if (!mounted || !_auto || _controller.isAnimating) return;
      if (status == AnimationStatus.completed) _controller.reverse();
      if (status == AnimationStatus.dismissed) _controller.forward();
    });
  }

  void _toggle() {
    setState(() => _auto = false);
    _controller.status.isForwardOrCompleted
        ? _controller.reverse()
        : _controller.forward();
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleWithSpec(
              title: tr(
                'AnimatedIcon — built-in icon morphs',
                'AnimatedIcon — встроенные иконки-морфы',
              ),
              spec: () => {
                'widget':
                    'AnimatedIcon (AnimatedIcons.*) + AnimationController + CurvedAnimation',
                'trigger': _auto ? 'auto ping-pong' : 'tap',
                ...timingSpec(durationMs: _durationMs, curve: _curve),
                'reverse': tr(
                  'same duration and curve, in reverse',
                  'та же длительность и кривая в обратную сторону',
                ),
                if (_auto) 'auto_pause_ms': _pauseMs,
                'icon_size_px': 36,
                'color': hexColor(kAccent),
                'icons': _animatedIcons.keys.toList(),
              },
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Material has 14 built-in icons that morph one into another out '
                    'of the box: hamburger → arrow, play → pause, search → menu, etc. '
                    'Tap any of them — all of them switch.',
                'Material из коробки умеет 14 иконок, которые перетекают одна в '
                    'другую: гамбургер → стрелка, play → pause, поиск → меню и т. д. '
                    'Тапни по любой — переключатся все.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 130,
              children: [
                for (final MapEntry(key: name, value: icon)
                    in _animatedIcons.entries)
                  Card.outlined(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _toggle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            AnimatedIcon(
                              icon: icon,
                              progress: _curved,
                              size: 36,
                              color: kAccent,
                            ),
                            const SizedBox(height: 6),
                            Text(name, style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: Text(tr('Auto', 'Авто')),
                  selected: _auto,
                  onSelected: (v) {
                    setState(() => _auto = v);
                    if (v) _onStatus(_controller.status);
                  },
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Duration', 'Длительность'),
                    value: _durationMs.toDouble(),
                    min: 150,
                    max: 1500,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) {
                      setState(() => _durationMs = v.round());
                      _controller.duration = Duration(
                        milliseconds: _durationMs,
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr(
                      'Pause between cycles (auto)',
                      'Пауза между циклами (авто)',
                    ),
                    value: _pauseMs.toDouble(),
                    min: 0,
                    max: 3000,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) => setState(() => _pauseMs = v.round()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: CurveDropdown(
                    value: _curve,
                    onChanged: (v) {
                      setState(() => _curve = v);
                      _curved.curve = resolveCurve(v);
                    },
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

// ─────────────────────────────────────────────────────────────────── Like

class _LikeBlock extends StatefulWidget {
  const _LikeBlock();

  @override
  State<_LikeBlock> createState() => _LikeBlockState();
}

class _LikeBlockState extends State<_LikeBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;
  bool _liked = false;
  int _count = 41;
  bool _burst = true;
  double _bounce = 1.35;
  double _squash = 0.6;
  int _durationMs = 700;
  Timer? _demo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _scale = _buildScale();
    // Until the user taps it themselves — we auto-like so the effect is visible.
    _demo = Timer.periodic(
      const Duration(milliseconds: 2200),
      (_) => _toggle(),
    );
  }

  Animation<double> _buildScale() => TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _squash,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 15,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _squash,
        end: _bounce,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _bounce,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 55,
    ),
  ]).animate(_controller);

  void _toggle() {
    setState(() {
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    if (_liked) _controller.forward(from: 0);
  }

  Map<String, Object?> _spec() {
    int part(int weight) => (_durationMs * weight / 100).round();
    return {
      'widget': tr(
        'TweenSequence (Transform.scale) + CustomPainter (sparks) + AnimatedSwitcher (icon and counter)',
        'TweenSequence (Transform.scale) + CustomPainter (искры) + AnimatedSwitcher (иконка и счётчик)',
      ),
      'trigger': tr(
        'tap (like); removing the like — no scale animation',
        'tap (лайк); снятие лайка — без анимации масштаба',
      ),
      'duration_ms': _durationMs,
      'heart_scale_sequence': [
        {
          'from_scale': 1.0,
          'to_scale': _squash,
          ...timingSpec(durationMs: part(15), curve: 'easeIn'),
        },
        {
          'from_scale': _squash,
          'to_scale': _bounce,
          ...timingSpec(durationMs: part(30), curve: 'easeOut'),
        },
        {
          'from_scale': _bounce,
          'to_scale': 1.0,
          ...timingSpec(durationMs: part(55), curve: 'elasticOut'),
        },
      ],
      'icon_size_px': 64,
      'icon_swap': {
        'from': 'favorite_border',
        'to': 'favorite',
        'crossfade_ms': 150,
      },
      'color_liked': hexColor(Colors.pink),
      'color_idle': hexColor(Colors.black45),
      'burst': _burst
          ? {
              'ring': {
                'radius_px': [20, 56],
                'stroke_px': [6, 0],
                'color': hexColor(Colors.pink.withValues(alpha: 0.5)),
              },
              'sparks_count': 8,
              'spark_distance_px': [30, 60],
              'spark_radius_px': [5, 1],
              'spark_colors': [
                for (final c in _BurstPainter._colors) hexColor(c),
              ],
              'expand': {
                'delay_ms': part(10),
                ...timingSpec(durationMs: part(60), curve: 'easeOutCubic'),
              },
              'fade_out': {'delay_ms': part(40), 'duration_ms': part(40)},
            }
          : false,
      'counter': {
        'widget': 'AnimatedSwitcher: SlideTransition + FadeTransition',
        ...timingSpec(durationMs: 250, curve: 'linear'),
        'direction': tr(
          'like — new digit bottom to top, unlike — top to bottom',
          'лайк — новая цифра снизу вверх, дизлайк — сверху вниз',
        ),
        'font_size_px': 28,
      },
    };
  }

  @override
  void dispose() {
    _demo?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Like', 'Лайк'),
      spec: _spec,
      description: tr(
        'The heart first "squashes down", then bounces and springs '
            '(TweenSequence), sparks fly out around it (CustomPainter), and '
            'the counter flips the digit up or down (AnimatedSwitcher).',
        'Сердце сначала «приседает», потом подпрыгивает и пружинит '
            '(TweenSequence), вокруг разлетаются искры (CustomPainter), а '
            'счётчик перелистывается цифрой вверх или вниз (AnimatedSwitcher).',
      ),
      preview: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _demo?.cancel();
              _toggle();
            },
            child: SizedBox.square(
              dimension: 120,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _burst && _liked
                      ? _BurstPainter(_controller.value)
                      : null,
                  child: Transform.scale(
                    scale: _liked ? _scale.value : 1,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_liked),
                        size: 64,
                        color: _liked ? Colors.pink : Colors.black45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                // Like: the new digit comes in from below, the old one leaves upward; unlike — the reverse.
                final incoming = child.key == ValueKey(_count);
                final dy = (incoming == _liked) ? 1.0 : -1.0;
                return ClipRect(
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(0, dy),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Text(
                '$_count',
                key: ValueKey(_count),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            label: Text(tr('Sparks', 'Искры')),
            selected: _burst,
            onSelected: (v) => setState(() => _burst = v),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 300,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              _controller.duration = Duration(milliseconds: _durationMs);
            },
          ),
          LabeledSlider(
            label: tr('Squash', 'Приседание'),
            value: _squash,
            min: 0.3,
            max: 1,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => setState(() {
              _squash = v;
              _scale = _buildScale();
            }),
          ),
          LabeledSlider(
            label: tr('Jump strength', 'Сила прыжка'),
            value: _bounce,
            min: 1,
            max: 2,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => setState(() {
              _bounce = v;
              _scale = _buildScale();
            }),
          ),
          Text(
            tr('Tap the heart.', 'Тапни по сердцу.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);
  final double t;

  static const _colors = [Colors.pink, Colors.orange, kAccent, Colors.amber];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.1 || t >= 1) return;
    final center = size.center(Offset.zero);
    final p = Curves.easeOutCubic.transform(((t - 0.1) / 0.6).clamp(0.0, 1.0));
    final fade = 1 - ((t - 0.4) / 0.4).clamp(0.0, 1.0);
    // Ripple ring.
    canvas.drawCircle(
      center,
      20 + 36 * p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - p)
        ..color = Colors.pink.withValues(alpha: 0.5 * fade),
    );
    // Sparks.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = 30 + 30 * p;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * r,
        4 * (1 - p) + 1,
        Paint()..color = _colors[i % _colors.length].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

// ──────────────────────────────────────────────────────── tap feedback

class _PressBlock extends StatefulWidget {
  const _PressBlock();

  @override
  State<_PressBlock> createState() => _PressBlockState();
}

class _PressBlockState extends State<_PressBlock> {
  double _pressScale = 0.92;
  int _durationMs = 120;
  String _springCurve = 'elasticOut';
  double _liftPx = 6;

  Map<String, Object?> _spec() {
    final liftLabel = tr('Lift', 'Подъём');
    return {
      'widget': tr(
        'AnimatedScale + AnimatedContainer (transform, boxShadow) on GestureDetector/MouseRegion',
        'AnimatedScale + AnimatedContainer (transform, boxShadow) на GestureDetector/MouseRegion',
      ),
      'trigger': tr(
        'pointer down → pressed, pointer up / cancel → release; "$liftLabel" also on hover',
        'pointer down → pressed, pointer up / cancel → release; «$liftLabel» ещё и на hover',
      ),
      'button': {
        'padding_px': [20, 14],
        'radius_px': 14,
        'color': hexColor(kAccent),
        'label_color': hexColor(Colors.white),
      },
      'variants': {
        'squeeze': {
          'pressed_scale': _pressScale,
          'press': timingSpec(durationMs: _durationMs, curve: 'easeOut'),
          'release': timingSpec(durationMs: _durationMs, curve: 'easeOut'),
        },
        'spring': {
          'pressed_scale': _pressScale,
          'press': timingSpec(durationMs: _durationMs, curve: 'easeOut'),
          'release': timingSpec(
            durationMs: _durationMs * 5,
            curve: _springCurve,
          ),
        },
        'lift': {
          'pressed_scale': 1.0,
          'lift_offset_px': -_liftPx,
          'shadow_idle': {
            'color': hexColor(Colors.black.withValues(alpha: 0.12)),
            'blur_px': 4,
            'offset_y_px': 2,
          },
          'shadow_raised': {
            'color': hexColor(Colors.black.withValues(alpha: 0.3)),
            'blur_px': 18,
            'offset_y_px': 10,
          },
          'press': timingSpec(durationMs: _durationMs, curve: 'easeOut'),
          'release': timingSpec(durationMs: _durationMs * 2, curve: 'easeOut'),
        },
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final squeezeLabel = tr('Squeeze', 'Сжатие');
    final springLabel = tr('Spring', 'Пружина');
    final liftLabel = tr('Lift', 'Подъём');
    return AnimBlock(
      title: tr('Press feedback', 'Отклик на нажатие'),
      spec: _spec,
      description: tr(
        'Three flavors of button reaction: "$squeezeLabel" — quickly shrinks '
            'under the finger; "$springLabel" — squeezes and springs back on '
            'release (elasticOut); "$liftLabel" — rises and casts a shadow on '
            'hover/press. Press and hold.',
        'Три характера реакции кнопки: «Сжатие» — быстро уменьшается под '
            'пальцем; «Пружина» — сжимается и отпружинивает при отпускании '
            '(elasticOut); «Подъём» — при наведении/нажатии поднимается и '
            'отбрасывает тень. Нажми и удерживай.',
      ),
      preview: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _PressableButton(
            label: squeezeLabel,
            pressScale: _pressScale,
            pressDuration: Duration(milliseconds: _durationMs),
            releaseDuration: Duration(milliseconds: _durationMs),
            releaseCurve: Curves.easeOut,
          ),
          _PressableButton(
            label: springLabel,
            pressScale: _pressScale,
            pressDuration: Duration(milliseconds: _durationMs),
            releaseDuration: Duration(milliseconds: _durationMs * 5),
            releaseCurve: resolveCurve(_springCurve),
          ),
          _PressableButton(
            label: liftLabel,
            pressScale: 1,
            lift: true,
            liftPx: _liftPx,
            pressDuration: Duration(milliseconds: _durationMs),
            releaseDuration: Duration(milliseconds: _durationMs * 2),
            releaseCurve: Curves.easeOut,
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            label: tr('Press scale', 'Масштаб при нажатии'),
            value: _pressScale,
            min: 0.7,
            max: 1,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => setState(() => _pressScale = v),
          ),
          LabeledSlider(
            label: tr('Response speed', 'Скорость реакции'),
            value: _durationMs.toDouble(),
            min: 50,
            max: 400,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Lift (for "$liftLabel")', 'Подъём (у «$liftLabel»)'),
            value: _liftPx,
            min: 0,
            max: 16,
            unit: 'px',
            onChanged: (v) => setState(() => _liftPx = v),
          ),
          Text(
            tr('Release for "$springLabel"', 'Отпускание «Пружины»'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CurveDropdown(
            value: _springCurve,
            onChanged: (v) => setState(() => _springCurve = v),
          ),
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  const _PressableButton({
    required this.label,
    required this.pressScale,
    required this.pressDuration,
    required this.releaseDuration,
    required this.releaseCurve,
    this.lift = false,
    this.liftPx = 6,
  });

  final String label;
  final double pressScale;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve releaseCurve;
  final bool lift;
  final double liftPx;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final raised = widget.lift && (_pressed || _hovered);
    final duration = _pressed ? widget.pressDuration : widget.releaseDuration;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressScale : 1,
          duration: duration,
          curve: _pressed ? Curves.easeOut : widget.releaseCurve,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              raised ? -widget.liftPx : 0,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: raised ? 0.3 : 0.12),
                  blurRadius: raised ? 18 : 4,
                  offset: Offset(0, raised ? 10 : 2),
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── input error

class _ShakeBlock extends StatefulWidget {
  const _ShakeBlock();

  @override
  State<_ShakeBlock> createState() => _ShakeBlockState();
}

enum _FieldState { idle, error, success }

class _ShakeBlockState extends State<_ShakeBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _text = TextEditingController();
  _FieldState _state = _FieldState.idle;
  double _amplitude = 12;
  int _shakes = 4;
  int _durationMs = 500;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
  }

  Map<String, Object?> _spec() => {
    'widget': tr(
      'AnimationController + Transform.translate (decaying sine wave), AnimatedContainer (border), AnimatedSwitcher (icon)',
      'AnimationController + Transform.translate (затухающая синусоида), AnimatedContainer (рамка), AnimatedSwitcher (иконка)',
    ),
    'trigger': tr(
      'submit with a wrong value → error; correct → success; typing → idle',
      'submit с неверным значением → error; верное → success; ввод текста → idle',
    ),
    'shake': {
      ...timingSpec(durationMs: _durationMs, curve: 'linear'),
      'amplitude_px': _amplitude.round(),
      'oscillations': _shakes,
      'axis': 'x',
      'decay': tr(
        'linear decay of amplitude to 0 by the end',
        'линейное затухание амплитуды до 0 к концу',
      ),
      'formula': 'dx = sin(t · 2π · oscillations) · amplitude_px · (1 − t)',
    },
    'border': {
      ...timingSpec(durationMs: 250, curve: 'linear'),
      'width_px': 2,
      'radius_px': 12,
      'color_idle': hexColor(Colors.black26),
      'color_error': hexColor(Colors.red),
      'color_success': hexColor(Colors.green),
    },
    'status_icon': {
      'transition': 'scale',
      ...timingSpec(durationMs: 300, curve: 'linear'),
      'error_icon': 'error',
      'success_icon': 'check_circle',
    },
  };

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (_text.text == '1234') {
      setState(() => _state = _FieldState.success);
    } else {
      setState(() => _state = _FieldState.error);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (_state) {
      _FieldState.idle => Colors.black26,
      _FieldState.error => Colors.red,
      _FieldState.success => Colors.green,
    };
    return AnimBlock(
      title: tr('Input error: shake', 'Ошибка ввода: тряска'),
      spec: _spec,
      description: tr(
        'A wrong entry — the field shakes along a decaying sine wave and '
            'turns red. Correct — the border turns green, a checkmark appears. '
            'The right code: 1234. Shaking is the clearest wordless "no" gesture.',
        'Неверный ввод — поле трясётся по затухающей синусоиде и краснеет. '
            'Верный — рамка зеленеет, появляется галочка. Правильный код: 1234. '
            'Тряска — самый понятный жест «нет» без слов.',
      ),
      preview: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final dx =
                    math.sin(t * math.pi * 2 * _shakes) * _amplitude * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_state != _FieldState.idle) {
                            setState(() => _state = _FieldState.idle);
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: tr('Code', 'Код'),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: switch (_state) {
                        _FieldState.idle => const SizedBox(
                          key: ValueKey('idle'),
                          width: 24,
                        ),
                        _FieldState.error => const Icon(
                          Icons.error,
                          key: ValueKey('e'),
                          color: Colors.red,
                        ),
                        _FieldState.success => const Icon(
                          Icons.check_circle,
                          key: ValueKey('s'),
                          color: Colors.green,
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: Text(tr('Log in', 'Войти')),
            ),
          ],
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: () {
              _text.clear();
              _submit();
            },
            icon: const Icon(Icons.vibration),
            label: Text(tr('Show error', 'Показать ошибку')),
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Amplitude', 'Амплитуда'),
            value: _amplitude,
            min: 2,
            max: 30,
            unit: 'px',
            onChanged: (v) => setState(() => _amplitude = v),
          ),
          LabeledSlider(
            label: tr('Number of oscillations', 'Количество качаний'),
            value: _shakes.toDouble(),
            min: 1,
            max: 8,
            onChanged: (v) => setState(() => _shakes = v.round()),
          ),
          LabeledSlider(
            label: tr('Shake duration', 'Длительность тряски'),
            value: _durationMs.toDouble(),
            min: 150,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              _controller.duration = Duration(milliseconds: _durationMs);
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── switches

class _TogglesBlock extends StatefulWidget {
  const _TogglesBlock();

  @override
  State<_TogglesBlock> createState() => _TogglesBlockState();
}

class _TogglesBlockState extends State<_TogglesBlock> {
  bool _night = false;
  int _segment = 0;
  int _durationMs = 400;
  String _curve = 'easeOutBack';
  Timer? _demo;

  @override
  void initState() {
    super.initState();
    _demo = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      setState(() {
        if (timer.tick.isEven) {
          _night = !_night;
        } else {
          _segment = (_segment + 1) % 3;
        }
      });
    });
  }

  @override
  void dispose() {
    _demo?.cancel();
    super.dispose();
  }

  void _stopDemo() => _demo?.cancel();

  Map<String, Object?> _spec() => {
    'widget': tr(
      'AnimatedContainer + AnimatedAlign + AnimatedSwitcher (day/night); AnimatedPositioned + AnimatedDefaultTextStyle (segments)',
      'AnimatedContainer + AnimatedAlign + AnimatedSwitcher (день/ночь); AnimatedPositioned + AnimatedDefaultTextStyle (сегменты)',
    ),
    'trigger': tr(
      'tap; until touched — auto-switches every 1600 ms',
      'tap; пока не тронули — автопереключение каждые 1600 мс',
    ),
    'day_night_switch': {
      'size_px': [120, 56],
      'padding_px': 6,
      'knob_size_px': 44,
      'knob_color': hexColor(Colors.white),
      'knob_shadow': {'color': hexColor(Colors.black26), 'blur_px': 6},
      'knob_move': timingSpec(durationMs: _durationMs, curve: _curve),
      'background': {
        ...timingSpec(durationMs: _durationMs, curve: 'easeInOut'),
        'gradient_day': [
          hexColor(const Color(0xFF81D4FA)),
          hexColor(const Color(0xFFFFE082)),
        ],
        'gradient_night': [
          hexColor(const Color(0xFF1A237E)),
          hexColor(const Color(0xFF311B92)),
        ],
      },
      'icon_swap': {
        'from': 'wb_sunny',
        'to': 'nightlight_round',
        'transition': 'rotate 0.5 → 1 turn + scale 0 → 1',
        ...timingSpec(durationMs: _durationMs, curve: 'linear'),
        'color_day': hexColor(Colors.orange),
        'color_night': hexColor(const Color(0xFF311B92)),
      },
    },
    'segmented_control': {
      'size_px': [240, 40],
      'items': 3,
      'pill_inset_px': 3,
      'pill_color': hexColor(kAccent),
      'pill_move': timingSpec(durationMs: _durationMs, curve: _curve),
      'label': {
        ...timingSpec(durationMs: _durationMs, curve: 'linear'),
        'color_selected': hexColor(Colors.white),
        'color_idle': hexColor(Colors.black87),
        'weight_selected': 600,
        'weight_idle': 400,
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: _durationMs);
    final curve = resolveCurve(_curve);
    return AnimBlock(
      title: tr('Switches', 'Переключатели'),
      spec: _spec,
      description: tr(
        'A custom "day/night" switch: the knob slides (AnimatedAlign), the '
            'background blends (AnimatedContainer), the icon rotates on change '
            '(AnimatedSwitcher). Below — a segmented control where the '
            'selection pill moves under the chosen item. Until you touch it — '
            'they switch on their own.',
        'Кастомный переключатель «день/ночь»: ползунок едет (AnimatedAlign), '
            'фон перетекает (AnimatedContainer), иконка вращается при смене '
            '(AnimatedSwitcher). Ниже — сегмент-контрол, где плашка выбора '
            'переезжает под нужный пункт. Пока не тронешь — щёлкают сами.',
      ),
      preview: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _stopDemo();
              setState(() => _night = !_night);
            },
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeInOut,
              width: 120,
              height: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: _night
                      ? const [Color(0xFF1A237E), Color(0xFF311B92)]
                      : const [Color(0xFF81D4FA), Color(0xFFFFE082)],
                ),
              ),
              child: AnimatedAlign(
                duration: duration,
                curve: curve,
                alignment: _night
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, a) => RotationTransition(
                      turns: Tween(begin: 0.5, end: 1.0).animate(a),
                      child: ScaleTransition(scale: a, child: child),
                    ),
                    child: Icon(
                      _night ? Icons.nightlight_round : Icons.wb_sunny,
                      key: ValueKey(_night),
                      color: _night ? const Color(0xFF311B92) : Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Segmented(
            items: [
              tr('Day', 'День'),
              tr('Week', 'Неделя'),
              tr('Month', 'Месяц'),
            ],
            selected: _segment,
            duration: duration,
            curve: curve,
            onChanged: (i) {
              _stopDemo();
              setState(() => _segment = i);
            },
          ),
        ],
      ),
      controls: Column(
        children: [
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 100,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = v.round()),
          ),
          CurveDropdown(
            value: _curve,
            onChanged: (v) => setState(() => _curve = v),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.items,
    required this.selected,
    required this.duration,
    required this.curve,
    required this.onChanged,
  });

  final List<String> items;
  final int selected;
  final Duration duration;
  final Curve curve;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const width = 240.0;
    final itemWidth = width / items.length;
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: duration,
            curve: curve,
            left: itemWidth * selected + 3,
            top: 3,
            bottom: 3,
            width: itemWidth - 6,
            child: Container(
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, label) in items.indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: duration,
                        style: TextStyle(
                          color: i == selected ? Colors.white : Colors.black87,
                          fontWeight: i == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────── loaders

class _LoadersBlock extends StatefulWidget {
  const _LoadersBlock();

  @override
  State<_LoadersBlock> createState() => _LoadersBlockState();
}

class _LoadersBlockState extends State<_LoadersBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _speed = 1;
  double _dotsJump = 14;
  String _squaresCurve = 'easeInOutBack';

  int get _cycleMs => (1400 / _speed).round();

  Map<String, Object?> _spec() => {
    'widget': tr(
      'one AnimationController..repeat() + AnimatedBuilder; Material — CircularProgressIndicator / LinearProgressIndicator',
      'один AnimationController..repeat() + AnimatedBuilder; Material — CircularProgressIndicator / LinearProgressIndicator',
    ),
    'cycle_ms': _cycleMs,
    'repeat': 'loop',
    'accent_color': hexColor(kAccent),
    'bouncing_dots': {
      'count': 3,
      'size_px': 14,
      'gap_px': 8,
      'jump_px': _dotsJump.round(),
      'phase_shift_cycle': 0.15,
      'phase_shift_ms': (_cycleMs * 0.15).round(),
      'jump_part_of_cycle': 0.5,
      'motion': tr(
        'sin, up and back over the first half of the cycle, then a pause',
        'sin, вверх и обратно за первую половину цикла, дальше пауза',
      ),
    },
    'pulse': {
      'rings': 3,
      'ring_diameter_px': [24, 94],
      'ring_stroke_px': 2,
      'ring_opacity': [1, 0],
      'ring_offset_cycle': 1 / 3,
      'core_diameter_px': 24,
      'curve': 'linear',
    },
    'skeleton_shimmer': {
      'widget': 'ShaderMask + LinearGradient (BlendMode.srcATop)',
      'placeholder_color': hexColor(Colors.black12),
      'highlight_colors': [
        hexColor(Colors.black12),
        hexColor(Colors.white70),
        hexColor(Colors.black12),
      ],
      'sweep': tr(
        'left to right, 1 pass per cycle',
        'слева направо, 1 проход за цикл',
      ),
      'radius_px': 6,
    },
    'spinning_squares': {
      'outer': {
        'size_px': 44,
        'stroke_px': 4,
        'radius_px': 8,
        'color': hexColor(kAccent),
        'turns_per_cycle': 0.5,
      },
      'inner': {
        'size_px': 22,
        'radius_px': 4,
        'color': hexColor(Colors.orange),
        'turns_per_cycle': -0.5,
      },
      ...timingSpec(durationMs: _cycleMs, curve: _squaresCurve),
    },
    'material_indicators': tr(
      'standard, color from the theme (colorScheme.primary)',
      'стандартные, цвет из темы (colorScheme.primary)',
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleWithSpec(
              title: tr('Loaders and waiting', 'Лоадеры и ожидание'),
              spec: _spec,
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Loading indicators: custom ones on a single repeating '
                    'controller, and built-in Material ones. A skeleton with '
                    'shimmer stands in for content while it loads.',
                'Индикаторы загрузки: кастомные на одном повторяющемся '
                    'контроллере и встроенные Material. Скелетон с шиммером — '
                    'заглушка контента, пока он грузится.',
              ),
              style: textTheme.bodyMedium,
            ),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr(
                      'Speed (cycle $_cycleMs ms)',
                      'Скорость (цикл $_cycleMs мс)',
                    ),
                    value: _speed,
                    min: 0.25,
                    max: 3,
                    unit: '×',
                    fractionDigits: 2,
                    onChanged: (v) {
                      setState(() => _speed = v);
                      _controller
                        ..duration = Duration(milliseconds: _cycleMs)
                        ..repeat();
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Dot jump', 'Прыжок точек'),
                    value: _dotsJump,
                    min: 4,
                    max: 30,
                    unit: 'px',
                    onChanged: (v) => setState(() => _dotsJump = v),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: CurveDropdown(
                    value: _squaresCurve,
                    onChanged: (v) => setState(() => _squaresCurve = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveWrap(
              minTileWidth: 220,
              children: [
                ShowcaseTile(
                  title: tr('Bouncing dots', 'Прыгающие точки'),
                  caption: tr(
                    'Three dots with a phase shift — "typing…"',
                    'Три точки с фазовым сдвигом — «печатает…»',
                  ),
                  previewHeight: 110,
                  child: _BouncingDots(animation: _controller, jump: _dotsJump),
                ),
                ShowcaseTile(
                  title: tr('Pulse', 'Пульс'),
                  caption: tr(
                    'Expanding rings — searching, recording, "live".',
                    'Расходящиеся кольца — поиск, запись, «на связи».',
                  ),
                  previewHeight: 110,
                  child: _Pulse(animation: _controller),
                ),
                ShowcaseTile(
                  title: tr('Skeleton + shimmer', 'Скелетон + шиммер'),
                  caption: tr(
                    'A highlight sweeps across the placeholders (ShaderMask).',
                    'Блик бежит по заглушкам (ShaderMask).',
                  ),
                  previewHeight: 110,
                  child: _Skeleton(animation: _controller),
                ),
                ShowcaseTile(
                  title: tr('Material: circular', 'Material: круговой'),
                  caption: tr(
                    'CircularProgressIndicator — indeterminate mode.',
                    'CircularProgressIndicator — неопределённый режим.',
                  ),
                  previewHeight: 110,
                  child: const CircularProgressIndicator(),
                ),
                ShowcaseTile(
                  title: tr('Material: linear', 'Material: линейный'),
                  caption: tr(
                    'LinearProgressIndicator — indeterminate mode.',
                    'LinearProgressIndicator — неопределённый режим.',
                  ),
                  previewHeight: 110,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(),
                  ),
                ),
                ShowcaseTile(
                  title: tr('Spinning squares', 'Вращающиеся квадраты'),
                  caption: tr(
                    'Two squares spin toward each other; curve — in the dropdown above.',
                    'Два квадрата крутятся навстречу; кривая — в дропдауне выше.',
                  ),
                  previewHeight: 110,
                  child: _SpinningSquares(
                    animation: _controller,
                    curve: resolveCurve(_squaresCurve),
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

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.animation, this.jump = 14});
  final Animation<double> animation;
  final double jump;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (context) {
                final phase = (animation.value - i * 0.15) % 1;
                final y = phase < 0.5
                    ? -math.sin(phase * 2 * math.pi) * jump
                    : 0.0;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (context) {
                final t = (animation.value + i / 3) % 1;
                return Container(
                  width: 24 + 70 * t,
                  height: 24 + 70 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kAccent.withValues(alpha: 1 - t),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height, {bool circle = false}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(circle ? height : 6),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final x = -1.5 + 3 * animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.5, -0.3),
            end: Alignment(x + 0.5, 0.3),
            colors: const [Colors.black12, Colors.white70, Colors.black12],
          ).createShader(rect),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            bar(48, 48, circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(double.infinity, 12),
                  const SizedBox(height: 8),
                  bar(100, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpinningSquares extends StatelessWidget {
  const _SpinningSquares({
    required this.animation,
    this.curve = Curves.easeInOutBack,
  });
  final Animation<double> animation;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = curve.transform(animation.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: t * math.pi,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: kAccent, width: 4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Transform.rotate(
              angle: -t * math.pi,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
