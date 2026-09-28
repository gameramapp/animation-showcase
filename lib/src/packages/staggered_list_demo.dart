// Showcase of the flutter_staggered_animations package — list/grid items
// appearing "staircase"-style, one after another:
//   • Playground — list or grid, combinations of Slide/Fade/Scale/Flip,
//     delay between items, duration, curve;
//   • toStaggeredList — the same for a plain Column (profile card);
//   • AnimationLimiter — why it's needed: two lists, with and without it.
// Everywhere, replay works by changing the key: widgets are recreated and
// play again.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class StaggeredListDemo extends StatelessWidget {
  const StaggeredListDemo({super.key});
  static const String routeName = 'packages/staggered_list';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_staggered_animations'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('The flutter_staggered_animations package', 'Пакет flutter_staggered_animations'),
            text: tr(
              'Ready-made "staircases" for lists and grids: items appear one '
              'after another with a small delay — sliding in, fading in, growing '
              'or flipping. Effects can be combined. Typical places: first feed '
              'load, product catalog, settings, search results. Fully works on the web.',
              'Готовые «лесенки» для списков и сеток: элементы появляются '
                  'друг за другом с небольшой задержкой — выезжают, проявляются, '
                  'увеличиваются или переворачиваются. Эффекты можно комбинировать. '
                  'Типичные места: первая загрузка ленты, каталог товаров, '
                  'настройки, результаты поиска. Полностью работает в вебе.',
            ),
            hint: tr(
              'Everything plays by itself and repeats. Move the sliders — the '
              'list restarts; the "Replay" button — manually.',
              'Всё играет само и повторяется. Меняй ручки — список '
                  'перезапустится; кнопка «Проиграть снова» — вручную.',
            ),
          ),
          const SizedBox(height: 16),
          _PlaygroundBlock(),
          const SizedBox(height: 16),
          _ColumnBlock(),
          const SizedBox(height: 16),
          _LimiterBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.duration('duration_ms', tr('duration — one item', 'duration — один элемент'), 450),
                BriefField.duration('delay_ms', tr('delay — staircase step', 'delay — шаг лесенки'), 70, max: 2000),
                BriefField.curve('curve', tr('Curve (Slide / Scale / Flip)', 'Кривая (Slide / Scale / Flip)'), 'easeOutCubic'),
                BriefField.choice('effect', tr('Effects', 'Эффекты'), ['Slide + Fade', 'Scale + Fade', 'Flip'], 'Slide + Fade'),
                BriefField.number('offset_px', 'Slide: verticalOffset', 60, unit: 'px', min: -300, max: 300),
                BriefField.number('scale_from', tr('Scale: starting scale', 'Scale: начальный масштаб'), 0.5, min: 0, max: 1),
              ],
              builder: _staggerPlayground,
            ),
            items: [
              (
                tr('Where it plays', 'Где играет'),
                tr(
                  'which list / grid / screen "assembles" as a staircase, and only on '
                  'first open (AnimationLimiter)',
                  'какой список / сетка / экран «собирается» лесенкой и только ли при первом открытии (AnimationLimiter)',
                ),
              ),
              (
                tr('Effects', 'Эффекты'),
                tr(
                  'Slide / FadeIn / Scale / Flip — which ones together; for Slide — from '
                  'where and how many px, for Scale — starting scale, for Flip — the axis',
                  'Slide / FadeIn / Scale / Flip — какие вместе; для Slide — откуда и на сколько px, для Scale — начальный масштаб, для Flip — ось',
                ),
              ),
              (
                'duration',
                tr('how long one item takes to appear, in ms', 'длительность появления одного элемента в мс'),
              ),
              (
                tr('delay — staircase step', 'delay — шаг лесенки'),
                tr(
                  'delay between neighboring items in ms; in a grid the step runs '
                  'diagonally (row + column)',
                  'задержка между соседними элементами в мс; в сетке шаг идёт по диагонали (строка + столбец)',
                ),
              ),
              (
                tr('Curve', 'Кривая'),
                tr(
                  'a preset or cubic-bezier from Figma for Slide / Scale / Flip',
                  'пресет или cubic-bezier из Figma для Slide / Scale / Flip',
                ),
              ),
              (
                tr('Layout', 'Раскладка'),
                tr(
                  'list or grid, number of columns, how many items are visible on the first screen',
                  'список или сетка, число колонок, сколько элементов видно на первом экране',
                ),
              ),
            ],
            avoid: [
              tr(
                'Springy / "overshooting" curves on fade-in (FadeIn) — opacity above 1 '
                "is impossible, the package crashes.",
                'Пружинные / «перелетающие» кривые на проявлении (FadeIn) — прозрачность больше 1 невозможна, пакет падает.',
              ),
              tr(
                'A large delay step in long lists — far items will appear too late.',
                'Большой шаг задержки в длинных списках — дальние элементы появятся слишком поздно.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Playground

enum _Fx { slide, fade, scale, flip }

String _fxLabel(_Fx fx) => switch (fx) {
  _Fx.slide => tr('Slide — slide in', 'Slide — выезд'),
  _Fx.fade => tr('FadeIn — fade in', 'FadeIn — проявление'),
  _Fx.scale => tr('Scale — grow', 'Scale — рост'),
  _Fx.flip => tr('Flip — flip', 'Flip — переворот'),
};

enum _Dir { bottom, top, right, left }

String _dirLabel(_Dir dir) => switch (dir) {
  _Dir.bottom => tr('From below', 'Снизу'),
  _Dir.top => tr('From above', 'Сверху'),
  _Dir.right => tr('From the right', 'Справа'),
  _Dir.left => tr('From the left', 'Слева'),
};

class _PlaygroundBlock extends StatefulWidget {
  const _PlaygroundBlock();

  @override
  State<_PlaygroundBlock> createState() => _PlaygroundBlockState();
}

class _PlaygroundBlockState extends State<_PlaygroundBlock> {
  final Set<_Fx> _fx = {_Fx.slide, _Fx.fade};
  _Dir _dir = _Dir.bottom;
  double _offset = 60;
  double _scaleFrom = 0.5;
  FlipAxis _flipAxis = FlipAxis.x;
  int _durationMs = 450;
  int _delayMs = 70;
  String _curve = 'easeOutCubic';
  bool _grid = false;
  int _columns = 3;
  bool _autoRepeat = true;
  int _generation = 0;
  Timer? _repeatTimer;

  static const _listCount = 12;
  static const _gridCount = 18;

  @override
  void initState() {
    super.initState();
    _scheduleRepeat();
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  /// Approximate time until the last visible item finishes playing.
  Duration get _totalTime {
    final steps = _grid
        ? (_gridCount / _columns).ceil() - 1 + _columns - 1
        : 7; // ~8 rows fit into the preview window
    return Duration(milliseconds: _durationMs + _delayMs * steps);
  }

  void _scheduleRepeat() {
    _repeatTimer?.cancel();
    if (!_autoRepeat) return;
    _repeatTimer = Timer(_totalTime + const Duration(milliseconds: 1500), () {
      if (mounted) _replay();
    });
  }

  void _replay() {
    setState(() => _generation++);
    _scheduleRepeat();
  }

  /// Changes a parameter and immediately replays the list.
  void _update(VoidCallback change) {
    setState(change);
    _replay();
  }

  Curve get _curveValue => resolveCurve(_curve);

  double get _vOffset => switch (_dir) {
        _Dir.bottom => _offset,
        _Dir.top => -_offset,
        _ => 0,
      };

  double get _hOffset => switch (_dir) {
        _Dir.right => _offset,
        _Dir.left => -_offset,
        _ => 0,
      };

  /// Wraps the item in the chosen effects (outside in: Slide → Fade →
  /// Scale → Flip). FadeIn is always on easeOut: "springy" curves overshoot
  /// past 1.0, and opacity above 1 isn't allowed.
  Widget _wrap(Widget child) {
    var w = child;
    final curve = _curveValue;
    if (_fx.contains(_Fx.flip)) w = FlipAnimation(flipAxis: _flipAxis, curve: curve, child: w);
    if (_fx.contains(_Fx.scale)) w = ScaleAnimation(scale: _scaleFrom, curve: curve, child: w);
    if (_fx.contains(_Fx.fade)) w = FadeInAnimation(curve: Curves.easeOut, child: w);
    if (_fx.contains(_Fx.slide)) {
      w = SlideAnimation(
        verticalOffset: _vOffset,
        horizontalOffset: _hOffset,
        curve: curve,
        child: w,
      );
    }
    return w;
  }

  Map<String, Object?> _spec() => {
    'package': packageSpec('flutter_staggered_animations'),
    'widget': _grid
        ? 'AnimationLimiter + GridView + AnimationConfiguration.staggeredGrid'
        : 'AnimationLimiter + ListView + AnimationConfiguration.staggeredList',
    'layout': _grid ? 'grid' : 'list',
    if (_grid) 'columnCount': _columns,
    'item_count': _grid ? _gridCount : _listCount,
    ...timingSpec(durationMs: _durationMs, curve: _curve, delayMs: _delayMs),
    'delay_note': _grid
        ? tr(
            'delay — staircase step: item delay = (row + column) × delay_ms',
            'delay — шаг лесенки: задержка элемента = (строка + столбец) × delay_ms',
          )
        : tr(
            'delay — staircase step: item delay = index × delay_ms',
            'delay — шаг лесенки: задержка элемента = номер × delay_ms',
          ),
    'curve_dart': curveCode(_curve),
    'effects': [
      if (_fx.contains(_Fx.slide))
        {
          'widget': 'SlideAnimation',
          'direction': _dir.name,
          'verticalOffset_px': _vOffset.round(),
          'horizontalOffset_px': _hOffset.round(),
          'curve': _curve,
        },
      if (_fx.contains(_Fx.fade))
        {
          'widget': 'FadeInAnimation',
          'curve': 'easeOut',
          'note': tr('not springy — opacity > 1 is not allowed', 'не пружинная — прозрачность > 1 недопустима'),
        },
      if (_fx.contains(_Fx.scale))
        {'widget': 'ScaleAnimation', 'scale_from': round2(_scaleFrom), 'curve': _curve},
      if (_fx.contains(_Fx.flip))
        {'widget': 'FlipAnimation', 'flipAxis': _flipAxis.name, 'curve': _curve},
    ],
    'item': _grid
        ? {
            'border_radius_px': 14,
            'spacing_px': 10,
            'colors': tr(
              'gradient ${hexColor(kAccent)} → ${hexColor(Colors.orange)}',
              'градиент ${hexColor(kAccent)} → ${hexColor(Colors.orange)}',
            ),
          }
        : {
            'border_radius_px': 12,
            'gap_px': 8,
            'colors': tr(
              'gradient ${hexColor(kAccent)} → ${hexColor(Colors.orange)}',
              'градиент ${hexColor(kAccent)} → ${hexColor(Colors.orange)}',
            ),
          },
  };

  String get _code {
    final c = curveCode(_curve);
    final wrappers = <String>[
      if (_fx.contains(_Fx.slide))
        _hOffset != 0
            ? 'SlideAnimation(horizontalOffset: ${_hOffset.round()}, curve: $c,'
            : 'SlideAnimation(verticalOffset: ${_vOffset.round()}, curve: $c,',
      if (_fx.contains(_Fx.fade)) 'FadeInAnimation(',
      if (_fx.contains(_Fx.scale)) 'ScaleAnimation(scale: ${_scaleFrom.toStringAsFixed(2)}, curve: $c,',
      if (_fx.contains(_Fx.flip)) 'FlipAnimation(flipAxis: FlipAxis.${_flipAxis.name}, curve: $c,',
    ];
    final head = _grid
        ? 'AnimationConfiguration.staggeredGrid(\n'
            '  position: index, columnCount: $_columns,'
        : 'AnimationConfiguration.staggeredList(\n  position: index,';
    final buf = StringBuffer('AnimationLimiter(child: ${_grid ? 'GridView' : 'ListView'}(…))\n')
      ..writeln(head)
      ..writeln('  duration: Duration(milliseconds: $_durationMs),')
      ..writeln('  delay: Duration(milliseconds: $_delayMs),');
    var indent = '  ';
    for (final w in wrappers) {
      buf.writeln('${indent}child: $w');
      indent += '  ';
    }
    buf.write('${indent}child: item${')' * (wrappers.length + 1)}');
    return buf.toString();
  }

  Widget _buildPreview() {
    final duration = Duration(milliseconds: _durationMs);
    final delay = Duration(milliseconds: _delayMs);
    if (_grid) {
      return AnimationLimiter(
        key: ValueKey('grid-$_generation'),
        child: GridView.count(
          crossAxisCount: _columns,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < _gridCount; i++)
              AnimationConfiguration.staggeredGrid(
                position: i,
                columnCount: _columns,
                duration: duration,
                delay: delay,
                child: _wrap(_GridItem(index: i, total: _gridCount)),
              ),
          ],
        ),
      );
    }
    return AnimationLimiter(
      key: ValueKey('list-$_generation'),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _listCount,
        itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: duration,
          delay: delay,
          child: _wrap(_ListItem(index: i, total: _listCount)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _TallBlock(
      title: tr('Playground: list and grid', 'Плейграунд: список и сетка'),
      spec: _spec,
      description: tr(
        'AnimationConfiguration sets the item number and timings, while the '
        'effect wrappers (Slide, FadeIn, Scale, Flip) nest inside one another '
        'and play at the same time. In a grid the "wave" runs diagonally: '
        'delay = (row + column) × step.',
        'AnimationConfiguration задаёт номер элемента и тайминги, а '
            'эффекты-обёртки (Slide, FadeIn, Scale, Flip) вкладываются друг в '
            'друга и играют одновременно. В сетке «волна» идёт по диагонали: '
            'задержка = (строка + столбец) × шаг.',
      ),
      previewHeight: 420,
      preview: _buildPreview(),
      belowPreview: _CodeBox(_code),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Layout', 'Раскладка'), style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(tr('List', 'Список')),
                selected: !_grid,
                onSelected: (_) => _update(() => _grid = false),
              ),
              ChoiceChip(
                label: Text(tr('Grid', 'Сетка')),
                selected: _grid,
                onSelected: (_) => _update(() => _grid = true),
              ),
            ],
          ),
          if (_grid)
            LabeledSlider(
              label: tr('Grid columns', 'Колонок в сетке'),
              value: _columns.toDouble(),
              min: 2,
              max: 4,
              onChanged: (v) {
                if (v.round() != _columns) _update(() => _columns = v.round());
              },
            ),
          const SizedBox(height: 12),
          Text(tr('Effects (several allowed)', 'Эффекты (можно несколько)'), style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fx in _Fx.values)
                FilterChip(
                  label: Text(_fxLabel(fx)),
                  selected: _fx.contains(fx),
                  onSelected: (on) {
                    // At least one effect must remain.
                    if (!on && _fx.length == 1) return;
                    _update(() => on ? _fx.add(fx) : _fx.remove(fx));
                  },
                ),
            ],
          ),
          if (_fx.contains(_Fx.slide)) ...[
            const SizedBox(height: 12),
            Text(tr('Where it slides from', 'Откуда выезжает'), style: textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _Dir.values)
                  ChoiceChip(
                    label: Text(_dirLabel(d)),
                    selected: _dir == d,
                    onSelected: (_) => _update(() => _dir = d),
                  ),
              ],
            ),
            LabeledSlider(
              label: tr('Slide-in distance', 'Расстояние выезда'),
              value: _offset,
              min: 10,
              max: 300,
              unit: 'px',
              onChanged: (v) => _update(() => _offset = v.roundToDouble()),
            ),
          ],
          if (_fx.contains(_Fx.scale))
            LabeledSlider(
              label: tr('Scale: starting scale', 'Scale: начальный масштаб'),
              value: _scaleFrom,
              min: 0,
              max: 0.95,
              fractionDigits: 2,
              onChanged: (v) => _update(() => _scaleFrom = v),
            ),
          if (_fx.contains(_Fx.flip)) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(tr('Flip on X (top to bottom)', 'Flip по X (сверху вниз)')),
                  selected: _flipAxis == FlipAxis.x,
                  onSelected: (_) => _update(() => _flipAxis = FlipAxis.x),
                ),
                ChoiceChip(
                  label: Text(tr('Flip on Y (left to right)', 'Flip по Y (слева направо)')),
                  selected: _flipAxis == FlipAxis.y,
                  onSelected: (_) => _update(() => _flipAxis = FlipAxis.y),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('Duration of one item', 'Длительность одного элемента'),
            value: _durationMs.toDouble(),
            min: 150,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) => _update(() => _durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Delay between items', 'Задержка между элементами'),
            value: _delayMs.toDouble(),
            min: 0,
            max: 300,
            unit: tr('ms', 'мс'),
            onChanged: (v) => _update(() => _delayMs = v.round()),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => _update(() => _curve = v)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.replay),
                label: Text(tr('Replay', 'Проиграть снова')),
              ),
              FilterChip(
                label: Text(tr('Auto-repeat', 'Автоповтор')),
                selected: _autoRepeat,
                onSelected: (v) {
                  setState(() => _autoRepeat = v);
                  _scheduleRepeat();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(kAccent, Colors.orange, index / (total - 1))!;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('List item ${index + 1}', 'Элемент списка ${index + 1}'),
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.4 + 0.5 * ((index * 37) % 10) / 10,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _gridIcons = [
  Icons.star,
  Icons.favorite,
  Icons.bolt,
  Icons.eco,
  Icons.music_note,
  Icons.palette,
];

class _GridItem extends StatelessWidget {
  const _GridItem({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(kAccent, Colors.orange, index / (total - 1))!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Icon(_gridIcons[index % _gridIcons.length], color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── toStaggeredList (Column)

class _ColumnBlock extends StatefulWidget {
  const _ColumnBlock();

  @override
  State<_ColumnBlock> createState() => _ColumnBlockState();
}

class _ColumnBlockState extends State<_ColumnBlock> {
  int _durationMs = 500;
  int _delayMs = 100;
  _Dir _dir = _Dir.right;
  String _curve = 'easeOutCubic';
  bool _loop = true;
  int _generation = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_loop) return;
    // 5 items: the last one starts after 4 delay steps.
    final total = _durationMs + _delayMs * 4 + 1500;
    _timer = Timer(Duration(milliseconds: total), () {
      if (mounted) _replay();
    });
  }

  void _replay() {
    setState(() => _generation++);
    _schedule();
  }

  void _update(VoidCallback change) {
    setState(change);
    _replay();
  }

  Widget _animate(Widget child) {
    const d = 50.0;
    return SlideAnimation(
      verticalOffset: switch (_dir) { _Dir.bottom => d, _Dir.top => -d, _ => 0 },
      horizontalOffset: switch (_dir) { _Dir.right => d, _Dir.left => -d, _ => 0 },
      curve: resolveCurve(_curve),
      child: FadeInAnimation(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    Widget bar(double factor) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          child: Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );

    return AnimBlock(
      title: tr('toStaggeredList — a staircase in a plain Column', 'toStaggeredList — лесенка в обычной Column'),
      spec: () => {
        'package': packageSpec('flutter_staggered_animations'),
        'widget': 'AnimationConfiguration.toStaggeredList',
        ...timingSpec(durationMs: _durationMs, curve: _curve, delayMs: _delayMs),
        'curve_dart': curveCode(_curve),
        'childAnimationBuilder': [
          {
            'widget': 'SlideAnimation',
            'direction': _dir.name,
            'verticalOffset_px': switch (_dir) { _Dir.bottom => 50, _Dir.top => -50, _ => 0 },
            'horizontalOffset_px': switch (_dir) { _Dir.right => 50, _Dir.left => -50, _ => 0 },
            'curve': _curve,
          },
          {'widget': 'FadeInAnimation', 'curve': tr('ease (package default)', 'ease (по умолчанию пакета)')},
        ],
        'children_count': 7,
      },
      description: tr(
        "Not just for lists: AnimationConfiguration.toStaggeredList wraps the "
        'children of any Column/Row. This is how a profile card, a form, or a '
        'settings screen "assembles" itself on open.',
        'Не только для списков: AnimationConfiguration.toStaggeredList '
            'оборачивает детей любой Column/Row. Так «собирается» карточка '
            'профиля, форма или экран настроек при открытии.',
      ),
      preview: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: ValueKey(_generation),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: Duration(milliseconds: _durationMs),
            delay: Duration(milliseconds: _delayMs),
            childAnimationBuilder: _animate,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: kAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      tr('Anna Designer', 'Анна Дизайнер'),
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              bar(0.9),
              bar(0.7),
              bar(0.5),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Text(
                        tr('Follow', 'Подписаться'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outline),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Text(
                        tr('Message', 'Написать'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Where it slides from', 'Откуда выезжает'), style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _Dir.values)
                ChoiceChip(
                  label: Text(_dirLabel(d)),
                  selected: _dir == d,
                  onSelected: (_) => _update(() => _dir = d),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 150,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) => _update(() => _durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Delay between rows', 'Задержка между строками'),
            value: _delayMs.toDouble(),
            min: 0,
            max: 400,
            unit: tr('ms', 'мс'),
            onChanged: (v) => _update(() => _delayMs = v.round()),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => _update(() => _curve = v)),
          Text(
            tr(
              'The slide-in curve (SlideAnimation). The FadeInAnimation fade-in uses '
              'its own ease curve: a spring on opacity crashes the package.',
              'Кривая выезда (SlideAnimation). Проявление FadeInAnimation — на '
                  'своей кривой ease: пружина на прозрачности роняет пакет.',
            ),
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _replay,
                icon: const Icon(Icons.replay),
                label: Text(tr('Replay', 'Проиграть снова')),
              ),
              FilterChip(
                label: Text(tr('Auto-repeat', 'Автоповтор')),
                selected: _loop,
                onSelected: (v) {
                  setState(() => _loop = v);
                  _schedule();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CodeBox(
            'Column(children: AnimationConfiguration.toStaggeredList(\n'
            '  duration: Duration(milliseconds: $_durationMs),\n'
            '  delay: Duration(milliseconds: $_delayMs),\n'
            '  childAnimationBuilder: (w) => SlideAnimation(\n'
            '    curve: ${curveCode(_curve)},\n'
            '    child: FadeInAnimation(child: w)),\n'
            '  children: [...]))',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── AnimationLimiter

class _LimiterBlock extends StatefulWidget {
  const _LimiterBlock();

  @override
  State<_LimiterBlock> createState() => _LimiterBlockState();
}

class _LimiterBlockState extends State<_LimiterBlock> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('AnimationLimiter — animate only the first screen', 'AnimationLimiter — анимировать только первый экран'),
      spec: () => {
        'package': packageSpec('flutter_staggered_animations'),
        'widget': 'AnimationLimiter + ListView.builder + AnimationConfiguration.staggeredList',
        ...timingSpec(durationMs: 450, curve: 'easeOutCubic', delayMs: 60),
        'effects': [
          {'widget': 'SlideAnimation', 'horizontalOffset_px': 60, 'curve': 'easeOutCubic'},
          {'widget': 'FadeInAnimation'},
        ],
        'item': {'height_px': 32, 'gap_px': 6, 'border_radius_px': 8},
        'rule': tr(
          'AnimationLimiter — a direct parent of the scrollable list',
          'AnimationLimiter — прямой родитель прокручиваемого списка',
        ),
      },
      description: tr(
        'Scroll both lists. Without the limiter, every new item also "slides in" '
        'as you scroll, with a delay based on its index — far items appear late. '
        'With the limiter, only what was visible on open animates, and the list '
        'behaves normally after that.',
        'Прокрути оба списка. Без лимитера каждый новый элемент при '
            'прокрутке тоже «выезжает», да ещё с задержкой по номеру — дальние '
            'элементы появляются с опозданием. С лимитером анимируется только '
            'то, что было видно при открытии, а дальше список ведёт себя обычно.',
      ),
      preview: Row(
        key: ValueKey(_generation),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _LimiterList(limited: false)),
          const VerticalDivider(width: 1),
          Expanded(child: _LimiterList(limited: true)),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _generation++),
            icon: const Icon(Icons.replay),
            label: Text(tr('Replay', 'Проиграть снова')),
          ),
          const SizedBox(height: 12),
          _CodeBox(
            'AnimationLimiter(\n'
            '  child: ListView.builder(\n'
            '    itemBuilder: (c, i) =>\n'
            '      AnimationConfiguration.staggeredList(\n'
            '        position: i, child: …)))',
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Rule: AnimationLimiter must be a direct parent of the scrollable list.',
              'Правило: AnimationLimiter должен быть прямым родителем '
                  'прокручиваемого списка.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LimiterList extends StatelessWidget {
  const _LimiterList({required this.limited});

  final bool limited;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final list = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 40,
      itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
        position: i,
        duration: const Duration(milliseconds: 450),
        delay: const Duration(milliseconds: 60),
        child: SlideAnimation(
          horizontalOffset: 60,
          curve: Curves.easeOutCubic,
          child: FadeInAnimation(
            child: Container(
              height: 32,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Color.lerp(kAccent, Colors.orange, math.min(i / 20, 1))!
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr('Row ${i + 1}', 'Строка ${i + 1}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: limited ? kAccent.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Text(
            limited
                ? tr('With AnimationLimiter', 'С AnimationLimiter')
                : tr('Without the limiter', 'Без лимитера'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium,
          ),
        ),
        Expanded(child: limited ? AnimationLimiter(child: list) : list),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── Shared widgets

/// A block with a tall preview (a list needs more room than AnimBlock's
/// 224px): preview and code below it on the left, settings on the right;
/// stacked on a narrow screen.
class _TallBlock extends StatelessWidget {
  const _TallBlock({
    required this.title,
    required this.description,
    required this.preview,
    required this.previewHeight,
    required this.belowPreview,
    required this.controls,
    required this.spec,
  });

  final String title;
  final String description;
  final Widget preview;
  final double previewHeight;
  final Widget belowPreview;
  final Widget controls;
  final Map<String, Object?> Function() spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final previewPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: previewHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          clipBehavior: Clip.antiAlias,
          child: preview,
        ),
        const SizedBox(height: 12),
        belowPreview,
      ],
    );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: textTheme.titleMedium)),
            SpecButton(title: title, spec: spec),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, previewPane, const SizedBox(height: 16), controls],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: previewPane),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, controls],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A monospace code line/block.
class _CodeBox extends StatelessWidget {
  const _CodeBox(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────── brief playground

/// Six staggered rows: item i starts after i × delay and plays for
/// duration. The fade-in is always easeOut (like FadeInAnimation in the playground).
Widget _staggerPlayground(BuildContext context, BriefValues v, double t) {
  const count = 6;
  final duration = v.ms('duration_ms');
  final delay = v.ms('delay_ms');
  final curve = v.curve('curve');
  final effect = v.text('effect');
  return LoopClock(
    periodMs: duration + delay * (count - 1),
    builder: (context, ms) => Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Builder(
              builder: (context) {
                final p = phase(ms, i * delay, duration);
                final e = curve.transform(p);
                Widget row = Container(
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: Color.lerp(kAccent, Colors.orange, i / (count - 1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
                switch (effect) {
                  case 'Flip':
                    row = Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX((1 - e) * math.pi / 2),
                      child: row,
                    );
                  case 'Scale + Fade':
                    row = Opacity(
                      opacity: Curves.easeOut.transform(p),
                      child: Transform.scale(scale: v.number('scale_from') + (1 - v.number('scale_from')) * e, child: row),
                    );
                  default:
                    row = Opacity(
                      opacity: Curves.easeOut.transform(p),
                      child: Transform.translate(offset: Offset(0, v.number('offset_px') * (1 - e)), child: row),
                    );
                }
                return row;
              },
            ),
        ],
      ),
    ),
  );
}
