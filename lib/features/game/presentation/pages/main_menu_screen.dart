import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../main_bindings.dart';
import '../../../score/domain/entities/score_entity.dart';
import '../widgets/menu_button.dart';

class MainMenuScreen extends StatefulWidget {
  final VoidCallback onPlayPressed;

  const MainMenuScreen({super.key, required this.onPlayPressed});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _insectSlideAnimation;
  late Animation<double> _insectScaleAnimation;
  List<ScoreEntity> _topScores = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _insectSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _insectScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await MainBindings.getScoresUseCase.execute();
    if (mounted) {
      setState(() {
        _topScores = scores.take(3).toList();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildScoreChart(),
                const Spacer(),
                SlideTransition(
                  position: _insectSlideAnimation,
                  child: ScaleTransition(
                    scale: _insectScaleAnimation,
                    child: SizedBox(
                      height: 450,
                      child: Image.asset('assets/images/main_insect.png'),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Column(
                    children: [
                      MenuButton(
                        text: 'PLAY',
                        onPressed: widget.onPlayPressed,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 20),
                      MenuButton(
                        text: 'QUIT',
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'Score chart',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(color: Colors.greenAccent),
          if (_topScores.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 8),
               child: Text('No scores yet', style: TextStyle(color: Colors.white70)),
             ),
          ...List.generate(_topScores.length, (index) {
            final labels = ['Highest score', '2nd Highest score', '3rd Highest score'];
            return _scoreEntry(labels[index], _topScores[index].score.toString());
          }),
        ],
      ),
    );
  }

  Widget _scoreEntry(String label, String score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(score, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
