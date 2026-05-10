/// App-wide constants for Phonics Journey.
/// No magic numbers elsewhere in the codebase — reference these.
class AppConstants {
  AppConstants._();

  // ── Game ──────────────────────────────────────────────────────────────────
  static const int questionsPerLevel = 5;
  static const int starsForCompletion = 3;
  static const int maxLevels = 100;
  static const int feedbackDelayMs = 1400;

  // ── Parental gate ─────────────────────────────────────────────────────────
  static const int parentalLongPressCount = 3;
  static const String defaultParentalPin = '1234';

  // ── Planet map ────────────────────────────────────────────────────────────
  static const double planetSpacing = 160.0;
  static const double planetSize = 90.0;
  static const double horizontalAmplitude = 90.0;

  // ── Audio ─────────────────────────────────────────────────────────────────
  static const double ttsSpeechRate = 0.4;
  static const double ttsPitch = 1.1;
  static const double ttsVolume = 1.0;
  static const String ttsLanguage = 'en-GB';

  // ── Typography ────────────────────────────────────────────────────────────
  static const String fontFamily = 'Andika';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const String profilesBox = 'profiles';
  static const String progressBox = 'progress';
  static const String settingsBox = 'settings';

  // ── Asset paths ───────────────────────────────────────────────────────────
  static const String curriculumAsset = 'curriculum.json';
  static const String confettiLottie = 'assets/lottie/confetti.json';
  static const String sfxCorrect = 'audio/sfx/correct.mp3';
  static const String sfxWrong = 'audio/sfx/wrong.mp3';
  static const String sfxLevelComplete = 'audio/sfx/level_complete.mp3';
  static const String sfxStar = 'audio/sfx/star.mp3';
  static const String sfxTap = 'audio/sfx/tap.mp3';
  static const String phonemesAssetDir = 'audio/phonemes/';
  static const String wordsAssetDir = 'audio/words/';
}
