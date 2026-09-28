// A shared frame for showcase blocks in implicit-animation demos:
// title, description, preview on the left — controls on the right.
// Used both on the Implicit Animations screen and the AnimatedSize screen.

import 'package:flutter/material.dart';

import 'motion_spec.dart';

/// The signature accent color of the demo blocks.
const kAccent = Color(0xFF673AB7);

/// Block frame: title, description, preview on the left — controls on the right.
/// On a narrow screen the preview goes on top, controls below.
class AnimBlock extends StatelessWidget {
  const AnimBlock({
    super.key,
    required this.title,
    required this.description,
    required this.preview,
    required this.controls,
    this.spec,
  });

  final String title;
  final String description;
  final Widget preview;
  final Widget controls;

  /// The block's current settings for the "Spec" button (JSON to hand off to
  /// development). Called at press time.
  final Map<String, Object?> Function()? spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final previewPane = Container(
      height: 224,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: preview,
    );

    final infoPane = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: textTheme.titleMedium)),
            if (spec != null) SpecButton(title: title, spec: spec!),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        controls,
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [previewPane, const SizedBox(height: 16), infoPane],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: previewPane),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: infoPane),
              ],
            );
          },
        ),
      ),
    );
  }
}
