import 'package:flutter/material.dart';
import 'features/game/presentation/pages/main_screen_controller.dart';

class SmashStressApp extends StatelessWidget {
  const SmashStressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Stress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE6F7F1), brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const MainScreenController(),
    );
  }
}
