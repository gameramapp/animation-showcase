// Mini previews for the home screen: each catalog item has a small looping
// animation spinning on the left that shows the gist of the screen.
//
// All previews are built the same way: LoopPreview supplies time t (0 → 1,
// looping), and builder draws the frame for that t. The _seg / _pingPong
// helpers slice the loop into segments with pauses — so the preview "breathes"
// instead of flickering.
// Where it's cheap, the package itself is used (flutter_animate, lottie);
// heavy ones (Rive, tilt, etc.) are faked so the home screen loads instantly.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../common/anim_block.dart';

const _a = kAccent;
const _b = Colors.orange;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Progress within the loop window [a, b], with a curve.
double _seg(double t, double a, double b, [Curve curve = Curves.easeInOut]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// 0 → 1 → 0 with pauses at the edges.
double _pingPong(double t, [Curve curve = Curves.easeInOut]) =>
    t < 0.5 ? _seg(t, 0.1, 0.4, curve) : 1 - _seg(t, 0.6, 0.9, curve);

/// A 72×72 preview frame and looping time for the builder.
class LoopPreview extends StatefulWidget {
  const LoopPreview({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 2600),
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  State<LoopPreview> createState() => _LoopPreviewState();
}

class _LoopPreviewState extends State<LoopPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreviewFrame(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller.value),
      ),
    );
  }
}

class PreviewFrame extends StatelessWidget {
  const PreviewFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _a.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}

Widget _box({double w = 28, double h = 28, Color color = _a, double r = 8, Widget? child}) =>
    Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
      child: child,
    );

Widget _line(double w, {double h = 5, Color color = Colors.black12}) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h / 2)),
);

/// Positions a child into a rectangle inside the 72×72 frame.
Widget _at(Rect r, Widget child) => Positioned.fromRect(rect: r, child: child);

// ───────────────────────────────────────────────────────────────── Basics

Widget animatedContainerPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t);
    return _box(
      w: _lerp(24, 52, p),
      h: _lerp(44, 26, p),
      color: Color.lerp(_a, _b, p)!,
      r: _lerp(4, 22, p),
    );
  },
);

Widget implicitPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t);
    return Align(
      alignment: Alignment.lerp(const Alignment(-0.6, 0.6), const Alignment(0.6, -0.6), p)!,
      child: Opacity(
        opacity: _lerp(0.5, 1, p),
        child: Transform.rotate(
          angle: p * math.pi,
          child: Transform.scale(scale: _lerp(0.8, 1.2, p), child: _box(w: 22, h: 22, r: 6)),
        ),
      ),
    );
  },
);

Widget switchPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t, Curves.easeOutCubic);
    return Container(
      width: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(42, h: 6, color: _a),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  _line(42),
                  const SizedBox(height: 4),
                  _line(28),
                  const SizedBox(height: 4),
                  _line(36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
);

Widget textThemePreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t);
    return Text(
      'Aa',
      style: TextStyle(
        fontSize: _lerp(18, 30, p),
        fontWeight: FontWeight.lerp(FontWeight.w300, FontWeight.w900, p),
        color: Color.lerp(_a, _b, p),
        letterSpacing: _lerp(0, 2, p),
      ),
    );
  },
);

// ─────────────────────────────────────────────────────────────── Explicit

Widget controllerPreview() => LoopPreview(
  builder: (context, t) => CustomPaint(
    size: const Size(52, 44),
    painter: _MiniCurvePainter(_seg(t, 0.1, 0.8, Curves.linear), Curves.easeOutBack),
  ),
);

class _MiniCurvePainter extends CustomPainter {
  _MiniCurvePainter(this.progress, this.curve);
  final double progress;
  final Curve curve;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x) =>
        Offset(x * size.width, size.height * 0.85 - curve.transform(x) * size.height * 0.7);
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i <= 40; i++) {
      final p = at(i / 40);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _a.withValues(alpha: 0.35),
    );
    canvas.drawCircle(at(progress), 4.5, Paint()..color = _a);
  }

  @override
  bool shouldRepaint(_MiniCurvePainter old) => old.progress != progress;
}

Widget staggeredPreview() => LoopPreview(
  builder: (context, t) {
    final out = 1 - _seg(t, 0.85, 0.97);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final v = _seg(t, 0.08 + i * 0.12, 0.35 + i * 0.12, Curves.easeOutCubic) * out;
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(-16 * (1 - v), 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _line(
                      [44.0, 32.0, 38.0][i],
                      h: 8,
                      color: Color.lerp(_a, _b, i / 2)!,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  },
);

// ──────────────────────────────────────────────────────────────── Routing

Widget _screen(Color color, {Color header = _a}) => Container(
  width: 40,
  height: 56,
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(6),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line(32, h: 6, color: header),
      const SizedBox(height: 5),
      _line(28, h: 4),
      const SizedBox(height: 3),
      _line(20, h: 4),
    ],
  ),
);

Widget routingPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t, Curves.easeOutCubic);
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-10 * p, 0),
          child: Opacity(opacity: 1 - 0.4 * p, child: _screen(Colors.white)),
        ),
        Transform.translate(offset: Offset(56 * (1 - p), 0), child: _screen(Colors.white, header: _b)),
      ],
    );
  },
);

Widget heroPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t, Curves.fastOutSlowIn);
    return Stack(
      children: [
        for (var i = 0; i < 3; i++)
          _at(
            Rect.fromLTWH(30, 14 + i * 16.0, 30, 6),
            Opacity(opacity: 1 - p, child: _line(30, h: 6)),
          ),
        _at(
          Rect.lerp(const Rect.fromLTWH(10, 10, 14, 14), const Rect.fromLTWH(8, 8, 56, 34), p)!,
          Container(
            decoration: BoxDecoration(
              color: _b,
              borderRadius: BorderRadius.circular(_lerp(7, 8, p)),
            ),
          ),
        ),
      ],
    );
  },
);

Widget materialMotionPreview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t, Curves.fastOutSlowIn);
    return Stack(
      children: [
        _at(
          Rect.lerp(const Rect.fromLTWH(14, 26, 44, 20), const Rect.fromLTWH(4, 4, 64, 64), p)!,
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Color.lerp(_a, Colors.white, p),
              borderRadius: BorderRadius.circular(_lerp(6, 10, p)),
            ),
            child: Opacity(
              opacity: _seg(p, 0.5, 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_line(40, h: 14, color: _b), const SizedBox(height: 4), _line(30)],
              ),
            ),
          ),
        ),
      ],
    );
  },
);

// ─────────────────────────────────────────────────── Micro / Scroll / Canvas

Widget microPreview() => LoopPreview(
  builder: (context, t) => AnimatedIcon(
    icon: AnimatedIcons.menu_close,
    progress: AlwaysStoppedAnimation(_pingPong(t)),
    size: 36,
    color: _a,
  ),
);

Widget scrollPreview() => LoopPreview(
  duration: const Duration(milliseconds: 3000),
  builder: (context, t) {
    final p = _pingPong(t);
    final header = _lerp(24, 9, p);
    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          for (var i = 0; i < 6; i++)
            Positioned(
              left: 5,
              top: 28 + i * 9 - p * 26,
              child: _line(i.isEven ? 32 : 24),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: header,
            child: ColoredBox(color: _a),
          ),
          Positioned(
            left: 0,
            right: _lerp(44, 0, p),
            top: header,
            height: 2,
            child: const ColoredBox(color: _b),
          ),
        ],
      ),
    );
  },
);

Widget paintingPreview() => LoopPreview(
  duration: const Duration(milliseconds: 3000),
  builder: (context, t) => CustomPaint(
    size: const Size(56, 56),
    painter: _DrawOnPainter(_seg(t, 0.05, 0.7), 1 - _seg(t, 0.85, 0.97)),
  ),
);

class _DrawOnPainter extends CustomPainter {
  _DrawOnPainter(this.progress, this.opacity);
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final star = Path();
    for (var i = 0; i <= 10; i++) {
      final r = (i.isEven ? 0.48 : 0.2) * size.width;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = size.center(Offset.zero) + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    final metric = star.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _a.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_DrawOnPainter old) => old.progress != progress || old.opacity != opacity;
}

// ───────────────────────────────────────────────────────────────── Packages

Widget flutterAnimatePreview() => PreviewFrame(
  child: _box(w: 40, h: 40, r: 10, child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22))
      .animate(onPlay: (c) => c.repeat())
      .scaleXY(begin: 0.6, duration: 600.ms, curve: Curves.easeOutBack)
      .shimmer(delay: 400.ms, duration: 900.ms, color: Colors.white)
      .then(delay: 800.ms),
);

Widget bounceablePreview() => LoopPreview(
  duration: const Duration(milliseconds: 2000),
  builder: (context, t) {
    final press = _seg(t, 0.1, 0.25, Curves.easeOut);
    final release = Curves.elasticOut.transform(_seg(t, 0.35, 0.9, Curves.linear));
    final scale = t < 0.35 ? 1 - 0.18 * press : 0.82 + 0.18 * release;
    final pressed = t > 0.1 && t < 0.35;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(scale: scale, child: _box(w: 52, h: 26, r: 13)),
        if (pressed)
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  },
);

Widget animatedTextPreview() => LoopPreview(
  duration: const Duration(milliseconds: 2400),
  builder: (context, t) {
    const word = 'Hello';
    final typed = (_seg(t, 0.05, 0.55, Curves.linear) * word.length).round();
    final erase = (_seg(t, 0.8, 0.95, Curves.linear) * word.length).round();
    final cursor = (t * 8).floor().isEven;
    return Text(
      '${word.substring(0, math.max(0, typed - erase))}${cursor ? '|' : ' '}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _a,
        fontFamily: 'SpecialElite',
      ),
    );
  },
);

Widget staggeredListPreview() => LoopPreview(
  builder: (context, t) {
    final out = 1 - _seg(t, 0.85, 0.97);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++)
          Builder(
            builder: (context) {
              final v = _seg(t, 0.05 + i * 0.1, 0.3 + i * 0.1, Curves.easeOutCubic) * out;
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - v)),
                  child: Container(
                    width: 50,
                    height: 10,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Color.lerp(_a, _b, i / 3)!.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  },
);

Widget matrix4Preview() => LoopPreview(
  builder: (context, t) {
    final p = _pingPong(t);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.004)
        ..rotateY(_lerp(-0.7, 0.7, p))
        ..rotateZ(_lerp(-0.15, 0.15, p))
        ..multiply(Matrix4.skewX(_lerp(0, 0.35, p))),
      child: _box(w: 40, h: 30, r: 6, color: Color.lerp(_a, _b, p)!),
    );
  },
);

// ─────────────────────────────────────────────────────────── Lottie and Rive

Widget lottiePreview() => const PreviewFrame(
  child: _LottieThumb(),
);

class _LottieThumb extends StatelessWidget {
  const _LottieThumb();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/bouncing_ball.json',
      width: 64,
      height: 64,
      errorBuilder: (context, error, stack) => const Icon(Icons.movie, color: _a),
    );
  }
}

Widget rivePreview() => LoopPreview(
  duration: const Duration(milliseconds: 3000),
  builder: (context, t) {
    final lit = _seg(t, 0.05, 0.6, Curves.linear) * 5;
    final out = _seg(t, 0.85, 0.95);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Builder(
            builder: (context) {
              final v = (lit - i).clamp(0.0, 1.0) * (1 - out);
              return Transform.scale(
                scale: 0.8 + 0.4 * math.sin(v * math.pi) + 0.1 * v,
                child: Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: Color.lerp(Colors.black26, Colors.amber, v),
                ),
              );
            },
          ),
      ],
    );
  },
);

// ────────────────────────────────────────────────────────── Experimental

Widget tiltPreview() => LoopPreview(
  duration: const Duration(milliseconds: 3200),
  builder: (context, t) {
    final a = t * 2 * math.pi;
    final rx = math.sin(a) * 0.35;
    final ry = math.cos(a) * 0.35;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.006)
        ..rotateX(rx)
        ..rotateY(ry),
      child: Container(
        width: 42,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment(-ry * 3, -rx * 3),
            end: Alignment(ry * 3, rx * 3),
            colors: [Colors.white.withValues(alpha: 0.9), _a, const Color(0xFF311B92)],
            stops: const [0, 0.35, 1],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(ry * 12, -rx * 12)),
          ],
        ),
      ),
    );
  },
);

Widget refreshPreview() => LoopPreview(
  duration: const Duration(milliseconds: 2800),
  builder: (context, t) {
    final pull = _seg(t, 0.05, 0.3, Curves.easeOut) * (1 - _seg(t, 0.8, 0.92));
    final spin = _seg(t, 0.3, 0.8, Curves.linear);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        for (var i = 0; i < 4; i++)
          Positioned(top: 20 + i * 11 + pull * 16, left: 12, child: _line(i.isEven ? 48 : 36, h: 6)),
        Positioned(
          top: -22 + pull * 28,
          child: Transform.rotate(
            angle: pull * math.pi + spin * 4 * math.pi,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: _a, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  },
);

Widget woltPreview() => LoopPreview(
  duration: const Duration(milliseconds: 3200),
  builder: (context, t) {
    final up = _seg(t, 0.05, 0.25, Curves.easeOutCubic) * (1 - _seg(t, 0.82, 0.95, Curves.easeInCubic));
    final page = _seg(t, 0.45, 0.6, Curves.easeInOutCubic);
    return Stack(
      children: [
        for (var i = 0; i < 4; i++) _at(Rect.fromLTWH(10, 10 + i * 10.0, 50, 5), _line(50)),
        Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.25 * up))),
        _at(
          Rect.fromLTWH(4, 72 - 44 * up, 64, 46),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                _at(Rect.fromLTWH(6 - 64 * page, 8, 52, 16), _box(w: 52, h: 16, r: 4)),
                _at(Rect.fromLTWH(70 - 64 * page, 8, 52, 16), _box(w: 52, h: 16, r: 4, color: _b)),
                _at(const Rect.fromLTWH(6, 30, 52, 8), _box(w: 52, h: 8, r: 4, color: Colors.black26)),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

Widget likeButtonPreview() => LoopPreview(
  duration: const Duration(milliseconds: 2200),
  builder: (context, t) {
    final liked = t > 0.12 && t < 0.88;
    final pop = Curves.elasticOut.transform(_seg(t, 0.12, 0.6, Curves.linear));
    final burst = _seg(t, 0.12, 0.45, Curves.easeOutCubic);
    final dotsAlpha = 1 - _seg(t, 0.3, 0.5);
    const colors = [Colors.pink, _b, _a, Colors.amber];
    return Stack(
      alignment: Alignment.center,
      children: [
        if (liked)
          for (var i = 0; i < 8; i++)
            Transform.translate(
              offset: Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) * (12 + 16 * burst),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i % 4].withValues(alpha: dotsAlpha),
                ),
              ),
            ),
        Transform.scale(
          scale: liked ? 0.5 + 0.5 * pop : 1,
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 30,
            color: liked ? Colors.pink : Colors.black38,
          ),
        ),
      ],
    );
  },
);

Widget avatarsPreview() => LoopPreview(
  duration: const Duration(milliseconds: 4000),
  builder: (context, t) {
    final a = t * 2 * math.pi;
    const palette = [Color(0xFF49007E), Color(0xFFFF005B), Color(0xFFFF7D10), Color(0xFFFFB238)];
    return ClipOval(
      child: SizedBox.square(
        dimension: 52,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: palette[0]),
              for (var i = 1; i < 4; i++)
                Transform.translate(
                  offset: Offset(math.cos(a + i * 2.1), math.sin(a * 1.3 + i)) * 14,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: palette[i], shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  },
);

Widget animatedBorderPreview() => LoopPreview(
  duration: const Duration(milliseconds: 2000),
  builder: (context, t) => CustomPaint(
    size: const Size(54, 36),
    painter: _RunningBorderPainter(t),
  ),
);

class _RunningBorderPainter extends CustomPainter {
  _RunningBorderPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = SweepGradient(
          colors: const [_a, Colors.pinkAccent, _b, Colors.cyan, _a],
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RunningBorderPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────── From config

Widget configPreview() => LoopPreview(
  duration: const Duration(milliseconds: 2400),
  builder: (context, t) {
    final p = _pingPong(t, Curves.easeInOutCubic);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(_lerp(-12, 12, p), _lerp(4, -4, p), 0, 1)
            ..rotateZ(_lerp(-0.3, 0.3, p))
            ..scaleByDouble(_lerp(0.8, 1.1, p), _lerp(0.8, 1.1, p), 1, 1),
          child: _box(w: 26, h: 20, r: 5),
        ),
        const SizedBox(height: 6),
        const Text(
          '{ json }',
          style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: _a),
        ),
      ],
    );
  },
);

Widget matrixSequencePreview() => LoopPreview(
  duration: const Duration(milliseconds: 3600),
  builder: (context, t) {
    // Four "matrix" poses in sequence, the dots below show the current one.
    const poses = [
      (0.0, 0.0, 0.0, 1.0),
      (10.0, -8.0, -0.26, 1.0),
      (0.0, -10.0, 0.0, 1.2),
      (-10.0, 4.0, 0.35, 0.95),
    ];
    final seg = t * 4;
    final i = seg.floor() % 4;
    final local = _seg(seg - seg.floor(), 0.35, 1, Curves.easeInOutCubic);
    final a = poses[i], b = poses[(i + 1) % 4];
    final m = Matrix4Tween(
      begin: Matrix4.identity()
        ..translateByDouble(a.$1, a.$2, 0, 1)
        ..rotateZ(a.$3)
        ..scaleByDouble(a.$4, a.$4, 1, 1),
      end: Matrix4.identity()
        ..translateByDouble(b.$1, b.$2, 0, 1)
        ..rotateZ(b.$3)
        ..scaleByDouble(b.$4, b.$4, 1, 1),
    ).lerp(local);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform(alignment: Alignment.center, transform: m, child: _box(w: 30, h: 22, r: 5)),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var k = 0; k < 4; k++)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: k == (local > 0.5 ? (i + 1) % 4 : i) ? _b : Colors.black12,
                ),
              ),
          ],
        ),
      ],
    );
  },
);
