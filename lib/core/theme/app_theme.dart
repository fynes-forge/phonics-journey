import 'package:flutter/material.dart';

class AppTheme {
  // ── Space Palette ─────────────────────────────────────────────────────────
  static const Color deepSpace = Color(0xFF0A0E2A);
  static const Color nebulaPurple = Color(0xFF2D1B69);
  static const Color stardustBlue = Color(0xFF1A3A6B);
  static const Color cosmicTeal = Color(0xFF0D6E8A);
  static const Color starYellow = Color(0xFFFFD700);
  static const Color moonWhite = Color(0xFFF0F4FF);
  static const Color lockedGrey = Color(0xFF4A4E6B);
  static const Color successGreen = Color(0xFF4CAF82);
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color accentOrange = Color(0xFFFF8C42);

  // ── Phase colour badges ───────────────────────────────────────────────────
  static const Map<int, Color> phaseColors = {
    2: Color(0xFF4CAF82), // green
    3: Color(0xFF2196F3), // blue
    4: Color(0xFFFF8C42), // orange
    5: Color(0xFFAB47BC), // purple
  };

  static Color phaseColor(int phase) => phaseColors[phase] ?? cosmicTeal;

  // ── Planet glow colours (profile theme options) ───────────────────────────
  static const List<Color> profileColors = [
    Color(0xFF7C4DFF), // violet
    Color(0xFF00BCD4), // cyan
    Color(0xFFFF4081), // pink
    Color(0xFF76FF03), // lime
    Color(0xFFFFD600), // gold
    Color(0xFFFF6D00), // orange
    Color(0xFF00E5FF), // light blue
    Color(0xFFE040FB), // magenta
  ];

  // ── Default theme ─────────────────────────────────────────────────────────
  static ThemeData get defaultTheme => _buildTheme(profileColors[0]);

  static ThemeData buildThemeForColor(Color seed) => _buildTheme(seed);

  static ThemeData _buildTheme(Color seed) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: seed,
        secondary: starYellow,
        surface: deepSpace,
        onPrimary: moonWhite,
        onSurface: moonWhite,
      ),
      scaffoldBackgroundColor: deepSpace,
      fontFamily: 'Andika',
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _buildTextTheme().titleLarge?.copyWith(
              color: moonWhite,
              fontFamily: 'Andika',
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: moonWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Andika',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: stardustBlue.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: seed.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: seed.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: seed, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Andika',
          color: moonWhite,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Andika',
          color: moonWhite.withOpacity(0.5),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Andika',
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: moonWhite,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Andika',
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: moonWhite,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Andika',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: moonWhite,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Andika',
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: moonWhite,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Andika',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: moonWhite,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Andika',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: moonWhite,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Andika',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: moonWhite,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Andika',
        fontSize: 18,
        color: moonWhite,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Andika',
        fontSize: 16,
        color: moonWhite,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Andika',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: moonWhite,
      ),
    );
  }

  // ── Gradient helpers ──────────────────────────────────────────────────────
  static LinearGradient spaceGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepSpace, nebulaPurple, stardustBlue],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient planetGlow(Color color) => RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color.withOpacity(0.4),
          Colors.transparent
        ],
        stops: const [0.3, 0.7, 1.0],
      ) as dynamic;

  static BoxDecoration spaceBackground = BoxDecoration(
    gradient: spaceGradient,
  );

  static BoxDecoration cardDecoration({Color? glowColor}) => BoxDecoration(
        color: stardustBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: (glowColor ?? cosmicTeal).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      );
}
