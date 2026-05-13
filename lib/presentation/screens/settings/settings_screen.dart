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
                            '⚙️ Parent Settings',
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
                          const _SectionTitle('Profile'),
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
                          const _SectionTitle('Voice & Audio'),
                          _SettingsTile(
                            icon: '🎙️',
                            title: 'Custom Voice Recordings',
                            subtitle: 'Record your own phoneme sounds',
                            onTap: () => _showVoiceRecorderList(context, audio),
                          ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),
                          const SizedBox(height: 24),
                          const _SectionTitle('About'),
                          _SettingsTile(
                            icon: 'ℹ️',
                            title: 'About Phonics Journey',
                            subtitle:
                                'Little Wandle aligned • Offline • v1.0.0',
                            onTap: () => _showAboutDialog(context),
                          ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),
                          _SettingsTile(
                            icon: '🔒',
                            title: 'Privacy',
                            subtitle: 'Local storage only • No tracking',
                            onTap: () => _showPrivacyDialog(context),
                          ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1),
                          const SizedBox(height: 24),
                          const _SectionTitle('Curriculum'),
                          _SettingsTile(
                            icon: '📚',
                            title: 'Curriculum Info',
                            subtitle: 'Phases 2, 3, 4 & 5',
                            onTap: () => _showCurriculumDialog(context),
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

  // --- Utility Methods for Dialogs ---

  void _showVoiceRecorderList(BuildContext context, AudioService audio) {
    final phonemes = [
      's',
      'a',
      't',
      'p',
      'i',
      'n',
      'm',
      'd',
      'g',
      'o',
      'ck',
      'ch',
      'sh',
      'th'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2329),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: phonemes.length,
          itemBuilder: (_, i) => ListTile(
            title: Text('Sound: ${phonemes[i]}',
                style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.mic, color: AppTheme.starYellow),
            onTap: () =>
                context.push('${AppRouter.voiceRecorder}/${phonemes[i]}'),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2329),
        title: const Text('Phonics Journey',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '''
Local, secure, and privacy-focused learning.

This app is designed to help children master phonics 
through a fun space adventure! All progress data 
stays on your device and is never shared.

Version: 1.0.0
Made for Explorers 🚀''',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2329),
        title: const Text('Privacy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('''
Your privacy is our priority. 
        
• All recordings are stored locally.
• No personal data is collected.
• No internet connection is required to play.
• No third-party tracking or analytics.''',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showCurriculumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2329),
        title: const Text('Space Curriculum',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '''
Aligned with Little Wandle Letters and Sounds Revised.

Systematic synthetic phonics progression:''',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildCurriculumTable(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  Widget _buildCurriculumTable() {
    const headerStyle = TextStyle(
        color: AppTheme.starYellow, fontWeight: FontWeight.bold, fontSize: 11);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(3),
      },
      border: TableBorder.all(color: Colors.white10),
      children: [
        const TableRow(
          // FIX: Use decoration instead of backgroundColor
          decoration: BoxDecoration(color: Colors.white12),
          children: [
            Padding(
                padding: EdgeInsets.all(8),
                child: Text('Levels', style: headerStyle)),
            Padding(
                padding: EdgeInsets.all(8),
                child: Text('Phase', style: headerStyle)),
            Padding(
                padding: EdgeInsets.all(8),
                child: Text('Content', style: headerStyle)),
          ],
        ),
        _buildRow('1–25', '2',
            's a t p i n m d g o c k ck e u r h b f l ff ll ss j v'),
        _buildRow('26–55', '3',
            'ch sh th ng ai ee igh oa oo ar or ur ow oi ear air ure er'),
        _buildRow(
            '56–70', '4', 'CVCC, CCVC, CCVCC; 3-letter blends; Tricky words'),
        _buildRow('71–100', '5',
            'Alternative spellings: ay ou ie ea oy ir ue aw wh ph ew oe au ey; Split digraphs'),
      ],
    );
  }

  TableRow _buildRow(String levels, String phase, String content) {
    const cellStyle = TextStyle(color: Colors.white70, fontSize: 10);
    return TableRow(
      children: [
        Padding(
            padding: const EdgeInsets.all(8), child: Text(levels, style: cellStyle)),
        Padding(
            padding: const EdgeInsets.all(8), child: Text(phase, style: cellStyle)),
        Padding(
            padding: const EdgeInsets.all(8), child: Text(content, style: cellStyle)),
      ],
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
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
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
