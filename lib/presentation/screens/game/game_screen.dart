import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/audio_service.dart';
import '../../../services/curriculum_service.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../widgets/game/word_peek_card.dart'; // Ensure this contains the WordPeek class

class GameScreen extends StatefulWidget {
  final int levelId;
  const GameScreen({super.key, required this.levelId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameBloc _gameBloc;
  late final ProfileBloc _profileBloc;
  late final ProgressBloc _progressBloc;
  late final AudioService _audio;
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    _audio = GetIt.I<AudioService>();
    _profileBloc = GetIt.I<ProfileBloc>();
    _progressBloc = GetIt.I<ProgressBloc>();
    _gameBloc = GameBloc();

    final level = GetIt.I<CurriculumService>().getLevelById(widget.levelId);
    if (level != null) {
      _gameBloc.add(StartGame(level));
      Future.delayed(const Duration(milliseconds: 600), () {
        _audio.speakPhoneme(level.gpc);
      });
    }
  }

  @override
  void dispose() {
    // Safety: ensure peek is cleared if user exits while holding down
    WordPeek.dismiss(); 
    _gameBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _gameBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _progressBloc),
      ],
      child: BlocConsumer<GameBloc, GameState>(
        listener: _onGameStateChange,
        builder: (context, state) {
          if (state is GameInitial) {
            return const Scaffold(
              backgroundColor: AppTheme.deepSpace,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is GameError) {
            return Scaffold(
              backgroundColor: AppTheme.deepSpace,
              body: Center(
                child: Text('Error: ${state.message}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          if (state is GameComplete) {
            return _buildCompleteScreen(context, state);
          }

          if (state is GamePlaying) {
            return _buildGameScreen(context, state);
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _onGameStateChange(BuildContext context, GameState state) {
    if (state is GamePlaying && state.showFeedback) {
      if (state.lastAnswerCorrect == true) {
        unawaited(_audio.playCorrect());
        unawaited(_audio.speakWord(state.currentQuestion.word));
      } else {
        unawaited(_audio.playWrong());
      }
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _gameBloc.add(NextQuestion());
      });
    }

    if (state is GameComplete && !_celebrationShown) {
      _celebrationShown = true;
      final profileState = _profileBloc.state;
      if (profileState is ProfileLoaded) {
        _progressBloc.add(RecordLevelAttempt(
          profileId: profileState.profile.id,
          levelId: widget.levelId,
          correctAnswers: state.correctCount,
          totalQuestions: state.totalQuestions,
        ));
      }
      if (state.stars > 0) unawaited(_audio.playLevelComplete());
    }
  }

  Widget _buildGameScreen(BuildContext context, GamePlaying state) {
    final profileState = _profileBloc.state;
    final themeColor = profileState is ProfileLoaded
        ? Color(profileState.profile.themeColorValue)
        : AppTheme.profileColors[0];

    return Scaffold(
      body: Container(
        decoration: AppTheme.spaceBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, state, themeColor),
              _buildProgressBar(state, themeColor),
              const SizedBox(height: 16),
              _buildLevelInfo(context, state),
              const SizedBox(height: 24),
              _buildWordDisplay(context, state),
              const Spacer(),
              _buildLetterTiles(context, state, themeColor),
              const SizedBox(height: 24),
              _buildSubmitButton(context, state, themeColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GamePlaying state, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.moonWhite),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: AppTheme.cardDecoration(glowColor: themeColor),
            child: Text(
              'Level ${widget.levelId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _audio.speakPhoneme(state.level.gpc),
            icon: const Icon(Icons.volume_up_rounded, color: AppTheme.starYellow, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(GamePlaying state, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${state.questionIndex + 1} / ${state.totalQuestions}',
            style: const TextStyle(fontFamily: 'Andika', fontSize: 14, color: AppTheme.moonWhite),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (state.questionIndex + 1) / state.totalQuestions,
              backgroundColor: AppTheme.stardustBlue.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(themeColor),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(BuildContext context, GamePlaying state) {
    final phaseColor = AppTheme.phaseColor(state.level.phase);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: phaseColor.withOpacity(0.5)),
            ),
            child: Text(
              'Phase ${state.level.phase}',
              style: TextStyle(fontFamily: 'Andika', fontSize: 14, color: phaseColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              state.level.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.moonWhite.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay(BuildContext context, GamePlaying state) {
    return Column(
      children: [
        _WordPeekButton(
          word: state.currentQuestion.word,
          audio: _audio,
        ),
        const SizedBox(height: 20),
        if (state.showFeedback)
          _buildFeedbackOverlay(state.lastAnswerCorrect == true, state.currentQuestion.word),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              state.currentQuestion.answer.length,
              (i) => _buildDropSlot(context, state, i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlay(bool isCorrect, String word) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppTheme.successGreen : AppTheme.errorRed).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCorrect ? '⭐ Brilliant!' : '❌ Try again!',
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ),
          if (isCorrect) ...[
            const SizedBox(width: 8),
            Text(
              word,
              style: const TextStyle(fontFamily: 'Andika', fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.moonWhite),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale();
  }

  Widget _buildDropSlot(BuildContext context, GamePlaying state, int index) {
    final letter = state.placedLetters[index];
    final isCorrectSlot = state.showFeedback &&
        state.lastAnswerCorrect == false &&
        letter != null &&
        letter != state.currentQuestion.answer[index];

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _gameBloc.add(PlaceLetter(details.data, index));
        _audio.playButtonTap();
      },
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return GestureDetector(
          onTap: letter != null && !state.showFeedback
              ? () => _gameBloc.add(RemoveLetter(index))
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _slotWidth(state.currentQuestion.answer.length),
            height: _slotWidth(state.currentQuestion.answer.length),
            decoration: BoxDecoration(
              color: isHovering
                  ? AppTheme.cosmicTeal.withOpacity(0.3)
                  : (letter != null
                      ? (isCorrectSlot
                          ? AppTheme.errorRed.withOpacity(0.3)
                          : AppTheme.cosmicTeal.withOpacity(0.2))
                      : AppTheme.stardustBlue.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering
                    ? AppTheme.cosmicTeal
                    : (letter != null
                        ? (isCorrectSlot
                            ? AppTheme.errorRed
                            : AppTheme.cosmicTeal.withOpacity(0.7))
                        : Colors.white24),
                width: isHovering ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: letter != null
                  ? Text(
                      letter,
                      style: TextStyle(
                        fontFamily: 'Andika',
                        fontSize: _letterFontSize(state.currentQuestion.answer.length),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.moonWhite,
                      ),
                    ).animate().scale(begin: const Offset(0.5, 0.5), duration: 200.ms)
                  : null,
            ),
          ),
        );
      },
    );
  }

  double _slotWidth(int wordLength) => wordLength <= 3 ? 70 : wordLength <= 5 ? 58 : wordLength <= 7 ? 48 : 42;
  double _letterFontSize(int wordLength) => wordLength <= 3 ? 28 : wordLength <= 5 ? 24 : 20;

  Widget _buildLetterTiles(BuildContext context, GamePlaying state, Color themeColor) {
    if (state.showFeedback) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: state.availableLetters.map((letter) {
          return _LetterTile(
            letter: letter,
            themeColor: themeColor,
            onTap: () {
              final emptyIndex = state.placedLetters.indexOf(null);
              if (emptyIndex != -1) {
                _gameBloc.add(PlaceLetter(letter, emptyIndex));
                _audio.playButtonTap();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, GamePlaying state, Color themeColor) {
    if (state.showFeedback) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton(
        onPressed: state.allSlotsFilled ? () => _gameBloc.add(SubmitAnswer()) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.allSlotsFilled ? themeColor : Colors.grey.shade700,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Check!', style: TextStyle(fontFamily: 'Andika', fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Text('✅', style: TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteScreen(BuildContext context, GameComplete state) {
    final profileState = _profileBloc.state;
    final themeColor = profileState is ProfileLoaded ? Color(profileState.profile.themeColorValue) : AppTheme.profileColors[0];
    return Scaffold(
      body: Container(
        decoration: AppTheme.spaceBackground,
        child: Stack(
          children: [
            if (state.stars == 3)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset('assets/lottie/confetti.json', repeat: false, fit: BoxFit.cover),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.stars == 3 ? '🏆' : state.stars == 2 ? '🥈' : state.stars == 1 ? '🥉' : '💪', style: const TextStyle(fontSize: 80))
                        .animate().scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 800.ms).fadeIn(),
                    const SizedBox(height: 16),
                    Text(state.stars == 3 ? 'Amazing!' : state.stars >= 1 ? 'Well Done!' : 'Keep Trying!',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: themeColor))
                        .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(i < state.stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 44, color: i < state.stars ? AppTheme.starYellow : Colors.white24)
                            .animate(delay: Duration(milliseconds: 500 + i * 150)).scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 600.ms);
                      }),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: AppTheme.cardDecoration(glowColor: themeColor),
                      child: Text('${state.correctCount} / ${state.totalQuestions} correct', style: Theme.of(context).textTheme.headlineMedium),
                    ).animate(delay: 600.ms).fadeIn(),
                    const SizedBox(height: 40),
                    _buildEndButtons(state, themeColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndButtons(GameComplete state, Color themeColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _celebrationShown = false;
              _gameBloc.add(StartGame(state.level));
            },
            style: OutlinedButton.styleFrom(side: BorderSide(color: themeColor), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            child: const Text('🔄 Try Again', style: TextStyle(fontFamily: 'Andika', fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.go(AppRouter.planetPath),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            child: Text(state.stars == 3 ? '🚀 Next Level' : '🗺️ Map', style: const TextStyle(fontFamily: 'Andika', fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3);
  }
}

// ── FIXED WORD PEEK BUTTON ───────────────────────────────────────────────────

class _WordPeekButton extends StatefulWidget {
  final String word;
  final AudioService audio;

  const _WordPeekButton({required this.word, required this.audio});

  @override
  State<_WordPeekButton> createState() => _WordPeekButtonState();
}

class _WordPeekButtonState extends State<_WordPeekButton> {
  bool _peeking = false;

  void _onLongPressStart(LongPressStartDetails _) {
    if (_peeking) return;
    setState(() => _peeking = true);
    unawaited(widget.audio.speakWord(widget.word));
    // CALL THE NEW OVERLAY CLASS
    WordPeek.show(context, widget.word);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_peeking) return;
    setState(() => _peeking = false);
    // REMOVE THE OVERLAY SAFELY
    WordPeek.dismiss();
  }

  void _onLongPressCancel() {
    if (!_peeking) return;
    setState(() => _peeking = false);
    WordPeek.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unawaited(widget.audio.speakWord(widget.word)),
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel, // Added for system interrupts
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _peeking ? AppTheme.starYellow.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _peeking ? AppTheme.starYellow.withOpacity(0.5) : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.hearing_rounded, color: AppTheme.starYellow, size: 20),
                SizedBox(width: 8),
                Text('Tap to hear · Hold to peek', style: TextStyle(fontFamily: 'Andika', fontSize: 14, color: AppTheme.starYellow, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👆', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('long-press for emoji hint', style: TextStyle(fontFamily: 'Andika', fontSize: 11, color: AppTheme.stardustBlue.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Letter Tile Widget ────────────────────────────────────────────────────────
class _LetterTile extends StatelessWidget {
  final String letter;
  final Color themeColor;
  final VoidCallback onTap;

  const _LetterTile({required this.letter, required this.themeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: letter,
      feedback: Material(color: Colors.transparent, child: _tile(context, isDragging: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: _tile(context)),
      child: GestureDetector(onTap: onTap, child: _tile(context)),
    );
  }

  Widget _tile(BuildContext context, {bool isDragging = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 58,
      height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [themeColor.withOpacity(0.4), themeColor.withOpacity(0.15)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.7), width: 2),
        boxShadow: [BoxShadow(color: themeColor.withOpacity(isDragging ? 0.6 : 0.2), blurRadius: isDragging ? 16 : 6, offset: isDragging ? const Offset(0, 4) : const Offset(0, 2))],
      ),
      child: Center(child: Text(letter, style: const TextStyle(fontFamily: 'Andika', fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.moonWhite))),
    );
  }
}