import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TapToPestsApp());
}

class TapToPestsApp extends StatelessWidget {
  const TapToPestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap To Pests',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class PestModel {
  final int id;
  final Alignment alignment;
  final double size;

  PestModel({
    required this.id,
    required this.alignment,
    this.size = 80.0,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int _score = 0;
  int _misses = 0;
  int _streak = 0;
  bool _isGameRunning = false;
  final List<PestModel> _activePests = [];
  final Map<int, Timer> _pestTimers = {};
  Timer? _spawnTimer;
  final Random _random = Random();
  int _pestIdCounter = 0;

  @override
  void dispose() {
    _cleanupTimers();
    super.dispose();
  }

  void _cleanupTimers() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    for (var timer in _pestTimers.values) {
      timer.cancel();
    }
    _pestTimers.clear();
  }

  void _startGame() {
    _cleanupTimers();
    setState(() {
      _score = 0;
      _misses = 0;
      _streak = 0;
      _activePests.clear();
      _isGameRunning = true;
    });
    spawnPest(); // First one
    _startSpawning();
  }

  void _startSpawning() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!_isGameRunning) {
        timer.cancel();
        return;
      }
      spawnPest();
    });
  }

  void spawnPest({Alignment? alignment}) {
    final id = _pestIdCounter++;
    setState(() {
      _activePests.add(PestModel(
        id: id,
        alignment: alignment ?? Alignment(
          _random.nextDouble() * 2 - 1.0,
          _random.nextDouble() * 2 - 1.0,
        ),
      ));
    });

    _pestTimers[id] = Timer(const Duration(milliseconds: 2000), () {
      _pestTimers.remove(id);
      if (_isGameRunning) {
        _removePestById(id, wasMissed: true);
      }
    });
  }

  void _removePestById(int id, {bool wasMissed = false}) {
    if (!_isGameRunning) return;

    setState(() {
      int index = _activePests.indexWhere((p) => p.id == id);
      if (index != -1) {
        _activePests.removeAt(index);
        if (wasMissed) {
          _misses++;
          _streak = 0;
          if (_misses >= 10) _endGame();
        }
      }
    });
  }

  void _handleHit(int id) {
    HapticFeedback.lightImpact();
    _pestTimers[id]?.cancel();
    _pestTimers.remove(id);
    setState(() {
      int index = _activePests.indexWhere((p) => p.id == id);
      if (index != -1) {
        _activePests.removeAt(index);
        _score++;
        _streak++;
      }
    });
  }

  void _endGame() {
    setState(() {
      _isGameRunning = false;
    });
    _cleanupTimers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            // Score and Stats Header
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SCORE: $_score',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('MISSES: $_misses/10',
                          style: TextStyle(fontSize: 16, color: Colors.redAccent[100], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('STREAK: $_streak',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ),

            // Game Area (Active Pests)
            ..._activePests.map((pest) => PestWidget(
              key: ValueKey(pest.id),
              pest: pest,
              onTap: () => _handleHit(pest.id),
            )),

            // Start/Game Over Overlay
            if (!_isGameRunning)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_score == 0 ? 'PEST REPEL' : 'GAME OVER',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                      if (_score > 0) ...[
                        const SizedBox(height: 16),
                        Text('FINAL SCORE: $_score', style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
                        Text('BEST STREAK: $_streak', style: const TextStyle(fontSize: 18, color: Colors.orangeAccent)),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_score == 0 ? 'START' : 'RETRY',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PestWidget extends StatefulWidget {
  final PestModel pest;
  final VoidCallback onTap;

  const PestWidget({super.key, required this.pest, required this.onTap});

  @override
  State<PestWidget> createState() => _PestWidgetState();
}

class _PestWidgetState extends State<PestWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.pest.alignment,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => widget.onTap(),
          child: Container(
            width: widget.pest.size,
            height: widget.pest.size,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.bug_report, size: 48, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
