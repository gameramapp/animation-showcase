// Intro card at the top of a showcase screen: a title, description and
// (optionally) an italic hint on how to use the screen.

import 'package:flutter/material.dart';

class IntroCard extends StatelessWidget {
  const IntroCard({super.key, required this.title, required this.text, this.hint});

  final String title;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(text, style: textTheme.bodyMedium),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                style: textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A grid of equal-width tiles: 1 column on phone, 2–3 on wide screens.
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({super.key, required this.children, this.minTileWidth = 260});

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

/// A tile for [ResponsiveWrap]: fixed-height preview + caption.
class ShowcaseTile extends StatelessWidget {
  const ShowcaseTile({
    super.key,
    required this.title,
    required this.caption,
    required this.child,
    this.previewHeight = 150,
    this.onTap,
  });

  final String title;
  final String caption;
  final Widget child;
  final double previewHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: previewHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: child,
              ),
              const SizedBox(height: 10),
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(caption, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
