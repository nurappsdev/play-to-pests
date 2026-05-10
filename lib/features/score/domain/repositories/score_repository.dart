import '../entities/score_entity.dart';

abstract class ScoreRepository {
  Future<void> saveScore(ScoreEntity score);
  Future<List<ScoreEntity>> getScores();
}
