// Showcase of the flutter_animate package: declarative animations in one line.
//   • Effect gallery — each package effect in its own tile, with code;
//   • Chains (.then) — effects run sequentially;
//   • Stagger list — `children.animate(interval: …)`;
//   • By state (target) — animation tied to a flag rather than a timer.
//
// The package is web-compatible; the blur/shimmer effects use shaders/filters
// that work on the web via the CanvasKit/Skwasm renderer.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';

/// A gallery tile: what to show and what to put in the spec.
typedef _Fx = ({String title, String code, Map<String, Object?> spec, Widget child});

class FlutterAnimateDemo extends StatefulWidget {
  static const String routeName = 'packages/flutter_animate';

  const FlutterAnimateDemo({super.key});

  @override
  State<FlutterAnimateDemo> createState() => _FlutterAnimateDemoState();
}

class _FlutterAnimateDemoState extends State<FlutterAnimateDemo> {
  // Changing the key recreates all Animate widgets — they play again.
  int _replay = 0;
  bool _target = false;

  // Gallery: shared duration multiplier.
  double _fxSpeed = 1;
  // Chain .then(): pause between steps.
  int _chainGapMs = 250;
  // Combination: card entrance duration.
  int _cardInMs = 500;
  // Stagger list.
  int _staggerMs = 80;
  int _staggerDurationMs = 400;
  double _staggerOffset = 0.3;
  String _staggerCurve = 'easeOutCubic';
  // By state (target).
  int _targetMs = 300;
  String _targetCurve = 'easeOutBack';
  double _targetScale = 1.1;

  static const _box = {
    'size_px': 64,
    'radius_px': 14,
    'color': '#673AB7',
    'icon': 'auto_awesome (white)',
  };

  Widget _header(String title, Map<String, Object?> Function() spec) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        SpecButton(title: title, spec: spec),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effects = _effects();
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_animate'),
        actions: [
          IconButton(
            tooltip: tr('Replay everything', 'Проиграть всё заново'),
            onPressed: () => setState(() => _replay++),
            icon: const Icon(Icons.replay),
          ),
          const LangButton(),
        ],
      ),
      body: ListView(
        key: ValueKey(_replay),
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('The flutter_animate package', 'Пакет flutter_animate'),
            text: tr(
              'The fastest way to animate in Flutter: '
              '`.animate().fadeIn().slideY()` — and done. Effects '
              'combine, chain in sequence, and stagger across a list. Below '
              "each tile is the line of code it's made of: that's the real "
              "developer effort involved.",
              'Самый быстрый способ сделать анимацию во Flutter: '
                  '`.animate().fadeIn().slideY()` — и готово. Эффекты '
                  'комбинируются, выстраиваются в цепочки, раскладываются по '
                  'списку с задержкой. Под каждой плиткой — строка кода, которой '
                  'она сделана: это реальные трудозатраты разработчика.',
            ),
            hint: tr(
              'Everything loops. The ↻ button in the header replays the screen.',
              'Всё зациклено. Кнопка ↻ в шапке проигрывает экран заново.',
            ),
          ),
          const SizedBox(height: 16),
          _header(tr('Effects', 'Эффекты'), () => _gallerySpec(_effects())),
          const SizedBox(height: 4),
          SizedBox(
            width: 360,
            child: LabeledSlider(
              label: tr('Duration multiplier', 'Множитель длительностей'),
              value: _fxSpeed,
              min: 0.25,
              max: 3,
              unit: '×',
              fractionDigits: 2,
              onChanged: (v) => setState(() => _fxSpeed = v),
            ),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            // New durations — recreate the tiles so cycles start over.
            key: ValueKey('fx-$_fxSpeed'),
            child: ResponsiveWrap(
              minTileWidth: 220,
              children: [
                for (final fx in effects)
                  ShowcaseTile(title: fx.title, caption: fx.code, child: fx.child),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _header(tr('Chains and combinations', 'Цепочки и комбинации'), _chainsSpec),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 300,
                child: LabeledSlider(
                  label: tr('Pause between .then() steps', 'Пауза между шагами .then()'),
                  value: _chainGapMs.toDouble(),
                  min: 0,
                  max: 1000,
                  unit: tr('ms', 'мс'),
                  onChanged: (v) => setState(() => _chainGapMs = v.round()),
                ),
              ),
              SizedBox(
                width: 300,
                child: LabeledSlider(
                  label: tr('Card entrance', 'Появление карточки'),
                  value: _cardInMs.toDouble(),
                  min: 150,
                  max: 1500,
                  unit: tr('ms', 'мс'),
                  onChanged: (v) => setState(() => _cardInMs = v.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ResponsiveWrap(
            minTileWidth: 300,
            children: [
              ShowcaseTile(
                key: ValueKey('chain-$_chainGapMs'),
                title: tr('Sequence via .then()', 'Последовательность через .then()'),
                caption: tr(
                  '.fadeIn().then(delay: $_chainGapMs.ms).shimmer().then().slide()'
                  '.then().blur() — effects run one after another.',
                  '.fadeIn().then(delay: $_chainGapMs.ms).shimmer().then().slide()'
                      '.then().blur() — эффекты идут друг за другом.',
                ),
                child:
                    Text('Hello Flutter Animate', style: textTheme.headlineSmall)
                        .animate(onPlay: (c) => c.repeat())
                        .then(delay: _chainGapMs.ms)
                        .fadeIn(duration: 500.ms)
                        .then(delay: _chainGapMs.ms)
                        .shimmer(duration: 400.ms)
                        .then(delay: _chainGapMs.ms)
                        .slide()
                        .then(delay: _chainGapMs.ms)
                        .blur(duration: 500.ms)
                        .then(delay: 100.ms),
              ),
              ShowcaseTile(
                key: ValueKey('card-$_cardInMs'),
                title: tr('Combination: card entrance', 'Комбинация: появление карточки'),
                caption: tr(
                  '.fadeIn().scale(begin: 0.8).moveY(begin: 30) + '
                  '.shimmer(delay: 800.ms) — simultaneously, then a glare.',
                  '.fadeIn().scale(begin: 0.8).moveY(begin: 30) + '
                      '.shimmer(delay: 800.ms) — одновременно, затем блик.',
                ),
                child: _SampleCard()
                    .animate(onPlay: (c) => c.repeat(), delay: 300.ms)
                    .fadeIn(duration: _cardInMs.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
                    .moveY(begin: 30, curve: Curves.easeOutCubic)
                    .shimmer(delay: 800.ms, duration: 900.ms)
                    .then(delay: 1200.ms),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _header(tr('Stagger list', 'Stagger-список'), _staggerSpec),
          const SizedBox(height: 4),
          Text(
            tr(
              '[...].animate(interval: $_staggerMs.ms).fadeIn().slideX(begin: '
              '${_staggerOffset.toStringAsFixed(2)}) — one line for the whole list. '
              'Hit ↻ or move the sliders to see it again.',
              '[...].animate(interval: $_staggerMs.ms).fadeIn().slideX(begin: '
                  '${_staggerOffset.toStringAsFixed(2)}) — одна строка на весь список. '
                  'Жми ↻ или двигай ручки, чтобы увидеть снова.',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 260,
                child: LabeledSlider(
                  label: tr('Step between items', 'Шаг между элементами'),
                  value: _staggerMs.toDouble(),
                  min: 0,
                  max: 300,
                  unit: tr('ms', 'мс'),
                  onChanged: (v) => setState(() => _staggerMs = v.round()),
                ),
              ),
              SizedBox(
                width: 260,
                child: LabeledSlider(
                  label: tr('Item duration', 'Длительность элемента'),
                  value: _staggerDurationMs.toDouble(),
                  min: 100,
                  max: 1500,
                  unit: tr('ms', 'мс'),
                  onChanged: (v) => setState(() => _staggerDurationMs = v.round()),
                ),
              ),
              SizedBox(
                width: 260,
                child: LabeledSlider(
                  label: tr('X offset (fraction of width)', 'Сдвиг по X (доля ширины)'),
                  value: _staggerOffset,
                  min: 0,
                  max: 1,
                  fractionDigits: 2,
                  onChanged: (v) => setState(() => _staggerOffset = v),
                ),
              ),
              SizedBox(
                width: 260,
                child: CurveDropdown(
                  value: _staggerCurve,
                  onChanged: (v) => setState(() => _staggerCurve = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                key: ValueKey(
                  'stagger-$_staggerMs-$_staggerDurationMs-$_staggerOffset-$_staggerCurve',
                ),
                children:
                    [
                          for (var i = 0; i < 6; i++)
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color.lerp(kAccent, Colors.orange, i / 5),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(tr('Item ${i + 1}', 'Элемент ${i + 1}')),
                              subtitle: Text(
                                tr(
                                  'Appears $_staggerMs ms after its neighbor',
                                  'Появляется с задержкой $_staggerMs мс от соседа',
                                ),
                              ),
                            ),
                        ]
                        .animate(interval: _staggerMs.ms, delay: 200.ms)
                        .fadeIn(duration: _staggerDurationMs.ms)
                        .slideX(begin: _staggerOffset, curve: resolveCurve(_staggerCurve)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _header(tr('Animation by state (target)', 'Анимация по состоянию (target)'), _targetSpec),
          const SizedBox(height: 4),
          Text(
            tr(
              '.animate(target: selected ? 1 : 0) — the effect runs forward or '
              'backward when the flag changes. Handy for selection, hover, expansion.',
              '.animate(target: selected ? 1 : 0) — эффект едет вперёд или назад '
                  'при смене флага. Удобно для выбора, наведения, раскрытия.',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(tr('Selected', 'Выбрано')),
                    value: _target,
                    onChanged: (v) => setState(() => _target = v),
                  ),
                  const SizedBox(height: 12),
                  _SampleCard()
                      .animate(target: _target ? 1 : 0)
                      .scaleXY(
                        end: _targetScale,
                        duration: _targetMs.ms,
                        curve: resolveCurve(_targetCurve),
                      )
                      .tint(color: Colors.orange, end: 0.35)
                      .elevation(end: 16, borderRadius: BorderRadius.circular(16))
                      .rotate(end: -0.02),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 260,
                        child: LabeledSlider(
                          label: tr('Duration', 'Длительность'),
                          value: _targetMs.toDouble(),
                          min: 100,
                          max: 1500,
                          unit: tr('ms', 'мс'),
                          onChanged: (v) => setState(() => _targetMs = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: LabeledSlider(
                          label: tr('Selected scale', 'Масштаб выбранного'),
                          value: _targetScale,
                          min: 1,
                          max: 1.5,
                          unit: '×',
                          fractionDigits: 2,
                          onChanged: (v) => setState(() => _targetScale = v),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: CurveDropdown(
                          value: _targetCurve,
                          onChanged: (v) => setState(() => _targetCurve = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          DesignerBrief(
            items: [
              (
                tr('Which effects and in what order', 'Какие эффекты и в каком порядке'),
                tr(
                  'e.g. "fadeIn + slideY together, then shimmer"; what runs in parallel and '
                  'what chains after the previous step',
                  'например «fadeIn + slideY одновременно, затем shimmer»; что идёт параллельно, а что — цепочкой после предыдущего',
                ),
              ),
              (
                tr('Duration and delay of each effect', 'Длительность и задержка каждого эффекта'),
                tr(
                  'in ms; delay from the start of the animation or from the end of the previous step',
                  'в мс; задержка — от старта анимации или от конца предыдущего шага',
                ),
              ),
              (
                tr('Curves', 'Кривые'),
                tr(
                  'for each effect: a preset, cubic-bezier(…) from Figma, or spring(stiffness, damping, mass)',
                  'для каждого эффекта: пресет, cubic-bezier(…) из Figma или spring(stiffness, damping, mass)',
                ),
              ),
              (
                tr('"From → to" values', 'Значения «от → до»'),
                tr(
                  'offset in px or fractions of size, scale ×, rotation in turns/degrees, blur in px, colors #hex',
                  'сдвиг в px или в долях размера, масштаб ×, поворот в оборотах/градусах, blur в px, цвета #hex',
                ),
              ),
              (
                tr('Repeat', 'Повтор'),
                tr(
                  'once / looping / back-and-forth, pause between cycles in ms',
                  'один раз / по кругу / туда-обратно, пауза между циклами в мс',
                ),
              ),
              (
                tr('Stagger', 'Stagger'),
                tr(
                  'step between list items in ms, start delay, max number of items that animate',
                  'шаг между элементами списка в мс, стартовая задержка, максимум элементов, которые анимируются',
                ),
              ),
              (
                tr('By state', 'По состоянию'),
                tr(
                  'which flag turns the effect on (selected, hovered, expanded) and whether it should roll back',
                  'какой флаг включает эффект (выбран, наведён, раскрыт) и должен ли он откатываться назад',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't send only a video without numbers — durations and delays guessed by "
                "eye won't match.",
                'Не присылать только видео без цифр — длительности и задержки «на глаз» не совпадут.',
              ),
              tr(
                "Don't forget inheritance: in flutter_animate an effect without its own "
                'duration/curve takes them from the previous one.',
                'Не забывать про наследование: у flutter_animate эффект без своей длительности/кривой берёт их у предыдущего.',
              ),
            ],
            playground: BriefPlayground(
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), ['fade + slide', 'scale', 'shimmer'], 'fade + slide'),
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 500),
                BriefField.duration('delay_ms', tr('Delay', 'Задержка'), 200),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeOutCubic'),
                BriefField.number('offset', tr('Offset from below (fade + slide)', 'Сдвиг снизу (fade + slide)'), 30, unit: 'px', min: -400, max: 400),
                BriefField.number('scale_from', tr('Scale "from" (scale)', 'Масштаб «от» (scale)'), 0.8, unit: '×', min: 0, max: 3),
                BriefField.color('color', tr('Card color', 'Цвет карточки'), '#673AB7'),
                BriefField.color('shimmer_color', tr('Glare color (shimmer)', 'Цвет блика (shimmer)'), '#FFFFFF'),
              ],
              delayKey: 'delay_ms',
              builder: _animatePlayground,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── specs

  Map<String, Object?> _gallerySpec(List<_Fx> effects) => {
    'widget': 'flutter_animate: widget.animate(onPlay: (c) => c.repeat(…)).<effect>(…)',
    'package': 'flutter_animate ^4.5',
    'duration_multiplier': double.parse(_fxSpeed.toStringAsFixed(2)),
    'defaults': tr(
      "if an effect has no duration/curve of its own — 300 ms, linear, or it's inherited from the previous one",
      'если у эффекта не задана длительность/кривая — 300 мс, linear или наследуется от предыдущего',
    ),
    'target_box': _box,
    'effects': [for (final fx in effects) fx.spec],
  };

  Map<String, Object?> _chainsSpec() {
    final gap = _chainGapMs;
    return {
      'widget': 'flutter_animate: .animate(onPlay: (c) => c.repeat()) + .then(delay:)',
      'inheritance': tr(
        "an effect without its own duration/curve takes them from the previous one",
        'эффект без своей длительности/кривой берёт их у предыдущего',
      ),
      'sequence_then': {
        'repeat': 'loop',
        'target': tr('Text "Hello Flutter Animate", headlineSmall', 'Text «Hello Flutter Animate», headlineSmall'),
        'steps': [
          {'effect': 'fadeIn', 'opacity': [0, 1], 'delay_after_prev_ms': gap, ...timingSpec(durationMs: 500, curve: 'linear')},
          {'effect': 'shimmer', 'color': hexColor(const Color(0x80FFFFFF)), 'angle_deg': 15, 'delay_after_prev_ms': gap, ...timingSpec(durationMs: 400, curve: 'linear')},
          {'effect': 'slide', 'offset_fraction_of_size': {'from': [0, -0.5], 'to': [0, 0]}, 'delay_after_prev_ms': gap, ...timingSpec(durationMs: 400, curve: 'linear'), 'note': tr('duration inherited from shimmer', 'длительность унаследована от shimmer')},
          {'effect': 'blur', 'blur_px': [0, 4], 'delay_after_prev_ms': gap, ...timingSpec(durationMs: 500, curve: 'linear')},
        ],
        'loop_pause_ms': 100,
        'cycle_ms': gap * 4 + 500 + 400 + 400 + 500 + 100,
      },
      'card_entrance': {
        'repeat': 'loop',
        'start_delay_ms': 300,
        'parallel': [
          {'effect': 'fadeIn', 'opacity': [0, 1], ...timingSpec(durationMs: _cardInMs, curve: 'linear')},
          {'effect': 'scale', 'scale': [0.8, 1], ...timingSpec(durationMs: _cardInMs, curve: 'easeOutBack')},
          {'effect': 'moveY', 'offset_y_px': [30, 0], ...timingSpec(durationMs: _cardInMs, curve: 'easeOutCubic')},
          {'effect': 'shimmer', 'color': hexColor(const Color(0x80FFFFFF)), ...timingSpec(durationMs: 900, curve: 'easeOutCubic', delayMs: 800)},
        ],
        'loop_pause_ms': 1200,
        'card': {'width_px': 220, 'radius_px': 16, 'color': hexColor(kAccent)},
      },
    };
  }

  Map<String, Object?> _staggerSpec() => {
    'widget': 'flutter_animate: <Widget>[…].animate(interval:, delay:).fadeIn().slideX()',
    'items': 6,
    'start_delay_ms': 200,
    'stagger_step_ms': _staggerMs,
    'item_effects': [
      {'effect': 'fadeIn', 'opacity': [0, 1], ...timingSpec(durationMs: _staggerDurationMs, curve: 'linear')},
      {
        'effect': 'slideX',
        'offset_fraction_of_width': [double.parse(_staggerOffset.toStringAsFixed(2)), 0],
        ...timingSpec(durationMs: _staggerDurationMs, curve: _staggerCurve),
      },
    ],
    'total_ms': 200 + _staggerMs * 5 + _staggerDurationMs,
    'repeat': tr('once (on screen open / via the ↻ button)', 'once (при появлении экрана / по кнопке ↻)'),
  };

  Map<String, Object?> _targetSpec() => {
    'widget': 'flutter_animate: .animate(target: selected ? 1 : 0)',
    'trigger': tr(
      'the "Selected" flag: 0 → 1 forward, 1 → 0 the same animation backward',
      'флаг «Выбрано»: 0 → 1 вперёд, 1 → 0 та же анимация назад',
    ),
    ...timingSpec(durationMs: _targetMs, curve: _targetCurve),
    'note': tr(
      'the duration and curve of the first effect are inherited by the rest',
      'длительность и кривая первого эффекта наследуются остальными',
    ),
    'effects': [
      {'effect': 'scaleXY', 'scale': [1, double.parse(_targetScale.toStringAsFixed(2))]},
      {'effect': 'tint', 'color': hexColor(Colors.orange), 'strength': [0, 0.35]},
      {'effect': 'elevation', 'elevation': [0, 16], 'radius_px': 16, 'shadow_color': '#000000'},
      {'effect': 'rotate', 'turns': [0, -0.02], 'deg': [0, -7.2]},
    ],
  };

  // ─────────────────────────────────────────────────────────── gallery

  List<_Fx> _effects() {
    int ms(int base) => (base * _fxSpeed).round();
    Duration d(int base) => Duration(milliseconds: ms(base));
    Map<String, Object?> t(int base, [String curve = 'linear']) =>
        timingSpec(durationMs: ms(base), curve: curve);
    const box = _Box();
    const pingPong = 'ping-pong (repeat reverse)';
    const loop = 'loop';

    return [
      (
        title: 'fadeIn',
        code: '.fadeIn(duration: 600.ms)',
        spec: {'effect': 'fadeIn', ...t(600), 'opacity': [0, 1], 'repeat': pingPong},
        child: box.animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: d(600)),
      ),
      (
        title: 'scale',
        code: '.scale(curve: Curves.elasticOut)',
        spec: {
          'effect': 'scale',
          ...t(1200, 'elasticOut'),
          'scale': [0, 1],
          'repeat': loop,
          'loop_pause_ms': ms(400),
        },
        child: box
            .animate(onPlay: (c) => c.repeat())
            .scale(duration: d(1200), curve: Curves.elasticOut)
            .then(delay: d(400)),
      ),
      (
        title: 'slideX / slideY',
        code: tr(
          '.slideX(begin: -1) — offset by a fraction of size',
          '.slideX(begin: -1) — сдвиг на долю размера',
        ),
        spec: {
          'effect': 'slideX',
          ...t(900, 'easeInOut'),
          'offset_fraction_of_width': [-1, 1],
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideX(begin: -1, end: 1, duration: d(900), curve: Curves.easeInOut),
      ),
      (
        title: 'move',
        code: tr(
          '.move(begin: Offset(-40, 30)) — offset in pixels',
          '.move(begin: Offset(-40, 30)) — сдвиг в пикселях',
        ),
        spec: {
          'effect': 'move',
          ...t(900),
          'offset_px': {'from': [-40, 30], 'to': [40, -30]},
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(begin: const Offset(-40, 30), end: const Offset(40, -30), duration: d(900)),
      ),
      (
        title: 'rotate',
        code: tr('.rotate(end: 1) — a full turn', '.rotate(end: 1) — полный оборот'),
        spec: {'effect': 'rotate', ...t(1400, 'easeInOutBack'), 'turns': [0, 1], 'repeat': loop},
        child: box
            .animate(onPlay: (c) => c.repeat())
            .rotate(end: 1, duration: d(1400), curve: Curves.easeInOutBack),
      ),
      (
        title: 'flip / flipH',
        code: tr(
          '.flipH() — a flip around an axis with perspective',
          '.flipH() — переворот по оси с перспективой',
        ),
        spec: {
          'effect': 'flipH',
          ...t(900),
          'turns': [-0.5, 0.5],
          'perspective': 1.5,
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .flipH(begin: -0.5, end: 0.5, duration: d(900), perspective: 1.5),
      ),
      (
        title: 'blur',
        code: tr('.blur(begin: Offset(8, 8)) — defocus', '.blur(begin: Offset(8, 8)) — расфокус'),
        spec: {'effect': 'blur', ...t(900), 'blur_px': [8, 0], 'repeat': pingPong},
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .blur(begin: const Offset(8, 8), end: Offset.zero, duration: d(900)),
      ),
      (
        title: 'shimmer',
        code: tr(
          '.shimmer(duration: 1200.ms) — a running glare',
          '.shimmer(duration: 1200.ms) — пробегающий блик',
        ),
        spec: {
          'effect': 'shimmer',
          ...t(1200),
          'color': hexColor(Colors.white),
          'angle_deg': 15,
          'repeat': loop,
          'loop_pause_ms': ms(300),
        },
        child: box
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: d(1200), color: Colors.white)
            .then(delay: d(300)),
      ),
      (
        title: 'shake',
        code: tr('.shake(hz: 4) — shaking', '.shake(hz: 4) — встряхивание'),
        spec: {
          'effect': 'shake',
          ...t(600),
          'hz': 4,
          'rotation_deg': 5,
          'repeat': loop,
          'loop_pause_ms': ms(900),
        },
        child: box
            .animate(onPlay: (c) => c.repeat())
            .shake(hz: 4, duration: d(600))
            .then(delay: d(900)),
      ),
      (
        title: 'tint',
        code: tr('.tint(color: Colors.orange) — recoloring', '.tint(color: Colors.orange) — перекраска'),
        spec: {
          'effect': 'tint',
          ...t(900),
          'color': hexColor(Colors.orange),
          'strength': [0, 1],
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .tint(color: Colors.orange, duration: d(900)),
      ),
      (
        title: 'desaturate',
        code: tr('.desaturate() — desaturation', '.desaturate() — обесцвечивание'),
        spec: {
          'effect': 'desaturate',
          ...t(1200),
          'saturation': [1, 0],
          'target': tr('photo', 'фото'),
          'repeat': pingPong,
        },
        child: Image.asset(
          'assets/eat_new_orleans_sm.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
        ).animate(onPlay: (c) => c.repeat(reverse: true)).desaturate(duration: d(1200)),
      ),
      (
        title: 'elevation',
        code: tr('.elevation(end: 24) — lift with a shadow', '.elevation(end: 24) — подъём с тенью'),
        spec: {
          'effect': 'elevation',
          ...t(900),
          'elevation': [0, 24],
          'radius_px': 14,
          'shadow_color': '#000000',
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .elevation(end: 24, borderRadius: BorderRadius.circular(14), duration: d(900)),
      ),
      (
        title: 'boxShadow',
        code: tr('.boxShadow(end: BoxShadow(…)) — glow', '.boxShadow(end: BoxShadow(…)) — свечение'),
        spec: {
          'effect': 'boxShadow',
          ...t(900),
          'shadow_end': {'color': hexColor(Colors.orange), 'blur_px': 28, 'spread_px': 6},
          'radius_px': 14,
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .boxShadow(
              end: const BoxShadow(color: Colors.orange, blurRadius: 28, spreadRadius: 6),
              borderRadius: BorderRadius.circular(14),
              duration: d(900),
            ),
      ),
      (
        title: 'color',
        code: tr(
          '.color(begin:, end:) — color change with blendMode',
          '.color(begin:, end:) — смена цвета с blendMode',
        ),
        spec: {
          'effect': 'color',
          ...t(900),
          'color': [hexColor(kAccent), hexColor(Colors.teal)],
          'blend_mode': 'srcATop',
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .color(
              begin: kAccent,
              end: Colors.teal,
              blendMode: BlendMode.srcATop,
              duration: d(900),
            ),
      ),
      (
        title: 'followPath',
        code: tr(
          '.followPath(path: …) — movement along a trajectory',
          '.followPath(path: …) — движение по траектории',
        ),
        spec: {
          'effect': 'followPath',
          ...t(2000),
          'path': tr('circle, radius 40 px, clockwise', 'окружность, радиус 40 px, по часовой'),
          'repeat': loop,
        },
        child: box
            .animate(onPlay: (c) => c.repeat())
            .followPath(
              path: Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 40)),
              duration: d(2000),
            ),
      ),
      (
        title: 'custom',
        code: tr('.custom(builder: …) — any effect of your own', '.custom(builder: …) — любой свой эффект'),
        spec: {
          'effect': 'custom',
          ...t(1000),
          'padding_px': [4, 24],
          'border': {'width_px': 2, 'radius_px': 20, 'color': hexColor(kAccent), 'opacity': [1, 0]},
          'repeat': pingPong,
        },
        child: box
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .custom(
              duration: d(1000),
              builder: (context, value, child) => Container(
                padding: EdgeInsets.all(4 + 20 * value),
                decoration: BoxDecoration(
                  border: Border.all(color: kAccent.withValues(alpha: 1 - value), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: child,
              ),
            ),
      ),
    ];
  }
}

/// Sandbox preview: a card with fade + slide, scale, or shimmer.
Widget _animatePlayground(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final card = Container(
    width: 220,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: v.color('color'), borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.bolt, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr('New card', 'Новая карточка'),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  switch (v.text('effect')) {
    case 'scale':
      final from = v.number('scale_from');
      return Transform.scale(scale: from + (1 - from) * e, child: card);
    case 'shimmer':
      final x = -1.5 + 3 * e;
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment(x - 0.4, -0.2),
          end: Alignment(x + 0.4, 0.2),
          colors: [Colors.transparent, v.color('shimmer_color').withValues(alpha: 0.7), Colors.transparent],
        ).createShader(rect),
        child: card,
      );
    default:
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, v.number('offset') * (1 - e)), child: card),
      );
  }
}

class _Box extends StatelessWidget {
  const _Box();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.bolt, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('New card', 'Новая карточка'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
