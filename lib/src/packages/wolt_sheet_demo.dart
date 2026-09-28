// Showcase of the wolt_modal_sheet package — multi-page modal sheets:
//   • A flow of three pages with "forward/back" transitions inside one sheet;
//   • Modal type of your choice: bottom sheet / dialog / side sheet / alert,
//     or "Auto" — the type is picked based on screen width (and switches on the fly);
//   • Sticky action bar and a hero image;
//   • A header that appears on scroll, and a fading hero image.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../common/anim_block.dart';
import '../common/animation_controls.dart';
import '../common/brief_playground.dart';
import '../common/designer_brief.dart';
import '../common/i18n.dart';
import '../common/intro_card.dart';
import 'package_spec.dart';

class WoltSheetDemo extends StatelessWidget {
  const WoltSheetDemo({super.key});
  static const String routeName = 'packages/wolt_modal_sheet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wolt Modal Sheet'),
        actions: const [LangButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntroCard(
            title: tr('Multi-page sheets', 'Многостраничные шторки'),
            text: tr(
              'The wolt_modal_sheet package (from the Wolt app) is a modal window '
                  'that hosts several pages inside it: pick a dish → extras → '
                  'confirmation, all without closing the sheet. Pages flip with a '
                  'soft slide-and-fade, and the height adjusts to the content. The '
                  'same sheet is a bottom sheet on the phone, a dialog on tablet, and '
                  'a side panel on desktop.',
              'Пакет wolt_modal_sheet (из приложения Wolt) — модальное окно, '
                  'внутри которого живёт несколько страниц: выбрал блюдо → '
                  'добавки → подтверждение, и всё это не закрывая шторку. '
                  'Страницы перелистываются мягким сдвигом с затуханием, высота '
                  'подстраивается под контент. Одна и та же шторка на телефоне — '
                  'снизу, на планшете — диалогом, на десктопе — боковой панелью.',
            ),
            hint: tr(
              'Pick a type and press "Open sheet". In "Auto" mode, open the sheet '
                  'and resize the browser window — the type will switch on the fly.',
              'Выбери тип и нажми «Открыть шторку». В режиме «Авто» открой '
                  'шторку и меняй ширину окна браузера — тип переключится на лету.',
            ),
          ),
          const SizedBox(height: 16),
          const _FlowBlock(),
          const SizedBox(height: 16),
          const _ScrollBlock(),
          const SizedBox(height: 16),
          DesignerBrief(
            playground: BriefPlayground(
              durationKey: 'paginationDuration_ms',
              fields: [
                BriefField.duration(
                  'paginationDuration_ms',
                  tr('Page flip (paginationDuration)', 'Перелистывание (paginationDuration)'),
                  350,
                ),
                BriefField.curve('slide_curve', tr('Page slide curve', 'Кривая сдвига страниц'), 'fastOutSlowIn'),
                BriefField.duration(
                  'transitionDuration_ms',
                  tr('Sheet appearance (transitionDuration)', 'Появление шторки (transitionDuration)'),
                  350,
                ),
                BriefField.choice(
                  'kind',
                  tr('Modal type', 'Тип модалки'),
                  [tr('Bottom sheet', 'Bottom sheet'), tr('Dialog', 'Диалог'), tr('Side panel', 'Боковая панель')],
                  tr('Bottom sheet', 'Bottom sheet'),
                ),
                BriefField.number(
                  'breakpoint_px',
                  tr('Bottom sheet → dialog breakpoint', 'Брейкпоинт bottom sheet → диалог'),
                  524,
                  unit: 'px',
                  min: 0,
                  max: 4000,
                ),
                BriefField.number('heroImageHeight', tr('Hero height', 'Высота hero'), 200, unit: 'px', min: 0, max: 600),
              ],
              builder: _woltPlayground,
            ),
            items: [
              (
                tr('Page flow', 'Флоу страниц'),
                tr(
                  'a diagram: which pages, in which order, where the "Next" / "Back" buttons lead, where it can be closed',
                  'схема: какие страницы, в каком порядке, куда ведут кнопки «Далее» / «Назад», где можно закрыть',
                ),
              ),
              (
                tr('Type by breakpoint', 'Тип по брейкпоинтам'),
                tr(
                  'bottom sheet / dialog / side panel / alert — and at which screen width which one (e.g. < 524 px — bottom)',
                  'bottom sheet / диалог / боковая панель / alert — и при какой ширине экрана какой (например, < 524 px — снизу)',
                ),
              ),
              (
                tr('Each page', 'Каждая страница'),
                tr(
                  'hero image (height in px), title, header on scroll, sticky action bar with buttons',
                  'hero-картинка (высота px), заголовок, шапка при скролле, sticky action bar с кнопками',
                ),
              ),
              (
                tr('Timings', 'Тайминги'),
                tr(
                  'sheet appearance (transitionDuration), closing, page flip (paginationDuration) in ms',
                  'появление шторки (transitionDuration), закрытие, перелистывание страниц (paginationDuration) в мс',
                ),
              ),
              (
                tr('Page flip curve', 'Кривая перелистывания'),
                tr(
                  'how the page slides in on change — a preset or a cubic-bezier from Figma',
                  'как страница выезжает при смене — пресет или cubic-bezier из Figma',
                ),
              ),
              (
                tr('Scroll', 'Скролл'),
                tr(
                  'how the hero fades (opacity / scale at the end), when the header appears',
                  'как тает hero (opacity / scale в конце), когда проявляется шапка',
                ),
              ),
              (
                tr('Details', 'Детали'),
                tr(
                  'the drag handle, background dimming color, corner radii',
                  'ручка для свайпа (drag handle), цвет затемнения фона, скругления углов',
                ),
              ),
            ],
            avoid: [
              tr(
                'Different page heights without a smooth transition in the design — the package '
                    'animates the height anyway, better to show how.',
                'Разные высоты страниц без плавного перехода в макете — пакет всё равно анимирует высоту, лучше показать, как.',
              ),
              tr(
                'Flows that are too long (> 4–5 pages) in one sheet — the user gets lost.',
                'Слишком длинные флоу (> 4–5 страниц) в одной шторке — пользователь теряется.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── shared bits

enum _SheetKind { auto, bottom, dialog, side, alert }

Map<_SheetKind, String> get _kindNames => {
  _SheetKind.auto: tr('Auto (by width)', 'Авто (по ширине)'),
  _SheetKind.bottom: 'Bottom sheet',
  _SheetKind.dialog: tr('Dialog', 'Диалог'),
  _SheetKind.side: tr('Side panel', 'Боковая панель'),
  _SheetKind.alert: 'Alert',
};

/// Our "Auto" rule: phone — bottom sheet, tablet — dialog, wide — side sheet.
_SheetKind _autoKind(double width) {
  if (width < 524) return _SheetKind.bottom;
  if (width < 1100) return _SheetKind.dialog;
  return _SheetKind.side;
}

/// All sheet settings in one place.
class _SheetConfig {
  const _SheetConfig({
    required this.kind,
    required this.paginationMs,
    required this.enterMs,
    required this.dragHandle,
    required this.heroImage,
    this.slideCurve = 'fastOutSlowIn',
    this.heroScaleEnd = 1,
    this.heroOpacityEnd = 0,
  });

  final _SheetKind kind;
  final int paginationMs;
  final int enterMs;
  final bool dragHandle;
  final bool heroImage;

  /// Content slide curve when paginating (in the package — Interval 50/350…1).
  final String slideCurve;
  final double heroScaleEnd;
  final double heroOpacityEnd;

  static const _heroHeight = 200;

  /// The "Spec" using wolt_modal_sheet's own parameter names.
  Map<String, Object?> spec(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolved = kind == _SheetKind.auto ? _autoKind(width) : kind;
    return {
      'package': packageSpec('wolt_modal_sheet'),
      'widget': 'WoltModalSheet.show',
      'modal_type_mode': kind == _SheetKind.auto ? 'auto' : kind.name,
      if (kind == _SheetKind.auto)
        'breakpoints_px': {'bottom_sheet': '< 524', 'dialog': '524–1099', 'side_sheet': '≥ 1100'},
      'modal_type_now': switch (resolved) {
        _SheetKind.dialog => 'WoltDialogType',
        _SheetKind.side => 'WoltSideSheetType',
        _SheetKind.alert => 'WoltAlertDialogType',
        _ => 'WoltBottomSheetType',
      },
      'screen_width_px': width.round(),
      'transitionDuration_ms': resolved == _SheetKind.alert ? tr('package default', 'по умолчанию пакета') : enterMs,
      'reverseTransitionDuration_ms':
          resolved == _SheetKind.alert ? tr('package default', 'по умолчанию пакета') : (enterMs * 0.75).round(),
      if (resolved == _SheetKind.bottom) 'showDragHandle': dragHandle,
      'modalBarrierColor': hexColor(Colors.black54),
      'paginationAnimationStyle': {
        'paginationDuration_ms': paginationMs,
        'mainContentSlidePositionCurve': 'Interval(50/350, 1, curve: $slideCurve)',
        ...timingSpec(durationMs: paginationMs, curve: slideCurve),
        'curve_dart': curveCode(slideCurve),
      },
      'scrollAnimationStyle': {
        'heroImageScaleEnd': round2(heroScaleEnd),
        'heroImageOpacityEnd': round2(heroOpacityEnd),
      },
      'heroImage': heroImage,
      'heroImageHeight_px': _heroHeight,
    };
  }

  WoltModalType typeFor(BuildContext context) {
    final enter = Duration(milliseconds: enterMs);
    final exit = Duration(milliseconds: (enterMs * 0.75).round());
    final resolved = kind == _SheetKind.auto ? _autoKind(MediaQuery.sizeOf(context).width) : kind;
    return switch (resolved) {
      _SheetKind.dialog => WoltDialogType(transitionDuration: enter, reverseTransitionDuration: exit),
      _SheetKind.side => WoltSideSheetType(transitionDuration: enter, reverseTransitionDuration: exit),
      _SheetKind.alert => const WoltAlertDialogType(),
      _ => WoltBottomSheetType(
        transitionDuration: enter,
        reverseTransitionDuration: exit,
        showDragHandle: dragHandle,
      ),
    };
  }

  /// Sheet theme: page pagination duration, hero height.
  Widget decorate(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! WoltModalSheetThemeData),
          WoltModalSheetThemeData(
            heroImageHeight: _heroHeight.toDouble(),
            mainContentScrollPhysics: const ClampingScrollPhysics(),
            animationStyle: WoltModalSheetAnimationStyle(
              paginationAnimationStyle: WoltModalSheetPaginationAnimationStyle(
                paginationDuration: Duration(milliseconds: paginationMs),
                mainContentIncomingSlidePositionCurve: Interval(
                  50 / 350,
                  1,
                  curve: resolveCurve(slideCurve),
                ),
                mainContentOutgoingSlidePositionCurve: Interval(
                  50 / 350,
                  1,
                  curve: resolveCurve(slideCurve),
                ),
              ),
              scrollAnimationStyle: WoltModalSheetScrollAnimationStyle(
                heroImageScaleEnd: heroScaleEnd,
                heroImageOpacityEnd: heroOpacityEnd,
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _heroImage(String asset) => Image.asset(asset, fit: BoxFit.cover);

/// Full-width button for the sticky action bar.
class _SabButton extends StatelessWidget {
  const _SabButton({required this.label, required this.onPressed, this.primary = true});

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 48,
      width: double.infinity,
      child: Center(child: Text(label, overflow: TextOverflow.ellipsis)),
    );
    return primary
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}

// ──────────────────────────────────────────────────────── flow of 3 pages

List<(String, String, int)> get _dishes => [
  (tr('Salmon bowl', 'Боул с лососем'), tr('rice, avocado, edamame', 'рис, авокадо, эдамаме'), 690),
  (tr('Tom yum', 'Том ям'), tr('shrimp, coconut milk', 'креветки, кокосовое молоко'), 540),
  (tr('Pad thai', 'Пад тай'), tr('rice noodles, peanuts', 'рисовая лапша, арахис'), 480),
];

List<String> get _extras => [
  tr('Double portion', 'Двойная порция'),
  tr('Hot sauce', 'Острый соус'),
  tr('Sesame', 'Кунжут'),
  tr('Lime', 'Лайм'),
  tr('Chopsticks', 'Палочки'),
];

class _FlowBlock extends StatefulWidget {
  const _FlowBlock();

  @override
  State<_FlowBlock> createState() => _FlowBlockState();
}

class _FlowBlockState extends State<_FlowBlock> {
  _SheetKind _kind = _SheetKind.auto;
  double _paginationMs = 350;
  double _enterMs = 350;
  bool _dragHandle = true;
  bool _hero = true;
  String _slideCurve = 'fastOutSlowIn';

  // The "order" state inside the sheet.
  final _dish = ValueNotifier<int>(0);
  final _chosenExtras = ValueNotifier<Set<int>>({1});

  _SheetConfig get _config => _SheetConfig(
    kind: _kind,
    paginationMs: _paginationMs.round(),
    enterMs: _enterMs.round(),
    dragHandle: _dragHandle,
    heroImage: _hero,
    slideCurve: _slideCurve,
  );

  @override
  void dispose() {
    _dish.dispose();
    _chosenExtras.dispose();
    super.dispose();
  }

  void _open() {
    final config = _config;
    WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: config.typeFor,
      modalDecorator: (child) => config.decorate(context, child),
      modalBarrierColor: Colors.black54,
      pageListBuilder: (sheetContext) => [
        _dishPage(sheetContext, config),
        _extrasPage(sheetContext),
        _donePage(sheetContext),
      ],
    );
  }

  Widget _close(BuildContext sheetContext) => IconButton(
    padding: const EdgeInsets.all(16),
    icon: const Icon(Icons.close),
    onPressed: Navigator.of(sheetContext).pop,
  );

  Widget _back(BuildContext sheetContext) => IconButton(
    padding: const EdgeInsets.all(16),
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: WoltModalSheet.of(sheetContext).showPrevious,
  );

  SliverWoltModalSheetPage _dishPage(BuildContext sheetContext, _SheetConfig config) {
    final textTheme = Theme.of(context).textTheme;
    return WoltModalSheetPage(
      heroImage: config.heroImage ? _heroImage('assets/eat_sydney_sm.jpg') : null,
      pageTitle: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(tr('Step 1 of 3 · Pick a dish', 'Шаг 1 из 3 · Выбери блюдо'), style: textTheme.titleLarge),
      ),
      topBarTitle: Text(tr('Pick a dish', 'Выбери блюдо'), style: textTheme.titleSmall),
      trailingNavBarWidget: _close(sheetContext),
      stickyActionBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _SabButton(label: tr('Next', 'Далее'), onPressed: WoltModalSheet.of(sheetContext).showNext),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: ValueListenableBuilder(
          valueListenable: _dish,
          builder: (context, selected, _) => Column(
            children: [
              for (final (i, (name, desc, price)) in _dishes.indexed)
                Card.outlined(
                  color: i == selected ? kAccent.withValues(alpha: 0.08) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: i == selected ? kAccent : Colors.black12),
                  ),
                  child: ListTile(
                    onTap: () => _dish.value = i,
                    leading: Icon(
                      i == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: kAccent,
                    ),
                    title: Text(name),
                    subtitle: Text(desc),
                    trailing: Text(tr('\$${(price / 100).toStringAsFixed(2)}', '$price ₽')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverWoltModalSheetPage _extrasPage(BuildContext sheetContext) {
    final textTheme = Theme.of(context).textTheme;
    return WoltModalSheetPage(
      pageTitle: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(tr('Step 2 of 3 · Extras', 'Шаг 2 из 3 · Добавки'), style: textTheme.titleLarge),
      ),
      topBarTitle: Text(tr('Extras', 'Добавки'), style: textTheme.titleSmall),
      isTopBarLayerAlwaysVisible: true,
      leadingNavBarWidget: _back(sheetContext),
      trailingNavBarWidget: _close(sheetContext),
      stickyActionBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SabButton(
                label: tr('Back', 'Назад'),
                primary: false,
                onPressed: WoltModalSheet.of(sheetContext).showPrevious,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SabButton(label: tr('Order', 'Заказать'), onPressed: WoltModalSheet.of(sheetContext).showNext),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
        child: ValueListenableBuilder(
          valueListenable: _chosenExtras,
          builder: (context, chosen, _) => Column(
            children: [
              for (final (i, name) in _extras.indexed)
                CheckboxListTile(
                  value: chosen.contains(i),
                  title: Text(name),
                  onChanged: (v) {
                    final next = {...chosen};
                    v == true ? next.add(i) : next.remove(i);
                    _chosenExtras.value = next;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverWoltModalSheetPage _donePage(BuildContext sheetContext) {
    final textTheme = Theme.of(context).textTheme;
    return WoltModalSheetPage(
      hasTopBarLayer: false,
      trailingNavBarWidget: _close(sheetContext),
      stickyActionBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _SabButton(label: tr('Close', 'Закрыть'), onPressed: Navigator.of(sheetContext).pop),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
        child: Column(
          children: [
            // The checkmark "pops" when the page appears.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, t, child) => Transform.scale(scale: t, child: child),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('Order placed!', 'Заказ оформлен!'), style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: Listenable.merge([_dish, _chosenExtras]),
              builder: (context, _) => Text(
                tr(
                  '${_dishes[_dish.value].$1} + extras: ${_chosenExtras.value.length}. '
                      'The sheet got shorter — its height smoothly adjusted to the content.',
                  '${_dishes[_dish.value].$1} + добавок: ${_chosenExtras.value.length}. '
                      'Шторка стала ниже — высота плавно подстроилась под контент.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolved = _kind == _SheetKind.auto ? _autoKind(width) : _kind;
    final onPageNote = tr('on the page:', 'на странице:');
    return AnimBlock(
      title: tr('A flow of three pages', 'Флоу из трёх страниц'),
      spec: () => {
        ..._config.spec(context),
        'pages': [
          {
            'page': 1,
            'title': tr('Pick a dish', 'Выбери блюдо'),
            'heroImage': _hero,
            'stickyActionBar': [tr('Next', 'Далее')],
            'nav': ['close'],
          },
          {
            'page': 2,
            'title': tr('Extras', 'Добавки'),
            'isTopBarLayerAlwaysVisible': true,
            'stickyActionBar': [tr('Back', 'Назад'), tr('Order', 'Заказать')],
            'nav': ['back', 'close'],
          },
          {
            'page': 3,
            'title': tr('Done', 'Готово'),
            'hasTopBarLayer': false,
            'stickyActionBar': [tr('Close', 'Закрыть')],
            'success_icon': {'curve': 'elasticOut', 'duration_ms': 700},
          },
        ],
      },
      description: tr(
        'Pick a dish → extras → "done" inside one sheet. On a transition, the '
            'old page slides away a third of the width and fades, the new one '
            'comes in from the right; the buttons at the bottom (sticky action '
            'bar) are always visible. On the left — a diagram of where the '
            'sheet of the chosen type ends up.',
        'Выбор блюда → добавки → «готово» внутри одной шторки. При переходе '
            'старая страница уезжает на треть ширины и тает, новая приходит '
            'справа; кнопки внизу (sticky action bar) всегда видны. Слева — '
            'схема: куда встанет шторка выбранного типа.',
      ),
      preview: GestureDetector(
        onTap: _open,
        child: _TypePreview(kind: resolved),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Modal type', 'Тип модалки'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in _SheetKind.values)
                ChoiceChip(
                  label: Text(_kindNames[k]!),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _kind == _SheetKind.auto
                ? tr(
                    'Current width is ${width.round()} px → "${_kindNames[resolved]}". '
                        'Up to 524 px — bottom, up to 1100 — dialog, wider — side.',
                    'Сейчас ширина ${width.round()} px → «${_kindNames[resolved]}». '
                        'До 524 px — снизу, до 1100 — диалог, шире — сбоку.',
                  )
                : tr('The type is fixed, doesn\'t depend on width.', 'Тип зафиксирован, от ширины не зависит.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Page flip', 'Перелистывание страниц'),
            value: _paginationMs,
            min: 150,
            max: 1500,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _paginationMs = v),
          ),
          CurveDropdown(
            value: _slideCurve,
            onChanged: (v) => setState(() => _slideCurve = v),
          ),
          Text(
            tr(
              'The page slide curve on flip (mainContentSlidePositionCurve).',
              'Кривая сдвига страниц при перелистывании '
                  '(mainContentSlidePositionCurve).',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Sheet appearance', 'Появление шторки'),
            value: _enterMs,
            min: 150,
            max: 1200,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => _enterMs = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(tr('Hero image', 'Hero-картинка')),
                selected: _hero,
                onSelected: (v) => setState(() => _hero = v),
              ),
              FilterChip(
                label: Text(tr('Drag handle', 'Ручка для свайпа')),
                selected: _dragHandle,
                onSelected: (v) => setState(() => _dragHandle = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.open_in_new),
            label: Text(tr('Open sheet', 'Открыть шторку')),
          ),
          const SizedBox(height: 8),
          _CodeBox(
            'WoltModalSheet.show(\n'
            '  context: context,\n'
            '  pageListBuilder: (ctx) => [dish, extras, done],\n'
            '  modalTypeBuilder: (ctx) => width < 524\n'
            '      ? WoltModalType.bottomSheet()\n'
            '      : WoltModalType.dialog(),\n'
            ');\n'
            '// $onPageNote WoltModalSheet.of(ctx).showNext()',
          ),
        ],
      ),
    );
  }
}

/// Diagram of the "screen": where the sheet of the chosen type ends up.
/// Inside the mini-sheet, pages paginate on their own — just like the real one.
class _TypePreview extends StatefulWidget {
  const _TypePreview({required this.kind});

  final _SheetKind kind;

  @override
  State<_TypePreview> createState() => _TypePreviewState();
}

class _TypePreviewState extends State<_TypePreview> {
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _page = (_page + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Rect _sheetRect(Size s) => switch (widget.kind) {
    _SheetKind.dialog => Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.6, height: s.height * 0.75),
    _SheetKind.side => Rect.fromLTWH(s.width * 0.58, 0, s.width * 0.42, s.height),
    _SheetKind.alert => Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.5, height: s.height * 0.4),
    _ => Rect.fromLTWH(0, s.height * 0.3, s.width, s.height * 0.7),
  };

  BorderRadius get _radius => switch (widget.kind) {
    _SheetKind.side => const BorderRadius.horizontal(left: Radius.circular(12)),
    _SheetKind.bottom || _SheetKind.auto => const BorderRadius.vertical(top: Radius.circular(12)),
    _ => BorderRadius.circular(12),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final rect = _sheetRect(size);
        return Stack(
          children: [
            // The "app" under the dimmed overlay.
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE9E4F2),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 16,
                        width: size.width * (0.8 - i * 0.12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: ColoredBox(color: Colors.black38)),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(color: Colors.white, borderRadius: _radius),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) {
                    // As in Wolt: a 30% slide + fade.
                    final incoming = child.key == ValueKey(_page);
                    final begin = incoming ? const Offset(0.3, 0) : const Offset(-0.3, 0);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(begin: begin, end: Offset.zero).animate(
                          CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _MiniPage(key: ValueKey(_page), index: _page),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  tr('tap to open', 'тапни, чтобы открыть'),
                  style: const TextStyle(fontSize: 11, color: kAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mini page in the diagram: hero, text lines, and a sticky button at the bottom.
class _MiniPage extends StatelessWidget {
  const _MiniPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFFFB74D), Color(0xFF81C784), Color(0xFF64B5F6)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 3,
          child: Container(
            color: colors[index],
            alignment: Alignment.center,
            child: Text(
              '${index + 1}/3',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 3; i++)
                  Flexible(
                    child: FractionallySizedBox(
                      widthFactor: 0.9 - i * 0.2,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 22,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(6)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── scroll: header and hero

class _ScrollBlock extends StatefulWidget {
  const _ScrollBlock();

  @override
  State<_ScrollBlock> createState() => _ScrollBlockState();
}

class _ScrollBlockState extends State<_ScrollBlock> {
  _SheetKind _kind = _SheetKind.auto;
  double _heroScaleEnd = 1;
  double _heroOpacityEnd = 0;

  _SheetConfig get _config => _SheetConfig(
    kind: _kind,
    paginationMs: 350,
    enterMs: 350,
    dragHandle: true,
    heroImage: true,
    heroScaleEnd: _heroScaleEnd,
    heroOpacityEnd: _heroOpacityEnd,
  );

  void _open() {
    final config = _config;
    WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: config.typeFor,
      modalDecorator: (child) => config.decorate(context, child),
      modalBarrierColor: Colors.black54,
      pageListBuilder: (sheetContext) {
        final textTheme = Theme.of(context).textTheme;
        return [
          SliverWoltModalSheetPage(
            heroImage: _heroImage('assets/eat_new_orleans_sm.jpg'),
            pageTitle: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(tr('Restaurant menu', 'Меню ресторана'), style: textTheme.headlineSmall),
            ),
            topBarTitle: Text(tr('Restaurant menu', 'Меню ресторана'), style: textTheme.titleSmall),
            trailingNavBarWidget: IconButton(
              padding: const EdgeInsets.all(16),
              icon: const Icon(Icons.close),
              onPressed: Navigator.of(sheetContext).pop,
            ),
            stickyActionBar: Padding(
              padding: const EdgeInsets.all(16),
              child: _SabButton(label: tr('Add to cart', 'В корзину'), onPressed: Navigator.of(sheetContext).pop),
            ),
            mainContentSliversBuilder: (context) => [
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96),
                sliver: SliverList.builder(
                  itemCount: 24,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.primaries[i % Colors.primaries.length].shade200,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(tr('Menu item #${i + 1}', 'Позиция меню №${i + 1}')),
                    subtitle: Text(tr('Scroll — the header will appear', 'Прокрути — шапка проявится')),
                    trailing: Text(tr('\$${((300 + i * 20) / 100).toStringAsFixed(2)}', '${300 + i * 20} ₽')),
                  ),
                ),
              ),
            ],
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuLabel = tr('Menu', 'Меню');
    return AnimBlock(
      title: tr('Header and hero on scroll', 'Шапка и hero при скролле'),
      spec: () => {
        ..._config.spec(context),
        'page': {
          'widget': 'SliverWoltModalSheetPage',
          'title': tr('Restaurant menu', 'Меню ресторана'),
          'stickyActionBar': [tr('Add to cart', 'В корзину')],
          'items': 24,
          'topBar': tr(
            'appears on scroll (opacity 0→1, title shifts 8 px)',
            'проявляется при скролле (opacity 0→1, title сдвиг 8 px)',
          ),
        },
      },
      description: tr(
        'A long page: as you scroll, the hero image fades, and a header with a '
            'title appears at the top (the page title seems to "drive into" it). '
            'The "Add to cart" button sticks to the bottom with a soft gradient.',
        'Длинная страница: пока листаешь, hero-картинка тает, а сверху '
            'проявляется шапка с заголовком (заголовок страницы как бы «въезжает» '
            'в неё). Кнопка «В корзину» прилипает к низу с мягким градиентом.',
      ),
      preview: GestureDetector(
        onTap: _open,
        child: const _ScrollPreview(),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in [_SheetKind.auto, _SheetKind.bottom, _SheetKind.dialog, _SheetKind.side])
                ChoiceChip(
                  label: Text(_kindNames[k]!),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: tr('Hero at end of scroll: scale (heroImageScaleEnd)', 'Hero в конце скролла: масштаб (heroImageScaleEnd)'),
            value: _heroScaleEnd,
            min: 1,
            max: 1.5,
            unit: '×',
            fractionDigits: 2,
            onChanged: (v) => setState(() => _heroScaleEnd = v),
          ),
          LabeledSlider(
            label: tr(
              'Hero at end of scroll: opacity (heroImageOpacityEnd)',
              'Hero в конце скролла: прозрачность (heroImageOpacityEnd)',
            ),
            value: _heroOpacityEnd,
            min: 0,
            max: 1,
            fractionDigits: 2,
            onChanged: (v) => setState(() => _heroOpacityEnd = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.open_in_new),
            label: Text(tr('Open the long page', 'Открыть длинную страницу')),
          ),
          const SizedBox(height: 8),
          _CodeBox(
            'SliverWoltModalSheetPage(\n'
            '  heroImage: Image.asset(...),\n'
            '  topBarTitle: Text(\'$menuLabel\'),\n'
            '  stickyActionBar: button,\n'
            '  mainContentSliversBuilder: (ctx) => [SliverList(...)],\n'
            ')',
          ),
        ],
      ),
    );
  }
}

/// Scroll diagram: the hero fades out, the header fades in — on a loop.
class _ScrollPreview extends StatefulWidget {
  const _ScrollPreview();

  @override
  State<_ScrollPreview> createState() => _ScrollPreviewState();
}

class _ScrollPreviewState extends State<_ScrollPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final scroll = t * h * 0.55;
            return Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
                // Content with the hero scrolls up.
                Positioned(
                  top: -scroll,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Opacity(
                        opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                        child: SizedBox(
                          height: h * 0.45,
                          child: Image.asset('assets/eat_new_orleans_sm.jpg', fit: BoxFit.cover),
                        ),
                      ),
                      for (var i = 0; i < 8; i++)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: Colors.primaries[i % Colors.primaries.length].shade200,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // The header fades in, the title slides up slightly.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Opacity(
                    opacity: ((t - 0.4) / 0.4).clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - ((t - 0.4) / 0.4).clamp(0.0, 1.0))),
                        child: Text(
                          tr('Restaurant menu', 'Меню ресторана'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                // Sticky button with a gradient.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Colors.white],
                      ),
                    ),
                    child: Container(
                      height: 26,
                      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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

/// Page 1 → 2 transition inside the sheet of the chosen type, using the
/// package's own intervals: the outgoing page fades out over 50-150/350 and
/// slides, the incoming one fades in over 150-350/350 and slides in from the
/// right along the entered curve (slide — 50/350…1).
Widget _woltPlayground(BuildContext context, BriefValues v, double t) {
  final slide = Interval(50 / 350, 1, curve: v.curve('slide_curve')).transform(t);
  final outOpacity = 1 - const Interval(50 / 350, 150 / 350).transform(t);
  final inOpacity = const Interval(150 / 350, 1).transform(t);
  final kind = v.text('kind');
  final heroFactor = (v.number('heroImageHeight') / 400).clamp(0.0, 0.6);
  return LayoutBuilder(
    builder: (context, c) {
      final s = c.biggest;
      final Rect rect;
      if (kind == tr('Dialog', 'Диалог')) {
        rect = Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.6, height: s.height * 0.8);
      } else if (kind == tr('Side panel', 'Боковая панель')) {
        rect = Rect.fromLTWH(s.width * 0.55, 0, s.width * 0.45, s.height);
      } else {
        rect = Rect.fromLTWH(0, s.height * 0.22, s.width, s.height * 0.78);
      }
      Widget page(int n, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: rect.height * heroFactor,
            color: color,
            alignment: Alignment.center,
            child: Text('$n/2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          for (var i = 0; i < 2; i++)
            Container(
              height: 8,
              margin: const EdgeInsets.fromLTRB(10, 10, 40, 0),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
            ),
          const Spacer(),
          Container(
            height: 22,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(6)),
          ),
        ],
      );
      return Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF8A8494))),
          Positioned.fromRect(
            rect: rect,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: kind == 'Bottom sheet'
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(-0.3 * slide, 0),
                      child: Opacity(opacity: outOpacity.clamp(0.0, 1.0), child: page(1, const Color(0xFFFFB74D))),
                    ),
                  ),
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(0.3 * (1 - slide), 0),
                      child: Opacity(opacity: inOpacity.clamp(0.0, 1.0), child: page(2, const Color(0xFF64B5F6))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
