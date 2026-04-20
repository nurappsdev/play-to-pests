import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../../main_bindings.dart';
import '../../../score/domain/entities/score_entity.dart';
import '../../domain/entities/pest_model.dart';
import '../../domain/entities/splatter_model.dart';
import '../widgets/pest_widget.dart';
import '../widgets/splatter_widget.dart';

class GameScreen extends StatefulWidget {
  final VoidCallback onQuitPressed;
  const GameScreen({super.key, required this.onQuitPressed});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int _score = 0;
  int _misses = 0;
  bool _isGameRunning = false;
  final List<PestModel> _activePests = [];
  final List<SplatterModel> _activeSplatters = [];
  final Map<int, Timer> _pestTimers = {};
  Timer? _spawnTimer;
  final Random _random = Random();
  int _pestIdCounter = 0;
  int _splatterIdCounter = 0;

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
      _activePests.clear();
      _activeSplatters.clear();
      _isGameRunning = true;
    });
    spawnPest();
    _startSpawning();
  }

  void _startSpawning() {
    if (!_isGameRunning) return;

    double difficulty = _score / 10.0;
    int spawnInterval = (700 - (difficulty * 50)).clamp(300, 700).toInt();

    _spawnTimer = Timer(Duration(milliseconds: spawnInterval), () {
      if (_isGameRunning) {
        spawnPest();
        _startSpawning();
      }
    });
  }

  void spawnPest() {
    final id = _pestIdCounter++;
    final alignment = Alignment(
      _random.nextDouble() * 1.6 - 0.8,
      _random.nextDouble() * 1.6 - 0.8,
    );

    final sides = [
      const Offset(-1.5, 0),
      const Offset(1.5, 0),
      const Offset(0, -1.5),
      const Offset(0, 1.5),
    ];
    final startOffset = sides[_random.nextInt(sides.length)];
    final imagePath = _random.nextBool() ? 'assets/images/insect_1.png' : 'assets/images/insect_1.png';

    setState(() {
      _activePests.add(PestModel(
        id: id,
        alignment: alignment,
        startOffset: startOffset,
        imagePath: imagePath,
      ));
    });

    double difficulty = _score / 10.0;
    int deSpawnDuration = (2000 - (difficulty * 150)).clamp(800, 2000).toInt();

    _pestTimers[id] = Timer(Duration(milliseconds: deSpawnDuration), () {
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
        final pest = _activePests[index];
        if (wasMissed && !pest.isHit) {
          _activePests.removeAt(index);
          _misses++;
          if (_misses >= 10) _endGame();
        } else if (!wasMissed) {
          _activePests.removeAt(index);
        }
      }
    });
  }

  void _handleHit(int id) async {
    int index = _activePests.indexWhere((p) => p.id == id);
    if (index == -1 || _activePests[index].isHit) return;

    final pest = _activePests[index];

    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 100, amplitude: 128);
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    _pestTimers[id]?.cancel();
    _pestTimers.remove(id);

    setState(() {
      _activeSplatters.add(SplatterModel(
        id: _splatterIdCounter++,
        alignment: pest.alignment,
        color: pest.imagePath.contains('1') ? Colors.greenAccent : Colors.orangeAccent,
      ));

      _activePests.removeAt(index);
      _score++;
    });
  }

  Future<void> _endGame() async {
    setState(() {
      _isGameRunning = false;
    });
    _cleanupTimers();

    if (_score > 0) {
      await MainBindings.saveScoreUseCase.execute(ScoreEntity(
        score: _score,
        dateTime: DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background.png', fit: BoxFit.cover),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.pause_circle_filled, size: 40, color: Colors.white),
                    onPressed: _endGame,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statLabel('score', '$_score'),
                      _statLabel('misses', '$_misses', color: Colors.redAccent),
                    ],
                  ),
                ),
                ..._activeSplatters.map((splatter) => SplatterWidget(
                  key: ValueKey('splatter_${splatter.id}'),
                  splatter: splatter,
                  onComplete: () {
                    setState(() {
                      _activeSplatters.removeWhere((s) => s.id == splatter.id);
                    });
                  },
                )),
                ..._activePests.map((pest) => PestWidget(
                  key: ValueKey(pest.id),
                  pest: pest,
                  onTap: () => _handleHit(pest.id),
                )),
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
                          const Text('GAME OVER',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 16),
                          Text('FINAL SCORE: $_score', style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: widget.onQuitPressed,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                                child: const Text('QUIT'),
                              ),
                              ElevatedButton(
                                onPressed: _startGame,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                                child: const Text('RETRY'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statLabel(String label, String value, {Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text('$label - $value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
