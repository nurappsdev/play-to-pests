import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'pest_3d_screen.dart';
import 'start_screen.dart';

enum AppState { start, game, pest3d }

class MainScreenController extends StatefulWidget {
  const MainScreenController({super.key});

  @override
  State<MainScreenController> createState() => _MainScreenControllerState();
}

class _MainScreenControllerState extends State<MainScreenController> {
  AppState _currentState = AppState.start;

  void _startGame() {
    setState(() {
      _currentState = AppState.game;
    });
  }

  void _showPest3d() {
    setState(() {
      _currentState = AppState.pest3d;
    });
  }

  void _showStart() {                      // ✅ build() এর বাইরে
    setState(() {
      _currentState = AppState.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case AppState.start:
        return StartScreen(onStartPressed: _startGame);
      case AppState.game:
        return GameScreen(onQuitPressed: _showStart);
      case AppState.pest3d:
        return Pest3dScreen(onBackPressed: _showStart);
    }                                      // ✅ switch বন্ধ
  }                                        // ✅ build() বন্ধ
}                                          // ✅ class বন্ধ