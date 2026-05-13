import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/curriculum_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class GameQuestion {
  final String word;
  final List<String> letters; // shuffled + distractors
  final List<String> answer; // correct letter sequence

  const GameQuestion({
    required this.word,
    required this.letters,
    required this.answer,
  });
}

// ── Events ────────────────────────────────────────────────────────────────────
abstract class GameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartGame extends GameEvent {
  final CurriculumLevel level;
  StartGame(this.level);
}

class PlaceLetter extends GameEvent {
  final String letter;
  final int slotIndex;
  PlaceLetter(this.letter, this.slotIndex);
  @override
  List<Object?> get props => [letter, slotIndex];
}

class RemoveLetter extends GameEvent {
  final int slotIndex;
  RemoveLetter(this.slotIndex);
  @override
  List<Object?> get props => [slotIndex];
}

class SubmitAnswer extends GameEvent {}

class NextQuestion extends GameEvent {}

class ResetGame extends GameEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class GameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GamePlaying extends GameState {
  final CurriculumLevel level;
  final GameQuestion currentQuestion;
  final List<String?> placedLetters; // null = empty slot
  final List<String> availableLetters;
  final int questionIndex;
  final int totalQuestions;
  final int correctCount;
  final bool showFeedback;
  final bool? lastAnswerCorrect;

  GamePlaying({
    required this.level,
    required this.currentQuestion,
    required this.placedLetters,
    required this.availableLetters,
    required this.questionIndex,
    required this.totalQuestions,
    required this.correctCount,
    this.showFeedback = false,
    this.lastAnswerCorrect,
  });

  bool get allSlotsFilled => placedLetters.every((l) => l != null);

  double get progress =>
      totalQuestions == 0 ? 0 : questionIndex / totalQuestions;

  @override
  List<Object?> get props => [
        questionIndex,
        placedLetters,
        availableLetters,
        showFeedback,
        lastAnswerCorrect,
      ];
}

class GameComplete extends GameState {
  final CurriculumLevel level;
  final int correctCount;
  final int totalQuestions;
  final int stars;

  GameComplete({
    required this.level,
    required this.correctCount,
    required this.totalQuestions,
  }) : stars = _calcStars(correctCount, totalQuestions);

  static int _calcStars(int c, int t) {
    if (t == 0) return 0;
    final pct = c / t * 100;
    if (pct == 100) return 3;
    if (pct >= 80) return 2;
    if (pct >= 60) return 1;
    return 0;
  }

  @override
  List<Object?> get props => [level.id, correctCount, totalQuestions, stars];
}

class GameError extends GameState {
  final String message;
  GameError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class GameBloc extends Bloc<GameEvent, GameState> {
  static const int _questionsPerLevel = 5;
  final _rng = Random();

  List<GameQuestion> _questions = [];

  GameBloc() : super(GameInitial()) {
    on<StartGame>(_onStart);
    on<PlaceLetter>(_onPlace);
    on<RemoveLetter>(_onRemove);
    on<SubmitAnswer>(_onSubmit);
    on<NextQuestion>(_onNext);
    on<ResetGame>(_onReset);
  }

  // ── Start ──────────────────────────────────────────────────────────────────
  void _onStart(StartGame event, Emitter<GameState> emit) {
    try {
      final level = event.level;
      _questions = _buildQuestions(level);

      emit(_makePlayingState(level, 0, 0));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  // ── Place letter ───────────────────────────────────────────────────────────
  void _onPlace(PlaceLetter event, Emitter<GameState> emit) {
    if (state is! GamePlaying) return;
    final s = state as GamePlaying;

    final newPlaced = List<String?>.from(s.placedLetters);
    final newAvail = List<String>.from(s.availableLetters);

    if (event.slotIndex >= newPlaced.length) return;
    if (!newAvail.contains(event.letter)) return;

    // If slot already has a letter, put it back
    final existing = newPlaced[event.slotIndex];
    if (existing != null) {
      newAvail.add(existing);
    }

    newPlaced[event.slotIndex] = event.letter;
    newAvail.remove(event.letter);

    emit(GamePlaying(
      level: s.level,
      currentQuestion: s.currentQuestion,
      placedLetters: newPlaced,
      availableLetters: newAvail,
      questionIndex: s.questionIndex,
      totalQuestions: s.totalQuestions,
      correctCount: s.correctCount,
    ));
  }

  // ── Remove letter ──────────────────────────────────────────────────────────
  void _onRemove(RemoveLetter event, Emitter<GameState> emit) {
    if (state is! GamePlaying) return;
    final s = state as GamePlaying;

    final newPlaced = List<String?>.from(s.placedLetters);
    final newAvail = List<String>.from(s.availableLetters);

    final letter = newPlaced[event.slotIndex];
    if (letter == null) return;

    newAvail.add(letter);
    newPlaced[event.slotIndex] = null;

    emit(GamePlaying(
      level: s.level,
      currentQuestion: s.currentQuestion,
      placedLetters: newPlaced,
      availableLetters: newAvail,
      questionIndex: s.questionIndex,
      totalQuestions: s.totalQuestions,
      correctCount: s.correctCount,
    ));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  void _onSubmit(SubmitAnswer event, Emitter<GameState> emit) {
    if (state is! GamePlaying) return;
    final s = state as GamePlaying;

    if (!s.allSlotsFilled) return;

    final placed = s.placedLetters.cast<String>();
    final correct = s.currentQuestion.answer;
    final isCorrect = _listsEqual(placed, correct);

    emit(GamePlaying(
      level: s.level,
      currentQuestion: s.currentQuestion,
      placedLetters: s.placedLetters,
      availableLetters: s.availableLetters,
      questionIndex: s.questionIndex,
      totalQuestions: s.totalQuestions,
      correctCount: s.correctCount + (isCorrect ? 1 : 0),
      showFeedback: true,
      lastAnswerCorrect: isCorrect,
    ));
  }

  // ── Next ───────────────────────────────────────────────────────────────────
  void _onNext(NextQuestion event, Emitter<GameState> emit) {
    if (state is! GamePlaying) return;
    final s = state as GamePlaying;

    final nextIndex = s.questionIndex + 1;

    if (nextIndex >= s.totalQuestions) {
      emit(GameComplete(
        level: s.level,
        correctCount: s.correctCount,
        totalQuestions: s.totalQuestions,
      ));
    } else {
      emit(_makePlayingState(s.level, nextIndex, s.correctCount));
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void _onReset(ResetGame event, Emitter<GameState> emit) {
    emit(GameInitial());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  GamePlaying _makePlayingState(
      CurriculumLevel level, int qIndex, int correctSoFar) {
    final question = _questions[qIndex];
    final shuffled = List<String>.from(question.letters)..shuffle(_rng);

    return GamePlaying(
      level: level,
      currentQuestion: question,
      placedLetters: List.filled(question.answer.length, null),
      availableLetters: shuffled,
      questionIndex: qIndex,
      totalQuestions: _questions.length,
      correctCount: correctSoFar,
    );
  }

  List<GameQuestion> _buildQuestions(CurriculumLevel level) {
    final words = List<String>.from(level.words)..shuffle(_rng);
    final count = min(_questionsPerLevel, words.length);
    final selected = words.take(count).toList();

    return selected.map((word) {
      final letters = word.split('');
      // Add distractor letters from the level config
      final distractors = List<String>.from(level.distractorLetters);
      distractors.shuffle(_rng);

      // Add 2–4 distractors depending on level phase
      final numDistractors = level.phase == 2 ? 2 : (level.phase == 3 ? 3 : 4);
      final selectedDistractors = distractors.take(numDistractors).toList();

      final allLetters = [...letters, ...selectedDistractors];

      return GameQuestion(
        word: word,
        letters: allLetters,
        answer: letters,
      );
    }).toList();
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
