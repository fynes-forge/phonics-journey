import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 1)
class LevelProgressModel extends HiveObject {
  @HiveField(0)
  String profileId;

  @HiveField(1)
  int levelId;

  @HiveField(2)
  int stars; // 0–3

  @HiveField(3)
  int bestScore; // 0–100 percentage

  @HiveField(4)
  int attempts;

  @HiveField(5)
  DateTime? lastPlayed;

  @HiveField(6)
  bool isUnlocked;

  @HiveField(7)
  int totalCorrect;

  @HiveField(8)
  int totalAttempted;

  LevelProgressModel({
    required this.profileId,
    required this.levelId,
    this.stars = 0,
    this.bestScore = 0,
    this.attempts = 0,
    this.lastPlayed,
    this.isUnlocked = false,
    this.totalCorrect = 0,
    this.totalAttempted = 0,
  });

  /// Calculate stars based on accuracy percentage
  static int calculateStars(int correctAnswers, int totalQuestions) {
    if (totalQuestions == 0) return 0;
    final pct = (correctAnswers / totalQuestions * 100).round();
    if (pct == 100) return 3;
    if (pct >= 80) return 2;
    if (pct >= 60) return 1;
    return 0;
  }

  bool get isComplete => stars == 3;

  LevelProgressModel copyWith({
    int? stars,
    int? bestScore,
    int? attempts,
    DateTime? lastPlayed,
    bool? isUnlocked,
    int? totalCorrect,
    int? totalAttempted,
  }) {
    return LevelProgressModel(
      profileId: profileId,
      levelId: levelId,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempted: totalAttempted ?? this.totalAttempted,
    );
  }
}
