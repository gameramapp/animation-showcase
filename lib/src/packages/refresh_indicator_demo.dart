// Showcase of the custom_refresh_indicator package — branded pull-to-refresh:
//   • Logo — the brand icon spins as you drag, and rotates while loading;
//   • Plane — a paper plane flies out, hovers in the clouds, and flies away;
//   • Ring — a circle drops down from the top, the ring fills as you pull;
//   • Drop — a liquid drop stretches, detaches into a ball, the ball bounces;
//   • Comparison with the standard Material RefreshIndicator.
//
// The package provides the "skeleton": the state (idle → dragging → armed →
// loading → complete → finalizing) and a pull value of 0…1.5, while the look
// is any widget of ours. The refresh can also be triggered from code —
// without a gesture.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class RefreshIndicatorDemo extends StatelessWidget {
  const RefreshIndicatorDemo({super.key});
  static const String routeName = 'packages/refresh_indicator';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Refresh Indicator'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Branded pull-to-refresh', 'Фирменный pull-to-refresh'),
            text: tr(
              'The custom_refresh_indicator package lets you replace the '
              'standard "pull to refresh" spinner with any animation: a '
              'logo, a paper plane, a liquid drop. It reports how far the '
              'list is pulled and the refresh state, and you can draw '
              'whatever you like. Great for feeds, chats, order lists — '
              'anywhere refreshing happens often and you want it "on brand".',
              'Пакет custom_refresh_indicator позволяет заменить стандартный '
              'кружок «потяни, чтобы обновить» на любую анимацию: логотип, '
              'самолётик, жидкую каплю. Он сообщает, насколько оттянут список '
              'и в каком состоянии обновление, а нарисовать можно что угодно. '
              'Хорошо подходит для лент, чатов, списков заказов — там, где '
              'обновление делают часто и его хочется «обрендить».',
            ),
            hint: tr(
              'Pull the list in the "phone" down (works with the mouse too) '
              'or press "Refresh programmatically". While you don\'t touch it '
              '— the demo plays on its own.',
              'Потяни список в «телефоне» вниз (мышью тоже можно) или нажми '
              '«Обновить программно». Пока ты не трогаешь — демо играет само.',
            ),
          ),
          const SizedBox(height: 16),
          const _BrandedRefreshBlock(),
          const SizedBox(height: 16),
          const _MaterialCompareBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.number('offsetToArmed', tr('offsetToArmed — threshold', 'offsetToArmed — порог'), 100, unit: 'px', min: 20, max: 300),
                BriefField.duration('load_ms', tr('Loading (onRefresh)', 'Загрузка (onRefresh)'), 1500),
                BriefField.duration('completeDuration_ms', tr('Showing "done" (completeDuration)', 'Показ «готово» (completeDuration)'), 600),
                BriefField.duration('finalizeDuration_ms', tr('Hiding (finalizeDuration)', 'Скрытие (finalizeDuration)'), 300),
                BriefField.color('color', tr('Indicator color', 'Цвет индикатора'), '#673AB7'),
                BriefField.choice('style', tr('Style', 'Стиль'), [tr('Ring', 'Кольцо'), tr('Logo', 'Логотип')], tr('Ring', 'Кольцо')),
              ],
              builder: _refreshPlayground,
            ),
            items: [
              (
                tr('Graphics per state', 'Графика по состояниям'),
                tr(
                  'what the indicator looks like in each state: dragging (0–100%), armed (release!), loading, complete, finalizing (hiding)',
                  'как выглядит индикатор в каждом состоянии: dragging (тянем, 0–100 %), armed (отпусти), loading (грузим), complete (готово), finalizing (скрытие)',
                ),
              ),
              (
                tr('Pull behavior', 'Поведение при оттягивании'),
                tr(
                  'what changes with the pull percentage 0…1: scale, rotation, fill, position; and what happens when overpulled to 1.5',
                  'что меняется от процента оттягивания 0…1: масштаб, поворот, заполнение, позиция; и что при перетягивании до 1.5',
                ),
              ),
              (
                tr('Trigger threshold', 'Порог срабатывания'),
                tr(
                  'offsetToArmed in px — how far to pull for it to refresh',
                  'offsetToArmed в px — сколько тянуть, чтобы обновилось',
                ),
              ),
              (
                tr('Timings', 'Тайминги'),
                tr(
                  'showing "done" (completeDuration), hiding (finalizeDuration), canceling (cancelDuration), the loader\'s minimum duration in ms',
                  'показ «готово» (completeDuration), скрытие (finalizeDuration), отмена (cancelDuration), минимальная длительность лоадера в мс',
                ),
              ),
              (
                tr('Layout', 'Раскладка'),
                tr(
                  'whether the indicator pushes the list down or sits on top, header height in px',
                  'индикатор сдвигает список вниз или лежит поверх, высота шапки в px',
                ),
              ),
              (
                tr('Colors and assets', 'Цвета и ассеты'),
                tr(
                  'colors as #hex; the loader animation can be sent as a Lottie / Rive file per state',
                  'цвета #hex; анимацию лоадера можно прислать Lottie / Rive-файлом по состояниям',
                ),
              ),
            ],
            avoid: [
              tr(
                'An endless "loading" with no error state — describe what to show if the data doesn\'t arrive.',
                'Бесконечную «загрузку» без состояния ошибки — опиши, что показывать, если данные не пришли.',
              ),
              tr(
                'Too high a threshold (> 150 px) on a phone — the gesture becomes uncomfortable.',
                'Слишком высокий порог (> 150 px) на телефоне — жест становится неудобным.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── shared bits

/// Scrolling with both mouse and touch — otherwise the list can't be dragged
/// with the cursor in the web.
ScrollBehavior _dragEverywhere(BuildContext context) =>
    ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        ui.PointerDeviceKind.touch,
        ui.PointerDeviceKind.mouse,
        ui.PointerDeviceKind.trackpad,
      },
    );

/// Human-readable labels for the indicator states.
Map<IndicatorState, String> get _stateLabels => <IndicatorState, String>{
  IndicatorState.idle: tr('idle', 'покой'),
  IndicatorState.dragging: tr('dragging', 'тянем'),
  IndicatorState.canceling: tr('canceling', 'отмена'),
  IndicatorState.armed: tr('release!', 'отпусти!'),
  IndicatorState.settling: tr('settling', 'фиксация'),
  IndicatorState.loading: tr('loading', 'загрузка'),
  IndicatorState.complete: tr('done', 'готово'),
  IndicatorState.finalizing: tr('hiding', 'скрытие'),
};

/// The main state chain for the "timeline" under the phone.
const _timeline = [
  IndicatorState.idle,
  IndicatorState.dragging,
  IndicatorState.armed,
  IndicatorState.loading,
  IndicatorState.complete,
];

/// Which timeline entry the current state maps to.
IndicatorState _timelineOf(IndicatorState s) => switch (s) {
  IndicatorState.canceling => IndicatorState.idle,
  IndicatorState.settling => IndicatorState.armed,
  IndicatorState.finalizing => IndicatorState.complete,
  _ => s,
};

Color _stateColor(IndicatorState s) => switch (_timelineOf(s)) {
  IndicatorState.dragging => Colors.orange,
  IndicatorState.armed => Colors.pink,
  IndicatorState.loading => Colors.blue,
  IndicatorState.complete => Colors.green,
  _ => Colors.grey,
};

enum _Style { logo, plane, ring, drop }

Map<_Style, String> get _styleNames => <_Style, String>{
  _Style.logo: tr('Logo', 'Логотип'),
  _Style.plane: tr('Plane', 'Самолётик'),
  _Style.ring: tr('Ring', 'Кольцо'),
  _Style.drop: tr('Drop', 'Капля'),
};

Map<_Style, String> get _styleCaptions => <_Style, String>{
  _Style.logo: tr(
    'The brand icon spins with your finger, spins while loading, and shows a checkmark at the end.',
    'Бренд-иконка крутится вслед за пальцем, при загрузке — вращается, в конце — галочка.',
  ),
  _Style.plane: tr(
    'A plane flies in from the edge, hovers in the clouds and flies away once the data arrives.',
    'Самолётик вылетает из-за края, парит в облаках и улетает, когда данные пришли.',
  ),
  _Style.ring: tr(
    'A circle slides in from the top, the ring fills with the pull % — like Material, but its own.',
    'Круг выезжает сверху, кольцо заполняется в % оттягивания — как Material, но свой.',
  ),
  _Style.drop: tr(
    'A liquid drop stretches, detaches into a ball, the ball bounces, then there\'s a splash.',
    'Жидкая капля тянется, отрывается в мячик, мячик прыгает, в конце — всплеск.',
  ),
};

/// Height of the "header" where the indicator is drawn above the list.
const _headerH = 90.0;

// ───────────────────────────────────────────────── branded indicators

class _BrandedRefreshBlock extends StatefulWidget {
  const _BrandedRefreshBlock();

  @override
  State<_BrandedRefreshBlock> createState() => _BrandedRefreshBlockState();
}

class _BrandedRefreshBlockState extends State<_BrandedRefreshBlock> {
  double _loadSec = 1.5;
  double _completeSec = 0.6;
  double _armOffset = 100;
  int _finalizeMs = 300;
  int _pullMs = 450;
  String _pullCurve = 'easeOutCubic';
  bool _auto = true;
  int _trigger = 0;
  _Style _single = _Style.logo;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAuto(first: true);
  }

  /// Auto-demo: every few seconds trigger a refresh on its own.
  void _scheduleAuto({bool first = false}) {
    _autoTimer?.cancel();
    if (!_auto) return;
    final pauseMs = first ? 1200 : ((_loadSec + _completeSec) * 1000).round() + 2800;
    _autoTimer = Timer(Duration(milliseconds: pauseMs), () {
      if (!mounted || !_auto) return;
      setState(() => _trigger++);
      _scheduleAuto();
    });
  }

  void _stopAuto() {
    if (!_auto) return;
    _autoTimer?.cancel();
    setState(() => _auto = false);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Widget _phone(_Style style, int index) => _PhoneRefresh(
    key: ValueKey(style),
    style: style,
    staggerIndex: index,
    trigger: _trigger,
    loadDuration: Duration(milliseconds: (_loadSec * 1000).round()),
    completeDuration: Duration(milliseconds: (_completeSec * 1000).round()),
    offsetToArmed: _armOffset,
    finalizeDuration: Duration(milliseconds: _finalizeMs),
    draggingDuration: Duration(milliseconds: _pullMs),
    draggingCurve: _pullCurve,
    onUserPull: _stopAuto,
  );

  Map<String, Object?> _spec(bool single) => {
    'package': packageSpec('custom_refresh_indicator'),
    'widget': 'CustomRefreshIndicator',
    'offsetToArmed_px': _armOffset.round(),
    'trigger': 'leadingEdge',
    'triggerMode': 'onEdge',
    'durations': {
      'completeDuration_ms': (_completeSec * 1000).round(),
      'finalizeDuration_ms': _finalizeMs,
      'settleDuration_ms': 150,
      'cancelDuration_ms': 300,
    },
    'onRefresh_load_ms': (_loadSec * 1000).round(),
    'programmatic_refresh': {
      'method': 'key.currentState!.refresh(draggingDuration:, draggingCurve:)',
      'param_duration': 'draggingDuration',
      'param_curve': 'draggingCurve',
      ...timingSpec(durationMs: _pullMs, curve: _pullCurve),
      'curve_dart': curveCode(_pullCurve),
    },
    'header_height_px': _headerH.round(),
    'controller_value_range': tr('0…1.5 (1 = trigger threshold)', '0…1.5 (1 = порог срабатывания)'),
    'states': [for (final s in IndicatorState.values) s.name],
    'styles': [
      for (final st in single ? [_single] : _Style.values) _styleSpec(st),
    ],
  };

  static Map<String, Object?> _styleSpec(_Style st) => {
    'style': _styleNames[st],
    'description': _styleCaptions[st],
    'layout': st == _Style.ring
        ? tr('on top of the list', 'поверх списка')
        : tr('pushes the list down', 'сдвигает список вниз'),
    'artwork': switch (st) {
      _Style.logo => {
        'dragging': tr(
          '44 px icon, scale 0.4→1, rotation 0→270° over the pull',
          'иконка 44 px, масштаб 0.4→1, поворот 0→270° за оттягивание',
        ),
        'armed': tr(
          'scale ×1.1 + a ${hexColor(kAccent)} glow at 50%, blur 14',
          'масштаб ×1.1 + свечение ${hexColor(kAccent)} 50 %, blur 14',
        ),
        'loading': tr('360° rotation over 900 ms, looping', 'вращение 360° за 900 мс по кругу'),
        'complete': tr(
          'a green ${hexColor(Colors.green)} circle with a checkmark, elasticOut over 500 ms',
          'зелёный круг ${hexColor(Colors.green)} с галочкой, elasticOut за 500 мс',
        ),
        'colors': [hexColor(kAccent), hexColor(const Color(0xFFFF4081)), hexColor(const Color(0xFFFFC107))],
        'background': hexColor(const Color(0xFFEDE7F6)),
      },
      _Style.plane => {
        'dragging': tr(
          'the plane flies in from the bottom left (easeOut), clouds fade in',
          'самолёт вылетает слева снизу (easeOut), облака проявляются',
        ),
        'loading': tr('hovers up and down, 900 ms cycle', 'парит вверх-вниз, цикл 900 мс'),
        'complete': tr('flies away up-right, easeIn over 500 ms', 'улетает вверх-вправо, easeIn за 500 мс'),
        'sky_gradient': [hexColor(const Color(0xFF7EC8F0)), hexColor(const Color(0xFFCBEAFB))],
      },
      _Style.ring => {
        'dragging': tr(
          'a 46 px circle slides in from the top, arc 0→100%, label in %',
          'круг 46 px выезжает сверху, дуга 0→100 %, подпись в %',
        ),
        'armed': tr(
          'a ${hexColor(const Color(0xFFFF4081))} arc, 5 px thick (otherwise ${hexColor(kAccent)}, 3.5 px)',
          'дуга ${hexColor(const Color(0xFFFF4081))}, толщина 5 px (иначе ${hexColor(kAccent)}, 3.5 px)',
        ),
        'loading': tr('a 108° arc spins, 900 ms cycle', 'дуга 108° вращается, цикл 900 мс'),
        'complete': tr('a green circle with a checkmark, easeOutBack over 500 ms', 'зелёный круг с галочкой, easeOutBack за 500 мс'),
      },
      _Style.drop => {
        'dragging': tr(
          'the drop stretches from the ceiling, radius 8→14 px, detaches at 100%',
          'капля тянется с потолка, радиус 8→14 px, при 100 % отрывается',
        ),
        'loading': tr(
          'an 11 px ball bounces, squashes at the floor, 900 ms cycle',
          'мячик 11 px прыгает, сплющивается у пола, цикл 900 мс',
        ),
        'complete': tr(
          'a splash: a 10→50 px ring fades over 500 ms + 6 droplets',
          'всплеск: кольцо 10→50 px тает за 500 мс + 6 капель',
        ),
        'color': hexColor(const Color(0xFF00B8D4)),
        'background': hexColor(const Color(0xFFE0F7FA)),
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final refreshComment = tr('// programmatically', '// программно');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(child: Text(tr('Four branded styles', 'Четыре фирменных стиля'), style: textTheme.titleMedium)),
                  SpecButton(
                    title: 'CustomRefreshIndicator',
                    // On a narrow screen only one style is shown — it goes into the spec.
                    spec: () => _spec(constraints.maxWidth < 620),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'The same CustomRefreshIndicator, different builders. Under '
                'each phone — a state timeline: you can see when the '
                'indicator is "dragging", when it\'s "armed" (release to '
                'refresh), loading, and showing "done".',
                'Один и тот же CustomRefreshIndicator, разные builder-ы. Под '
                'каждым телефоном — таймлайн состояний: видно, когда индикатор '
                '«тянется», когда «взведён» (отпусти — обновится), грузит и '
                'показывает «готово».',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Narrow — one phone and toggle chips, wide — all side by side.
                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final s in _Style.values)
                            ChoiceChip(
                              label: Text(_styleNames[s]!),
                              selected: _single == s,
                              onSelected: (_) => setState(() => _single = s),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _phone(_single, 0),
                    ],
                  );
                }
                return ResponsiveWrap(
                  minTileWidth: 280,
                  children: [
                    for (final (i, s) in _Style.values.indexed) _phone(s, i),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _stopAuto();
                    setState(() => _trigger++);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('Refresh programmatically', 'Обновить программно')),
                ),
                FilterChip(
                  label: Text(tr('Auto-demo', 'Авто-демо')),
                  selected: _auto,
                  onSelected: (v) {
                    setState(() => _auto = v);
                    _scheduleAuto(first: true);
                  },
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Loading duration', 'Длительность загрузки'),
                    value: _loadSec,
                    min: 0.5,
                    max: 5,
                    unit: tr('s', 'с'),
                    fractionDigits: 1,
                    onChanged: (v) => setState(() => _loadSec = v),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Showing "done"', 'Показ «готово»'),
                    value: _completeSec,
                    min: 0,
                    max: 1.5,
                    unit: tr('s', 'с'),
                    fractionDigits: 1,
                    onChanged: (v) => setState(() => _completeSec = v),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Hiding (finalizeDuration)', 'Скрытие (finalizeDuration)'),
                    value: _finalizeMs.toDouble(),
                    min: 100,
                    max: 1000,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) => setState(() => _finalizeMs = v.round()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Programmatic "tug" (draggingDuration)', 'Программный «рывок» (draggingDuration)'),
                    value: _pullMs.toDouble(),
                    min: 100,
                    max: 1500,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) => setState(() => _pullMs = v.round()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: CurveDropdown(
                    value: _pullCurve,
                    onChanged: (v) => setState(() => _pullCurve = v),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Trigger threshold', 'Порог срабатывания'),
                    value: _armOffset,
                    min: 60,
                    max: 160,
                    unit: 'px',
                    onChanged: (v) => setState(() => _armOffset = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'The curve is for the programmatic refresh: this is how the '
                'indicator "pulls itself" (refresh(draggingCurve: …)). With a '
                'finger gesture, the finger itself sets the curve.',
                'Кривая — для программного обновления: так индикатор «сам '
                'оттягивается» (refresh(draggingCurve: …)). При жесте пальцем '
                'кривую задаёт сам палец.',
              ),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _CodeBox(
              'CustomRefreshIndicator(\n'
              '  onRefresh: load,\n'
              '  offsetToArmed: ${_armOffset.round()},\n'
              '  durations: RefreshIndicatorDurations(\n'
              '    completeDuration: ${(_completeSec * 1000).round()}.ms,\n'
              '    finalizeDuration: $_finalizeMs.ms),\n'
              '  builder: (ctx, child, c) => MyHeader(c.value, c.state, child),\n'
              '  child: ListView(...),\n'
              ')\n'
              '$refreshComment: key.currentState!.refresh(\n'
              '//   draggingDuration: $_pullMs.ms, draggingCurve: ${curveCode(_pullCurve)})',
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone mockup with a list and a single indicator style.
class _PhoneRefresh extends StatefulWidget {
  const _PhoneRefresh({
    super.key,
    required this.style,
    required this.staggerIndex,
    required this.trigger,
    required this.loadDuration,
    required this.completeDuration,
    required this.offsetToArmed,
    required this.finalizeDuration,
    required this.draggingDuration,
    required this.draggingCurve,
    required this.onUserPull,
  });

  final _Style style;
  final int staggerIndex;
  final int trigger;
  final Duration loadDuration;
  final Duration completeDuration;
  final double offsetToArmed;
  final Duration finalizeDuration;
  final Duration draggingDuration;
  final String draggingCurve;
  final VoidCallback onUserPull;

  @override
  State<_PhoneRefresh> createState() => _PhoneRefreshState();
}

class _PhoneRefreshState extends State<_PhoneRefresh> with TickerProviderStateMixin {
  final _indicatorKey = GlobalKey<CustomRefreshIndicatorState>();
  final _controller = IndicatorController();

  /// Spins while loading is in progress (rotation, hovering, ball bounces).
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 0 → 1 over half a second on transitioning to "complete" (checkmark, fly-away, splash).
  late final AnimationController _done = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  final List<int> _items = List.generate(12, (i) => 12 - i);
  int _fresh = 0;
  bool _programmatic = false;
  Timer? _staggerTimer;
  Timer? _loadTimer;
  Completer<void>? _loading;

  @override
  void didUpdateWidget(covariant _PhoneRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      // Phones start with a slight stagger — nicer than all at once.
      _staggerTimer?.cancel();
      _staggerTimer = Timer(Duration(milliseconds: widget.staggerIndex * 220), _refreshProgrammatically);
    }
  }

  void _refreshProgrammatically() {
    if (!mounted || !_controller.isIdle) return;
    _programmatic = true;
    _indicatorKey.currentState?.refresh(
      draggingDuration: widget.draggingDuration,
      draggingCurve: resolveCurve(widget.draggingCurve),
    );
  }

  /// "Loading" is just a timer; the Completer is also closed on dispose,
  /// so the package doesn't wait forever.
  Future<void> _onRefresh() {
    final completer = Completer<void>();
    _loading = completer;
    _loadTimer?.cancel();
    _loadTimer = Timer(widget.loadDuration, () {
      if (mounted) {
        setState(() {
          _fresh = 3;
          _items.insert(0, _items.first + 1);
        });
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _onStateChanged(IndicatorStateChange change) {
    if (change.didChange(from: IndicatorState.idle, to: IndicatorState.dragging) && !_programmatic) {
      widget.onUserPull();
    }
    if (change.didChange(to: IndicatorState.loading)) _loop.repeat();
    if (change.didChange(to: IndicatorState.complete)) _done.forward(from: 0);
    if (change.didChange(to: IndicatorState.finalizing) && !_done.isCompleted) _done.forward();
    if (change.didChange(to: IndicatorState.idle)) {
      _programmatic = false;
      _loop.stop();
      _done.value = 0;
      if (_fresh > 0 && mounted) setState(() => _fresh--);
    }
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _loadTimer?.cancel();
    if (_loading != null && !_loading!.isCompleted) _loading!.complete();
    _loop.dispose();
    _done.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final list = ScrollConfiguration(
      behavior: _dragEverywhere(context),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        physics: AlwaysScrollableScrollPhysics(
          parent: ClampingWithOverscrollPhysics(state: _controller),
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) => _FeedItem(number: _items[i], isNew: i == 0 && _fresh > 0),
      ),
    );

    return Column(
      children: [
        Center(
          child: Container(
            width: 270,
            height: 440,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1B1F),
              borderRadius: BorderRadius.circular(34),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: ColoredBox(
                color: const Color(0xFFF4F1FA),
                child: Column(
                  children: [
                    _PhoneBar(title: _styleNames[widget.style]!, controller: _controller),
                    Expanded(
                      child: CustomRefreshIndicator(
                        key: _indicatorKey,
                        controller: _controller,
                        onRefresh: _onRefresh,
                        offsetToArmed: widget.offsetToArmed,
                        onStateChanged: _onStateChanged,
                        durations: RefreshIndicatorDurations(
                          completeDuration: widget.completeDuration == Duration.zero
                              ? null
                              : widget.completeDuration,
                          finalizeDuration: widget.finalizeDuration,
                        ),
                        builder: (context, child, c) => _IndicatorView(
                          style: widget.style,
                          controller: c,
                          loop: _loop,
                          done: _done,
                          child: child,
                        ),
                        child: list,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _StateTimeline(state: _controller.state),
        ),
        const SizedBox(height: 6),
        Text(
          _styleCaptions[widget.style]!,
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The "app header" inside the phone with a badge for the current state.
class _PhoneBar extends StatelessWidget {
  const _PhoneBar({required this.title, required this.controller});

  final String title;
  final IndicatorController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final color = _stateColor(controller.state);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _stateLabels[controller.state]!,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A feed item — avatar and "skeleton" text bars.
class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.number, required this.isNew});

  final int number;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFE8DEFF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.primaries[number % Colors.primaries.length].shade200,
            child: Text('$number', style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tr('Post #$number', 'Пост №$number'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Text(tr('new', 'новое'), style: const TextStyle(fontSize: 10, color: kAccent)),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                FractionallySizedBox(
                  widthFactor: 0.5 + (number * 37 % 40) / 100,
                  child: Container(
                    height: 7,
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
    );
  }
}

/// State timeline: the current step is highlighted.
class _StateTimeline extends StatelessWidget {
  const _StateTimeline({required this.state});

  final IndicatorState state;

  @override
  Widget build(BuildContext context) {
    final current = _timelineOf(state);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final s in _timeline)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: s == current ? _stateColor(s) : Colors.transparent,
              border: Border.all(color: s == current ? _stateColor(s) : Colors.black26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.name,
              style: TextStyle(
                fontSize: 10,
                color: s == current ? Colors.white : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── indicator rendering

class _IndicatorView extends StatelessWidget {
  const _IndicatorView({
    required this.style,
    required this.controller,
    required this.loop,
    required this.done,
    required this.child,
  });

  final _Style style;
  final IndicatorController controller;
  final Animation<double> loop;
  final Animation<double> done;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = controller.value.clamp(0.0, 1.5);
    final isRing = style == _Style.ring;
    // Ring — overlaid on the list (like Material); the others push the list down.
    final shift = isRing ? 0.0 : math.min(v, 1.2) * _headerH;

    final header = AnimatedBuilder(
      animation: Listenable.merge([loop, done]),
      builder: (context, _) => switch (style) {
        _Style.logo => _LogoHeader(c: controller, v: v, loop: loop.value, done: done.value),
        _Style.plane => _PlaneHeader(c: controller, v: v, loop: loop.value, done: done.value),
        _Style.ring => _RingHeader(c: controller, v: v, loop: loop.value, done: done.value),
        _Style.drop => CustomPaint(
          painter: _DropPainter(
            v: v,
            loading: controller.isLoading,
            done: controller.isComplete || controller.isFinalizing,
            loop: loop.value,
            doneT: done.value,
          ),
        ),
      },
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (!isRing && !controller.isIdle)
          Positioned(top: 0, left: 0, right: 0, height: math.max(shift, 0.0), child: header),
        Transform.translate(offset: Offset(0, shift), child: child),
        if (isRing && !controller.isIdle)
          Positioned(top: 0, left: 0, right: 0, height: _headerH + 30, child: header),
      ],
    );
  }
}

/// Logo: spins with the finger, bounces when "armed", rotates while loading.
class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.c, required this.v, required this.loop, required this.done});

  final IndicatorController c;
  final double v;
  final double loop;
  final double done;

  @override
  Widget build(BuildContext context) {
    final finished = c.isComplete || c.isFinalizing;
    final angle = c.isLoading ? loop * 2 * math.pi : v * 1.5 * math.pi;
    final armedBump = c.isArmed ? 1.1 : 1.0;
    final scale = (0.4 + 0.6 * math.min(v, 1.0)) * armedBump;
    return ClipRect(
      child: Container(
        color: const Color(0xFFEDE7F6),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: finished ? 1 : scale,
          child: finished
              ? Transform.scale(
                  scale: Curves.elasticOut.transform(done),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check_rounded, color: Colors.white),
                  ),
                )
              : Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [kAccent, Color(0xFFFF4081), Color(0xFFFFC107), kAccent],
                      ),
                      boxShadow: [
                        if (c.isArmed || c.isLoading)
                          BoxShadow(color: kAccent.withValues(alpha: 0.5), blurRadius: 14),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Plane: flies in from the bottom left, hovers in the clouds, flies away up-right.
class _PlaneHeader extends StatelessWidget {
  const _PlaneHeader({required this.c, required this.v, required this.loop, required this.done});

  final IndicatorController c;
  final double v;
  final double loop;
  final double done;

  @override
  Widget build(BuildContext context) {
    final finished = c.isComplete || c.isFinalizing;
    final t = math.min(v, 1.0);
    // Plane position in Alignment coordinates (-1…1).
    var x = -1.4 + 1.4 * Curves.easeOut.transform(t);
    var y = 0.9 - 0.9 * t;
    var tilt = -0.5 + 0.3 * t;
    if (c.isLoading) y = math.sin(loop * 2 * math.pi) * 0.25;
    if (finished) {
      final e = Curves.easeIn.transform(done);
      x = 2.2 * e;
      y = -1.8 * e;
      tilt = -0.6;
    }
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7EC8F0), Color(0xFFCBEAFB)],
          ),
        ),
        child: Stack(
          children: [
            // Clouds drift right to left — gives a sense of flight.
            for (var i = 0; i < 3; i++)
              Align(
                alignment: Alignment(
                  1.3 - ((i / 3 + (c.isLoading ? loop : 0) * 0.5 + t * 0.2) % 1) * 2.6,
                  -0.6 + i * 0.6,
                ),
                child: Opacity(
                  opacity: 0.85 * t,
                  child: Container(
                    width: 38.0 + i * 10,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment(x, y),
              child: Transform.rotate(
                angle: tilt,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring: a circle slides in from the top, the arc grows with the percentage, then spins.
class _RingHeader extends StatelessWidget {
  const _RingHeader({required this.c, required this.v, required this.loop, required this.done});

  final IndicatorController c;
  final double v;
  final double loop;
  final double done;

  @override
  Widget build(BuildContext context) {
    final finished = c.isComplete || c.isFinalizing;
    final top = -50 + math.min(v, 1.3) * 80;
    return Stack(
      children: [
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: finished ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: finished
                  ? Transform.scale(
                      scale: Curves.easeOutBack.transform(done),
                      child: const Icon(Icons.check_rounded, color: Colors.white),
                    )
                  : CustomPaint(
                      painter: _RingPainter(
                        progress: math.min(v, 1.0),
                        loading: c.isLoading,
                        loop: loop,
                        armed: c.isArmed || c.isSettling,
                      ),
                      child: Center(
                        child: c.isLoading
                            ? null
                            : Text(
                                '${(math.min(v, 1.0) * 100).round()}%',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.loading, required this.loop, required this.armed});

  final double progress;
  final bool loading;
  final double loop;
  final bool armed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(6);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.black12;
    canvas.drawArc(ring, 0, 2 * math.pi, false, track);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = armed ? 5 : 3.5
      ..color = armed ? const Color(0xFFFF4081) : kAccent;
    if (loading) {
      final start = loop * 2 * math.pi - math.pi / 2;
      canvas.drawArc(ring, start, math.pi * 0.6, false, paint);
    } else {
      canvas.drawArc(ring, -math.pi / 2, 2 * math.pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.loading != loading || old.loop != loop || old.armed != armed;
}

/// Drop: stretches from the "ceiling", detaches into a ball, the ball bounces, ends with a splash.
class _DropPainter extends CustomPainter {
  _DropPainter({
    required this.v,
    required this.loading,
    required this.done,
    required this.loop,
    required this.doneT,
  });

  final double v;
  final bool loading;
  final bool done;
  final double loop;
  final double doneT;

  static const _color = Color(0xFF00B8D4);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final paint = Paint()..color = _color;
    final cx = size.width / 2;
    final t = math.min(v, 1.0);

    // Background — light "water".
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE0F7FA));

    if (done) {
      // Splash: the ring expands and fades, droplets fly outward.
      final r = 10 + 40 * doneT;
      final a = (1 - doneT).clamp(0.0, 1.0);
      final cy = size.height * 0.55;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _color.withValues(alpha: a),
      );
      for (var i = 0; i < 6; i++) {
        final ang = i / 6 * 2 * math.pi;
        canvas.drawCircle(
          Offset(cx + math.cos(ang) * r * 1.2, cy + math.sin(ang) * r * 0.8),
          3 * a,
          Paint()..color = _color.withValues(alpha: a),
        );
      }
      return;
    }

    if (loading) {
      // Ball bounces: |sin| + squashing against the "floor".
      final floor = size.height - 14;
      final bounce = math.sin(loop * math.pi).abs();
      final r = 11.0;
      final cy = floor - r - bounce * (size.height * 0.45);
      final squash = bounce < 0.15 ? 1 + (0.15 - bounce) * 2 : 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 2 * r * squash, height: 2 * r / squash),
        paint,
      );
      // Shadow.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, floor + 4), width: 26 * (1 - bounce * 0.5), height: 5),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
      return;
    }

    // Pulling: the drop hangs from the "ceiling", the neck narrows; armed — it detaches.
    final r = 8 + 6 * t;
    final cy = 10 + (size.height - 30) * t;
    final detached = v >= 1.0;
    if (!detached) {
      final neck = (1 - t) * 14 + 2;
      final path = Path()
        ..moveTo(cx - 22, 0)
        ..quadraticBezierTo(cx - neck, cy * 0.4, cx - r * 0.8, cy)
        ..lineTo(cx + r * 0.8, cy)
        ..quadraticBezierTo(cx + neck, cy * 0.4, cx + 22, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Highlight — gives it volume.
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.35), r * 0.25, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _DropPainter old) =>
      old.v != v || old.loading != loading || old.done != done || old.loop != loop || old.doneT != doneT;
}

// ─────────────────────────────────────────── standard RefreshIndicator

class _MaterialCompareBlock extends StatefulWidget {
  const _MaterialCompareBlock();

  @override
  State<_MaterialCompareBlock> createState() => _MaterialCompareBlockState();
}

class _MaterialCompareBlockState extends State<_MaterialCompareBlock> {
  final _key = GlobalKey<RefreshIndicatorState>();
  double _displacement = 40;
  double _stroke = 2.5;
  bool _auto = true;
  Timer? _autoTimer;
  Timer? _loadTimer;
  Completer<void>? _loading;
  int _refreshes = 0;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (_auto) _show();
    });
  }

  void _show() => _key.currentState?.show();

  String get _programmaticComment => tr('// programmatically', '// программно');

  Future<void> _onRefresh() {
    final completer = Completer<void>();
    _loading = completer;
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _refreshes++);
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _loadTimer?.cancel();
    if (_loading != null && !_loading!.isCompleted) _loading!.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('For comparison: standard RefreshIndicator', 'Для сравнения: стандартный RefreshIndicator'),
      spec: () => {
        'package': tr('flutter (Material, no package)', 'flutter (Material, без пакета)'),
        'widget': 'RefreshIndicator',
        'color': hexColor(kAccent),
        'displacement_px': _displacement.round(),
        'strokeWidth_px': round2(_stroke, 1),
        'onRefresh_load_ms': 1500,
        'programmatic': 'key.currentState!.show()',
      },
      description: tr(
        'The indicator built into Flutter: a spinner circle that slides in '
        'from the top. You can change the color, thickness and offset — '
        'that\'s it. If you need a brand, a "done" state or your own '
        'physics — reach for custom_refresh_indicator.',
        'Встроенный во Flutter индикатор: кружок-спиннер, который выезжает '
        'сверху. Можно поменять цвет, толщину и отступ — и всё. Если нужен '
        'бренд, состояние «готово» или своя физика — берём '
        'custom_refresh_indicator.',
      ),
      preview: ColoredBox(
        color: const Color(0xFFF4F1FA),
        child: ScrollConfiguration(
          behavior: _dragEverywhere(context),
          child: RefreshIndicator(
            key: _key,
            onRefresh: _onRefresh,
            color: kAccent,
            displacement: _displacement,
            strokeWidth: _stroke,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: 10,
              itemBuilder: (context, i) => _FeedItem(number: 100 + _refreshes * 10 + i, isNew: false),
            ),
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _auto = false);
                  _show();
                },
                icon: const Icon(Icons.refresh),
                label: Text(tr('Show', 'Показать')),
              ),
              FilterChip(
                label: Text(tr('Auto', 'Авто')),
                selected: _auto,
                onSelected: (v) => setState(() => _auto = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Top offset (displacement)', 'Отступ сверху (displacement)'),
            value: _displacement,
            min: 10,
            max: 100,
            unit: 'px',
            onChanged: (v) => setState(() => _displacement = v),
          ),
          LabeledSlider(
            label: tr('Line thickness', 'Толщина линии'),
            value: _stroke,
            min: 1,
            max: 6,
            fractionDigits: 1,
            onChanged: (v) => setState(() => _stroke = v),
          ),
          _CodeBox(
            'RefreshIndicator(onRefresh: load, color: accent, child: list)\n'
            '$_programmaticComment: key.currentState!.show()',
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

/// Full indicator cycle on the entered values: pull (600 ms to 120%),
/// settle (settleDuration 150 ms), loading, "complete", hide.
Widget _refreshPlayground(BuildContext context, BriefValues v, double t) {
  const pull = 600, settle = 150;
  final load = v.ms('load_ms');
  final complete = v.ms('completeDuration_ms');
  final finalize = v.ms('finalizeDuration_ms');
  final color = v.color('color');
  final arm = v.number('offsetToArmed');
  final ring = v.text('style') == tr('Ring', 'Кольцо');
  return LoopClock(
    periodMs: pull + settle + load + complete + finalize,
    builder: (context, ms) {
      final String state;
      double value;
      if (ms < pull) {
        value = 1.2 * Curves.easeOut.transform(phase(ms, 0, pull));
        state = value >= 1 ? 'armed' : 'dragging';
      } else if (ms < pull + settle) {
        value = 1.2 - 0.2 * phase(ms, pull, settle);
        state = 'settling';
      } else if (ms < pull + settle + load) {
        value = 1;
        state = 'loading';
      } else if (ms < pull + settle + load + complete) {
        value = 1;
        state = 'complete';
      } else {
        value = 1 - phase(ms, pull + settle + load + complete, finalize);
        state = value <= 0 ? 'idle' : 'finalizing';
      }
      // The preview is smaller than a real phone: halve the threshold in px.
      final shift = value * arm / 2;
      final spin = phase(ms, pull + settle, load) * load / 900;
      final done = state == 'complete' || (state == 'finalizing');
      Widget indicator;
      if (done) {
        indicator = const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.green,
          child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
        );
      } else if (ring) {
        indicator = SizedBox.square(
          dimension: 30,
          child: CircularProgressIndicator(
            value: state == 'loading' ? null : value.clamp(0.0, 1.0),
            strokeWidth: 3.5,
            color: color,
          ),
        );
      } else {
        indicator = Transform.rotate(
          angle: state == 'loading' ? spin * 2 * math.pi : value * 1.5 * math.pi,
          child: Transform.scale(
            scale: 0.4 + 0.6 * value.clamp(0.0, 1.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          ),
        );
      }
      return Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF4F1FA))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: math.max(shift, 0.0),
            child: ClipRect(child: Center(child: indicator)),
          ),
          Positioned(
            top: shift,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    height: 26,
                    margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _stateColor(IndicatorState.values.byName(state)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(state, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      );
    },
  );
}
