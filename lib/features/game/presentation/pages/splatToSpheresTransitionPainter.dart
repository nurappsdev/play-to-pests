import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'pest_3d_screen.dart';

/// Paints a smooth transition from [_SplatPest3dPainter] to [SpheresCustomPainter].
///
/// [transition] drives the full animation:
///   0.0 → full splat
///   0.5 → midpoint burst (shockwave + particles peak here)
///   1.0 → full spheres
class SplatToSpheresTransitionPainter extends CustomPainter {
  final Color splatColor;
  final double splatProgress;
  final List<AnimatedSphere> spheres;
  final Animation<double> animation;
  final List<Animation<double>> sphereAnimations;

  /// 0.0 = splat only, 1.0 = spheres only.
  final double transition;

  SplatToSpheresTransitionPainter({
    required this.splatColor,
    required this.splatProgress,
    required this.spheres,
    required this.animation,
    required this.sphereAnimations,
    required this.transition,
  }) : super(repaint: animation);

  // ─── Curve helpers ──────────────────────────────────────────────────────────

  static double _easeIn(double t) => t * t * t;
  static double _easeOut(double t) => 1 - pow(1 - t, 3).toDouble();

  // ─── Main paint ─────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final t = transition.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);

    // ── 1. SPHERES layer (renders first / lowest) ────────────────────────────
    //    Fades in during the second half; scales from 0.85 → 1.0.
    final spheresAlpha = _easeOut((t * 2 - 1).clamp(0.0, 1.0));
    if (spheresAlpha > 0.0) {
      final spheresScale = 0.85 + 0.15 * spheresAlpha;
      _withOpacity(canvas, size, spheresAlpha, () {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(spheresScale);
        canvas.translate(-center.dx, -center.dy);
        SpheresCustomPainter(
          spheres: spheres,
          animation: animation,
          sphereAnimations: sphereAnimations,
        ).paint(canvas, size);
        canvas.restore();
      });
    }

    // ── 2. BURST particles + SHOCKWAVE ring (peaks at t = 0.5) ──────────────
    final burstAlpha = sin(t * pi).clamp(0.0, 1.0); // sin gives 0→1→0 arc
    if (burstAlpha > 0.01) {
      _drawShockwave(canvas, center, size, t, burstAlpha);
      _drawBurstParticles(canvas, center, size, t, burstAlpha);
    }

    // ── 3. SPLAT layer (renders last / highest) ──────────────────────────────
    //    Fades out during the first half; scales from 1.0 → 1.25 as it pops.
    final splatAlpha = _easeIn((1 - t * 2).clamp(0.0, 1.0));
    if (splatAlpha > 0.0) {
      final splatScale = 1.0 + 0.25 * (1 - splatAlpha); // expands as it fades
      _withOpacity(canvas, size, splatAlpha, () {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(splatScale);
        canvas.translate(-center.dx, -center.dy);
        _SplatPest3dPainter(
          color: splatColor,
          progress: splatProgress,
        ).paint(canvas, size);
        canvas.restore();
      });
    }
  }

  // ─── Shockwave ring ─────────────────────────────────────────────────────────

  void _drawShockwave(
      Canvas canvas,
      Offset center,
      Size size,
      double t,
      double alpha,
      ) {
    final unit = min(size.width, size.height);
    // Ring grows from 0 → 0.7 * unit over the transition; alpha fades with sin.
    final ringRadius = _easeOut(t) * unit * 0.70;
    final strokeWidth = (1 - t) * unit * 0.012 + unit * 0.003;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Color.lerp(
        splatColor,
        spheres.isNotEmpty ? spheres.first.color : Colors.white,
        t,
      )!.withValues(alpha: alpha * 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.012);

    canvas.drawCircle(center, ringRadius, paint);

    // Inner, slightly delayed ring for depth.
    final inner = _easeOut((t - 0.12).clamp(0.0, 1.0)) * unit * 0.55;
    paint
      ..color = paint.color.withValues(alpha: alpha * 0.35)
      ..strokeWidth = strokeWidth * 0.5;
    canvas.drawCircle(center, inner, paint);
  }

  // ─── Burst particles ────────────────────────────────────────────────────────

  void _drawBurstParticles(
      Canvas canvas,
      Offset center,
      Size size,
      double t,
      double alpha,
      ) {
    final unit = min(size.width, size.height);
    const particleCount = 14;

    // Use a fixed seed so the burst is deterministic across frames.
    final rng = math.Random();

    for (int i = 0; i < particleCount; i++) {
      final jitter = rng.nextDouble(); // 0..1, stable per particle

      // Each particle travels along its own angle with a slight random spread.
      final angle = i * 2 * pi / particleCount + (jitter - 0.5) * 0.7;

      // Travel distance grows with easeOut; earlier particles are farther along.
      final travelOffset = jitter * 0.15; // stagger start
      final travel = _easeOut((t - travelOffset).clamp(0.0, 1.0));
      final maxDist = unit * (0.32 + jitter * 0.22);
      final distance = travel * maxDist;

      // Radius starts large and shrinks as particles coast outward.
      final radius = unit * (0.025 + jitter * 0.018) * (1 - travel * 0.7);

      // Color lerps from splatColor → nearest sphere color.
      final sphereColor = spheres.isNotEmpty
          ? spheres[i % spheres.length].color
          : Colors.white;
      final particleColor = Color.lerp(splatColor, sphereColor, t)!;

      final pos = center + Offset(cos(angle) * distance, sin(angle) * distance);

      // Each particle fades with the burst envelope, dimmer near the edges.
      final particleAlpha = alpha * (0.5 + 0.5 * (1 - travel));
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = particleColor.withValues(alpha: particleAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4),
      );
    }
  }

  // ─── Utility: render fn at a given opacity via saveLayer ───────────────────

  void _withOpacity(
      Canvas canvas,
      Size size,
      double opacity,
      VoidCallback draw,
      ) {
    if (opacity >= 1.0) {
      draw();
      return;
    }
    final layerPaint = Paint()
      ..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255);
    canvas.saveLayer(Offset.zero & size, layerPaint);
    draw();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SplatToSpheresTransitionPainter old) {
    return old.transition != transition ||
        old.splatProgress != splatProgress ||
        old.splatColor != splatColor;
  }
}

class _SplatPest3dPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _SplatPest3dPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final unit = min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final rotation = progress * 2 * pi;
    final bob = sin(rotation * 1.8) * unit * 0.025;
    final pulse = 1 + sin(rotation * 2.4) * 0.035;
    final bodyCenter = center.translate(0, bob);
    final bodyWidth = unit * 0.62 * pulse;
    final bodyHeight = unit * 0.45 * (1 / pulse);
    final palette = _SplatPalette.from(color);

    _drawShadow(canvas, bodyCenter, unit, pulse);
    _drawMotionLines(canvas, bodyCenter, unit, rotation, palette);
    _drawBody(
      canvas,
      bodyCenter,
      bodyWidth,
      bodyHeight,
      unit,
      rotation,
      palette,
    );
    _drawFace(canvas, bodyCenter, unit, rotation, pulse);
    _drawAntennae(canvas, bodyCenter, unit, rotation);
  }

  void _drawShadow(Canvas canvas, Offset center, double unit, double pulse) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.44)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, unit * 0.32),
        width: unit * 0.58 * pulse,
        height: unit * 0.12,
      ),
      paint,
    );
  }

  void _drawBody(
      Canvas canvas,
      Offset center,
      double width,
      double height,
      double unit,
      double rotation,
      _SplatPalette palette,
      ) {
    final path = _inkSplatPath(center, width, height, unit, rotation);
    final bounds = path.getBounds();
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.58),
        radius: 0.9,
        colors: [palette.highlight, palette.bright, palette.base, palette.deep],
        stops: const [0.0, 0.23, 0.62, 1.0],
      ).createShader(bounds);

    canvas.drawPath(path, bodyPaint);

    final lowerShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.26)],
      ).createShader(bounds);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(bounds, lowerShade);
    canvas.restore();

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-width * 0.18, -height * 0.20),
        width: width * 0.24,
        height: height * 0.12,
      ),
      shinePaint,
    );
  }

  Path _inkSplatPath(
      Offset center,
      double width,
      double height,
      double unit,
      double rotation,
      ) {
    final points = <Offset>[];
    const radii = <double>[
      0.74,
      0.47,
      0.62,
      0.43,
      0.92,
      0.46,
      0.57,
      0.38,
      1.04,
      0.51,
      0.66,
      0.40,
      0.82,
      0.45,
      0.59,
      0.43,
      0.97,
      0.48,
      0.56,
      0.39,
      0.84,
      0.46,
      0.62,
      0.42,
      1.00,
      0.50,
      0.60,
      0.39,
      0.78,
      0.45,
      0.61,
      0.43,
    ];

    for (int i = 0; i < radii.length; i++) {
      final angle = -pi / 2 + i * 2 * pi / radii.length;
      final ripple = sin(rotation * 1.4 + i * 1.7) * 0.025;
      final radius = radii[i] + ripple;
      points.add(
        center.translate(
          cos(angle) * width * 0.50 * radius,
          sin(angle) * height * 0.55 * radius,
        ),
      );
    }

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      if (i == 0) {
        path.moveTo(midpoint.dx, midpoint.dy);
      } else {
        path.quadraticBezierTo(
          current.dx,
          current.dy,
          midpoint.dx,
          midpoint.dy,
        );
      }
    }
    path.close();
    return path;
  }

  void _drawFace(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      double pulse,
      ) {
    final eyePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = unit * 0.028
      ..strokeCap = StrokeCap.round;
    final tilt = sin(rotation) * unit * 0.012;
    _drawAngryEye(
      canvas,
      center.translate(-unit * 0.095, -unit * 0.025 + tilt),
      unit,
      eyePaint,
      -0.72,
    );
    _drawAngryEye(
      canvas,
      center.translate(unit * 0.095, -unit * 0.027 - tilt),
      unit,
      eyePaint,
      0.72,
    );

    final mouthPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.012;
    final mouth = Path()
      ..moveTo(center.dx - unit * 0.035, center.dy + unit * 0.062 * pulse)
      ..quadraticBezierTo(
        center.dx,
        center.dy + unit * 0.036,
        center.dx + unit * 0.04,
        center.dy + unit * 0.062 / pulse,
      );
    canvas.drawPath(mouth, mouthPaint);
  }

  void _drawAngryEye(
      Canvas canvas,
      Offset center,
      double unit,
      Paint paint,
      double angle,
      ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final w = unit * 0.072; // half-width  (long axis)
    final h = unit * 0.038; // half-height (short axis)

    // ── 1. TEARDROP BODY ─────────────────────────────────────────────────────
    // Built from two cubics:
    //   • left side: the blunt, rounded end
    //   • right side: the tapered point (teardrop tip)
    final bodyPath = Path()
      ..moveTo(-w, 0)
    // top edge — gentle outward arc toward the pointed tip
      ..cubicTo(-w * 0.50, -h * 1.10, w * 0.30, -h * 0.95, w, 0)
    // bottom edge — slightly fuller belly, matching tip
      ..cubicTo(w * 0.30, h * 1.05, -w * 0.50, h * 1.10, -w, 0)
      ..close();

    // ── 2. EDGE IRREGULARITIES ───────────────────────────────────────────────
    // Small "wobble" bumps stamped around the perimeter via a clipping
    // approach: we union tiny ellipses at irregular angular positions so the
    // silhouette reads as organically uneven rather than perfectly smooth.
    final edgePath = Path.combine(
      PathOperation.union,
      bodyPath,
      _buildEdgeBumps(w, h),
    );

    // ── 3. BASE FILL — deep near-black ───────────────────────────────────────
    final basePaint = Paint()
      ..color = const Color(0xFF0D0D0F)
      ..style = PaintingStyle.fill;

    canvas.drawPath(edgePath, basePaint);

    // ── 4. GLOSS LAYER 1 — broad inner glow along top edge ───────────────────
    // A radial gradient mimics the way light catches a convex glossy surface.
    final glossRect = Rect.fromCenter(
      center: Offset(-w * 0.15, -h * 0.30),
      width: w * 1.10,
      height: h * 0.80,
    );
    final glossPaint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.60),
        radius: 0.75,
        colors: const [
          Color(0x55FFFFFF), // bright centre
          Color(0x00FFFFFF), // fade to transparent
        ],
      ).createShader(glossRect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipPath(edgePath); // keep gloss strictly inside the eye
    canvas.drawRect(glossRect, glossPaint1);

    // ── 5. GLOSS LAYER 2 — tight specular hotspot (upper-left) ───────────────
    final hotspotPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-w * 0.38, -h * 0.42),
        width: w * 0.22,
        height: h * 0.18,
      ),
      hotspotPaint,
    );
    canvas.restore(); // remove clip

    // ── 6. RIM SHADOW — thin dark stroke to ground the form ──────────────────
    final rimPaint = Paint()
      ..color = const Color(0xFF050507)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.003
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(edgePath, rimPaint);

    canvas.restore();
  }

  // ── HELPER: organic edge bumps ────────────────────────────────────────────────
  // Returns a Path of tiny ellipses placed at irregular angles around the
  // eye perimeter.  Unioning them with the body silhouette creates the
  // slight, lumpy irregularities visible on a dark ink-like surface.
  Path _buildEdgeBumps(double w, double h) {
    const bumps = [
      // [angleRad, radiusFraction, bumpW, bumpH]
      [0.35, 0.96, 0.018, 0.010],
      [0.90, 0.98, 0.014, 0.008],
      [1.80, 0.97, 0.016, 0.009],
      [2.50, 0.95, 0.012, 0.008],
      [3.30, 0.97, 0.015, 0.009],
      [4.10, 0.96, 0.013, 0.007],
      [5.00, 0.98, 0.017, 0.010],
      [5.70, 0.95, 0.012, 0.008],
    ];

    final path = Path();
    for (final b in bumps) {
      final a = b[0];
      final r = b[1];
      // Map angle to the teardrop perimeter (approximate ellipse)
      final px = w * r * math.cos(a);
      final py = h * r * math.sin(a);
      path.addOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: w * b[2] * 2,
          height: h * b[3] * 2,
        ),
      );
    }
    return path;
  }

  void _drawAntennae(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      ) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.014;
    final sway = sin(rotation * 1.8) * unit * 0.016;
    final left = Path()
      ..moveTo(center.dx - unit * 0.12, center.dy - unit * 0.17)
      ..quadraticBezierTo(
        center.dx - unit * 0.20 + sway,
        center.dy - unit * 0.29,
        center.dx - unit * 0.30 + sway,
        center.dy - unit * 0.35,
      );
    final right = Path()
      ..moveTo(center.dx + unit * 0.12, center.dy - unit * 0.17)
      ..quadraticBezierTo(
        center.dx + unit * 0.20 - sway,
        center.dy - unit * 0.30,
        center.dx + unit * 0.29 - sway,
        center.dy - unit * 0.36,
      );
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  void _drawMotionLines(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      _SplatPalette palette,
      ) {
    final specs =
    <
        ({
        double angle,
        double distance,
        double width,
        double height,
        double phase,
        })
    >[
      (
      angle: -2.55,
      distance: 0.49,
      width: 0.12,
      height: 0.030,
      phase: 0.0,
      ),
      (
      angle: -1.58,
      distance: 0.55,
      width: 0.145,
      height: 0.035,
      phase: 0.7,
      ),
      (
      angle: -0.94,
      distance: 0.50,
      width: 0.095,
      height: 0.026,
      phase: 1.3,
      ),
      (
      angle: -0.45,
      distance: 0.52,
      width: 0.105,
      height: 0.028,
      phase: 2.0,
      ),
      (
      angle: -0.04,
      distance: 0.53,
      width: 0.095,
      height: 0.050,
      phase: 2.7,
      ),
      (
      angle: 2.92,
      distance: 0.43,
      width: 0.080,
      height: 0.030,
      phase: 3.3,
      ),
    ];
    final fill = Paint()..color = palette.base;

    for (final spec in specs) {
      final travel = sin(rotation * 1.55 + spec.phase) * unit * 0.012;
      final position = center.translate(
        cos(spec.angle) * unit * spec.distance,
        sin(spec.angle) * unit * spec.distance + travel,
      );
      _drawTaperedStroke(
        canvas,
        position,
        unit * spec.width,
        unit * spec.height,
        spec.angle + sin(rotation + spec.phase) * 0.08,
        fill,
      );
    }
  }

  void _drawTaperedStroke(
      Canvas canvas,
      Offset center,
      double width,
      double height,
      double angle,
      Paint paint,
      ) {
    final path = Path()
      ..moveTo(center.dx - width * 0.50, center.dy)
      ..quadraticBezierTo(
        center.dx - width * 0.10,
        center.dy - height * 0.74,
        center.dx + width * 0.50,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.10,
        center.dy + height * 0.74,
        center.dx - width * 0.50,
        center.dy,
      )
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplatPest3dPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SplatPalette {
  final Color highlight;
  final Color bright;
  final Color base;
  final Color deep;

  const _SplatPalette({
    required this.highlight,
    required this.bright,
    required this.base,
    required this.deep,
  });

  factory _SplatPalette.from(Color color) {
    final hsl = HSLColor.fromColor(color);
    return _SplatPalette(
      highlight: hsl
          .withLightness((hsl.lightness + 0.36).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
          .toColor(),
      bright: hsl
          .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0))
          .toColor(),
      base: color,
      deep: hsl
          .withLightness((hsl.lightness * 0.42).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation + 0.16).clamp(0.0, 1.0))
          .toColor(),
    );
  }
}
