import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/progress_model.dart';
import '../../../services/curriculum_service.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../widgets/planet/planet_node.dart';

// Top-level constants accessible by all private classes in this file
const double kPlanetSpacing = 160.0;
const double kHorizontalAmplitude = 90.0;

class PlanetPathScreen extends StatefulWidget {
  const PlanetPathScreen({super.key});

  @override
  State<PlanetPathScreen> createState() => _PlanetPathScreenState();
}

class _PlanetPathScreenState extends State<PlanetPathScreen> {
  late final ProfileBloc _profileBloc;
  late final ProgressBloc _progressBloc;
  final ScrollController _scrollController = ScrollController();
  int _longPressCount = 0; // For parental gate

  @override
  void initState() {
    super.initState();
    _profileBloc = GetIt.I<ProfileBloc>()..add(LoadActiveProfile());
    _progressBloc = GetIt.I<ProgressBloc>();
  }

  @override
  void dispose() {
    _profileBloc.close();
    _progressBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _progressBloc),
      ],
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _progressBloc.add(LoadAllProgress(state.profile.id));
          } else if (state is ProfileNotFound) {
            context.go(AppRouter.profileSetup);
          }
        },
        builder: (context, profileState) {
          if (profileState is! ProfileLoaded) {
            return const Scaffold(
              backgroundColor: AppTheme.deepSpace,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final profile = profileState.profile;
          final themeColor = Color(profile.themeColorValue);

          return BlocBuilder<ProgressBloc, ProgressState>(
            builder: (context, progressState) {
              Map<int, LevelProgressModel> progressMap = {};
              if (progressState is ProgressLoaded) {
                progressMap = progressState.progressMap;
              } else if (progressState is ProgressUpdated) {
                progressMap = progressState.progressMap;
              }

              final levels = GetIt.I<CurriculumService>().levels;

              return Scaffold(
                body: Container(
                  decoration: AppTheme.spaceBackground,
                  child: Stack(
                    children: [
                      // Starfield background
                      const Positioned.fill(child: _ScrollingStarfield()),

                      // Top bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _TopBar(
                          profile: profile,
                          themeColor: themeColor,
                          onSettingsTap: () =>
                              context.push(AppRouter.settings),
                          onLongPress: _handleParentalGate,
                        ),
                      ),

                      // Planet Path
                      Positioned.fill(
                        top: 100,
                        child: _PlanetScrollView(
                          levels: levels,
                          progressMap: progressMap,
                          themeColor: themeColor,
                          scrollController: _scrollController,
                          onLevelTap: (levelId) =>
                              _onLevelTap(context, levelId, progressMap, profile.id),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onLevelTap(
    BuildContext context,
    int levelId,
    Map<int, LevelProgressModel> progressMap,
    String profileId,
  ) {
    final isUnlocked = levelId == 1 ||
        (progressMap[levelId - 1]?.stars ?? 0) == 3;

    if (!isUnlocked) {
      _showLockedDialog(context);
      return;
    }

    context.push('${AppRouter.game}/$levelId');
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Planet Locked!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Get 3 stars on the previous level to unlock this planet!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK, I\'ll try again!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleParentalGate() {
    _longPressCount++;
    if (_longPressCount >= 3) {
      _longPressCount = 0;
      _showParentalPinDialog();
    }
  }

  void _showParentalPinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          '👋 Parent/Carer Access',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter PIN to access settings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: '4-digit PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Default PIN: 1234. In production, user-configurable.
              if (controller.text == '1234') {
                Navigator.pop(context);
                context.push(AppRouter.settings);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final dynamic profile;
  final Color themeColor;
  final VoidCallback onSettingsTap;
  final VoidCallback onLongPress;

  const _TopBar({
    required this.profile,
    required this.themeColor,
    required this.onSettingsTap,
    required this.onLongPress,
  });

  static const _avatarEmojis = [
    '🚀', '⭐', '🌙', '🪐', '☄️', '🌟', '🛸', '🌈',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.deepSpace,
            AppTheme.deepSpace.withOpacity(0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Avatar + name
              GestureDetector(
                onLongPress: onLongPress,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _avatarEmojis[profile.avatarIndex % _avatarEmojis.length],
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Settings icon
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(Icons.settings_rounded, color: AppTheme.moonWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Planet Scroll View ────────────────────────────────────────────────────────
class _PlanetScrollView extends StatelessWidget {
  final List<CurriculumLevel> levels;
  final Map<int, LevelProgressModel> progressMap;
  final Color themeColor;
  final ScrollController scrollController;
  final void Function(int) onLevelTap;

  const _PlanetScrollView({
    required this.levels,
    required this.progressMap,
    required this.themeColor,
    required this.scrollController,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    // Total height: spacing per planet + top/bottom padding
    final totalHeight = levels.length * kPlanetSpacing + 200.0;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        width: screenWidth,
        child: Stack(
          children: [
            // Path line (drawn behind planets)
            CustomPaint(
              size: Size(screenWidth, totalHeight),
              painter: _PathPainter(
                levelCount: levels.length,
                spacing: kPlanetSpacing,
                amplitude: kHorizontalAmplitude,
                screenWidth: screenWidth,
                themeColor: themeColor,
              ),
            ),

            // Planet nodes
            ...List.generate(levels.length, (index) {
              final level = levels[index];
              // Levels are shown bottom-to-top (level 1 at bottom)
              final reversedIndex = levels.length - 1 - index;
              final progress = progressMap[level.id];
              final stars = progress?.stars ?? 0;

              final isUnlocked = level.id == 1 ||
                  (progressMap[level.id - 1]?.stars ?? 0) == 3;

              final isCurrent = isUnlocked &&
                  stars < 3 &&
                  (level.id == 1 ||
                      (progressMap[level.id - 1]?.stars ?? 0) == 3);

              // Winding path position
              final t = reversedIndex / (levels.length - 1).clamp(1, 100);
              final wave = (reversedIndex % 4);
              double xOffset;
              if (wave == 0 || wave == 3) {
                xOffset = screenWidth / 2 - kHorizontalAmplitude;
              } else {
                xOffset = screenWidth / 2 + kHorizontalAmplitude;
              }

              final double yPos = reversedIndex * kPlanetSpacing + 80.0;

              return Positioned(
                left: xOffset - 45,
                top: yPos,
                child: PlanetNode(
                  level: level,
                  stars: stars,
                  isUnlocked: isUnlocked,
                  isCurrent: isCurrent,
                  themeColor: themeColor,
                  onTap: () => onLevelTap(level.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Path Painter ──────────────────────────────────────────────────────────────
class _PathPainter extends CustomPainter {
  final int levelCount;
  final double spacing;
  final double amplitude;
  final double screenWidth;
  final Color themeColor;

  _PathPainter({
    required this.levelCount,
    required this.spacing,
    required this.amplitude,
    required this.screenWidth,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withOpacity(0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = themeColor.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    for (int i = 0; i < levelCount; i++) {
      final wave = i % 4;
      double x;
      if (wave == 0 || wave == 3) {
        x = screenWidth / 2 - amplitude;
      } else {
        x = screenWidth / 2 + amplitude;
      }
      final y = i * spacing + 125;

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        // Bezier curve for smooth winding
        final prevWave = (i - 1) % 4;
        double prevX;
        if (prevWave == 0 || prevWave == 3) {
          prevX = screenWidth / 2 - amplitude;
        } else {
          prevX = screenWidth / 2 + amplitude;
        }
        final prevY = (i - 1) * spacing + 125;
        final midY = (prevY + y) / 2;
        path.cubicTo(prevX, midY, x, midY, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.levelCount != levelCount || old.themeColor != themeColor;
}

// ── Scrolling Starfield ───────────────────────────────────────────────────────
class _ScrollingStarfield extends StatelessWidget {
  const _ScrollingStarfield();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StaticStarPainter(),
    );
  }
}

class _StaticStarPainter extends CustomPainter {
  static final List<_Star> _stars = List.generate(
    80,
    (i) => _Star(
      x: (i * 137.508 % 1000) / 1000,
      y: (i * 73.1 % 1000) / 1000,
      radius: 0.8 + (i % 3) * 0.6,
      opacity: 0.2 + (i % 5) * 0.1,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StaticStarPainter _) => false;
}

class _Star {
  final double x, y, radius, opacity;
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}
