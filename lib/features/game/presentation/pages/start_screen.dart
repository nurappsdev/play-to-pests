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

  static const _sideConfetti = <_ConfettiPiece>[
    _ConfettiPiece(
      x: 0.05,
      y: 0.05,
      size: 9,
      color: Color(0xFFF4D13D),
      rotation: pi / 5,
      isSquare: true,
    ),
    _ConfettiPiece(
      x: 0.94,
      y: 0.06,
      size: 11,
      color: Color(0xFFF12A17),
      rotation: pi / 7,
      isSquare: false,
    ),
    _ConfettiPiece(
      x: 0.04,
      y: 0.36,
      size: 10,
      color: Color(0xFF9C27B0),
      rotation: pi / 3,
      isSquare: false,
    ),
    _ConfettiPiece(
      x: 0.96,
      y: 0.39,
      size: 8,
      color: Color(0xFF87C902),
      rotation: pi / 4,
      isSquare: true,
    ),
    _ConfettiPiece(
      x: 0.08,
      y: 0.46,
      size: 8,
      color: Color(0xFFF12A17),
      rotation: pi / 8,
      isSquare: true,
    ),
    _ConfettiPiece(
      x: 0.92,
      y: 0.48,
      size: 10,
      color: Color(0xFFF4D13D),
      rotation: pi / 2.8,
      isSquare: false,
    ),
    _ConfettiPiece(
      x: 0.05,
      y: 0.78,
      size: 11,
      color: Color(0xFF87C902),
      rotation: pi / 6,
      isSquare: false,
    ),
    _ConfettiPiece(
      x: 0.95,
      y: 0.80,
      size: 9,
      color: Color(0xFF9C27B0),
      rotation: pi / 2,
      isSquare: true,
    ),
    _ConfettiPiece(
      x: 0.10,
      y: 0.90,
      size: 8,
      color: Color(0xFFF4D13D),
      rotation: pi / 4,
      isSquare: true,
    ),
    _ConfettiPiece(
      x: 0.90,
      y: 0.91,
      size: 10,
      color: Color(0xFFF12A17),
      rotation: pi / 5,
      isSquare: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final shortestSide = min(width, height);

                final bugSize = min(width * 0.34, height * 0.19)
                    .clamp(76.0, 140.0)
                    .toDouble();
                final sideInset = (width * 0.025).clamp(8.0, 24.0).toDouble();
                final topBugTop =
                    (height * 0.12).clamp(24.0, 128.0).toDouble();

                final buttonWidth =
                    (width * 0.54).clamp(160.0, 230.0).toDouble();
                final buttonVisualHeight = buttonWidth * 0.42;
                final buttonBottom =
                    (height * 0.9).clamp(28.0, 150.0).toDouble();

                final desiredLowerBugBottom = max(
                  height * 0.28,
                  buttonBottom + buttonVisualHeight + height * 0.04,
                );
                final maxLowerBugBottom = max(0.0, height - bugSize - 16.0);
                final lowerBugBottom =
                    min(desiredLowerBugBottom, maxLowerBugBottom).toDouble();

                final titleWidth =
                    (width * 0.74).clamp(210.0, 360.0).toDouble();
                final titleHeight =
                    (height * 0.22).clamp(86.0, 190.0).toDouble();
                final maxTitleTop = height -
                    titleHeight -
                    buttonVisualHeight -
                    buttonBottom -
                    24;
                final titleTop = min(
                  max(height * 0.31, topBugTop + bugSize * 0.30),
                  max(16.0, maxTitleTop),
                ).toDouble();

                final dotSize =
                    (shortestSide * 0.02).clamp(6.0, 10.0).toDouble();
                final showLowerBugs = height >= 520;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConfettiPainter(_sideConfetti),
                      ),
                    ),
                    _DecorDot(
                      top: height * 0.07,
                      left: width * 0.36,
                      size: dotSize,
                      color: const Color(0xFF8BC34A),
                    ),
                    _DecorDot(
                      top: height * 0.12,
                      right: width * 0.18,
                      size: dotSize,
                      color: const Color(0xFF8BC34A),
                    ),
                    _DecorDot(
                      top: height * 0.38,
                      left: width * 0.08,
                      size: dotSize,
                      color: const Color(0xFF8BC34A),
                    ),
                    _DecorDot(
                      top: height * 0.43,
                      right: width * 0.11,
                      size: dotSize,
                      color: const Color(0xFF8BC34A),
                    ),
                    _DecorDot(
                      bottom: height * 0.20,
                      left: width * 0.12,
                      size: dotSize,
                      color: const Color(0xFF8BC34A),
                    ),
                    Positioned(
                      top: topBugTop,
                      left: sideInset,
                      child: _CornerBug(
                        asset: 'assets/images/Yellow_bug.png',
                        size: bugSize,
                        controller: _controller,
                      ),
                    ),
                    Positioned(
                      top: topBugTop,
                      right: sideInset,
                      child: _CornerBug(
                        asset: 'assets/images/Red_bug.png',
                        size: bugSize,
                        controller: _controller,
                        phaseOffset: 0.35,
                      ),
                    ),
                    if (showLowerBugs)
                      Positioned(
                        bottom: lowerBugBottom,
                        left: sideInset,
                        child: _CornerBug(
                          asset: 'assets/images/Purple_bug.png',
                          size: bugSize,
                          controller: _controller,
                          phaseOffset: 0.6,
                        ),
                      ),
                    if (showLowerBugs)
                      Positioned(
                        bottom: lowerBugBottom,
                        right: sideInset,
                        child: _CornerBug(
                          asset: 'assets/images/Green_bug.png',
                          size: bugSize,
                          controller: _controller,
                          phaseOffset: 0.85,
                        ),
                      ),
                    Positioned(
                      top: titleTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: titleWidth,
                          height: titleHeight,
                          child: Image.asset(
                            'assets/images/Text.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: buttonBottom,
                      child: Center(
                        child: _ImageButton(
                          asset: 'assets/images/Button.png',
                          width: buttonWidth,
                          onTap: widget.onStartPressed,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

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
        final dy =
            (sin(t * 2 * pi) * (size * 0.045).clamp(3.0, 6.0)).toDouble();
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

class _ConfettiPiece {
  final double x;
  final double y;
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

class _DecorDot extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const _DecorDot({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.size = 8,
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
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
        ),
      ),
    );
  }
}
