import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/emoji_dictionary_service.dart';

/// Shown when a child long-presses the "Tap to hear" prompt or the
/// word slots during a game round.
///
/// Displays a large emoji + the written word in Andika font.
/// Dismissed automatically when the long-press is released (caller's
/// responsibility) or by tapping outside.
class WordPeekCard extends StatelessWidget {
  final String word;

  const WordPeekCard({super.key, required this.word});

  /// Shows the peek as a Dialog. Returns immediately — the dialog is
  /// dismissed by [dismissWordPeek] or a tap outside.
  static void show(BuildContext context, String word) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      barrierDismissible: true,
      // No default close button — dismissed on long-press end
      builder: (_) => WordPeekCard(word: word),
    );
  }

  /// Pops the peek dialog if one is showing.
  static void dismiss(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = EmojiDictionaryService.getEmoji(word);
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: _PeekCardContent(
        word: word,
        emoji: emoji,
        width: screenWidth - 80,
      )
          .animate()
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 180.ms),
    );
  }
}

class _PeekCardContent extends StatelessWidget {
  final String word;
  final String emoji;
  final double width;

  const _PeekCardContent({
    required this.word,
    required this.emoji,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        // Deep space gradient background
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2329), Color(0xFF252E36)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.lavender.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepSpace.withOpacity(0.8),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppTheme.lavender.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
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
              border: Border.all(
                color: const Color(0xFF4F6272).withOpacity(0.4),
              ),
            ),
            child: const Text(
              'WORD PEEK',
              style: TextStyle(
                fontFamily: 'Andika',
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4F6272),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Large emoji — uses system emoji font, never 404s
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 110,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
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
                  AppTheme.lavender.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // The word in Andika font — large and clear for reading
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

          // Phoneme segmentation dots (visual hint)
          _PhonemeDotsRow(word: word),

          const SizedBox(height: 20),

          // Release hint
          Text(
            'Release to continue',
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 12,
              color: const Color(0xFF4F6272).withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders one coloured dot per letter — a subtle phoneme-count hint
class _PhonemeDotsRow extends StatelessWidget {
  final String word;

  const _PhonemeDotsRow({required this.word});

  static const List<Color> _dotColors = [
    AppTheme.lavender,
    AppTheme.pink,
    AppTheme.gold,
    AppTheme.cyan,
    const Color(0xFF9F7EBE),
    const Color(0xFF83AFDF),
    const Color(0xFFAED6F1),
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
