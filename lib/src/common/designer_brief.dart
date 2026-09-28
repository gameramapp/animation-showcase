// The "What's needed from the designer" block — placed at the very bottom of each screen.
// A checklist of what the designer should provide so the developer can reproduce
// the animation exactly: timings, curves, values, files and their requirements.

import 'package:flutter/material.dart';

import 'anim_block.dart';
import 'i18n.dart';

class DesignerBrief extends StatelessWidget {
  const DesignerBrief({
    super.key,
    required this.items,
    this.handoff,
    this.avoid = const [],
    this.playground,
  });

  /// What to provide: (what, details).
  final List<(String, String)> items;

  /// How to hand it off to development. Null (the default) shows a generic
  /// "set up the block above, press Spec" message, resolved through [tr]
  /// in [_checklist] — that keeps it in the current language.
  final String? handoff;

  /// What not to do / what's not supported.
  final List<String> avoid;

  /// The "check your own values" sandbox (see brief_playground.dart):
  /// on a wide screen — to the right of the checklist, on a narrow one — below it.
  final Widget? playground;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFE082)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final checklist = _checklist(context);
            final pg = playground;
            if (pg == null) return checklist;
            if (constraints.maxWidth < 820) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [checklist, const Divider(height: 32), pg],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: checklist),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: pg),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _checklist(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final handoffText =
        handoff ??
        tr(
          'Set up the block above and press "Spec" — the copied JSON is the spec. '
              'Attach it to the task along with a reference (video or prototype).',
          'Настрой блок выше и нажми «Спека» — скопированный JSON и есть ТЗ. '
              'Приложи его к задаче вместе с референсом (видео или прототип).',
        );
    final howToHandOff = tr('How to hand it off', 'Как передать');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_outlined, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('What we need from the designer', 'Что нужно от дизайнера'),
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (what, details) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_box_outlined, size: 18, color: kAccent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: what,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (details.isNotEmpty) TextSpan(text: ' — $details'),
                      ],
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (avoid.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(tr('What to avoid', 'Чего избегать'), style: textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final a in avoid)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.block, size: 16, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
        const Divider(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.send, size: 16, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$howToHandOff: $handoffText',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
