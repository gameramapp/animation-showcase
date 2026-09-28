// Showcase of the flutter_tilt package: 3D tilt of an element following the
// cursor/finger, with a light glare and a dynamic shadow.
//   • Tilt and motion — angle, reverse, axis restriction, return speed;
//   • Light and shadow — glare intensity and direction, shadow strength/offset/blur;
//   • Medal — a round badge with a metallic glare and a projected shadow;
//   • Parallax — layers inside the card move at different depths (TiltParallax);
//   • Gallery — how it looks in a grid of cards (hover/touch only).
//
// Auto-demo: TiltController.move() along a Lissajous curve. The package's
// gesture priority is touch > hover > controller > sensors, so the
// cursor/finger immediately take over control, and the auto-demo resumes
// after they leave.
//
// Web: hover/touch tilt works everywhere. The gyroscope (sensors_plus) in the
// web uses the Generic Sensor API — only Chromium browsers on Android;
// Safari/iOS, Firefox, and desktop don't provide sensor data.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class TiltDemo extends StatelessWidget {
  const TiltDemo({super.key});
  static const String routeName = 'packages/tilt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_tilt'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('The flutter_tilt package', 'Пакет flutter_tilt'),
            text: tr(
              'A card tilts in 3D following the cursor or a finger, a glare '
              'slides across it, and a shadow shifts the opposite way — the '
              '"physical" card effect, like on Apple TV or collectible cards. '
              'Parallax layers can be placed inside. The package is '
              'web-compatible; the gyroscope in the browser only works in '
              'Chrome on Android.',
              'Карточка наклоняется в 3D вслед за курсором или пальцем, по ней '
                  'скользит блик, а тень смещается в противоположную сторону — '
                  'эффект «физической» карточки, как у Apple TV или '
                  'коллекционных карт. Внутрь можно положить слои с параллаксом. '
                  'Пакет web-совместим; гироскоп в браузере работает только в '
                  'Chrome на Android.',
            ),
            hint: tr(
              'The cards wobble on their own. Hover the cursor or drag with a '
              'finger — control switches to you.',
              'Карточки покачиваются сами. Наведи курсор или потяни пальцем — '
                  'управление перейдёт к тебе.',
            ),
          ),
          const SizedBox(height: 16),
          _MotionBlock(),
          const SizedBox(height: 16),
          _LightShadowBlock(),
          const SizedBox(height: 16),
          _MedalBlock(),
          const SizedBox(height: 16),
          _ParallaxBlock(),
          const SizedBox(height: 16),
          _GalleryBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              durationKey: 'leaveDuration_ms',
              fields: [
                BriefField.number('angle', tr('angle — tilt angle', 'angle — угол наклона'), 10, unit: '°', min: 0, max: 60),
                BriefField.duration('leaveDuration_ms', tr('Return (leaveDuration)', 'Возврат (leaveDuration)'), 300),
                BriefField.curve('leaveCurve', tr('Return curve (leaveCurve)', 'Кривая возврата (leaveCurve)'), 'linear'),
                BriefField.number('light', tr('Glare maxIntensity', 'Блик maxIntensity'), 0.4, min: 0, max: 1),
                BriefField.color('light_color', tr('Glare color', 'Цвет блика'), '#FFFFFF'),
                BriefField.number('shadow', tr('Shadow maxIntensity', 'Тень maxIntensity'), 0.5, min: 0, max: 1),
                BriefField.number('shadow_blur', tr('Shadow maxBlurRadius', 'Тень maxBlurRadius'), 30, unit: 'px', min: 0, max: 100),
                BriefField.color('card_color', tr('Card color', 'Цвет карточки'), '#673AB7'),
              ],
              builder: _tiltPlayground,
            ),
            items: [
              (
                'angle',
                tr(
                  'max tilt angle in degrees (5–10° is subdued, 20–30° is playful); reverse — yes/no',
                  'максимальный угол наклона в градусах (5–10° спокойно, 20–30° игриво); реверс — да/нет',
                ),
              ),
              (
                tr('Axes', 'Оси'),
                tr(
                  'tilt on both axes, or only horizontal/vertical (direction)',
                  'наклон по обеим осям или только по горизонтали/вертикали (direction)',
                ),
              ),
              (
                tr('Return and entry', 'Возврат и вход'),
                tr(
                  'leaveDuration + leaveCurve and enterToMoveDuration + enterToMoveCurve (ms and curve)',
                  'leaveDuration + leaveCurve и enterToMoveDuration + enterToMoveCurve (мс и кривая)',
                ),
              ),
              (
                tr('Glare (LightConfig)', 'Блик (LightConfig)'),
                tr(
                  'color #hex, maxIntensity 0–1, spreadFactor, direction — where the light comes from',
                  'цвет #hex, maxIntensity 0–1, spreadFactor, direction — откуда свет',
                ),
              ),
              (
                tr('Shadow (ShadowBaseConfig)', 'Тень (ShadowBaseConfig)'),
                tr(
                  'color #hex, maxIntensity, offsetFactor, maxBlurRadius in px — or a projected shadow',
                  'цвет #hex, maxIntensity, offsetFactor, maxBlurRadius в px — или тень-проекция',
                ),
              ),
              (
                tr('Parallax layers', 'Параллакс-слои'),
                tr(
                  'which layers are separate (background / text / badge), each layer\'s '
                  'TiltParallax offset in px, what goes past the edge',
                  'какие слои отдельно (фон / текст / бейдж), сдвиг каждого TiltParallax offset в px, что выходит за край',
                ),
              ),
              (
                tr('Gyroscope', 'Гироскоп'),
                tr(
                  'is tilt from the phone sensors needed (on the web — only Chrome on Android)',
                  'нужен ли наклон от датчиков телефона (в вебе — только Chrome на Android)',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't rely on the gyroscope on the web on iOS/desktop — it doesn't work there.",
                'Рассчитывать на гироскоп в вебе на iOS/десктопе — там он не работает.',
              ),
              tr(
                'A strong tilt in long feeds on a phone — the finger tilts the card '
                'instead of scrolling.',
                'Сильный наклон в длинных лентах на телефоне — палец наклоняет карточку вместо скролла.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────── auto-demo

/// Automatic "wobble": every frame sends TiltController a position on a
/// Lissajous curve inside the [size] area.
class _AutoTilt {
  _AutoTilt(this.size);

  final Size size;
  final controller = TiltController();
  Timer? _timer;
  double _t = 0;

  bool get running => _timer != null;

  void start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      _t += 0.016;
      controller.move(
        position: Offset(
          size.width / 2 + math.cos(_t * 1.3) * size.width * 0.45,
          size.height / 2 + math.sin(_t * 1.9) * size.height * 0.45,
        ),
      );
    });
  }

  void stop() {
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;
    controller.leave(position: size.center(Offset.zero));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    controller.dispose();
  }
}

/// Shared State mixin: creates [_AutoTilt], starts it, and disposes it properly.
mixin _AutoTiltState<T extends StatefulWidget> on State<T> {
  Size get tiltSize;
  late final _AutoTilt autoTilt = _AutoTilt(tiltSize);
  bool auto = true;

  @override
  void initState() {
    super.initState();
    autoTilt.start();
  }

  void setAuto(bool value) {
    setState(() => auto = value);
    value ? autoTilt.start() : autoTilt.stop();
  }

  Widget autoChip() => FilterChip(
    label: Text(tr('Auto', 'Авто')),
    selected: auto,
    onSelected: setAuto,
  );

  @override
  void dispose() {
    autoTilt.dispose();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────── tilt and motion

class _MotionBlock extends StatefulWidget {
  const _MotionBlock();

  @override
  State<_MotionBlock> createState() => _MotionBlockState();
}

class _MotionBlockState extends State<_MotionBlock> with _AutoTiltState {
  static const _size = Size(220, 140);
  @override
  Size get tiltSize => _size;

  double _angle = 10;
  bool _reverse = false;
  bool _gyro = false;
  bool _horizontalOnly = false;
  int _leaveMs = 300;
  String _leaveCurve = 'linear';
  int _enterMs = 600;
  String _enterCurve = 'easeOutCubic';

  Map<String, Object?> _spec() => {
    'package': packageSpec('flutter_tilt'),
    'widget': 'Tilt.base',
    'tiltConfig': {
      'angle_deg': _angle.round(),
      'enableReverse': _reverse,
      'enableGestureSensors': _gyro,
      'direction': _horizontalOnly ? ['left', 'right'] : tr('all directions (null)', 'все стороны (null)'),
      'leave': {
        'param_duration': 'leaveDuration',
        'param_curve': 'leaveCurve',
        ...timingSpec(durationMs: _leaveMs, curve: _leaveCurve),
        'curve_dart': curveCode(_leaveCurve),
      },
      'enter_to_move': {
        'param_duration': 'enterToMoveDuration',
        'param_curve': 'enterToMoveCurve',
        ...timingSpec(durationMs: _enterMs, curve: _enterCurve),
        'curve_dart': curveCode(_enterCurve),
      },
      'controllerLeaveDuration_ms': _leaveMs,
    },
    'borderRadius_px': 16,
    'child': {
      'width_px': _size.width.round(),
      'height_px': _size.height.round(),
      'gradient': [hexColor(const Color(0xFF7E57C2)), hexColor(kAccent), hexColor(const Color(0xFF311B92))],
      'gradient_direction': 'topLeft → bottomRight',
    },
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimBlock(
      title: tr('Tilt and motion', 'Наклон и движение'),
      spec: _spec,
      description: tr(
        'The main parameter is angle: the max tilt angle. 5–10° is subdued '
        '(product cards, pricing plans), 20–30° is playful (promos, '
        'collectible cards). "Reverse" — the card leans away from the cursor '
        "instead of toward it. Return — how fast the card levels out once "
        'the cursor leaves.',
        'Главный параметр — angle: максимальный угол наклона. 5–10° — '
            'благородно (карточки товаров, тарифы), 20–30° — игриво (промо, '
            'коллекционные карты). «Реверс» — карточка отклоняется от курсора, '
            'а не тянется к нему. Возврат — как быстро карточка выравнивается, '
            'когда курсор ушёл.',
      ),
      preview: Tilt.base(
        tiltController: autoTilt.controller,
        borderRadius: BorderRadius.circular(16),
        tiltConfig: TiltConfig(
          angle: _angle,
          enableReverse: _reverse,
          enableGestureSensors: _gyro,
          direction: _horizontalOnly ? const [TiltDirection.left, TiltDirection.right] : null,
          leaveDuration: Duration(milliseconds: _leaveMs),
          leaveCurve: resolveCurve(_leaveCurve),
          enterToMoveDuration: Duration(milliseconds: _enterMs),
          enterToMoveCurve: resolveCurve(_enterCurve),
          controllerLeaveDuration: Duration(milliseconds: _leaveMs),
        ),
        child: const _BankCard(size: _size),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              autoChip(),
              FilterChip(
                label: Text(tr('Reverse', 'Реверс')),
                selected: _reverse,
                onSelected: (v) => setState(() => _reverse = v),
              ),
              FilterChip(
                label: Text(tr('Horizontal only', 'Только по горизонтали')),
                selected: _horizontalOnly,
                onSelected: (v) => setState(() => _horizontalOnly = v),
              ),
              FilterChip(
                label: Text(tr('Gyroscope', 'Гироскоп')),
                selected: _gyro,
                onSelected: (v) {
                  // The controller ranks above sensors in priority — turn off the auto-demo.
                  if (v) setAuto(false);
                  setState(() => _gyro = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Gyroscope: tilt the phone. In the browser it only works in Chrome '
              "on Android; Safari/iOS and desktop don't provide sensor data.",
              'Гироскоп: наклоняй телефон. В браузере работает только в Chrome '
                  'на Android; Safari/iOS и десктоп датчики не отдают.',
            ),
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('angle — tilt angle', 'angle — угол наклона'),
            value: _angle,
            min: 0,
            max: 45,
            unit: '°',
            onChanged: (v) => setState(() => _angle = v.roundToDouble()),
          ),
          LabeledSlider(
            label: tr('leaveDuration — return', 'leaveDuration — возврат'),
            value: _leaveMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _leaveMs = (v / 50).round() * 50),
          ),
          CurveDropdown(
            value: _leaveCurve,
            onChanged: (v) => setState(() => _leaveCurve = v),
          ),
          const SizedBox(height: 12),
          Text(tr('Cursor entry (enterToMove)', 'Вход курсора (enterToMove)'), style: textTheme.titleSmall),
          Text(
            tr(
              'How smoothly the card "catches up" with the cursor the moment it '
              'just entered it.',
              'Как плавно карточка «догоняет» курсор в момент, когда он только '
                  'зашёл на неё.',
            ),
            style: textTheme.bodySmall,
          ),
          LabeledSlider(
            label: 'enterToMoveDuration',
            value: _enterMs.toDouble(),
            min: 0,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _enterMs = (v / 50).round() * 50),
          ),
          CurveDropdown(
            value: _enterCurve,
            onChanged: (v) => setState(() => _enterCurve = v),
          ),
          const SizedBox(height: 8),
          _CodeBox(
            'Tilt.base(\n'
            '  tiltConfig: TiltConfig(\n'
            '    angle: ${_angle.round()},\n'
            '    enableReverse: $_reverse,\n'
            '${_horizontalOnly ? '    direction: [TiltDirection.left, TiltDirection.right],\n' : ''}'
            '    enableGestureSensors: $_gyro,\n'
            '    leaveDuration: Duration(milliseconds: $_leaveMs),\n'
            '    leaveCurve: ${curveCode(_leaveCurve)},\n'
            '    enterToMoveDuration: Duration(milliseconds: $_enterMs),\n'
            '    enterToMoveCurve: ${curveCode(_enterCurve)},\n'
            '  ),\n'
            '  child: …,\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── light and shadow

class _LightShadowBlock extends StatefulWidget {
  const _LightShadowBlock();

  @override
  State<_LightShadowBlock> createState() => _LightShadowBlockState();
}

class _LightShadowBlockState extends State<_LightShadowBlock> with _AutoTiltState {
  static const _size = Size(200, 150);
  @override
  Size get tiltSize => _size;

  double _light = 0.4;
  double _spread = 4;
  LightDirection _lightDir = LightDirection.around;
  double _shadow = 0.5;
  double _shadowOffset = 0.15;
  double _blur = 30;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimBlock(
      title: tr('Light and shadow', 'Свет и тень'),
      spec: () => {
        'package': packageSpec('flutter_tilt'),
        'widget': 'Tilt.base',
        'tiltConfig': {'angle_deg': 15, 'enableGestureSensors': false},
        'borderRadius_px': 20,
        'lightConfig': {
          'color': hexColor(Colors.white),
          'maxIntensity': round2(_light),
          'spreadFactor': round2(_spread, 1),
          'direction': _lightDir.name,
        },
        'shadowConfig': {
          'class': 'ShadowBaseConfig',
          'color': hexColor(Colors.black),
          'maxIntensity': round2(_shadow),
          'offsetFactor': round2(_shadowOffset),
          'maxBlurRadius_px': _blur.round(),
        },
        'child': {
          'width_px': _size.width.round(),
          'height_px': _size.height.round(),
          'gradient': [
            hexColor(const Color(0xFF263238)),
            hexColor(const Color(0xFF37474F)),
            hexColor(const Color(0xFF212121)),
          ],
        },
      },
      description: tr(
        'The glare (LightConfig) is a semi-transparent gradient over the card '
        'that follows the tilt: it imitates gloss, glass, metal. The shadow '
        '(ShadowBaseConfig) shifts the opposite way and blurs more at a '
        'steeper tilt — the card "hovers" above the page. The light direction '
        'limits which side the glare can appear from.',
        'Блик (LightConfig) — полупрозрачный градиент поверх карточки, '
            'бежит за наклоном: имитирует глянец, стекло, металл. Тень '
            '(ShadowBaseConfig) смещается в противоположную сторону и '
            'размывается сильнее при большем наклоне — карточка «парит» над '
            'страницей. Направление света ограничивает, с какой стороны может '
            'появиться блик.',
      ),
      preview: Tilt.base(
        tiltController: autoTilt.controller,
        borderRadius: BorderRadius.circular(20),
        tiltConfig: const TiltConfig(angle: 15, enableGestureSensors: false),
        lightConfig: LightConfig(
          maxIntensity: _light,
          spreadFactor: _spread,
          direction: _lightDir,
        ),
        shadowConfig: ShadowBaseConfig(
          color: Colors.black,
          maxIntensity: _shadow,
          offsetFactor: _shadowOffset,
          maxBlurRadius: _blur,
        ),
        child: Container(
          width: _size.width,
          height: _size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF212121)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.headphones, color: Colors.white, size: 40),
              const Spacer(),
              const Text(
                'Studio Pro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                tr('\$249.90', '24 990 ₽'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          autoChip(),
          const SizedBox(height: 8),
          Text(tr('Light', 'Свет'), style: textTheme.titleSmall),
          LabeledSlider(
            label: tr('maxIntensity — glare brightness', 'maxIntensity — яркость блика'),
            value: _light,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _light = v),
          ),
          LabeledSlider(
            label: tr('spreadFactor — spot size', 'spreadFactor — размер пятна'),
            value: _spread,
            min: 1,
            max: 10,
            fractionDigits: 1,
            onChanged: (v) => setState(() => _spread = v),
          ),
          Text(tr('direction — where the light comes from', 'direction — откуда свет'), style: textTheme.bodyMedium),
          DropdownButton<LightDirection>(
            isExpanded: true,
            value: _lightDir,
            items: [
              for (final d in LightDirection.values)
                DropdownMenuItem(value: d, child: Text(d.name)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _lightDir = v);
            },
          ),
          const SizedBox(height: 8),
          Text(tr('Shadow', 'Тень'), style: textTheme.titleSmall),
          LabeledSlider(
            label: tr('maxIntensity — shadow density', 'maxIntensity — плотность тени'),
            value: _shadow,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _shadow = v),
          ),
          LabeledSlider(
            label: tr('offsetFactor — shadow offset', 'offsetFactor — сдвиг тени'),
            value: _shadowOffset,
            min: 0,
            max: 0.5,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _shadowOffset = v),
          ),
          LabeledSlider(
            label: tr('maxBlurRadius — blur', 'maxBlurRadius — размытие'),
            value: _blur,
            min: 10,
            max: 80,
            unit: 'px',
            onChanged: (v) => setState(() => _blur = v.roundToDouble()),
          ),
          const SizedBox(height: 8),
          _CodeBox(
            'Tilt.base(\n'
            '  lightConfig: LightConfig(\n'
            '    maxIntensity: ${_light.toStringAsFixed(2)},\n'
            '    spreadFactor: ${_spread.toStringAsFixed(1)},\n'
            '    direction: LightDirection.${_lightDir.name},\n'
            '  ),\n'
            '  shadowConfig: ShadowBaseConfig(\n'
            '    maxIntensity: ${_shadow.toStringAsFixed(2)},\n'
            '    offsetFactor: ${_shadowOffset.toStringAsFixed(2)},\n'
            '    maxBlurRadius: ${_blur.round()},\n'
            '  ),\n'
            '  child: …,\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── medal

class _MedalBlock extends StatefulWidget {
  const _MedalBlock();

  @override
  State<_MedalBlock> createState() => _MedalBlockState();
}

class _MedalBlockState extends State<_MedalBlock> with _AutoTiltState {
  static const _diameter = 150.0;
  @override
  Size get tiltSize => const Size.square(_diameter);

  bool _projector = false;
  double _angle = 25;
  double _light = 0.6;

  @override
  Widget build(BuildContext context) {
    final config = TiltConfig(angle: _angle, enableGestureSensors: false);
    const radius = BorderRadius.all(Radius.circular(_diameter / 2));
    const medal = _Medal(diameter: _diameter);
    return AnimBlock(
      title: tr('Medal / achievement badge', 'Медаль / бейдж достижения'),
      spec: () => {
        'package': packageSpec('flutter_tilt'),
        'widget': _projector ? 'Tilt.projector' : 'Tilt.base',
        'tiltConfig': {'angle_deg': _angle.round(), 'enableGestureSensors': false},
        'borderRadius_px': (_diameter / 2).round(),
        if (_projector)
          'shadowConfig': {
            'class': 'ShadowProjectorConfig',
            'maxIntensity': 0.6,
            'offsetFactor': 0.2,
            'projectorScaleTo': 0.95,
            'projectorBlurSigmaTo': 14,
          }
        else ...{
          'lightConfig': {'maxIntensity': round2(_light), 'spreadFactor': 2},
          'shadowConfig': {
            'class': 'ShadowBaseConfig',
            'color': hexColor(const Color(0xFF8D6E00)),
            'maxIntensity': 0.5,
            'offsetFactor': 0.12,
          },
        },
        'medal': {
          'diameter_px': _diameter.round(),
          'radial_gradient': [
            hexColor(const Color(0xFFFFF59D)),
            hexColor(const Color(0xFFFFC107)),
            hexColor(const Color(0xFFB8860B)),
          ],
          'border': {'width_px': 6, 'color': hexColor(const Color(0xFFFFE082))},
        },
      },
      description: tr(
        'A round award with a strong glare looks metallic. Good for '
        'achievement screens, levels, NFT cards, profile badges. The '
        'Tilt.projector mode draws a blurred "projection" under the element '
        'instead of a regular shadow — the shadow follows the shape (handy for '
        'irregular PNGs), but the package draws no glare in this mode.',
        'Круглая награда с сильным бликом выглядит металлической. Подходит '
            'для экранов достижений, уровней, NFT-карточек, бейджей профиля. '
            'Режим Tilt.projector вместо обычной тени рисует под элементом его '
            'размытую «проекцию» — тень повторяет форму (удобно для фигурных '
            'PNG), но блик в этом режиме пакет не рисует.',
      ),
      preview: _projector
          ? Tilt.projector(
              tiltController: autoTilt.controller,
              borderRadius: radius,
              tiltConfig: config,
              shadowConfig: const ShadowProjectorConfig(
                maxIntensity: 0.6,
                offsetFactor: 0.2,
                projectorScaleTo: 0.95,
                projectorBlurSigmaTo: 14,
              ),
              child: medal,
            )
          : Tilt.base(
              tiltController: autoTilt.controller,
              borderRadius: radius,
              tiltConfig: config,
              lightConfig: LightConfig(maxIntensity: _light, spreadFactor: 2),
              shadowConfig: const ShadowBaseConfig(
                color: Color(0xFF8D6E00),
                maxIntensity: 0.5,
                offsetFactor: 0.12,
              ),
              child: medal,
            ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              autoChip(),
              FilterChip(
                label: Text(tr('Projected shadow (Tilt.projector)', 'Тень-проекция (Tilt.projector)')),
                selected: _projector,
                onSelected: (v) => setState(() => _projector = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('angle — tilt angle', 'angle — угол наклона'),
            value: _angle,
            min: 0,
            max: 45,
            unit: '°',
            onChanged: (v) => setState(() => _angle = v.roundToDouble()),
          ),
          if (!_projector)
            LabeledSlider(
              label: tr('Glare brightness', 'Яркость блика'),
              value: _light,
              min: 0,
              max: 1,
              fractionDigits: 2,
              onChanged: (v) => setState(() => _light = v),
            ),
          const SizedBox(height: 8),
          _CodeBox(
            _projector
                ? 'Tilt.projector(\n'
                      '  borderRadius: BorderRadius.circular(75),\n'
                      '  tiltConfig: TiltConfig(angle: ${_angle.round()}),\n'
                      '  shadowConfig: ShadowProjectorConfig(…),\n'
                      '  child: medal,\n'
                      ')'
                : 'Tilt.base(\n'
                      '  borderRadius: BorderRadius.circular(75),\n'
                      '  tiltConfig: TiltConfig(angle: ${_angle.round()}),\n'
                      '  lightConfig: LightConfig(maxIntensity: ${_light.toStringAsFixed(2)}),\n'
                      '  child: medal,\n'
                      ')',
          ),
        ],
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.diameter});
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFB8860B)],
          stops: [0, 0.55, 1],
        ),
        border: Border.all(color: const Color(0xFFFFE082), width: 6),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 56, color: Color(0xFF7A5200)),
          Text(
            'TOP 1',
            maxLines: 1,
            style: TextStyle(
              color: Color(0xFF7A5200),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────── parallax

class _ParallaxBlock extends StatefulWidget {
  const _ParallaxBlock();

  @override
  State<_ParallaxBlock> createState() => _ParallaxBlockState();
}

class _ParallaxBlockState extends State<_ParallaxBlock> with _AutoTiltState {
  static const _size = Size(240, 150);
  @override
  Size get tiltSize => _size;

  double _depth = 1;
  double _angle = 12;

  @override
  Widget build(BuildContext context) {
    final d = _depth;
    return AnimBlock(
      title: tr('Parallax layers (TiltParallax)', 'Параллакс-слои (TiltParallax)'),
      spec: () => {
        'package': packageSpec('flutter_tilt'),
        'widget': 'Tilt.base + ChildLayout + TiltParallax',
        'tiltConfig': {'angle_deg': _angle.round(), 'enableGestureSensors': false},
        'lightConfig': {'maxIntensity': 0.3},
        'borderRadius_px': 16,
        'depth_multiplier': round2(d, 1),
        'layers': [
          {
            'layer': tr('photo (child)', 'фото (child)'),
            'width_px': _size.width.round(),
            'height_px': _size.height.round(),
            'TiltParallax_offset_px': null,
          },
          {
            'layer': tr('caption (ChildLayout.inner)', 'подпись (ChildLayout.inner)'),
            'TiltParallax_offset_px': {'x': (12 * d).round(), 'y': (12 * d).round()},
          },
          {
            'layer': tr('badge (ChildLayout.outer)', 'бейдж (ChildLayout.outer)'),
            'position_px': {'right': -14, 'top': -14},
            'TiltParallax_offset_px': {'x': (28 * d).round(), 'y': (28 * d).round()},
            'color': hexColor(Colors.redAccent),
          },
        ],
      },
      description: tr(
        'Inside the tilting card sit layers that additionally shift by '
        'different amounts: the larger the offset, the "closer" the layer '
        'looks to the viewer. Photo — background plane, caption — middle, '
        'the discount badge spills past the card edge (ChildLayout.outer). '
        'Promo banners, covers, game and movie cards.',
        'Внутри наклоняемой карточки лежат слои, которые дополнительно '
            'сдвигаются на разную величину: чем больше offset, тем «ближе» слой '
            'к зрителю. Фото — дальний план, подпись — средний, бейдж скидки '
            'выходит за край карточки (ChildLayout.outer). Промо-баннеры, '
            'обложки, карточки игр и фильмов.',
      ),
      preview: Tilt.base(
        tiltController: autoTilt.controller,
        borderRadius: BorderRadius.circular(16),
        tiltConfig: TiltConfig(angle: _angle, enableGestureSensors: false),
        lightConfig: const LightConfig(maxIntensity: 0.3),
        childLayout: ChildLayout(
          inner: [
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: TiltParallax(
                offset: Offset(12 * d, 12 * d),
                child: Text(
                  tr('Sydney', 'Сидней'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ],
          outer: [
            Positioned(
              right: -14,
              top: -14,
              child: TiltParallax(
                offset: Offset(28 * d, 28 * d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: const Text(
                    '−30%',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Image.asset(
          'assets/eat_sydney_sm.jpg',
          width: _size.width,
          height: _size.height,
          fit: BoxFit.cover,
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          autoChip(),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Layer depth (offset multiplier)', 'Глубина слоёв (множитель offset)'),
            value: _depth,
            min: 0,
            max: 3,
            unit: '×',
            fractionDigits: 1,
            onChanged: (v) => setState(() => _depth = v),
          ),
          LabeledSlider(
            label: tr('angle — tilt angle', 'angle — угол наклона'),
            value: _angle,
            min: 0,
            max: 45,
            unit: '°',
            onChanged: (v) => setState(() => _angle = v.roundToDouble()),
          ),
          const SizedBox(height: 8),
          _CodeBox(
            'Tilt.base(\n'
            '  childLayout: ChildLayout(\n'
            '    inner: [TiltParallax(offset: Offset(${(12 * d).round()}, ${(12 * d).round()}), child: title)],\n'
            '    outer: [TiltParallax(offset: Offset(${(28 * d).round()}, ${(28 * d).round()}), child: badge)],\n'
            '  ),\n'
            '  child: Image.asset(…),\n'
            ')',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────── gallery

class _GalleryBlock extends StatelessWidget {
  const _GalleryBlock();

  static List<(String, String, String)> get _items => [
    ('assets/eat_cape_town_sm.jpg', tr('Cape Town', 'Кейптаун'), tr('angle 10° — subdued', 'angle 10° — спокойно')),
    (
      'assets/eat_new_orleans_sm.jpg',
      tr('New Orleans', 'Новый Орлеан'),
      tr('angle 20° + reverse', 'angle 20° + реверс'),
    ),
    (
      'assets/eat_sydney_sm.jpg',
      tr('Sydney', 'Сидней'),
      tr('angle 30° + bright glare', 'angle 30° + яркий блик'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final configs = [
      (const TiltConfig(angle: 10, enableGestureSensors: false), 0.2),
      (const TiltConfig(angle: 20, enableReverse: true, enableGestureSensors: false), 0.3),
      (const TiltConfig(angle: 30, enableGestureSensors: false), 0.6),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(tr('In a grid of cards', 'В сетке карточек'), style: textTheme.titleMedium)),
                SpecButton(
                  title: tr('Tilt in a grid of cards', 'Tilt в сетке карточек'),
                  spec: () => {
                    'package': packageSpec('flutter_tilt'),
                    'widget': 'Tilt.base',
                    'borderRadius_px': 12,
                    'card_size_px': {'width': 180, 'height': 120},
                    'cards': [
                      for (final (i, (_, title, _)) in _items.indexed)
                        {
                          'card': title,
                          'tiltConfig': {
                            'angle_deg': configs[i].$1.angle.round(),
                            'enableReverse': configs[i].$1.enableReverse,
                            'enableGestureSensors': false,
                          },
                          'lightConfig': {'maxIntensity': configs[i].$2},
                        },
                    ],
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                "This is how the effect looks in a catalog: no auto-demo, only "
                "under the cursor. Compare three tilt strengths and pick your "
                "own. On a phone, a finger on the card tilts it instead of "
                "scrolling the page — keep that in mind in long feeds.",
                'Так эффект выглядит в каталоге: без автодемо, только под '
                    'курсором. Сравни три силы наклона и выбери свою. На телефоне '
                    'палец на карточке наклоняет её, а не скроллит страницу — учитывай '
                    'это в длинных лентах.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              minTileWidth: 240,
              children: [
                for (final (i, (asset, title, caption)) in _items.indexed)
                  ShowcaseTile(
                    title: title,
                    caption: caption,
                    previewHeight: 170,
                    child: Tilt.base(
                      borderRadius: BorderRadius.circular(12),
                      tiltConfig: configs[i].$1,
                      lightConfig: LightConfig(maxIntensity: configs[i].$2),
                      child: Image.asset(asset, width: 180, height: 120, fit: BoxFit.cover),
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

// ─────────────────────────────────────────────────────────────── card

class _BankCard extends StatelessWidget {
  const _BankCard({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7E57C2), kAccent, Color(0xFF311B92)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.white70),
              Spacer(),
              Icon(Icons.contactless, color: Colors.white70),
            ],
          ),
          Spacer(),
          Text(
            '4276 •••• 1234',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5),
          ),
          SizedBox(height: 4),
          Text(
            'ANNA IVANOVA',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 11),
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

/// The cursor has left the top-right corner: the card returns from maximum
/// tilt over leaveDuration along leaveCurve (there and back). The glare and
/// shadow are a light imitation of LightConfig / ShadowBaseConfig.
Widget _tiltPlayground(BuildContext context, BriefValues v, double t) {
  final a = 1 - v.curve('leaveCurve').transform(t);
  final rad = v.number('angle') * math.pi / 180 * a;
  final light = v.color('light_color');
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(rad)
      ..rotateY(rad),
    child: Container(
      width: 200,
      height: 124,
      decoration: BoxDecoration(
        color: v.color('card_color'),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (v.number('shadow') * (0.3 + 0.7 * a)).clamp(0.0, 1.0)),
            blurRadius: 10 + v.number('shadow_blur') * a,
            offset: Offset(-10 * a, 10 * a),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [light.withValues(alpha: (v.number('light') * a).clamp(0.0, 1.0)), light.withValues(alpha: 0)],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.credit_card, color: Colors.white70),
          Spacer(),
          Text('4276 •••• 1234', style: TextStyle(color: Colors.white, letterSpacing: 1.5)),
        ],
      ),
    ),
  );
}
