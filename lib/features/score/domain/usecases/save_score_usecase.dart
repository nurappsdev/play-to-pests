import '../entities/score_entity.dart';
import '../repositories/score_repository.dart';

class SaveScoreUseCase {
  final ScoreRepository repository;

  SaveScoreUseCase({required this.repository});

  Future<void> execute(ScoreEntity score) async {
    await repository.saveScore(score);
  }
}
