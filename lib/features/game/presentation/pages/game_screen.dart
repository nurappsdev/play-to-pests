import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../main_bindings.dart';
import '../../../score/domain/entities/score_entity.dart';
import '../../domain/entities/pest_model.dart';
import '../widgets/pest_widget.dart';

// ─── Confetti Particle ─────────────────────────────────────────────────────
class _ConfettiPiece {
  final double x;            // 0..1 base horizontal position
  final double startY;       // 0..1 initial vertical offset
  final double size;
  final Color color;
  final double rotationStart;
  final double rotationSpeed; // radians per loop
  final double fallSpeed;     // fraction of height per loop
  final double swayAmplitude; // 0..1 horizontal sway range
  final double swayPhase;
  final bool isSquare;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.size,
    required this.color,
    required this.rotationStart,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.isSquare,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double t; // 0..1 looping
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      // Loop from -0.1 (just above top) to 1.1 (just below bottom).
      final yNorm = ((p.startY + p.fallSpeed * t) % 1.2) - 0.1;
      final sway = sin((t + p.swayPhase) * 2 * pi) * p.swayAmplitude;
      final xNorm = p.x + sway;
      final rotation = p.rotationStart + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(xNorm * size.width, yNorm * size.height);
      canvas.rotate(rotation);
      final paint = Paint()..color = p.color;
      if (p.isSquare) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || !identical(old.pieces, pieces);
}

// ─── 3-D Score Painter ─────────────────────────────────────────────────────
class _Score3DPainter extends CustomPainter {
  final String text;
  final double fontSize;
  _Score3DPainter(this.text, this.fontSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Depth shadow layers
    for (int i = 6; i >= 1; i--) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..color = Color.lerp(
                  const Color(0xFF1B5E20), const Color(0xFF2E7D32), i / 6)!,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2 + i * 0.6,
          (size.height - tp.height) / 2 + i * 0.8,
        ),
      );
    }

    // Gradient fill
    final main = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [
                Color(0xFF81C784),
                Color(0xFF4CAF50),
                Color(0xFF388E3C),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    main.paint(
      canvas,
      Offset(
        (size.width - main.width) / 2,
        (size.height - main.height) / 2,
      ),
    );

    // White top-highlight
    final hl = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    hl.paint(
      canvas,
      Offset(
        (size.width - hl.width) / 2,
        (size.height - hl.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_Score3DPainter old) =>
      old.text != text || old.fontSize != fontSize;
}

// ─── Game Screen ───────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final VoidCallback onQuitPressed;
  const GameScreen({super.key, required this.onQuitPressed});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int _gameDurationSeconds = 30;
  static const int _endPhaseSeconds = 8;

  int _score = 0;
  int _gameTimeRemaining = _gameDurationSeconds;
  bool _isGameRunning = false;
  final List<PestModel> _activePests = [];
  final Random _random = Random();
  int _pestIdCounter = 0;
  Timer? _spawnTimer;
  Timer? _gameCountdownTimer;

  // Overlay controllers
  late final AnimationController _overlayController;
  late final Animation<double> _overlayFadeAnim;
  late final Animation<double> _cardScaleAnim;
  late final AnimationController _confettiController;
  List<_ConfettiPiece> _confetti = [];

  static const _confettiColors = [
    Color(0xFF4CAF50),
    Color(0xFFFFEB3B),
    Color(0xFF9C27B0),
    Color(0xFF2196F3),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _overlayFadeAnim = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );
    _cardScaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _startGame();
  }

  @override
  void dispose() {
    _cleanupTimers();
    _overlayController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _cleanupTimers() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _gameCountdownTimer?.cancel();
    _gameCountdownTimer = null;
  }

  void _generateConfetti() {
    final rng = Random();
    _confetti = List.generate(20, (_) {
      return _ConfettiPiece(
        x: rng.nextDouble(),
        startY: rng.nextDouble(),
        size: 6 + rng.nextDouble() * 8,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        rotationStart: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() * 4 - 2) * pi,
        fallSpeed: 0.6 + rng.nextDouble() * 0.7,
        swayAmplitude: 0.01 + rng.nextDouble() * 0.04,
        swayPhase: rng.nextDouble(),
        isSquare: rng.nextBool(),
      );
    });
  }

  void _startGame() {
    _cleanupTimers();
    _overlayController.reset();
    _confettiController.stop();
    _confettiController.reset();
    setState(() {
      _score = 0;
      _gameTimeRemaining = _gameDurationSeconds;
      _activePests.clear();
      _isGameRunning = true;
      _confetti = [];
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
      Future.delayed(Duration(milliseconds: _random.nextInt(800)), () {
        if (_isGameRunning) spawnPest();
      });
    }
    _spawnTimer = Timer(const Duration(seconds: 1), _startSpawning);
  }

  int get _elapsedSeconds => _gameDurationSeconds - _gameTimeRemaining;

  bool _isEndPhaseElapsed(int elapsed) =>
      elapsed >= _gameDurationSeconds - _endPhaseSeconds;

  int _spawnCountForElapsed(int elapsed) {
    if (elapsed < 8) return 4 + _random.nextInt(2);
    if (elapsed < 18) return 6 + _random.nextInt(2);
    if (_isEndPhaseElapsed(elapsed)) return 8 + _random.nextInt(3);
    return 5 + _random.nextInt(3);
  }

  int _deSpawnDurationForElapsed(int elapsed) {
    if (elapsed < 8) return 1400;
    if (elapsed < 18) return 1000;
    if (_isEndPhaseElapsed(elapsed)) return 850;
    return 1000;
  }

  double _driftSpeedMultiplierForElapsed(int elapsed) {
    if (_isEndPhaseElapsed(elapsed)) return 6;
    return elapsed >= 18 ? 5 : 4;
  }

  void spawnPest() {
    final id = _pestIdCounter++;
    final alignment = Alignment(
      _random.nextDouble() * 1.6 - 0.8,
      _random.nextDouble() * 1.6 - 0.8,
    );
    const colors = [
      Color(0xFFF4D13D),
      Color(0xFFF12A17),
      Color(0xFF87C902),
      Color(0xFF2196F3),
      Color(0xFF9C27B0),
    ];
    final color = colors[_random.nextInt(colors.length)];
    final elapsed = _elapsedSeconds;

    setState(() {
      _activePests.add(PestModel(
        id: id,
        alignment: alignment,
        startOffset: Offset(
          _random.nextDouble() * 3 - 1.5,
          _random.nextDouble() * 3 - 1.5,
        ),
        color: color,
        size: 96.0,
        driftSpeedMultiplier: _driftSpeedMultiplierForElapsed(elapsed),
      ));
    });

    Timer(Duration(milliseconds: _deSpawnDurationForElapsed(elapsed)), () {
      if (_isGameRunning) {
        setState(() =>
            _activePests.removeWhere((p) => p.id == id && !p.isHit));
      }
    });
  }

  void _handleHit(int id) async {
    if (!_isGameRunning) return;
    final index = _activePests.indexWhere((p) => p.id == id);
    if (index == -1 || _activePests[index].isHit) return;
    _activePests[index].isHit = true;
    setState(() => _score++);
    Future.delayed(PestWidget.hitSequenceDuration, () {
      if (mounted) {
        setState(() => _activePests.removeWhere((p) => p.id == id));
      }
    });
  }

  Future<void> _endGame() async {
    setState(() => _isGameRunning = false);
    _cleanupTimers();
    _generateConfetti();
    _overlayController.forward();
    _confettiController.repeat();

    if (_score > 0) {
      await MainBindings.saveScoreUseCase.execute(
        ScoreEntity(score: _score, dateTime: DateTime.now()),
      );
    }
  }

  // Stress relief scales with how many pests were squashed.
  // Linear: score × 1.1, capped at 99%.
  int get _stressReducedPercent {
    final raw = (_score * 1.1).round();
    return raw.clamp(0, 99);
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
              // ── HUD ──
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

              // ── Pests ──
              ..._activePests.map(
                    (pest) => PestWidget(
                  key: ValueKey(pest.id),
                  pest: pest,
                  onTap: () => _handleHit(pest.id),
                  enabled: _isGameRunning,
                ),
              ),

              // ── Game Over Overlay (Result screen) ──
              if (!_isGameRunning)
                FadeTransition(
                  opacity: _overlayFadeAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      // linear-gradient(180deg, #E6F7F1 0%, #CFEEE3 137.91%)
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE6F7F1), Color(0xFFCFEEE3)],
                        stops: [0.0, 1.3791],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Rain-like animated confetti behind everything
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _confettiController,
                            builder: (_, __) => CustomPaint(
                              painter: _ConfettiPainter(
                                _confetti,
                                _confettiController.value,
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: ScaleTransition(
                            scale: _cardScaleAnim,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // TIME'S UP!
                                const Text(
                                  "TIME'S UP!",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1C1E),
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // STRESS REDUCED label
                                const Text(
                                  'STRESS REDUCED',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1C1E),
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Big green percentage with 3D effect
                                CustomPaint(
                                  size: const Size(260, 110),
                                  painter: _Score3DPainter(
                                    '$_stressReducedPercent%',
                                    78,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // RETRY button (PNG with press-to-shrink)
                                _RetryImageButton(
                                  asset: 'assets/images/retry_button.png',
                                  width: 200,
                                  onTap: _startGame,
                                ),
                                const SizedBox(height: 10),

                                // HOME text button
                                TextButton(
                                  onPressed: widget.onQuitPressed,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1A1C1E),
                                  ),
                                  child: const Text(
                                    'HOME',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
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

class StartButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final double width;
  final double height;

  const StartButton({
    super.key,
    required this.onTap,
    this.label = 'START',
    this.width = 180,
    this.height = 58,
  });

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.height / 2;

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
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.9),
                blurRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              colors: _pressed
                  ? const [
                Color(0xFF388E3C),
                Color(0xFF2E7D32),
                Color(0xFF1B5E20),
              ]
                  : const [
                Color(0xFF66BB6A),
                Color(0xFF43A047),
                Color(0xFF2E7D32),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glossy top shine
                Positioned(
                  top: 4,
                  left: widget.width * 0.12,
                  right: widget.width * 0.12,
                  child: Container(
                    height: widget.height * 0.38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: _pressed ? 0.20 : 0.45),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Label
                Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.height * 0.38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF1B5E20),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PNG retry button with press-to-shrink animation ────────────────────
class _RetryImageButton extends StatefulWidget {
  final String asset;
  final double width;
  final VoidCallback onTap;

  const _RetryImageButton({
    required this.asset,
    required this.width,
    required this.onTap,
  });

  @override
  State<_RetryImageButton> createState() => _RetryImageButtonState();
}

class _RetryImageButtonState extends State<_RetryImageButton> {
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
