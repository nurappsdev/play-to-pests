import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/pest_model.dart';

class PestWidget extends StatefulWidget {
  final PestModel pest;
  final VoidCallback onTap;

  const PestWidget({super.key, required this.pest, required this.onTap});

  @override
  State<PestWidget> createState() => _PestWidgetState();
}

class _PestWidgetState extends State<PestWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isTapped = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isTapped) return;
    setState(() {
      _isTapped = true;
    });

    _audioPlayer.play(AssetSource('audio/pop.mp3')).catchError((_) {});
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.pest.color;

    return Align(
      alignment: widget.pest.alignment,
      child: GestureDetector(
        onTapDown: (_) => _handleTap(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isTapped)
              ...List.generate(8, (index) {
                final angle = (index * 45) * pi / 180;
                return _Particle(
                  color: color,
                  angle: angle,
                );
              }),
            Container(
              width: widget.pest.size,
              height: widget.pest.size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            )
                .animate(target: _isTapped ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 100.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0, 0),
                  duration: 100.ms,
                  curve: Curves.easeIn,
                ),
          ],
        )
            .animate()
            .move(
              begin: widget.pest.startOffset * 200,
              end: Offset.zero,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.bounceOut,
            ),
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
        final double dist = value * 60;
        return Transform.translate(
          offset: Offset(cos(angle) * dist, sin(angle) * dist),
          child: Opacity(
            opacity: 1.0 - value,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

