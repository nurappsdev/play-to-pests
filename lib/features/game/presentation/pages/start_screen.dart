import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStartPressed;

  const StartScreen({
    super.key,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background image (full screen) ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/startImgs.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── START button (bottom center) ──
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: onStartPressed,
                child: Padding(
                  padding: EdgeInsets.all(0),
                  child: Image.asset(
                    height: 65,
                    width: 180,
                    'assets/images/startBtn.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
