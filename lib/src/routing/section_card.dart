// Section scaffold for the Routing & Transitions screen: title, description
// and body (demo area + buttons/settings). Each screen is assembled from these sections.

import 'package:flutter/material.dart';

class RoutingSection extends StatelessWidget {
  const RoutingSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
