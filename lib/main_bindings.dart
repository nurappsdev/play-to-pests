import 'core/database/database_helper.dart';
import 'core/services/feedback_service.dart';
import 'features/score/data/datasources/score_local_datasource.dart';
import 'features/score/data/repositories/score_repository_impl.dart';
import 'features/score/domain/usecases/get_scores_usecase.dart';
import 'features/score/domain/usecases/save_score_usecase.dart';

class MainBindings {
  static late final GetScoresUseCase getScoresUseCase;
  static late final SaveScoreUseCase saveScoreUseCase;
  static final FeedbackService feedbackService = FeedbackService();

  static Future<void> init() async {
    final databaseHelper = DatabaseHelper.instance;
    final scoreLocalDataSource = ScoreLocalDataSourceImpl(
      databaseHelper: databaseHelper,
    );
    final scoreRepository = ScoreRepositoryImpl(
      localDataSource: scoreLocalDataSource,
    );

    getScoresUseCase = GetScoresUseCase(repository: scoreRepository);
    saveScoreUseCase = SaveScoreUseCase(repository: scoreRepository);

    await feedbackService.init();
  }
}
