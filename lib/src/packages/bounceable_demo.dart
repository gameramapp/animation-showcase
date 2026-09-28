// Showcase of the flutter_bounceable package: an iOS-like "springy" press.
//   • Settings — compression depth, press/release durations and curves;
//     applied to all examples on screen;
//   • On different elements — button, card, icon, list row, photo, tags;
//   • Comparison — plain Material InkWell (ripple) vs Bounceable (squeeze);
//   • Presets — ready-made parameter sets "from light to deep".
//
// The package is pure Dart/Flutter (GestureDetector + ScaleTransition),
// fully web-compatible.

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

/// A set of Bounceable parameters — one for the whole screen.
class _BounceParams {
  const _BounceParams({
    this.scaleFactor = 0.8,
    this.pressMs = 200,
    this.releaseMs = 200,
    this.pressCurve = 'decelerate',
    this.releaseCurve = 'decelerate',
  });

  final double scaleFactor;
  final int pressMs;
  final int releaseMs;
  final String pressCurve;
  final String releaseCurve;

  _BounceParams copyWith({
    double? scaleFactor,
    int? pressMs,
    int? releaseMs,
    String? pressCurve,
    String? releaseCurve,
  }) => _BounceParams(
    scaleFactor: scaleFactor ?? this.scaleFactor,
    pressMs: pressMs ?? this.pressMs,
    releaseMs: releaseMs ?? this.releaseMs,
    pressCurve: pressCurve ?? this.pressCurve,
    releaseCurve: releaseCurve ?? this.releaseCurve,
  );

  /// Bounceable creates its controller only once, so the widget needs to be
  /// recreated on parameter changes — we do that via a key.
  Key get key => ValueKey('$scaleFactor-$pressMs-$releaseMs-$pressCurve-$releaseCurve');

  /// The package's curve applies directly to the scale value (from scaleFactor
  /// to 1). Once the squeeze is done and the finger is held, CurvedAnimation
  /// switches to the forward curve (curve), so the visible scale = curve(scaleFactor).
  double get visualScale => resolveCurve(releaseCurve).transform(scaleFactor);

  // Outer KeyedSubtree with no key — so several wrappers can sit next to
  // each other in the same Row/Wrap without colliding on identical keys.
  Widget wrap(Widget child, {VoidCallback? onTap}) => KeyedSubtree(
    child: Bounceable(
      key: key,
      onTap: onTap ?? () {},
      scaleFactor: scaleFactor,
      reverseDuration: Duration(milliseconds: pressMs),
      reverseCurve: resolveCurve(pressCurve),
      duration: Duration(milliseconds: releaseMs),
      curve: resolveCurve(releaseCurve),
      child: child,
    ),
  );

  String get code =>
      'Bounceable(\n'
      '  scaleFactor: ${scaleFactor.toStringAsFixed(2)},\n'
      '  reverseDuration: Duration(milliseconds: $pressMs),\n'
      '  reverseCurve: ${curveCode(pressCurve)},\n'
      '  duration: Duration(milliseconds: $releaseMs),\n'
      '  curve: ${curveCode(releaseCurve)},\n'
      '  onTap: () {…},\n'
      '  child: …,\n'
      ')';

  /// The "spec" in Bounceable parameter names.
  Map<String, Object?> spec() => {
    'package': packageSpec('flutter_bounceable'),
    'widget': 'Bounceable',
    'scale_factor': scaleFactor,
    'visual_scale_when_held': round2(visualScale, 3),
    'press_tap_down': {
      'param_duration': 'reverseDuration',
      'param_curve': 'reverseCurve',
      ...timingSpec(durationMs: pressMs, curve: pressCurve),
      'curve_dart': curveCode(pressCurve),
    },
    'release_tap_up': {
      'param_duration': 'duration',
      'param_curve': 'curve',
      ...timingSpec(durationMs: releaseMs, curve: releaseCurve),
      'curve_dart': curveCode(releaseCurve),
    },
    'note': tr(
      'The curve applies to the scale value (from scale_factor to 1), '
      'so the visible squeeze = visual_scale_when_held.',
      'Кривая применяется к значению масштаба (от scale_factor до 1), '
      'поэтому видимое сжатие = visual_scale_when_held.',
    ),
  };
}

class BounceableDemo extends StatefulWidget {
  const BounceableDemo({super.key});
  static const String routeName = 'packages/bounceable';

  @override
  State<BounceableDemo> createState() => _BounceableDemoState();
}

class _BounceableDemoState extends State<BounceableDemo> {
  _BounceParams _params = const _BounceParams();
  int _taps = 0;

  void _onTap() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_bounceable'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Package flutter_bounceable', 'Пакет flutter_bounceable'),
            text: tr(
              'One wrapper and any element "sinks in" on press and springs '
              'back, like buttons in iOS and games. No controllers to write: '
              'Bounceable(onTap: …, child: …). Works with buttons, cards, '
              'icons, images. The package is fully web-compatible (pure '
              'Flutter).',
              'Одна обёртка — и любой элемент при нажатии «проседает» и '
              'пружинисто возвращается, как кнопки в iOS и играх. Не нужно '
              'писать контроллеры: Bounceable(onTap: …, child: …). Работает '
              'с кнопками, карточками, иконками, картинками. Пакет '
              'полностью web-совместим (чистый Flutter).',
            ),
            hint: tr(
              'Press and hold any element on the screen. The sliders in the '
              'first block change the response for all examples at once.',
              'Нажимай и удерживай любой элемент на экране. Ползунки в первом '
              'блоке меняют отклик сразу у всех примеров.',
            ),
          ),
          const SizedBox(height: 16),
          _SettingsBlock(
            params: _params,
            taps: _taps,
            onTap: _onTap,
            onChanged: (p) => setState(() => _params = p),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(tr('On different elements', 'На разных элементах'), style: textTheme.titleLarge),
              ),
              SpecButton(
                title: tr('Bounceable on different elements', 'Bounceable на разных элементах'),
                spec: () => {
                  ..._params.spec(),
                  'elements': tr(
                    'button, card, icon, list row, image, tags',
                    'кнопка, карточка, иконка, строка списка, изображение, теги',
                  ),
                  'hint': tr(
                    'Large elements (card) only need scale_factor ≈ 0.95, small '
                    'ones (icon) can go down to 0.8.',
                    'Крупным элементам (карточка) достаточно scale_factor ≈ 0.95, '
                    'мелким (иконка) — до 0.8.',
                  ),
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Same settings as above. Notice that the larger the element, the '
              'less squeeze it needs — 0.95 is already visible on a card, while '
              'an icon can take 0.8.',
              'Те же настройки, что выше. Обрати внимание: чем крупнее элемент, '
              'тем меньше нужно сжатие — у карточки 0.95 уже заметно, у иконки '
              'можно 0.8.',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _ElementsGrid(params: _params, onTap: _onTap),
          const SizedBox(height: 16),
          _ComparisonBlock(params: _params),
          const SizedBox(height: 16),
          Text(tr('Presets', 'Пресеты'), style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            tr(
              'Ready-made parameter sets. Tap "Apply" to bring a preset into '
              'the whole screen\'s settings.',
              'Готовые наборы параметров. Тапни «Применить», чтобы перенести '
              'пресет в настройки всего экрана.',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _PresetsGrid(onApply: (p) => setState(() => _params = p)),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.number(
                  'scaleFactor',
                  tr('scaleFactor — squeeze', 'scaleFactor — сжатие'),
                  0.8,
                  unit: '×',
                  min: 0,
                  max: 1,
                ),
                BriefField.duration('reverseDuration_ms', tr('Press (reverseDuration)', 'Нажатие (reverseDuration)'), 200),
                BriefField.curve('reverseCurve', tr('Press curve (reverseCurve)', 'Кривая нажатия (reverseCurve)'), 'decelerate'),
                BriefField.duration('duration_ms', tr('Release (duration)', 'Отпускание (duration)'), 200),
                BriefField.curve('curve', tr('Release curve (curve)', 'Кривая отпускания (curve)'), 'decelerate'),
                BriefField.color('color', tr('Button color', 'Цвет кнопки'), '#673AB7'),
              ],
              builder: _bouncePlayground,
            ),
            items: [
              (
                tr('Which elements spring', 'Какие элементы пружинят'),
                tr(
                  'buttons, cards, icons, list rows — list them or mark them on the mockup',
                  'кнопки, карточки, иконки, строки списка — перечисли или отметь в макете',
                ),
              ),
              (
                'scaleFactor',
                tr(
                  'squeeze depth for each element type: 0.95 for large cards, 0.8–0.9 for icons and CTAs',
                  'глубина сжатия для каждого типа элемента: 0.95 для крупных карточек, 0.8–0.9 для иконок и CTA',
                ),
              ),
              (
                tr('Press (reverseDuration + reverseCurve)', 'Нажатие (reverseDuration + reverseCurve)'),
                tr(
                  'how many ms and along which curve the element sinks under the finger',
                  'сколько мс и по какой кривой элемент проседает под пальцем',
                ),
              ),
              (
                tr('Release (duration + curve)', 'Отпускание (duration + curve)'),
                tr(
                  'how many ms and along which curve it returns to 1.0; a cubic-bezier from Figma works too',
                  'сколько мс и по какой кривой возвращается к 1.0; можно cubic-bezier из Figma',
                ),
              ),
              (
                tr('Extra feedback', 'Доп. отклик'),
                tr(
                  'whether a color/shadow change is needed on press — the package does not draw one itself',
                  'нужна ли смена цвета/тени при нажатии — пакет сам его не рисует',
                ),
              ),
              (
                tr('Reference', 'Референс'),
                tr(
                  'a video or Figma prototype of the press, if you want "like in iOS / game X"',
                  'видео или прототип Figma с нажатием, если хочется «как в iOS/игре X»',
                ),
              ),
            ],
            avoid: [
              tr(
                'Different curves for press and release without checking — the package shows a visible scale jump.',
                'Разные кривые на нажатие и отпускание без проверки — у пакета заметен скачок масштаба.',
              ),
              tr(
                'Squeeze stronger than 0.7 on large elements — looks like a layout bug.',
                'Сжатие сильнее 0.7 на крупных элементах — выглядит как баг вёрстки.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── settings

class _SettingsBlock extends StatelessWidget {
  const _SettingsBlock({
    required this.params,
    required this.taps,
    required this.onTap,
    required this.onChanged,
  });

  final _BounceParams params;
  final int taps;
  final VoidCallback onTap;
  final ValueChanged<_BounceParams> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimBlock(
      title: tr('Response settings', 'Настройки отклика'),
      spec: () => {
        ...params.spec(),
        'element': {
          'padding_px': {'horizontal': 32, 'vertical': 18},
          'border_radius_px': 18,
          'color': hexColor(kAccent),
          'shadow': {'color': hexColor(Colors.black26), 'blur_px': 10, 'offset_y_px': 4},
        },
      },
      description: tr(
        'Press: the element squeezes to scaleFactor over reverseDuration. '
        'Release: it returns to 1.0 over duration. Fits any tappable '
        'element that needs a tactile "physical" response instead of the '
        'Material ripple.',
        'Нажатие: элемент сжимается до scaleFactor за reverseDuration. '
        'Отпускание: возвращается к 1.0 за duration. Подходит для любых '
        'кликабельных элементов, где нужен тактильный «физический» отклик '
        'вместо ряби Material.',
      ),
      preview: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          params.wrap(
            onTap: onTap,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Text(
                tr('Press me', 'Нажми меня'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('Taps: $taps', 'Нажатий: $taps'), style: textTheme.bodySmall),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            label: tr('scaleFactor — squeeze depth', 'scaleFactor — глубина сжатия'),
            value: params.scaleFactor,
            min: 0.5,
            max: 1,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) =>
                onChanged(params.copyWith(scaleFactor: (v * 100).round() / 100)),
          ),
          Text(
            tr(
              'Actual scale while held: ×${params.visualScale.toStringAsFixed(2)}. '
              'A package quirk: the curve applies to the scale value itself, so '
              'decelerate 0.8 only gives ~0.96. For an exact value without '
              'jumps, use the same curve on both sides — linear is simplest.',
              'Фактический масштаб при удержании: '
              '×${params.visualScale.toStringAsFixed(2)}. Особенность пакета: '
              'кривая применяется к самому значению масштаба, поэтому с '
              'decelerate 0.8 даёт лишь ~0.96. Для точного значения и без '
              'скачков ставь одинаковые кривые, проще всего — linear.',
            ),
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(tr('Press (finger down)', 'Нажатие (палец вниз)'), style: textTheme.titleSmall),
          LabeledSlider(
            label: 'reverseDuration',
            value: params.pressMs.toDouble(),
            min: 30,
            max: 800,
            unit: tr('ms', 'мс'),
            onChanged: (v) => onChanged(params.copyWith(pressMs: v.round())),
          ),
          CurveDropdown(
            value: params.pressCurve,
            onChanged: (v) => onChanged(params.copyWith(pressCurve: v)),
          ),
          const SizedBox(height: 12),
          Text(tr('Release (finger up)', 'Отпускание (палец вверх)'), style: textTheme.titleSmall),
          LabeledSlider(
            label: 'duration',
            value: params.releaseMs.toDouble(),
            min: 30,
            max: 1200,
            unit: tr('ms', 'мс'),
            onChanged: (v) => onChanged(params.copyWith(releaseMs: v.round())),
          ),
          CurveDropdown(
            value: params.releaseCurve,
            onChanged: (v) => onChanged(params.copyWith(releaseCurve: v)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged(const _BounceParams()),
              icon: const Icon(Icons.restart_alt),
              label: Text(tr('Reset to package defaults', 'Сбросить к значениям пакета')),
            ),
          ),
          const SizedBox(height: 8),
          _CodeBox(params.code),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── different elements

class _ElementsGrid extends StatelessWidget {
  const _ElementsGrid({required this.params, required this.onTap});

  final _BounceParams params;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ResponsiveWrap(
      minTileWidth: 240,
      children: [
        ShowcaseTile(
          title: tr('Button', 'Кнопка'),
          caption: tr(
            'The main CTA: "Buy", "Continue". The most common case.',
            'Главный CTA: «Купить», «Продолжить». Самый частый случай.',
          ),
          child: params.wrap(
            onTap: onTap,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFFA726)]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                tr('Buy', 'Купить'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        ShowcaseTile(
          title: tr('Card', 'Карточка'),
          caption: tr(
            'A product, plan, game level — the whole card acts as one button.',
            'Товар, тариф, уровень в игре — вся карточка как одна кнопка.',
          ),
          child: params.wrap(
            onTap: onTap,
            Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.diamond, color: kAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Premium', 'Премиум'),
                          style: textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tr('\$4.99/mo', '299 ₽/мес'),
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ShowcaseTile(
          title: tr('Icon', 'Иконка'),
          caption: tr(
            'Round icon buttons: favorite, settings, close.',
            'Круглые иконки-кнопки: избранное, настройки, закрыть.',
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (icon, color) in const [
                (Icons.favorite, Colors.pink),
                (Icons.settings, Colors.blueGrey),
                (Icons.share, Colors.teal),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: params.wrap(
                    onTap: onTap,
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ShowcaseTile(
          title: tr('List row', 'Строка списка'),
          caption: tr(
            'A ListTile in settings or chats — a response without a ripple.',
            'ListTile в настройках или чатах — отклик без ряби.',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: params.wrap(
              onTap: onTap,
              Material(
                color: Colors.white,
                elevation: 1,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kAccent,
                    child: Text(tr('A', 'А'), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(tr('Anna', 'Анна'), overflow: TextOverflow.ellipsis),
                  subtitle: Text(tr('Hi! How are you?', 'Привет! Как дела?'), overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ),
        ),
        ShowcaseTile(
          title: tr('Image', 'Изображение'),
          caption: tr(
            'Photo previews, covers, banners — "press in" under the finger.',
            'Превью фото, обложки, баннеры — «вдавливаются» под пальцем.',
          ),
          child: params.wrap(
            onTap: onTap,
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/eat_sydney_sm.jpg',
                width: 180,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        ShowcaseTile(
          title: tr('Tags / chips', 'Теги / чипы'),
          caption: tr(
            'Filters and tags — each one springs on its own.',
            'Фильтры и теги — каждый пружинит отдельно.',
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final tag in [
                tr('Pizza', 'Пицца'),
                tr('Sushi', 'Суши'),
                tr('Burgers', 'Бургеры'),
                tr('Salads', 'Салаты'),
              ])
                params.wrap(
                  onTap: onTap,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: kAccent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: const TextStyle(color: kAccent)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────── comparison

class _ComparisonBlock extends StatelessWidget {
  const _ComparisonBlock({required this.params});

  final _BounceParams params;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: textTheme.bodySmall, textAlign: TextAlign.center),
    );

    return AnimBlock(
      title: tr('Comparison: InkWell vs Bounceable', 'Сравнение: InkWell против Bounceable'),
      spec: () => {
        'left': {
          'widget': 'Material + InkWell',
          'color': hexColor(kAccent),
          'border_radius_px': 16,
          'splash_color': hexColor(Colors.white38),
        },
        'right': {
          ...params.spec(),
          'color': hexColor(kAccent),
          'border_radius_px': 16,
        },
        'button_padding_px': {'horizontal': 22, 'vertical': 16},
      },
      description: tr(
        'On the left — the standard Material response: the button stays put '
        'and a "ripple" spreads across it. On the right — Bounceable: the '
        'button physically squeezes. Ripple is Android/Material\'s language, '
        'bounce is iOS, games, kids\' and "friendly" products. Try pressing '
        'both in turn.',
        'Слева — стандартный Material-отклик: кнопка на месте, по ней '
        'расходится «рябь» (ripple). Справа — Bounceable: кнопка физически '
        'сжимается. Ripple — язык Android/Material, bounce — iOS, игры, '
        'детские и «дружелюбные» продукты. Понажимай обе по очереди.',
      ),
      preview: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {},
                    splashColor: Colors.white38,
                    child: const _CompareButtonBody(),
                  ),
                ),
                label(tr('InkWell\n(ripple)', 'InkWell\n(рябь)')),
              ],
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                params.wrap(
                  Container(
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const _CompareButtonBody(),
                  ),
                ),
                label(tr('Bounceable\n(squeeze)', 'Bounceable\n(сжатие)')),
              ],
            ),
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('When to pick which', 'Когда что выбирать'), style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            tr(
              '• Material app, strict style, dense lists → InkWell.\n'
              '• iOS style, games, promos, large cards and CTAs → Bounceable.\n'
              '• Bounceable doesn\'t draw a ripple or change color — if you also '
              'need a color response, add it separately.\n'
              '• Bounceable\'s parameters come from the "Response settings" block.',
              '• Material-приложение, строгий стиль, плотные списки → InkWell.\n'
              '• iOS-стиль, игры, промо, крупные карточки и CTA → Bounceable.\n'
              '• Bounceable не рисует рябь и не меняет цвет — если нужен ещё и '
              'цветовой отклик, добавь его отдельно.\n'
              '• Параметры Bounceable берутся из блока «Настройки отклика».',
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const _CodeBox(
            'InkWell(onTap: …, child: …)\n'
            'Bounceable(onTap: …, child: …)',
          ),
        ],
      ),
    );
  }
}

class _CompareButtonBody extends StatelessWidget {
  const _CompareButtonBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Text(
        tr('Done', 'Готово'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────── presets

/// Preset caption with the current parameters appended.
String _presetCaption(String caption, _BounceParams params) {
  final msLabel = tr('ms', 'мс');
  return '$caption\nscale ${params.scaleFactor}, '
      '${params.pressMs}/${params.releaseMs} $msLabel, '
      '${params.pressCurve}/${params.releaseCurve}';
}

class _PresetsGrid extends StatelessWidget {
  const _PresetsGrid({required this.onApply});

  final ValueChanged<_BounceParams> onApply;

  static List<(String, String, _BounceParams)> get _presets => [
    (
      tr('Light (iOS)', 'Лёгкий (iOS)'),
      tr(
        'A barely noticeable squeeze — system buttons, list rows.',
        'Едва заметное сжатие — системные кнопки, строки списков.',
      ),
      const _BounceParams(scaleFactor: 0.95, pressMs: 80, releaseMs: 150, pressCurve: 'linear', releaseCurve: 'linear'),
    ),
    (
      tr('Package default', 'По умолчанию пакета'),
      tr(
        'scaleFactor 0.8, 200 ms, decelerate. Visually ≈ ×0.96.',
        'scaleFactor 0.8, 200 мс, decelerate. Визуально ≈ ×0.96.',
      ),
      const _BounceParams(),
    ),
    (
      tr('Noticeable', 'Заметный'),
      tr(
        'A distinct "click" for CTAs and product cards.',
        'Чёткий «клик» для CTA и карточек товаров.',
      ),
      const _BounceParams(scaleFactor: 0.88, pressMs: 100, releaseMs: 250, pressCurve: 'linear', releaseCurve: 'linear'),
    ),
    (
      tr('Deep (game-like)', 'Глубокий (игровой)'),
      tr(
        'A strong squeeze and a slow return — games, kids\' apps.',
        'Сильное сжатие и медленный возврат — игры, детские приложения.',
      ),
      const _BounceParams(scaleFactor: 0.72, pressMs: 120, releaseMs: 450, pressCurve: 'linear', releaseCurve: 'linear'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrap(
      minTileWidth: 240,
      children: [
        for (final (title, caption, params) in _presets)
          ShowcaseTile(
            title: title,
            caption: _presetCaption(caption, params),
            previewHeight: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                params.wrap(
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.touch_app, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => onApply(params),
                      child: Text(tr('Apply', 'Применить')),
                    ),
                    SpecButton(
                      title: 'Bounceable — $title',
                      spec: () => {...params.spec(), 'preset': title},
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
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

/// Press → hold → release with the package's math: the controller moves
/// linearly between scaleFactor and 1, and the curve applies to the scale
/// value itself (reverseCurve on press, curve on hold and release).
Widget _bouncePlayground(BuildContext context, BriefValues v, double t) {
  final sf = v.number('scaleFactor');
  final press = v.ms('reverseDuration_ms');
  final release = v.ms('duration_ms');
  const hold = 350;
  double curved(Curve c, double value) => value <= 0 || value >= 1 ? value : c.transform(value);
  return LoopClock(
    periodMs: press + hold + release,
    builder: (context, ms) {
      final String label;
      final double scale;
      if (ms < press) {
        label = tr('press', 'нажатие');
        scale = curved(v.curve('reverseCurve'), 1 - (1 - sf) * phase(ms, 0, press));
      } else if (ms < press + hold) {
        label = tr('hold', 'удержание');
        scale = curved(v.curve('curve'), sf);
      } else {
        label = ms >= press + hold + release ? tr('idle', 'покой') : tr('release', 'отпускание');
        scale = curved(v.curve('curve'), sf + (1 - sf) * phase(ms, press + hold, release));
      }
      final scaleLabel = tr('scale', 'масштаб');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: v.color('color'),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Text(
                tr('Press me', 'Нажми меня'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$label · $scaleLabel ×${scale.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );
}
