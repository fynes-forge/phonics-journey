import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/splash_screen.dart';
import '../../presentation/screens/profile/profile_setup_screen.dart';
import '../../presentation/screens/level_map/planet_path_screen.dart';
import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/voice_recorder_screen.dart';

class AppRouter {
  static const String splash        = '/';
  static const String profileSetup  = '/profile-setup';
  static const String planetPath    = '/planet-path';
  static const String game          = '/game';
  static const String settings      = '/settings';
  static const String voiceRecorder = '/voice-recorder';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: profileSetup,
        name: 'profileSetup',
        builder: (context, state) {
          final isEditing = state.extra as bool? ?? false;
          return ProfileSetupScreen(isEditing: isEditing);
        },
      ),
      GoRoute(
        path: planetPath,
        name: 'planetPath',
        builder: (context, state) => const PlanetPathScreen(),
      ),
      GoRoute(
        path: '$game/:levelId',
        name: 'game',
        builder: (context, state) {
          final levelId = int.parse(state.pathParameters['levelId']!);
          return GameScreen(levelId: levelId);
        },
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '$voiceRecorder/:phoneme',
        name: 'voiceRecorder',
        builder: (context, state) {
          final phoneme = state.pathParameters['phoneme']!;
          return VoiceRecorderScreen(phoneme: phoneme);
        },
      ),
    ],
  );
}
