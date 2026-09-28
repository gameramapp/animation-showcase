// The "animation from config" showcase: the designer writes (or pastes) JSON
// with keyframes — properties, a CSS transform from Figma, or ready-made
// matrices — and immediately sees the result. The developer puts that same
// JSON into the product: the runtime lives in common/keyframe_spec.dart and
// carries over as is.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/anim_block.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import '../common/keyframe_spec.dart';

// Preset names and the JSON text itself are resolved through tr() every time
// this is called, so a preset picked in one language re-appears correctly
// worded if the language is switched before it's picked again.
List<(String, String)> _presets() => [
  (
    tr('Card appearance', 'Появление карточки'),
    tr(
      '''
{
  "name": "Card appearance",
  "duration_ms": 1400,
  "repeat": "loop",
  "keyframes": [
    { "at": 0, "opacity": 0, "y": 60, "scale": 0.85, "rotate": -6 },
    { "at": 0.45, "opacity": 1, "y": -8, "scale": 1.03, "rotate": 1,
      "curve": "cubic-bezier(0.2, 0, 0, 1)" },
    { "at": 0.7, "y": 0, "scale": 1, "rotate": 0, "curve": "spring(300, 20, 1)" },
    { "at": 1 }
  ]
}''',
      '''
{
  "name": "Появление карточки",
  "duration_ms": 1400,
  "repeat": "loop",
  "keyframes": [
    { "at": 0, "opacity": 0, "y": 60, "scale": 0.85, "rotate": -6 },
    { "at": 0.45, "opacity": 1, "y": -8, "scale": 1.03, "rotate": 1,
      "curve": "cubic-bezier(0.2, 0, 0, 1)" },
    { "at": 0.7, "y": 0, "scale": 1, "rotate": 0, "curve": "spring(300, 20, 1)" },
    { "at": 1 }
  ]
}''',
    ),
  ),
  (
    tr('Pulse', 'Пульс'),
    tr(
      '''
{
  "name": "Pulse invitation",
  "duration_ms": 1600,
  "repeat": "loop",
  "curve": "easeInOut",
  "keyframes": [
    { "at": 0, "scale": 1 },
    { "at": 0.15, "scale": 1.12 },
    { "at": 0.3, "scale": 0.97 },
    { "at": 0.45, "scale": 1.05 },
    { "at": 0.6, "scale": 1 },
    { "at": 1, "scale": 1 }
  ]
}''',
      '''
{
  "name": "Пульс-приглашение",
  "duration_ms": 1600,
  "repeat": "loop",
  "curve": "easeInOut",
  "keyframes": [
    { "at": 0, "scale": 1 },
    { "at": 0.15, "scale": 1.12 },
    { "at": 0.3, "scale": 0.97 },
    { "at": 0.45, "scale": 1.05 },
    { "at": 0.6, "scale": 1 },
    { "at": 1, "scale": 1 }
  ]
}''',
    ),
  ),
  (
    tr('3D flip', '3D-переворот'),
    tr(
      '''
{
  "name": "3D flip",
  "duration_ms": 1800,
  "repeat": "ping-pong",
  "perspective": 600,
  "curve": "easeInOutCubic",
  "keyframes": [
    { "at": 0, "rotate_y": 0 },
    { "at": 0.5, "rotate_y": 90, "scale": 0.9 },
    { "at": 1, "rotate_y": 180, "scale": 1 }
  ]
}''',
      '''
{
  "name": "3D-переворот",
  "duration_ms": 1800,
  "repeat": "ping-pong",
  "perspective": 600,
  "curve": "easeInOutCubic",
  "keyframes": [
    { "at": 0, "rotate_y": 0 },
    { "at": 0.5, "rotate_y": 90, "scale": 0.9 },
    { "at": 1, "rotate_y": 180, "scale": 1 }
  ]
}''',
    ),
  ),
  (
    tr('Swing from top', 'Качели от верха'),
    tr(
      '''
{
  "name": "Badge swing",
  "duration_ms": 2000,
  "repeat": "loop",
  "origin": [0.5, 0],
  "curve": "easeInOutSine",
  "keyframes": [
    { "at": 0, "rotate": 0 },
    { "at": 0.2, "rotate": 14 },
    { "at": 0.4, "rotate": -10 },
    { "at": 0.6, "rotate": 6 },
    { "at": 0.8, "rotate": -3 },
    { "at": 1, "rotate": 0 }
  ]
}''',
      '''
{
  "name": "Качели бейджа",
  "duration_ms": 2000,
  "repeat": "loop",
  "origin": [0.5, 0],
  "curve": "easeInOutSine",
  "keyframes": [
    { "at": 0, "rotate": 0 },
    { "at": 0.2, "rotate": 14 },
    { "at": 0.4, "rotate": -10 },
    { "at": 0.6, "rotate": 6 },
    { "at": 0.8, "rotate": -3 },
    { "at": 1, "rotate": 0 }
  ]
}''',
    ),
  ),
  (
    tr('Matrices from Figma', 'Матрицы из Figma'),
    tr(
      '''
{
  "name": "Matrices from Figma (Copy as CSS)",
  "duration_ms": 2400,
  "repeat": "ping-pong",
  "curve": "cubic-bezier(0.65, 0, 0.35, 1)",
  "keyframes": [
    { "at": 0, "css": "matrix(1, 0, 0, 1, 0, 0)" },
    { "at": 0.5, "css": "translate(40px, -20px) rotate(-15deg) scale(1.15)" },
    { "at": 1, "matrix": "matrix(0.866, 0.5, -0.5, 0.866, -30, 10)" }
  ]
}''',
      '''
{
  "name": "Матрицы из Figma (Copy as CSS)",
  "duration_ms": 2400,
  "repeat": "ping-pong",
  "curve": "cubic-bezier(0.65, 0, 0.35, 1)",
  "keyframes": [
    { "at": 0, "css": "matrix(1, 0, 0, 1, 0, 0)" },
    { "at": 0.5, "css": "translate(40px, -20px) rotate(-15deg) scale(1.15)" },
    { "at": 1, "matrix": "matrix(0.866, 0.5, -0.5, 0.866, -30, 10)" }
  ]
}''',
    ),
  ),
  (
    tr('Frames from After Effects', 'Кадры из After Effects'),
    tr(
      '''
{
  "name": "Frames from After Effects (30 fps)",
  "duration_ms": 1000,
  "fps": 30,
  "repeat": "loop",
  "keyframes": [
    { "frame": 0, "x": -80, "opacity": 0, "skew": [20, 0] },
    { "frame": 12, "x": 10, "opacity": 1, "skew": [-6, 0],
      "curve": "cubic-bezier(0.33, 0, 0.2, 1)" },
    { "frame": 18, "x": 0, "skew": [0, 0], "curve": "easeOutBack" },
    { "frame": 30, "x": 0 }
  ]
}''',
      '''
{
  "name": "Кадры из After Effects (30 fps)",
  "duration_ms": 1000,
  "fps": 30,
  "repeat": "loop",
  "keyframes": [
    { "frame": 0, "x": -80, "opacity": 0, "skew": [20, 0] },
    { "frame": 12, "x": 10, "opacity": 1, "skew": [-6, 0],
      "curve": "cubic-bezier(0.33, 0, 0.2, 1)" },
    { "frame": 18, "x": 0, "skew": [0, 0], "curve": "easeOutBack" },
    { "frame": 30, "x": 0 }
  ]
}''',
    ),
  ),
];

enum _Target { card, button, icon, image }

extension on _Target {
  String get label => switch (this) {
    _Target.card => tr('Card', 'Карточка'),
    _Target.button => tr('Button', 'Кнопка'),
    _Target.icon => tr('Icon', 'Иконка'),
    _Target.image => tr('Image', 'Картинка'),
  };
}

class ConfigAnimationDemo extends StatefulWidget {
  const ConfigAnimationDemo({super.key});
  static const String routeName = 'config/keyframes';

  @override
  State<ConfigAnimationDemo> createState() => _ConfigAnimationDemoState();
}

class _ConfigAnimationDemoState extends State<ConfigAnimationDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  final _text = TextEditingController(text: _presets().first.$2.trim());
  late KeyframeSpec _spec = _parse(_text.text)!;
  String? _error;
  int _preset = 0;
  _Target _target = _Target.card;

  @override
  void initState() {
    super.initState();
    _spec.play(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  KeyframeSpec? _parse(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) {
        throw FormatException(tr('the root must be an object {…}', 'корень должен быть объектом {…}'));
      }
      return KeyframeSpec.fromJson(json);
    } on FormatException catch (e) {
      _error = e.message;
      return null;
    }
  }

  void _onEdited(String source) {
    final spec = _parse(source);
    setState(() {
      if (spec == null) return;
      _error = null;
      _spec = spec;
    });
    // Invalid JSON doesn't break the preview — the last working version keeps playing.
    if (spec != null) spec.play(_controller);
  }

  void _loadPreset(int i) {
    _text.text = _presets()[i].$2.trim();
    setState(() => _preset = i);
    _onEdited(_text.text);
  }

  void _format() {
    try {
      _text.text = const JsonEncoder.withIndent('  ').convert(jsonDecode(_text.text));
    } on FormatException {
      // The error message is already shown under the editor.
    }
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _spec.play(_controller);
    }
    setState(() {});
  }

  void _jumpTo(double at) {
    _controller
      ..stop()
      ..value = at;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Animation from config', 'Анимация из конфига')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Keyframes in JSON', 'Ключевые кадры в JSON'),
            text: tr(
              "A motion animation can be fully described by data: where the "
              "element is at each moment, how big it is, how it's rotated and "
              "how transparent it is, and with which curve it transitions "
              "between frames. The designer writes it as a config — "
              "properties, a CSS transform string from Figma, or a ready-made "
              "matrix — and the app plays it back exactly. All the developer "
              "has to do is drop the same JSON into the product.",
              'Анимацию движения можно полностью описать данными: в какой '
                  'момент элемент где стоит, какого он размера, как повёрнут и '
                  'насколько прозрачен, и с какой кривой он переходит между '
                  'кадрами. Дизайнер записывает это конфигом — свойствами, '
                  'строкой CSS transform из Figma или готовой матрицей, — а '
                  'приложение проигрывает один в один. Разработчику остаётся '
                  'подставить тот же JSON в продукт.',
            ),
            hint: tr(
              'Pick a preset or edit the JSON on the right — the preview '
              'updates live. Errors are highlighted, and the last working '
              'version keeps playing.',
              'Выбери пресет или правь JSON справа — превью обновляется на '
                  'лету. Ошибки подсвечиваются, при этом играет последняя '
                  'рабочая версия.',
            ),
          ),
          const SizedBox(height: 16),
          const _HandoffSteps(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final preview = _buildPreview(context);
                  final editor = _buildEditor(context);
                  if (constraints.maxWidth < 860) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, const SizedBox(height: 16), editor],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: preview),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: editor),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _KeyframeList(spec: _spec, onJump: _jumpTo),
          const SizedBox(height: 16),
          const _FormatReference(),
          const SizedBox(height: 16),
          const _CodeCard(),
          const SizedBox(height: 16),
          DesignerBrief(
            items: [
              (
                tr('Duration and repeat', 'Длительность и повтор'),
                tr(
                  'duration_ms for the whole animation, and repeat: loop, ping-pong or once.',
                  'duration_ms всей анимации и repeat: loop, ping-pong или once.',
                ),
              ),
              (
                tr('Keyframes', 'Ключевые кадры'),
                tr(
                  'the time of each frame (in %, ms or a frame number + fps) and values: '
                      'x/y offset in px, scale, rotate in degrees, opacity 0–1.',
                  'время каждого кадра (в %, мс или номер кадра + fps) и значения: '
                      'сдвиг x/y в px, scale, rotate в градусах, opacity 0–1.',
                ),
              ),
              (
                tr('A transform from Figma', 'Трансформация из Figma'),
                tr(
                  "if it's simpler — a CSS transform string from Figma → Copy as CSS "
                      '(translate/rotate/scale) or a matrix(…) / matrix3d(…).',
                  'если проще — строка CSS transform из Figma → Copy as CSS '
                      '(translate/rotate/scale) или матрица matrix(…) / matrix3d(…).',
                ),
              ),
              (
                tr('Transition curves', 'Кривые переходов'),
                tr(
                  'for each segment: a preset, cubic-bezier(…) from Figma/AE or '
                      'spring(stiffness, damping, mass) from Smart Animate.',
                  'для каждого отрезка: пресет, cubic-bezier(…) из Figma/AE или '
                      'spring(жёсткость, затухание, масса) из Smart Animate.',
                ),
              ),
              (
                tr('Pivot point', 'Точка опоры'),
                tr(
                  'origin: which point to rotate and scale around ([0.5, 0.5] — center).',
                  'origin: вокруг какой точки вращать и масштабировать ([0.5, 0.5] — центр).',
                ),
              ),
              (
                tr('For 3D rotations', 'Для 3D-поворотов'),
                tr('perspective in px — how strong the depth effect is.', 'perspective в px — насколько сильный эффект глубины.'),
              ),
              (
                tr('Which element animates', 'Какой элемент анимируется'),
                tr(
                  'a link to the frame in Figma and what triggers the animation '
                      '(appearance, tap, event).',
                  'ссылка на фрейм в Figma и что запускает анимацию (появление, тап, событие).',
                ),
              ),
            ],
            avoid: [
              tr(
                "Sending only a video with no numbers — matching it \"by eye\" exactly "
                'won\'t work.',
                'Присылать только видео без цифр — повторить «на глаз» один в один не получится.',
              ),
              tr(
                'Setting a rotation greater than 180° between neighboring frames via matrix '
                    "— a matrix doesn't remember full turns; use rotate for that instead.",
                'Задавать в соседних кадрах поворот больше 180° через matrix — матрица не помнит обороты; для этого используй rotate.',
              ),
            ],
            handoff: tr(
              'Put together the JSON here, check it in the preview, press "Copy JSON" '
              'and attach it to the task.',
              'Собери JSON здесь, проверь в превью, нажми «Скопировать JSON» '
                  'и приложи к задаче.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_spec.name, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _GridPainter(),
            child: Center(
              child: KeyframeAnimator(
                spec: _spec,
                animation: _controller,
                child: _TargetWidget(target: _target),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final ms = (_controller.value * _spec.duration.inMilliseconds).round();
            final msUnit = tr('ms', 'мс');
            return Row(
              children: [
                IconButton(
                  tooltip: _controller.isAnimating ? tr('Pause', 'Пауза') : tr('Play', 'Играть'),
                  onPressed: _togglePlay,
                  icon: Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: tr('From the start', 'С начала'),
                  onPressed: () {
                    _controller.value = 0;
                    _spec.play(_controller);
                    setState(() {});
                  },
                  icon: const Icon(Icons.replay),
                ),
                Expanded(
                  child: Slider(
                    value: _controller.value,
                    onChanged: (v) => _jumpTo(v),
                  ),
                ),
                Text('$ms / ${_spec.duration.inMilliseconds} $msUnit', style: textTheme.bodySmall),
              ],
            );
          },
        ),
        _Timeline(spec: _spec, animation: _controller, onJump: _jumpTo),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _Target.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _target == t,
                onSelected: (_) => setState(() => _target = t),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final errorLabel = tr('Error', 'Ошибка');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('Presets', 'Пресеты'), style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, (name, _)) in _presets().indexed)
              ChoiceChip(
                label: Text(name),
                selected: _preset == i,
                onSelected: (_) => _loadPreset(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          onChanged: (v) {
            setState(() => _preset = -1);
            _onEdited(v);
          },
          minLines: 14,
          maxLines: 24,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.35),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: tr('Animation JSON', 'JSON анимации'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _error == null ? Icons.check_circle : Icons.error,
              size: 18,
              color: _error == null ? Colors.green : colors.error,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _error == null
                    ? tr(
                        'All good: ${_spec.keyframes.length} frames, '
                            '${_spec.duration.inMilliseconds} ms',
                        'Всё верно: ${_spec.keyframes.length} кадров, '
                            '${_spec.duration.inMilliseconds} мс',
                      )
                    : '$errorLabel: $_error',
                style: textTheme.bodySmall?.copyWith(
                  color: _error == null ? null : colors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _text.text));
                ScaffoldMessenger.maybeOf(
                  context,
                )?.showSnackBar(SnackBar(content: Text(tr('JSON copied', 'JSON скопирован'))));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text(tr('Copy JSON', 'Скопировать JSON')),
            ),
            OutlinedButton.icon(
              onPressed: _format,
              icon: const Icon(Icons.format_align_left, size: 18),
              label: Text(tr('Format', 'Форматировать')),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────── screen parts

class _HandoffSteps extends StatelessWidget {
  const _HandoffSteps();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = [
      (
        Icons.draw,
        tr('Assemble the frames', 'Собрать кадры'),
        tr(
          'In Figma — states (Smart Animate), in After Effects — keys.',
          'В Figma — состояния (Smart Animate), в After Effects — ключи.',
        ),
      ),
      (
        Icons.data_object,
        tr('Write the JSON', 'Записать JSON'),
        tr(
          'Properties, "Copy as CSS" from Figma, or matrices; curves — cubic-bezier or spring.',
          'Свойства, «Copy as CSS» из Figma или матрицы; кривые — cubic-bezier или spring.',
        ),
      ),
      (
        Icons.play_circle,
        tr('Check it here', 'Проверить здесь'),
        tr('Paste the JSON, take a look, tune the timings.', 'Вставить JSON, посмотреть, подкрутить тайминги.'),
      ),
      (
        Icons.send,
        tr('Hand it to development', 'Отдать в разработку'),
        tr('Attach the JSON to the task — it\'s two lines of code.', 'Приложить JSON к задаче — в коде это две строки.'),
      ),
    ];
    return ResponsiveWrap(
      minTileWidth: 200,
      children: [
        for (final (i, (icon, title, text)) in steps.indexed)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kAccent.withValues(alpha: 0.12),
                    child: Icon(icon, size: 18, color: kAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. $title', style: textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(text, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Timeline strip: keyframe marks and a running playhead. Tap a mark to jump to it.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.spec, required this.animation, required this.onJump});
  final KeyframeSpec spec;
  final Animation<double> animation;
  final ValueChanged<double> onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, c) => SizedBox(
          height: 28,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 13,
                  height: 2,
                  child: ColoredBox(color: kAccent.withValues(alpha: 0.2)),
                ),
                for (final kf in spec.keyframes)
                  Positioned(
                    left: c.maxWidth * kf.at - 8,
                    top: 6,
                    child: GestureDetector(
                      onTap: () => onJump(kf.at),
                      child: Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 12,
                          height: 12,
                          color: (animation.value - kf.at).abs() < 0.02 ? Colors.orange : kAccent,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: c.maxWidth * animation.value - 1,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: const ColoredBox(color: Colors.orange),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyframeList extends StatelessWidget {
  const _KeyframeList({required this.spec, required this.onJump});
  final KeyframeSpec spec;
  final ValueChanged<double> onJump;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ms = spec.duration.inMilliseconds;
    final msUnit = tr('ms', 'мс');
    final curveLabel = tr('curve', 'кривая');
    final defaultLabel = tr('default', 'по умолчанию');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Frames', 'Кадры'), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(
                "This is how the runtime read the spec. Tap a frame to stop on it.",
                'Так спеку прочитал рантайм. Тап по кадру — остановиться в нём.',
              ),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final (i, kf) in spec.keyframes.indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () => onJump(kf.at),
                leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                title: Text('${(kf.at * 100).round()}% · ${(kf.at * ms).round()} $msUnit'),
                subtitle: Text(
                  '${kf.summary}\n$curveLabel: '
                  '${i == 0 ? '—' : kf.curve ?? '${spec.curve} ($defaultLabel)'}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _FormatReference extends StatelessWidget {
  const _FormatReference();

  static List<(String, String)> get _rows => [
    ('duration_ms', tr('duration of the whole animation, ms', 'длительность всей анимации, мс')),
    (
      'repeat',
      tr(
        'loop — repeating, ping-pong — back and forth, once — once',
        'loop — по кругу, ping-pong — туда-обратно, once — один раз',
      ),
    ),
    (
      'curve',
      tr(
        'the default curve: a preset, cubic-bezier(…) or spring(stiffness, damping, mass)',
        'кривая по умолчанию: пресет, cubic-bezier(…) или spring(жёсткость, затухание, масса)',
      ),
    ),
    (
      'origin',
      tr(
        'the pivot point [x, y] as fractions: [0.5, 0.5] — center, [0.5, 0] — top',
        'точка опоры [x, y] в долях: [0.5, 0.5] — центр, [0.5, 0] — верх',
      ),
    ),
    (
      'perspective',
      tr('depth for 3D rotations, px (smaller — a stronger effect)', 'глубина для 3D-поворотов, px (меньше — сильнее эффект)'),
    ),
    (
      'keyframes[].at / at_ms / frame',
      tr('frame time: a fraction 0…1, ms or a frame number (+ fps)', 'время кадра: доля 0…1, мс или номер кадра (+ fps)'),
    ),
    ('opacity, x, y', tr('opacity 0…1 and offset in px', 'прозрачность 0…1 и сдвиг в px')),
    ('scale', tr('scale: a number or [x, y]', 'масштаб: число или [по X, по Y]')),
    (
      'rotate, rotate_x, rotate_y',
      tr('rotation in degrees (rotate_x / rotate_y — in 3D)', 'поворот в градусах (rotate_x / rotate_y — в 3D)'),
    ),
    ('skew', tr('skew [x, y] in degrees', 'наклон [x, y] в градусах')),
    (
      'css',
      tr(
        'a CSS transform string from Figma → Copy as CSS: translate, rotate, scale, skew, matrix',
        'строка CSS transform из Figma → Copy as CSS: translate, rotate, scale, skew, matrix',
      ),
    ),
    (
      'matrix',
      tr('the whole matrix: matrix(a, b, c, d, tx, ty) or matrix3d(16 numbers)', 'матрица целиком: matrix(a, b, c, d, tx, ty) или matrix3d(16 чисел)'),
    ),
    ('keyframes[].curve', tr('the curve the animation arrives at this frame with', 'кривая, с которой анимация приходит в этот кадр')),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('What can go in the JSON', 'Что можно писать в JSON'), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(
                "A property that isn't set takes the previous frame's value. If "
                'neighboring frames both set css / matrix, the transition is computed '
                'via matrix decomposition (the way a browser does it).',
                'Не указанное свойство кадр берёт из предыдущего. Если у соседних '
                    'кадров заданы css / matrix, переход считается через разложение '
                    'матрицы (как в браузере).',
              ),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final (key, text) in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    Text(text, style: textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard();

  static String get _code {
    final parseComment = tr(
      'JSON from the designer → a spec (errors are a clear FormatException)',
      'JSON от дизайнера → спека (ошибки — понятным FormatException)',
    );
    final playComment = tr('Start: duration and repeat come from the spec', 'Запуск: duration и repeat берутся из спеки');
    final animateComment = tr('Animate any widget', 'Анимируем любой виджет');
    return '''
// $parseComment
final spec = KeyframeSpec.fromJson(jsonDecode(json));

// $playComment
spec.play(controller);

// $animateComment
KeyframeAnimator(spec: spec, animation: controller, child: MyCard());''';
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
            Text(tr('What this looks like in code', 'Как это в коде'), style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(
                'The runtime is a single file, lib/src/common/keyframe_spec.dart, with no '
                'third-party packages. It can be moved into the product as is.',
                'Рантайм — один файл lib/src/common/keyframe_spec.dart, без '
                    'сторонних пакетов. Его можно перенести в продукт как есть.',
              ),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFFE0DEF4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetWidget extends StatelessWidget {
  const _TargetWidget({required this.target});
  final _Target target;

  @override
  Widget build(BuildContext context) {
    switch (target) {
      case _Target.card:
        return Container(
          width: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: kAccent, child: Icon(Icons.bolt, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('New reward', 'Новая награда'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case _Target.button:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(28)),
          child: Text(
            tr('Buy', 'Купить'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
        );
      case _Target.icon:
        return const Icon(Icons.star_rounded, size: 96, color: Colors.amber);
      case _Target.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/eat_sydney_sm.jpg', width: 160, height: 110, fit: BoxFit.cover),
        );
    }
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.05);
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final axis = Paint()..color = kAccent.withValues(alpha: 0.15);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), axis);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axis);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
