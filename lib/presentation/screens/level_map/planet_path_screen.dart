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

// Constants for the winding path layout
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
  int _longPressCount = 0;

  @override
  void initState() {
    super.initState();
    _profileBloc = GetIt.I<ProfileBloc>();
    _progressBloc = GetIt.I<ProgressBloc>();
    _profileBloc.add(LoadActiveProfile());
  }

  @override
  void dispose() {
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
                      // 1. Background Layer
                      const Positioned.fill(child: _ScrollingStarfield()),

                      // 2. Middle Layer: Winding Planet Path
                      // top: 0 allows the scroll area to go full screen
                      Positioned.fill(
                        top: 0, 
                        child: _PlanetScrollView(
                          levels: levels,
                          progressMap: progressMap,
                          themeColor: themeColor,
                          scrollController: _scrollController,
                          onLevelTap: (levelId) =>
                              _onLevelTap(context, levelId, progressMap),
                        ),
                      ),

                      // 3. Front Layer: Custom Navigation/Top Bar
                      // Placing this LAST in the stack keeps it in front of scrolling planets
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.deepSpace.withOpacity(0.8),
                                AppTheme.deepSpace.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: _TopBar(
                            profile: profile,
                            themeColor: themeColor,
                            onSettingsTap: () => context.push(AppRouter.settings),
                            onLongPress: _handleParentalGate,
                          ),
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

  void _onLevelTap(BuildContext context, int levelId, Map<int, LevelProgressModel> progressMap) {
    // 3-STAR GATE: Level 1 is always open, others require 3 stars on previous level
    final bool isUnlocked = levelId == 1 || (progressMap[levelId - 1]?.stars ?? 0) >= 3;

    if (!isUnlocked) {
      _showLockedDialog(context);
      return;
    }
    context.push('${AppRouter.game}/$levelId');
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2329),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Planet Locked!', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Master the previous planet with 3 stars to unlock this one!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _handleParentalGate() {
    _longPressCount++;
    if (_longPressCount >= 3) {
      _longPressCount = 0;
      context.push(AppRouter.settings);
    }
  }
}

// ── Supporting Widgets ───────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: themeColor.withOpacity(0.2),
                  child: Text(
                    ['🚀', '⭐', '🌙', '🪐', '☄️', '🌟', '🛸', '🌈'][profile.avatarIndex % 8],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              profile.name,
              style: TextStyle(
                color: themeColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(2, 2)),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
              onPressed: onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

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
    final totalHeight = levels.length * kPlanetSpacing + 250.0;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
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
            ...List.generate(levels.length, (index) {
              final level = levels[index];
              final reversedIndex = levels.length - 1 - index;

              final progress = progressMap[level.id];
              final stars = progress?.stars ?? 0;

              // 3-STAR GATE logic for visual unlocking
              final isUnlocked = level.id == 1 || (progressMap[level.id - 1]?.stars ?? 0) >= 3;

              final wave = (reversedIndex % 4);
              double xOffset = (wave == 0 || wave == 3) 
                  ? screenWidth / 2 - kHorizontalAmplitude 
                  : screenWidth / 2 + kHorizontalAmplitude;

              return Positioned(
                left: xOffset - 45,
                top: reversedIndex * kPlanetSpacing + 120.0, // Adjusted padding for TopBar
                child: PlanetNode(
                  level: level,
                  stars: stars,
                  isUnlocked: isUnlocked,
                  isCurrent: isUnlocked && stars < 3,
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

class _PathPainter extends CustomPainter {
  final int levelCount;
  final double spacing, amplitude, screenWidth;
  final Color themeColor;

  _PathPainter({
    required this.levelCount, 
    required this.spacing, 
    required this.amplitude, 
    required this.screenWidth, 
    required this.themeColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final path = Path();
    for (int i = 0; i < levelCount; i++) {
      final wave = i % 4;
      double x = (wave == 0 || wave == 3) 
          ? screenWidth / 2 - amplitude 
          : screenWidth / 2 + amplitude;
      double y = i * spacing + 165; // Offset to match node positions

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScrollingStarfield extends StatelessWidget {
  const _ScrollingStarfield();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2);
    for (int i = 0; i < 60; i++) {
      double x = (i * 137.5) % 400;
      double y = (i * 240.0) % 800;
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}