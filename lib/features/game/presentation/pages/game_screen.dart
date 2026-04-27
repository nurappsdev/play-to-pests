import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../main_bindings.dart';
import '../../../score/domain/entities/score_entity.dart';
import '../../domain/entities/pest_model.dart';
import '../widgets/pest_widget.dart';

class GameScreen extends StatefulWidget {
  final VoidCallback onQuitPressed;
  const GameScreen({super.key, required this.onQuitPressed});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int _score = 0;
  int _gameTimeRemaining = 30;
  bool _isGameRunning = false;
  final List<PestModel> _activePests = [];
  final Random _random = Random();
  int _pestIdCounter = 0;
  Timer? _spawnTimer;
  Timer? _gameCountdownTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _cleanupTimers();
    super.dispose();
  }

  void _cleanupTimers() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _gameCountdownTimer?.cancel();
    _gameCountdownTimer = null;
  }

  void _startGame() {
    _cleanupTimers();
    setState(() {
      _score = 0;
      _gameTimeRemaining = 30;
      _activePests.clear();
      _isGameRunning = true;
    });

    _startSpawning();
    _startGameCountdown();
  }

  void _startGameCountdown() {
    _gameCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameRunning) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_gameTimeRemaining > 0) {
          _gameTimeRemaining--;
        } else {
          _endGame();
          timer.cancel();
        }
      });
    });
  }

  void _startSpawning() {
    if (!_isGameRunning) return;

    final spawnCount = _spawnCountForElapsed(_elapsedSeconds);

    for (int i = 0; i < spawnCount; i++) {
      // Small delay between spawns within the same second for better feel
      Future.delayed(Duration(milliseconds: _random.nextInt(800)), () {
        if (_isGameRunning) spawnPest();
      });
    }

    _spawnTimer = Timer(const Duration(seconds: 1), _startSpawning);
  }

  int get _elapsedSeconds => 30 - _gameTimeRemaining;

  int _spawnCountForElapsed(int elapsed) {
    if (elapsed < 8) {
      return 2 + _random.nextInt(2);
    }
    if (elapsed < 18) {
      return 4 + _random.nextInt(2);
    }
    return 5 + _random.nextInt(3);
  }

  int _deSpawnDurationForElapsed(int elapsed) {
    if (elapsed < 8) {
      return 2000;
    }
    if (elapsed < 18) {
      return 1500;
    }
    return 1000;
  }

  double _driftSpeedMultiplierForElapsed(int elapsed) {
    return elapsed >= 18 ? 1.8 : 1.0;
  }

  void spawnPest() {
    final id = _pestIdCounter++;
    final alignment = Alignment(
      _random.nextDouble() * 1.6 - 0.8,
      _random.nextDouble() * 1.6 - 0.8,
    );

    const colors = [
      Color(0xFFF4D13D),
      Color(0xFFF28C28),
      Color(0xFFE84B3C),
      Color(0xFF4CAF50),
    ];
    final color = colors[_random.nextInt(colors.length)];

    final elapsed = _elapsedSeconds;

    setState(() {
      _activePests.add(
        PestModel(
          id: id,
          alignment: alignment,
          startOffset: Offset(
            _random.nextDouble() * 3 - 1.5,
            _random.nextDouble() * 3 - 1.5,
          ),
          color: color,
          size: 96.0,
          driftSpeedMultiplier: _driftSpeedMultiplierForElapsed(elapsed),
        ),
      );
    });

    final deSpawnDuration = _deSpawnDurationForElapsed(elapsed);

    Timer(Duration(milliseconds: deSpawnDuration), () {
      if (_isGameRunning) {
        setState(() {
          _activePests.removeWhere((p) => p.id == id && !p.isHit);
        });
      }
    });
  }

  void _handleHit(int id) async {
    if (!_isGameRunning) return;
    int index = _activePests.indexWhere((p) => p.id == id);
    if (index == -1 || _activePests[index].isHit) return;

    _activePests[index].isHit = true;

    setState(() {
      _score++;
    });

    // The widget will handle its own disappearance after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _activePests.removeWhere((p) => p.id == id);
        });
      }
    });
  }

  Future<void> _endGame() async {
    setState(() {
      _isGameRunning = false;
    });
    _cleanupTimers();

    if (_score > 0) {
      await MainBindings.saveScoreUseCase.execute(
        ScoreEntity(score: _score, dateTime: DateTime.now()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F7F1), Color(0xFFCFEEE3)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // UI Stats
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statLabel('SCORE: $_score'),
                    const SizedBox(width: 20),
                    _statLabel(
                      'TIME: $_gameTimeRemaining',
                      isAlert: _gameTimeRemaining < 10,
                    ),
                  ],
                ),
              ),

              // Game Layer
              ..._activePests.map(
                (pest) => PestWidget(
                  key: ValueKey(pest.id),
                  pest: pest,
                  onTap: () => _handleHit(pest.id),
                  enabled: _isGameRunning,
                ),
              ),

              // Game Over Layer
              if (!_isGameRunning)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCFEEE3),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'RETRY',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: widget.onQuitPressed,
                          child: const Text(
                            'HOME',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statLabel(String text, {bool isAlert = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: isAlert ? Colors.red : Colors.black.withValues(alpha: 0.6),
      ),
    );
  }
}
