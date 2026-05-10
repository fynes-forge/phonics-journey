import '../datasources/hive_datasource.dart';
import '../models/progress_model.dart';

class ProgressRepository {
  final HiveDatasource _datasource;

  ProgressRepository(this._datasource);

  Future<void> saveProgress(LevelProgressModel progress) =>
      _datasource.saveProgress(progress);

  LevelProgressModel? getProgress(String profileId, int levelId) =>
      _datasource.getProgress(profileId, levelId);

  List<LevelProgressModel> getAllProgressForProfile(String profileId) =>
      _datasource.getAllProgressForProfile(profileId);

  /// Returns whether a level is unlocked for the given profile.
  /// Level 1 is always unlocked.
  /// Level N is unlocked if Level N-1 has 3 stars.
  bool isLevelUnlocked(String profileId, int levelId) {
    if (levelId == 1) return true;
    final prevProgress = getProgress(profileId, levelId - 1);
    return prevProgress?.stars == 3;
  }

  /// Record a completed attempt and update stars if improved.
  Future<LevelProgressModel> recordAttempt({
    required String profileId,
    required int levelId,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final existing = getProgress(profileId, levelId);
    final newStars =
        LevelProgressModel.calculateStars(correctAnswers, totalQuestions);
    final newScore =
        totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0;

    final updated = LevelProgressModel(
      profileId: profileId,
      levelId: levelId,
      stars: existing != null ? (newStars > existing.stars ? newStars : existing.stars) : newStars,
      bestScore: existing != null
          ? (newScore > existing.bestScore ? newScore : existing.bestScore)
          : newScore,
      attempts: (existing?.attempts ?? 0) + 1,
      lastPlayed: DateTime.now(),
      isUnlocked: true,
      totalCorrect: (existing?.totalCorrect ?? 0) + correctAnswers,
      totalAttempted: (existing?.totalAttempted ?? 0) + totalQuestions,
    );

    await saveProgress(updated);

    // Unlock next level if 3 stars achieved
    if (updated.stars == 3) {
      final nextExisting = getProgress(profileId, levelId + 1);
      if (nextExisting == null) {
        await saveProgress(LevelProgressModel(
          profileId: profileId,
          levelId: levelId + 1,
          isUnlocked: true,
        ));
      } else if (!nextExisting.isUnlocked) {
        await saveProgress(nextExisting.copyWith(isUnlocked: true));
      }
    }

    return updated;
  }

  /// Initialise progress entries for a brand-new profile (only level 1 unlocked)
  Future<void> initProgressForProfile(String profileId) async {
    final existing = getAllProgressForProfile(profileId);
    if (existing.isEmpty) {
      await saveProgress(LevelProgressModel(
        profileId: profileId,
        levelId: 1,
        isUnlocked: true,
      ));
    }
  }
}
