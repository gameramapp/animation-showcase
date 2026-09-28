// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:heroine/heroine.dart';

import 'src/basics/basics.dart';
import 'src/config/config.dart';
import 'src/explicit/explicit.dart';
import 'src/hero/hero.dart';
import 'src/common/i18n.dart';
import 'src/home/demo_previews.dart';
import 'src/micro/micro.dart';
import 'src/packages/flutter_animate_demo.dart';
import 'src/packages/packages_content.dart';
import 'src/packages/packages_interaction.dart';
import 'src/packages/packages_media.dart';
import 'src/packages/packages_ui.dart';
import 'src/painting/painting.dart';
import 'src/routing/routing.dart';
import 'src/scroll/scroll.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLang();
  runApp(const AnimationSamples());
}

/// How much effort it takes to build this animation in the product — a hint
/// to the designer for what's "cheap" and what will need a separate task.
///
/// [label] and [explanation] are computed from [tr] so they follow the
/// current language; only [color] is a fixed, language-independent value.
enum Effort {
  easy(Color(0xFF2E7D32)),
  medium(Color(0xFFEF6C00)),
  hard(Color(0xFFC62828));

  const Effort(this.color);
  final Color color;

  String get label => switch (this) {
    Effort.easy => tr('Easy', 'Легко'),
    Effort.medium => tr('Medium', 'Средне'),
    Effort.hard => tr('Hard', 'Сложно'),
  };

  String get explanation => switch (this) {
    Effort.easy => tr('ready-made Flutter widgets, a couple of lines of code', 'готовые виджеты Flutter, пара строк кода'),
    Effort.medium => tr('custom logic, but standard tools', 'своя логика, но стандартные инструменты'),
    Effort.hard => tr('manual drawing or physics, built per task', 'ручная отрисовка или физика, делается под задачу'),
  };
}

class Demo {
  final String name;
  final String route;
  final WidgetBuilder builder;

  /// One line for the designer: what the effect is and where it's useful.
  final String description;
  final Effort effort;

  /// A 72×72 mini-animation for the home screen — shows the gist of the screen.
  /// Built by the helpers in lib/src/home/demo_previews.dart.
  final Widget? preview;

  const Demo({
    required this.name,
    required this.route,
    required this.builder,
    this.description = '',
    this.effort = Effort.easy,
    this.preview,
  });
}

class DemoCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Demo> demos;

  const DemoCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.demos,
  });
}

// The lists below build fresh Demo/DemoCategory objects (with names and
// descriptions resolved through tr()) every time they're called — that's why
// they're functions, not top-level `final`s: a `final` would freeze the
// strings in whatever language was active the first time it ran.

List<Demo> basicDemos() => [
  Demo(
    name: 'AnimatedContainer',
    route: AnimatedContainerDemo.routeName,
    builder: (context) => const AnimatedContainerDemo(),
    preview: animatedContainerPreview(),
    description: tr(
      'Size, color, corner radius, shadow, padding — all smoothly animated, with any curve.',
      'Размер, цвет, скругление, тень, отступы — всё плавно, со всеми кривыми.',
    ),
  ),
  Demo(
    name: 'Implicit Animations',
    route: ImplicitAnimationsDemo.routeName,
    builder: (context) => const ImplicitAnimationsDemo(),
    preview: implicitPreview(),
    description: 'Align, Scale, Rotation, Opacity, Padding, Slide, Positioned, PhysicalModel.',
  ),
  Demo(
    name: 'Switch Animations',
    route: AnimatedSizeDemo.routeName,
    builder: (context) => const AnimatedSizeDemo(),
    preview: switchPreview(),
    description: tr(
      'Expanding blocks, content swaps, cross-fade between two states.',
      'Раскрытие блоков, смена контента, кросс-фейд двух состояний.',
    ),
  ),
  Demo(
    name: 'Text & Theme',
    route: TextThemeAnimationsDemo.routeName,
    builder: (context) => const TextThemeAnimationsDemo(),
    preview: textThemePreview(),
    description: tr(
      'Smooth text style changes and a whole color theme morphing.',
      'Плавная смена стиля текста и перетекание целой цветовой темы.',
    ),
  ),
];

List<Demo> explicitDemos() => [
  Demo(
    name: 'Controller & Transitions',
    route: ControllerTransitionsDemo.routeName,
    builder: (context) => const ControllerTransitionsDemo(),
    preview: controllerPreview(),
    description: tr(
      'A play/reverse/repeat remote, every *Transition, TweenAnimationBuilder, a 3D flip.',
      'Пульт play/reverse/repeat, все *Transition, TweenAnimationBuilder, 3D-переворот.',
    ),
  ),
  Demo(
    name: 'Staggered & Keyframes',
    route: StaggeredDemo.routeName,
    builder: (context) => const StaggeredDemo(),
    preview: staggeredPreview(),
    description: tr(
      'A card assembled on a timeline, a list appearing one by one, keyframes.',
      'Сборка карточки по таймлайну, появление списка по очереди, ключевые кадры.',
    ),
    effort: Effort.medium,
  ),
];

List<Demo> routingDemos() => [
  Demo(
    name: 'Routing & Transitions',
    route: RoutingDemo.routeName,
    builder: (context) => const RoutingDemo(),
    preview: routingPreview(),
    description: tr(
      'A sandbox for screen transitions: type, direction, speed, curve.',
      'Песочница переходов между экранами: тип, направление, скорость, кривая.',
    ),
  ),
  Demo(
    name: 'Hero & Heroine',
    route: HeroDemo.routeName,
    builder: (context) => const HeroDemo(),
    preview: heroPreview(),
    description: tr(
      'An element "flies" between screens; a spring variant and swipe-to-dismiss.',
      'Элемент «перелетает» между экранами; пружинный вариант и свайп-закрытие.',
    ),
  ),
  Demo(
    name: 'Material Motion',
    route: MaterialMotionDemo.routeName,
    builder: (context) => const MaterialMotionDemo(),
    preview: materialMotionPreview(),
    description: tr(
      'Official Material patterns: card → screen, shared axis, fade through.',
      'Официальные паттерны Material: карточка → экран, shared axis, fade through.',
    ),
  ),
];

List<Demo> microDemos() => [
  Demo(
    name: 'Micro-interactions',
    route: MicroInteractionsDemo.routeName,
    builder: (context) => const MicroInteractionsDemo(),
    preview: microPreview(),
    description: tr(
      'Morphing icons, likes, button feedback, error shake, switches, loaders.',
      'Иконки-морфы, лайк, отклик кнопок, тряска при ошибке, переключатели, лоадеры.',
    ),
    effort: Effort.medium,
  ),
];

List<Demo> scrollDemos() => [
  Demo(
    name: 'Scroll Effects',
    route: ScrollEffectsDemo.routeName,
    builder: (context) => const ScrollEffectsDemo(),
    preview: scrollPreview(),
    description: tr(
      'A collapsing header, parallax, reading progress, reveal on scroll.',
      'Сжимающаяся шапка, параллакс, прогресс чтения, появление при скролле.',
    ),
    effort: Effort.medium,
  ),
];

List<Demo> paintingDemos() => [
  Demo(
    name: 'CustomPainter & Canvas',
    route: CustomPainterDemo.routeName,
    builder: (context) => const CustomPainterDemo(),
    preview: paintingPreview(),
    description: tr(
      'Activity rings, outline draw-on, shape morphing, waves, confetti.',
      'Кольца активности, прорисовка контура, морфинг фигур, волны, конфетти.',
    ),
    effort: Effort.hard,
  ),
];

List<Demo> packageDemos() => [
  Demo(
    name: 'flutter_animate',
    route: FlutterAnimateDemo.routeName,
    builder: (context) => const FlutterAnimateDemo(),
    preview: flutterAnimatePreview(),
    description: tr(
      '16 ready-made effects in one line, chains, staggered lists.',
      '16 готовых эффектов одной строкой, цепочки, stagger-списки.',
    ),
  ),
  Demo(
    name: 'flutter_bounceable',
    route: BounceableDemo.routeName,
    builder: (context) => const BounceableDemo(),
    preview: bounceablePreview(),
    description: tr(
      'iOS-like springy press feedback on buttons, cards, icons, photos.',
      'iOS-подобное пружинящее нажатие на кнопках, карточках, иконках, фото.',
    ),
  ),
  Demo(
    name: 'animated_text_kit',
    route: AnimatedTextDemo.routeName,
    builder: (context) => const AnimatedTextDemo(),
    preview: animatedTextPreview(),
    description: tr(
      'Typewriter, rotating phrases, shimmer, wave, neon, fill — 11 kinds.',
      'Печатная машинка, смена фраз, перелив, волна, неон, заливка — 11 видов.',
    ),
  ),
  Demo(
    name: 'flutter_staggered_animations',
    route: StaggeredListDemo.routeName,
    builder: (context) => const StaggeredListDemo(),
    preview: staggeredListPreview(),
    description: tr(
      'Lists and grids appearing in a staggered "ladder": slide-in, fade-in, grow, flip.',
      'Появление списков и сеток «лесенкой»: выезд, проявление, рост, переворот.',
    ),
  ),
  Demo(
    name: 'matrix4_transform',
    route: Matrix4TransformDemo.routeName,
    builder: (context) => const Matrix4TransformDemo(),
    preview: matrix4Preview(),
    description: tr(
      'Rotate, scale, shift, mirror chained around a pivot; hover cards.',
      'Поворот, масштаб, сдвиг, отражение цепочкой с точкой опоры; hover-карточки.',
    ),
    effort: Effort.medium,
  ),
];

List<Demo> mediaDemos() => [
  Demo(
    name: 'Lottie',
    route: LottieDemo.routeName,
    builder: (context) => const LottieDemo(),
    preview: lottiePreview(),
    description: tr(
      'After Effects animations (JSON): a gallery, a player with segments, tap animations, recoloring.',
      'Анимации из After Effects (JSON): галерея, плеер с отрезками, тап-анимации, перекраска.',
    ),
  ),
  Demo(
    name: 'Rive',
    route: RiveDemo.routeName,
    builder: (context) => const RiveDemo(),
    preview: rivePreview(),
    description: tr(
      "Interactive .riv files from Rive Editor: a state machine and its inputs as controls, fit/alignment.",
      'Интерактивные .riv из Rive Editor: state machine и её inputs как контролы, fit/alignment.',
    ),
    effort: Effort.medium,
  ),
];

List<Demo> experimentalDemos() => [
  Demo(
    name: 'flutter_tilt',
    route: TiltDemo.routeName,
    builder: (context) => const TiltDemo(),
    preview: tiltPreview(),
    description: tr(
      'A 3D tilt that follows the cursor/finger with glare and shadow: cards, medals, parallax.',
      '3D-наклон за курсором/пальцем с бликом и тенью: карточки, медали, параллакс.',
    ),
    effort: Effort.medium,
  ),
  Demo(
    name: 'custom_refresh_indicator',
    route: RefreshIndicatorDemo.routeName,
    builder: (context) => const RefreshIndicatorDemo(),
    preview: refreshPreview(),
    description: tr(
      'A branded pull-to-refresh: logo, paper plane, ring, liquid drop.',
      'Фирменный pull-to-refresh: логотип, самолётик, кольцо, жидкая капля.',
    ),
    effort: Effort.medium,
  ),
  Demo(
    name: 'wolt_modal_sheet',
    route: WoltSheetDemo.routeName,
    builder: (context) => const WoltSheetDemo(),
    preview: woltPreview(),
    description: tr(
      'A multi-page Wolt sheet: paging, hero, bottom sheet / dialog / side panel.',
      'Многостраничная шторка Wolt: перелистывание, hero, bottom sheet / диалог / панель.',
    ),
    effort: Effort.medium,
  ),
  Demo(
    name: 'like_button',
    route: LikeButtonDemo.routeName,
    builder: (context) => const LikeButtonDemo(),
    preview: likeButtonPreview(),
    description: tr(
      'A like button like Twitter/X: a burst of dots, a ring, a flipping counter.',
      'Лайк как в Twitter/X: взрыв точек, кольцо, перелистывание счётчика.',
    ),
  ),
  Demo(
    name: 'Generative avatars',
    route: GenerativeAvatarsDemo.routeName,
    builder: (context) => const GenerativeAvatarsDemo(),
    preview: avatarsPreview(),
    description: tr(
      'Avatars generated from a name (marble, beam, bauhaus, rings, pixel) — our port of boring_avatars.',
      'Аватары из имени (marble, beam, bauhaus, rings, pixel) — наш порт boring_avatars.',
    ),
  ),
  Demo(
    name: 'zo_animated_border',
    route: AnimatedBorderDemo.routeName,
    builder: (context) => const AnimatedBorderDemo(),
    preview: animatedBorderPreview(),
    description: tr(
      'Running, glowing, dashed borders for buttons, stories, fields, promos.',
      'Бегущие, светящиеся, пунктирные рамки для кнопок, сторис, полей, промо.',
    ),
  ),
];

List<Demo> configDemos() => [
  Demo(
    name: tr('Animation from config', 'Анимация из конфига'),
    route: ConfigAnimationDemo.routeName,
    builder: (context) => const ConfigAnimationDemo(),
    preview: configPreview(),
    description: tr(
      'Keyframes in JSON: properties, a CSS transform from Figma, matrices, curves and springs.',
      'Ключевые кадры в JSON: свойства, CSS transform из Figma, матрицы, кривые и пружины.',
    ),
  ),
  Demo(
    name: tr('Matrix sequence', 'Сиквенция матриц'),
    route: MatrixSequenceDemo.routeName,
    builder: (context) => const MatrixSequenceDemo(),
    preview: matrixSequencePreview(),
    description: tr(
      'N matrices from Figma in order → smooth transitions via Matrix4Tween.',
      'N матриц из Figma по порядку → плавные переходы через Matrix4Tween.',
    ),
  ),
];

List<DemoCategory> categories() => [
  DemoCategory(
    title: tr('From designer to code', 'От дизайнера — в код'),
    subtitle: tr(
      'The animation is described by a config: the designer sets it, the app plays it.',
      'Анимация описывается конфигом: дизайнер задаёт, приложение проигрывает.',
    ),
    icon: Icons.handshake,
    demos: configDemos(),
  ),
  DemoCategory(
    title: tr('Basics: implicit animations', 'Основы: implicit-анимации'),
    subtitle: tr(
      'Change a value — the widget smoothly animates to the new one on its own.',
      'Меняешь значение — виджет сам плавно переходит к новому.',
    ),
    icon: Icons.auto_fix_high,
    demos: basicDemos(),
  ),
  DemoCategory(
    title: tr('Explicit and choreography', 'Explicit и хореография'),
    subtitle: tr(
      'Manual control over time: a remote, a timeline, keyframes.',
      'Ручное управление временем: пульт, таймлайн, ключевые кадры.',
    ),
    icon: Icons.timeline,
    demos: explicitDemos(),
  ),
  DemoCategory(
    title: tr('Screen transitions', 'Переходы между экранами'),
    subtitle: tr(
      'How one screen replaces another, and what "flies" between them.',
      'Как один экран сменяет другой и что при этом «перелетает».',
    ),
    icon: Icons.swap_horiz,
    demos: routingDemos(),
  ),
  DemoCategory(
    title: tr('Micro-interactions', 'Микро-взаимодействия'),
    subtitle: tr(
      "Short interface reactions to the user's actions.",
      'Короткие реакции интерфейса на действия пользователя.',
    ),
    icon: Icons.touch_app,
    demos: microDemos(),
  ),
  DemoCategory(
    title: tr('Scroll', 'Скролл'),
    subtitle: tr(
      'Animations where "time" is the scroll position.',
      'Анимации, где «время» — это позиция прокрутки.',
    ),
    icon: Icons.swipe_vertical,
    demos: scrollDemos(),
  ),
  DemoCategory(
    title: tr('Drawing on Canvas', 'Рисование на Canvas'),
    subtitle: tr(
      "Everything that can't be assembled from ready-made widgets.",
      'Всё, что нельзя собрать из готовых виджетов.',
    ),
    icon: Icons.brush,
    demos: paintingDemos(),
  ),
  DemoCategory(
    title: tr('Packages', 'Пакеты'),
    subtitle: tr(
      'Proven animation libraries — safe to bring into the product without a second thought.',
      'Проверенные библиотеки анимаций — берём в продукт без раздумий.',
    ),
    icon: Icons.extension,
    demos: packageDemos(),
  ),
  DemoCategory(
    title: tr('Lottie and Rive', 'Lottie и Rive'),
    subtitle: tr(
      'Animations the designer makes in the editor and hands off as a file.',
      'Анимации, которые дизайнер делает сам в редакторе и отдаёт файлом.',
    ),
    icon: Icons.movie_filter,
    demos: mediaDemos(),
  ),
  DemoCategory(
    title: tr('Experimental', 'Экспериментальное'),
    subtitle: tr(
      'Bold effects and ready-made components: good for branding and accents.',
      'Яркие эффекты и готовые компоненты: хорошо для бренда и акцентов.',
    ),
    icon: Icons.science,
    demos: experimentalDemos(),
  ),
];

/// The routes themselves (path + builder) don't depend on the language, so
/// they're computed once — only the on-screen category/demo names (built
/// fresh in [HomePage] via [categories]) change when the language switches.
List<RouteBase> _demoRoutes() => [
  for (final category in categories())
    for (final demo in category.demos) GoRoute(path: demo.route, builder: (context, state) => demo.builder(context)),
];

final router = GoRouter(
  // HeroineController is needed for spring-based Heroine flights between routes.
  observers: [HeroineController()],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: _demoRoutes(),
    ),
  ],
);

class AnimationSamples extends StatefulWidget {
  const AnimationSamples({super.key});

  @override
  State<AnimationSamples> createState() => _AnimationSamplesState();
}

class _AnimationSamplesState extends State<AnimationSamples> {
  @override
  void initState() {
    super.initState();
    appLang.addListener(_onLang);
  }

  @override
  void dispose() {
    appLang.removeListener(_onLang);
    super.dispose();
  }

  // Strings come from tr() inside build(), including in const subtrees that
  // Flutter would normally skip. Reassembling (the hot-reload mechanism, also
  // available in release) re-runs every build() while keeping all state and
  // the current page.
  void _onLang() {
    setState(() {});
    WidgetsBinding.instance.reassembleApplication();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Animation Showcase',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      locale: Locale(appLang.value.name),
      supportedLocales: [for (final l in AppLang.values) Locale(l.name)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final demoCategories = categories();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Flutter Animation Showcase', 'Витрина анимаций Flutter')),
        actions: const [LangButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Animation catalog', 'Каталог анимаций'), style: textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          "A live sandbox: open any example, turn the knobs (duration, curve, "
                          "effect strength) and dial in an animation for your case. The preview "
                          "on the left shows the gist of the example, and the badge shows how "
                          "much effort that animation costs in the product:",
                          'Живая песочница: открой любой пример, покрути ручки '
                              '(длительность, кривая, сила эффекта) и подбери анимацию '
                              'под свой кейс. Превью слева показывает суть примера, '
                              'а метка — сколько усилий стоит такая анимация в продукте:',
                        ),
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      for (final e in Effort.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              EffortChip(effort: e),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.explanation, style: textTheme.bodySmall)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              for (final category in demoCategories) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(category.icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(category.title, style: textTheme.titleLarge),
                  subtitle: Text(category.subtitle),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // On a wide screen — two columns, so previews are more visible.
                        final columns = constraints.maxWidth >= 720 ? 2 : 1;
                        final width = constraints.maxWidth / columns;
                        return Wrap(
                          children: [
                            for (final demo in category.demos)
                              SizedBox(width: width, child: DemoTile(demo: demo)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DemoTile extends StatelessWidget {
  final Demo demo;

  const DemoTile({required this.demo, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.go('/${demo.route}');
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            demo.preview ?? const SizedBox(width: 72, height: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(demo.name, style: textTheme.titleMedium),
                  if (demo.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      demo.description,
                      style: textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  EffortChip(effort: demo.effort),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EffortChip extends StatelessWidget {
  const EffortChip({required this.effort, super.key});
  final Effort effort;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: effort.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        effort.label,
        style: TextStyle(color: effort.color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
