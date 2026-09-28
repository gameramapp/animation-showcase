// A reusable widget for smooth expand/collapse by height.
//
// Unlike the implicit AnimatedSize widget, the animation here is explicit:
// AnimationController + SizeTransition. This gives full control — you can
// force forward/reverse, read progress, sync with other animations.
// Controlled externally via the expand flag.

import 'package:flutter/material.dart';

class ExpandedSection extends StatefulWidget {
  final Widget child;
  final bool expand;
  final Duration? duration;
  final Curve curve;
  final bool expandOnStart;
  final VoidCallback? afterInit;

  const ExpandedSection({
    required this.child,
    super.key,
    this.expand = false,
    this.duration,
    this.curve = Curves.fastOutSlowIn,
    this.afterInit,
    this.expandOnStart = true,
  });

  @override
  State<ExpandedSection> createState() => _ExpandedSectionState();
}

class _ExpandedSectionState extends State<ExpandedSection>
    with SingleTickerProviderStateMixin {
  AnimationController? expandController;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
    if (widget.afterInit != null) {
      widget.afterInit!();
    }
  }

  /// Sets up the animation.
  void prepareAnimations() {
    final initValue = widget.expandOnStart ? 1.0 : 0.0;

    expandController = AnimationController(
      value: initValue,
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 500),
    );
    if (!widget.expandOnStart) {
      expandController!.value = widget.expand ? 1.0 : 0.0;
    }
    animation = CurvedAnimation(parent: expandController!, curve: widget.curve)
      ..addListener(() {
        setState(() {});
      });
  }

  void _runExpandCheck() {
    if (widget.expand && animation!.value != 1.0) {
      expandController!.forward();
    }
    if (!widget.expand && animation!.value != 0.0) {
      expandController!.reverse();
    }
  }

  @override
  void didUpdateWidget(ExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Duration and curve can change externally (e.g. via controls in the showcase).
    if (widget.duration != null && widget.duration != oldWidget.duration) {
      expandController!.duration = widget.duration;
    }
    if (widget.curve != oldWidget.curve) {
      (animation as CurvedAnimation).curve = widget.curve;
    }
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: -1.0,
      sizeFactor: animation!,
      child: Stack(children: <Widget>[widget.child]),
    );
  }
}
