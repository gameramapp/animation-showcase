// Routing & Transitions screen: everything about navigation and transitions
// in one place. Three sections — the transitions playground, Material 3
// motion, and modals/dialogs/gestures — each with its own settings and launch buttons.

import 'package:flutter/material.dart';

import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import 'transitions_playground.dart';

class RoutingDemo extends StatelessWidget {
  const RoutingDemo({super.key});
  static const String routeName = 'routing/transitions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Transitions Playground', 'Песочница переходов')),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Intro(),
          const SizedBox(height: 16),
          const TransitionsPlayground(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              fields: [
                BriefField.choice(
                  'type',
                  tr('Transition type', 'Тип перехода'),
                  _pgTypes,
                  'Slide',
                ),
                BriefField.choice(
                  'direction',
                  tr('Where it enters from', 'Откуда въезжает'),
                  _pgDirs,
                  tr('bottom', 'снизу'),
                ),
                BriefField.duration(
                  'duration_ms',
                  tr('Duration', 'Длительность'),
                  450,
                ),
                BriefField.curve('curve', tr('Curve', 'Кривая'), 'easeInOut'),
                BriefField.choice(
                  'exit',
                  tr('Departing screen', 'Уходящий экран'),
                  _pgExits,
                  'parallax',
                ),
              ],
              builder: _routePreview,
            ),
            items: [
              (
                tr('Transition type', 'Тип перехода'),
                tr(
                  'slide, fade, zoom, rotate… or a system one (Material / Cupertino).',
                  'сдвиг, проявление, зум, поворот… или системный (Material / Cupertino).',
                ),
              ),
              (
                tr('Direction', 'Направление'),
                tr(
                  'where the new screen enters from: right, bottom, top, left.',
                  'откуда въезжает новый экран: справа, снизу, сверху, слева.',
                ),
              ),
              (
                tr('Duration in and out', 'Длительность туда и обратно'),
                tr(
                  'in ms — separately for opening and closing, if they differ.',
                  'в мс — отдельно для открытия и закрытия, если отличаются.',
                ),
              ),
              (
                tr('Curves', 'Кривые'),
                tr(
                  'for opening and closing: preset, cubic-bezier(…) from Figma, or a spring from Smart Animate.',
                  'для открытия и закрытия: пресет, cubic-bezier(…) из Figma или spring из Smart Animate.',
                ),
              ),
              (
                tr(
                  'What the departing screen does',
                  'Что делает уходящий экран',
                ),
                tr(
                  'stays put, leaves with parallax, recedes, dims — and by how much.',
                  'стоит на месте, уезжает с параллаксом, отдаляется, затемняется — и насколько.',
                ),
              ),
              (
                tr('Page or modal', 'Страница или модалка'),
                tr(
                  'a regular screen or a fullscreen dialog (closes with an X, slides in from the bottom).',
                  'обычный экран или fullscreen-диалог (закрывается крестиком, въезжает снизу).',
                ),
              ),
              (
                tr('Prototype', 'Прототип'),
                tr(
                  'two frames in Figma linked by a transition with these settings.',
                  'два фрейма в Figma, связанные переходом с этими настройками.',
                ),
              ),
            ],
            avoid: [
              tr(
                'Different animations for the same transition type in different places in the app — agree on one.',
                'Разные анимации для одного типа перехода в разных местах приложения — договоритесь об одной.',
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
            Text(
              tr('Transitions Playground', 'Песочница переходов'),
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'A sandbox for transitions between screens. Build your own '
                    'transition on top of PageRouteBuilder (type, direction, '
                    'duration, curve, departing-page behavior), or pick one of '
                    'the ready-made built-in transitions from Material and Cupertino.',
                'Песочница переходов между экранами. Собери свой переход на '
                    'PageRouteBuilder (тип, направление, длительность, кривая, '
                    'поведение уходящей страницы) или возьми готовые «зашитые» '
                    'переходы из Material и Cupertino.',
              ),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

const _pgTypes = ['Slide', 'Fade', 'Scale', 'Slide + Fade', 'Fade + Scale'];
List<String> get _pgDirs => [
  tr('right', 'справа'),
  tr('bottom', 'снизу'),
  tr('left', 'слева'),
  tr('top', 'сверху'),
];
List<String> get _pgExits => [
  tr('none', 'нет'),
  'parallax',
  'zoom out',
  tr('dim', 'затемнение'),
];

/// Playground preview: two mini screens, the second slides in over the first.
Widget _routePreview(BuildContext context, BriefValues v, double t) {
  final e = v.curve('curve').transform(t);
  const w = 110.0, h = 180.0;
  final type = v.text('type');
  final direction = v.text('direction');
  final begin = direction == tr('right', 'справа')
      ? const Offset(1, 0)
      : direction == tr('left', 'слева')
      ? const Offset(-1, 0)
      : direction == tr('top', 'сверху')
      ? const Offset(0, -1)
      : const Offset(0, 1);

  // The departing screen (secondaryAnimation).
  Widget first = _MiniScreen(
    color: const Color(0xFF673AB7),
    title: tr('Screen 1', 'Экран 1'),
  );
  final exit = v.text('exit');
  if (exit == 'parallax') {
    first = Opacity(
      opacity: (1 - 0.3 * e).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(-0.25 * w * e, 0),
        child: first,
      ),
    );
  } else if (exit == 'zoom out') {
    first = Opacity(
      opacity: (1 - 0.4 * e).clamp(0.0, 1.0),
      child: Transform.scale(scale: 1 - 0.1 * e, child: first),
    );
  } else if (exit == tr('dim', 'затемнение')) {
    first = Opacity(opacity: (1 - 0.7 * e).clamp(0.0, 1.0), child: first);
  }

  // The incoming screen.
  Widget second = _MiniScreen(
    color: const Color(0xFF009688),
    title: tr('Screen 2', 'Экран 2'),
  );
  final k = e.clamp(0.0, 1.0);
  switch (type) {
    case 'Slide':
      second = Transform.translate(
        offset: Offset(begin.dx * w * (1 - e), begin.dy * h * (1 - e)),
        child: second,
      );
    case 'Fade':
      second = Opacity(opacity: k, child: second);
    case 'Scale':
      second = Transform.scale(scale: e, child: second);
    case 'Slide + Fade':
      second = Opacity(
        opacity: k,
        child: Transform.translate(
          offset: Offset(
            begin.dx * w * 0.3 * (1 - e),
            begin.dy * h * 0.3 * (1 - e),
          ),
          child: second,
        ),
      );
    default:
      second = Opacity(
        opacity: k,
        child: Transform.scale(scale: 0.85 + 0.15 * e, child: second),
      );
  }

  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Container(
      width: w,
      height: h,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black87, width: 3),
      ),
      child: Stack(fit: StackFit.expand, children: [first, second]),
    ),
  );
}

/// Mini screen for the preview: a header + placeholder rows.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.color, required this.title});
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            color: color,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          for (var i = 0; i < 5; i++)
            Container(
              height: 12,
              margin: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
