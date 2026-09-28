// The "animation through a matrix sequence" showcase: the designer sends N
// matrices (Figma → Copy as CSS: matrix(…), matrix3d(…) or any CSS
// transform), and Flutter smoothly carries the element through them.
//
// Under the hood — plain Flutter, no packages:
//   TweenSequence<Matrix4>([
//     TweenSequenceItem(tween: Matrix4Tween(begin: m0, end: m1).chain(CurveTween(curve: c)), weight: 600),
//     TweenSequenceItem(tween: ConstantTween(m1), weight: 300), // hold on the frame
//     …
//   ])
// Matrix4Tween interpolates via decomposition (translate / rotate / scale) —
// the way a browser does for CSS transform. For comparison there's an
// element-wise variant (Tween<Matrix4> — just lerp of 16 numbers), to show why not to do that.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import '../common/keyframe_spec.dart' show parseCssTransform;
import '../common/matrix_sequence.dart';

// ───────────────────────────────────────────────────────────────── model

enum _Interp { decompose, linear }

extension on _Interp {
  String get label => switch (this) {
    _Interp.decompose => tr('Matrix4Tween (decomposition, like CSS)', 'Matrix4Tween (разложение, как CSS)'),
    _Interp.linear => tr('Tween<Matrix4> (element-wise)', 'Tween<Matrix4> (поэлементно)'),
  };
}

/// A pivot point the designer can choose for the transform.
enum _Origin { center, topLeft, top, bottom, left }

extension on _Origin {
  String get label => switch (this) {
    _Origin.center => tr('center', 'центр'),
    _Origin.topLeft => tr('top left', 'левый верх'),
    _Origin.top => tr('top', 'верх'),
    _Origin.bottom => tr('bottom', 'низ'),
    _Origin.left => tr('left edge', 'левый край'),
  };

  Alignment get alignment => switch (this) {
    _Origin.center => Alignment.center,
    _Origin.topLeft => Alignment.topLeft,
    _Origin.top => Alignment.topCenter,
    _Origin.bottom => Alignment.bottomCenter,
    _Origin.left => Alignment.centerLeft,
  };
}

enum _Repeat { loop, pingPong, once }

extension on _Repeat {
  String get label => switch (this) {
    _Repeat.loop => tr('Loop', 'По кругу'),
    _Repeat.pingPong => tr('Back and forth', 'Туда-обратно'),
    _Repeat.once => tr('Once', 'Один раз'),
  };
}

typedef _Seq = MatrixSequence;

_Seq _buildSequence(
  List<MatrixStep> steps, {
  required int defaultMs,
  required String defaultCurve,
  required int holdMs,
  required _Interp interp,
}) => MatrixSequence.fromSteps(
  steps,
  defaultDurationMs: defaultMs,
  defaultCurve: defaultCurve,
  holdMs: holdMs,
  linear: interp == _Interp.linear,
);

/// A human-readable decoding of the matrix's 2D part.
class _Decoded {
  _Decoded(Matrix4 m) {
    final s = m.storage;
    final a = s[0], b = s[1], c = s[4], d = s[5];
    tx = s[12];
    ty = s[13];
    is3d =
        s[2].abs() > 1e-6 ||
        s[6].abs() > 1e-6 ||
        s[8].abs() > 1e-6 ||
        s[9].abs() > 1e-6 ||
        (s[10] - 1).abs() > 1e-6 ||
        s[14].abs() > 1e-6;
    scaleX = math.sqrt(a * a + b * b);
    rotation = math.atan2(b, a) * 180 / math.pi;
    final det = a * d - b * c;
    scaleY = scaleX == 0 ? 0 : det / scaleX;
    skew = scaleX == 0 ? 0 : math.atan2(a * c + b * d, scaleX * scaleX) * 180 / math.pi;
  }

  late final double tx, ty, scaleX, scaleY, rotation, skew;
  late final bool is3d;

  String get summary {
    String f(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll(RegExp(r'\.0+$'), '');
    final parts = [
      tr('shift ${f(tx, 0)}, ${f(ty, 0)} px', 'сдвиг ${f(tx, 0)}, ${f(ty, 0)} px'),
      tr('rotation ${f(rotation)}°', 'поворот ${f(rotation)}°'),
      tr('scale ${f(scaleX, 2)} × ${f(scaleY, 2)}', 'масштаб ${f(scaleX, 2)} × ${f(scaleY, 2)}'),
      if (skew.abs() > 0.05) tr('skew ${f(skew)}°', 'скос ${f(skew)}°'),
      if (scaleY < 0) tr('mirrored', 'отражение'),
      if (is3d) '3D',
    ];
    return parts.join(' · ');
  }

  /// Skew is lost on decomposition — Matrix4Tween will reduce it to rotation/scale.
  bool get skewLost => skew.abs() > 0.05;
}

Matrix4 _withPerspective(Matrix4 m, double perspective) {
  final p = Matrix4.identity();
  if (perspective > 0) p.setEntry(3, 2, 1 / perspective);
  return p..multiply(m);
}

// ───────────────────────────────────────────────────────────────── presets

// The matrix/CSS text itself is language-neutral (numbers and CSS syntax) —
// only the preset's button label needs tr(), so this stays a function only
// because the label does.
List<(String, String)> _presets() => [
  (
    tr('Card: 4 poses', 'Карточка: 4 позы'),
    'matrix(1, 0, 0, 1, 0, 0)\n'
        'matrix(0.966, -0.259, 0.259, 0.966, 40, -20) | 500 | easeOutBack\n'
        'matrix(1.15, 0, 0, 1.15, 0, -30) | 400 | easeInOutCubic\n'
        'matrix(0.94, 0.342, -0.342, 0.94, -40, 10) | 600 | spring(300, 20, 1)',
  ),
  (
    tr('From Figma: Copy as CSS', 'Из Figma: Copy as CSS'),
    'transform: rotate(0deg);\n'
        'transform: rotate(-12deg) translate(20px, 0);\n'
        'transform: matrix(1.2, 0, 0, 1.2, 0, -20);\n'
        'transform: scale(0.9) rotate(8deg);',
  ),
  (
    tr('3D: matrix3d', '3D: matrix3d'),
    '// rotateY 0° → 45° → 90° → rotateX 45°\n'
        'matrix3d(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)\n'
        'matrix3d(0.707,0,-0.707,0, 0,1,0,0, 0.707,0,0.707,0, 0,0,0,1)\n'
        'matrix3d(0,0,-1,0, 0,1,0,0, 1,0,0,0, 0,0,0,1)\n'
        'matrix3d(1,0,0,0, 0,0.707,0.707,0, 0,-0.707,0.707,0, 0,0,0,1)',
  ),
  (
    tr('Skew (compare methods)', 'Скос (сравни методы)'),
    'matrix(1, 0, 0, 1, 0, 0)\n'
        'matrix(1, 0, 0.6, 1, 0, 0)\n'
        'matrix(1, 0, -0.6, 1, 0, 0)\n'
        'matrix(1, 0, 0, 1, 0, 0)',
  ),
  (
    tr('Rotate 0 → 180°', 'Поворот 0 → 180°'),
    'matrix(1, 0, 0, 1, 0, 0)\n'
        'matrix(0, 1, -1, 0, 0, 0)\n'
        'matrix(-1, 0, 0, -1, 0, 0)',
  ),
];

// ────────────────────────────────────────────────────────────────── screen

class MatrixSequenceDemo extends StatelessWidget {
  const MatrixSequenceDemo({super.key});
  static const String routeName = 'config/matrix_sequence';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Matrix sequence', 'Сиквенция матриц')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Animation through a sequence of matrices', 'Анимация последовательностью матриц'),
            text: tr(
              'Any position of an element — offset, rotation, scale, skew, even '
              '3D — can be written as a single transform matrix. Figma hands it '
              'over in Dev Mode (Copy as CSS → transform: matrix(…)). Give us a '
              'few of these matrices in order — Flutter smoothly carries the '
              'element through all of them, with the durations and curves you '
              "need. It's built-in TweenSequence + Matrix4Tween, no packages.",
              'Любое положение элемента — сдвиг, поворот, масштаб, скос, даже '
                  '3D — можно записать одной матрицей трансформации. Figma отдаёт её '
                  'в Dev Mode (Copy as CSS → transform: matrix(…)). Дайте нам '
                  'несколько таких матриц по порядку — Flutter плавно проведёт '
                  'элемент через все, с нужными длительностями и кривыми. Это '
                  'встроенные TweenSequence + Matrix4Tween, без пакетов.',
            ),
            hint: tr(
              'Pick a preset or paste your own matrices — one per line. After the '
              'matrix, a "|" lets you set the duration and curve of the transition into it.',
              'Выбери пресет или вставь свои матрицы — по одной на строку. '
                  'После матрицы через «|» можно задать длительность и кривую '
                  'перехода в неё.',
            ),
          ),
          const SizedBox(height: 16),
          const _SequenceEditor(),
          const SizedBox(height: 16),
          const _CompareBlock(),
          const SizedBox(height: 16),
          const _CodeCard(),
          const SizedBox(height: 16),
          const _Brief(),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────── sequence editor

class _SequenceEditor extends StatefulWidget {
  const _SequenceEditor();

  @override
  State<_SequenceEditor> createState() => _SequenceEditorState();
}

class _SequenceEditorState extends State<_SequenceEditor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final _text = TextEditingController(text: _presets().first.$2);
  int _preset = 0;

  List<MatrixStep> _steps = const [];
  Map<int, String> _errors = const {};
  late _Seq _seq;

  int _durationMs = 600;
  String _curve = 'easeInOutCubic';
  int _holdMs = 300;
  _Interp _interp = _Interp.decompose;
  _Repeat _repeat = _Repeat.loop;
  _Origin _origin = _Origin.center;
  bool _perspective = true;
  double _perspectivePx = 800;

  @override
  void initState() {
    super.initState();
    _reparse(_text.text, play: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  void _reparse(String text, {bool play = false}) {
    final (steps, errors) = MatrixSequence.parseLines(text);
    _errors = errors;
    // Fewer than two valid matrices — keep playing the last working version.
    if (steps.length >= 2) _steps = steps;
    if (_steps.length < 2) {
      _steps = MatrixSequence.parseLines(_presets().first.$2).$1;
    }
    _rebuild(play: play);
  }

  void _rebuild({bool play = true}) {
    _seq = _buildSequence(
      _steps,
      defaultMs: _durationMs,
      defaultCurve: _curve,
      holdMs: _holdMs,
      interp: _interp,
    );
    if (play) _play();
  }

  void _play() {
    _controller.duration = Duration(milliseconds: _seq.duration.inMilliseconds);
    switch (_repeat) {
      case _Repeat.loop:
        _controller.repeat();
      case _Repeat.pingPong:
        _controller.repeat(reverse: true);
      case _Repeat.once:
        _controller.forward(from: 0);
    }
  }

  void _jump(double at) {
    _controller
      ..stop()
      ..value = at;
    setState(() {});
  }

  Map<String, Object?> _spec() => {
    'widget': 'TweenSequence<Matrix4> + ${_interp.label}',
    'matrices': [
      for (final (i, s) in _steps.indexed)
        {
          'matrix': s.raw,
          if (i > 0)
            ...timingSpec(durationMs: s.durationMs ?? _durationMs, curve: s.curve ?? _curve),
          'decoded': _Decoded(s.matrix).summary,
        },
    ],
    'hold_ms': _holdMs,
    'total_ms': _seq.duration.inMilliseconds,
    'repeat': _repeat.name,
    'origin': _origin.label,
    'perspective_px': _perspective ? _perspectivePx.round() : null,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final msUnit = tr('ms', 'мс');
    final sequenceTitle = tr('Matrix sequence', 'Сиквенция матриц');
    final errorLabel = tr('Error', 'Ошибка');

    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform(
                  alignment: _origin.alignment,
                  transform: _withPerspective(
                    _seq.tween.transform(_controller.value),
                    _perspective ? _perspectivePx : 0,
                  ),
                  child: child,
                ),
                child: const _SampleCard(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            children: [
              IconButton(
                tooltip: _controller.isAnimating ? tr('Pause', 'Пауза') : tr('Play', 'Играть'),
                onPressed: () {
                  _controller.isAnimating ? _controller.stop() : _play();
                  setState(() {});
                },
                icon: Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
              ),
              Expanded(
                child: Slider(value: _controller.value, onChanged: _jump),
              ),
              Text(
                '${(_controller.value * _seq.duration.inMilliseconds).round()} / ${_seq.duration.inMilliseconds} $msUnit',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _Timeline(marks: _seq.marks, animation: _controller, onJump: _jump),
      ],
    );

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, (name, text)) in _presets().indexed)
              ChoiceChip(
                label: Text(name),
                selected: _preset == i,
                onSelected: (_) {
                  _text.text = text;
                  setState(() {
                    _preset = i;
                    _perspective = true;
                    _reparse(text, play: true);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 10,
          onChanged: (v) => setState(() {
            _preset = -1;
            _reparse(v, play: true);
          }),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: tr('Matrices — one per line', 'Матрицы — по одной на строку'),
            helperText: tr(
              'matrix(…) | matrix3d(…) | CSS transform  [ | ms | curve ]',
              'matrix(…) | matrix3d(…) | CSS transform  [ | мс | кривая ]',
            ),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 6),
        if (_errors.isEmpty)
          Text(
            tr(
              'All good: ${_steps.length} matrices, ${_seq.duration.inMilliseconds} ms',
              'Всё верно: ${_steps.length} матриц, ${_seq.duration.inMilliseconds} мс',
            ),
            style: textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
          )
        else
          for (final e in _errors.values)
            Text('$errorLabel: $e', style: textTheme.bodySmall?.copyWith(color: colors.error)),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(sequenceTitle, style: textTheme.titleMedium)),
                SpecButton(title: sequenceTitle, spec: _spec),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) => c.maxWidth < 860
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, const SizedBox(height: 16), editor],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: preview),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: editor),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _settings(context),
            const SizedBox(height: 16),
            Text(tr("What's inside each matrix", 'Что внутри каждой матрицы'), style: textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final (i, s) in _steps.indexed) _stepRow(context, i, s),
          ],
        ),
      ),
    );
  }

  Widget _settings(BuildContext context) {
    return ResponsiveWrap(
      minTileWidth: 260,
      children: [
        LabeledSlider(
          label: tr('Default transition', 'Переход по умолчанию'),
          value: _durationMs.toDouble(),
          min: 100,
          max: 3000,
          unit: tr('ms', 'мс'),
          onChanged: (v) => setState(() {
            _durationMs = v.round();
            _rebuild();
          }),
        ),
        LabeledSlider(
          label: tr('Hold on each matrix', 'Пауза на каждой матрице'),
          value: _holdMs.toDouble(),
          min: 0,
          max: 2000,
          unit: tr('ms', 'мс'),
          onChanged: (v) => setState(() {
            _holdMs = v.round();
            _rebuild();
          }),
        ),
        CurveDropdown(
          value: _curve,
          onChanged: (v) => setState(() {
            _curve = v;
            _rebuild();
          }),
        ),
        _labeledDropdown<_Interp>(
          tr('Interpolation', 'Интерполяция'),
          _interp,
          _Interp.values,
          (e) => e.label,
          (v) => setState(() {
            _interp = v;
            _rebuild();
          }),
        ),
        _labeledDropdown<_Repeat>(
          tr('Repeat', 'Повтор'),
          _repeat,
          _Repeat.values,
          (e) => e.label,
          (v) => setState(() {
            _repeat = v;
            _play();
          }),
        ),
        _labeledDropdown<_Origin>(
          tr('Pivot point (transform-origin)', 'Точка опоры (transform-origin)'),
          _origin,
          _Origin.values,
          (e) => e.label,
          (v) => setState(() => _origin = v),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(tr('Perspective (for 3D)', 'Перспектива (для 3D)')),
              value: _perspective,
              onChanged: (v) => setState(() => _perspective = v),
            ),
            if (_perspective)
              LabeledSlider(
                label: tr('Depth', 'Глубина'),
                value: _perspectivePx,
                min: 200,
                max: 3000,
                unit: 'px',
                onChanged: (v) => setState(() => _perspectivePx = v),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepRow(BuildContext context, int i, MatrixStep s) {
    final textTheme = Theme.of(context).textTheme;
    final d = _Decoded(s.matrix);
    final msUnit = tr('ms', 'мс');
    final timing = i == 0 ? tr('start', 'старт') : '${s.durationMs ?? _durationMs} $msUnit · ${s.curve ?? _curve}';
    return InkWell(
      onTap: () => _jump(_seq.marks[i]),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 13, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.raw,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('${d.summary}  ·  $timing', style: textTheme.bodySmall),
                  if (d.skewLost && _interp == _Interp.decompose)
                    Text(
                      tr(
                        "There's a skew: Matrix4Tween will decompose the matrix without it, "
                        'turning the skew into rotation/scale along the way. Compare with '
                        'the element-wise mode.',
                        'Есть скос: Matrix4Tween разложит матрицу без него, по пути '
                            'скос превратится в поворот/масштаб. Сравни с поэлементным режимом.',
                      ),
                      style: textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _labeledDropdown<T>(
  String label,
  T value,
  List<T> items,
  String Function(T) text,
  ValueChanged<T> onChanged,
) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: [
            for (final i in items)
              DropdownMenuItem(
                value: i,
                child: Text(text(i), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    ),
  );
}

/// Matrix marks on the time scale and a playhead; tap a mark to jump to it.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.marks, required this.animation, required this.onJump});
  final List<double> marks;
  final Animation<double> animation;
  final ValueChanged<double> onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, c) => SizedBox(
          height: 30,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  height: 2,
                  child: ColoredBox(color: kAccent.withValues(alpha: 0.2)),
                ),
                for (final (i, m) in marks.indexed)
                  Positioned(
                    left: c.maxWidth * m - 11,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => onJump(m),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: (animation.value - m).abs() < 0.03
                            ? Colors.orange
                            : kAccent,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
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

// ─────────────────────────────────────────────── decomposition vs element-wise

class _CompareBlock extends StatefulWidget {
  const _CompareBlock();

  @override
  State<_CompareBlock> createState() => _CompareBlockState();
}

class _CompareBlockState extends State<_CompareBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  int _preset = 4; // "Rotate 0 → 180°" — the difference is most visible here
  int _durationMs = 900;
  String _curve = 'easeInOut';
  late List<MatrixStep> _steps;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  void _apply() {
    _steps = MatrixSequence.parseLines(_presets()[_preset].$2).$1;
    final seq = _build(_Interp.decompose);
    _controller
      ..duration = Duration(milliseconds: seq.duration.inMilliseconds)
      ..repeat(reverse: true);
  }

  _Seq _build(_Interp interp) =>
      _buildSequence(
        _steps,
        defaultMs: _durationMs,
        defaultCurve: _curve,
        holdMs: 250,
        interp: interp,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _build(_Interp.decompose), b = _build(_Interp.linear);
    final decomposeLabel = tr('Matrix4Tween\ndecomposition', 'Matrix4Tween\nразложение');
    final elementWiseLabel = tr('Tween<Matrix4>\nelement-wise', 'Tween<Matrix4>\nпоэлементно');
    Widget pane(String label, TweenSequence<Matrix4> tween) => Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform(
                  alignment: Alignment.center,
                  transform: _withPerspective(tween.transform(_controller.value), 800),
                  child: child,
                ),
                child: const _SampleCard(small: true),
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );

    return AnimBlock(
      title: tr('Decomposition vs element-wise', 'Разложение vs поэлементно'),
      description: tr(
        "The same matrices — two ways to move between them. Matrix4Tween "
        'decomposes the matrix into shift, rotation and scale and drives them '
        'separately — the way a browser does for CSS. Element-wise lerp just '
        'blends 16 numbers: on a 0 → 180° rotation, the card collapses to a '
        'point along the way. So for transitions — Matrix4Tween only.',
        'Одни и те же матрицы — два способа провести между ними. Matrix4Tween '
            'раскладывает матрицу на сдвиг, поворот и масштаб и ведёт их по '
            'отдельности — как браузер для CSS. Поэлементный lerp просто '
            'смешивает 16 чисел: на повороте 0 → 180° карточка по пути '
            'схлопывается в точку. Поэтому для переходов — только Matrix4Tween.',
      ),
      spec: () => {
        'matrices': [for (final s in _steps) s.raw],
        ...timingSpec(durationMs: _durationMs, curve: _curve),
        'left': tr('Matrix4Tween (decomposition)', 'Matrix4Tween (разложение)'),
        'right': tr(
          'Tween<Matrix4> (element-wise) — do not use for transitions',
          'Tween<Matrix4> (поэлементно) — не использовать для переходов',
        ),
      },
      preview: Row(
        children: [
          pane(decomposeLabel, a.tween),
          const VerticalDivider(width: 1),
          pane(elementWiseLabel, b.tween),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in [4, 3, 0])
                ChoiceChip(
                  label: Text(_presets()[i].$1),
                  selected: _preset == i,
                  onSelected: (_) => setState(() {
                    _preset = i;
                    _apply();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Transition duration', 'Длительность перехода'),
            value: _durationMs.toDouble(),
            min: 200,
            max: 3000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() {
              _durationMs = v.round();
              _apply();
            }),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── code

class _CodeCard extends StatelessWidget {
  const _CodeCard();

  static String get _code {
    final c1 = tr(
      "1. Text from the designer — as is (can live in assets or come from the backend)",
      '1. Текст от дизайнера — как есть (можно хранить в assets или приходить с бэка)',
    );
    final c2 = tr(
      '2. Parsing (FormatException with line numbers if something is off)',
      '2. Разбор (FormatException с номерами строк, если что-то не так)',
    );
    final c3 = tr('3. A controller for the whole sequence length', '3. Контроллер на всю длину сиквенции');
    final c4 = tr('4. Animate any widget', '4. Анимируем любой виджет');
    return '''
// $c1
const cardMotion = \'\'\'
matrix(1, 0, 0, 1, 0, 0)
matrix(0.966, -0.259, 0.259, 0.966, 40, -20) | 500 | easeOutBack
matrix(1.15, 0, 0, 1.15, 0, -30) | 400 | easeInOutCubic
matrix(0.94, 0.342, -0.342, 0.94, -40, 10) | 600 | spring(300, 20, 1)
\'\'\';

// $c2
final seq = MatrixSequence.parse(cardMotion, holdMs: 300);

// $c3
late final controller = AnimationController(vsync: this, duration: seq.duration)
  ..repeat();

// $c4
MatrixSequenceAnimator(sequence: seq, animation: controller, child: const MyCard());''';
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
                'Just Flutter, no packages. The runtime is lib/src/common/matrix_sequence.dart '
                '(+ keyframe_spec.dart and motion_spec.dart): it moves into the product as is. '
                'Inside — a TweenSequence made of Matrix4Tween.',
                'Только Flutter, без пакетов. Рантайм — lib/src/common/matrix_sequence.dart '
                    '(+ keyframe_spec.dart и motion_spec.dart): переносится в продукт как есть. '
                    'Внутри — TweenSequence из Matrix4Tween.',
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

// ─────────────────────────────────────────────────── what's needed from the designer

class _Brief extends StatelessWidget {
  const _Brief();

  @override
  Widget build(BuildContext context) {
    return DesignerBrief(
      items: [
        (
          tr('Matrices in order', 'Матрицы по порядку'),
          tr(
            'for each key state — Figma Dev Mode → Copy as CSS → '
                'transform: matrix(…) or matrix3d(…); rotate()/scale()/translate() work too.',
            'для каждого ключевого состояния — Figma Dev Mode → Copy as CSS → '
                'transform: matrix(…) или matrix3d(…); можно и rotate()/scale()/translate().',
          ),
        ),
        (
          tr('Offset separately', 'Сдвиг отдельно'),
          tr(
            "Figma reports position as left/top, not in the matrix — send the offset "
                'between states in px (or write it into tx, ty of the matrix).',
            'Figma отдаёт позицию как left/top, а не в матрице — пришли сдвиг между '
                'состояниями в px (или впиши его в tx, ty матрицы).',
          ),
        ),
        (
          tr('Duration of each transition', 'Длительность каждого перехода'),
          tr('in ms: from state 1 to 2, from 2 to 3, and so on.', 'в мс: из состояния 1 в 2, из 2 в 3 и т. д.'),
        ),
        (
          tr('Curve of each transition', 'Кривая каждого перехода'),
          tr(
            'a preset, cubic-bezier(…) from Figma or spring(stiffness, damping, mass).',
            'пресет, cubic-bezier(…) из Figma или spring(жёсткость, затухание, масса).',
          ),
        ),
        (tr('Holds', 'Паузы'), tr('how long the element stays in each state, ms.', 'сколько элемент стоит в каждом состоянии, мс.')),
        (
          tr('Pivot point', 'Точка опоры'),
          tr(
            'transform-origin: center, a corner or an edge — what to rotate around and grow from.',
            'transform-origin: центр, угол или край — вокруг чего крутить и откуда растить.',
          ),
        ),
        (
          tr('Repeat', 'Повтор'),
          tr('once, looping or back and forth; for 3D — perspective in px.', 'один раз, по кругу или туда-обратно; для 3D — перспектива в px.'),
        ),
      ],
      avoid: [
        tr(
          "A rotation greater than 180° between neighboring matrices — a matrix doesn't "
              'remember full turns, so Flutter will take the short way around. Split it '
              'into steps of ≤ 180°.',
          'Поворот больше 180° между соседними матрицами — матрица не помнит обороты, '
              'Flutter пойдёт коротким путём. Разбей на шаги ≤ 180°.',
        ),
        tr(
          'Skew in matrices — decomposition turns it into rotation/scale. If you need a '
              'skew, better to set it as a property in "Animation from config" instead.',
          'Скос (skew) в матрицах — при разложении он превращается в поворот/масштаб. '
              'Если нужен скос, лучше задать его свойством в «Анимации из конфига».',
        ),
      ],
      handoff: tr(
        'Paste the matrices into the editor above, check them, press "Spec" and attach '
        'the JSON to the task.',
        'Вставь матрицы в редактор выше, проверь, нажми «Спека» и приложи JSON к задаче.',
      ),
      playground: BriefPlayground(
        fields: [
          BriefField.text('m1', tr('Matrix 1', 'Матрица 1'), 'matrix(1, 0, 0, 1, 0, 0)'),
          BriefField.text('m2', tr('Matrix 2', 'Матрица 2'), 'matrix(0.966, -0.259, 0.259, 0.966, 40, -20)'),
          BriefField.text('m3', tr('Matrix 3', 'Матрица 3'), 'matrix(1.15, 0, 0, 1.15, 0, -30)'),
          BriefField.text('m4', tr('Matrix 4', 'Матрица 4'), 'matrix(0.94, 0.342, -0.342, 0.94, -40, 10)'),
          BriefField.duration('duration_ms', tr('Whole pass (3 transitions)', 'Весь проход (3 перехода)'), 1800),
          BriefField.curve('curve', tr('Curve of each transition', 'Кривая каждого перехода'), 'easeInOutCubic'),
        ],
        mode: PlaygroundMode.loop,
        builder: _playgroundPreview,
      ),
    );
  }
}

final _parsedCache = <String, Matrix4?>{};

Matrix4? _tryMatrix(String s) => _parsedCache.putIfAbsent(s, () {
  try {
    return parseCssTransform(s);
  } on FormatException {
    return null;
  }
});

Widget _playgroundPreview(BuildContext context, BriefValues v, double t) {
  final raw = [
    for (final k in ['m1', 'm2', 'm3', 'm4']) v.text(k),
  ];
  final matrices = [for (final r in raw) _tryMatrix(r)];
  final bad = [
    for (final (i, m) in matrices.indexed)
      if (m == null) i + 1,
  ];
  if (bad.isNotEmpty) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        tr(
          "Couldn't parse matrix ${bad.join(', ')} — need matrix(…), matrix3d(…) or a CSS transform.",
          'Не разобрал матрицу ${bad.join(', ')} — нужен matrix(…), matrix3d(…) или CSS transform.',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
  final ms = matrices.cast<Matrix4>();
  final curve = v.curve('curve');
  // Three equal transitions in sequence.
  final seg = (t * 3).clamp(0.0, 2.9999);
  final i = seg.floor();
  final m = Matrix4Tween(begin: ms[i], end: ms[i + 1]).lerp(curve.transform(seg - i));
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Transform(
        alignment: Alignment.center,
        transform: _withPerspective(m, 800),
        child: const _SampleCard(small: true),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var k = 0; k < 4; k++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (seg - k).abs() < 0.5 || (k == 3 && t >= 0.99)
                    ? Colors.orange
                    : Colors.black12,
              ),
            ),
        ],
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────── samples

class _SampleCard extends StatelessWidget {
  const _SampleCard({this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 110 : 160,
      height: small ? 70 : 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [kAccent, Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: const Align(
        alignment: Alignment.topLeft,
        child: Icon(Icons.north_east, color: Colors.white),
      ),
    );
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
