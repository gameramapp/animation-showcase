// Generative avatars in the boring-avatars spirit — our own CustomPainter implementation:
//   • A string (name) deterministically hashes into shape parameters;
//   • 5 styles: marble (blurred blobs), beam (a face), bauhaus (shapes),
//     rings (rings), pixel (pixels) + a palette of 5 colors;
//   • When the name or palette changes, the shapes and colors smoothly morph
//     (lerp of parameters via TweenAnimationBuilder); style changes crossfade.
//
// The boring_avatars package requires Dart 3.11+, and we're on Dart 3.9 — so
// this is a port of the same idea. Once Flutter is updated, it can be
// replaced with the package.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class GenerativeAvatarsDemo extends StatefulWidget {
  const GenerativeAvatarsDemo({super.key});
  static const String routeName = 'packages/generative_avatars';

  @override
  State<GenerativeAvatarsDemo> createState() => _GenerativeAvatarsDemoState();
}

// ──────────────────────────────────────────────────────────── demo data

enum AvatarStyle { marble, beam, bauhaus, rings, pixel }

Map<AvatarStyle, String> get _styleCaptions => <AvatarStyle, String>{
  AvatarStyle.marble: tr('blurred blobs', 'размытые пятна'),
  AvatarStyle.beam: tr('a face', 'рожица'),
  AvatarStyle.bauhaus: tr('shapes', 'фигуры'),
  AvatarStyle.rings: tr('rings', 'кольца'),
  AvatarStyle.pixel: tr('pixels', 'пиксели'),
};

Map<String, List<Color>> get _palettes => <String, List<Color>>{
  tr('Classic', 'Классика'): [
    Color(0xFF92A1C6),
    Color(0xFF146A7C),
    Color(0xFFF0AB3D),
    Color(0xFFC271B4),
    Color(0xFFC20D90),
  ],
  tr('Neon', 'Неон'): [
    Color(0xFF0A0310),
    Color(0xFF49007E),
    Color(0xFFFF005B),
    Color(0xFFFF7D10),
    Color(0xFFFFB238),
  ],
  tr('Earth', 'Земля'): [
    Color(0xFF264653),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFFF4A261),
    Color(0xFFE76F51),
  ],
  tr('Pastel', 'Пастель'): [
    Color(0xFFFFADAD),
    Color(0xFFFFD6A5),
    Color(0xFFFDFFB6),
    Color(0xFFCAFFBF),
    Color(0xFF9BF6FF),
  ],
  tr('Branded', 'Фирменный'): [
    Color(0xFF673AB7),
    Color(0xFFB388FF),
    Color(0xFF311B92),
    Color(0xFFFFC107),
    Color(0xFFF3E5F5),
  ],
};

List<String> get _names => [
  tr('Maria Ivanova', 'Мария Иванова'),
  tr('Alexey', 'Алексей'),
  'Grace Hopper',
  tr('Designer', 'Дизайнер'),
  tr('Anna Smirnova', 'Анна Смирнова'),
  'Ada Lovelace',
  tr('Ivan Petrov', 'Иван Петров'),
  tr('Katya', 'Катя'),
  tr('Nikita', 'Никита'),
  'Margaret Hamilton',
  tr('Sergey', 'Сергей'),
  tr('Liza', 'Лиза'),
  tr('Dmitry', 'Дмитрий'),
  'Frida Kahlo',
  tr('Timur', 'Тимур'),
  tr('Vera', 'Вера'),
  tr('Roman', 'Роман'),
  tr('Yulia', 'Юля'),
];

class _GenerativeAvatarsDemoState extends State<GenerativeAvatarsDemo> {
  final _nameCtrl = TextEditingController(text: _names.first);
  bool _userTyped = false;
  int _nameIndex = 0;
  AvatarStyle _style = AvatarStyle.marble;
  // Palette is remembered by index: its name is translated, so a stored name
  // would stop matching after a language switch.
  int _paletteIndex = 0;
  String get _palette => _palettes.keys.elementAt(_paletteIndex);
  int _shift = 0;
  bool _square = false;
  bool _autoShift = true;
  double _durationMs = 700;
  String _curve = 'easeInOutCubic';
  Timer? _nameTimer;
  Timer? _shiftTimer;

  @override
  void initState() {
    super.initState();
    // Until the user starts typing — names change on their own.
    _nameTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || _userTyped) return;
      setState(() {
        _nameIndex = (_nameIndex + 1) % _names.length;
        _nameCtrl.text = _names[_nameIndex];
      });
    });
    _shiftTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted || !_autoShift) return;
      setState(() => _shift++);
    });
  }

  // Called on a language switch too (see i18n.dart): re-translate the
  // auto-cycled sample name unless the user typed their own.
  @override
  void reassemble() {
    super.reassemble();
    if (!_userTyped) _nameCtrl.text = _names[_nameIndex];
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _shiftTimer?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Palette accounting for the "shift" — colors rotate around in a circle.
  List<Color> get _colors {
    final p = _palettes[_palette]!;
    final s = _shift % p.length;
    return [...p.sublist(s), ...p.sublist(0, s)];
  }

  Duration get _duration => Duration(milliseconds: _durationMs.round());
  Curve get _curveValue => resolveCurve(_curve);

  String get _name => _nameCtrl.text.isEmpty ? ' ' : _nameCtrl.text;

  String get _sampleName => tr('Alice', 'Мария');

  /// Shared avatar "Spec" (our own implementation, analogous to boring_avatars).
  Map<String, Object?> _spec({required double size, AvatarStyle? style}) => {
    'package': tr(
      'none — our own implementation (an analog of boring_avatars, needs Dart 3.11+)',
      'нет — своя реализация (аналог boring_avatars, нужен Dart 3.11+)',
    ),
    'widget': 'GenerativeAvatar',
    'style': (style ?? _style).name,
    'palette': _palette,
    'colors': [for (final c in _colors) hexColor(c)],
    'palette_shift': _shift % 5,
    'size_px': size.round(),
    'shape': _square ? 'square' : 'circle',
    if (_square) 'corner_radius_percent': 12,
    'morph': {
      ...timingSpec(durationMs: _durationMs.round(), curve: _curve),
      'curve_dart': curveCode(_curve),
      'style_change': tr('crossfade + scale 0.85 → 1', 'кроссфейд + масштаб 0.85 → 1'),
    },
  };

  Widget _avatar(String name, double size, {AvatarStyle? style}) => GenerativeAvatar(
    name: name,
    style: style ?? _style,
    colors: _colors,
    size: size,
    square: _square,
    duration: _duration,
    curve: _curveValue,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Generative Avatars'), actions: const [LangButton()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Avatars from a name', 'Аватары из имени'),
            text: tr(
              'A generative avatar is drawn from a string: the same name '
                  'always gives the same picture, different names give '
                  'different ones. Handy for empty profiles, comments, teams '
                  'and chats: instead of a gray silhouette — a bright '
                  'recognizable "mark" in brand colors. The idea is like '
                  'boringavatars.com. The boring_avatars package needs a newer '
                  'Flutter; this is our own implementation of the same idea, '
                  'and can be swapped for the package once Flutter is updated.',
              'Генеративный аватар рисуется из строки: одно и то же имя всегда '
                  'даёт одну и ту же картинку, разные имена — разные. Удобно для '
                  'пустых профилей, комментариев, команд и чатов: вместо серого '
                  'силуэта — яркая узнаваемая «метка» в цветах бренда. Идея — как в '
                  'boringavatars.com. Пакет boring_avatars требует более новый '
                  'Flutter; здесь — наша реализация той же идеи, после обновления '
                  'Flutter можно заменить на пакет.',
            ),
            hint: tr(
              'Names change on their own until you start typing your own. '
                  'Change the palette or style — the shapes will smoothly morph.',
              'Имена меняются сами, пока ты не начнёшь печатать своё. Смени '
                  'палитру или стиль — фигуры плавно перетекут.',
            ),
          ),
          const SizedBox(height: 16),
          AnimBlock(
            title: tr('Avatar from a name', 'Аватар из имени'),
            spec: () => {..._spec(size: 150), 'name': _name, 'name_hash': _hashCode(_name)},
            description: tr(
              'Name → hash → position, rotation and shape color. When the '
                  'name or palette changes, the parameters don\'t jump — they '
                  'smoothly interpolate (lerp), producing a "morph" from one '
                  'avatar into another.',
              'Имя → хэш → положение, поворот и цвет фигур. При смене имени '
                  'или палитры параметры не прыгают, а плавно интерполируются '
                  '(lerp) — получается «морфинг» одного аватара в другой.',
            ),
            preview: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _avatar(_name, 150),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _name,
                      key: ValueKey(_name),
                      style: textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            controls: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Name or e-mail', 'Имя или e-mail'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _userTyped
                        ? IconButton(
                            tooltip: tr('Back to auto', 'Снова авто'),
                            icon: const Icon(Icons.autorenew),
                            onPressed: () => setState(() => _userTyped = false),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() => _userTyped = true),
                ),
                const SizedBox(height: 12),
                Text(tr('Style', 'Стиль'), style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in AvatarStyle.values)
                      ChoiceChip(
                        label: Text(s.name),
                        selected: _style == s,
                        onSelected: (_) => setState(() => _style = s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(tr('Palette', 'Палитра'), style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in _palettes.keys)
                      ChoiceChip(
                        avatar: _PaletteDots(colors: _palettes[name]!),
                        label: Text(name),
                        selected: _palette == name,
                        onSelected: (_) =>
                            setState(() => _paletteIndex = _palettes.keys.toList().indexOf(name)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(tr('Square', 'Квадрат')),
                      selected: _square,
                      onSelected: (v) => setState(() => _square = v),
                    ),
                    FilterChip(
                      label: Text(tr('Auto-shift palette', 'Авто-сдвиг палитры')),
                      selected: _autoShift,
                      onSelected: (v) => setState(() => _autoShift = v),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.shuffle, size: 18),
                      label: Text(tr('Shift colors', 'Сдвинуть цвета')),
                      onPressed: () => setState(() => _shift++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LabeledSlider(
                  label: tr('Transition duration', 'Длительность перехода'),
                  value: _durationMs,
                  min: 0,
                  max: 2000,
                  unit: tr('ms', 'мс'),
                  onChanged: (v) => setState(() => _durationMs = v),
                ),
                CurveDropdown(value: _curve, onChanged: (v) => setState(() => _curve = v)),
                const SizedBox(height: 8),
                _CodeBox(
                  "GenerativeAvatar(name: '$_sampleName', style: AvatarStyle.marble,\n"
                  '    colors: palette, size: 80)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StylesCard(
            spec: () => {
              ..._spec(size: 88),
              'name': _name,
              'styles': [
                for (final st in AvatarStyle.values) {'style': st.name, 'look': _styleCaptions[st]},
              ],
            },
            builder: (style) => _avatar(_name, 88, style: style),
            selected: _style,
            onSelect: (s) => setState(() => _style = s),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('User list', 'Список пользователей'),
                          style: textTheme.titleMedium,
                        ),
                      ),
                      SpecButton(
                        title: tr('Avatars in a list', 'Аватары в списке'),
                        spec: () => {
                          ..._spec(size: 44),
                          'names': _names,
                          'row_padding_px': 10,
                          'gap_to_text_px': 10,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'This is how avatars look in a feed, chat, or team list: '
                          'everyone has their own, but all in the same palette. '
                          'Shifting the palette recolors all of them at once.',
                      'Так аватары выглядят в ленте, чате или списке команды: у '
                          'каждого — свой, но все в одной палитре. При сдвиге палитры '
                          'перекрашиваются все сразу.',
                    ),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ResponsiveWrap(
                    minTileWidth: 160,
                    children: [
                      for (final name in _names)
                        Card.outlined(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                _avatar(name, 44),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.duration(
                  'duration_ms',
                  tr('Morph: duration', 'Морфинг: длительность'),
                  700,
                ),
                BriefField.curve('curve', tr('Morph: curve', 'Морфинг: кривая'), 'easeInOutCubic'),
                BriefField.text(
                  'name_from',
                  tr('Name "before"', 'Имя «до»'),
                  tr('Maria Ivanova', 'Мария Иванова'),
                ),
                BriefField.text('name_to', tr('Name "after"', 'Имя «после»'), 'Grace Hopper'),
                BriefField.choice('style', tr('Style', 'Стиль'), [
                  'marble',
                  'beam',
                  'bauhaus',
                  'rings',
                  'pixel',
                ], 'marble'),
                BriefField.choice('shape', tr('Shape', 'Форма'), [
                  tr('circle', 'круг'),
                  tr('square', 'квадрат'),
                ], tr('circle', 'круг')),
                BriefField.number('size', tr('Size', 'Размер'), 120, unit: 'px', min: 16, max: 180),
                BriefField.color('c1', tr('Color 1', 'Цвет 1'), '#92A1C6'),
                BriefField.color('c2', tr('Color 2', 'Цвет 2'), '#146A7C'),
                BriefField.color('c3', tr('Color 3', 'Цвет 3'), '#F0AB3D'),
                BriefField.color('c4', tr('Color 4', 'Цвет 4'), '#C271B4'),
                BriefField.color('c5', tr('Color 5', 'Цвет 5'), '#C20D90'),
              ],
              builder: _avatarPlayground,
            ),
            items: [
              (
                tr('Style', 'Стиль'),
                tr(
                  'marble / beam / bauhaus / rings / pixel — one per product or per context',
                  'marble / beam / bauhaus / rings / pixel — один на продукт или по контексту',
                ),
              ),
              (
                tr('Palette', 'Палитра'),
                tr(
                  '5 #hex colors in order; the order matters — it decides which color becomes the background',
                  '5 цветов #hex по порядку; порядок важен — от него зависит, какой цвет будет фоном',
                ),
              ),
              (
                tr('Shape and sizes', 'Форма и размеры'),
                tr(
                  'circle or rounded square (radius in %), sizes in px for a list, profile, chat',
                  'круг или скруглённый квадрат (радиус в %), размеры в px для списка, профиля, чата',
                ),
              ),
              (
                tr('String source', 'Источник строки'),
                tr(
                  'what turns into an avatar: name, e-mail, user id (this determines how stable the picture is)',
                  'что превращается в аватар: имя, e-mail, id пользователя (от этого зависит стабильность картинки)',
                ),
              ),
              (
                tr('Morphing', 'Морфинг'),
                tr(
                  'whether a smooth change is needed on rename / theme change: duration in ms and the curve',
                  'нужна ли плавная смена при переименовании / смене темы: длительность в мс и кривая',
                ),
              ),
              (
                tr('When to show it', 'Когда показывать'),
                tr(
                  'only while there\'s no photo, or always; how it behaves while a photo is loading',
                  'только пока нет фото или всегда; как ведёт себя при загрузке фото',
                ),
              ),
            ],
            avoid: [
              tr(
                'A palette with near-identical colors — the avatars become indistinguishable.',
                'Палитру с почти одинаковыми цветами — аватары станут неразличимыми.',
              ),
              tr(
                'Building the avatar from mutable data (a nickname that changes often) — the picture will "jump".',
                'Строить аватар из изменяемых данных (ник, который часто меняют) — картинка будет «прыгать».',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// All 5 styles for the current name — side by side, for comparison.
class _StylesCard extends StatelessWidget {
  const _StylesCard({
    required this.builder,
    required this.selected,
    required this.onSelect,
    required this.spec,
  });

  final Map<String, Object?> Function() spec;
  final Widget Function(AvatarStyle style) builder;
  final AvatarStyle selected;
  final ValueChanged<AvatarStyle> onSelect;

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
                Expanded(
                  child: Text(
                    tr('All styles for one name', 'Все стили для одного имени'),
                    style: textTheme.titleMedium,
                  ),
                ),
                SpecButton(title: tr('All avatar styles', 'Все стили аватара'), spec: spec),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'One hash — five different "handwritings". Tap to pick a style.',
                'Один хэш — пять разных «почерков». Тапни, чтобы выбрать стиль.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final s in AvatarStyle.values)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelect(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 124,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s == selected ? kAccent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          builder(s),
                          const SizedBox(height: 6),
                          Text(s.name, style: textTheme.titleSmall),
                          Text(
                            _styleCaptions[s]!,
                            style: textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

class _PaletteDots extends StatelessWidget {
  const _PaletteDots({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Stack(
        children: [
          for (var i = 0; i < 4; i++)
            Positioned(
              left: i * 4.0,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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

// ═══════════════════════════════════════════════════════ the avatar itself

/// Generative avatar: name + palette → image. Smoothly morphs when the
/// name/palette changes and crossfades when the style changes.
class GenerativeAvatar extends StatelessWidget {
  const GenerativeAvatar({
    super.key,
    required this.name,
    required this.colors,
    this.style = AvatarStyle.marble,
    this.size = 80,
    this.square = false,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeInOutCubic,
  });

  final String name;
  final List<Color> colors;
  final AvatarStyle style;
  final double size;
  final bool square;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final spec = _AvatarSpec.build(style, _hashCode(name), colors);
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: TweenAnimationBuilder<_AvatarSpec>(
          key: ValueKey(style),
          tween: _SpecTween(begin: spec, end: spec),
          duration: duration,
          curve: curve,
          builder: (context, s, _) =>
              CustomPaint(size: Size.square(size), painter: _AvatarPainter(s, square)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────── "randomness" from a hash, as in boring-avatars

/// 32-bit string hash (like `hashCode` in the JS version) — the same in the web and the VM.
int _hashCode(String name) {
  var hash = 0;
  for (final ch in name.codeUnits) {
    hash = ((hash << 5) - hash + ch).toSigned(32);
  }
  return hash.abs();
}

int _digit(int number, int ntn) => ((number / math.pow(10, ntn)) % 10).floor();

bool _boolean(int number, int ntn) => _digit(number, ntn) % 2 == 0;

double _unit(int number, num range, [int? index]) {
  final value = (number % range).toDouble();
  if (index != null && _digit(number, index) % 2 == 0) return -value;
  return value;
}

Color _color(int number, List<Color> colors) => colors[number % colors.length];

/// Contrasting face color for beam: black on light, white on dark.
Color _contrast(Color c) {
  final yiq = ((c.r * 255) * 299 + (c.g * 255) * 587 + (c.b * 255) * 114) / 1000;
  return yiq >= 128 ? Colors.black : Colors.white;
}

// ───────────────────────────────────────────── avatar parameters + lerp

/// Everything needed to draw the avatar: style, colors, and numeric parameters.
/// Numbers and colors are interpolated — hence the smooth morphing.
@immutable
class _AvatarSpec {
  const _AvatarSpec(this.style, this.colors, this.nums);

  final AvatarStyle style;
  final List<Color> colors;
  final List<double> nums;

  static _AvatarSpec build(AvatarStyle style, int n, List<Color> palette) {
    switch (style) {
      case AvatarStyle.marble:
        // 3 elements: background + 2 blobs. Each: tx, ty, scale, rotate.
        final colors = <Color>[];
        final nums = <double>[];
        for (var i = 0; i < 3; i++) {
          final k = n * (i + 1);
          colors.add(_color(n + i, palette));
          nums.addAll([
            _unit(k, 80 / 10, 1),
            _unit(k, 80 / 10, 2),
            1.2 + _unit(k, 80 / 20) / 10,
            _unit(k, 360, 1),
          ]);
        }
        return _AvatarSpec(style, colors, nums);
      case AvatarStyle.beam:
        const size = 36.0;
        final wrapper = _color(n, palette);
        final preX = _unit(n, 10, 1);
        final wtx = preX < 5 ? preX + size / 9 : preX;
        final preY = _unit(n, 10, 2);
        final wty = preY < 5 ? preY + size / 9 : preY;
        return _AvatarSpec(
          style,
          [
            _color(n + 13, palette), // background
            wrapper,
            _contrast(wrapper), // face
          ],
          [
            wtx,
            wty,
            _unit(n, 360),
            1 + _unit(n, size / 12) / 10,
            _boolean(n, 1) ? 18 : 6, // circle or rounded square
            _boolean(n, 2) ? 1 : 0, // mouth open
            _unit(n, 5), // eye spread
            _unit(n, 3), // mouth position
            _unit(n, 10, 3), // face rotation
            wtx > size / 6 ? wtx / 2 : _unit(n, 8, 1),
            wty > size / 6 ? wty / 2 : _unit(n, 7, 2),
          ],
        );
      case AvatarStyle.bauhaus:
        final colors = <Color>[];
        final nums = <double>[];
        for (var i = 0; i < 4; i++) {
          final k = n * (i + 1);
          colors.add(_color(n + i, palette));
          nums.addAll([
            _unit(k, 80 / 2 - (i + 17), 1),
            _unit(k, 80 / 2 - (i + 17), 2),
            _unit(k, 360),
          ]);
        }
        nums.add(_boolean(n, 2) ? 80 : 10); // rectangle height
        return _AvatarSpec(style, colors, nums);
      case AvatarStyle.rings:
        final c = [for (var i = 0; i < 5; i++) _color(n + i, palette)];
        return _AvatarSpec(style, [c[0], c[1], c[1], c[2], c[2], c[3], c[3], c[0], c[4]], const []);
      case AvatarStyle.pixel:
        return _AvatarSpec(style, [
          for (var i = 0; i < 64; i++) _color(n % (i + 1) + i ~/ 9, palette),
        ], const []);
    }
  }

  static _AvatarSpec lerp(_AvatarSpec a, _AvatarSpec b, double t) {
    if (a.style != b.style ||
        a.colors.length != b.colors.length ||
        a.nums.length != b.nums.length) {
      return t < 0.5 ? a : b;
    }
    return _AvatarSpec(
      b.style,
      [for (var i = 0; i < a.colors.length; i++) Color.lerp(a.colors[i], b.colors[i], t)!],
      [for (var i = 0; i < a.nums.length; i++) ui.lerpDouble(a.nums[i], b.nums[i], t)!],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _AvatarSpec &&
      other.style == style &&
      listEquals(other.colors, colors) &&
      listEquals(other.nums, nums);

  @override
  int get hashCode => Object.hash(style, Object.hashAll(colors), Object.hashAll(nums));
}

class _SpecTween extends Tween<_AvatarSpec> {
  _SpecTween({required super.begin, required super.end});

  @override
  _AvatarSpec lerp(double t) => _AvatarSpec.lerp(begin!, end!, t);
}

// ─────────────────────────────────────────────────────────── rendering

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.spec, this.square);

  final _AvatarSpec spec;
  final bool square;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(square ? size.width * 0.12 : size.width / 2)),
    );
    switch (spec.style) {
      case AvatarStyle.marble:
        _marble(canvas, size);
      case AvatarStyle.beam:
        _beam(canvas, size);
      case AvatarStyle.bauhaus:
        _bauhaus(canvas, size);
      case AvatarStyle.rings:
        _rings(canvas, size);
      case AvatarStyle.pixel:
        _pixel(canvas, size);
    }
    canvas.restore();
  }

  /// Rotation around point (cx, cy) — like `rotate(a cx cy)` in SVG.
  void _rotateAround(Canvas canvas, double degrees, double cx, double cy) {
    canvas.translate(cx, cy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(-cx, -cy);
  }

  static final _marblePath1 = Path()
    ..moveTo(32.414, 59.35)
    ..lineTo(50.376, 70.5)
    ..lineTo(72.5, 70.5)
    ..lineTo(72.5, -0.5)
    ..lineTo(33.728, -0.5)
    ..lineTo(26.5, 13.381)
    ..lineTo(45.557, 40.461)
    ..close();

  static final _marblePath2 = Path()
    ..moveTo(22.216, 24)
    ..lineTo(0, 46.75)
    ..lineTo(14.108, 84.879)
    ..lineTo(78, 86)
    ..lineTo(74.919, 26.724)
    ..lineTo(52.541, 30.729)
    ..lineTo(65.513, 50.915)
    ..lineTo(42.163, 78.31)
    ..close();

  void _marble(Canvas canvas, Size size) {
    final s = size.width / 80;
    final c = spec.colors;
    final n = spec.nums;
    canvas.drawRect(Offset.zero & size, Paint()..color = c[0]);
    canvas.save();
    canvas.scale(s);
    // Blur over the whole layer with the blobs — "marble" veining.
    canvas.saveLayer(
      const Rect.fromLTWH(-40, -40, 160, 160),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
    );
    for (var i = 1; i < 3; i++) {
      final tx = n[i * 4], ty = n[i * 4 + 1], scale = n[i * 4 + 2], rot = n[i * 4 + 3];
      canvas.save();
      canvas.translate(tx, ty);
      _rotateAround(canvas, rot, 40, 40);
      canvas.scale(scale);
      final paint = Paint()..color = c[i];
      if (i == 2) paint.blendMode = BlendMode.overlay;
      canvas.drawPath(i == 1 ? _marblePath1 : _marblePath2, paint);
      canvas.restore();
    }
    canvas.restore();
    canvas.restore();
  }

  void _beam(Canvas canvas, Size size) {
    final s = size.width / 36;
    final c = spec.colors;
    final n = spec.nums;
    canvas.drawRect(Offset.zero & size, Paint()..color = c[0]);
    canvas.save();
    canvas.scale(s);

    // The "head" — a square/circle, shifted and rotated.
    canvas.save();
    canvas.translate(n[0], n[1]);
    _rotateAround(canvas, n[2], 18, 18);
    canvas.scale(n[3]);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 36, 36), Radius.circular(n[4])),
      Paint()..color = c[1],
    );
    canvas.restore();

    // Face: eyes and mouth.
    canvas.save();
    canvas.translate(n[9], n[10]);
    _rotateAround(canvas, n[8], 18, 18);
    final face = Paint()..color = c[2];
    final eye = n[6];
    final mouthY = 19 + n[7];
    final open = n[5];
    if (open > 0.01) {
      final smile = Path()
        ..moveTo(15, mouthY)
        ..cubicTo(17, mouthY + 1, 19, mouthY + 1, 21, mouthY);
      canvas.drawPath(
        smile,
        Paint()
          ..color = c[2].withValues(alpha: c[2].a * open)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
    if (open < 0.99) {
      final mouth = Path()
        ..moveTo(13, mouthY)
        ..arcToPoint(
          Offset(23, mouthY),
          radius: const Radius.elliptical(5, 3.75),
          clockwise: false,
        );
      canvas.drawPath(mouth, Paint()..color = c[2].withValues(alpha: c[2].a * (1 - open)));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(14 - eye, 14, 1.5, 2), const Radius.circular(1)),
      face,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20 + eye, 14, 1.5, 2), const Radius.circular(1)),
      face,
    );
    canvas.restore();
    canvas.restore();
  }

  void _bauhaus(Canvas canvas, Size size) {
    final s = size.width / 80;
    final c = spec.colors;
    final n = spec.nums;
    canvas.drawRect(Offset.zero & size, Paint()..color = c[0]);
    canvas.save();
    canvas.scale(s);
    // Rectangle (or stripe).
    canvas.save();
    canvas.translate(n[3], n[4]);
    _rotateAround(canvas, n[5], 40, 40);
    canvas.drawRect(Rect.fromLTWH(10, 30, 80, n[12]), Paint()..color = c[1]);
    canvas.restore();
    // Circle.
    canvas.save();
    canvas.translate(n[6], n[7]);
    canvas.drawCircle(const Offset(40, 40), 16, Paint()..color = c[2]);
    canvas.restore();
    // Line.
    canvas.save();
    canvas.translate(n[9], n[10]);
    _rotateAround(canvas, n[11], 40, 40);
    canvas.drawLine(
      const Offset(0, 40),
      const Offset(80, 40),
      Paint()
        ..color = c[3]
        ..strokeWidth = 2,
    );
    canvas.restore();
    canvas.restore();
  }

  void _rings(Canvas canvas, Size size) {
    final s = size.width / 90;
    final c = spec.colors;
    canvas.save();
    canvas.scale(s);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 90, 45), Paint()..color = c[0]);
    canvas.drawRect(const Rect.fromLTWH(0, 45, 90, 45), Paint()..color = c[1]);
    const center = Offset(45, 45);
    var i = 2;
    for (final r in [38.0, 32.0, 26.0]) {
      final oval = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(oval, math.pi, math.pi, true, Paint()..color = c[i]); // top half
      canvas.drawArc(oval, 0, math.pi, true, Paint()..color = c[i + 1]); // bottom half
      i += 2;
    }
    canvas.drawCircle(center, 23, Paint()..color = c[8]);
    canvas.restore();
  }

  void _pixel(Canvas canvas, Size size) {
    final cell = size.width / 8;
    for (var i = 0; i < 64; i++) {
      final x = i % 8, y = i ~/ 8;
      // +0.5 — avoids gaps between cells at fractional sizes.
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
        Paint()..color = spec.colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.spec != spec || old.square != square;
}

// ─────────────────────────────────────────────────────────── brief playground

/// Morphs the avatar from the "before" name to the "after" name on the
/// entered palette: shape parameters and colors are interpolated along the
/// curve (there and back).
Widget _avatarPlayground(BuildContext context, BriefValues v, double t) {
  final style = AvatarStyle.values.byName(v.text('style'));
  final palette = [
    for (final k in ['c1', 'c2', 'c3', 'c4', 'c5']) v.color(k),
  ];
  final a = _AvatarSpec.build(style, _hashCode(v.text('name_from')), palette);
  final b = _AvatarSpec.build(style, _hashCode(v.text('name_to')), palette);
  final spec = _AvatarSpec.lerp(a, b, v.curve('curve').transform(t));
  final size = v.number('size');
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _AvatarPainter(spec, v.text('shape') == tr('square', 'квадрат')),
        ),
        const SizedBox(height: 8),
        Text(
          t < 0.5 ? v.text('name_from') : v.text('name_to'),
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
