import 'package:flutter/material.dart';
import 'features/game/presentation/pages/main_screen_controller.dart';

class TapToPestsApp extends StatelessWidget {
  const TapToPestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap To Pests',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE6F7F1), brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const MainScreenController(),
    );
  }
}
