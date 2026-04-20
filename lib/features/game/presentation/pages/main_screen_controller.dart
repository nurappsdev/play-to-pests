import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';

enum AppState { menu, game }

class MainScreenController extends StatefulWidget {
  const MainScreenController({super.key});

  @override
  State<MainScreenController> createState() => _MainScreenControllerState();
}

class _MainScreenControllerState extends State<MainScreenController> {
  AppState _currentState = AppState.menu;

  void _startGame() {
    setState(() {
      _currentState = AppState.game;
    });
  }

  void _showMenu() {
    setState(() {
      _currentState = AppState.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case AppState.menu:
        return MainMenuScreen(onPlayPressed: _startGame);
      case AppState.game:
        return GameScreen(onQuitPressed: _showMenu);
    }
  }
}
