// The "check your own values" sandbox — the right half of the
// "What's needed from the designer" block. The designer enters exactly what
// we ask for (duration, curve, values, colors…) and immediately sees how it
// plays into the animation. The "Spec from my values" button turns the input
// into a ready-made spec.
//
// The screen describes fields (BriefField) and a preview (builder). The
// sandbox itself drives the animation's time: builder gets a linear progress
// t (0…1) and the entered values — applying the curve to t is the builder's job:
//   final e = v.curve('curve').transform(t);

import 'package:flutter/material.dart';

import 'i18n.dart';
import 'motion_spec.dart';

enum _Kind { duration, curve, number, color, text, choice }

/// A sandbox input field.
class BriefField {
  const BriefField._(
    this.kind,
    this.key,
    this.label,
    this.initial, {
    this.unit = '',
    this.min,
    this.max,
    this.options = const [],
  });

  /// Duration in ms.
  ///
  /// The unit is fixed to the Latin "ms" abbreviation (not translated, like
  /// other units/numbers) — this constructor stays `const`, so its unit
  /// can't be resolved through [tr] at build time.
  const BriefField.duration(String key, String label, int initialMs, {double max = 10000})
    : this._(_Kind.duration, key, label, '$initialMs', unit: 'ms', min: 0, max: max);

  /// Curve as a string: preset, cubic-bezier(…) or spring(…).
  const BriefField.curve(String key, String label, String initial)
    : this._(_Kind.curve, key, label, initial);

  /// A number (with optional units and bounds).
  const BriefField.number(
    String key,
    String label,
    num initial, {
    String unit = '',
    double? min,
    double? max,
  }) : this._(_Kind.number, key, label, '$initial', unit: unit, min: min, max: max);

  /// Color '#RRGGBB' or '#AARRGGBB'.
  const BriefField.color(String key, String label, String initialHex)
    : this._(_Kind.color, key, label, initialHex);

  /// Free text (a phrase, marker name…).
  const BriefField.text(String key, String label, String initial)
    : this._(_Kind.text, key, label, initial);

  /// A choice among options.
  const BriefField.choice(String key, String label, List<String> options, String initial)
    : this._(_Kind.choice, key, label, initial, options: options);

  final _Kind kind;
  final String key;
  final String label;
  final String initial;
  final String unit;
  final double? min;
  final double? max;
  final List<String> options;

  /// Parses input: a value, or throws FormatException with an error message.
  Object parse(String raw) {
    final s = raw.trim();
    switch (kind) {
      case _Kind.duration:
      case _Kind.number:
        final v = double.tryParse(s.replaceAll(',', '.'));
        if (v == null) throw FormatException(tr('a number is required', 'нужно число'));
        if (min != null && v < min!) {
          throw FormatException(tr('at least ${_fmt(min!)}', 'не меньше ${_fmt(min!)}'));
        }
        if (max != null && v > max!) {
          throw FormatException(tr('at most ${_fmt(max!)}', 'не больше ${_fmt(max!)}'));
        }
        return kind == _Kind.duration ? v.round() : v;
      case _Kind.curve:
        parseCurve(s);
        return s;
      case _Kind.color:
        return parseHexColor(s);
      case _Kind.text:
        if (s.isEmpty) throw FormatException(tr('empty', 'пусто'));
        return s;
      case _Kind.choice:
        return s;
    }
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : '$v';
}

/// '#RRGGBB' / '#AARRGGBB' → Color.
Color parseHexColor(String s) {
  var hex = s.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final v = hex.length == 8 ? int.tryParse(hex, radix: 16) : null;
  if (v == null) throw FormatException(tr('format #RRGGBB', 'формат #RRGGBB'));
  return Color(v);
}

/// Entered values (always valid: on error, keeps the last valid one).
class BriefValues {
  BriefValues(this._values);
  final Map<String, Object> _values;

  int ms(String key) => _values[key] as int;
  Duration duration(String key) => Duration(milliseconds: ms(key));
  Curve curve(String key) => resolveCurve(_values[key] as String);
  String curveName(String key) => _values[key] as String;
  double number(String key) => (_values[key] as num).toDouble();
  Color color(String key) => _values[key] as Color;
  String text(String key) => _values[key] as String;

  Map<String, Object?> toSpec() => {
    for (final MapEntry(:key, :value) in _values.entries)
      key: switch (value) {
        final Color c =>
          '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        final String s
            when curveToCss(s) != null && !s.startsWith('cubic') && !s.startsWith('spring') =>
          '$s (${curveToCss(s)})',
        _ => value,
      },
  };
}

/// How to run the preview.
enum PlaygroundMode {
  /// Back and forth with pauses — for transitions between two states.
  pingPong,

  /// Looping 0 → 1 with a pause — for one-directional effects.
  loop,
}

class BriefPlayground extends StatefulWidget {
  const BriefPlayground({
    super.key,
    required this.fields,
    required this.builder,
    this.durationKey = 'duration_ms',
    this.delayKey,
    this.mode = PlaygroundMode.pingPong,
    this.previewHeight = 200,
    this.title,
  });

  final List<BriefField> fields;

  /// A preview frame: linear progress [t] (0…1) and the entered values.
  final Widget Function(BuildContext context, BriefValues values, double t) builder;

  /// Which field sets the duration of one pass (if any).
  final String? durationKey;

  /// Which field sets the delay before starting (if any).
  final String? delayKey;
  final PlaygroundMode mode;
  final double previewHeight;

  /// Heading above the sandbox. Null (the default) shows the generic
  /// "Check your own values" hint, resolved through [tr] in [build].
  final String? title;

  @override
  State<BriefPlayground> createState() => _BriefPlaygroundState();
}

class _BriefPlaygroundState extends State<BriefPlayground> with SingleTickerProviderStateMixin {
  static const _pauseMs = 700;
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.initial),
  };
  late final Map<String, Object> _values = {
    for (final f in widget.fields) f.key: f.parse(f.initial),
  };
  final _errors = <String, String>{};

  /// Choice fields are remembered by option INDEX: option texts are
  /// translated, so after a language switch the stored text would no longer
  /// match any option.
  final _choiceIndex = <String, int>{};

  /// Re-reads choice values from the current (possibly re-translated) options.
  void _syncChoices() {
    for (final f in widget.fields) {
      if (f.kind != _Kind.choice || f.options.isEmpty) continue;
      final i = (_choiceIndex[f.key] ?? f.options.indexOf(f.initial)).clamp(
        0,
        f.options.length - 1,
      );
      _values[f.key] = f.options[i];
    }
  }

  bool _loop = true;

  int get _durationMs {
    final key = widget.durationKey;
    final v = key == null ? null : _values[key];
    return v is int ? v.clamp(1, 60000) : 1000;
  }

  int get _delayMs {
    final key = widget.delayKey;
    final v = key == null ? null : _values[key];
    return v is int ? v : 0;
  }

  /// Length of one pass: delay + animation + pause.
  int get _passMs => _delayMs + _durationMs + _pauseMs;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _restart() {
    if (_loop) {
      final passes = widget.mode == PlaygroundMode.pingPong ? 2 : 1;
      _controller
        ..duration = Duration(milliseconds: _passMs * passes)
        ..repeat();
    } else {
      _controller
        ..duration = Duration(milliseconds: _delayMs + _durationMs)
        ..forward(from: 0);
    }
  }

  /// Linear animation progress accounting for delay, pause and mode.
  double get _t {
    if (!_loop) {
      final ms = _controller.value * (_delayMs + _durationMs);
      return ((ms - _delayMs) / _durationMs).clamp(0.0, 1.0);
    }
    double pass(double ms) => ((ms - _delayMs) / _durationMs).clamp(0.0, 1.0);
    if (widget.mode == PlaygroundMode.loop) return pass(_controller.value * _passMs);
    final ms = _controller.value * _passMs * 2;
    return ms < _passMs ? pass(ms) : 1 - pass(ms - _passMs);
  }

  void _onChanged(BriefField f, String raw) {
    if (f.kind == _Kind.choice) _choiceIndex[f.key] = f.options.indexOf(raw);
    try {
      final v = f.parse(raw);
      setState(() {
        _values[f.key] = v;
        _errors.remove(f.key);
      });
      if (f.key == widget.durationKey || f.key == widget.delayKey) _restart();
    } on FormatException catch (e) {
      setState(() => _errors[f.key] = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncChoices();
    final textTheme = Theme.of(context).textTheme;
    final values = BriefValues(_values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.science_outlined, size: 20, color: Color(0xFFF57F17)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.title ?? tr('Check your own values', 'Проверь свои значения'),
                style: textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          tr(
            "Enter your own values — the preview immediately plays the animation with them.",
            'Введи свои значения — превью сразу проиграет анимацию с ними.',
          ),
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Container(
          height: widget.previewHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => widget.builder(context, values, _t),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(tr('Loop', 'Цикл')),
              selected: _loop,
              onSelected: (v) {
                setState(() => _loop = v);
                _restart();
              },
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _loop = false);
                _restart();
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(tr('Play once', 'Проиграть раз')),
            ),
            TextButton.icon(
              onPressed: () => showSpecDialog(
                context,
                title: tr('My values', 'Мои значения'),
                spec: values.toSpec(),
              ),
              icon: const Icon(Icons.data_object, size: 18),
              label: Text(tr('Spec from my values', 'Спека из моих значений')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 420 ? 2 : 1;
            final width = (c.maxWidth - 10 * (columns - 1)) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in widget.fields) SizedBox(width: width, child: _field(context, f)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _field(BuildContext context, BriefField f) {
    final error = _errors[f.key];
    if (f.kind == _Kind.choice) {
      return DropdownButtonFormField<String>(
        // The form field keeps its own copy of the value — re-create it when
        // the language (and so the option texts) changes.
        key: ValueKey('${f.key}-${appLang.value.name}'),
        initialValue: _values[f.key] as String,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: f.label,
          isDense: true,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          for (final o in f.options)
            DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) _onChanged(f, v);
        },
      );
    }
    Widget? prefix;
    Widget? suffix;
    if (f.kind == _Kind.color) {
      prefix = Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _values[f.key] as Color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black26),
          ),
        ),
      );
    }
    if (f.kind == _Kind.curve) {
      suffix = IconButton(
        tooltip: tr('Curve editor', 'Редактор кривой'),
        icon: const Icon(Icons.tune, size: 18),
        onPressed: () async {
          final custom = await showCurveEditor(context, _values[f.key] as String);
          if (custom != null) {
            _text[f.key]!.text = custom;
            _onChanged(f, custom);
          }
        },
      );
    } else if (f.unit.isNotEmpty) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(f.unit, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return TextField(
      controller: _text[f.key],
      onChanged: (v) => _onChanged(f, v),
      keyboardType: f.kind == _Kind.duration || f.kind == _Kind.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      style: TextStyle(
        fontFamily: f.kind == _Kind.curve || f.kind == _Kind.color ? 'monospace' : null,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: f.label,
        errorText: error,
        isDense: true,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
