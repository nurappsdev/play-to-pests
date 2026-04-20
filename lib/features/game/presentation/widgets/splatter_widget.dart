import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/splatter_model.dart';

class SplatterWidget extends StatefulWidget {
  final SplatterModel splatter;
  final VoidCallback onComplete;

  const SplatterWidget({
    super.key,
    required this.splatter,
    required this.onComplete,
  });

  @override
  State<SplatterWidget> createState() => _SplatterWidgetState();
}

class _SplatterWidgetState extends State<SplatterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    for (int i = 0; i < 15; i++) {
      _particles.add(Particle(
        angle: _random.nextDouble() * pi * 2,
        distance: _random.nextDouble() * 60 + 20,
        size: _random.nextDouble() * 8 + 4,
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.splatter.alignment,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: SplatterPainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.splatter.color,
            ),
            size: const Size(150, 150),
          );
        },
      ),
    );
  }
}

class SplatterPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  SplatterPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final currentDistance = particle.distance * progress;
      final x = center.dx + cos(particle.angle) * currentDistance;
      final y = center.dy + sin(particle.angle) * currentDistance;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity);

      final path = Path();
      final particleSize = particle.size * (1.0 - progress * 0.5);
      
      path.moveTo(x, y - particleSize);
      path.lineTo(x + particleSize, y);
      path.lineTo(x, y + particleSize);
      path.lineTo(x - particleSize, y);
      path.close();

      canvas.drawPath(path, paint);
      
      if (progress < 0.5) {
        canvas.drawCircle(
          Offset(x + cos(particle.angle) * 5, y + sin(particle.angle) * 5),
          particleSize * 0.3,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplatterPainter oldDelegate) => true;
}
