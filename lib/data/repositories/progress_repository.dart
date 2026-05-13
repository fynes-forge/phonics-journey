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
  /// Level N is unlocked if Level N-1 has at least 1 star.
  bool isLevelUnlocked(String profileId, int levelId) {
    if (levelId == 1) return true;
    final prevProgress = getProgress(profileId, levelId - 1);

    // FIX: Changed from == 3 to > 0 so any pass unlocks the next level
    return prevProgress != null && prevProgress.stars > 0;
  }

  /// Record a completed attempt and update stars if improved.
  Future<LevelProgressModel> recordAttempt({
    required String profileId,
    required int levelId,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final existing = getProgress(profileId, levelId);

    // Calculate stars based on the new attempt
    final newStars =
        LevelProgressModel.calculateStars(correctAnswers, totalQuestions);

    final newScore = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;

    final updated = LevelProgressModel(
      profileId: profileId,
      levelId: levelId,
      // Only update stars if the new attempt is better than the previous best
      stars: existing != null
          ? (newStars > existing.stars ? newStars : existing.stars)
          : newStars,
      bestScore: existing != null
          ? (newScore > existing.bestScore ? newScore : existing.bestScore)
          : newScore,
      attempts: (existing?.attempts ?? 0) + 1,
      lastPlayed: DateTime.now(),
      isUnlocked: true,
      totalCorrect: (existing?.totalCorrect ?? 0) + correctAnswers,
      totalAttempted: (existing?.totalAttempted ?? 0) + totalQuestions,
    );

    // Persist to Hive via DataSource
    await saveProgress(updated);

    // FIX: Unlock next level if AT LEAST 1 star is achieved
    if (updated.stars > 0) {
      final nextLevelId = levelId + 1;
      final nextExisting = getProgress(profileId, nextLevelId);

      if (nextExisting == null) {
        // If no progress exists for next level, create an unlocked entry
        await saveProgress(LevelProgressModel(
          profileId: profileId,
          levelId: nextLevelId,
          isUnlocked: true,
          stars: 0,
        ));
      } else if (!nextExisting.isUnlocked) {
        // If it exists but is locked, unlock it
        await saveProgress(nextExisting.copyWith(isUnlocked: true));
      }
    }

    return updated;
  }

  /// Initialise progress entries for a brand-new profile
  Future<void> initProgressForProfile(String profileId) async {
    final existing = getAllProgressForProfile(profileId);
    if (existing.isEmpty) {
      await saveProgress(LevelProgressModel(
        profileId: profileId,
        levelId: 1,
        isUnlocked: true,
        stars: 0,
      ));
    }
  }
}
