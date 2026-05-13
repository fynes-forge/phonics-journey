import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/profile/profile_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    // Initialize the singleton and trigger the initial load
    _profileBloc = GetIt.I<ProfileBloc>()..add(LoadActiveProfile());
  }

  @override
  void dispose() {
    // IMPORTANT: We do NOT close _profileBloc here.
    // It is a global singleton managed by GetIt and used throughout the app.
    // Closing it here would prevent any other screen from using it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      listener: (context, state) {
        // We add a slight delay to ensure the splash animations can be seen
        if (state is ProfileLoaded) {
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted) context.go(AppRouter.planetPath);
          });
        } else if (state is ProfileNotFound) {
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted) context.go(AppRouter.profileSetup);
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: AppTheme.spaceBackground,
          child: Stack(
            children: [
              const _StarField(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🚀',
                      style: TextStyle(fontSize: 96),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.elasticOut,
                          duration: 900.ms,
                        )
                        .then()
                        .shimmer(duration: 1200.ms),
                    const SizedBox(height: 24),
                    Text(
                      'Phonics Journey',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppTheme.moonWhite,
                                fontWeight: FontWeight.bold,
                              ),
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'A Space Adventure in Reading',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.starYellow,
                          ),
                    )
                        .animate(delay: 700.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 48),
                    _LoadingDots()
                        .animate(delay: 1000.ms)
                        .fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _StarPainter(_controller.value),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);

  static final List<Offset> _positions = List.generate(
    60,
    (i) => Offset(
      (i * 137.508 % 400) / 400,
      (i * 97.3 % 800) / 800,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _positions.length; i++) {
      final pos = _positions[i];
      final flicker = 0.4 + 0.6 * ((t * 3.14 + i * 0.5).abs() % 3.14 / 3.14);
      paint.color = Colors.white.withOpacity(flicker * 0.8);
      final radius = 1.0 + (i % 3) * 0.8;
      canvas.drawCircle(
        Offset(pos.dx * size.width, pos.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _LoadingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppTheme.starYellow,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
              duration: 600.ms,
              delay: Duration(milliseconds: i * 200),
            );
      }),
    );
  }
}
