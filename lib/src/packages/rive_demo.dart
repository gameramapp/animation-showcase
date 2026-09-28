// Showcase of the `rive` package (0.14, new runtime on rive_native):
//   • How to hand off a file — Rive Editor → .riv → State Machine and its
//     inputs as a "contract" between the designer and the developer;
//   • Renderer — Rive Renderer or Flutter's standard renderer;
//   • Infinite loop — the file plays its State Machine's idle animation on its own;
//   • State Machine — the file's inputs (Boolean / Number / Trigger) automatically
//     turn into Flutter controls: a switch, a slider, a button;
//   • Fit and Alignment — how the artboard fits into the container.
//
// WEB: rive 0.14 works through rive_native, which loads a WASM module
// (rive_native.js + rive_native.wasm) from the CDN
// cdn.jsdelivr.net/npm/@rive-app/flutter-native-wasm in the browser the first
// time this screen is opened. Needs internet access (or your own host via
// `wasmHost`); the first load takes 1-3 seconds. In the web, Rive Renderer
// draws each RiveWidget into its own WebGL canvas (platform view); browsers
// limit the number of live WebGL contexts (~16), so we keep only a few
// widgets on screen at once.
//
// RiveNative.init() initialization is lazy, inside the screen (not in
// main.dart). If the runtime fails to start (no network, `flutter test`
// without native libraries), a "Rive failed to load: …" card is shown instead
// of the animation — the screen doesn't crash.
//
// Inputs in the rive 0.14 API are marked deprecated in favor of Data Binding
// (View Models), but they remain the most common "contract" in ready-made
// files, so that's what's used here.

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../common/anim_block.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import '../common/motion_spec.dart' show SpecButton;
import 'package_spec.dart';

const _dir = 'assets/rive';

class RiveDemo extends StatefulWidget {
  const RiveDemo({super.key});
  static const String routeName = 'packages/rive';

  @override
  State<RiveDemo> createState() => _RiveDemoState();
}

class _RiveDemoState extends State<RiveDemo> {
  bool _riveRenderer = true;
  late _RiveFiles _files = _RiveFiles(riveRenderer: _riveRenderer);

  @override
  void dispose() {
    // The child blocks have already disposed their controllers by this point.
    _files.dispose();
    super.dispose();
  }

  void _setRenderer(bool riveRenderer) {
    if (riveRenderer == _riveRenderer) return;
    final old = _files;
    setState(() {
      _riveRenderer = riveRenderer;
      _files = _RiveFiles(riveRenderer: riveRenderer);
    });
    // Dispose the old files after a frame, once the blocks holding the old
    // controllers have already been unmounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    // Keys derived from the file set: blocks are recreated when the renderer changes.
    final files = _files;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr(
              'Rive — interactive animation with logic inside',
              'Rive — интерактивная анимация с логикой внутри',
            ),
            text: tr(
              'Rive is an editor (rive.app) and a runtime. The designer draws, '
                  'animates and assembles a State Machine right in the editor: states, '
                  'transitions and "handles" (inputs) — e.g. "rating = 3" or "raining = '
                  'yes". One .riv file is exported, and it behaves in the app exactly '
                  'as in the editor. All the code has to do is turn those handles. '
                  'Integration difficulty for a ready file: medium — you need to agree '
                  'on the artboard, state machine and input names.\n\n'
                  'On the web, Rive downloads its WASM engine from a CDN '
                  '(cdn.jsdelivr.net) the first time this screen opens — it needs '
                  'internet access, and the first load takes a couple of seconds.',
              'Rive — редактор (rive.app) и рантайм. Дизайнер рисует, '
                  'анимирует и прямо в редакторе собирает State Machine: состояния, '
                  'переходы и «ручки» (inputs) — например, «рейтинг = 3» или «идёт '
                  'дождь = да». Экспортируется один .riv-файл, который в приложении '
                  'ведёт себя точно как в редакторе. Коду остаётся только крутить '
                  'эти ручки. Сложность интеграции готового файла: средне — нужно '
                  'договориться об именах artboard, state machine и inputs.\n\n'
                  'В вебе Rive при первом открытии экрана скачивает свой '
                  'WASM-движок с CDN (cdn.jsdelivr.net) — нужен интернет, первая '
                  'загрузка занимает пару секунд.',
            ),
            hint: tr(
              'Everything plays on its own. In the State Machine block, tap the '
                  'switches, sliders and buttons — or tap right on the animation.',
              'Всё играет само. В блоке State Machine жми на свитчи, '
                  'слайдеры и кнопки — или тапай прямо по анимации.',
            ),
          ),
          const SizedBox(height: 16),
          const _HandoffCard(),
          const SizedBox(height: 16),
          _RendererCard(riveRenderer: _riveRenderer, onChanged: _setRenderer),
          const SizedBox(height: 16),
          _LoopBlock(key: ValueKey(('loop', files)), files: files),
          const SizedBox(height: 16),
          _StateMachineBlock(key: ValueKey(('sm', files)), files: files),
          const SizedBox(height: 16),
          _FitBlock(key: ValueKey(('fit', files)), files: files),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.number('input_value', tr('Number-input value', 'Значение Number-input'), 3, min: 0, max: 5),
                BriefField.text('input_name', tr('Input name', 'Имя input'), 'rating'),
                BriefField.text('state_machine', 'State Machine', 'State Machine 1'),
                BriefField.text('artboard', 'Artboard', tr('default', 'по умолчанию')),
                BriefField.choice(
                  'fit',
                  'Fit',
                  ['contain', 'cover', 'fill', 'fitWidth', 'fitHeight', 'none', 'scaleDown', 'layout'],
                  'contain',
                ),
                BriefField.choice(
                  'alignment',
                  'Alignment',
                  ['center', 'topLeft', 'topCenter', 'topRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
                  'center',
                ),
              ],
              builder: (context, v, t) => _RivePlaygroundPreview(
                key: ValueKey(('playground', files)),
                files: files,
                inputName: v.text('input_name'),
                value: v.number('input_value'),
                fit: v.text('fit'),
                alignment: v.text('alignment'),
              ),
            ),
            items: [
              (
                tr('.riv file', 'Файл .riv'),
                tr(
                  'Export → For Runtime; a single file with all artboards and logic',
                  'Export → For Runtime; один файл со всеми артбордами и логикой',
                ),
              ),
              (
                tr('Artboard name', 'Имя артборда'),
                tr(
                  'exact, case- and space-sensitive; if there are several artboards — which one for which screen',
                  'точное, с учётом регистра и пробелов; если артбордов несколько — какой для какого экрана',
                ),
              ),
              (
                tr('State Machine name', 'Имя State Machine'),
                tr('exact; which one starts by default', 'точное; какая из них стартует по умолчанию'),
              ),
              (
                tr('Inputs are the contract', 'Inputs — это контракт'),
                tr(
                  'a list: name, type (Boolean / Number / Trigger), range and meaning — '
                      '"rating: Number 0–5, step 1"',
                  'список: имя, тип (Boolean / Number / Trigger), диапазон и смысл — '
                      '«rating: Number 0–5, шаг 1»',
                ),
              ),
              (
                tr('Idle state', 'Idle-состояние'),
                tr(
                  'what plays while nothing is done to the animation, and whether it loops',
                  'что играет, пока с анимацией ничего не делают, и зациклено ли оно',
                ),
              ),
              (
                tr('Events for the app', 'События для приложения'),
                tr(
                  'which states / Events from the file the app should catch (e.g. '
                      '"success animation finished")',
                  'какие состояния / Events из файла приложение должно ловить (например, '
                      '«анимация успеха закончилась»)',
                ),
              ),
              (
                tr('Size and fit', 'Размер и вписывание'),
                tr(
                  'artboard size, place in the interface, Fit (contain / cover / layout…) and Alignment',
                  'размер артборда, место в интерфейсе, Fit (contain / cover / layout…) и Alignment',
                ),
              ),
            ],
            avoid: [
              tr(
                'Renaming the artboard, state machine or inputs after handoff — the code will stop finding them.',
                'Переименовывать artboard, state machine или inputs после передачи — код перестанет их находить.',
              ),
              tr(
                'Unnamed inputs like "Trigger 1" — name them meaningfully.',
                'Безымянные inputs вроде «Trigger 1» — называй по смыслу.',
              ),
              tr(
                'Too many simultaneous Rive widgets on one web screen — browsers limit the number of WebGL contexts.',
                'Слишком много одновременных Rive-виджетов на одном экране в вебе — у браузера ограничено число WebGL-контекстов.',
              ),
            ],
            handoff: tr(
              'send the .riv file + a table: artboard, state machine and all inputs '
                  '(name, type, range, meaning). Attach the State Machine block\'s "Spec".',
              'пришли .riv-файл + таблицу: artboard, state machine и все inputs '
                  '(имя, тип, диапазон, что означает). Приложи «Спеку» блока State Machine.',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Runtime/file loading

/// Lazy one-time initialization of rive_native.
abstract final class _RiveRuntime {
  static Future<void>? _init;

  static Future<void> ensureInitialized() => _init ??= _doInit();

  static Future<void> _doInit() async {
    // Don't touch the native engine under `flutter test`: if rive_native was
    // built locally, it crashes the test process at the C++ level (SIGABRT),
    // and that can't be caught from Dart. Tests check the fallback instead.
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      throw StateError(tr('Rive is disabled under flutter test', 'Rive отключён в flutter test'));
    }
    // In the web, init() waits for the WASM script to load from the CDN and
    // may never finish without network access — so we cap the wait.
    final ok = await rive.RiveNative.init().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        tr(
          'The Rive WASM engine did not load within 20 s (needs access to cdn.jsdelivr.net)',
          'WASM-движок Rive не загрузился за 20 с (нужен доступ к cdn.jsdelivr.net)',
        ),
      ),
    );
    if (!ok) {
      throw StateError(
        tr('RiveNative.init() returned false — the engine is unavailable', 'RiveNative.init() вернул false — движок недоступен'),
      );
    }
  }
}

/// Runs [body] in a separate zone and catches "lost" asynchronous rive_native
/// errors too (for example, when the native library isn't found under
/// `flutter test`) — so they don't surface as uncaught errors.
Future<T> _guarded<T>(Future<T> Function() body) {
  final completer = Completer<T>();
  runZonedGuarded(
    () async {
      final value = await body();
      if (!completer.isCompleted) completer.complete(value);
    },
    (error, stack) {
      if (!completer.isCompleted) {
        completer.completeError(error, stack);
      } else {
        debugPrint('Rive: $error');
      }
    },
  );
  return completer.future;
}

/// Cache of the screen's .riv files. A single file can be used by several
/// controllers (each creates its own artboard instance).
class _RiveFiles {
  _RiveFiles({required this.riveRenderer});

  final bool riveRenderer;
  final _futures = <String, Future<rive.File>>{};
  final _loaded = <rive.File>[];
  bool _disposed = false;

  Future<rive.File> get(String asset) {
    return _futures.putIfAbsent(
      asset,
      () => _guarded(() async {
        await _RiveRuntime.ensureInitialized();
        final factory = riveRenderer ? rive.Factory.rive : rive.Factory.flutter;
        final file = await rive.File.asset('$_dir/$asset', riveFactory: factory);
        if (file == null) throw StateError(tr('failed to read file $asset', 'файл $asset не удалось прочитать'));
        if (_disposed) {
          file.dispose();
          throw StateError(tr('the screen is already closed', 'экран уже закрыт'));
        }
        _loaded.add(file);
        return file;
      }),
    );
  }

  void dispose() {
    _disposed = true;
    for (final file in _loaded) {
      file.dispose();
    }
    _loaded.clear();
  }
}

/// Which artboard and which state machine to take from the file.
class _RiveSource {
  const _RiveSource(this.asset, {this.artboard});

  final String asset;

  /// null — default artboard. The state machine is always taken by default.
  final String? artboard;
}

/// Shared logic for the blocks: load the file → create the controller →
/// swap out the old controller (the old one is disposed after a frame).
mixin _RiveControllerHost<T extends StatefulWidget> on State<T> {
  _RiveFiles get files;

  rive.RiveWidgetController? controller;
  Object? loadError;
  int _loadId = 0;

  /// Called when the new controller is ready (before setState).
  void onControllerReady(rive.RiveWidgetController controller) {}

  /// Release resources tied to the old controller (e.g. inputs).
  void onControllerRetired(rive.RiveWidgetController controller) {}

  Future<void> loadSource(_RiveSource source) async {
    final id = ++_loadId;
    try {
      final file = await files.get(source.asset);
      if (!mounted || id != _loadId) return;
      final next = rive.RiveWidgetController(
        file,
        artboardSelector: source.artboard == null
            ? const rive.ArtboardDefault()
            : rive.ArtboardSelector.byName(source.artboard!),
      );
      final old = controller;
      if (old != null) onControllerRetired(old);
      onControllerReady(next);
      setState(() {
        controller = next;
        loadError = null;
      });
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    } catch (e) {
      if (mounted && id == _loadId) setState(() => loadError = e);
    }
  }

  void disposeController() {
    _loadId++;
    final c = controller;
    if (c != null) {
      onControllerRetired(c);
      c.dispose();
    }
    controller = null;
  }

  /// Shared part of the "Spec": file, artboard, state machine, renderer.
  Map<String, Object?> sourceSpec(_RiveSource source) {
    final c = controller;
    return {
      'package': packageSpec('rive'),
      'widget': 'RiveWidget(controller: RiveWidgetController(file))',
      'file': '$_dir/${source.asset}',
      'artboard': c?.artboard.name ?? source.artboard ?? tr('default (ArtboardDefault)', 'по умолчанию (ArtboardDefault)'),
      'artboard_selector': source.artboard == null
          ? 'ArtboardDefault()'
          : "ArtboardSelector.byName('${source.artboard}')",
      'state_machine': c?.stateMachine.name ?? tr('default (StateMachineDefault)', 'по умолчанию (StateMachineDefault)'),
      'riveFactory': files.riveRenderer ? 'Factory.rive' : 'Factory.flutter',
      if (c == null) 'status': loadError == null ? tr('loading', 'загружается') : tr('Rive failed to load', 'Rive не загрузился'),
    };
  }

  /// Preview: loading / error / the widget itself.
  Widget buildPreview(Widget Function(rive.RiveWidgetController c) builder) {
    final error = loadError;
    if (error != null) return _RiveUnavailable(error: error);
    final c = controller;
    if (c == null) return const CircularProgressIndicator();
    return builder(c);
  }
}

/// Fallback shown instead of the animation if Rive fails to start.
class _RiveUnavailable extends StatelessWidget {
  const _RiveUnavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    var message = error.toString().split('\n').first;
    if (message.length > 140) message = '${message.substring(0, 140)}…';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: colors.error),
          const SizedBox(height: 8),
          Text(
            tr('Rive failed to load: $message', 'Rive не загрузился: $message'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'On the web, check access to cdn.jsdelivr.net and refresh the page.',
              'В вебе проверь доступ к cdn.jsdelivr.net и обнови страницу.',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.outline),
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
      tr('Draw and animate in Rive Editor', 'Рисуй и анимируй в Rive Editor'),
      tr(
        'rive.app — vectors, bones, meshes, timelines. Each animation is a '
            'separate timeline (idle, hover, press…).',
        'rive.app — векторы, кости, меши, таймлайны. Каждая анимация — '
            'отдельный таймлайн (idle, hover, press…).',
      ),
    ),
    (
      tr('Assemble a State Machine', 'Собери State Machine'),
      tr(
        'States and transitions between timelines. Transition conditions are '
            'inputs: Boolean (on/off), Number, Trigger (a one-off pulse). You can '
            'also add Listeners right away — a reaction to tap and hover in the '
            'file itself. In newer files Rive recommends Data Binding (View Model) '
            '— an evolution of the same idea.',
        'Состояния и переходы между таймлайнами. Условия переходов — это '
            'inputs: Boolean (вкл/выкл), Number (число), Trigger (разовый '
            'импульс). Можно сразу добавить Listeners — реакцию на тап и '
            'наведение прямо в файле. В новых файлах Rive советует Data Binding '
            '(View Model) — это развитие той же идеи.',
      ),
    ),
    (
      tr('Export .riv', 'Экспортируй .riv'),
      tr(
        'Export → For Runtime. One small file (usually tens of KB) holding '
            'all the artboards, animations and logic.',
        'Export → For Runtime. Один небольшой файл (обычно десятки КБ), '
            'в нём все артборды, анимации и логика.',
      ),
    ),
    (
      tr('Hand off the "contract"', 'Передай «контракт»'),
      tr(
        'The artboard name, the state machine name and the list of inputs: name, '
            'type, range and meaning ("rating: Number 0–5"). That\'s the only thing '
            'to agree on — names are case- and space-sensitive.',
        'Имя артборда, имя state machine и список inputs: имя, тип, диапазон и '
            'смысл («rating: Number 0–5»). Это единственное, о чём нужно '
            'договориться — имена чувствительны к регистру и пробелам.',
      ),
    ),
    (
      tr('The developer wires it up', 'Разработчик подключает'),
      tr(
        'RiveWidget(controller: RiveWidgetController(file)), then '
            'stateMachine.number(\'rating\')?.value = 3 or .trigger(\'bump\')?.fire(). '
            'Nothing needs redrawing: change the file — the animation changes.',
        'RiveWidget(controller: RiveWidgetController(file)), а дальше '
            'stateMachine.number(\'rating\')?.value = 3 или .trigger(\'bump\')?.fire(). '
            'Перерисовывать ничего не нужно: поменял файл — поменялась анимация.',
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

// ──────────────────────────────────────────────────────────────── Renderer

class _RendererCard extends StatelessWidget {
  const _RendererCard({required this.riveRenderer, required this.onChanged});

  final bool riveRenderer;
  final ValueChanged<bool> onChanged;

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
                Expanded(child: Text(tr('What to draw with', 'Чем рисовать'), style: textTheme.titleMedium)),
                SpecButton(
                  title: tr('Rive — renderer', 'Rive — рендерер'),
                  spec: () => {
                    'package': packageSpec('rive'),
                    'riveFactory': riveRenderer ? 'Factory.rive' : 'Factory.flutter',
                    'renderer': riveRenderer ? 'Rive Renderer' : 'Flutter Renderer',
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Rive Renderer is Rive\'s own engine: it matches the editor more '
                    'closely and is faster on complex scenes. Flutter Renderer draws '
                    'with Flutter\'s built-in tools — useful when the animation needs '
                    'clipping, effects layered on top, or if the browser is short on '
                    'WebGL. It\'s the same file either way, the developer picks.',
                'Rive Renderer — собственный движок Rive: точнее совпадает с '
                    'редактором и быстрее на сложных сценах. Flutter Renderer рисует '
                    'штатными средствами Flutter — пригодится, если анимацию нужно '
                    'обрезать, наложить эффекты или если в браузере не хватает WebGL. '
                    'Файл один и тот же, выбор делает разработчик.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Rive Renderer')),
                ButtonSegment(value: false, label: Text('Flutter Renderer')),
              ],
              selected: {riveRenderer},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── Infinite loop

List<(String, String, _RiveSource)> get _loopSources => [
  (tr('Off-road car', 'Внедорожник'), 'off_road_car.riv', const _RiveSource('off_road_car.riv')),
  (tr('Truck', 'Грузовик'), 'vehicles.riv · Truck', const _RiveSource('vehicles.riv', artboard: 'Truck')),
  (tr('Robot', 'Робот'), 'little_machine.riv', const _RiveSource('little_machine.riv')),
];

class _LoopBlock extends StatefulWidget {
  const _LoopBlock({super.key, required this.files});

  final _RiveFiles files;

  @override
  State<_LoopBlock> createState() => _LoopBlockState();
}

class _LoopBlockState extends State<_LoopBlock> with _RiveControllerHost {
  int _selected = 0;
  bool _playing = true;

  @override
  _RiveFiles get files => widget.files;

  @override
  void initState() {
    super.initState();
    loadSource(_loopSources[_selected].$3);
  }

  @override
  void onControllerReady(rive.RiveWidgetController controller) {
    controller.active = _playing;
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sources = _loopSources;
    return AnimBlock(
      title: tr('Infinite loop', 'Бесконечный цикл'),
      spec: () => {
        ...sourceSpec(sources[_selected].$3),
        'fit': 'contain',
        'alignment': 'center',
        'active': _playing,
        'loop': tr(
          'the state machine\'s idle animation, looped inside the file itself',
          'idle-анимация state machine, зацикленная в самом файле',
        ),
      },
      description: tr(
        'The simplest case: the file has a State Machine that starts on its '
            'own with a looped idle animation. The code just needs to show the '
            'RiveWidget — no settings required.',
        'Самый простой случай: у файла есть State Machine, которая сама '
            'стартует с зацикленной idle-анимации. Коду достаточно показать '
            'RiveWidget — никаких настроек.',
      ),
      preview: buildPreview((c) => rive.RiveWidget(controller: c, fit: rive.Fit.contain)),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('File', 'Файл'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, (title, _, source)) in sources.indexed)
                ChoiceChip(
                  label: Text(title),
                  selected: _selected == i,
                  onSelected: (_) {
                    setState(() => _selected = i);
                    loadSource(source);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sources[_selected].$2, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          FilterChip(
            label: Text(tr('Play', 'Играть')),
            selected: _playing,
            onSelected: (v) {
              setState(() => _playing = v);
              controller?.active = v;
            },
          ),
          const SizedBox(height: 12),
          const _CodeLine('RiveWidget(controller: RiveWidgetController(file))'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────── State Machine and its inputs

class _SmExample {
  const _SmExample({
    required this.title,
    required this.source,
    required this.note,
    this.ranges = const {},
  });

  final String title;
  final _RiveSource source;
  final String note;

  /// Ranges for Number inputs: name → (min, max, steps; 0 — smooth).
  final Map<String, (double, double, int)> ranges;
}

List<_SmExample> get _smExamples => [
  _SmExample(
    title: tr('Rating', 'Рейтинг'),
    source: const _RiveSource('rating.riv'),
    note: tr(
      'Number "rating" 0–5. The stars can be tapped right in the preview — '
          'the slider value updates: the file changes its own input.',
      'Number «rating» 0–5. Звёзды можно тапать прямо в превью — '
          'значение слайдера обновится: файл сам меняет свой input.',
    ),
    ranges: const {'rating': (0, 5, 5)},
  ),
  _SmExample(
    title: tr('Download', 'Загрузка'),
    source: const _RiveSource('liquid_download.riv'),
    note: tr(
      'Trigger "Download" starts the download, Number "Progress" 0–100 is '
          'the progress, "Indet Mix" is the blend with the indeterminate loader.',
      'Trigger «Download» запускает загрузку, Number «Progress» 0–100 — '
          'прогресс, «Indet Mix» — смесь с неопределённым лоадером.',
    ),
    ranges: const {'Progress': (0, 100, 0), 'Indet Mix': (0, 100, 0)},
  ),
  _SmExample(
    title: tr('Jeep: weather', 'Джип: погода'),
    source: const _RiveSource('vehicles.riv', artboard: 'Jeep'),
    note: tr(
      'Boolean "Raining" — turns on rain and wipers. The "Jeep" artboard from '
          'the vehicles.riv file: a single file can hold several scenes.',
      'Boolean «Raining» — включает дождь и дворники. Артборд «Jeep» '
          'из файла vehicles.riv: в одном файле может быть несколько сцен.',
    ),
  ),
  _SmExample(
    title: tr('Truck: bump', 'Грузовик: кочка'),
    source: const _RiveSource('vehicles.riv', artboard: 'Truck'),
    note: tr(
      'Trigger "bump" — a one-off pulse: the truck bounces and returns to the loop.',
      'Trigger «bump» — разовый импульс: грузовик подпрыгивает и '
          'возвращается в цикл.',
    ),
  ),
  _SmExample(
    title: tr('Level', 'Уровень'),
    source: const _RiveSource('skills.riv'),
    note: tr(
      'Number "Level" 0–2: beginner / intermediate / expert. You can also tap the buttons in the preview.',
      'Number «Level» 0–2: новичок / средний / эксперт. Можно и тапать '
          'по кнопкам в превью.',
    ),
    ranges: const {'Level': (0, 2, 2)},
  ),
  _SmExample(
    title: tr('Button', 'Кнопка'),
    source: const _RiveSource('rocket.riv'),
    note: tr(
      'Two Booleans — "Hover" and "Press": button states driven by code (hover, tap).',
      'Два Boolean — «Hover» и «Press»: состояния кнопки, которыми '
          'управляет код (наведение, нажатие).',
    ),
  ),
  _SmExample(
    title: tr('Switch', 'Выключатель'),
    source: const _RiveSource('light_switch.riv'),
    note: tr('One Boolean "On". The file weighs 319 bytes.', 'Один Boolean «On». Файл весит 319 байт.'),
  ),
  _SmExample(
    title: tr('Robot', 'Робот'),
    source: const _RiveSource('little_machine.riv'),
    note: tr(
      'Trigger "Trigger 1" — the robot "processes data". The designer didn\'t '
          'rename the input — better to name it meaningfully.',
      'Trigger «Trigger 1» — робот «обрабатывает данные». Имя input '
          'дизайнер не поменял — лучше называть осмысленно.',
    ),
  ),
];

class _StateMachineBlock extends StatefulWidget {
  const _StateMachineBlock({super.key, required this.files});

  final _RiveFiles files;

  @override
  State<_StateMachineBlock> createState() => _StateMachineBlockState();
}

class _StateMachineBlockState extends State<_StateMachineBlock> with _RiveControllerHost {
  int _selected = 0;
  List<rive.Input> _inputs = const [];

  /// null — placeholder text (translates with the current language).
  String? _lastCode;

  @override
  _RiveFiles get files => widget.files;

  _SmExample get _example => _smExamples[_selected];

  @override
  void initState() {
    super.initState();
    loadSource(_example.source);
  }

  @override
  void onControllerReady(rive.RiveWidgetController controller) {
    _inputs = controller.stateMachine.inputs;
  }

  @override
  void onControllerRetired(rive.RiveWidgetController controller) {
    for (final input in _inputs) {
      input.dispose();
    }
    _inputs = const [];
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  void _changed(String code) {
    controller?.scheduleRepaint();
    setState(() => _lastCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = controller;
    final examples = _smExamples;
    return AnimBlock(
      title: tr('State Machine — the file is interactive, code turns the handles', 'State Machine — файл интерактивный, код дёргает ручки'),
      spec: () => {
        ...sourceSpec(_example.source),
        'fit': 'contain',
        'inputs': [
          for (final input in _inputs)
            switch (input) {
              rive.BooleanInput() => {
                'name': input.name,
                'type': 'Boolean',
                'value': input.value,
                'code': "stateMachine.boolean('${input.name}')?.value = ${input.value};",
              },
              rive.NumberInput() => {
                'name': input.name,
                'type': 'Number',
                'value': round2(input.value, 2),
                if (_example.ranges[input.name] case (final min, final max, final steps))
                  'range': {'min': min, 'max': max, 'step': steps > 0 ? (max - min) / steps : tr('smooth', 'плавно')},
                'code': "stateMachine.number('${input.name}')?.value = ${round2(input.value, 2)};",
              },
              rive.TriggerInput() => {
                'name': input.name,
                'type': 'Trigger',
                'code': "stateMachine.trigger('${input.name}')?.fire();",
              },
              _ => {'name': input.name, 'type': input.runtimeType.toString()},
            },
        ],
        if (_inputs.isEmpty) 'inputs_note': _example.note,
      },
      description: tr(
        'All the inputs the designer set up in the State Machine are read from '
            'the file and automatically turn into controls: Boolean → switch, '
            'Number → slider, Trigger → button. The app\'s code drives them the '
            'exact same way.',
        'Все inputs, которые дизайнер завёл в State Machine, читаются из файла '
            'и сами превращаются в контролы: Boolean → свитч, Number → слайдер, '
            'Trigger → кнопка. Ровно так же ими управляет код приложения.',
      ),
      preview: buildPreview(
        (c) => Listener(
          // Tapping the animation may change an input inside the file — refresh the controls.
          onPointerUp: (_) => setState(() {}),
          child: rive.RiveWidget(controller: c, fit: rive.Fit.contain),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, example) in examples.indexed)
                ChoiceChip(
                  label: Text(example.title),
                  selected: _selected == i,
                  onSelected: (_) {
                    setState(() {
                      _selected = i;
                      _lastCode = null;
                    });
                    loadSource(example.source);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_example.note, style: textTheme.bodySmall),
          if (c != null) ...[
            const SizedBox(height: 8),
            Text(
              tr(
                'File ${_example.source.asset} · artboard "${c.artboard.name}" · '
                    'state machine "${c.stateMachine.name}" · inputs: ${_inputs.length}',
                'Файл ${_example.source.asset} · artboard «${c.artboard.name}» · '
                    'state machine «${c.stateMachine.name}» · inputs: ${_inputs.length}',
              ),
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            for (final input in _inputs) _inputControl(input),
            if (_inputs.isEmpty)
              Text(tr('This state machine has no inputs.', 'У этой state machine нет inputs.'), style: textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          _CodeLine(_lastCode ?? tr('// Move the controls — code will appear here', '// Покрути контролы — здесь появится код')),
        ],
      ),
    );
  }

  Widget _inputControl(rive.Input input) {
    final textTheme = Theme.of(context).textTheme;
    final name = input.name;
    switch (input) {
      case rive.BooleanInput():
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(tr('Boolean "$name"', 'Boolean «$name»')),
          value: input.value,
          onChanged: (v) {
            input.value = v;
            _changed("stateMachine.boolean('$name')?.value = $v;");
          },
        );
      case rive.NumberInput():
        final (min, max, divisions) = _example.ranges[name] ?? (0.0, 100.0, 0);
        final value = input.value.clamp(min, max).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(tr('Number "$name"', 'Number «$name»'), style: textTheme.bodyMedium)),
                Text(value.toStringAsFixed(divisions > 0 ? 0 : 1), style: textTheme.bodySmall),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions > 0 ? divisions : null,
              onChanged: (v) {
                input.value = v;
                final shown = divisions > 0 ? v.round().toString() : v.toStringAsFixed(1);
                _changed("stateMachine.number('$name')?.value = $shown;");
              },
            ),
          ],
        );
      case rive.TriggerInput():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FilledButton.tonalIcon(
            onPressed: () {
              input.fire();
              _changed("stateMachine.trigger('$name')?.fire();");
            },
            icon: const Icon(Icons.bolt),
            label: Text(tr('Trigger "$name"', 'Trigger «$name»')),
          ),
        );
      default:
        return Text(tr('Input "$name" (${input.runtimeType})', 'Input «$name» (${input.runtimeType})'), style: textTheme.bodySmall);
    }
  }
}

// ──────────────────────────────────────────────────────── Fit and Alignment

Map<rive.Fit, String> get _fitNames => {
  rive.Fit.contain: tr('contain — whole, with margins', 'contain — целиком, с полями'),
  rive.Fit.cover: tr('cover — fill, cropping edges', 'cover — заполнить, обрезая края'),
  rive.Fit.fill: tr('fill — stretch (distorts proportions)', 'fill — растянуть (искажает пропорции)'),
  rive.Fit.fitWidth: tr('fitWidth — by width', 'fitWidth — по ширине'),
  rive.Fit.fitHeight: tr('fitHeight — by height', 'fitHeight — по высоте'),
  rive.Fit.none: tr('none — original artboard size', 'none — исходный размер артборда'),
  rive.Fit.scaleDown: tr('scaleDown — shrink only', 'scaleDown — только уменьшать'),
  rive.Fit.layout: tr('layout — artboard adapts (Layouts in the editor)', 'layout — артборд подстраивается (Layouts в редакторе)'),
};

const _alignments = <Alignment>[
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

class _FitBlock extends StatefulWidget {
  const _FitBlock({super.key, required this.files});

  final _RiveFiles files;

  @override
  State<_FitBlock> createState() => _FitBlockState();
}

class _FitBlockState extends State<_FitBlock> with _RiveControllerHost {
  rive.Fit _fit = rive.Fit.contain;
  Alignment _alignment = Alignment.center;
  double _widthFactor = 1;
  double _heightFactor = 1;

  @override
  _RiveFiles get files => widget.files;

  @override
  void initState() {
    super.initState();
    loadSource(const _RiveSource('rating.riv'));
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AnimBlock(
      title: tr('Fit and Alignment — how to fit the artboard', 'Fit и Alignment — как вписать артборд'),
      spec: () => {
        ...sourceSpec(const _RiveSource('rating.riv')),
        'fit': _fit.name,
        'alignment': _alignmentName(_alignment),
        'artboard_size_px': {'width': 500, 'height': 500},
        'container_size_percent': {
          'width': (_widthFactor * 100).round(),
          'height': (_heightFactor * 100).round(),
        },
      },
      description: tr(
        'The artboard is square (500×500), while the space for the animation in '
            'the interface can be anything. Fit decides whether to stretch, crop or '
            'keep margins; Alignment — which edge to hug. Change the container size '
            '(the dashed frame) to see the difference.',
        'Артборд квадратный (500×500), а место под анимацию в интерфейсе — '
            'любое. Fit решает, растягивать, обрезать или оставлять поля, '
            'Alignment — к какому краю прижать. Меняй размер контейнера '
            '(пунктирная рамка), чтобы увидеть разницу.',
      ),
      preview: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: Container(
            width: constraints.maxWidth * _widthFactor,
            height: constraints.maxHeight * _heightFactor,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              border: Border.all(color: colors.primary, width: 1.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: buildPreview(
              (c) => rive.RiveWidget(controller: c, fit: _fit, alignment: _alignment),
            ),
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fit', style: textTheme.titleSmall),
          DropdownButton<rive.Fit>(
            isExpanded: true,
            value: _fit,
            items: [
              for (final MapEntry(key: fit, value: label) in _fitNames.entries)
                DropdownMenuItem(value: fit, child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _fit = v);
            },
          ),
          const SizedBox(height: 8),
          Text('Alignment', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          SizedBox(
            width: 120,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final a in _alignments)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => _alignment = a),
                    child: Container(
                      decoration: BoxDecoration(
                        color: a == _alignment ? kAccent : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FactorSlider(
            label: tr('Container width', 'Ширина контейнера'),
            value: _widthFactor,
            onChanged: (v) => setState(() => _widthFactor = v),
          ),
          _FactorSlider(
            label: tr('Container height', 'Высота контейнера'),
            value: _heightFactor,
            onChanged: (v) => setState(() => _heightFactor = v),
          ),
          const SizedBox(height: 4),
          _CodeLine(
            'RiveWidget(controller: c, fit: Fit.${_fit.name}, '
            'alignment: Alignment.${_alignmentName(_alignment)})',
          ),
        ],
      ),
    );
  }

  String _alignmentName(Alignment a) {
    const names = [
      'topLeft', 'topCenter', 'topRight', //
      'centerLeft', 'center', 'centerRight',
      'bottomLeft', 'bottomCenter', 'bottomRight',
    ];
    return names[_alignments.indexOf(a)];
  }
}

class _FactorSlider extends StatelessWidget {
  const _FactorSlider({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: textTheme.bodyMedium)),
            Text('${(value * 100).round()} %', style: textTheme.bodySmall),
          ],
        ),
        Slider(value: value, min: 0.3, max: 1, onChanged: onChanged),
      ],
    );
  }
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

const _alignmentByName = <String, Alignment>{
  'center': Alignment.center,
  'topLeft': Alignment.topLeft,
  'topCenter': Alignment.topCenter,
  'topRight': Alignment.topRight,
  'bottomLeft': Alignment.bottomLeft,
  'bottomCenter': Alignment.bottomCenter,
  'bottomRight': Alignment.bottomRight,
};

/// The real rating.riv file from the screen's already-loaded file set: the
/// Number input with the entered name gets the entered value, Fit and
/// Alignment come from the fields. If Rive fails to start (no network,
/// flutter test) — the same fallback as above.
class _RivePlaygroundPreview extends StatefulWidget {
  const _RivePlaygroundPreview({
    super.key,
    required this.files,
    required this.inputName,
    required this.value,
    required this.fit,
    required this.alignment,
  });

  final _RiveFiles files;
  final String inputName;
  final double value;
  final String fit;
  final String alignment;

  @override
  State<_RivePlaygroundPreview> createState() => _RivePlaygroundPreviewState();
}

class _RivePlaygroundPreviewState extends State<_RivePlaygroundPreview> with _RiveControllerHost {
  rive.NumberInput? _input;
  String? _inputFor;

  @override
  _RiveFiles get files => widget.files;

  @override
  void initState() {
    super.initState();
    loadSource(const _RiveSource('rating.riv'));
  }

  @override
  void onControllerReady(rive.RiveWidgetController controller) {
    _bind(controller);
  }

  @override
  void onControllerRetired(rive.RiveWidgetController controller) {
    _input?.dispose();
    _input = null;
    _inputFor = null;
  }

  /// Finds the input by name and sets the value (the name may have been renamed).
  void _bind(rive.RiveWidgetController c) {
    if (_inputFor != widget.inputName) {
      _input?.dispose();
      _input = c.stateMachine.number(widget.inputName);
      _inputFor = widget.inputName;
    }
    final input = _input;
    if (input != null && input.value != widget.value) {
      input.value = widget.value;
      c.scheduleRepaint();
    }
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c != null) _bind(c);
    final fit = rive.Fit.values.firstWhere((f) => f.name == widget.fit, orElse: () => rive.Fit.contain);
    return Column(
      children: [
        Expanded(
          child: buildPreview(
            (c) => rive.RiveWidget(
              controller: c,
              fit: fit,
              alignment: _alignmentByName[widget.alignment] ?? Alignment.center,
            ),
          ),
        ),
        if (c != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _input == null
                  ? tr(
                      'Number-input "${widget.inputName}" not found in the file',
                      'Number-input «${widget.inputName}» в файле не найден',
                    )
                  : 'rating.riv · "${c.stateMachine.name}" · ${widget.inputName} = ${widget.value}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
