import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../main_bindings.dart';
import '../../domain/entities/pest_model.dart';

class PestWidget extends StatefulWidget {
  final PestModel pest;
  final VoidCallback onTap;
  final bool enabled;

  const PestWidget({
    super.key,
    required this.pest,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<PestWidget> createState() => _PestWidgetState();
}

class _PestWidgetState extends State<PestWidget> with TickerProviderStateMixin {
  static const Duration _hitAnimationDuration = Duration(milliseconds: 300);

  bool _isTapped = false;
  late final Ticker _ticker;
  late final AnimationController _hitController;
  Offset _driftOffset = Offset.zero;
  Offset _velocity = Offset.zero;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final driftSpeedMultiplier = widget.pest.driftSpeedMultiplier;
    _velocity = Offset(
      (_random.nextDouble() - 0.5) * 0.003 * driftSpeedMultiplier,
      (_random.nextDouble() - 0.5) * 0.003 * driftSpeedMultiplier,
    );
    _ticker = createTicker(_onTick)..start();
    _hitController = AnimationController(
      vsync: this,
      duration: _hitAnimationDuration,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hitController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_isTapped || !mounted) return;

    setState(() {
      _driftOffset += _velocity;

      if (_random.nextDouble() < 0.02) {
        final driftSpeedMultiplier = widget.pest.driftSpeedMultiplier;
        _velocity += Offset(
          (_random.nextDouble() - 0.5) * 0.001 * driftSpeedMultiplier,
          (_random.nextDouble() - 0.5) * 0.001 * driftSpeedMultiplier,
        );
        final maxVelocity = 0.006 * driftSpeedMultiplier;
        if (_velocity.distance > maxVelocity) {
          _velocity = _velocity / _velocity.distance * maxVelocity;
        }
      }
    });
  }

  void _executeInstantTapEffects() {
    if (_isTapped || !widget.enabled) return;

    // Trigger Sound & Vibration FIRST for absolute zero-latency feel
    MainBindings.feedbackService.triggerTapFeedback();

    setState(() {
      _isTapped = true;
    });
    _ticker.stop();
    _hitController.forward(from: 0);

    widget.onTap();
  }

  double _phase(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  Widget _buildHitFrame(Color color) {
    return AnimatedBuilder(
      animation: _hitController,
      builder: (context, child) {
        final progress = _hitController.value;
        final moveOnly = Curves.easeOut.transform(_phase(progress, 0.00, 0.23));
        final scaleUp = Curves.easeOut.transform(_phase(progress, 0.23, 0.42));
        final squashPop = Curves.easeInOut.transform(
          _phase(progress, 0.42, 0.70),
        );
        final burst = Curves.easeOut.transform(_phase(progress, 0.70, 1.00));

        final insectOpacity = progress < 0.70 ? 1.0 : 1.0 - burst;
        final splatOpacity = progress < 0.42 ? 0.0 : 1.0 - burst;
        final moveOffset = Offset(0, -18 * sin(moveOnly * pi));
        final insectScale = 1.0 + (0.28 * scaleUp);
        final squashX = insectScale + (0.30 * squashPop);
        final squashY = insectScale - (0.82 * squashPop);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (burst > 0)
              ...List.generate(12, (index) {
                final angle = (index * 30) * pi / 180;
                return _Particle(
                  color: color,
                  angle: angle,
                  progress: burst,
                  isDark: index % 3 == 0,
                );
              }),
            if (splatOpacity > 0)
              Opacity(
                opacity: splatOpacity,
                child: Transform.scale(
                  scaleX: 0.35 + (0.75 * squashPop),
                  scaleY: 0.25 + (0.75 * squashPop),
                  child: _SquashPestShape(size: widget.pest.size),
                ),
              ),
            if (insectOpacity > 0)
              Opacity(
                opacity: insectOpacity,
                child: Transform.translate(
                  offset: moveOffset,
                  child: Transform.scale(
                    scaleX: squashX,
                    scaleY: squashY,
                    child: _SimplePestShape(
                      size: widget.pest.size,
                      color: color,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.pest.color;
    final currentAlignment = Alignment(
      (widget.pest.alignment.x + _driftOffset.dx).clamp(-1.0, 1.0),
      (widget.pest.alignment.y + _driftOffset.dy).clamp(-1.0, 1.0),
    );

    return Align(
      alignment: currentAlignment,
      child: GestureDetector(
        onTapDown: (_) => _executeInstantTapEffects(),
        child:
            Stack(
              alignment: Alignment.center,
              children: [
                if (_isTapped)
                  _buildHitFrame(color)
                else
                  _SimplePestShape(size: widget.pest.size, color: color)
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .shake(
                        hz: 3,
                        offset: const Offset(2, 2),
                        duration: 200.ms,
                      ),
              ],
            ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }
}

class _SquashPestShape extends StatelessWidget {
  final double size;

  const _SquashPestShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.55,
      height: size * 1.55,
      child: const CustomPaint(painter: _SquashPestPainter()),
    );
  }
}

class _SquashPestPainter extends CustomPainter {
  const _SquashPestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.shortestSide;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final splatPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.85,
        colors: const [Color(0xFFFF5A2C), Color(0xFFE32213), Color(0xFF9D140B)],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: unit * 0.38));
    final edgePaint = Paint()
      ..color = const Color(0xFF8B130C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.028
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, unit * 0.25),
        width: unit * 0.72,
        height: unit * 0.12,
      ),
      shadowPaint,
    );

    final splatPath = Path();
    const pointCount = 22;
    for (int i = 0; i < pointCount; i++) {
      final angle = (-pi / 2) + (i * 2 * pi / pointCount);
      final isSpike = i.isOdd;
      final radius = unit * (isSpike ? 0.39 : 0.27);
      final point = center.translate(cos(angle) * radius, sin(angle) * radius);
      if (i == 0) {
        splatPath.moveTo(point.dx, point.dy);
      } else {
        final previousAngle = (-pi / 2) + ((i - 0.5) * 2 * pi / pointCount);
        final controlRadius = unit * 0.31;
        final control = center.translate(
          cos(previousAngle) * controlRadius,
          sin(previousAngle) * controlRadius,
        );
        splatPath.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
      }
    }
    splatPath.close();

    canvas.drawPath(splatPath, splatPaint);
    canvas.drawPath(splatPath, edgePaint);

    final dropletPaint = Paint()
      ..color = const Color(0xFFF23A1F)
      ..style = PaintingStyle.fill;
    final dropletEdgePaint = Paint()
      ..color = const Color(0xFF8B130C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.014;
    final droplets =
        <({double angle, double distance, double width, double height})>[
          (angle: -2.55, distance: 0.48, width: 0.12, height: 0.05),
          (angle: -1.95, distance: 0.46, width: 0.08, height: 0.04),
          (angle: -1.32, distance: 0.55, width: 0.14, height: 0.05),
          (angle: -0.72, distance: 0.47, width: 0.09, height: 0.04),
          (angle: -0.18, distance: 0.50, width: 0.11, height: 0.07),
          (angle: 0.35, distance: 0.43, width: 0.09, height: 0.05),
          (angle: 2.65, distance: 0.39, width: 0.07, height: 0.04),
        ];

    for (final droplet in droplets) {
      final dropletCenter = center.translate(
        cos(droplet.angle) * unit * droplet.distance,
        sin(droplet.angle) * unit * droplet.distance,
      );
      final rect = Rect.fromCenter(
        center: dropletCenter,
        width: unit * droplet.width,
        height: unit * droplet.height,
      );
      canvas.save();
      canvas.translate(dropletCenter.dx, dropletCenter.dy);
      canvas.rotate(droplet.angle + pi / 2);
      canvas.translate(-dropletCenter.dx, -dropletCenter.dy);
      canvas.drawOval(rect, dropletPaint);
      canvas.drawOval(rect, dropletEdgePaint);
      canvas.restore();
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-unit * 0.11, -unit * 0.10),
        width: unit * 0.16,
        height: unit * 0.08,
      ),
      highlightPaint,
    );

    final darkPaint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.035;
    _drawEye(
      canvas,
      center.translate(-unit * 0.10, -unit * 0.02),
      unit,
      darkPaint,
    );
    _drawEye(
      canvas,
      center.translate(unit * 0.10, -unit * 0.03),
      unit,
      darkPaint,
    );

    final antennaPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = unit * 0.025;
    canvas.drawLine(
      center.translate(-unit * 0.15, -unit * 0.22),
      center.translate(-unit * 0.25, -unit * 0.33),
      antennaPaint,
    );
    canvas.drawLine(
      center.translate(unit * 0.12, -unit * 0.22),
      center.translate(unit * 0.20, -unit * 0.35),
      antennaPaint,
    );
  }

  void _drawEye(Canvas canvas, Offset center, double unit, Paint paint) {
    final radius = unit * 0.045;
    canvas.drawLine(
      center.translate(-radius, -radius),
      center.translate(radius, radius),
      paint,
    );
    canvas.drawLine(
      center.translate(radius, -radius),
      center.translate(-radius, radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SquashPestPainter oldDelegate) => false;
}

class _Particle extends StatelessWidget {
  final Color color;
  final double angle;
  final double progress;
  final bool isDark;

  const _Particle({
    required this.color,
    required this.angle,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final distance = 95 * progress;
    final size = 9 * (1.0 - progress).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(cos(angle) * distance, sin(angle) * distance),
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? Colors.black87 : color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SimplePestShape extends StatelessWidget {
  final double size;
  final Color color;

  const _SimplePestShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.45,
      height: size,
      child: CustomPaint(painter: _BlobCapsulePestPainter(color: color)),
    );
  }
}

class _BlobCapsulePestPainter extends CustomPainter {
  final Color color;

  const _BlobCapsulePestPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // ১. ডানা (Wings) - হালকা সাদা এবং স্বচ্ছ
    final wingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // বাম ডানা
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          centerX - size.width * 0.25,
          centerY + size.height * 0.05,
        ),
        width: size.width * 0.3,
        height: size.height * 0.25,
      ),
      wingPaint,
    );
    // ডান ডানা
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          centerX + size.width * 0.25,
          centerY + size.height * 0.05,
        ),
        width: size.width * 0.3,
        height: size.height * 0.25,
      ),
      wingPaint,
    );

    // ২. অ্যান্টেনা (Antennas) - কালো রঙের দুটি ছোট বাঁকানো লাইন
    final antennaPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final antennaPathLeft = Path();
    antennaPathLeft.moveTo(centerX - 10, centerY - size.height * 0.35);
    antennaPathLeft.quadraticBezierTo(
      centerX - 20,
      centerY - size.height * 0.5,
      centerX - 25,
      centerY - size.height * 0.45,
    );
    canvas.drawPath(antennaPathLeft, antennaPaint);

    final antennaPathRight = Path();
    antennaPathRight.moveTo(centerX + 10, centerY - size.height * 0.35);
    antennaPathRight.quadraticBezierTo(
      centerX + 20,
      centerY - size.height * 0.5,
      centerX + 25,
      centerY - size.height * 0.45,
    );
    canvas.drawPath(antennaPathRight, antennaPaint);

    // ৩. মূল শরীর (Body) - Glossy 3D Effect using Radial Gradient
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.45,
      height: size.height * 0.8,
    );

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.5), // আলোর রিফ্লেকশন বাম-উপরে
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: 0.6), // হাইলাইট
          color, // মূল রঙ
          color.withAlpha(200), // নিচের দিকে একটু গাঢ়
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(bodyRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(size.width * 0.25)),
      bodyPaint,
    );

    // ৪. চোখ (Eyes) - লম্বাটে কালো বড় চোখ
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 12, centerY - 5),
        width: 8,
        height: 12,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 12, centerY - 5),
        width: 8,
        height: 12,
      ),
      eyePaint,
    );

    // চোখের ভেতরে ছোট সাদা বিন্দু (Shine)
    final eyeShinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(centerX - 10, centerY - 8), 1.5, eyeShinePaint);
    canvas.drawCircle(Offset(centerX + 14, centerY - 8), 1.5, eyeShinePaint);

    // ৫. পায়ের অংশ (Legs) - ছোট ছোট কালো হাত/পা
    final legPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 20, centerY + 10),
      Offset(centerX - 28, centerY + 15),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX + 20, centerY + 10),
      Offset(centerX + 28, centerY + 15),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX - 20, centerY + 25),
      Offset(centerX - 28, centerY + 30),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX + 20, centerY + 25),
      Offset(centerX + 28, centerY + 30),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BlobCapsulePestPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
