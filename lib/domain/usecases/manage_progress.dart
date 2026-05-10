import '../../data/models/progress_model.dart';
import '../../data/repositories/progress_repository.dart';

class ManageProgress {
  final ProgressRepository _repo;

  ManageProgress(this._repo);

  bool isLevelUnlocked(String profileId, int levelId) =>
      _repo.isLevelUnlocked(profileId, levelId);

  LevelProgressModel? getProgress(String profileId, int levelId) =>
      _repo.getProgress(profileId, levelId);

  List<LevelProgressModel> getAllProgress(String profileId) =>
      _repo.getAllProgressForProfile(profileId);

  Future<LevelProgressModel> recordAttempt({
    required String profileId,
    required int levelId,
    required int correctAnswers,
    required int totalQuestions,
  }) =>
      _repo.recordAttempt(
        profileId: profileId,
        levelId: levelId,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );

  Future<void> initProfile(String profileId) =>
      _repo.initProgressForProfile(profileId);
}
