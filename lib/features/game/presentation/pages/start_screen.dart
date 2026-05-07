import 'dart:math';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStartPressed;

  const StartScreen({
    super.key,
    required this.onStartPressed,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_ConfettiPiece> _confetti = const [];

  static const _confettiColors = <Color>[
    Color(0xFFF4D13D), // yellow
    Color(0xFFF12A17), // red
    Color(0xFF9C27B0), // purple
    Color(0xFF87C902), // green
  ];

  @override
  void initState() {
    super.initState();
    // Continuous loop – drives the pest bob/pulse animation.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final rng = Random();
    final count = 8 + rng.nextInt(3); // 8..10
    _confetti = List.generate(count, (_) {
      return _ConfettiPiece(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 8 + rng.nextDouble() * 8,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        rotation: rng.nextDouble() * 2 * pi,
        isSquare: rng.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ── Light mint gradient background (matches the screenshot) ──
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6F7F1),
              Color(0xFFCFEEE3),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Random colored confetti scattered behind everything ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConfettiPainter(_confetti),
                ),
              ),

              // ── Decorative leaf/sparkle dots scattered around ──
              const _DecorDot(top: 70, left: 140, color: Color(0xFF8BC34A)),
              const _DecorDot(top: 110, right: 70, color: Color(0xFF8BC34A)),
              const _DecorDot(top: 320, left: 30, color: Color(0xFF8BC34A)),
              const _DecorDot(top: 360, right: 50, color: Color(0xFF8BC34A)),
              const _DecorDot(bottom: 180, left: 50, color: Color(0xFF8BC34A)),

              // ── Top-left YELLOW bug ──
              Positioned(
                top: 120,
                left: 10,
                child: _CornerBug(
                  asset: 'assets/images/Yellow_bug.png',
                  size: 140,
                  controller: _controller,
                ),
              ),

              // ── Top-right RED bug ──
              Positioned(
                top: 120,
                right: 10,
                child: _CornerBug(
                  asset: 'assets/images/Red_bug.png',
                  size: 140,
                  controller: _controller,
                  phaseOffset: 0.35,
                ),
              ),

              // ── Bottom-left PURPLE bug ──
              Positioned(
                bottom: 270,
                left: 10,
                child: _CornerBug(
                  asset: 'assets/images/Purple_bug.png',
                  size: 140,
                  controller: _controller,
                  phaseOffset: 0.6,
                ),
              ),

              // ── Bottom-right GREEN bug ──
              Positioned(
                bottom: 270,
                right: 10,
                child: _CornerBug(
                  asset: 'assets/images/Green_bug.png',
                  size: 140,
                  controller: _controller,
                  phaseOffset: 0.85,
                ),
              ),

              // ── Center: SMASH STRESS title image ──


              Positioned(
                left: 0,
                right: 0,
                bottom: 450,
                child:  Center(
                  child: Image.asset(
                    'assets/images/Text.png',
                    width: 280,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              // ── START button anchored near the bottom ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 155,
                child: Center(
                  child: _ImageButton(
                    asset: 'assets/images/Button.png',
                    width: 200,
                    onTap: widget.onStartPressed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Corner bug using a PNG asset, with a gentle bob animation ───────────
class _CornerBug extends StatelessWidget {
  final String asset;
  final double size;
  final AnimationController controller;
  final double phaseOffset;

  const _CornerBug({
    required this.asset,
    required this.size,
    required this.controller,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + phaseOffset) % 1.0;
        final dy = sin(t * 2 * pi) * 6.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    );
  }
}

// ─── Tappable PNG button with press-to-shrink feedback ───────────────────
class _ImageButton extends StatefulWidget {
  final String asset;
  final double width;
  final VoidCallback onTap;

  const _ImageButton({
    required this.asset,
    required this.width,
    required this.onTap,
  });

  @override
  State<_ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<_ImageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Image.asset(
          widget.asset,
          width: widget.width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

// ─── Static confetti scattered across the start screen ───────────────────
class _ConfettiPiece {
  final double x; // 0..1 fraction of width
  final double y; // 0..1 fraction of height
  final double size;
  final Color color;
  final double rotation;
  final bool isSquare;

  const _ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.rotation,
    required this.isSquare,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  _ConfettiPainter(this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      final paint = Paint()..color = p.color;
      if (p.isSquare) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => !identical(old.pieces, pieces);
}

// ─── Tiny decorative leaf-dot used to fill empty space ────────────────────
class _DecorDot extends StatelessWidget {
  final double? top, left, right, bottom;
  final Color color;

  const _DecorDot({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.rotate(
        angle: pi / 4,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
