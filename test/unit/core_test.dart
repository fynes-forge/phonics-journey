import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_journey/data/models/progress_model.dart';
import 'package:phonics_journey/presentation/blocs/game/game_bloc.dart';
import 'package:phonics_journey/services/curriculum_service.dart';

void main() {
  // ── LevelProgressModel tests ───────────────────────────────────────────────
  group('LevelProgressModel', () {
    test('calculateStars returns 3 for 100%', () {
      expect(LevelProgressModel.calculateStars(5, 5), 3);
      expect(LevelProgressModel.calculateStars(10, 10), 3);
    });

    test('calculateStars returns 2 for 80–99%', () {
      expect(LevelProgressModel.calculateStars(4, 5), 2);  // 80%
      expect(LevelProgressModel.calculateStars(8, 10), 2); // 80%
      expect(LevelProgressModel.calculateStars(9, 10), 2); // 90%
    });

    test('calculateStars returns 1 for 60–79%', () {
      expect(LevelProgressModel.calculateStars(3, 5), 1);  // 60%
      expect(LevelProgressModel.calculateStars(6, 10), 1); // 60%
      expect(LevelProgressModel.calculateStars(7, 10), 1); // 70%
    });

    test('calculateStars returns 0 for < 60%', () {
      expect(LevelProgressModel.calculateStars(2, 5), 0);  // 40%
      expect(LevelProgressModel.calculateStars(0, 5), 0);  // 0%
      expect(LevelProgressModel.calculateStars(5, 10), 0); // 50%
    });

    test('calculateStars returns 0 for zero total', () {
      expect(LevelProgressModel.calculateStars(0, 0), 0);
    });

    test('isComplete returns true only for 3 stars', () {
      final p = LevelProgressModel(
        profileId: 'test',
        levelId: 1,
        stars: 3,
        isUnlocked: true,
      );
      expect(p.isComplete, true);
    });

    test('isComplete returns false for < 3 stars', () {
      for (int s = 0; s < 3; s++) {
        final p = LevelProgressModel(
          profileId: 'test',
          levelId: 1,
          stars: s,
          isUnlocked: true,
        );
        expect(p.isComplete, false, reason: 'Expected false for $s stars');
      }
    });

    test('copyWith preserves unchanged fields', () {
      final original = LevelProgressModel(
        profileId: 'abc',
        levelId: 5,
        stars: 2,
        bestScore: 80,
        attempts: 3,
        isUnlocked: true,
      );
      final copy = original.copyWith(stars: 3);
      expect(copy.stars, 3);
      expect(copy.profileId, 'abc');
      expect(copy.levelId, 5);
      expect(copy.bestScore, 80);
      expect(copy.attempts, 3);
    });
  });

  // ── GameBloc tests ─────────────────────────────────────────────────────────
  group('GameBloc', () {
    late GameBloc bloc;
    late CurriculumLevel testLevel;

    setUp(() {
      bloc = GameBloc();
      testLevel = const CurriculumLevel(
        id: 1,
        phase: 2,
        title: 'Test level',
        gpc: 's',
        phoneme: 's',
        grapheme: 's',
        exampleWord: 'sat',
        words: ['sat', 'tip', 'nap'],
        trickyWords: [],
        distractorLetters: ['b', 'd'],
        description: 'Test',
        startsUnlocked: true,
      );
    });

    tearDown(() => bloc.close());

    test('initial state is GameInitial', () {
      expect(bloc.state, isA<GameInitial>());
    });

    test('emits GamePlaying after StartGame', () async {
      bloc.add(StartGame(testLevel));
      await expectLater(
        bloc.stream,
        emits(isA<GamePlaying>()),
      );
    });

    test('GamePlaying has correct question count', () async {
      bloc.add(StartGame(testLevel));
      final state = await bloc.stream.first as GamePlaying;
      expect(state.totalQuestions, lessThanOrEqualTo(5));
      expect(state.totalQuestions, greaterThan(0));
    });

    test('PlaceLetter moves letter to slot', () async {
      bloc.add(StartGame(testLevel));
      await bloc.stream.first; // consume GamePlaying

      final initial = bloc.state as GamePlaying;
      final letter = initial.availableLetters.first;

      bloc.add(PlaceLetter(letter, 0));
      final next = await bloc.stream.first as GamePlaying;

      expect(next.placedLetters[0], letter);
      expect(next.availableLetters.contains(letter), false);
    });

    test('RemoveLetter returns letter to available', () async {
      bloc.add(StartGame(testLevel));
      await bloc.stream.first;

      final initial = bloc.state as GamePlaying;
      final letter = initial.availableLetters.first;

      bloc.add(PlaceLetter(letter, 0));
      await bloc.stream.first;

      bloc.add(RemoveLetter(0));
      final afterRemove = await bloc.stream.first as GamePlaying;

      expect(afterRemove.placedLetters[0], isNull);
      expect(afterRemove.availableLetters.contains(letter), true);
    });

    test('SubmitAnswer shows feedback', () async {
      bloc.add(StartGame(testLevel));
      await bloc.stream.first;

      final playing = bloc.state as GamePlaying;
      final correctAnswer = playing.currentQuestion.answer;

      // Place all correct letters
      for (int i = 0; i < correctAnswer.length; i++) {
        bloc.add(PlaceLetter(correctAnswer[i], i));
        await bloc.stream.first;
      }

      bloc.add(SubmitAnswer());
      final submitted = await bloc.stream.first as GamePlaying;

      expect(submitted.showFeedback, true);
    });

    test('GameComplete emits after all questions', () async {
      bloc.add(StartGame(testLevel));

      // Keep answering until complete
      await for (final state in bloc.stream) {
        if (state is GamePlaying && !state.showFeedback) {
          // Place correct letters
          final answer = state.currentQuestion.answer;
          for (int i = 0; i < answer.length; i++) {
            if (state.availableLetters.contains(answer[i])) {
              bloc.add(PlaceLetter(answer[i], i));
            }
          }
          bloc.add(SubmitAnswer());
        } else if (state is GamePlaying && state.showFeedback) {
          bloc.add(NextQuestion());
        } else if (state is GameComplete) {
          expect(state.totalQuestions, greaterThan(0));
          break;
        }
      }
    });

    test('GameComplete star calculation is correct', () {
      final complete = GameComplete(
        level: testLevel,
        correctCount: 5,
        totalQuestions: 5,
      );
      expect(complete.stars, 3);

      final twoStar = GameComplete(
        level: testLevel,
        correctCount: 4,
        totalQuestions: 5,
      );
      expect(twoStar.stars, 2);
    });

    test('ResetGame returns to GameInitial', () async {
      bloc.add(StartGame(testLevel));
      await bloc.stream.first;

      bloc.add(ResetGame());
      final state = await bloc.stream.first;
      expect(state, isA<GameInitial>());
    });
  });

  // ── CurriculumLevel helpers ────────────────────────────────────────────────
  group('CurriculumLevel', () {
    const level = CurriculumLevel(
      id: 26,
      phase: 3,
      title: 'ch',
      gpc: 'ch',
      phoneme: 'tʃ',
      grapheme: 'ch',
      exampleWord: 'chin',
      words: ['chat', 'chip'],
      trickyWords: ['I', 'he'],
      distractorLetters: ['sh', 'th'],
      description: 'ch sound',
    );

    test('isTrickyWordLevel returns false for phoneme levels', () {
      expect(level.isTrickyWordLevel, false);
    });

    test('isTrickyWordLevel returns true for tricky word levels', () {
      const tricky = CurriculumLevel(
        id: 49,
        phase: 3,
        title: 'Tricky',
        gpc: 'tricky_1',
        phoneme: 'tricky',
        grapheme: 'sight',
        exampleWord: 'the',
        words: ['the', 'to'],
        trickyWords: ['the', 'to'],
        distractorLetters: [],
        description: 'tricky',
      );
      expect(tricky.isTrickyWordLevel, true);
    });

    test('isReviewLevel returns false for regular levels', () {
      expect(level.isReviewLevel, false);
    });
  });
}
