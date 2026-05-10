import '../entities/score_entity.dart';
import '../repositories/score_repository.dart';

class GetScoresUseCase {
  final ScoreRepository repository;

  GetScoresUseCase({required this.repository});

  Future<List<ScoreEntity>> execute() async {
    return await repository.getScores();
  }
}
