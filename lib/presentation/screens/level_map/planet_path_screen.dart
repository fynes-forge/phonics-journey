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
    // Getting the singletons from GetIt
    _profileBloc = GetIt.I<ProfileBloc>();
    _progressBloc = GetIt.I<ProgressBloc>();
    
    // Initial load of the active profile
    _profileBloc.add(LoadActiveProfile());
  }

  @override
  void dispose() {
    // IMPORTANT: We do NOT call _profileBloc.close() or _progressBloc.close() here.
    // Since they are LazySingletons in GetIt, closing them here makes them 
    // unusable (Bad State) for the rest of the app's lifecycle.
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
            // Load progress as soon as we know which profile is active
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
              // Map state data to local variable
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
                      // Animated background
                      const Positioned.fill(child: _ScrollingStarfield()),
                      
                      // Custom Navigation/Top Bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _TopBar(
                          profile: profile,
                          themeColor: themeColor,
                          onSettingsTap: () => context.push(AppRouter.settings),
                          onLongPress: _handleParentalGate,
                        ),
                      ),
                      
                      // Winding Planet Path
                      Positioned.fill(
                        top: 100,
                        child: _PlanetScrollView(
                          levels: levels,
                          progressMap: progressMap,
                          themeColor: themeColor,
                          scrollController: _scrollController,
                          onLevelTap: (levelId) =>
                              _onLevelTap(context, levelId, progressMap),
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
    // Unlock Logic: Level 1 is always open, others require 1+ stars on the previous level
    final bool isUnlocked = levelId == 1 || (progressMap[levelId - 1]?.stars ?? 0) > 0;

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
          'Finish the previous planet to unlock this one!',
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
                  child: const Text('🚀', style: TextStyle(fontSize: 20)),
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
            // Path Line Painter
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
            // Map Nodes
            ...List.generate(levels.length, (index) {
              final level = levels[index];
              // Reverse index to put Level 1 at the bottom
              final reversedIndex = levels.length - 1 - index;
              
              final progress = progressMap[level.id];
              final stars = progress?.stars ?? 0;
              
              // Standard game logic: unlock if previous level is passed (>0 stars)
              final isUnlocked = level.id == 1 || (progressMap[level.id - 1]?.stars ?? 0) > 0;

              // Visual calculations
              final wave = (reversedIndex % 4);
              double xOffset = (wave == 0 || wave == 3) 
                  ? screenWidth / 2 - kHorizontalAmplitude 
                  : screenWidth / 2 + kHorizontalAmplitude;

              return Positioned(
                left: xOffset - 45, // Adjust based on PlanetNode width
                top: reversedIndex * kPlanetSpacing + 80.0,
                child: PlanetNode(
                  level: level,
                  stars: stars,
                  isUnlocked: isUnlocked,
                  isCurrent: isUnlocked && stars == 0,
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
      double y = i * spacing + 125;
      
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
    // Simple static star field
    for (int i = 0; i < 60; i++) {
      double x = (i * 137.5) % 400; // Pseudo-random distribution
      double y = (i * 240.0) % 800;
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}