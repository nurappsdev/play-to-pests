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
    _velocity = Offset(
      (_random.nextDouble() - 0.5) * 0.003,
      (_random.nextDouble() - 0.5) * 0.003,
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
        _velocity += Offset(
          (_random.nextDouble() - 0.5) * 0.001,
          (_random.nextDouble() - 0.5) * 0.001,
        );
        if (_velocity.distance > 0.006) {
          _velocity = _velocity / _velocity.distance * 0.006;
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

                _InsectBody(size: widget.pest.size, color: color)
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

class _InsectBody extends StatelessWidget {
  final double size;
  final Color color;

  const _InsectBody({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.35,
            child: Row(
              children: [
                _Wing(size: size, angle: -0.5),
                SizedBox(width: size * 0.2),
                _Wing(size: size, angle: 0.5),
              ],
            ),
          ),

          Positioned(
            top: size * 0.15,
            child: Row(
              children: [
                Transform.rotate(
                  angle: -0.4,
                  child: _Antenna(color: color, height: size * 0.25),
                ),
                SizedBox(width: size * 0.3),
                Transform.rotate(
                  angle: 0.4,
                  child: _Antenna(color: color, height: size * 0.25),
                ),
              ],
            ),
          ),

          Container(
            width: size * 0.75,
            height: size * 0.9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.9), color],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wing extends StatelessWidget {
  final double size;
  final double angle;

  const _Wing({required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size * 0.45,
        height: size * 0.3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(size * 0.15),
        ),
      ),
    );
  }
}

class _Antenna extends StatelessWidget {
  final Color color;
  final double height;

  const _Antenna({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
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
