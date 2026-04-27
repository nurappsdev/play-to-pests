import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:math';

class Pest3dScreen extends StatelessWidget {
  final VoidCallback onBackPressed;

  const Pest3dScreen({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.22),
                    radius: 0.95,
                    colors: [Color(0xFF343434), Color(0xFF111111)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: min(MediaQuery.sizeOf(context).width * 0.92, 420.0),
                height: min(MediaQuery.sizeOf(context).height * 0.68, 460.0),
                child: const AnimatedSplatPest3d(),
              ),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: IconButton.filled(
                onPressed: onBackPressed,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedSplatPest3d extends StatefulWidget {
  const AnimatedSplatPest3d({super.key});

  @override
  State<AnimatedSplatPest3d> createState() => _AnimatedSplatPest3dState();
}

class _AnimatedSplatPest3dState extends State<AnimatedSplatPest3d>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BlobPest3dPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _SplatPest3dPainter extends CustomPainter {
  final double progress;

  const _SplatPest3dPainter({required this.progress});

  static const Color _red = Color(0xFFF12A17);
  static const Color _deepRed = Color(0xFF910E07);
  static const Color _orangeRed = Color(0xFFFF6230);

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

    _drawShadow(canvas, bodyCenter, unit, pulse);
    _drawMotionLines(canvas, bodyCenter, unit, rotation);
    _drawBody(canvas, bodyCenter, bodyWidth, bodyHeight, unit, rotation);
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
  ) {
    final path = _inkSplatPath(center, width, height, unit, rotation);
    final bounds = path.getBounds();
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.58),
        radius: 0.9,
        colors: const [Color(0xFFFF9A6D), _orangeRed, _red, _deepRed],
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
      ..cubicTo(
        -w * 0.50, -h * 1.10,
        w * 0.30, -h * 0.95,
        w,         0,
      )
    // bottom edge — slightly fuller belly, matching tip
      ..cubicTo(
        w * 0.30,  h * 1.05,
        -w * 0.50,  h * 1.10,
        -w,         0,
      )
      ..close();

    // ── 2. EDGE IRREGULARITIES ───────────────────────────────────────────────
    // Small "wobble" bumps stamped around the perimeter via a clipping
    // approach: we union tiny ellipses at irregular angular positions so the
    // silhouette reads as organically uneven rather than perfectly smooth.
    final edgePath = Path.combine(PathOperation.union, bodyPath, _buildEdgeBumps(w, h));

    // ── 3. BASE FILL — deep near-black ───────────────────────────────────────
    final basePaint = Paint()
      ..color = const Color(0xFF0D0D0F)
      ..style = PaintingStyle.fill;

    canvas.drawPath(edgePath, basePaint);

    // ── 4. GLOSS LAYER 1 — broad inner glow along top edge ───────────────────
    // A radial gradient mimics the way light catches a convex glossy surface.
    final glossRect = Rect.fromCenter(
      center: Offset(-w * 0.15, -h * 0.30),
      width:  w * 1.10,
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
        width:  w * 0.22,
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
      [0.35,  0.96, 0.018, 0.010],
      [0.90,  0.98, 0.014, 0.008],
      [1.80,  0.97, 0.016, 0.009],
      [2.50,  0.95, 0.012, 0.008],
      [3.30,  0.97, 0.015, 0.009],
      [4.10,  0.96, 0.013, 0.007],
      [5.00,  0.98, 0.017, 0.010],
      [5.70,  0.95, 0.012, 0.008],
    ];

    final path = Path();
    for (final b in bumps) {
      final a  = b[0];
      final r  = b[1];
      // Map angle to the teardrop perimeter (approximate ellipse)
      final px = w * r * math.cos(a);
      final py = h * r * math.sin(a);
      path.addOval(Rect.fromCenter(
        center: Offset(px, py),
        width:  w * b[2] * 2,
        height: h * b[3] * 2,
      ));
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
    final fill = Paint()..color = _red;

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
    return oldDelegate.progress != progress;
  }
}


class _BlobPest3dPainter extends CustomPainter {
  final double progress;

  const _BlobPest3dPainter({required this.progress});

  static const Color _red = Color(0xFFF12A17);
  static const Color _deepRed = Color(0xFF910E07);
  static const Color _orangeRed = Color(0xFFFF6230);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final rotation = progress * 2 * pi;
    final bob = sin(rotation * 1.8) * unit * 0.025;
    final pulse = 1 + sin(rotation * 2.4) * 0.035;
    final bodyCenter = center.translate(0, bob);

    _drawShadow(canvas, bodyCenter, unit, pulse);
    _drawFluffyWing(canvas, bodyCenter, unit, rotation, isLeft: true);  // ← before body
    _drawFluffyWing(canvas, bodyCenter, unit, rotation, isLeft: false);
    _drawLegs(canvas, bodyCenter, unit, rotation);
    _drawBody(canvas, bodyCenter, unit, rotation, pulse);
    _drawFace(canvas, bodyCenter, unit, rotation, pulse);
    _drawAntennae(canvas, bodyCenter, unit, rotation);
    // _drawMotionLines(canvas, bodyCenter, unit, rotation);
  }

  void _drawShadow(Canvas canvas, Offset center, double unit, double pulse) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, unit * 0.30),
        width: unit * 0.62 * pulse,
        height: unit * 0.11,
      ),
      paint,
    );
  }

  void _drawFluffyWing(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation, {
        required bool isLeft,
      }) {
    final dir = isLeft ? -1.0 : 1.0;
    final fluff = sin(rotation * 2.2) * unit * 0.004;

    // Positioned upper-side, partially hidden behind body
    final wingCenter = center.translate(dir * unit * 0.18, -unit * 0.004);

    final rect = Rect.fromCenter(
      center: wingCenter,
      width: unit * 0.14 + fluff,
      height: unit * 0.18, // taller than wide — egg/teardrop shape
    );

    // Soft shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: wingCenter.translate(unit * 0.008, unit * 0.010),
        width: unit * 0.13,
        height: unit * 0.17,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Main egg puff
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(dir * -0.40, -0.50),
        radius: 0.70,
        colors: [
          Colors.white,
          const Color(0xFFF0F0F0),
          const Color(0xFFD8D8D8),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, paint);

    // Specular glint — upper inner corner
    canvas.drawOval(
      Rect.fromCenter(
        center: wingCenter.translate(dir * -unit * 0.028, -unit * 0.042),
        width: unit * 0.042,
        height: unit * 0.028,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawLegs(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      ) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = unit * 0.0154; // 0.022 * 0.7

    final legDefs = [
      // top legs
      (attachY: unit * 0.000, ctrlX: unit * 0.182, ctrlY: unit * 0.028, tipX: unit * 0.252, tipY: unit * 0.098),
      // middle legs
      (attachY: unit * 0.070, ctrlX: unit * 0.154, ctrlY: unit * 0.056, tipX: unit * 0.238, tipY: unit * 0.140),
      // bottom legs
      (attachY: unit * 0.112, ctrlX: unit * 0.140, ctrlY: unit * 0.140, tipX: unit * 0.196, tipY: unit * 0.210),
    ];

    for (int i = 0; i < legDefs.length; i++) {
      final leg = legDefs[i];
      final phase = i * 0.9;
      final kick = sin(rotation * 2.2 + phase) * unit * 0.0126; // 0.018 * 0.7

      // Right legs
      final rightPath = Path()
        ..moveTo(center.dx + unit * 0.119, center.dy + leg.attachY) // 0.17 * 0.7
        ..quadraticBezierTo(
          center.dx + leg.ctrlX,
          center.dy + leg.ctrlY + kick,
          center.dx + leg.tipX,
          center.dy + leg.tipY + kick,
        );
      canvas.drawPath(rightPath, paint);

      // Left legs (mirror X)
      final leftPath = Path()
        ..moveTo(center.dx - unit * 0.119, center.dy + leg.attachY) // 0.17 * 0.7
        ..quadraticBezierTo(
          center.dx - leg.ctrlX,
          center.dy + leg.ctrlY - kick,
          center.dx - leg.tipX,
          center.dy + leg.tipY - kick,
        );
      canvas.drawPath(leftPath, paint);
    }
  }
  void _drawBody(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      double pulse,
      ) {
    final rx = unit * 0.18 * pulse;        // narrower width
    final ry = unit * 0.30 * (1 / pulse); // taller height
    final capsuleRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    final capsulePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(capsuleRect, Radius.circular(rx)), // radius = half-width = perfect semicircle on top/bottom
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // canvas.rotate(rotation * 0.12); // gentle tilt sway with animation
    canvas.translate(-center.dx, -center.dy);

    // Gradient fill
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.55),
        radius: 0.88,
        colors: const [Color(0xFFFF9A6D), _orangeRed, _red, _deepRed],
        stops: const [0.0, 0.22, 0.60, 1.0],
      ).createShader(capsuleRect);
    canvas.drawPath(capsulePath, bodyPaint);

    // Bottom shade
    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
      ).createShader(capsuleRect);
    canvas.save();
    canvas.clipPath(capsulePath);
    canvas.drawRect(capsuleRect, shade);
    canvas.restore();

    // Specular highlight — tall & narrow to follow the vertical capsule
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-rx * 0.30, -ry * 0.30),
        width: rx * 0.40,  // narrow
        height: ry * 0.45, // tall
      ),
      shine,
    );

    canvas.restore(); // restore rotation
  }
  void _drawFace(
      Canvas canvas,
      Offset center,
      double unit,
      double rotation,
      double pulse,
      ) {
    final tilt = sin(rotation) * unit * 0.010;
    _drawEye(canvas, center.translate(-unit * 0.080, -unit * 0.020 + tilt), unit, true);
    _drawEye(canvas, center.translate(unit * 0.080, -unit * 0.022 - tilt), unit, false);

    // Mouth
    // final mouthPaint = Paint()
    //   ..color = Colors.black.withValues(alpha: 0.68)
    //   ..style = PaintingStyle.stroke
    //   ..strokeCap = StrokeCap.round
    //   ..strokeWidth = unit * 0.011;
    // final mouth = Path()
    //   ..moveTo(center.dx - unit * 0.036, center.dy + unit * 0.058 * pulse)
    //   ..quadraticBezierTo(
    //     center.dx,
    //     center.dy + unit * 0.034,
    //     center.dx + unit * 0.038,
    //     center.dy + unit * 0.058 / pulse,
    //   );
    // canvas.drawPath(mouth, mouthPaint);
  }

  void _drawEye(
      Canvas canvas,
      Offset center,
      double unit,
      bool isLeft,
      ) {
    final eyeW = unit * 0.054;
    final eyeH = unit * 0.028;
    final tiltAngle = isLeft ? -(100 * pi / 180) : (100 * pi / 180);

    final eyeRect = Rect.fromCenter(center: center, width: eyeW * 2, height: eyeH * 2);
    final scleraRect = Rect.fromCenter(center: center, width: eyeW * 2.15, height: eyeH * 2.15);

    Path makeCapsule(Rect rect) => Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);
    canvas.translate(-center.dx, -center.dy);

    // Sclera capsule
    canvas.drawPath(
      makeCapsule(scleraRect),
      Paint()..color = Colors.transparent,
    );

    // Iris / pupil capsule
    canvas.drawPath(
      makeCapsule(eyeRect),
      Paint()..color = const Color(0xFF0D0D0F),
    );

    // Glint
    canvas.drawCircle(
      center.translate(-eyeH * 0.04, -eyeH * 0.04),
      unit * 0.008,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    canvas.restore();
  }

  void _drawAntennae(Canvas canvas, Offset center, double unit, double rotation) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0D0D0F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.013;
    final sway = sin(rotation * 1.8) * unit * 0.016;

    void antenna(double baseX, double tipX, double tipY) {
      final tipOffset = Offset(tipX, tipY);
      final path = Path()
        ..moveTo(center.dx + baseX, center.dy - unit * 0.21)
        ..quadraticBezierTo(
          center.dx + baseX * 1.55 + sway * (baseX < 0 ? 1 : -1),
          center.dy - unit * 0.28,
          center.dx + tipX,
          center.dy + tipY,
        );
      canvas.drawPath(path, strokePaint);
      // Tip ball
      final tipPos = center.translate(tipX, tipY);
      canvas.drawCircle(tipPos, unit * 0.020, Paint()..color = const Color(0xFF0D0D0F));
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(tipPos, unit * 0.020, glintPaint);
    }

    antenna(-unit * 0.095, -unit * 0.14 + sway, -unit * 0.36);
    antenna(unit * 0.095, unit * 0.14 - sway, -unit * 0.37);
  }

  void _drawMotionLines(Canvas canvas, Offset center, double unit, double rotation) {
    final specs = <({double angle, double distance, double width, double height, double phase})>[
      (angle: -2.55, distance: 0.44, width: 0.09, height: 0.024, phase: 0.0),
      (angle: -1.58, distance: 0.50, width: 0.11, height: 0.028, phase: 0.7),
      (angle: -0.94, distance: 0.45, width: 0.08, height: 0.020, phase: 1.3),
      (angle: 0.00, distance: 0.48, width: 0.09, height: 0.042, phase: 2.0),
      (angle: 2.92, distance: 0.40, width: 0.07, height: 0.024, phase: 3.3),
    ];
    final fill = Paint()..color = _red;

    for (final spec in specs) {
      final travel = sin(rotation * 1.55 + spec.phase) * unit * 0.012;
      final pos = center.translate(
        cos(spec.angle) * unit * spec.distance,
        sin(spec.angle) * unit * spec.distance + travel,
      );
      _drawTaperedStroke(
        canvas, pos,
        unit * spec.width, unit * spec.height,
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
      ..quadraticBezierTo(center.dx - width * 0.10, center.dy - height * 0.74, center.dx + width * 0.50, center.dy)
      ..quadraticBezierTo(center.dx - width * 0.10, center.dy + height * 0.74, center.dx - width * 0.50, center.dy)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobPest3dPainter oldDelegate) =>
      oldDelegate.progress != progress;
}