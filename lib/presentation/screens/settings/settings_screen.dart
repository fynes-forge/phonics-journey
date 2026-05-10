import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/audio_service.dart';
import '../../blocs/profile/profile_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBloc = GetIt.I<ProfileBloc>();
    final audio = GetIt.I<AudioService>();

    return BlocProvider.value(
      value: profileBloc,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final profile = state is ProfileLoaded ? state.profile : null;
          final themeColor = profile != null
              ? Color(profile.themeColorValue)
              : AppTheme.profileColors[0];

          return Scaffold(
            body: Container(
              decoration: AppTheme.spaceBackground,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppTheme.moonWhite),
                          ),
                          Text(
                            '⚙️ Parent Settings',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SectionTitle('Profile'),
                          _SettingsTile(
                            icon: '✏️',
                            title: 'Edit Profile',
                            subtitle: profile != null
                                ? 'Currently: ${profile.name}'
                                : 'No profile',
                            onTap: () => context.push(
                              AppRouter.profileSetup,
                              extra: true,
                            ),
                          ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          _SectionTitle('Voice & Audio'),
                          _SettingsTile(
                            icon: '🎙️',
                            title: 'Custom Voice Recordings',
                            subtitle: 'Record your own phoneme sounds',
                            onTap: () => _showVoiceRecorderList(context, audio),
                          ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          _SectionTitle('About'),
                          _SettingsTile(
                            icon: 'ℹ️',
                            title: 'About Phonics Journey',
                            subtitle: 'Little Wandle aligned • Offline only • v1.0.0',
                            onTap: () => _showAboutDialog(context),
                          ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1),

                          _SettingsTile(
                            icon: '🔒',
                            title: 'Privacy',
                            subtitle: 'All data stored locally. No tracking. No ads.',
                            onTap: () => _showPrivacyDialog(context),
                          ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          _SectionTitle('Curriculum'),
                          _SettingsTile(
                            icon: '📚',
                            title: 'About Little Wandle',
                            subtitle: 'Phases 2, 3, 4 & 5 — 100 levels',
                            onTap: () => _showCurriculumDialog(context),
                          ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVoiceRecorderList(BuildContext context, AudioService audio) {
    final phonemes = [
      's', 'a', 't', 'p', 'i', 'n', 'm', 'd', 'g', 'o',
      'c', 'k', 'ck', 'e', 'u', 'r', 'h', 'b', 'f', 'l',
      'ch', 'sh', 'th', 'ng', 'ai', 'ee', 'igh', 'oa', 'oo',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.stardustBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select a phoneme to record',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: phonemes.length,
                itemBuilder: (_, i) {
                  final phoneme = phonemes[i];
                  final hasCustom =
                      audio.customVoicePaths.containsKey(phoneme);
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasCustom
                            ? AppTheme.successGreen.withOpacity(0.2)
                            : AppTheme.cosmicTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          phoneme,
                          style: const TextStyle(
                            fontFamily: 'Andika',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.moonWhite,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      '"$phoneme" sound',
                      style: const TextStyle(
                        fontFamily: 'Andika',
                        color: AppTheme.moonWhite,
                      ),
                    ),
                    subtitle: Text(
                      hasCustom ? '✅ Custom recording' : '🔊 Using TTS',
                      style: TextStyle(
                        fontFamily: 'Andika',
                        color: hasCustom
                            ? AppTheme.successGreen
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '${AppRouter.voiceRecorder}/$phoneme');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('🚀 Phonics Journey',
            style: TextStyle(fontFamily: 'Andika', color: AppTheme.moonWhite)),
        content: const Text(
          'A privacy-first phonics app aligned to the '
          'Little Wandle Letters and Sounds Revised programme.\n\n'
          '100 levels across Phases 2–5.\n\n'
          'All data is stored locally on this device. '
          'No internet connection required. '
          'No data is ever sent anywhere.',
          style: TextStyle(fontFamily: 'Andika', color: AppTheme.moonWhite),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('🔒 Privacy',
            style: TextStyle(fontFamily: 'Andika', color: AppTheme.moonWhite)),
        content: const Text(
          '• No internet permissions required\n'
          '• No analytics or tracking\n'
          '• No advertising\n'
          '• No cloud sync\n'
          '• All profile and progress data lives on this device only\n'
          '• No personal data is collected or transmitted',
          style: TextStyle(
              fontFamily: 'Andika', color: AppTheme.moonWhite, height: 1.8),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showCurriculumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.stardustBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('📚 Curriculum',
            style: TextStyle(fontFamily: 'Andika', color: AppTheme.moonWhite)),
        content: const Text(
          'This app follows the Little Wandle Letters and Sounds Revised programme:\n\n'
          '• Phase 2 (Levels 1–25): Single GPCs\n'
          '• Phase 3 (Levels 26–55): Digraphs, trigraphs & tricky words\n'
          '• Phase 4 (Levels 56–70): Adjacent consonants\n'
          '• Phase 5 (Levels 71–100): Alternative spellings & split digraphs\n\n'
          'Each level requires 3 stars (100% accuracy) to unlock the next.',
          style: TextStyle(
              fontFamily: 'Andika', color: AppTheme.moonWhite, height: 1.7),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Andika',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.starYellow,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.moonWhite.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
