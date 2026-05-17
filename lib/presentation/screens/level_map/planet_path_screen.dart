import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showParentalGate(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ParentalGateDialog(
        onPassed: () => context.push(AppRouter.settings),
      ),
    );
  }

  void _onLevelTap(BuildContext context, int levelId, Map<int, LevelProgressModel> progressMap) {
    final bool isUnlocked = levelId == 1 || (progressMap[levelId - 1]?.stars ?? 0) >= 3;

    if (!isUnlocked) {
      _showLockedDialog(context);
      return;
    }
    context.push('${AppRouter.game}/$levelId');
  }

  void _showLockedDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
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
              int totalStars = 0;

              if (progressState is ProgressLoaded) {
                progressMap = progressState.progressMap;
                totalStars = progressState.totalStarCoins;
              } else if (progressState is ProgressUpdated) {
                progressMap = progressState.progressMap;
                totalStars = progressState.totalStarCoins;
              }

              final levels = GetIt.I<CurriculumService>().levels;

              return Scaffold(
                body: Container(
                  decoration: AppTheme.spaceBackground,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _ScrollingStarfield()),
                      Positioned.fill(
                        child: _PlanetScrollView(
                          levels: levels,
                          progressMap: progressMap,
                          themeColor: themeColor,
                          totalStars: totalStars,
                          scrollController: _scrollController,
                          onLevelTap: (levelId) => _onLevelTap(context, levelId, progressMap),
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: _TopBar(
                          profile: profile,
                          themeColor: themeColor,
                          totalStars: totalStars,
                          onSettingsTap: () => _showParentalGate(context),
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
}

// ── Rocket Hero Widget ───────────────────────────────────────────────────────

class _RocketHero extends StatelessWidget {
  final int totalStars;

  const _RocketHero({required this.totalStars});

  @override
  Widget build(BuildContext context) {
    Color rocketColor = Colors.redAccent;
    if (totalStars >= 10) rocketColor = Colors.greenAccent;
    if (totalStars >= 30) rocketColor = Colors.orangeAccent;
    if (totalStars >= 60) rocketColor = Colors.purpleAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.rocket_launch_rounded,
          size: 32, // Slightly smaller for corner docking
          color: rocketColor,
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.white30)
        .shake(hz: 1.5, curve: Curves.easeInOut),
        
        Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: rocketColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
      ],
    );
  }
}

// ── Top Bar Widget ───────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final dynamic profile;
  final Color themeColor;
  final int totalStars;
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.profile,
    required this.themeColor,
    required this.totalStars,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    String rank = 'Cadet';
    if (totalStars >= 10) rank = 'Explorer';
    if (totalStars >= 30) rank = 'Captain';
    if (totalStars >= 60) rank = 'Master';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.deepSpace.withOpacity(0.9), AppTheme.deepSpace.withOpacity(0.0)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(profile.name, style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(rank.toUpperCase(), style: TextStyle(color: themeColor.withOpacity(0.6), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.starYellow, size: 20),
                    const SizedBox(width: 6),
                    Text('$totalStars', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ).animate(target: totalStars > 0 ? 1 : 0).shimmer(duration: 1200.ms).scale(duration: 300.ms),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 28), onPressed: onSettingsTap),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Path Rendering Widgets ───────────────────────────────────────────────────

class _PlanetScrollView extends StatelessWidget {
  final List<CurriculumLevel> levels;
  final Map<int, LevelProgressModel> progressMap;
  final Color themeColor;
  final int totalStars;
  final ScrollController scrollController;
  final void Function(int) onLevelTap;

  const _PlanetScrollView({
    required this.levels,
    required this.progressMap,
    required this.themeColor,
    required this.totalStars,
    required this.scrollController,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalHeight = levels.length * kPlanetSpacing + 250.0;
    final screenWidth = MediaQuery.of(context).size.width;

    final int currentLevelId = levels.firstWhere(
      (l) => (progressMap[l.id]?.stars ?? 0) < 3,
      orElse: () => levels.last,
    ).id;

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
              final isUnlocked = level.id == 1 || (progressMap[level.id - 1]?.stars ?? 0) >= 3;

              final wave = (reversedIndex % 4);
              double xOffset = (wave == 0 || wave == 3)
                  ? screenWidth / 2 - kHorizontalAmplitude
                  : screenWidth / 2 + kHorizontalAmplitude;
              double yOffset = reversedIndex * kPlanetSpacing + 120.0;

              return Stack(
                children: [
                  Positioned(
                    left: xOffset - 45,
                    top: yOffset,
                    child: PlanetNode(
                      level: level,
                      stars: stars,
                      isUnlocked: isUnlocked,
                      isCurrent: level.id == currentLevelId,
                      themeColor: themeColor,
                      onTap: () => onLevelTap(level.id),
                    ),
                  ),

                  if (level.id == currentLevelId)
                    Positioned(
                      left: xOffset - 65, // Tucked to the left
                      top: yOffset - 15,  // Tucked slightly higher
                      child: _RocketHero(totalStars: totalStars),
                    ),
                ],
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

  _PathPainter({required this.levelCount, required this.spacing, required this.amplitude, required this.screenWidth, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = themeColor.withOpacity(0.15)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 4;
    final path = Path();
    for (int i = 0; i < levelCount; i++) {
      final wave = i % 4;
      double x = (wave == 0 || wave == 3) ? screenWidth / 2 - amplitude : screenWidth / 2 + amplitude;
      double y = i * spacing + 165;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
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
    final paint = Paint()..color = Colors.white.withOpacity(0.15);
    final random = Random(42); 
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * 500, random.nextDouble() * 2000), random.nextDouble() * 1.5, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParentalGateDialog extends StatefulWidget {
  final VoidCallback onPassed;
  const _ParentalGateDialog({required this.onPassed});

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  late int num1, num2, answer;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final random = Random();
    num1 = random.nextInt(10) + 5;
    num2 = random.nextInt(10) + 2;
    answer = num1 + num2;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text("Parental Gate", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Solve to enter settings:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Text("$num1 + $num2 = ?", style: const TextStyle(color: AppTheme.starYellow, fontSize: 32, fontWeight: FontWeight.bold)),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.cosmicTeal))),
            onChanged: (value) {
              if (int.tryParse(value) == answer) {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                widget.onPassed();
              }
            },
          ),
        ],
      ),
    );
  }
}