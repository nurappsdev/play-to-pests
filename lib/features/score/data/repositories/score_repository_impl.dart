import '../../domain/entities/score_entity.dart';
import '../../domain/repositories/score_repository.dart';
import '../datasources/score_local_datasource.dart';
import '../models/score_model.dart';

class ScoreRepositoryImpl implements ScoreRepository {
  final ScoreLocalDataSource localDataSource;

  ScoreRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveScore(ScoreEntity score) async {
    final model = ScoreModel(
      score: score.score,
      dateTime: score.dateTime,
    );
    await localDataSource.saveScore(model);
  }

  @override
  Future<List<ScoreEntity>> getScores() async {
    return await localDataSource.getScores();
  }
}
