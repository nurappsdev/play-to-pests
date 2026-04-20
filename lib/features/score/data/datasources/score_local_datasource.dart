import '../../../../core/database/database_helper.dart';
import '../models/score_model.dart';

abstract class ScoreLocalDataSource {
  Future<void> saveScore(ScoreModel score);
  Future<List<ScoreModel>> getScores();
}

class ScoreLocalDataSourceImpl implements ScoreLocalDataSource {
  final DatabaseHelper databaseHelper;

  ScoreLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> saveScore(ScoreModel score) async {
    final db = await databaseHelper.database;
    await db.insert('scores', score.toMap());
  }

  @override
  Future<List<ScoreModel>> getScores() async {
    final db = await databaseHelper.database;
    final result = await db.query('scores', orderBy: 'score DESC');
    return result.map((map) => ScoreModel.fromMap(map)).toList();
  }
}
