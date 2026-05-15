import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/audio_service.dart';
import '../../../services/curriculum_service.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../../data/models/progress_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBloc = GetIt.I<ProfileBloc>();
    final progressBloc = GetIt.I<ProgressBloc>();
    final audio = GetIt.I<AudioService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: profileBloc),
        BlocProvider.value(value: progressBloc),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          final profile = profileState is ProfileLoaded ? profileState.profile : null;

          return Scaffold(
            body: Container(
              decoration: AppTheme.spaceBackground,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppTheme.moonWhite),
                          ),
                          const Text(
                            '⚙️ Parent Mission Control',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Andika',
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // --- Privacy Banner ---
                          _buildPrivacyBanner(),
                          const SizedBox(height: 24),

                          const _SectionTitle('Explorer Profile'),
                          _SettingsTile(
                            icon: '✏️',
                            title: 'Edit Profile',
                            subtitle: profile != null
                                ? 'Currently: ${profile.name}'
                                : 'No profile found',
                            onTap: () => context.push(
                              AppRouter.profileSetup,
                              extra: true,
                            ),
                          ).animate().fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          const _SectionTitle('Curriculum & Progress'),
                          _SettingsTile(
                            icon: '📊',
                            title: 'View Progress Table',
                            subtitle: 'Track Little Wandle Phase mastery',
                            onTap: () => _showCurriculumDialog(context),
                          ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          const _SectionTitle('Voice & Audio'),
                          _SettingsTile(
                            icon: '🎙️',
                            title: 'Custom Voice Recordings',
                            subtitle: 'Record your own phoneme sounds',
                            onTap: () => _showVoiceRecorderList(context, audio),
                          ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                          const SizedBox(height: 24),
                          const _SectionTitle('Ship Info'),
                          _SettingsTile(
                            icon: 'ℹ️',
                            title: 'About Phonics Journey',
                            subtitle: 'Version 1.0.0 • Offline Only',
                            onTap: () => _showAboutDialog(context),
                          ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1),
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

  Widget _buildPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cosmicTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.cosmicTeal.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppTheme.cosmicTeal),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your child's data is safe. Everything is stored locally on this Pixel 10. No tracking, no cloud, no stress.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // --- Dialogs & Lists ---

  void _showCurriculumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: BlocProvider.of<ProgressBloc>(context),
        child: BlocBuilder<ProgressBloc, ProgressState>(
          builder: (context, state) {
            Map<int, LevelProgressModel> progressMap = {};
            if (state is ProgressLoaded) progressMap = state.progressMap;

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Curriculum Progress',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mapped to Little Wandle Letters and Sounds Revised.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressTable(progressMap),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close', style: TextStyle(color: AppTheme.cosmicTeal)))
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressTable(Map<int, LevelProgressModel> progressMap) {
    const headerStyle = TextStyle(color: AppTheme.starYellow, fontWeight: FontWeight.bold, fontSize: 12);
    
    // Grouping logic for summary (Simulated based on your level ranges)
    final phases = [
      {'range': '1-25', 'phase': '2', 'sounds': 's, a, t, p, i, n...'},
      {'range': '26-55', 'phase': '3', 'sounds': 'ch, sh, th, ai...'},
      {'range': '56-70', 'phase': '4', 'sounds': 'Blends (CVCC)'},
      {'range': '71-100', 'phase': '5', 'sounds': 'Alt spellings'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Phase', style: headerStyle)),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Focus', style: headerStyle)),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Status', style: headerStyle)),
          ],
        ),
        ...phases.map((p) => TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text(p['phase']!, style: const TextStyle(color: Colors.white))),
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text(p['sounds']!, style: const TextStyle(color: Colors.white70, fontSize: 11))),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _getPhaseStatusWidget(p['phase']!, progressMap),
            ),
          ],
        )),
      ],
    );
  }

  Widget _getPhaseStatusWidget(String phase, Map<int, LevelProgressModel> progressMap) {
    // Basic logic to show if a phase is "started" or "done"
    bool hasStarted = false;
    if (phase == '2' && progressMap.containsKey(1)) hasStarted = true;
    if (phase == '3' && progressMap.containsKey(26)) hasStarted = true;

    return Icon(
      hasStarted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
      size: 18,
      color: hasStarted ? AppTheme.cosmicTeal : Colors.white24,
    );
  }

  void _showVoiceRecorderList(BuildContext context, AudioService audio) {
    final phonemes = ['s', 'a', 't', 'p', 'i', 'n', 'm', 'd', 'g', 'o', 'ck', 'ch', 'sh', 'th'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2329),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Custom Recordings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: phonemes.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.volume_up, size: 18, color: Colors.white70)),
                  title: Text('Phoneme: /${phonemes[i]}/', style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.mic_none_rounded, color: AppTheme.starYellow),
                  onTap: () => context.push('${AppRouter.voiceRecorder}/${phonemes[i]}'),
                ),
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
        backgroundColor: const Color(0xFF1C2329),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Phonics Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "A systematic phonics adventure built on the Little Wandle framework. Designed for offline safety and maximum fun.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}

// --- Internal Helper Widgets ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.starYellow,
          letterSpacing: 1.5,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
