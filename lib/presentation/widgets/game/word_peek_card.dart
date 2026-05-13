import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/emoji_dictionary_service.dart';

/// A Navigation-safe Peek Overlay.
///
/// Instead of using showDialog, this uses an [OverlayEntry] to ensure
/// that dismissing the peek never accidentally pops the game screen.
class WordPeek {
  static OverlayEntry? _currentEntry;

  /// Shows the peek at the center of the screen.
  static void show(BuildContext context, String word) {
    // If one is already showing, remove it first to prevent stacking
    dismiss();

    final emoji = EmojiDictionaryService.getEmoji(word);

    _currentEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent backdrop
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          // Centered Peek Card
          Center(
            child: Material(
              color: Colors.transparent,
              child: _PeekCardContent(
                word: word,
                emoji: emoji,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 250.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 180.ms),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  /// Removes the peek safely without touching the Navigator stack.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _PeekCardContent extends StatelessWidget {
  final String word;
  final String emoji;

  const _PeekCardContent({
    required this.word,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 80;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2329), Color(0xFF252E36)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.stardustBlue.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepSpace.withOpacity(0.8),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Peek hint label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.stardustBlue.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'WORD PEEK',
              style: TextStyle(
                fontFamily: 'Andika',
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB7C3F3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Large emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 110, height: 1.1),
            textAlign: TextAlign.center,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 24),
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.stardustBlue.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // The word
          Text(
            word.toLowerCase(),
            style: const TextStyle(
              fontFamily: 'Andika',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.moonWhite,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _PhonemeDotsRow(word: word),
          const SizedBox(height: 20),
          Text(
            'Release to continue',
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 12,
              color: const Color(0xFF4F6272).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonemeDotsRow extends StatelessWidget {
  final String word;
  const _PhonemeDotsRow({required this.word});

  static const List<Color> _dotColors = [
    AppTheme.nebulaPurple,
    AppTheme.accentOrange,
    AppTheme.starYellow,
    AppTheme.cosmicTeal,
    AppTheme.stardustBlue,
    AppTheme.successGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final letters = word.toLowerCase().split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.asMap().entries.map((entry) {
        final color = _dotColors[entry.key % _dotColors.length];
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
