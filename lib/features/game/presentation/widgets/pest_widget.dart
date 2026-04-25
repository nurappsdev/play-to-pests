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
  bool _isTapped = false;
  late final Ticker _ticker;
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
  }

  @override
  void dispose() {
    _ticker.dispose();
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

    widget.onTap();
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
                // Particle effect: 8 small circular particles spreading outward
                if (_isTapped)
                  ...List.generate(8, (index) {
                    final angle = (index * 45) * pi / 180;
                    return _Particle(color: color, angle: angle);
                  }),

                _SimplePestShape(size: widget.pest.size, color: color)
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shake(hz: 3, offset: const Offset(2, 2), duration: 200.ms)
                    .animate(target: _isTapped ? 1 : 0)
                    // Scale up quickly to 1.1x
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 60.ms,
                      curve: Curves.easeOutQuad,
                    )
                    .then()
                    // Shrink rapidly to zero
                    .scale(
                      end: const Offset(0, 0),
                      duration: 140.ms,
                      curve: Curves.easeInQuad,
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
    final wingPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEFF7F2);
    final bodyPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = color;
    final detailPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Color.lerp(color, Colors.black, 0.16)!;

    _drawCapsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.27,
        size.width * 0.32,
        size.height * 0.43,
      ),
      size.width * 0.09,
      -0.18,
      wingPaint,
    );
    _drawCapsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.27,
        size.width * 0.32,
        size.height * 0.43,
      ),
      size.width * 0.09,
      0.18,
      wingPaint,
    );

    _drawCapsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.08,
        size.width * 0.32,
        size.height * 0.84,
      ),
      size.width * 0.16,
      0,
      bodyPaint,
    );
    _drawCapsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.39,
        size.height * 0.15,
        size.width * 0.22,
        size.height * 0.22,
      ),
      size.width * 0.08,
      0,
      bodyPaint,
    );
    _drawCapsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.68,
        size.width * 0.20,
        size.height * 0.08,
      ),
      size.width * 0.04,
      0,
      detailPaint,
    );
  }

  void _drawCapsule(
    Canvas canvas,
    Rect rect,
    double radius,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobCapsulePestPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _Particle extends StatelessWidget {
  final Color color;
  final double angle;

  const _Particle({required this.color, required this.angle});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        final double dist = value * 90;
        return Transform.translate(
          offset: Offset(cos(angle) * dist, sin(angle) * dist),
          child: Opacity(
            opacity: 1.0 - value,
            child: Container(
              width: 8 * (1.0 - value),
              height: 8 * (1.0 - value),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}
