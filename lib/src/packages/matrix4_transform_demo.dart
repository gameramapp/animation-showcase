// Showcase of the matrix4_transform package — a "human" fluent API for
// transformation matrices instead of manual work with Matrix4:
//   • Playground — rotation, scale, translation, flips, pivot point (origin),
//     skew + presets "Card tilt", "Fly away", "Flip"; below the preview is
//     the generated code chain;
//   • Directions — up/down/left/right, diagonals and directionDegrees;
//   • Hover cards — ready-made hover reactions for the web.
// Everything is animated by a plain AnimatedContainer(transform: ...): it
// smoothly interpolates the matrix from the old value to the new one.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class Matrix4TransformDemo extends StatelessWidget {
  const Matrix4TransformDemo({super.key});
  static const String routeName = 'packages/matrix4_transform';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('matrix4_transform'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('The matrix4_transform package', 'Пакет matrix4_transform'),
            text: tr(
              'Rotate, scale, move and flip widgets with a chain of readable '
                  'commands: .rotateDegrees(15).scale(1.2).up(20). Every command can '
                  'take a pivot point (origin) — what to rotate around and where to '
                  'grow from. Paired with AnimatedContainer, any change turns into a '
                  'smooth animation. Pure Dart, works without limits on the web.',
              'Поворачивать, масштабировать, сдвигать и отражать виджеты '
                  'цепочкой понятных команд: .rotateDegrees(15).scale(1.2).up(20). '
                  'У каждой команды можно задать точку опоры (origin) — вокруг '
                  'чего вращать и откуда растить. В паре с AnimatedContainer '
                  'любое изменение превращается в плавную анимацию. Чистый Dart, '
                  'в вебе работает без ограничений.',
            ),
            hint: tr(
              'The playground cycles through presets on its own. Touch any '
                  'control — auto-play stops and you take over.',
              'Плейграунд сам перебирает пресеты. Тронь любую ручку — '
                  'автопоказ остановится, и управление перейдёт к тебе.',
            ),
          ),
          const SizedBox(height: 16),
          const _PlaygroundBlock(),
          const SizedBox(height: 16),
          const _DirectionsBlock(),
          const SizedBox(height: 16),
          const _HoverCardsBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 700),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeInOutCubic'),
                BriefField.number('rotateDegrees', 'rotateDegrees', -6, unit: '°', min: -360, max: 360),
                BriefField.number('scale', 'scale', 1.08, unit: '×', min: 0, max: 5),
                BriefField.number('translate_x', 'translate x', 0, unit: 'px', min: -200, max: 200),
                BriefField.number('translate_y', 'translate y', -14, unit: 'px', min: -200, max: 200),
                BriefField.choice(
                  'origin',
                  tr('Pivot point (origin)', 'Точка опоры (origin)'),
                  ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
                  'center',
                ),
              ],
              builder: _matrixPlayground,
            ),
            items: [
              (
                tr('"Before" and "after" states', 'Состояния «до» и «после»'),
                tr(
                  'two frames in Figma: the starting position and the final one; for hover — normal and hovered',
                  'два кадра в Figma: исходное положение и конечное; для hover — обычное и при наведении',
                ),
              ),
              (
                tr('Transform values', 'Значения трансформации'),
                tr(
                  'rotation in °, scale (×), x / y shift in px, horizontal/vertical flip, skew in °',
                  'поворот в °, масштаб (×), сдвиг x / y в px, отражение по горизонтали/вертикали, скос в °',
                ),
              ),
              (
                tr('Pivot point (origin)', 'Точка опоры (origin)'),
                tr(
                  'what to rotate around and where to grow from: center, corner, edge — or coordinates in '
                      'px from the top-left corner',
                  'вокруг чего вращать и откуда растить: центр, угол, край — или координаты в px от левого верхнего угла',
                ),
              ),
              (
                tr('Or a ready-made matrix', 'Или готовая матрица'),
                tr(
                  'Figma → Copy as CSS: transform / matrix(…) + transform-origin — the developer will port it 1:1',
                  'Figma → Copy as CSS: transform / matrix(…) + transform-origin — разработчик перенесёт один в один',
                ),
              ),
              (
                tr('Timing', 'Тайминг'),
                tr(
                  'transition duration in ms and the curve (a preset or a cubic-bezier from Figma)',
                  'длительность перехода в мс и кривая (пресет или cubic-bezier из Figma)',
                ),
              ),
              (
                tr('Perspective', 'Перспектива'),
                tr('is depth needed for flips (CSS perspective in px)', 'нужна ли объёмность для переворотов (CSS perspective в px)'),
              ),
            ],
            avoid: [
              tr(
                'A full 360° turn through the matrix — AnimatedContainer interpolates the matrix and the '
                    'turn "collapses"; use a separate RotationTransition instead.',
                'Полный оборот на 360° через матрицу — AnimatedContainer интерполирует матрицу и оборот «схлопывается»; нужен отдельный RotationTransition.',
              ),
              tr(
                'Skew as part of the package\'s chain — matrix4_transform doesn\'t have it, it\'s done with a separate Transform.',
                'Скос как часть цепочки пакета — в matrix4_transform его нет, он делается отдельным Transform.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Playground

const _cardSize = Size(150, 94);

/// The nine pivot points offered by the origin picker, in reading order.
const _originPoints = <Alignment>[
  Alignment.topLeft,
  Alignment.topCenter,
  Alignment.topRight,
  Alignment.centerLeft,
  Alignment.center,
  Alignment.centerRight,
  Alignment.bottomLeft,
  Alignment.bottomCenter,
  Alignment.bottomRight,
];

/// Human description of a pivot point (for tooltips and code comments).
String _originLabel(Alignment a) => switch (a) {
  Alignment.topLeft => tr('top-left corner', 'левый верхний угол'),
  Alignment.topCenter => tr('top middle', 'середина верха'),
  Alignment.topRight => tr('top-right corner', 'правый верхний угол'),
  Alignment.centerLeft => tr('middle of the left edge', 'середина левого края'),
  Alignment.centerRight => tr('middle of the right edge', 'середина правого края'),
  Alignment.bottomLeft => tr('bottom-left corner', 'левый нижний угол'),
  Alignment.bottomCenter => tr('bottom middle', 'середина низа'),
  Alignment.bottomRight => tr('bottom-right corner', 'правый нижний угол'),
  _ => tr('center', 'центр'),
};

/// The pivot point in pixels relative to the widget's top-left corner —
/// this is exactly the form matrix4_transform expects.
Offset _originOffset(Alignment a, Size size) =>
    Offset((a.x + 1) / 2 * size.width, (a.y + 1) / 2 * size.height);

/// A set of transformation parameters (current state or a preset).
class _Pose {
  const _Pose({
    this.rotation = 0,
    this.scale = 1,
    this.tx = 0,
    this.ty = 0,
    this.skew = 0,
    this.origin = Alignment.center,
    this.flipH = false,
    this.flipV = false,
  });

  final double rotation;
  final double scale;
  final double tx;
  final double ty;
  final double skew;
  final Alignment origin;
  final bool flipH;
  final bool flipV;

  _Pose copyWith({
    double? rotation,
    double? scale,
    double? tx,
    double? ty,
    double? skew,
    Alignment? origin,
    bool? flipH,
    bool? flipV,
  }) =>
      _Pose(
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
        tx: tx ?? this.tx,
        ty: ty ?? this.ty,
        skew: skew ?? this.skew,
        origin: origin ?? this.origin,
        flipH: flipH ?? this.flipH,
        flipV: flipV ?? this.flipV,
      );

  /// The matrix4_transform chain (skew is not included — the package has none).
  Matrix4 matrix(Size size) {
    final o = _originOffset(origin, size);
    var t = Matrix4Transform().translate(x: tx, y: ty).rotateDegrees(rotation, origin: o);
    if (scale != 1) t = t.scale(scale, origin: o);
    if (flipH) t = t.flipHorizontally(origin: o);
    if (flipV) t = t.flipVertically(origin: o);
    return t.matrix4;
  }

  /// The pose "spec": package chain steps + resulting matrix for CSS/Figma.
  Map<String, Object?> spec(Size size) {
    final o = _originOffset(origin, size);
    final m = matrix(size).storage;
    String f(double v) => round2(v, 4).toString();
    return {
      'rotateDegrees': rotation.round(),
      'scale': round2(scale),
      'translate_px': {'x': tx.round(), 'y': ty.round()},
      'flipHorizontally': flipH,
      'flipVertically': flipV,
      'origin': alignmentName(origin),
      'origin_px': {'x': round2(o.dx, 1), 'y': round2(o.dy, 1)},
      'skewX_deg': skew.round(),
      'chain': [
        if (tx != 0 || ty != 0) 'translate(x: ${tx.round()}, y: ${ty.round()})',
        if (rotation != 0) 'rotateDegrees(${rotation.round()}, origin: origin_px)',
        if (scale != 1) 'scale(${round2(scale)}, origin: origin_px)',
        if (flipH) 'flipHorizontally(origin: origin_px)',
        if (flipV) 'flipVertically(origin: origin_px)',
      ],
      'css_transform_origin': '0 0',
      'css_matrix': 'matrix(${f(m[0])}, ${f(m[1])}, ${f(m[4])}, ${f(m[5])}, ${f(m[12])}, ${f(m[13])})',
      if (skew != 0)
        'css_skew_extra': tr(
          'skewX(${skew.round()}deg) with transform-origin = origin',
          'skewX(${skew.round()}deg) с transform-origin = origin',
        ),
    };
  }

  String code(Size size, int durationMs, String curve) {
    final o = _originOffset(origin, size);
    String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    final steps = <String>[
      if (tx != 0 || ty != 0) '.translate(x: ${n(tx)}, y: ${n(ty)})',
      if (rotation != 0) '.rotateDegrees(${n(rotation)}, origin: o)',
      if (scale != 1) '.scale(${n(scale)}, origin: o)',
      if (flipH) '.flipHorizontally(origin: o)',
      if (flipV) '.flipVertically(origin: o)',
    ];
    final buf = StringBuffer()
      ..writeln('// o = Offset(${n(o.dx)}, ${n(o.dy)}) — ${_originLabel(origin)}')
      ..writeln('AnimatedContainer(')
      ..writeln('  duration: Duration(milliseconds: $durationMs),')
      ..writeln('  curve: ${curveCode(curve)},')
      ..writeln('  transform: Matrix4Transform()');
    for (final s in steps) {
      buf.writeln('      $s');
    }
    buf.write('      .matrix4,\n)');
    if (skew != 0) {
      final note = tr(
        'no skew in the package — do it separately:',
        'скоса в пакете нет — отдельно:',
      );
      final radiansNote = tr('in radians', 'в радианах');
      buf.write(
        '\n// $note\n'
        '// Transform(transform: Matrix4.skewX(${n(skew)}° $radiansNote))',
      );
    }
    return buf.toString();
  }
}

const _presets = <String, _Pose>{
  'tilt': _Pose(rotation: -6, scale: 1.08, ty: -14),
  'flyAway': _Pose(rotation: 35, scale: 0.35, tx: 150, ty: -100),
  'flip': _Pose(flipH: true),
  'cornerSwing': _Pose(rotation: 18, origin: Alignment.topLeft),
  'skew': _Pose(skew: 20, scale: 1.05),
  'reset': _Pose(),
};

/// Display name for a preset id.
String _presetLabel(String id) => switch (id) {
  'tilt' => tr('Card tilt', 'Наклон карточки'),
  'flyAway' => tr('Fly away', 'Отлёт'),
  'flip' => tr('Flip', 'Переворот'),
  'cornerSwing' => tr('Swing from corner', 'Качели от угла'),
  'skew' => tr('Skew', 'Скос'),
  _ => tr('Reset', 'Сброс'),
};

/// Auto-play order: preset → reset → next preset…
const _autoSequence = [
  'tilt',
  'reset',
  'flyAway',
  'reset',
  'flip',
  'reset',
  'cornerSwing',
  'reset',
  'skew',
  'reset',
];

class _PlaygroundBlock extends StatefulWidget {
  const _PlaygroundBlock();

  @override
  State<_PlaygroundBlock> createState() => _PlaygroundBlockState();
}

class _PlaygroundBlockState extends State<_PlaygroundBlock> {
  _Pose _pose = const _Pose();
  int _durationMs = 700;
  String _curve = 'easeInOutCubic';
  bool _perspective = true;
  bool _auto = true;
  int _autoStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // First preset — after the first frame, so the transition is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAuto() {
    _timer?.cancel();
    if (!_auto || !mounted) return;
    _tick();
    _timer = Timer.periodic(Duration(milliseconds: _durationMs + 900), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _pose = _presets[_autoSequence[_autoStep % _autoSequence.length]]!;
      _autoStep++;
    });
  }

  /// Manual change — turns off auto-play.
  void _manual(_Pose pose) {
    _timer?.cancel();
    setState(() {
      _auto = false;
      _pose = pose;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final curve = resolveCurve(_curve);
    final duration = Duration(milliseconds: _durationMs);

    final card = AnimatedContainer(
      width: _cardSize.width,
      height: _cardSize.height,
      duration: duration,
      curve: curve,
      transform: _pose.matrix(_cardSize),
      // Skew — a separate animation around the same pivot point.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _pose.skew),
        duration: duration,
        curve: curve,
        builder: (context, skew, child) => Transform(
          alignment: _pose.origin,
          transform: Matrix4.skewX(skew * math.pi / 180),
          child: child,
        ),
        child: const _DemoCard(),
      ),
    );

    final preview = Center(
      child: SizedBox.fromSize(
        size: _cardSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // "Ghost" of the original position.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black26),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                // A light perspective so the flip looks three-dimensional.
                transform: Matrix4.identity()..setEntry(3, 2, _perspective ? 0.002 : 0),
                child: card,
              ),
            ),
            // Pivot point (origin).
            Positioned(
              left: _originOffset(_pose.origin, _cardSize).dx - 6,
              top: _originOffset(_pose.origin, _cardSize).dy - 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return _TallBlock(
      title: tr('Transform playground', 'Плейграунд трансформаций'),
      spec: () => {
        'package': packageSpec('matrix4_transform'),
        'widget': 'AnimatedContainer(transform: Matrix4Transform()….matrix4)',
        ...timingSpec(durationMs: _durationMs, curve: _curve),
        'curve_dart': curveCode(_curve),
        'element_size_px': {'width': _cardSize.width.round(), 'height': _cardSize.height.round()},
        'from': tr('identity (starting position)', 'identity (исходное положение)'),
        'to': _pose.spec(_cardSize),
        'perspective': _perspective ? {'setEntry_3_2': 0.002, 'css_perspective_px': 500} : tr('none', 'нет'),
      },
      description: tr(
        'The gray frame is the starting position, the orange dot is the pivot '
            'point (origin): rotation goes around it, scale grows from it, and the '
            'flip axis passes through it. AnimatedContainer interpolates the whole '
            'matrix, so a full 360° turn can\'t be done this way — that needs a '
            'separate RotationTransition.',
        'Серая рамка — исходное положение, оранжевая точка — точка опоры '
            '(origin): вокруг неё идёт поворот, от неё растёт масштаб и '
            'проходит ось отражения. AnimatedContainer интерполирует матрицу '
            'целиком, поэтому полный оборот на 360° так не сделать — для него '
            'нужен RotationTransition.',
      ),
      previewHeight: 300,
      preview: preview,
      belowPreview: _CodeBox(_pose.code(_cardSize, _durationMs, _curve)),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Presets', 'Пресеты'), style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: name, value: pose) in _presets.entries)
                ActionChip(
                  avatar: Icon(name == 'reset' ? Icons.restart_alt : Icons.play_arrow, size: 18),
                  label: Text(_presetLabel(name)),
                  onPressed: () => _manual(pose),
                ),
              FilterChip(
                label: Text(tr('Auto-play', 'Автопоказ')),
                selected: _auto,
                onSelected: (v) {
                  setState(() => _auto = v);
                  _startAuto();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('rotateDegrees — rotation', 'rotateDegrees — поворот'),
            value: _pose.rotation,
            min: -180,
            max: 180,
            unit: '°',
            onChanged: (v) => _manual(_pose.copyWith(rotation: v.roundToDouble())),
          ),
          LabeledSlider(
            label: tr('scale — scale', 'scale — масштаб'),
            value: _pose.scale,
            min: 0.2,
            max: 2,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => _manual(_pose.copyWith(scale: v)),
          ),
          LabeledSlider(
            label: tr('translate x — right/left', 'translate x — вправо/влево'),
            value: _pose.tx,
            min: -160,
            max: 160,
            unit: 'px',
            onChanged: (v) => _manual(_pose.copyWith(tx: v.roundToDouble())),
          ),
          LabeledSlider(
            label: tr('translate y — down/up', 'translate y — вниз/вверх'),
            value: _pose.ty,
            min: -110,
            max: 110,
            unit: 'px',
            onChanged: (v) => _manual(_pose.copyWith(ty: v.roundToDouble())),
          ),
          LabeledSlider(
            label: tr('skewX — skew (outside the package)', 'skewX — скос (вне пакета)'),
            value: _pose.skew,
            min: -40,
            max: 40,
            unit: '°',
            onChanged: (v) => _manual(_pose.copyWith(skew: v.roundToDouble())),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Pivot point (origin)', 'Точка опоры (origin)'), style: textTheme.titleSmall),
                  const SizedBox(height: 6),
                  _OriginPicker(
                    value: _pose.origin,
                    onChanged: (a) => _manual(_pose.copyWith(origin: a)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Flips', 'Отражения'), style: textTheme.titleSmall),
                  const SizedBox(height: 6),
                  FilterChip(
                    label: const Text('flipHorizontally'),
                    selected: _pose.flipH,
                    onSelected: (v) => _manual(_pose.copyWith(flipH: v)),
                  ),
                  const SizedBox(height: 6),
                  FilterChip(
                    label: const Text('flipVertically'),
                    selected: _pose.flipV,
                    onSelected: (v) => _manual(_pose.copyWith(flipV: v)),
                  ),
                  const SizedBox(height: 6),
                  FilterChip(
                    label: Text(tr('Perspective', 'Перспектива')),
                    selected: _perspective,
                    onSelected: (v) => setState(() => _perspective = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 150,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) {
              setState(() => _durationMs = v.round());
              if (_auto) _startAuto();
            },
          ),
          CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
        ],
      ),
    );
  }
}

class _OriginPicker extends StatelessWidget {
  const _OriginPicker({required this.value, required this.onChanged});

  final Alignment value;
  final ValueChanged<Alignment> onChanged;

  @override
  Widget build(BuildContext context) {
    final alignments = _originPoints;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 3; row++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var col = 0; col < 3; col++)
                  _originDot(alignments[row * 3 + col]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _originDot(Alignment a) {
    final selected = a == value;
    return Tooltip(
      message: _originLabel(a),
      child: InkWell(
        onTap: () => onChanged(a),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 16 : 10,
              height: selected ? 16 : 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.orange : Colors.black26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card, color: Colors.white),
          Spacer(),
          Text(
            '•••• 4242',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Directions

enum _Move { upLeft, up, upRight, left, center, right, downLeft, down, downRight }

const _moveIcons = {
  _Move.upLeft: Icons.north_west,
  _Move.up: Icons.north,
  _Move.upRight: Icons.north_east,
  _Move.left: Icons.west,
  _Move.center: Icons.adjust,
  _Move.right: Icons.east,
  _Move.downLeft: Icons.south_west,
  _Move.down: Icons.south,
  _Move.downRight: Icons.south_east,
};

class _DirectionsBlock extends StatefulWidget {
  const _DirectionsBlock();

  @override
  State<_DirectionsBlock> createState() => _DirectionsBlockState();
}

class _DirectionsBlockState extends State<_DirectionsBlock> {
  double _distance = 70;
  double _angle = 30;
  int _durationMs = 500;
  String _curve = 'easeOutBack';
  bool _auto = true;
  int _step = 0;
  Timer? _timer;

  /// Current move: either a direction button or "at an angle".
  _Move? _move = _Move.center;
  bool _byAngle = false;

  static const _autoMoves = [
    _Move.up,
    _Move.center,
    _Move.right,
    _Move.center,
    _Move.downLeft,
    _Move.center,
    _Move.upRight,
    _Move.center,
  ];

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAuto() {
    _timer?.cancel();
    if (!_auto) return;
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        _byAngle = false;
        _move = _autoMoves[_step++ % _autoMoves.length];
      });
    });
  }

  void _manual(VoidCallback change) {
    _timer?.cancel();
    setState(() {
      _auto = false;
      change();
    });
  }

  Matrix4Transform get _transform {
    final t = Matrix4Transform();
    final d = _distance;
    if (_byAngle) return t.directionDegrees(_angle, d);
    return switch (_move) {
      _Move.up => t.up(d),
      _Move.down => t.down(d),
      _Move.left => t.left(d),
      _Move.right => t.right(d),
      _Move.upLeft => t.upLeft(d),
      _Move.upRight => t.upRight(d),
      _Move.downLeft => t.downLeft(d),
      _Move.downRight => t.downRight(d),
      _ => t,
    };
  }

  String get _code {
    final d = _distance.round();
    if (_byAngle) return 'Matrix4Transform().directionDegrees(${_angle.round()}, $d).matrix4';
    if (_move == null || _move == _Move.center) {
      final note = tr('starting point', 'исходная точка');
      return 'Matrix4Transform().matrix4 // $note';
    }
    return 'Matrix4Transform().${_move!.name}($d).matrix4';
  }

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: tr('Directions: up / down / left / right / diagonals', 'Направления: up / down / left / right / диагонали'),
      spec: () {
        final m = _transform.matrix4.storage;
        return {
          'package': packageSpec('matrix4_transform'),
          'widget': 'AnimatedContainer(transform: Matrix4Transform()….matrix4)',
          ...timingSpec(durationMs: _durationMs, curve: _curve),
          'curve_dart': curveCode(_curve),
          'method': _byAngle ? 'directionDegrees' : (_move?.name ?? 'center'),
          if (_byAngle) 'directionDegrees_deg': _angle.round(),
          'distance_px': _distance.round(),
          'angle_note': tr('directionDegrees: 0° — up, clockwise', 'directionDegrees: 0° — вверх, по часовой'),
          'result_translate_px': {'x': round2(m[12], 1), 'y': round2(m[13], 1)},
          'element': {'diameter_px': 44, 'color': hexColor(kAccent)},
        };
      },
      description: tr(
        'A shift in words, not coordinates: .up(70), .downLeft(70) — a diagonal '
            'at the exact distance you need, .directionDegrees(30, 70) — at any '
            'angle (0° — up, clockwise). Handy for toast "flyouts", tooltips and particles.',
        'Сдвиг словами, а не координатами: .up(70), .downLeft(70) — '
            'диагональ сразу на нужную дистанцию, .directionDegrees(30, 70) — '
            'под любым углом (0° — вверх, по часовой). Удобно для «вылетов» '
            'тостов, всплывающих подсказок и частиц.',
      ),
      preview: Stack(
        alignment: Alignment.center,
        children: [
          // Target grid, so the distance is visible.
          Container(
            width: _distance * 2 + 44,
            height: _distance * 2 + 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: _durationMs),
            curve: resolveCurve(_curve),
            transform: _transform.matrix4,
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kAccent,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MovePad(
                selected: _byAngle ? null : _move,
                onMove: (m) => _manual(() {
                  _byAngle = false;
                  _move = m;
                }),
              ),
              FilterChip(
                label: Text(tr('Auto-play', 'Автопоказ')),
                selected: _auto,
                onSelected: (v) {
                  setState(() => _auto = v);
                  _startAuto();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Distance', 'Дистанция'),
            value: _distance,
            min: 20,
            max: 85,
            unit: 'px',
            onChanged: (v) => setState(() => _distance = v.roundToDouble()),
          ),
          LabeledSlider(
            label: tr('directionDegrees — angle', 'directionDegrees — угол'),
            value: _angle,
            min: 0,
            max: 359,
            unit: '°',
            onChanged: (v) => _manual(() {
              _byAngle = true;
              _angle = v.roundToDouble();
            }),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: _durationMs.toDouble(),
            min: 150,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _durationMs = v.round()),
          ),
          CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
          const SizedBox(height: 8),
          _CodeBox(_code),
        ],
      ),
    );
  }
}

class _MovePad extends StatelessWidget {
  const _MovePad({required this.selected, required this.onMove});

  final _Move? selected;
  final ValueChanged<_Move> onMove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < 3; col++)
                Builder(builder: (context) {
                  final m = _Move.values[row * 3 + col];
                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: IconButton.filledTonal(
                      tooltip: m == _Move.center ? tr('To starting point', 'В исходную точку') : m.name,
                      isSelected: m == selected,
                      selectedIcon: Icon(_moveIcons[m], color: colors.onPrimary),
                      style: m == selected
                          ? IconButton.styleFrom(backgroundColor: colors.primary)
                          : null,
                      onPressed: () => onMove(m),
                      icon: Icon(_moveIcons[m]),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── Hover cards

class _HoverPreset {
  const _HoverPreset(this.title, this.caption, this.code, this.build);

  final String title;
  final String caption;
  final String code;
  final Matrix4Transform Function(Size size) build;
}

List<_HoverPreset> get _hoverPresets => [
  _HoverPreset(
    tr('Lift', 'Подъём'),
    tr(
      'The card lifts and grows a bit — a classic for a product catalog.',
      'Карточка приподнимается и чуть растёт — классика для каталога товаров.',
    ),
    '.up(10).scale(1.05, origin: center)',
    (s) => Matrix4Transform().up(10).scale(1.05, origin: s.center(Offset.zero)),
  ),
  _HoverPreset(
    tr('Tilt', 'Наклон'),
    tr(
      'A slight rotation and lift — a "lively" card for promos and pricing plans.',
      'Лёгкий поворот и подъём — «живая» карточка для промо и тарифов.',
    ),
    '.rotateDegrees(-4, origin: center).up(6)',
    (s) => Matrix4Transform().rotateDegrees(-4, origin: s.center(Offset.zero)).up(6),
  ),
  _HoverPreset(
    tr('Rotate from a corner', 'Поворот от угла'),
    tr(
      'The card tilts, anchored at the bottom-left corner — like a sticker.',
      'Карточка отклоняется, закреплённая в левом нижнем углу, — как стикер.',
    ),
    '.rotateDegrees(6, origin: bottomLeft)',
    (s) => Matrix4Transform().rotateDegrees(6, origin: s.bottomLeft(Offset.zero)),
  ),
  _HoverPreset(
    tr('Slide away sideways', 'Уезд вбок'),
    tr(
      'A shift to the right with a squeeze — a "swipe me" hint for swipe actions.',
      'Сдвиг вправо со сжатием — намёк «смахни меня» для свайп-действий.',
    ),
    '.right(24).scaleVertically(0.92, origin: center)',
    (s) => Matrix4Transform().right(24).scaleVertically(0.92, origin: s.center(Offset.zero)),
  ),
];

class _HoverCardsBlock extends StatefulWidget {
  const _HoverCardsBlock();

  @override
  State<_HoverCardsBlock> createState() => _HoverCardsBlockState();
}

class _HoverCardsBlockState extends State<_HoverCardsBlock> {
  bool _auto = true;
  bool _autoPhase = false;
  int _durationMs = 250;
  String _curve = 'easeOutCubic';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAuto() {
    _timer?.cancel();
    _autoPhase = false;
    if (!_auto) return;
    _timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (mounted) setState(() => _autoPhase = !_autoPhase);
    });
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
            Row(
              children: [
                Expanded(child: Text(tr('Hover cards for the web', 'Hover-карточки для веба'), style: textTheme.titleMedium)),
                SpecButton(
                  title: tr('Hover cards', 'Hover-карточки'),
                  spec: () => {
                    'package': packageSpec('matrix4_transform'),
                    'widget': 'MouseRegion + AnimatedContainer(transform: …)',
                    ...timingSpec(durationMs: _durationMs, curve: _curve),
                    'curve_dart': curveCode(_curve),
                    'card_size_px': {'width': 150, 'height': 90},
                    'border_radius_px': 14,
                    'rest': {
                      'transform': 'identity',
                      'border': {'width_px': 1.5, 'color': hexColor(Colors.black12)},
                      'shadow': {'opacity': 0.08, 'blur_px': 4, 'offset_y_px': 2},
                    },
                    'hover': {
                      'border': {'width_px': 1.5, 'color': hexColor(kAccent)},
                      'shadow': {'opacity': 0.22, 'blur_px': 16, 'offset_y_px': 8},
                    },
                    'presets': [
                      for (final p in _hoverPresets)
                        {'preset': p.title, 'Matrix4Transform': p.code},
                    ],
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'A reaction to the cursor hovering: one line of transformation + '
                    'AnimatedContainer. Hover your mouse or tap a card. Auto-play '
                    '"hovers" over all of them in turn.',
                'Реакция на наведение курсора: одна строка трансформации + '
                    'AnimatedContainer. Наведи мышь или тапни по карточке. '
                    'Автопоказ по очереди «наводит» на все сразу.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 230,
              children: [
                for (final p in _hoverPresets)
                  ShowcaseTile(
                    title: p.title,
                    caption: '${p.caption}\n${p.code}',
                    previewHeight: 140,
                    child: _HoverCard(
                      preset: p,
                      forced: _auto && _autoPhase,
                      duration: Duration(milliseconds: _durationMs),
                      curve: resolveCurve(_curve),
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
                  label: Text(tr('Auto-play', 'Автопоказ')),
                  selected: _auto,
                  onSelected: (v) {
                    setState(() => _auto = v);
                    _startAuto();
                  },
                ),
                SizedBox(
                  width: 260,
                  child: LabeledSlider(
                    label: tr('Duration', 'Длительность'),
                    value: _durationMs.toDouble(),
                    min: 100,
                    max: 1000,
                    unit: tr('ms', 'мс'),
                    onChanged: (v) => setState(() => _durationMs = v.round()),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: CurveDropdown(
                    value: _curve,
                    onChanged: (v) => setState(() => _curve = v),
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

class _HoverCard extends StatefulWidget {
  const _HoverCard({
    required this.preset,
    required this.forced,
    required this.duration,
    required this.curve,
  });

  final _HoverPreset preset;
  final bool forced;
  final Duration duration;
  final Curve curve;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  static const _size = Size(150, 90);
  bool _hovered = false;
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _tapped || widget.forced;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _tapped = !_tapped),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          width: _size.width,
          height: _size.height,
          transform: active ? widget.preset.build(_size).matrix4 : Matrix4.identity(),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? kAccent : Colors.black12, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.22 : 0.08),
                blurRadius: active ? 16 : 4,
                offset: Offset(0, active ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_offer, color: kAccent),
              const Spacer(),
              Text(
                widget.preset.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Shared widgets

/// A block with a tall preview: preview and code below it on the left,
/// settings on the right; stacked on a narrow screen.
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

/// A monospace code block.
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

const _originByName = <String, Alignment>{
  'topLeft': Alignment.topLeft,
  'topCenter': Alignment.topCenter,
  'topRight': Alignment.topRight,
  'centerLeft': Alignment.centerLeft,
  'center': Alignment.center,
  'centerRight': Alignment.centerRight,
  'bottomLeft': Alignment.bottomLeft,
  'bottomCenter': Alignment.bottomCenter,
  'bottomRight': Alignment.bottomRight,
};

/// "Before" (gray frame) → "after": a Matrix4Transform chain built from the
/// entered values, progress along the path — the curve applied to t (there and back).
Widget _matrixPlayground(BuildContext context, BriefValues v, double t) {
  const size = Size(120, 76);
  final e = v.curve('curve').transform(t);
  final origin = _originByName[v.text('origin')] ?? Alignment.center;
  final o = _originOffset(origin, size);
  final matrix = Matrix4Transform()
      .translate(x: v.number('translate_x') * e, y: v.number('translate_y') * e)
      .rotateDegrees(v.number('rotateDegrees') * e, origin: o)
      .scale(1 + (v.number('scale') - 1) * e, origin: o)
      .matrix4;
  return SizedBox.fromSize(
    size: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
        Positioned.fill(child: Transform(transform: matrix, child: const _DemoCard())),
        Positioned(
          left: o.dx - 5,
          top: o.dy - 5,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    ),
  );
}
