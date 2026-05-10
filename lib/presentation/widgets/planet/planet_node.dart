import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/curriculum_service.dart';

class PlanetNode extends StatelessWidget {
  final CurriculumLevel level;
  final int stars;
  final bool isUnlocked;
  final bool isCurrent;
  final Color themeColor;
  final VoidCallback onTap;

  const PlanetNode({
    super.key,
    required this.level,
    required this.stars,
    required this.isUnlocked,
    required this.isCurrent,
    required this.themeColor,
    required this.onTap,
  });

  static const double _size = 90.0;

  // Different planet visual styles based on level id
  static const List<String> _planetEmojis = [
    '🌍', '🌕', '🪐', '🔴', '🌑', '🟤', '⚫', '🌐',
    '🌏', '🌖', '💙', '🟠',
  ];

  static const List<List<Color>> _planetGradients = [
    [Color(0xFF4CAF82), Color(0xFF2E7D52)],    // green
    [Color(0xFF2196F3), Color(0xFF0D47A1)],    // blue
    [Color(0xFFFF8C42), Color(0xFFE65100)],    // orange
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)],    // purple
    [Color(0xFFEF5350), Color(0xFFB71C1C)],    // red
    [Color(0xFF26C6DA), Color(0xFF00838F)],    // teal
    [Color(0xFF7E57C2), Color(0xFF311B92)],    // deep purple
    [Color(0xFF66BB6A), Color(0xFF1B5E20)],    // dark green
    [Color(0xFFEC407A), Color(0xFF880E4F)],    // pink
    [Color(0xFFFFCA28), Color(0xFFF57F17)],    // yellow
  ];

  List<Color> get _gradient {
    final idx = (level.id - 1) % _planetGradients.length;
    if (stars == 3) {
      return [themeColor, themeColor.withOpacity(0.6)];
    }
    return _planetGradients[idx];
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = AppTheme.phaseColor(level.phase);

    Widget planetBody = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _size,
        height: _size + 50, // 90 planet + 6 gap + 18 stars + 22 label + 4 buffer
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Planet circle
            _buildPlanet(phaseColor),
            const SizedBox(height: 6),
            // Level label — constrained to avoid overflow
            _buildLabel(context),
          ],
        ),
      ),
    );

    // Pulsating animation for current level
    if (isCurrent) {
      planetBody = planetBody
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
            duration: 900.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .shimmer(duration: 1500.ms, color: themeColor.withOpacity(0.4));
    }

    return planetBody;
  }

  Widget _buildPlanet(Color phaseColor) {
    final gradient = _gradient;

    Widget planet = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnlocked
            ? RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: gradient,
              )
            : const RadialGradient(
                colors: [
                  Color(0xFF3A3E5C),
                  Color(0xFF1E2138),
                ],
              ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: gradient.first.withOpacity(stars == 3 ? 0.7 : 0.3),
                  blurRadius: stars == 3 ? 24 : 12,
                  spreadRadius: stars == 3 ? 4 : 1,
                ),
              ]
            : null,
        border: Border.all(
          color: isUnlocked
              ? gradient.first.withOpacity(0.6)
              : Colors.white12,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Planet surface details (rings for some)
          if (isUnlocked && level.id % 5 == 3)
            _PlanetRings(color: gradient.first),

          // Lock icon or stars
          if (!isUnlocked)
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 28)
          else if (stars == 3)
            // Completed: show big star icon (avoids Noto font fetch on web)
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 32)
          else
            // Show level number
            Text(
              '${level.id}',
              style: TextStyle(
                fontFamily: 'Andika',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );

    return planet;
  }

  Widget _buildLabel(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90, maxHeight: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // Stars row
        if (isUnlocked)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 13,
                color: i < stars ? AppTheme.starYellow : Colors.white24,
              );
            }),
          ),

        // GPC label (grapheme)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppTheme.stardustBlue.withOpacity(0.7)
                : AppTheme.lockedGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            level.grapheme.length > 6
                ? 'L${level.id}'
                : level.grapheme,
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ],
      ),
    );
  }
}

/// Decorative planetary rings for certain levels
class _PlanetRings extends StatelessWidget {
  final Color color;
  const _PlanetRings({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: CustomPaint(
          size: const Size(90, 30),
          painter: _RingPainter(color: color),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}