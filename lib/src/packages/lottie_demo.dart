// Showcase of the `lottie` package — After Effects animations in the app:
//   • How to hand off an animation — the AE → Bodymovin/LottieFiles → JSON → code path;
//   • Gallery — several JSON files playing in a loop;
//   • Player — a custom AnimationController: play/pause, reverse, repeat, ping-pong,
//     frame scrubbing, speed, playing a "from frame — to frame" segment;
//   • Tap — play once: a like animation using AE markers, a checkmark, a toggle;
//   • Dynamic properties — recoloring layers from code by name (keypath).
//
// Files are taken from the package's official example (github.com/xvrh/lottie-flutter),
// sources are in assets/lottie/SOURCES.md. Works in the web (CanvasKit / skwasm).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

const _dir = 'assets/lottie';

/// File details for the "Spec": fps, frames, artboard size, markers.
Map<String, Object?> _compositionSpec(LottieComposition? c) {
  if (c == null) return {'composition': tr('not loaded yet', 'ещё не загружена')};
  return {
    'frame_rate_fps': round2(c.frameRate, 2),
    'start_frame': round2(c.startFrame, 1),
    'end_frame': round2(c.endFrame, 1),
    'total_frames': round2(c.durationFrames, 1),
    'duration_ms': c.duration.inMilliseconds,
    'artboard_size_px': {'width': c.bounds.width, 'height': c.bounds.height},
    'markers': [
      for (final m in c.markers)
        {
          'name': m.name,
          'start_frame': round2(m.startFrame, 1),
          'duration_frames': round2(m.durationFrames, 1),
          'start_progress': round2(m.start, 3),
          'end_progress': round2(m.end, 3),
        },
    ],
  };
}

class LottieDemo extends StatelessWidget {
  const LottieDemo({super.key});
  static const String routeName = 'packages/lottie';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottie'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Lottie — animations from After Effects', 'Lottie — анимации из After Effects'),
            text: tr(
              'Lottie is a JSON file that a designer exports from After Effects '
                  'with the Bodymovin plugin (or LottieFiles). The app draws it as '
                  'vectors, frame by frame — no video or GIF: the file weighs '
                  'kilobytes and is crisp on any screen. The developer doesn\'t need '
                  'to redraw anything: the file goes into the project as-is, and '
                  'code can control playback, speed, segments and even colors. '
                  'Integration difficulty for a ready file: easy.',
              'Lottie — это JSON-файл, который дизайнер экспортирует из After '
                  'Effects плагином Bodymovin (или LottieFiles). Приложение рисует '
                  'его векторно, кадр за кадром — без видео и GIF: файл весит '
                  'килобайты, чёткий на любом экране. Разработчику ничего не нужно '
                  'перерисовывать: файл кладётся в проект как есть, а из кода можно '
                  'управлять воспроизведением, скоростью, отрезками и даже цветами. '
                  'Сложность интеграции готового файла: легко.',
            ),
            hint: tr(
              'Everything below plays on its own; in the player, drag the sliders and tap the tiles.',
              'Всё ниже играет само; в плеере крути ползунки, плитки тапай.',
            ),
          ),
          const SizedBox(height: 16),
          const _HandoffCard(),
          const SizedBox(height: 16),
          const _GalleryBlock(),
          const SizedBox(height: 16),
          const _PlayerBlock(),
          const SizedBox(height: 16),
          const _TapOnceBlock(),
          const SizedBox(height: 16),
          const _DelegatesBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.number('frame_from', tr('Segment: from frame', 'Отрезок: с кадра'), 0, min: 0, max: 10000),
                BriefField.number('frame_to', tr('Segment: to frame', 'Отрезок: по кадр'), 179, min: 0, max: 10000),
                BriefField.number('speed', tr('Speed', 'Скорость'), 1, unit: '×', min: 0.05, max: 10),
                BriefField.choice(
                  'file',
                  tr('File', 'Файл'),
                  ['lottie_logo.json', 'twitter_heart.json', 'gears.json'],
                  'lottie_logo.json',
                ),
                BriefField.choice('loop', tr('Repeat', 'Повтор'), ['loop', 'ping-pong'], 'loop'),
              ],
              builder: _lottiePlayground,
            ),
            items: [
              (
                tr('.json file', 'Файл .json'),
                tr(
                  'Bodymovin or LottieFiles for AE export (.lottie is fine too); not .aep and not video/GIF',
                  'экспорт Bodymovin или LottieFiles for AE (можно .lottie); не .aep и не видео/GIF',
                ),
              ),
              (
                tr('Artboard size and fps', 'Размер артборда и fps'),
                tr(
                  'e.g. 512×512, 30 or 60 fps — they drive the layout and smoothness',
                  'например 512×512, 30 или 60 fps — от них зависят вёрстка и плавность',
                ),
              ),
              (
                tr('Markers for segments', 'Маркеры для кусков'),
                tr(
                  'named markers in AE for each state: like_on, like_off, loop_idle…',
                  'именованные маркеры в AE на каждое состояние: like_on, like_off, loop_idle…',
                ),
              ),
              (
                tr('State segments', 'Отрезки состояний'),
                tr(
                  'which frames / markers play for which event: appearance, waiting loop, success, error',
                  'какие кадры / маркеры играть на какое событие: появление, петля ожидания, успех, ошибка',
                ),
              ),
              (
                tr('Repeat', 'Повтор'),
                tr(
                  'for each segment: once, looping or back-and-forth; speed, if different from 1×',
                  'для каждого куска: один раз, по кругу или туда-обратно; скорость, если отличается от 1×',
                ),
              ),
              (
                tr('Layers to recolor', 'Слои для перекраски'),
                tr(
                  'clear layer names that the code will recolor (keypath), and #hex colors for themes',
                  'понятные имена слоёв, которые код будет перекрашивать (keypath), и цвета #hex для тем',
                ),
              ),
              (
                tr('Check', 'Проверка'),
                tr(
                  'open the file at lottiefiles.com/preview — if it plays correctly there, it will in the app too',
                  'открой файл на lottiefiles.com/preview — если там играет правильно, в приложении будет так же',
                ),
              ),
            ],
            avoid: [
              tr(
                'Expressions and 3D layers — partially supported or don\'t work.',
                'Выражения (expressions) и 3D-слои — поддерживаются частично или не работают.',
              ),
              tr(
                'Effects like Blur / Glow / Drop Shadow — rendered differently or dropped.',
                'Эффекты вроде Blur / Glow / Drop Shadow — рисуются иначе или пропадают.',
              ),
              tr(
                'Embedded raster images — bloat the file; send them separately if needed.',
                'Встроенные растровые картинки — раздувают файл; если нужны, присылай отдельно.',
              ),
              tr(
                'Live text with fonts — convert to shapes (Create Shapes from Text).',
                'Живой текст со шрифтами — переведи в кривые (Create Shapes from Text).',
              ),
            ],
            handoff: tr(
              'send the .json file + a list of markers (name → what state it is) and the '
                  'layers to recolor. Attach the player\'s "Spec" with the segments and speed you need.',
              'пришли .json-файл + список маркеров (имя → что это за состояние) и '
                  'слоёв для перекраски. Приложи «Спеку» плеера с нужными отрезками и скоростью.',
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── How to hand off a file

class _HandoffCard extends StatelessWidget {
  const _HandoffCard();

  static List<(String, String)> get _steps => [
    (
      tr('Animate in After Effects', 'Анимируй в After Effects'),
      tr(
        'Shape layers, masks, trim paths, easing — all vector. Effects, '
            'expressions and 3D are only partially supported: check the list at '
            'airbnb.io/lottie/#/supported-features.',
        'Shape-слои, маски, трим-пасы, easing — всё векторное. Эффекты, '
            'выражения и 3D поддерживаются частично: сверяйся со списком '
            'airbnb.io/lottie/#/supported-features.',
      ),
    ),
    (
      tr('Export to JSON', 'Экспортируй в JSON'),
      tr(
        'The Bodymovin or LottieFiles for After Effects plugin → a .json file '
            '(or a packed .lottie). Better not to use raster images — they bloat the file.',
        'Плагин Bodymovin или LottieFiles for After Effects → файл .json '
            '(или упакованный .lottie). Растровые картинки лучше не использовать '
            '— они раздувают файл.',
      ),
    ),
    (
      tr('Check the preview', 'Проверь превью'),
      tr(
        'Open the file at lottiefiles.com/preview — if it plays correctly there, '
            'it will in the app too.',
        'Открой файл на lottiefiles.com/preview — если там играет правильно, '
            'в приложении будет так же.',
      ),
    ),
    (
      tr('Agree on the "handles"', 'Договорись о «ручках»'),
      tr(
        'Name layers meaningfully (they can be recolored from code) and place '
            'markers (e.g. like_start / like_end) — the developer plays the right '
            'segments off them. Say whether the animation should loop.',
        'Назови слои осмысленно (их можно перекрашивать из кода) и расставь '
            'маркеры (например, like_start / like_end) — по ним разработчик '
            'проигрывает нужные куски. Укажи, должна ли анимация зацикливаться.',
      ),
    ),
    (
      tr('The developer wires it up', 'Разработчик подключает'),
      tr(
        'The file goes into assets/, in code — Lottie.asset(\'…json\'). Then: a '
            'controller for play/pause/speed, segments by frame or marker, '
            'ValueDelegate for colors and text.',
        'Файл в assets/, в коде — Lottie.asset(\'…json\'). Дальше: контроллер '
            'для play/pause/скорости, отрезки по кадрам или маркерам, '
            'ValueDelegate для цветов и текста.',
      ),
    ),
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
            Text(tr('How to hand off an animation to the developer', 'Как передать анимацию разработчику'), style: textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final (i, (title, text)) in _steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: kAccent,
                      child: Text(
                        '${i + 1}',
                        style: textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: textTheme.titleSmall),
                          Text(text, style: textTheme.bodySmall),
                        ],
                      ),
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

// ───────────────────────────────────────────────────────────────── Gallery

List<(String, String, String)> get _gallery => [
  ('gears.json', tr('Gears', 'Шестерёнки'), tr('A looping loader, 52 frames, 9 KB', 'Зацикленный лоадер, 52 кадра, 9 КБ')),
  (
    'bouncing_ball.json',
    tr('Bouncing ball', 'Прыгающий мяч'),
    tr('A squash & stretch classic, 30 frames', 'Классика squash & stretch, 30 кадров'),
  ),
  (
    'thunder_storm.json',
    tr('Thunderstorm', 'Гроза'),
    tr('A weather icon: cloud, lightning, rain', 'Погодная иконка: облако, молния, дождь'),
  ),
  (
    'day_night_cycle.json',
    tr('Day / night', 'День / ночь'),
    tr('A scene change via masks (track matte)', 'Смена сцены через маски (track matte)'),
  ),
  (
    'jojo_the_bird.json',
    tr('Bird', 'Птица'),
    tr('Character animation: wings, tail, head', 'Персонажная анимация: крылья, хвост, голова'),
  ),
  ('material_wave_loading.json', tr('Wave', 'Волна'), tr('A Material dot loader', 'Material-лоадер из точек')),
];

class _GalleryBlock extends StatefulWidget {
  const _GalleryBlock();

  @override
  State<_GalleryBlock> createState() => _GalleryBlockState();
}

class _GalleryBlockState extends State<_GalleryBlock> {
  bool _animate = true;
  bool _pingPong = false;
  bool _maxFps = false;

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
                  child: Text(tr('Gallery — files loop on their own', 'Галерея — файлы играют по кругу'), style: textTheme.titleMedium),
                ),
                SpecButton(
                  title: tr('Lottie — gallery', 'Lottie — галерея'),
                  spec: () => {
                    'package': packageSpec('lottie'),
                    'widget': 'Lottie.asset',
                    'files': [for (final (file, title, _) in _gallery) {'asset': '$_dir/$file', 'title': title}],
                    'animate': _animate,
                    'repeat': true,
                    'reverse': _pingPong,
                    'loop_mode': _pingPong ? 'ping-pong' : 'loop',
                    'frameRate': _maxFps ? 'FrameRate.max' : 'FrameRate.composition',
                    'fit': 'contain',
                    'height_px': 120,
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'The simplest case: Lottie.asset(\'file.json\') — and the animation '
                    'loops on its own. One line of code per animation.',
                'Самый простой случай: Lottie.asset(\'файл.json\') — и анимация '
                    'сама зацикливается. Одна строка кода на анимацию.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 200,
              children: [
                for (final (file, title, caption) in _gallery)
                  ShowcaseTile(
                    title: title,
                    caption: caption,
                    previewHeight: 140,
                    child: Lottie.asset(
                      '$_dir/$file',
                      animate: _animate,
                      reverse: _pingPong,
                      frameRate: _maxFps ? FrameRate.max : FrameRate.composition,
                      fit: BoxFit.contain,
                      height: 120,
                      errorBuilder: _lottieError,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(tr('Play', 'Играть')),
                  selected: _animate,
                  onSelected: (v) => setState(() => _animate = v),
                ),
                FilterChip(
                  label: Text(tr('Ping-pong (back and forth)', 'Пинг-понг (туда-обратно)')),
                  selected: _pingPong,
                  onSelected: (v) => setState(() => _pingPong = v),
                ),
                FilterChip(
                  label: Text(tr('Screen refresh rate instead of AE fps', 'Частота экрана вместо fps из AE')),
                  tooltip: tr(
                    'By default Lottie draws at the rate the file was exported at '
                        '(usually 24–60 fps) — this saves battery. FrameRate.max — '
                        'smooth, up to 120 fps.',
                    'По умолчанию Lottie рисует с частотой, с которой '
                        'файл экспортирован (обычно 24–60 fps) — это экономит '
                        'батарею. FrameRate.max — плавно, до 120 fps.',
                  ),
                  selected: _maxFps,
                  onSelected: (v) => setState(() => _maxFps = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _lottieError(BuildContext context, Object error, StackTrace? stackTrace) {
  return Center(
    child: Text(tr('Failed to load: $error', 'Не удалось загрузить: $error'), textAlign: TextAlign.center),
  );
}

// ─────────────────────────────────────────────────────────────────── Player

class _PlayerBlock extends StatefulWidget {
  const _PlayerBlock();

  @override
  State<_PlayerBlock> createState() => _PlayerBlockState();
}

class _PlayerBlockState extends State<_PlayerBlock> with SingleTickerProviderStateMixin {
  static const _asset = '$_dir/lottie_logo.json';

  late final AnimationController _controller = AnimationController(vsync: this);
  LottieComposition? _composition;
  Object? _error;

  bool _playing = false;
  bool _backward = false;
  bool _loop = true;
  bool _pingPong = false;
  double _speed = 1;
  BoxFit _fit = BoxFit.contain;
  RangeValues _segment = const RangeValues(0, 1); // in frames, set after loading

  /// The "run" number: a new run cancels the previous one's loop.
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    AssetLottie(_asset).load().then((composition) {
      if (!mounted) return;
      setState(() {
        _composition = composition;
        _segment = RangeValues(0, composition.durationFrames);
      });
      _applySpeed();
      _play();
    }, onError: (Object e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    _runId++;
    _controller.dispose();
    super.dispose();
  }

  double get _totalFrames => _composition?.durationFrames ?? 1;
  double get _lo => _segment.start / _totalFrames;
  double get _hi => _segment.end / _totalFrames;

  void _applySpeed() {
    final c = _composition;
    if (c == null) return;
    // Duration of a full 0→1 pass; animateTo shortens it itself
    // proportionally to the distance already covered.
    _controller.duration = c.duration * (1 / _speed);
  }

  /// Plays the selected segment honoring direction, repeat, and ping-pong.
  Future<void> _play() async {
    if (_composition == null) return;
    final id = ++_runId;
    setState(() => _playing = true);
    var backward = _backward;
    const eps = 0.001;
    try {
      while (mounted && id == _runId) {
        if (_hi - _lo < eps) break;
        if (!backward) {
          if (_controller.value >= _hi - eps || _controller.value < _lo) {
            _controller.value = _lo;
          }
          await _controller.animateTo(_hi).orCancel;
        } else {
          if (_controller.value <= _lo + eps || _controller.value > _hi) {
            _controller.value = _hi;
          }
          await _controller.animateBack(_lo).orCancel;
        }
        if (!_loop) break;
        if (_pingPong) backward = !backward;
      }
    } on TickerCanceled {
      // Stopped manually, settings changed, or left the screen — this is expected.
    }
    if (mounted && id == _runId) setState(() => _playing = false);
  }

  void _pause() {
    _runId++;
    _controller.stop();
    setState(() => _playing = false);
  }

  /// Restart with the new settings if currently playing.
  void _restartIfPlaying() {
    if (_playing) {
      _controller.stop();
      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    final Widget preview;
    if (_error != null) {
      preview = Text(tr('Failed to load: $_error', 'Не удалось загрузить: $_error'));
    } else if (composition == null) {
      preview = const CircularProgressIndicator();
    } else {
      preview = Lottie(
        composition: composition,
        controller: _controller,
        fit: _fit,
      );
    }

    return AnimBlock(
      title: tr('Player — full control from code', 'Плеер — полный контроль из кода'),
      spec: () => {
        'package': packageSpec('lottie'),
        'widget': 'Lottie(composition, controller: AnimationController)',
        'asset': _asset,
        ..._compositionSpec(_composition),
        'segment_frames': {'from': _segment.start.round(), 'to': _segment.end.round()},
        'segment_progress': {'from': round2(_lo, 3), 'to': round2(_hi, 3)},
        'speed': round2(_speed),
        'segment_duration_ms': _composition == null
            ? null
            : ((_hi - _lo) * _composition!.duration.inMilliseconds / _speed).round(),
        'direction': _backward ? 'reverse' : 'forward',
        'loop_mode': !_loop ? 'once' : (_pingPong ? 'ping-pong' : 'loop'),
        'fit': _fit.name,
        'current_frame': (_controller.value * _totalFrames).round(),
      },
      description: tr(
        'The developer passes their own AnimationController to Lottie and controls '
            'the file like a video: pause, reverse, speed, scrubbing, replaying only '
            'part of the animation (e.g. a "waiting loop" from frame 60 to 120).',
        'Разработчик передаёт в Lottie свой AnimationController и управляет '
            'файлом как видео: пауза, реверс, скорость, перемотка, повтор только '
            'части анимации (например, «петля ожидания» с 60 по 120 кадр).',
      ),
      preview: preview,
      controls: composition == null ? const SizedBox.shrink() : _controls(composition),
    );
  }

  Widget _controls(LottieComposition composition) {
    final textTheme = Theme.of(context).textTheme;
    final total = composition.durationFrames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _playing ? _pause : _play,
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              label: Text(_playing ? tr('Pause', 'Пауза') : tr('Play', 'Играть')),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, icon: const Icon(Icons.fast_forward), label: Text(tr('Forward', 'Вперёд'))),
                ButtonSegment(value: true, icon: const Icon(Icons.fast_rewind), label: Text(tr('Backward', 'Назад'))),
              ],
              selected: {_backward},
              onSelectionChanged: (s) {
                setState(() => _backward = s.first);
                _restartIfPlaying();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(tr('Repeat', 'Повтор')),
              selected: _loop,
              onSelected: (v) {
                setState(() => _loop = v);
                _restartIfPlaying();
              },
            ),
            FilterChip(
              label: Text(tr('Ping-pong', 'Пинг-понг')),
              selected: _pingPong,
              onSelected: (v) {
                setState(() => _pingPong = v);
                _restartIfPlaying();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Scrubbing: shows the current frame and lets you seek.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => LabeledSlider(
            label: tr('Frame (scrubbing)', 'Кадр (перемотка)'),
            value: (_controller.value * total).clamp(0, total),
            min: 0,
            max: total,
            unit: '/ ${total.round()}',
            onChanged: (v) {
              if (_playing) _pause();
              _controller.value = v / total;
            },
          ),
        ),
        LabeledSlider(
          label: tr('Speed', 'Скорость'),
          value: _speed,
          min: 0.25,
          max: 3,
          fractionDigits: 2,
          unit: '×',
          onChanged: (v) {
            setState(() => _speed = v);
            _applySpeed();
            _restartIfPlaying();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('Segment: from frame — to frame', 'Отрезок: с кадра — по кадр'), style: textTheme.bodyMedium)),
            Text(
              '${_segment.start.round()} – ${_segment.end.round()}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        RangeSlider(
          values: _segment,
          min: 0,
          max: total,
          onChanged: (v) => setState(() => _segment = v),
          onChangeEnd: (_) {
            _controller.value = _backward ? _hi : _lo;
            _restartIfPlaying();
          },
        ),
        Row(
          children: [
            Text('fit', style: textTheme.bodyMedium),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<BoxFit>(
                isExpanded: true,
                value: _fit,
                items: [
                  for (final f in const [BoxFit.contain, BoxFit.cover, BoxFit.fill, BoxFit.fitWidth, BoxFit.fitHeight, BoxFit.none])
                    DropdownMenuItem(value: f, child: Text(f.name)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _fit = v);
                },
              ),
            ),
          ],
        ),
        Text(
          tr(
            '${composition.frameRate.round()} fps · ${total.round()} frames · '
                '${composition.seconds.toStringAsFixed(1)} s at 1× speed',
            '${composition.frameRate.round()} fps · ${total.round()} кадров · '
                '${composition.seconds.toStringAsFixed(1)} с при скорости 1×',
          ),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Tap — play once

class _TapOnceBlock extends StatefulWidget {
  const _TapOnceBlock();

  @override
  State<_TapOnceBlock> createState() => _TapOnceBlockState();
}

class _TapOnceBlockState extends State<_TapOnceBlock> with TickerProviderStateMixin {
  late final AnimationController _heart = AnimationController(vsync: this);
  late final AnimationController _check = AnimationController(vsync: this);
  late final AnimationController _toggle = AnimationController(vsync: this);

  bool _liked = false;
  bool _toggled = false;

  // Segments from the like file — markers the designer placed in AE.
  Marker? _likeStart;
  Marker? _likeEnd;
  LottieComposition? _heartC;
  LottieComposition? _checkC;
  LottieComposition? _toggleC;

  Map<String, Object?> _segment(LottieComposition? c, double from, double to) => {
    'progress': {'from': round2(from, 3), 'to': round2(to, 3)},
    if (c != null) ...{
      'frames': {
        'from': (c.startFrame + from * c.durationFrames).round(),
        'to': (c.startFrame + to * c.durationFrames).round(),
      },
      'duration_ms': ((to - from) * c.duration.inMilliseconds).round(),
    },
  };

  Map<String, Object?> _spec() => {
    'package': packageSpec('lottie'),
    'widget': 'Lottie.asset(controller: AnimationController)',
    'items': [
      {
        'item': tr('Like', 'Лайк'),
        'asset': '$_dir/twitter_heart.json',
        ..._compositionSpec(_heartC),
        'on_tap_like': {
          'from_marker': 'touchDownStart',
          'to_marker': 'touchUpEnd',
          ..._segment(_heartC, _likeStart?.start ?? 0.28, _likeEnd?.start ?? 0.9),
        },
        'on_tap_unlike': {'animateBack_to': 0, 'duration_ms': 250},
        'loop_mode': 'once',
      },
      {
        'item': tr('Checkmark', 'Галочка'),
        'asset': '$_dir/check_pop.json',
        ..._compositionSpec(_checkC),
        'on_tap': {'method': 'forward(from: 0)', ..._segment(_checkC, 0, 1)},
        'rest_progress': 1,
        'loop_mode': 'once',
      },
      {
        'item': tr('Toggle', 'Переключатель'),
        'asset': '$_dir/toggle_switch.json',
        ..._compositionSpec(_toggleC),
        'on_tap_on': _segment(_toggleC, _toggleOn.$1, _toggleOn.$2),
        'on_tap_off': _segment(_toggleC, _toggleOff.$1, _toggleOff.$2),
        'display_scale': 2.4,
        'loop_mode': 'once',
      },
    ],
  };

  // The toggle has no markers — segments are picked by frame (fractions of 0…1).
  static const _toggleOn = (0.0, 0.40);
  static const _toggleOff = (0.50, 0.73);

  @override
  void dispose() {
    _heart.dispose();
    _check.dispose();
    _toggle.dispose();
    super.dispose();
  }

  void _tapHeart() {
    setState(() => _liked = !_liked);
    final start = _likeStart?.start ?? 0.28;
    final end = _likeEnd?.start ?? 0.9;
    if (_liked) {
      // Play the "like" from the touchDownStart marker to touchUpEnd.
      _heart.value = start;
      _heart.animateTo(end);
    } else {
      // Unliking — quickly go back to the gray heart.
      _heart.animateBack(0, duration: const Duration(milliseconds: 250));
    }
  }

  void _tapCheck() => _check.forward(from: 0);

  void _tapToggle() {
    setState(() => _toggled = !_toggled);
    final (from, to) = _toggled ? _toggleOn : _toggleOff;
    _toggle.value = from;
    _toggle.animateTo(to);
  }

  void _playAll() {
    _tapHeart();
    _tapCheck();
    _tapToggle();
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
                Expanded(child: Text(tr('Tap — play once', 'Тап — сыграть один раз'), style: textTheme.titleMedium)),
                SpecButton(title: tr('Lottie — tap, play once', 'Lottie — тап, сыграть один раз'), spec: _spec),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Micro-interactions: the animation doesn\'t loop, it plays in '
                    'response to an action. The like plays a segment between markers '
                    'the designer placed in After Effects; the toggle — two segments, '
                    '"on" and "off", of one file.',
                'Микро-взаимодействия: анимация не крутится, а проигрывается в '
                    'ответ на действие. Лайк играет отрезок между маркерами, которые '
                    'дизайнер поставил в After Effects; переключатель — два отрезка '
                    '«вкл» и «выкл» одного файла.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 200,
              children: [
                ShowcaseTile(
                  title: _liked
                      ? tr('Like ♥ (tap again to unlike)', 'Лайк ♥ (тапни ещё раз — снять)')
                      : tr('Like', 'Лайк'),
                  caption: tr('touchDownStart → touchUpEnd markers from AE', 'Маркеры touchDownStart → touchUpEnd из AE'),
                  previewHeight: 140,
                  onTap: _tapHeart,
                  child: Lottie.asset(
                    '$_dir/twitter_heart.json',
                    controller: _heart,
                    height: 130,
                    errorBuilder: _lottieError,
                    onLoaded: (c) {
                      _heartC = c;
                      _heart.duration = c.duration;
                      _likeStart = c.getMarker('touchDownStart');
                      _likeEnd = c.getMarker('touchUpEnd');
                    },
                  ),
                ),
                ShowcaseTile(
                  title: tr('"Done" checkmark', 'Галочка «готово»'),
                  caption: tr('forward(from: 0) — replays on every tap', 'forward(from: 0) — каждый тап заново'),
                  previewHeight: 140,
                  onTap: _tapCheck,
                  child: Lottie.asset(
                    '$_dir/check_pop.json',
                    controller: _check,
                    height: 120,
                    errorBuilder: _lottieError,
                    onLoaded: (c) {
                      _checkC = c;
                      _check.duration = c.duration;
                      // At rest, show the completed checkmark; a tap replays it.
                      if (!_check.isAnimating) _check.value = 1;
                    },
                  ),
                ),
                ShowcaseTile(
                  title: _toggled ? tr('Toggle: on', 'Переключатель: вкл') : tr('Toggle: off', 'Переключатель: выкл'),
                  caption: tr('One file — two segments: on and off', 'Один файл — два отрезка: вкл и выкл'),
                  previewHeight: 140,
                  onTap: _tapToggle,
                  // The toggle itself occupies a small part of the 600×600
                  // frame — scale it up to make it visible.
                  child: Transform.scale(
                    scale: 2.4,
                    child: Lottie.asset(
                      '$_dir/toggle_switch.json',
                      controller: _toggle,
                      height: 130,
                      errorBuilder: _lottieError,
                      onLoaded: (c) {
                        _toggleC = c;
                        _toggle.duration = c.duration;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _playAll,
              icon: const Icon(Icons.touch_app),
              label: Text(tr('Tap all', 'Тапнуть все')),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── Dynamic properties (colors)

const _colors = <String, Color>{
  'as in file': Colors.transparent,
  'purple': kAccent,
  'teal': Color(0xFF00897B),
  'orange': Color(0xFFF57C00),
  'graphite': Color(0xFF37474F),
};

/// Display name for a color option id.
String _colorLabel(String id) => switch (id) {
  'purple' => tr('Purple', 'Фиолетовый'),
  'teal' => tr('Teal', 'Бирюзовый'),
  'orange' => tr('Orange', 'Оранжевый'),
  'graphite' => tr('Graphite', 'Графит'),
  _ => tr('As in file', 'Как в файле'),
};

const _layers = <String, List<String>>{
  'all': ['**'],
  'gear1': ['gear1', '**'],
  'gear2': ['gear2', '**'],
  'gear3': ['gear3', '**'],
};

/// Display name for a layer option id.
String _layerLabel(String id) => id == 'all' ? tr('All layers (**)', 'Все слои (**)') : id;

class _DelegatesBlock extends StatefulWidget {
  const _DelegatesBlock();

  @override
  State<_DelegatesBlock> createState() => _DelegatesBlockState();
}

class _DelegatesBlockState extends State<_DelegatesBlock> {
  String _color = 'purple';
  String _layer = 'gear1';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _colors[_color]!;
    final keyPath = _layers[_layer]!;
    final delegates = color == Colors.transparent
        ? null
        : LottieDelegates(values: [ValueDelegate.color(keyPath, value: color)]);

    return AnimBlock(
      title: tr('Recoloring from code — by layer name', 'Перекраска из кода — по имени слоя'),
      spec: () => {
        'package': packageSpec('lottie'),
        'widget': 'Lottie.asset(delegates: LottieDelegates)',
        'asset': '$_dir/gears.json',
        'height_px': 180,
        'delegate': color == Colors.transparent
            ? tr('none — colors as in the file', 'нет — цвета как в файле')
            : {
                'type': 'ValueDelegate.color',
                'keyPath': keyPath,
                'value': hexColor(color),
              },
        'layers_in_file': ['gear1', 'gear2', 'gear3'],
        'repeat': true,
      },
      description: tr(
        'One file — many themes: the developer changes a layer\'s color, opacity or '
            'text right in code via ValueDelegate. The layer is looked up by its '
            'After Effects name (keypath), so it matters that the designer names '
            'layers clearly. In this file the layers are named gear1, gear2, gear3.',
        'Один файл — много тем: разработчик меняет цвет, прозрачность или '
            'текст слоя прямо в коде через ValueDelegate. Слой ищется по имени '
            'из After Effects (keypath), поэтому дизайнеру важно называть слои '
            'понятно. В этом файле слои называются gear1, gear2, gear3.',
      ),
      preview: Lottie.asset(
        '$_dir/gears.json',
        delegates: delegates,
        height: 180,
        errorBuilder: _lottieError,
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Color', 'Цвет'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: name, value: c) in _colors.entries)
                ChoiceChip(
                  avatar: c == Colors.transparent
                      ? const Icon(Icons.restart_alt, size: 18)
                      : CircleAvatar(backgroundColor: c),
                  label: Text(_colorLabel(name)),
                  selected: _color == name,
                  onSelected: (_) => setState(() => _color = name),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tr('Which layer (keypath)', 'Какой слой (keypath)'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in _layers.keys)
                ChoiceChip(
                  label: Text(_layerLabel(name)),
                  selected: _layer == name,
                  onSelected: (_) => setState(() => _layer = name),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _CodeLine(
            color == Colors.transparent
                ? "Lottie.asset('gears.json')"
                : "ValueDelegate.color(${_keyPathLiteral(keyPath)}, value: …)",
          ),
        ],
      ),
    );
  }

  String _keyPathLiteral(List<String> path) => "[${path.map((p) => "'$p'").join(', ')}]";
}

/// A line of code in a monospace font — so it's clear what the developer writes.
class _CodeLine extends StatelessWidget {
  const _CodeLine(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── brief playground

/// Real Lottie: the selected file plays a "from frame — to frame" segment at
/// the given speed, looping or ping-pong. Pass duration is computed from the
/// file's fps: (to − from) / fps / speed.
Widget _lottiePlayground(BuildContext context, BriefValues v, double t) => _LottieRangePreview(
  file: v.text('file'),
  from: v.number('frame_from'),
  to: v.number('frame_to'),
  speed: v.number('speed'),
  pingPong: v.text('loop') == 'ping-pong',
);

class _LottieRangePreview extends StatefulWidget {
  const _LottieRangePreview({
    required this.file,
    required this.from,
    required this.to,
    required this.speed,
    required this.pingPong,
  });

  final String file;
  final double from;
  final double to;
  final double speed;
  final bool pingPong;

  @override
  State<_LottieRangePreview> createState() => _LottieRangePreviewState();
}

class _LottieRangePreviewState extends State<_LottieRangePreview> {
  late Future<LottieComposition> _future = AssetLottie('$_dir/${widget.file}').load();

  @override
  void didUpdateWidget(_LottieRangePreview old) {
    super.didUpdateWidget(old);
    if (old.file != widget.file) _future = AssetLottie('$_dir/${widget.file}').load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _future,
      builder: (context, snap) {
        final c = snap.data;
        if (snap.hasError) return Text(tr('Failed to load: ${snap.error}', 'Не удалось загрузить: ${snap.error}'));
        if (c == null) return const CircularProgressIndicator();
        final total = c.durationFrames;
        final from = widget.from.clamp(0, total).toDouble();
        final to = widget.to.clamp(0, total).toDouble();
        final lo = math.min(from, to), hi = math.max(from, to);
        final passMs = ((hi - lo) / c.frameRate * 1000 / widget.speed).round().clamp(1, 60000);
        return LoopClock(
          periodMs: widget.pingPong ? passMs * 2 : passMs,
          pauseMs: widget.pingPong ? 0 : 400,
          builder: (context, ms) {
            var p = ms / passMs;
            if (widget.pingPong) p = p <= 1 ? p : 2 - p;
            final frame = lo + (hi - lo) * p.clamp(0.0, 1.0);
            return Column(
              children: [
                Expanded(
                  child: Lottie(
                    composition: c,
                    controller: AlwaysStoppedAnimation(frame / total),
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  tr(
                    'frame ${frame.round()} of ${total.round()} · ${c.frameRate.round()} fps · '
                        'pass $passMs ms',
                    'кадр ${frame.round()} из ${total.round()} · ${c.frameRate.round()} fps · '
                        'проход $passMs мс',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        );
      },
    );
  }
}
