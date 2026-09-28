// Section 1 — "Transitions Playground" built on top of PageRouteBuilder.
//
// Shows what's configurable about a transition between pages: animation type,
// direction, forward/reverse duration, curve, fullscreenDialog, and how
// secondaryAnimation works (the departing page's animation when a new one is pushed on top).

import 'package:flutter/material.dart';

import '../common/animation_controls.dart';
import '../common/i18n.dart';
import 'section_card.dart';

enum _Transition {
  // Custom — assembled by hand in transitionsBuilder.
  slide,
  fade,
  scale,
  rotation,
  size,
  fadeScale,
  slideFade,
  // Built-in — ready-made PageTransitionsBuilder from Material and Cupertino.
  materialZoom,
  materialFadeForwards,
  materialFadeUpwards,
  materialOpenUpwards,
  cupertino,
}

enum _Dir { up, down, left, right }

/// What the departing page does when a new one is pushed on top of it.
enum _Exit { none, parallax, zoomOut, fade, slideUp }

extension on _Exit {
  String get label => switch (this) {
    _Exit.none => tr('None (stays put)', 'Нет (стоит на месте)'),
    _Exit.parallax => tr('Parallax — moves left', 'Parallax — уезжает влево'),
    _Exit.zoomOut => tr('Zoom out — recedes', 'Zoom out — отдаляется'),
    _Exit.fade => tr('Fade — dims', 'Fade — затемняется'),
    _Exit.slideUp => tr('Slide up — moves up', 'Slide up — уезжает вверх'),
  };
}

extension on _Transition {
  String get label => switch (this) {
    _Transition.slide => 'Slide',
    _Transition.fade => 'Fade',
    _Transition.scale => 'Scale / zoom',
    _Transition.rotation => 'Rotation',
    _Transition.size => 'Size',
    _Transition.fadeScale => 'Fade + Scale',
    _Transition.slideFade => 'Slide + Fade',
    _Transition.materialZoom => 'Material: Zoom (Android)',
    _Transition.materialFadeForwards => 'Material: Fade forwards (M3)',
    _Transition.materialFadeUpwards => 'Material: Fade upwards',
    _Transition.materialOpenUpwards => 'Material: Open upwards',
    _Transition.cupertino => 'Cupertino: iOS slide',
  };

  /// A ready-made builder from Material/Cupertino, or null for custom transitions.
  PageTransitionsBuilder? get builtInBuilder => switch (this) {
    _Transition.materialZoom => const ZoomPageTransitionsBuilder(),
    _Transition.materialFadeForwards =>
      const FadeForwardsPageTransitionsBuilder(),
    _Transition.materialFadeUpwards =>
      const FadeUpwardsPageTransitionsBuilder(),
    _Transition.materialOpenUpwards =>
      const OpenUpwardsPageTransitionsBuilder(),
    _Transition.cupertino => const CupertinoPageTransitionsBuilder(),
    _ => null,
  };

  bool get isBuiltIn => builtInBuilder != null;

  bool get usesDirection =>
      this == _Transition.slide || this == _Transition.slideFade;
}

Offset _beginOffset(_Dir dir) => switch (dir) {
  _Dir.up => const Offset(0, 1),
  _Dir.down => const Offset(0, -1),
  _Dir.left => const Offset(1, 0),
  _Dir.right => const Offset(-1, 0),
};

class TransitionsPlayground extends StatefulWidget {
  const TransitionsPlayground({super.key});

  @override
  State<TransitionsPlayground> createState() => _TransitionsPlaygroundState();
}

class _TransitionsPlaygroundState extends State<TransitionsPlayground> {
  _Transition transition = _Transition.slide;
  _Dir dir = _Dir.up;
  int durationMs = 450;
  int reverseMs = 450;
  String curve = 'easeInOut';
  String reverseCurve = 'easeInOut';
  bool fullscreenDialog = false;
  _Exit exit = _Exit.parallax;

  void _open(BuildContext context) {
    Navigator.of(context).push(_buildRoute(depth: 1));
  }

  Route<void> _buildRoute({required int depth}) {
    final c = resolveCurve(curve);
    final rc = resolveCurve(reverseCurve);
    return PageRouteBuilder<void>(
      fullscreenDialog: fullscreenDialog,
      transitionDuration: Duration(milliseconds: durationMs),
      reverseTransitionDuration: Duration(milliseconds: reverseMs),
      pageBuilder: (context, animation, secondaryAnimation) => _DestinationPage(
        depth: depth,
        config:
            '${transition.label}'
            '${transition.usesDirection ? ' · ${dir.name}' : ''}'
            ' · ${durationMs}ms / ${reverseMs}ms'
            '${transition.isBuiltIn ? '' : ' · $curve / $reverseCurve'}',
        onPushAnother: () =>
            Navigator.of(context).push(_buildRoute(depth: depth + 1)),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Built-in transitions: hand everything to the ready-made builder —
        // it draws both the entrance and the departing page's behavior (secondaryAnimation).
        final builtIn = transition.builtInBuilder;
        if (builtIn != null) {
          final route = ModalRoute.of(context)! as PageRoute<void>;
          return builtIn.buildTransitions<void>(
            route,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        }
        // Custom transition: we assemble the entrance and the departing page's behavior ourselves.
        final curved = CurvedAnimation(
          parent: animation,
          curve: c,
          reverseCurve: rc,
        );
        Widget result = _applyEnter(curved, child);
        final out = CurvedAnimation(
          parent: secondaryAnimation,
          curve: c,
          reverseCurve: rc,
        );
        result = _applyExit(out, result);
        return result;
      },
    );
  }

  Widget _applyExit(Animation<double> secondary, Widget child) {
    switch (exit) {
      case _Exit.none:
        return child;
      case _Exit.parallax:
        return SlideTransition(
          position: Tween(
            begin: Offset.zero,
            end: const Offset(-0.25, 0),
          ).animate(secondary),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.7).animate(secondary),
            child: child,
          ),
        );
      case _Exit.zoomOut:
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 0.9).animate(secondary),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.6).animate(secondary),
            child: child,
          ),
        );
      case _Exit.fade:
        return FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.3).animate(secondary),
          child: child,
        );
      case _Exit.slideUp:
        return SlideTransition(
          position: Tween(
            begin: Offset.zero,
            end: const Offset(0, -0.2),
          ).animate(secondary),
          child: child,
        );
    }
  }

  Widget _applyEnter(Animation<double> animation, Widget child) {
    switch (transition) {
      case _Transition.fade:
        return FadeTransition(opacity: animation, child: child);
      case _Transition.scale:
        return ScaleTransition(scale: animation, child: child);
      case _Transition.rotation:
        return RotationTransition(turns: animation, child: child);
      case _Transition.size:
        return Align(
          child: SizeTransition(sizeFactor: animation, child: child),
        );
      case _Transition.fadeScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        );
      case _Transition.slide:
        return SlideTransition(
          position: Tween(
            begin: _beginOffset(dir),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case _Transition.slideFade:
        return SlideTransition(
          position: Tween(
            begin: _beginOffset(dir) * 0.3,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      // Built-in transitions never reach here — builtInBuilder draws them.
      case _Transition.materialZoom:
      case _Transition.materialFadeForwards:
      case _Transition.materialFadeUpwards:
      case _Transition.materialOpenUpwards:
      case _Transition.cupertino:
        return child;
    }
  }

  /// Current transition settings — for the "Spec" button.
  Map<String, Object?> _spec() {
    final builtIn = transition.builtInBuilder;
    final begin = _beginOffset(dir);
    return {
      'widget': builtIn == null
          ? 'PageRouteBuilder + transitionsBuilder'
          : 'PageRouteBuilder + ${builtIn.runtimeType}',
      'transition': transition.label,
      if (transition.usesDirection) ...{
        'direction': dir.name,
        'enter_offset_from_fraction_of_screen': {
          'x': begin.dx * (transition == _Transition.slideFade ? 0.3 : 1),
          'y': begin.dy * (transition == _Transition.slideFade ? 0.3 : 1),
        },
      },
      if (!transition.usesDirection && !transition.isBuiltIn)
        'enter': switch (transition) {
          _Transition.fade => {'opacity_from': 0, 'opacity_to': 1},
          _Transition.scale => {'scale_from': 0, 'scale_to': 1},
          _Transition.rotation => {'turns_from': 0, 'turns_to': 1},
          _Transition.size => {
            'size_factor_from': 0,
            'size_factor_to': 1,
            'axis': 'vertical',
          },
          _Transition.fadeScale => {
            'opacity_from': 0,
            'opacity_to': 1,
            'scale_from': 0.85,
            'scale_to': 1,
          },
          _ => null,
        },
      if (transition.usesDirection && transition == _Transition.slideFade)
        'enter_opacity': {'from': 0, 'to': 1},
      if (builtIn == null) ...{
        'forward': timingSpec(durationMs: durationMs, curve: curve),
        'back': timingSpec(durationMs: reverseMs, curve: reverseCurve),
      } else ...{
        'forward': {'duration_ms': durationMs},
        'back': {'duration_ms': reverseMs},
        'curve': transition == _Transition.cupertino
            ? tr(
                'built-in: fastEaseInToSlowEaseOut (back — flipped)',
                'встроенная: fastEaseInToSlowEaseOut (назад — flipped)',
              )
            : tr(
                'built into ${builtIn.runtimeType}',
                'встроенная в ${builtIn.runtimeType}',
              ),
      },
      'fullscreen_dialog': fullscreenDialog,
      'outgoing_page': builtIn != null
          ? tr(
              'built into ${builtIn.runtimeType}',
              'встроено в ${builtIn.runtimeType}',
            )
          : {
              'behavior': exit.name,
              ...switch (exit) {
                _Exit.none => <String, Object?>{},
                _Exit.parallax => {
                  'offset_x_fraction_of_screen_to': -0.25,
                  'opacity_to': 0.7,
                },
                _Exit.zoomOut => {'scale_to': 0.9, 'opacity_to': 0.6},
                _Exit.fade => {'opacity_to': 0.3},
                _Exit.slideUp => {'offset_y_fraction_of_screen_to': -0.2},
              },
              'curve': tr(
                'same as the entrance (forward / back)',
                'как у входа (forward / back)',
              ),
            },
    };
  }

  @override
  Widget build(BuildContext context) {
    final builtIn = transition.isBuiltIn;
    return RoutingSection(
      title: tr('Transitions Playground', 'Песочница переходов'),
      description: tr(
        'Custom transitions are hand-assembled in transitionsBuilder: type, '
            'direction, forward duration and a separate reverse one, curve, '
            'fullscreenDialog, and the departing page\'s behavior '
            '(secondaryAnimation). Built-in variants (Material / Cupertino) are '
            'ready-made PageTransitionsBuilders with their own curves and '
            'departing-page handling. Open a page, then tap "Open another one" '
            'on it to see secondaryAnimation.',
        'Кастомные переходы собираются руками в transitionsBuilder: тип, '
            'направление, длительность вперёд и отдельно назад, кривая, '
            'fullscreenDialog и поведение уходящей страницы (secondaryAnimation). '
            'Зашитые варианты (Material / Cupertino) — готовые PageTransitionsBuilder '
            'со своими кривыми и обработкой уходящей страницы. Открой страницу, а '
            'на ней нажми «Открыть ещё одну», чтобы увидеть secondaryAnimation.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledDropdown<_Transition>(
            label: tr('Transition type', 'Тип перехода'),
            value: transition,
            values: _Transition.values,
            itemLabel: (t) => t.label,
            onChanged: (v) => setState(() => transition = v),
          ),
          if (transition.usesDirection)
            _LabeledDropdown<_Dir>(
              label: tr('Direction', 'Направление'),
              value: dir,
              values: _Dir.values,
              itemLabel: (d) => d.name,
              onChanged: (v) => setState(() => dir = v),
            ),
          LabeledSlider(
            label: tr('Duration (forward)', 'Длительность (вперёд)'),
            value: durationMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => durationMs = v.round()),
          ),
          LabeledSlider(
            label: tr('Duration (back)', 'Длительность (назад)'),
            value: reverseMs.toDouble(),
            min: 100,
            max: 2000,
            unit: tr('ms', 'мс'),
            onChanged: (v) => setState(() => reverseMs = v.round()),
          ),
          // Curve and departing-page behavior — only for custom transitions;
          // built-in ones have their own, baked into the builder itself.
          if (!builtIn) ...[
            Text(
              tr('Forward (curve)', 'Вперёд (curve)'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            CurveDropdown(
              value: curve,
              onChanged: (v) => setState(() => curve = v),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Back (reverseCurve)', 'Назад (reverseCurve)'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            CurveDropdown(
              value: reverseCurve,
              onChanged: (v) => setState(() => reverseCurve = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr(
                'fullscreenDialog (modal style)',
                'fullscreenDialog (модальный стиль)',
              ),
            ),
            value: fullscreenDialog,
            onChanged: (v) => setState(() => fullscreenDialog = v),
          ),
          if (!builtIn)
            _LabeledDropdown<_Exit>(
              label: tr(
                'secondaryAnimation (departing page)',
                'secondaryAnimation (уходящая страница)',
              ),
              value: exit,
              values: _Exit.values,
              itemLabel: (e) => e.label,
              onChanged: (v) => setState(() => exit = v),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.open_in_new),
                label: Text(tr('Open page', 'Открыть страницу')),
              ),
              SpecButton(
                title: tr('Transitions Playground', 'Песочница переходов'),
                spec: _spec,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A generic labeled dropdown — for the section's enum settings.
class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: [
            for (final v in values)
              DropdownMenuItem(value: v, child: Text(itemLabel(v))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// Destination page: shows the applied configuration and lets you open
/// another one just like it — to see secondaryAnimation in action.
class _DestinationPage extends StatelessWidget {
  const _DestinationPage({
    required this.depth,
    required this.config,
    required this.onPushAnother,
  });

  final int depth;
  final String config;
  final VoidCallback onPushAnother;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Page $depth', 'Страница $depth'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                tr('Stack depth: $depth', 'Глубина стека: $depth'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                config,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onPushAnother,
                icon: const Icon(Icons.add),
                label: Text(tr('Open another one', 'Открыть ещё одну')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('Back', 'Назад')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
