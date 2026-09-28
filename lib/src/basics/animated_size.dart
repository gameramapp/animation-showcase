// Showcase of "size and content change" animations:
//   • AnimatedSize — the box adjusts itself to the content;
//   • ExpandedSection — the same effect using explicit animation (SizeTransition);
//   • AnimatedSwitcher — animated swap of one widget for another;
//   • AnimatedCrossFade — cross-fade of two widgets + size morph.

import 'dart:math';

import 'package:flutter/material.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/expanded_section.dart';
import '../common/i18n.dart';

class AnimatedSizeDemo extends StatelessWidget {
  const AnimatedSizeDemo({super.key});
  static String routeName = 'basics/animated_size';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Animations'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const _SizeBlock(),
          const SizedBox(height: 16),
          const _ExpandedSectionBlock(),
          const SizedBox(height: 16),
          const _SwitcherBlock(),
          const SizedBox(height: 16),
          const _CrossFadeBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.choice('effect', tr('Effect', 'Эффект'), _pgEffects, _pgEffects[0]),
                BriefField.duration('duration_ms', tr('Duration', 'Длительность'), 500),
                BriefField.curve(
                  'curve',
                  tr('Size / entrance curve', 'Кривая размера / входа'),
                  'easeInOut',
                ),
                BriefField.curve(
                  'out_curve',
                  tr("Old element's exit curve", 'Кривая ухода старого'),
                  'easeIn',
                ),
                BriefField.number(
                  'collapsed_px',
                  tr('Height "collapsed"', 'Высота «свёрнуто»'),
                  40,
                  unit: 'px',
                  min: 0,
                  max: 400,
                ),
                BriefField.number(
                  'expanded_px',
                  tr('Height "expanded"', 'Высота «развёрнуто»'),
                  120,
                  unit: 'px',
                  min: 0,
                  max: 400,
                ),
                BriefField.choice('fade', tr('Content fade', 'Фейд контента'), [_yes, _no], _yes),
              ],
              builder: _sizePreview,
            ),
            items: [
              (
                tr('Content states', 'Состояния контента'),
                tr(
                  '"collapsed" and "expanded" frames (or "before" / "after") in Figma',
                  'фреймы «свёрнуто» и «развёрнуто» (или «было» / «стало») в Figma',
                ),
              ),
              (
                tr('What the neighbors do', 'Что делают соседи'),
                tr(
                  'the blocks below smoothly slide or jump; which edge the block '
                      'grows from (top, center)',
                  'блоки ниже плавно съезжают или прыгают; от какого края растёт блок (верх, центр)',
                ),
              ),
              (
                tr('Swap (Switcher)', 'Подмена (Switcher)'),
                tr(
                  'transition type: fade / scale / rotation / slide / size; for '
                      'slide — where it enters from and by how much',
                  'тип перехода: fade / scale / rotation / slide / size; для slide — '
                      'откуда въезжает и на сколько',
                ),
              ),
              (
                tr('Curves', 'Кривые'),
                tr(
                  'separately for the new element entering and the old one leaving; '
                      'for cross-fade — the fade curve and the size-change curve',
                  'отдельно для входа нового и ухода старого; для cross-fade — '
                      'кривая фейда и кривая изменения размера',
                ),
              ),
              (
                tr('Duration', 'Длительность'),
                tr(
                  'ms; if expanding and collapsing differ, give both numbers',
                  'мс; раскрытие и сворачивание — если разные, обе цифры',
                ),
              ),
              (
                tr('Fade', 'Фейд'),
                tr(
                  'whether the content should dissolve at the same time as the size change',
                  'нужно ли растворение контента одновременно с изменением размера',
                ),
              ),
            ],
            avoid: [
              tr(
                "Don't send just a video without numbers",
                'Не присылать только видео без цифр',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Size & content change', 'Размер и смена контента'), style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(
                'A group of animations about how content changes and gets swapped. '
                'AnimatedSize smoothly fits a box to its content, ExpandedSection '
                'does the same with an explicit animation, AnimatedSwitcher '
                'animates swapping one widget for another, and AnimatedCrossFade '
                'cross-fades two widgets while morphing their size at the same time.',
                'Группа анимаций про то, как меняется и подменяется содержимое. '
                    'AnimatedSize плавно подстраивает габариты коробки под контент, '
                    'ExpandedSection делает то же на explicit-анимации, AnimatedSwitcher '
                    'анимирует подмену одного виджета другим, а AnimatedCrossFade '
                    'делает кросс-фейд двух виджетов с одновременным морфом размера.',
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Tap "Expand" and turn the handles — the preview animates in real time.',
                'Жми «Развернуть» и крути ручки — превью анимируется в реальном времени.',
              ),
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── AnimatedSize

class _SizeBlock extends StatefulWidget {
  const _SizeBlock();
  @override
  State<_SizeBlock> createState() => _SizeBlockState();
}

class _SizeBlockState extends State<_SizeBlock> {
  int durationMs = 600;
  String curve = 'easeInOut';

  // Base text from which we "generate" a string of random length.
  static String get _base => tr(
    'And here is the expanded text: several lines with details. When the '
    'content changes, the card smoothly grows or shrinks, and the block below '
    'shifts just as smoothly. The longer the line, the taller the card: '
    'AnimatedSize fits its own size to the content, and the neighbors follow.',
    'А здесь — развёрнутый текст: несколько строк с деталями. Когда контент '
        'меняется, карточка плавно растёт или сжимается, а блок ниже так же '
        'плавно сдвигается. Чем длиннее строка — тем выше карточка: AnimatedSize '
        'сам подстраивает габариты под контент, а соседи едут следом.',
  );

  final _random = Random();
  List<String> get _words => _base.split(' ');
  String? text;

  // "Generation": take a random number of words and truncate the base text.
  void _generate() {
    final words = _words;
    final count = _random.nextInt(words.length) + 1;
    setState(() => text = words.take(count).join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        text ??
        tr(
          'Tap "Generate text" — the line will be a random length.',
          'Нажми «Генерировать текст» — строка будет случайной длины.',
        );
    return AnimBlock(
      title: 'AnimatedSize',
      spec: () => {
        'widget': 'AnimatedSize',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'alignment': 'topCenter',
        'card': {
          'max_width_px': 280,
          'padding_px': 12,
          'border_radius_px': 12,
          'color': hexColor(kAccent),
          'opacity': 0.12,
        },
        'text_font_size_px': 12,
        'neighbour_gap_px': 8,
      },
      description: tr(
        'The real purpose: the container itself doesn\'t know the content\'s '
        'size, and when the content changes (text, a list, an expansion), the '
        'box smoothly adjusts, and neighboring blocks smoothly shift. This is '
        'accordions, "read more", dynamic hints.\n\n'
        'The base text we "generate" a random-length line from. Tap "Generate '
        'text" — the line will be a random length.\n\n'
        'The animation can be used not just on text, but on a list, an image, '
        'video, and so on — anything at all.',
        'Настоящее назначение: контейнер сам не знает размер контента, и '
            'когда контент меняется (текст, список, раскрытие), коробка плавно '
            'подстраивается, а соседние блоки плавно сдвигаются. Это аккордеоны, '
            '«читать дальше», динамические подсказки.\n\n'
            'Базовый текст, из которого «генерируем» строку случайной длины. '
            'Нажми «Генерировать текст» — строка будет случайной длины.\n\n'
            'Анимацию можно использовать не только на текст, но и на список, изображение, видео и т.д., что угодно',
      ),
      preview: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth < 280 ? c.maxWidth : 280.0;
          return Center(
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card whose size is dictated by the text inside it.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedSize(
                      duration: Duration(milliseconds: durationMs),
                      curve: resolveCurve(curve),
                      alignment: Alignment.topCenter,
                      child: Text(displayText, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Neighboring block — you can see it smoothly shift on resize.
                  Container(
                    width: double.infinity,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tr('Neighboring block', 'Соседний блок'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonal(
            onPressed: _generate,
            child: Text(tr('Generate text', 'Генерировать текст')),
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(
            value: curve,
            onChanged: (v) => setState(() => curve = v),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────── ExpandedSection (explicit, SizeTransition)

class _ExpandedSectionBlock extends StatefulWidget {
  const _ExpandedSectionBlock();
  @override
  State<_ExpandedSectionBlock> createState() => _ExpandedSectionBlockState();
}

class _ExpandedSectionBlockState extends State<_ExpandedSectionBlock> {
  bool expanded = false;
  bool fade = true;
  int durationMs = 500;
  String curve = 'fastOutSlowIn';

  static String get _detail => tr(
    'The expanded block opens via a SizeTransition, driven by an '
    'AnimationController inside ExpandedSection. From the outside we just '
    'flip the expand flag — the widget forces forward/reverse on its own. '
    'Duration and curve are configurable, and an AnimatedOpacity is layered '
    'on top for the fade.',
    'Развёрнутый блок раскрывается через SizeTransition, которым управляет '
        'AnimationController внутри ExpandedSection. Снаружи мы лишь дёргаем флаг '
        'expand — виджет сам форсит forward/reverse. Длительность и кривая '
        'настраиваются, а сверху накинут AnimatedOpacity для фейда.',
  );

  @override
  Widget build(BuildContext context) {
    return AnimBlock(
      title: 'ExpandedSection (explicit)',
      spec: () => {
        'widget': 'ExpandedSection (AnimationController + SizeTransition)',
        ...timingSpec(durationMs: durationMs, curve: curve),
        'axis': 'vertical',
        'state': expanded ? 'expanded' : 'collapsed',
        'fade': fade
            ? {'widget': 'AnimatedOpacity', 'from': 0, 'to': 1, 'same_timing': true}
            : tr('none', 'нет'),
        'card': {
          'max_width_px': 280,
          'padding_px': 12,
          'border_radius_px': 12,
          'color': hexColor(kAccent),
          'opacity': 0.12,
        },
        'detail_top_padding_px': 8,
      },
      description: tr(
        'The same "expand/collapse" effect, but instead of the implicit '
        'AnimatedSize, via an explicit animation: AnimationController + '
        'SizeTransition. A hand-rolled, reusable ExpandedSection widget — '
        'driven by a boolean expand flag, convenient to hang off screen state.\n',
        'Тот же эффект «раскрыть/свернуть», но не через implicit AnimatedSize, '
            'а через explicit-анимацию: AnimationController + SizeTransition. '
            'Самодельный переиспользуемый виджет ExpandedSection — управляется '
            'булевым флагом expand, удобно вешать на состояние экрана.\n',
      ),
      preview: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth < 280 ? c.maxWidth : 280.0;
          return Center(
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card: the details inside expand by height.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('A short one-line summary.', 'Краткое описание в одну строку.'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        AnimatedOpacity(
                          // The fade can be turned off — then the detail simply
                          // expands by height, with no change in opacity.
                          opacity: fade ? (expanded ? 1 : 0) : 1,
                          duration: Duration(milliseconds: durationMs),
                          curve: resolveCurve(curve),
                          child: ExpandedSection(
                            expand: expanded,
                            expandOnStart: false,
                            duration: Duration(milliseconds: durationMs),
                            curve: resolveCurve(curve),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _detail,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Neighboring block — you can see it smoothly shift as it expands.
                  Container(
                    width: double.infinity,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tr('Neighboring block', 'Соседний блок'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonal(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? tr('Collapse', 'Свернуть') : tr('Expand', 'Развернуть')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Fade (AnimatedOpacity)', 'Фейд (AnimatedOpacity)')),
            value: fade,
            onChanged: (v) => setState(() => fade = v),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          CurveDropdown(
            value: curve,
            onChanged: (v) => setState(() => curve = v),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── AnimatedSwitcher

/// Transition types demonstrating transitionBuilder in AnimatedSwitcher.
enum _SwitchTransition { fade, scale, rotation, slide, size }

class _SwitcherBlock extends StatefulWidget {
  const _SwitcherBlock();
  @override
  State<_SwitcherBlock> createState() => _SwitcherBlockState();
}

class _SwitcherBlockState extends State<_SwitcherBlock> {
  int index = 0;
  int durationMs = 500;
  String inCurve = 'easeOut';
  String outCurve = 'easeIn';
  _SwitchTransition transition = _SwitchTransition.scale;

  // Palette we "cycle through" for the content.
  static const _palette = [
    Color(0xFF673AB7),
    Color(0xFF009688),
    Color(0xFFE91E63),
    Color(0xFFFF9800),
    Color(0xFF3F51B5),
  ];

  Widget _buildTransition(Widget child, Animation<double> animation) {
    switch (transition) {
      case _SwitchTransition.fade:
        return FadeTransition(opacity: animation, child: child);
      case _SwitchTransition.scale:
        return ScaleTransition(scale: animation, child: child);
      case _SwitchTransition.rotation:
        return RotationTransition(turns: animation, child: child);
      case _SwitchTransition.slide:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0, 0.4), end: Offset.zero),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      case _SwitchTransition.size:
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 0,
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[index % _palette.length];
    return AnimBlock(
      title: 'AnimatedSwitcher',
      spec: () => {
        'widget': 'AnimatedSwitcher',
        'transition': switch (transition) {
          _SwitchTransition.fade => 'FadeTransition',
          _SwitchTransition.scale => 'ScaleTransition (0 → 1)',
          _SwitchTransition.rotation => tr(
            'RotationTransition (0 → 1 turn)',
            'RotationTransition (0 → 1 оборот)',
          ),
          _SwitchTransition.slide => 'SlideTransition + FadeTransition',
          _SwitchTransition.size => 'SizeTransition (vertical, from center)',
        },
        if (transition == _SwitchTransition.slide) 'slide_begin_offset_y_fraction_of_height': 0.4,
        'duration_ms': durationMs,
        'switch_in': timingSpec(durationMs: durationMs, curve: inCurve),
        'switch_out': timingSpec(durationMs: durationMs, curve: outCurve),
        'element': {
          'size_px': {'width': 96, 'height': 96},
          'border_radius_px': 20,
          'color': hexColor(_palette[index % _palette.length]),
          'palette': [for (final c in _palette) hexColor(c)],
        },
      },
      description: tr(
        'Animates the SWAP of one widget for another. As soon as the child '
        'changes (it must have a new Key), the old one leaves and the new one '
        'enters via the chosen transition. The transition is set by '
        'transitionBuilder — here you can switch between fade / scale / '
        'rotation / slide / size. Good for counters, icon changes, tab content.',
        'Анимирует ПОДМЕНУ одного виджета другим. Как только меняется child '
            '(обязательно с новым Key), старый уезжает, а новый въезжает по '
            'выбранному переходу. Переход задаётся transitionBuilder — здесь '
            'можно переключать fade / scale / rotation / slide / size. Удобно для '
            'счётчиков, смены иконок, контента вкладок.',
      ),
      preview: AnimatedSwitcher(
        duration: Duration(milliseconds: durationMs),
        switchInCurve: resolveCurve(inCurve),
        switchOutCurve: resolveCurve(outCurve),
        transitionBuilder: _buildTransition,
        child: Container(
          // Key is required: AnimatedSwitcher detects that the content changed
          // by the key change, and triggers the transition.
          key: ValueKey(index),
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 32),
          ),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonal(
            onPressed: () => setState(() => index++),
            child: Text(tr('Change content', 'Сменить содержимое')),
          ),
          const SizedBox(height: 8),
          Text(tr('Transition type', 'Тип перехода'), style: Theme.of(context).textTheme.titleSmall),
          DropdownButton<_SwitchTransition>(
            isExpanded: true,
            value: transition,
            items: [
              for (final t in _SwitchTransition.values)
                DropdownMenuItem(value: t, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => transition = v ?? transition),
          ),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          Text(
            tr('New entering (switchInCurve)', 'Вход нового (switchInCurve)'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CurveDropdown(value: inCurve, onChanged: (v) => setState(() => inCurve = v)),
          const SizedBox(height: 8),
          Text(
            tr('Old leaving (switchOutCurve)', 'Уход старого (switchOutCurve)'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CurveDropdown(value: outCurve, onChanged: (v) => setState(() => outCurve = v)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── AnimatedCrossFade

class _CrossFadeBlock extends StatefulWidget {
  const _CrossFadeBlock();
  @override
  State<_CrossFadeBlock> createState() => _CrossFadeBlockState();
}

class _CrossFadeBlockState extends State<_CrossFadeBlock> {
  bool showSecond = false;
  int durationMs = 500;
  String curve = 'easeInOut';
  String sizeCurve = 'easeInOut';

  /// Custom layoutBuilder: the disappearing layer is centered and NOT clamped to
  /// the box size — OverflowBox gives it loose (infinite) constraints, so its
  /// inner Column isn't squeezed against a height and doesn't complain about
  /// overflow; the excess is symmetrically clipped by ClipRect inside
  /// AnimatedCrossFade. The box size is still driven by the appearing (top)
  /// widget, so the card smoothly shrinks back into the button — a mirror of
  /// expanding.
  static Widget _centeredCrossFade(
    Widget topChild,
    Key topKey,
    Widget bottomChild,
    Key bottomKey,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          key: bottomKey,
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: bottomChild,
          ),
        ),
        Positioned(key: topKey, child: topChild),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = resolveCurve(curve);
    return AnimBlock(
      title: 'AnimatedCrossFade',
      spec: () => {
        'widget': 'AnimatedCrossFade',
        'state': showSecond ? 'showSecond' : 'showFirst',
        'duration_ms': durationMs,
        'fade': timingSpec(durationMs: durationMs, curve: curve),
        'size': timingSpec(durationMs: durationMs, curve: sizeCurve),
        'alignment': 'center',
        'first_child': {
          'width_px': 120,
          'padding_px': 12,
          'border_radius_px': 12,
          'color': hexColor(kAccent),
          'opacity': 0.12,
        },
        'second_child': {
          'width_px': 240,
          'padding_px': 16,
          'border_radius_px': 16,
          'color': hexColor(kAccent),
        },
        'clip_border_radius_px': 16,
      },
      description: tr(
        'A cross-fade between EXACTLY two widgets (firstChild / secondChild) '
        'plus a simultaneous size animation between them. Essentially '
        '"AnimatedSize + cross-fade" in one widget: the old one dissolves, the '
        'new one appears, and the box smoothly morphs its size. The state is '
        'chosen via crossFadeState. The fade curve and the size curve are '
        'configured separately.',
        'Кросс-фейд между РОВНО двумя виджетами (firstChild / secondChild) '
            'плюс одновременная анимация размера между ними. По сути «AnimatedSize '
            '+ перекрёстный фейд» в одном виджете: старый растворяется, новый '
            'проявляется, а коробка плавно морфит габариты. Состояние выбирается '
            'через crossFadeState. Кривые fade и размера настраиваются раздельно.',
      ),
      preview: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            // AnimatedCrossFade's internal clip is rectangular, so sharp corners
            // show up during shrinking. We wrap it in ClipRRect to round them to
            // match the card radius. Clip.antiAlias draws the rounded clip on
            // the canvas without a saveLayer, and the radius is constant — so
            // there's practically no performance impact.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedCrossFade(
                duration: Duration(milliseconds: durationMs),
                firstCurve: c,
                secondCurve: c,
                sizeCurve: resolveCurve(sizeCurve),
                alignment: Alignment.center,
                // The default layoutBuilder pins the disappearing widget to a
                // corner and clamps it to a width — the large card jumps when
                // shrinking. We center both layers so the transition is symmetric.
                layoutBuilder: _centeredCrossFade,
                crossFadeState: showSecond
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                // Compact variant.
                firstChild: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, color: kAccent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tr('Preview', 'Превью'),
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expanded variant — a different size, cross-fade + size morph.
                secondChild: Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.photo, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        tr('Expanded card', 'Развёрнутая карточка'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'The second widget is bigger: you can see how the box '
                          'smoothly morphs its size from the compact state to this '
                          'one during the cross-fade.',
                          'Второй виджет крупнее: видно, как при кросс-фейде коробка '
                              'плавно морфит размер от компактного состояния к этому.',
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonal(
            onPressed: () => setState(() => showSecond = !showSecond),
            child: Text(showSecond ? tr('Collapse', 'Свернуть') : tr('Expand', 'Развернуть')),
          ),
          const SizedBox(height: 12),
          LabeledSlider(
            label: tr('Duration', 'Длительность'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          Text(
            tr('Fade (firstCurve / secondCurve)', 'Фейд (firstCurve / secondCurve)'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CurveDropdown(
            value: curve,
            onChanged: (v) => setState(() => curve = v),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Size morph (sizeCurve)', 'Морф размера (sizeCurve)'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          CurveDropdown(
            value: sizeCurve,
            onChanged: (v) => setState(() => sizeCurve = v),
          ),
        ],
      ),
    );
  }
}

String get _yes => tr('yes', 'да');
String get _no => tr('no', 'нет');

List<String> get _pgEffects => [
  tr('Expand (AnimatedSize)', 'Раскрытие (AnimatedSize)'),
  tr('Swap (AnimatedSwitcher)', 'Подмена (AnimatedSwitcher)'),
  tr('Cross-fade (AnimatedCrossFade)', 'Кросс-фейд (AnimatedCrossFade)'),
];

/// Playground preview: card expansion, swap, or cross-fade.
Widget _sizePreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  final fade = v.text('fade') == _yes;
  final effect = v.text('effect');
  double h(double k) =>
      (v.number('collapsed_px') + (v.number('expanded_px') - v.number('collapsed_px')) * k)
          .clamp(0.0, 1000.0);
  const label = TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold);

  if (effect == _pgEffects[1]) {
    final out = v.curve('out_curve').transform(t);
    Widget box(Color c, String s, double k) => Opacity(
      opacity: fade ? k.clamp(0.0, 1.0) : 1,
      child: Transform.scale(
        scale: k,
        child: Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
          child: Text(s, style: label),
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [box(kAccent, '1', 1 - out), box(const Color(0xFF009688), '2', e)],
    );
  }

  if (effect == _pgEffects[2]) {
    final k = e.clamp(0.0, 1.0);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: (120 + 120 * e).clamp(0.0, 1000.0),
        height: h(e),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Color.lerp(kAccent.withValues(alpha: 0.12), kAccent, k),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: 1 - k, child: const Icon(Icons.image_outlined, color: kAccent)),
            Opacity(
              opacity: k,
              child: const Icon(Icons.photo, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  return FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: h(e),
            padding: const EdgeInsets.all(10),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: fade ? e.clamp(0.0, 1.0) : 1,
              child: Text(
                tr(
                  'Expanded text: details that appear when it opens.',
                  'Развёрнутый текст: детали, которые появляются при раскрытии.',
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(8)),
            child: Text(
              tr('Neighboring block', 'Соседний блок'),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
